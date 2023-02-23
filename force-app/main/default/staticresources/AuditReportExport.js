(function() {
    var app = angular.module('auditReportExport', []);

    function Criteria() {
        this.id = 0;
        this.field = {}
        this.operator = {}
        this.value = '';
    }

    function cloneObject(obj) {
        if (obj === null || typeof obj !== 'object') {
            return obj;
        }

        var temp = obj.constructor(); // give temp the original obj's constructor
        for (var key in obj) {
            temp[key] = cloneObject(obj[key]);
        }

        return temp;
    }

    function parseDate(input) {
        re = /^(\d{1,2})[\.\/\\](\d{1,2})[\.\/\\](\d{4})$/;
        var parts = input.match(re);

        var month = parts[1];
        var day = parts[2];
        var year = parts[3];
        var date = new Date(year, month - 1, day);
        if (date.getDate() != day || date.getMonth() != (month - 1)) {
            throw 1;
        }
    }

    function parseDateTime(input) {
        re = /^(\d{2})[\.\/\\](\d{2})[\.\/\\](\d{4}) (\d{2}):(\d{2}):?(\d{0,2})$/;
        var parts = input.match(re);
        var month = parts[1] - 1;
        var day = parts[2];
        var year = parts[3];
        var hour = parts[4];
        var minute = parts[5];
        var second = parts[6];
        var date = new Date(year, month, day, hour, minute, second);
        if (parts == null || date.getFullYear() != year || date.getMonth() != month || date.getDate() != day || date.getHours() != hour || date.getMinutes() != minute || date.getSeconds() != second) {
            throw 1;
        }
    }

    function parseReal(input) {
        var parts = input.match(/^(\d+)\.{0,1}(\d*)$/);
        if (parts == null) {
            throw {};
        }
    }

    function parseInteger(input) {
        var parts = input.match(/^(\d+)$/);
        if (parts == null) {
            throw {};
        }
    }

    function AuditFilterController($scope) {
        //var $scope = this;
        $scope.status = 'Controller set';
        //$scope.criterias = [];

        //$scope.fieldNames = [];
        $scope.objectMetadata = {};
        $scope.audits = [];
        $scope.googleUrl = '';
        $scope.pageSize = '10';
        $scope.pageNumber = 1;
        $scope.allRecords = 0;
        $scope.overalPages = 0;
        $scope.dateError = false;
        $scope.errorsCount = 0;
        $scope.startPurgeAuto = false;
        $scope.isFilterApplied = false;
        $scope.filterScope = 'AND';

        function validateFilterCriterias() {
            var criteria;
            var isValid = true
            $scope.criterias.forEach(function(element, index) {
                //console.log(element);
                if (!element.isValid) {
                    isValid = false;
                    return;
                }
            });
            onValidated(isValid);
            return isValid;
        }

        function onValidated(validationResult) {
            if (validationResult) {
                $('#applyButton').prop('disabled', false);
            } else {
                $('#applyButton').prop('disabled', true);
            }
        }

        $scope.validateFilterCriterias = function() {
            return validateFilterCriterias();
        }

        $scope.onCriteriaNameChanged = function(criteriaId, fieldMetaName) {
            console.log('onCriteriaNameChanged');
            var criteria;
            $scope.criterias.forEach(function(element, index) {
                //console.log(element);
                if (element.id == criteriaId) {
                    criteria = element;
                    return;
                }
            });
            //console.log('criteria ' + criteria);
            var meta;
            $scope.objectMetadata.fieldMetadata.forEach(function(element, index) {
                if (element.fieldName == fieldMetaName) {
                    meta = element;
                    return;
                }
            });
            //console.log('meta ' + meta);
            if (criteria && meta) {
                criteria.field = cloneObject(meta);
                criteria.value = '';
                criteria.operator = {};
                $scope.validateCriteria(criteria);
                //$scope.$apply();
            }
            $scope.validateFilterCriterias();
        }

        $scope.initDefaultCriterias = function() {
            $scope.criterias = [];
            for (var i = 0; i < 3; i++) {
                $scope.addCriteria();
            }
            /*
            $scope.addCriteria();
            $scope.addCriteria();*/
        }
        $scope.clearFilterCriterias = function() {
            $scope.initDefaultCriterias();
            $scope.loadAudits();
            //$scope.addCriteria();
        }
        /**
         * Load object metadata from salesforce
         */
        $scope.loadFilterObjectMetadata = function() {
            Visualforce.remoting.Manager.invokeAction("AuditReportExportController.prepareAuditsMetadata", function(e) {
                $scope.objectMetadata = e;
                console.log(e);
                //$scope.loadAudits();
            });
        };

        /**
         * Find metadata for current field
         */
        $scope.findFieldMetadata = function(fieldName) {
            //console.log(fieldName);
            if (fieldName && fieldName != null) {
                for (var i = 0; i < $scope.objectMetadata.fieldMetadata.length; i++) {
                    var meta = $scope.objectMetadata.fieldMetadata[i];
                    if (meta.fieldName == fieldName) {
                        //console.log('meta ' + meta);
                        return meta;
                    }
                }
                //console.log('null1');
                return {};
            }
            //console.log('null2');
            return {};
        }

        /**
         * Add new criteria
         */
        $scope.addCriteria = function() {
            var criteria = new Criteria();
            criteria.prefix = $scope.filterScope;
            criteria.id = $scope.criterias.length + 1;
            criteria.isValid = true;
            $scope.criterias.push(criteria);
            $scope.isFilterApplied = false;
            return criteria;
        }

        function showErrorSpan(criteriaId, message, isShown) {
            var errorSpan = $("span[id*=error-" + criteriaId + "]");
            if (isShown) {
                errorSpan.removeAttr('style');
                errorSpan.css("color", "red");
                errorSpan.html(message);
                errorSpan.show();
            } else {
                errorSpan.hide();
            }
        }

        $scope.validateCriteria = function validateCriteria(criteria) {
            console.log('validateCriteria');
            $scope.isFilterApplied = false;
            var result = {
                message: '',
                result: true
            };
            if (criteria) {
                if ((criteria.operator.value === undefined || criteria.operator.value === null || criteria.operator.value == '') && (criteria.value != null && criteria.value.length > 0)) {
                    //return false;
                    criteria.isValid = false;
                    result = {
                        message: 'Operator not specified',
                        result: false
                    }
                } else {
                    criteria.isValid = true;
                    result = {
                        message: '',
                        result: true
                    }
                }
                var fieldDataType = criteria.field.fieldDataType;
                if (fieldDataType == 'DATE' || fieldDataType == 'DATETIME') {
                    var dateValue = criteria.value;
                    if (fieldDataType == 'DATE') {
                        try {
                            parseDate(dateValue);
                            //showErrorSpan(criteria.id, '', false);
                            criteria.isValid = true;
                            //return true;
                            result = {
                                message: '',
                                result: true
                            }
                        } catch (exc) {
                            console.log(exc);
                            //showErrorSpan(criteria.id, 'Invalid date. Date must be mm/dd/yyyy', true);
                            criteria.isValid = false;
                            result = {
                                message: 'Invalid date. Date must be mm/dd/yyyy',
                                result: false
                            }
                        }
                    }
                    if (fieldDataType == 'DATETIME') {
                        try {
                            parseDateTime(dateValue);
                            //showErrorSpan(criteria.id, '', false);
                            criteria.isValid = true;
                            result = {
                                message: '',
                                result: true
                            }
                        } catch (exc) {
                            //console.log(exc);
                            //showErrorSpan(criteria.id, 'Invalid date time. Date must be mm/dd/yyyy hh:mm:ss', true);
                            criteria.isValid = false;
                            result = {
                                message: 'Invalid date time. Date must be mm/dd/yyyy hh:mm:ss',
                                result: false
                            }
                        }
                    }
                } else if (result.result) {
                    if (fieldDataType == 'DOUBLE' ||
                        fieldDataType == 'CURRENCY' ||
                        fieldDataType == 'PERCENT') {
                        try {
                            parseReal(criteria.value);
                            //showErrorSpan(criteria.id, '', false);
                            criteria.isValid = true;
                            result = {
                                message: '',
                                result: true
                            }
                        } catch (exc) {
                            //console.log(exc);
                            //showErrorSpan(criteria.id, 'Invalid date time. Date must be mm/dd/yyyy hh:mm:ss', true);
                            criteria.isValid = false;
                            result = {
                                message: "Invalid real number. Value must be digits and '.'",
                                result: false
                            }
                        }
                    } else if (fieldDataType == 'INTEGER') {
                        try {
                            parseInteger(criteria.value);
                            //showErrorSpan(criteria.id, '', false);
                            criteria.isValid = true;
                            result = {
                                message: '',
                                result: true
                            }
                        } catch (exc) {
                            //console.log(exc);
                            //showErrorSpan(criteria.id, 'Invalid date time. Date must be mm/dd/yyyy hh:mm:ss', true);
                            criteria.isValid = false;
                            result = {
                                message: "Invalid integer number. Value must be only digits",
                                result: false
                            }
                        }
                    } else {
                        criteria.isValid = true;
                        showErrorSpan(criteria.id, '', false);
                    }
                }
                //showErrorSpan(criteria.id, '', false);
                //criteria.isValid = true;
                return result;
            }
        }

        $scope.criteriaValueChanged = function(criteriaId) {
            var criteria;
            $scope.criterias.forEach(function(element, index) {
                //console.log(element);
                if (element.id == criteriaId) {
                    criteria = element;
                    return;
                }
            });
            var fieldDataType = criteria.field.fieldDataType;
            var validationRes = $scope.validateCriteria(criteria);
            showErrorSpan(criteria.id, validationRes.message, !validationRes.result);

            $scope.validateFilterCriterias();
        }
        $scope.changeCriteriaScope = function(prefix) {
            $scope.isFilterApplied = false;

            $scope.filterScope = prefix;
            $scope.criterias.forEach(function(element, index) {
                //console.log(element);
                element.prefix = $scope.filterScope;

            });
            $scope.validateFilterCriterias();
        }

        /**
         * remove criteria
         */
        $scope.removeCriteria = function(criteriaId) {
            $scope.isFilterApplied = false;

            var criteria;
            $scope.criterias.forEach(function(element, index) {
                console.log(element);
                if (element.id == criteriaId) {
                    criteria = element;
                    return;
                }
            });
            $scope.criterias.remove(criteria);
            $scope.validateFilterCriterias();
            /*
            $scope.criterias.forEach(function(element, index) {

            });
*/
        }

        /**
         * Get non-empty criterias
         */
        $scope.getCriterias = function() {
            var clearCriterias = [];
            $scope.criterias.forEach(function(element, index) {
                if (element.field && element.operator && element.value) {
                    if (element.field.fieldName != null && element.field.fieldName != "" &&
                        element.operator.value != null && element.operator.value != "" &&
                        element.value != null && element.value != "") {
                        clearCriterias.push(element);
                    }
                }
            });
            console.log(clearCriterias);
            return clearCriterias;
        }

        /**
         * Move page number to pagesnum
         */
        $scope.movePage = function(pagesNum) {
            $scope.pageNumber += pagesNum;
            $scope.loadAudits();
        }

        /**
         * Apply current filter
         */
        $scope.loadAudits = function() {
            var criterias = JSON.stringify($scope.getCriterias());
            Visualforce.remoting.Manager.invokeAction("AuditReportExportController.getAuditsCount", criterias, function(e) {
                $scope.recordsNumber = e;
                $scope.overalPages = (Math.floor($scope.recordsNumber / $scope.pageSize) + 1)
                console.log('records number ' + e);
                Visualforce.remoting.Manager.invokeAction("AuditReportExportController.loadFilteredAudits", criterias, $scope.pageSize, $scope.pageNumber, function(data) {
                    $scope.audits = data;
                    console.log(data);
                    if (criterias.length && criterias.length > 0) {
                        $scope.isFilterApplied = true;
                    }

                    $scope.$apply();
                }, {
                    escape: true
                });
                //$scope.$apply();
                //window.location.href = window.location.href + '?fid=' + e;
            }, {
                escape: true
            });
        }

        /**
         * Send filter to save
         */
        $scope.runBatch = function() {
            Visualforce.remoting.Manager.invokeAction("AuditReportExportController.saveFilter", JSON.stringify($scope.getCriterias()), function(e) {

                var url = window.location.href;
                var uriParam = '';
                if (url.indexOf('?') == -1) {
                    uriParam = '?state=';
                } else {
                    uriParam = '&state=';
                }
                uriParam += encodeURIComponent([e/*, $scope.startPurgeAuto*/].join(''));
                var stateIdx = url.indexOf('state=');
                if (stateIdx != -1) {
                    url = url.substring(0, stateIdx);
                }
                console.log('' + window.location.href + ' ' + stateIdx);

                console.log('uriParam ' + uriParam);
                window.location.href = url + uriParam;

            }, {
                escape: true
            });
        }

        $scope.isNextPageAvailable = function() {
            //console.log((Math.floor($scope.recordsNumber / $scope.pageSize) + 1));
            return $scope.pageNumber < $scope.overalPages;
        }

        $scope.isPreviousPageAvailable = function() {
            return $scope.pageNumber != 1;
        }

        $scope.pageSizeChanged = function() {
            $scope.pageNumber = 1;
            $scope.loadAudits();

        }

        $scope.isPaginationShown = function() {
            return $scope.audits && $scope.audits.length > 0 && $scope.recordsNumber > $scope.pageSize;
        }

        $scope.isAllowedExport = function() {
            //$scope.$apply();
            return $scope.audits && $scope.audits.length > 0 && $scope.isFilterApplied && $scope.validateFilterCriterias();
        }

        $scope.isAuditsNotFound = function() {
            return !$scope.audits || $scope.audits.length == 0;
        }
        $scope.isFilterForUploadedRecords = function() {
            var criteria = false;
            $scope.criterias.forEach(function(element, index) {
                //console.log(element);
                if (element.field.fieldName == 'IsUploaded__c' && (element.value && 'true' == element.value.toLowerCase())) {
                    criteria = true;
                    return;
                }
            });
            return criteria;
        }

        $scope.isDeleteAvailable = function() {
            return $scope.isAllowedExport() && $scope.isFilterForUploadedRecords() && $scope.isFilterApplied && $scope.filterScope == 'AND';
        }

        $scope.runDeleteBatch = function() {
            if ($scope.isFilterForUploadedRecords()) {
                if (confirm("Do you want to delete specialized records")) {
                    Visualforce.remoting.Manager.invokeAction("AuditReportExportController.runAuditPurgeBatch", JSON.stringify($scope.getCriterias()), function(e) {
                        //$scope.audits = e;
                        //console.log(e);
                        //$scope.$apply();
                        if (e == 'ok') {
                            alert('You will be notified by email after records deleted!');
                            console.log(e);
                        }

                    }, {
                        escape: true
                    });
                }
            }
        }

        $scope.initDefaultCriterias();
    }
    app.controller('AuditFilterController', AuditFilterController);

})();