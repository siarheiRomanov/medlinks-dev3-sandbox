public class AuditCaseRptExt {


    private final Audit__c audit;
    private final Account acct;
    private Audit__c acopy;
    public ID acctId;
    public String acctName;
    public String stuffpn { get; set; }
    public String stuffpa { get; set; }
    public String stuffpb { get; set; }
    public String stuffpm { get; set; }

    public class BillSum {
        public String KeyCls { get; set; }
        public String Rowcls { get; set; }
        public String DescAlign { get; set; }
        public String Dept { get; set; }
        public String DOS { get; set; }
        public String ChgCode { get; set; }
        public String BillDesc { get; set; }
        public String UBnum { get; set; }
        public String UBamt { get; set; }
        public String UBcode { get; set; }
        public String OBnum { get; set; }
        public String OBamt { get; set; }
        public String OBcode { get; set; }
        public String DSnum { get; set; }
        public String DSamt { get; set; }
        public String CDnum { get; set; }
        public String CDamt { get; set; }
        public String Annot { get; set; }
    }
    public class DeptSum {
        public String dep { get; set; }
        public String tot { get; set; }
        public String unb { get; set; }
        public String unbp { get; set; }
        public String und { get; set; }
        public String undp { get; set; }
        public String ov { get; set; }
        public String ovp { get; set; }
        public String md { get; set; }
        public String mdp { get; set; }
        public String er { get; set; }  // Jan 2012
        public String ds { get; set; }
        public String dsp { get; set; }
        public String cd { get; set; }
        public String cdp { get; set; }
        public String net { get; set; }
        public String netp { get; set; }
        public String rev { get; set; }
        public String revp { get; set; }
    }

    Integer d_UBnum = 0;
    Integer d_OBnum = 0;
    Integer d_DSnum = 0;
    Integer d_CDnum = 0;
    Decimal d_UBamt = 0;
    Decimal d_OBamt = 0;
    Decimal d_DSamt = 0;
    Decimal d_CDamt = 0;
    String d_dept;

    Decimal ds_tot = 0;
    Decimal ds_unb = 0;
    Decimal ds_und = 0;
    Decimal ds_ov = 0;
    Decimal ds_md = 0;
    Decimal ds_ds = 0;
    Decimal ds_cd = 0;

    Decimal tds_tot = 0;
    Decimal tds_unb = 0;
    Decimal tds_und = 0;
    Decimal tds_ov = 0;
    Decimal tds_md = 0;
    Decimal tds_ds = 0;
    Decimal tds_cd = 0;
    Decimal tds_net = 0;
    Decimal tds_rev = 0;

    Integer t_UBnum = 0;
    Integer t_OBnum = 0;
    Integer t_DSnum = 0;
    Integer t_CDnum = 0;
    Decimal t_UBamt = 0;
    Decimal t_OBamt = 0;
    Decimal t_DSamt = 0;
    Decimal t_CDamt = 0;

    public List<BillSum[]> pageSumLines {get; private set; }
    public BillSum[] TheSum;
    public DeptSum[] TheDepts { get; private set; }

    private Map<String, String> deps;
    private Map<ID, String> depids;

    private class ckey {
        String c;
        String d;
    }
    private List<ckey> uc;
    private List<ckey> oc;
    private List<ckey> dc;

    public class KeyTab {
        public String dcode { get; set; }
        public String ddesc { get; set; }
        public String ucode { get; set; }
        public String udesc { get; set; }
        public String ocode { get; set; }
        public String odesc { get; set; }
    }

    public KeyTab[] TheKeys { get; private set; }
    public String ExitDate { get; private set; }
    public String IncPrefs { get; private set; }

    private static Integer FIRST_BREAK = 15;
    private static Integer SUBSEQ_BREAKS = 24;
    Integer linecount = 0;
    Integer keyelement = 0;
    Integer linemax = FIRST_BREAK;

    Map<String, Double> DeptTotals = new Map<String, Double>();

    public AuditCaseRptExt(ApexPages.StandardController stdController) {
        //Added fields to std controller for AuditPdfReportExportBatch
        if (!Test.isRunningTest()) {
            stdController.addFields(new String[] {'NAME', 'ACCOUNT__C', 'ASSIGNED_AUDITOR__C',
                                                  'ASSIGNED_SCHEDULER__C', 'AUDIT_AMOUNT__C', 'AUDIT_FEE_PAID__C', 'AUDIT_ROLE__C', 'AUDIT_STAGE__C',
                                                  'AUDIT_TYPE__C', 'BILL_ANALYSIS_COMPLETE__C', 'BILL_UPLOADED__C', 'CLIENT_AUDIT_ACCOUNT__C', 'DATE_ACTUAL_EXIT__C',
                                                  'DATE_AUDIT_COMPLETED__C', 'DATE_BILL_RECEIVED__C', 'DATE_BILL_REQUESTED__C', 'DATE_CHART_PULL_REQUESTED__C', 'DATE_LOI__C',
                                                  'DATE_PROPOSED_EXIT__C', 'EVENTGUID__C', 'EXIT_DURATION__C', 'EXIT_MODE__C', 'FACILITY_BILLING_CONTACT__C', 'FACILITY_IS_CLIENT__C',
                                                  'FACILITY_MR_CONTACT__C', 'OPPOSING_AUDIT_ACCOUNT__C', 'OPPOSING_AUDITOR__C', 'OPPOSING_SCHEDULER__C', 'PATIENT_ACCOUNT__C', 'PATIENT_DOB__C',
                                                  'PATIENT_DOBEDIT__C', 'PATIENT_FIRST_NAME__C', 'PATIENT_LAST_NAME__C', 'PATIENT_MR__C', 'PATIENT_NAME__C', 'PAYER_TYPE__C', 'PAYER__C',
                                                  'SERVICE_END_DATE__C', 'SERVICE_START_DATE__C', 'SKIPEVENTUPDATE__C', 'TAMT_ADJ__C', 'TAMT_REVISED__C', 'TAMT_SUMOVER__C', 'TAMT_SUMUNDER__C',
                                                  'TOTAL_SERVICE_DAYS__C',
                                                  'XFLAG__C', 'XN1__C', 'XN2__C', 'XN3__C', 'XN4__C', 'XPA__C', 'XPD__C', 'XPM__C', 'XPN__C',
                                                  'FLAGGED_ITEMS__C', 'TAMT_BILLED__C', 'TAMT_DISALLOWED__C', 'TAMT_DISPUTED__C', 'TAMT_OTHER__C', 'TAMT_OVER__C', 'TAMT_UNBILL__C', 'TAMT_UNDER__C', 'TAMT_NOMD__C', 'TOT_ITEMS__C', 'AUDIT_CONTRACTOR_EXPENSE__C', 'AUDIT_GROSS_REVENUE__C', 'AUDIT_NET_REVENUE__C', 'PATIENT_AUTH_DATE__C', 'PERCENT_DISALLOWED__C', 'PERCENT_DISPUTED__C', 'PERCENT_NET_ADJ__C', 'PERCENT_OVER__C', 'PERCENT_UNDER__C', 'PRE_AUDIT_DIS__C', 'TOTAL_DISP_ADJ__C', 'DATE_AUDIT_RESULTS_DELIVERED__C', 'DATE_BILL_ANALYSIS_COMPLETE__C', 'DATE_CHART_PULL_CONFIRMED__C', 'CURRENTUSERROLES__C', 'BILL_ATTACHED_AS_IMAGE__C', 'DATE_AUDIT_CANCELED__C', 'NEED_OPPOSING__C', 'OPPOSING_AUDIT_CASE_ID__C', 'INVOICE_NUMBER__C', 'EXIT_PAST_DUE_DAYS__C', 'PERCENT_TOT_ERR__C', 'APPROVED__C', 'NOT_APPROVED__C', 'DATE_LOI_SENT__C', 'DRG_VALIDATION_OK__C', 'DRG_VALIDATION_ALTERED__C', 'COMMENTS__C', 'AUDIT_POLICY_SENT_DATE__C'
                                                 });
        }
        this.audit = (Audit__c)stdController.getRecord();

        stuffpn = audit.Patient_Name__c;
        stuffpa = audit.Patient_Account__c;
        system.debug(UserInfo.getUserName() + ' #### : ####' + stuffpn + ' ' + stuffpa);
        String pbd = audit.Patient_DOB__c;
        if (pbd != null)
            stuffpb = pbd.substring(5) + '-' + pbd.substring(0, 4);
        else
            stuffpb = '';
        stuffpm = audit.Patient_MR__c;

        acctId = audit.Account__c;
        acct = [SELECT Id, Name, Shortname__c, Prefs_Include_Disputed__c, Prefs_Include_Unbilled__c, Facility_Street__c,
                Facility_City__c, Facility_State__c, Facility_Zip__c, BillingStreet, BillingCity, BillingState, BillingPostalCode
                FROM Account WHERE Id = :acctid];
        acctName = acct.Name;
        if (acct.Prefs_Include_Disputed__c == true && acct.Prefs_Include_Unbilled__c == true)
            IncPrefs = '*Underbilled and Disputed amounts are included in Net Adjustment';
        if (acct.Prefs_Include_Disputed__c == true && acct.Prefs_Include_Unbilled__c == false)
            IncPrefs = '*Disputed amounts are included in Net Adjustment; Underbilled amounts are NOT included';
        if (acct.Prefs_Include_Disputed__c == false && acct.Prefs_Include_Unbilled__c == true)
            IncPrefs = '*Underbilled amounts are included in Net Adjustment; Disputed amounts are NOT included';
        if (acct.Prefs_Include_Disputed__c == false && acct.Prefs_Include_Unbilled__c == false)
            IncPrefs = '*Underbilled and Disputed amounts are NOT INCLUDED in Net Adjustment';
        AuditItem__c[] audititems = new AuditItem__c[] {};

        audititems = [Select Id, Date_Of_Service__c, Audit_Dept_Code__c, Audit_Dept_Code__r.Name,
                      Bill_Charge_Code__c, Item_Description__c, Bill_Unit_Price__c, Bill_Qty__c, Bill_Total__c, Qty_MR__c, Qty_MD__c,
                      Qty_Net__c, Qty_Unbill__c, Qty_Under__c, Qty_Over__c, Qty_noMD__c, Qty_Disallowed__c, Qty_Disputed__c,
                      Qty_Adj_Other__c, MR_Flag__c, Not_Billed_Code__c, Adj_Other_Code__c, Amt_Adj__c, Amt_Disputed__c,
                      Amt_Disallowed__c, Amt_Other__c, Amt_Over__c, Amt_NoMD__c, Amt_Unbill__c, Amt_Under__c,
                      Annotation__c
                      from AuditItem__c WHERE Audit_Master__c = :audit.Id AND
                              (MR_Flag__c = true OR Not_Billed_Code__c != null OR Adj_Other_Code__c != null OR Qty_Disputed__c != 0)
                              ORDER BY Audit_Dept_Code__r.Name, Date_of_Service__c];

        genDeptTable();
        genKeyTable();

        List<aggregateResult> ardepts = [SELECT sum(Bill_Total__c) bsum,  Audit_Dept_Code__c FROM AuditItem__c WHERE Audit_Master__c = :audit.Id GROUP BY  Audit_Dept_Code__c];
        for (AggregateResult ar : ardepts) {
            Id did = (Id)ar.get('Audit_Dept_Code__c');
            Double damt = (Double)ar.get('bsum');
            tds_tot += damt;    // GRAND TOTAL for ALL depts
            String dn;
            if (did != null)
                dn = depids.get(did);
            else
                dn = '*';
            DeptTotals.put(dn, damt);
        }
        if (audit.Audit_Stage__c == 'Pending' || audit.Audit_Stage__c == 'Scheduled') {
            ExitDate = '[Audit Incomplete - Preliminary Report]';
        } else if (!String.isBlank(ExitDate)) {
            ExitDate = audit.Date_Actual_Exit__c.format('MM-dd-yy');
            // ExitDate = ExitDate.substring(0,ExitDate.indexof(' '));
        }
        Integer b_UBnum = 0;
        Integer b_OBnum = 0;
        Integer b_DSnum = 0;
        Integer b_CDnum = 0;
        Decimal b_UBamt = 0;
        Decimal b_OBamt = 0;
        Decimal b_DSamt = 0;
        Decimal b_CDamt = 0;
        String newd;

        pageSumLines = new List<BillSum[]>();
        TheSum = new BillSum[] {};
        TheDepts = new DeptSum[] {};
        BillSum b;
        d_dept = '';

        if (audititems.size() > 0) {        // Any edits at all??
            for (AuditItem__c a : audititems) {
                b = new BillSum();
                if (a.Audit_Dept_Code__c == null)
                    newd = '*';
                else
                    newd = a.Audit_Dept_Code__r.Name;
                if (d_Dept != '' && d_Dept != newd) {
                    // Dept break - create summary line
                    addTheDept(b);
                    b = new BillSum();
                }
                // Next item
                b_UBnum = 0;
                b_UBamt = 0;
                b_OBnum = 0;
                b_OBamt = 0;
                b_DSnum = 0;
                b_DSamt = 0;
                b_CDnum = 0;
                b_CDamt = 0;
                b.UBcode = '';
                b.OBcode = '';

                b.DOS = String.valueOf(a.Date_Of_Service__c);
                b.Dept = newd;
                b.ChgCode = a.Bill_Charge_Code__c;
                b.BillDesc = a.Item_Description__c;
                if (a.Qty_Disputed__c != 0) {   // New disputed handling Jan 2012
                    b_DSnum = a.Qty_Disputed__c.intValue();
                    b_DSamt = a.Amt_Disputed__c;
                    ds_ds += a.Amt_Disputed__c;
                }
                if (a.MR_Flag__c == true) {
                    if (a.Qty_MD__c > a.Bill_Qty__c) {
                        b_UBnum = a.Qty_Under__c.intValue();
                        b_UBamt = a.Amt_Under__c;
                        b.UBcode = 'U';
                        ds_und += a.Amt_Under__c;
                    } else if (a.Qty_MD__c == a.Qty_MR__c) {
                        b.OBcode = 'O';
                        b_OBnum = a.Qty_Over__c.intValue();
                        b_OBamt = a.Amt_Over__c;
                        ds_ov += a.Amt_Over__c;
                    } else {
                        b.OBcode = 'N';
                        b_OBnum = a.Qty_noMD__c.intValue() + a.Qty_Over__c.intValue();  // MUST ADD BOTH OVERCHARGE FACTORS (Jan 12)
                        b_OBamt = a.Amt_noMD__c + a.Amt_Over__c;
                        ds_md += b_OBamt;
                    }
                } else {
                    if (a.Not_Billed_Code__c != null) {
                        b.UBcode = a.Not_Billed_Code__c;    // MUST be unbilled
                        b_UBnum = a.Qty_Unbill__c.intValue();
                        b_UBamt = a.Amt_Unbill__c;
                        ds_unb += a.Amt_Unbill__c;
                    } else if (a.Adj_Other_Code__c == 'C') {
                        b_CDnum = a.Qty_Disallowed__c.intValue();
                        b_CDamt = a.Amt_Disallowed__c;
                        ds_cd += a.Amt_Disallowed__c;
                    } else {
                        if (a.Qty_Adj_Other__c > 0) {
                            b.UBcode = a.Adj_Other_Code__c; // Under?
                            b_UBnum = a.Qty_Adj_Other__c.intValue();
                            b_UBamt = a.Amt_Other__c;
                            ds_und += a.Amt_Other__c;

                        } else {
                            b.OBcode = a.Adj_Other_Code__c; // Over
                            b_OBnum = -(a.Qty_Adj_Other__c).intValue();
                            b_OBamt = -(a.Amt_Other__c);
                            ds_ov += b_OBamt;
                        }
                    }
                }
                b.UBnum = (b_UBnum == 0) ? '' : String.ValueOf(b_UBnum);
                b.UBamt = (b_UBamt == 0) ? '' : formatDollars(b_UBamt);
                b.OBnum = (b_OBnum == 0) ? '' : String.ValueOf(b_OBnum);
                b.OBamt = (b_OBamt == 0) ? '' : formatDollars(b_OBamt);
                b.DSnum = (b_DSnum == 0) ? '' : String.ValueOf(b_DSnum);
                b.DSamt = (b_DSamt == 0) ? '' : formatDollars(b_DSamt);
                b.CDnum = (b_CDnum == 0) ? '' : String.ValueOf(b_CDnum);
                b.CDamt = (b_CDamt == 0) ? '' : formatDollars(b_CDamt);
                b.Rowcls = 'itemrow';
                b.DescAlign = 'left';
                b.Annot = a.Annotation__c;

                // Dept totals
                d_Dept = b.Dept;
                d_UBnum += b_UBnum;
                d_UBamt += b_UBamt;
                d_OBnum += b_OBnum;
                d_OBamt += b_OBamt;
                d_DSnum += b_DSnum;
                d_DSamt += b_DSamt;
                d_CDnum += b_CDnum;
                d_CDamt += b_CDamt;
                addTheSum(b, false);
            }
            b = new BillSum();
            addTheDept(b);  // Last dept summary
        }

        b = new BillSum();
        b.Dept = '';    // Grand Totals
        b.DOS = '';
        b.ChgCode = '';
        b.BillDesc = 'Totals for all Departments:';
        b.UBnum = String.ValueOf(t_UBnum);
        b.UBamt = formatDollars(t_UBamt);
        b.OBnum = String.ValueOf(t_OBnum);
        b.OBamt = formatDollars(t_OBamt);
        b.DSnum = String.ValueOf(t_DSnum);
        b.DSamt = formatDollars(t_DSamt);
        b.CDnum = String.ValueOf(t_CDnum);
        b.CDamt = formatDollars(t_CDamt);
        b.UBcode = '';
        b.OBcode = '';
        b.Rowcls = 'totrow';
        b.DescAlign = 'right';
        addTheSum(b, true);
        if (linecount > 0) {    // Final page group
            pageSumLines.add(TheSum);
        }
        // Grand total for dept summary
        DeptSum s = new DeptSum();
        s.dep = 'All Depts:';
        s.tot = formatDollarsz(tds_tot);
        s.unb = formatDollarsz(tds_unb);
        s.unbp = formatPercent(tds_unb, tds_tot);
        s.und = formatDollarsz(tds_und);
        s.undp = formatPercent(tds_und, tds_tot);
        s.ov = formatDollarsz(tds_ov);
        s.ovp = formatPercent(tds_ov, tds_tot);
        s.md = formatDollarsz(tds_md);
        s.mdp = formatPercent(tds_md, tds_tot);
        s.er = formatPercent((tds_unb + tds_und + tds_ov + tds_md), tds_tot);
        s.ds = formatDollarsz(tds_ds);
        s.dsp = formatPercent(tds_ds, tds_tot);
        s.cd = formatDollarsz(tds_cd);
        s.cdp = formatPercent(tds_cd, tds_tot);
        s.net = formatDollarsz(tds_net);
        s.netp = formatPercent(tds_net, tds_tot);
        tds_rev = tds_tot + tds_net;
        s.rev = formatDollarsz(tds_rev);
        s.revp = formatPercent(tds_rev, tds_tot);
        TheDepts.add(s);
        // TEST TO FILL ARRAY
        //Integer m = dc.size()-TheDepts.size();
        //for (Integer j=0; j<m ; j++) {
        //  s = new DeptSum();
        //  s.dep = 'Test ' + String.ValueOf(j);
        //  TheDepts.add(s);
        //}

    }

    private void addTheSum(BillSum b, Boolean lastpg) {
        TheSum.add(b);
        linecount++;
        if (lastpg)
            TheSum[0].KeyCls = 'keytabon';
        if (linecount == linemax) {
            if (!lastpg)
                TheSum[0].KeyCls = 'keytaboff';
            pageSumLines.add(TheSum);   // End of page - add the page array
            TheSum = new BillSum[] {};
            linecount = 0;              // Reset for next page
            linemax = SUBSEQ_BREAKS;
        }
    }
    private void addTheDept(BillSum b) {
        b.Dept = d_Dept;
        b.DOS = '';     // Acts as flag for line
        b.ChgCode = '';
        b.BillDesc = (b.Dept == null || b.Dept == 'NO') ? 'Totals for items w/o dept code:' : b.dept + ' Deptartment Totals:';
        b.UBnum = (d_UBnum == 0) ? '' : String.ValueOf(d_UBnum);
        b.UBamt = (d_UBamt == 0) ? '' : formatDollars(d_UBamt);
        b.OBnum = (d_OBnum == 0) ? '' : String.ValueOf(d_OBnum);
        b.OBamt = (d_OBamt == 0) ? '' : formatDollars(d_OBamt);
        b.DSnum = (d_DSnum == 0) ? '' : String.ValueOf(d_DSnum);
        b.DSamt = (d_DSamt == 0) ? '' : formatDollars(d_DSamt);
        b.CDnum = (d_CDnum == 0) ? '' : String.ValueOf(d_CDnum);
        b.CDamt = (d_CDamt == 0) ? '' : formatDollars(d_CDamt);

        b.UBcode = '';
        b.OBcode = '';
        b.Rowcls = 'deptrow';
        b.DescAlign = 'right';
        addTheSum(b, false);
        t_UBnum += d_UBnum; // Accum totals
        t_UBamt += d_UBamt;
        t_OBnum += d_OBnum;
        t_OBamt += d_OBamt;
        t_DSnum += d_DSnum;
        t_DSamt += d_DSamt;
        t_CDnum += d_CDnum;
        t_CDamt += d_CDamt;
        d_UBnum = 0;
        d_UBamt = 0;
        d_OBnum = 0;
        d_OBamt = 0;
        d_DSnum = 0;
        d_DSamt = 0;
        d_CDnum = 0;
        d_CDamt = 0;

        // Create the Dept Summary entry
        DeptSum s = new DeptSum();
        ds_tot = DeptTotals.get(d_Dept);  // Tot billed for ALL ITEMS in this dept
        s.dep = d_Dept;
        s.tot = formatDollarsz(ds_tot);
        s.unb = formatDollarsz(ds_unb);
        s.unbp = formatPercent(ds_unb, ds_tot);
        s.und = formatDollarsz(ds_und);
        s.undp = formatPercent(ds_und, ds_tot);
        s.ov = formatDollarsz(ds_ov);
        s.ovp = formatPercent(ds_ov, ds_tot);
        s.md = formatDollarsz(ds_md);
        s.mdp = formatPercent(ds_md, ds_tot);
        s.er = formatPercent((ds_unb + ds_und + ds_ov + ds_md), ds_tot); // Jan 2012
        s.ds = formatDollarsz(ds_ds);
        s.dsp = formatPercent(ds_ds, ds_tot);
        s.cd = formatDollarsz(ds_cd);
        s.cdp = formatPercent(ds_cd, ds_tot);
        Decimal tad = (audit.Client_Audit_Account__r.Prefs_Include_Disputed__c == True) ? ds_ds : 0;
        Decimal dnet = (audit.Client_Audit_Account__r.Prefs_Include_Unbilled__c == True) ? (ds_unb + ds_und) - ds_ov - ds_md - ds_cd - tad : -(ds_ov + ds_md + ds_cd + tad);
        s.net = formatDollarsz(dnet);
        s.netp = formatPercent(dnet, ds_tot);
        s.rev = formatDollarsz(ds_tot + dnet);
        s.revp = formatPercent((ds_tot + dnet), ds_tot);
        TheDepts.add(s);
        // tds_tot += ds_tot;   // Grand totals
        tds_unb += ds_unb;
        tds_und += ds_und;
        tds_ov += ds_ov;
        tds_md += ds_md;
        tds_ds += ds_ds;
        tds_cd += ds_cd;
        tds_net += dnet;
        // tds_rev += (ds_tot+dnet);
        ds_tot = 0;
        ds_unb = 0;
        ds_und = 0;
        ds_ov = 0;
        ds_md = 0;
        ds_ds = 0;
        ds_cd = 0;
    }

    String formatDollarsz(Decimal num) {
        return (num == 0) ? ' ' : formatDollars(num);
    }
    String formatDollars(Decimal num) {
        String s1 = num < 0 ? '(' : '';
        String s2 = num < 0 ? ')' : '';
        String z = '00';
        String snum = String.ValueOf(Math.floor(Math.abs(num) * 100 + .5));
        if (snum.length() < 3)
            snum = z.substring(snum.length() - 1) + snum;
        String d = snum.substring(0, snum.length() - 2);
        if (d.length() > 3)
            d = d.substring(0, d.length() - 3) + ',' + d.substring(d.length() - 3);
        if (d.length() > 7)
            d = d.substring(0, d.length() - 7) + ',' + d.substring(d.length() - 7);
        return s1 + '$' + d + '.' + snum.substring(snum.length() - 2) + s2;
    }
    String formatPercent(Decimal num, Decimal div) {
        if (div == 0) {
            return (num == 0 ? ' ' : '100%');
        }
        String z = '00';
        num = Math.floor(Math.abs(num / div) * 10000 + .5); // 2 dec places
        if (num == 0)
            return ' ';
        if (num == 10000)
            return '100%';
        String snum = String.ValueOf(num);
        if (snum.length() < 3)
            snum = z.substring(snum.length() - 1) + snum;
        return (snum.substring(0, snum.length() - 2) + '.' + snum.substring(snum.length() - 2) + '%');
    }

    void genDeptTable() {
        Department__c[] ditems = [Select Id, Name, Description__c from Department__c ORDER BY Name];
        deps = new Map<String, String>();
        depids = new Map<ID, String>();
        dc = new List<ckey>();

        for (Department__c d : ditems) {
            deps.put(d.Name, d.Description__c);
            depids.put(d.Id, d.Name);
            kadd(dc, d.Name, d.Description__c);
        }
    }

    void kadd(List<ckey> cl, String cd, String ds) {
        ckey ck = new ckey();
        ck.c = cd;
        ck.d = ds;
        cl.add(ck);
    }

    void genKeyTable() {
        uc = new List<ckey>();
        oc = new List<ckey>();
        TheKeys = new KeyTab[] {};

        kadd(uc, 'U', 'Documented quantity in Medical Record');
        kadd(uc, ' ', 'is greater than quantity billed');
        kadd(uc, 'X1', 'Not Originally Billed');
        kadd(uc, 'X2', 'Change in Policy or Procedure');
        kadd(uc, 'X3', 'New to CDM');
        kadd(uc, 'X4', 'Keying Error');
        kadd(uc, 'X5', 'Departmental Error');
        kadd(uc, 'X6', 'Not Normally Billed');
        kadd(uc, 'X0', 'Level Discrepancy');
        kadd(oc, 'O', 'Not documented in Medical Record');
        kadd(oc, 'N', 'Documented, but no corresponding');
        kadd(oc, ' ', 'MD order in Medical Record');
        kadd(oc, 'M1', 'Professional Fee(s)');
        kadd(oc, 'M2', 'Technical Component Fee(s)');
        kadd(oc, 'M3', 'Bundled/UnBundled');
        kadd(oc, 'M4', 'Client Directive/Specifications');
        kadd(oc, 'M5', 'CMS Guidelines');
        kadd(oc, 'M6', 'Investigational/Focused');
        kadd(oc, 'M7', 'Split bill');
        kadd(oc, 'M8', 'Business Office Request');
        kadd(oc, 'M9', 'Gender Specific Charge');
        kadd(oc, 'M0', 'Level Discrepancy');
        kadd(oc, 'Z', 'Other (see item notations)');

        integer l = dc.size(); // TODO max of the 3 sets
        KeyTab k;

        for (Integer i = 0; i < l; i++) { // Create key table lines
            k = new KeyTab();
            k.dcode = dc[i].c;          // Dept
            k.ddesc = dc[i].d;
            if (i < uc.size()) {
                k.ucode = uc[i].c;      // Underbilled
                k.udesc = uc[i].d;
            } else {
                k.ucode = '';
                k.udesc = '';
            }
            if (i < oc.size()) {
                k.ocode = oc[i].c;      // Overbilled
                k.odesc = oc[i].d;
            } else {
                k.ucode = '';
                k.udesc = '';
            }
            TheKeys.add(k);
        }

    }

    public String getFacilityAddr() {
        if (acct.Facility_Street__c != null) {
            return (acct.Facility_Street__c + ' ' + acct.Facility_City__c + ',' + acct.Facility_State__c + ' ' + acct.Facility_Zip__c);
        } else if (acct.BillingStreet != null) {
            return (acct.BillingStreet + ' ' + acct.BillingCity + ',' + acct.BillingState + ' ' + acct.BillingPostalCode);
        } else {
            return ' ';
        }
    }
    public Double getBillDiff() {
        return (audit.TAmt_Billed__c - audit.Audit_Amount__c);
    }

    //public String getPName() {
    //    return acopy.Patient_Name__c;
    //}
    //public String getPAcct() {
    //    return acopy.Patient_Account__c;
    //}
    //public String getPDOB() {
    //    return acopy.Patient_DOB__c;
    // }
    //public String getPMR() {
    //  return acopy.Patient_MR__c;
    //}

    //public String getPNstuff() {
    //    return stuffpn;
    //}
    //public String getPAstuff() {
    //    return stuffpa;
    //}
    //public String getPBstuff() {
    //    return stuffpb;
    //}
    //public String getPMstuff() {
    //    return stuffpm;
    //}

    //@RemoteAction
    //global static String StuffIt(String pn,String pa, String pb, String pm) {
    //    AuditCaseRptExt.stuffpn=pn;
    //    AuditCaseRptExt.stuffpa=pa;
    //    AuditCaseRptExt.stuffpb=pb;
    //    AuditCaseRptExt.stuffpm=pm;
    //    return 'OK';
    // }

    public void setStuff(String p) {
        //system.debug('******************* setStuff = ' + p);
        String[] plist = p.split(':');
        stuffpn = plist[0];
        stuffpa = plist[1];
        stuffpb = plist[2];
        stuffpm = plist[3];
    }
    public PageReference StowStuff() {
        //system.debug('******************* StowStuff = ' + stuffpn);
        return null;
    }
    public String getStuff() {
        return null;
    }
    public PageReference SaveReportPage() {
        //system.debug('********* Save Report Page');
        PageReference pr = Page.AuditCaseReport;
        pr.getParameters().put('id', audit.Id);
        String fn = acct.Shortname__c + '_' + audit.Name + '_' + stuffpn + '_'; // New Filename a/o 10-12-11
        integer nb = fn.indexOf(' ');
        if (nb != -1) {
            fn = fn.substring(0, nb) + fn.substring(nb + 1); // Get rid of blank in name
        }
        if (stuffpa != null) {
            fn += stuffpa.substring(stuffpa.length() - 3);
        } else {
            fn += '###';
        }
        //pr.getHeaders().put('Content-Disposition:', 'inline; filename="'+fn+'.pdf"');
        pr.getHeaders().put('Content-Disposition:', 'attachment; filename=\'' + String.escapeSingleQuotes(fn.replace('\n', '').replace('\r', '')) + '.pdf\';');
        pr.setRedirect(false);
        return pr;
    }
    public PageReference DisplayReportPage() {
        //system.debug('********* Display Report Page');
        PageReference pr = Page.AuditCaseReport;
        pr.getParameters().put('id', audit.Id);
        pr.setRedirect(false);
        return pr;
    }

}