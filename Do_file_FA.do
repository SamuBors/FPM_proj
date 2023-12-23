set more off
clear all
scalar drop _all

*ssc install estout

cd "/Users/samueleborsini/Library/Mobile Documents/com~apple~CloudDocs/Università/Economics and econometrics/I anno/Financial products and markets/Assignment"

import excel "Bonds.xlsx", first

*--------------------------------------------------------
*----------------------Data cleaning---------------------
*--------------------------------------------------------

*dropping duplicates
duplicates report
duplicates drop

*transforming and choosing variables
gen YTM = real(YieldtoMaturity)
gen A = real(AmountIssuedUSD)
gen Co = real(Coupon)
drop YieldtoMaturity AmountIssuedUSD Coupon

encode PrincipalCurrency, gen(PC)
encode CountryofIssue, gen(C)
encode Issuer, gen(issuer)
encode Sector, gen(sector)
encode Seniority, gen(seniority)
drop Issuer Sector Seniority CountryofIssue PrincipalCurrency IssuerTicker ISIN

*panel
bysort issuer: gen T=_n
xtset issuer T

*GB dummy
gen GB =.
replace GB=1 if GreenBond=="Yes"
replace GB=0 if GreenBond=="No"
drop GreenBond

*time to maturity
gen TTM = (Maturity - IssueDate)/365
//we assume that the YTM is computed at the IssueDate

gen year=year(IssueDate)
drop Maturity IssueDate

*dropping missing value
drop if YTM==.
drop if GB==.

*dropping outliers
drop if YTM < 0
cumul YTM, generate(freqY) eq
drop if freqY >.99

*summary
gen l_A = log(A)
sum GB Co l_A YTM TTM

est clear
estpost sum GB YTM Co TTM l_A
esttab using "sumstats.tex", replace nonumber nomti cells("mean sd min max count")  collabels("Mean" "SD" "Min" "Max" "N") ///
varlabel(GB "Green bond dummy " YTM "Yield to maturity (\%)" Co "Coupon rate (\%)" TTM "Time to maturity " l_A "log of amount issued") noobs ///
prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" ///
"\begin{table}[h!]" ///
"\centering" ///
"\caption{Summary statistics}" ///
"\label{sumstats}" /// 
"\resizebox{0.7\textwidth}{!}{%" ///
"\begin{tabular}{l*{5}{c}}" ///
"\toprule") ///
postfoot("\bottomrule" ///
"\end{tabular}" ///
"}" ///
"\end{table}")

*--------------------------------------------------------
*--------------------------Panel-------------------------
*--------------------------------------------------------

est clear

eststo model1: xtreg YTM GB Co A i.seniority TTM i.year, robust fe

eststo model2: xtreg YTM GB Co i.seniority TTM i.year, robust fe

testparm i.seniority i.year

eststo model3: xtreg YTM GB Co TTM, robust fe

esttab model1 model2 model3 using "table1.tex", replace star(* 0.10 ** 0.05 *** 0.01) se nogaps nomti ///
varlabel(GB "Green bond dummy" TTM "Time to maturity (years)" Co "Coupon rate") k(GB Co TTM) ///
stats(N r2, labels("\(N\)" "\(R^2\)")) ///
prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" ///
"\begin{table}[htbp]" ///
"\centering" ///
"\caption{Regressions results fo Yield to maturity}" ///
"\label{tab1}" ///
"\begin{tabular}{l*{3}{c}}" ///
"\toprule") ///
postfoot("\bottomrule" ///
"\multicolumn{4}{l}{\footnotesize Robust standard errors in parentheses} \\" ///
"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)}" ///
"\end{tabular}" ///
"\end{table}")

*--------------------------------------------------------
*--------------------------Matching----------------------
*--------------------------------------------------------

preserve

replace Co=round(Co, 0.5)
replace TTM=round(TTM, 0.25)
gen l_amount=round(log(A),1)

by issuer Co TTM l_amount, sort: keep if _N > 1 // keep only obs that have this values repeated
bysort issuer: egen a_GB=mean(GB)
keep if a_GB > 0 & a_GB < 1 // keep only companies with both green and brown bonds

keep issuer Co TTM l_amount GB YTM // keep only vars that interest me for this

collapse (mean) YTM=YTM, by(issuer Co TTM l_amount GB)
by issuer Co TTM l_amount, sort: keep if _N > 1 // keep only obs that have this vales repeated
bysort issuer: egen a_GB=mean(GB)
keep if a_GB > 0 & a_GB < 1

ttest YTM, by(GB)

est clear
estpost ttest YTM, by(GB)
esttab using "ttest_matching.tex", replace nonumber nomti cells("mu_1 mu_2 b p") collabels("Non-green bonds" "Green bonds" "Diff." "p-value (diff.)") ///
varlabel(YTM "Yield to matutity" N "Obs.") ///
prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" ///
"\begin{table}[h!]" ///
"\centering" ///
"\caption{T-test of matched bonds}" ///
"\label{ttest}" /// 
"\resizebox{0.8\textwidth}{!}{%" ///
"\begin{tabular}{l*{5}{c}}" ///
"\toprule") ///
postfoot("\bottomrule" ///
"\end{tabular}" ///
"}" ///
"\end{table}")

restore
