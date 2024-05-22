******************import data from excel and ipolation******************
**Fatemeh Abbasian-Abyaneh
**400100338
**Project2
***part1 : Import data
cls
clear
cd "C:\Users\fardin\Desktop\Project2_99203082"
import excel "data_99203082.xlsx", sheet("project") firstrow 
destring year POP GDP GFCF GGFCE RD Employment Renewable RePerEng Labor_edu Internet ,replace force
format %17.0g POP GDP GFCF GGFCE RD Employment Renewable RePerEng Labor_edu Internet
***part2 : panel definaning
encode country, generate(country_n)
drop country
xtset country_n year 
***part3 : ipolate_epolate
foreach x of varlist POP-Internet {
ipolate `x' year , generate(`x'_ip) epolate by (country_n)
format %17.0g `x'_ip
drop `x'
rename `x'_ip `x'
}


******************Summary Statistics and correlation of variables******************
asdoc xtsum GDP-Renewable, replace fs(9) save(plot_table/tables.doc)


******************plot for comparison*****************
foreach x of varlist GDP POP GFCF GGFCE RD Employment Renewable RePerEng {
xtline `x' , overlay ylabel(#20, labsize(6-pt) angle(horizontal)) xlabel(#15, labsize(6-pt))
graph export plot_table/`x'.png, replace 
}

foreach x of varlist GDP POP GFCF GGFCE RD Employment Renewable RePerEng {
bysort year : egen `x'_ave1 = mean(`x')
xtset country_n year  
twoway scatter `x' year , msymbol(circle_hollow) || connected `x'_ave1 year , xlabel(#10, labsize(6-pt)) ylabel(#10, labsize(6-pt) angle(horizontal))
graph export plot_table/`x'_year.png, replace 
}


*****************Choice between normal or logarithm and per capita variables for regression******************
***part1 : normal variables
asdoc regress GDP GFCF GGFCE RD Employment Renewable , fs(9) save(plot_table/tables.doc)
outreg2 using plot_table/tables2.doc, replace ctitle(Model 1: GDP ) addstat("Adjusted Rsquard", e(r2_a))
***part2 : per capita variables
foreach x of varlist GDP GFCF GGFCE RD Employment Renewable Labor_edu Internet {
generate double `x'_s= `x'/POP
format %17.0g `x'_s
} 

asdoc regress GDP_s GFCF_s GGFCE_s RD_s Employment_s Renewable_s , fs(9) save(plot_table/tables.doc)
outreg2 using plot_table/tables2.doc, ctitle(Model 2: GDP/POP ) addstat("Adjusted Rsquard", e(r2_a))
***part3 : logarithm variables
foreach x of varlist GDP GFCF GGFCE RD Employment Renewable Labor_edu Internet {
generate double Ln_`x'= log(`x')
format %17.0g Ln_`x'
}
asdoc regress Ln_GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable , fs(9) save(plot_table/tables.doc)
outreg2 using plot_table/tables2.doc, ctitle(Model 3: Ln_GDP ) addstat("Adjusted Rsquard", e(r2_a))
***part4 : normal testing for variables
asdoc sktest GDP GFCF GGFCE RD Employment Renewable , fs(9) save(plot_table/tables.doc)
asdoc swilk GDP GFCF GGFCE RD Employment Renewable , fs(9) save(plot_table/tables.doc)
histogram GDP, normal
graph export plot_table/normal_GDP.png, replace 
asdoc sktest Ln_GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable , fs(9) save(plot_table/tables.doc)
asdoc swilk Ln_GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable , fs(9) save(plot_table/tables.doc)

histogram Ln_GDP, normal
graph export plot_table/normal_Ln_GDP.png, replace
***part5 : davidson Mackinnon test
regress GDP GFCF GGFCE RD Employment Renewable
predict double yhat, xb
format %17.0g yhat
regress Ln_GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable yhat

regress Ln_GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable 
predict double yhat2, xb
format %17.0g yhat2
regress GDP GFCF GGFCE RD Employment Renewable yhat2
***part6 : Mizon and Richard test
regress GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable GFCF GGFCE RD Employment Renewable
test Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable
test GFCF GGFCE RD Employment Renewable

 
*****************perfect collinearity testing******************
asdoc by country, sort : pwcorr GDP-Renewable, sig fs(9) save(plot_table/tables.doc) 


regress Ln_GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment Ln_Renewable 
estat vif


*****************stationary testing******************
***part1 : stationary test
foreach x of varlist  Ln_GDP Ln_GFCF Ln_GGFCE Ln_RD Ln_Employment RePerEng Renewable {
asdoc  xtunitroot llc `x' , fs(9) save(plot_table/tables.doc)
}
***part2 : defing the first order difference and stationary test
foreach x of varlist Ln_Renewable Ln_RD RePerEng Ln_Labor_edu Ln_Internet{
generate double `x'f1= D.`x'
format %17.0g `x'f1
} 
foreach x of varlist  Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment RePerEng Ln_Renewablef1 {
asdoc  xtunitroot llc `x' , fs(9) save(plot_table/tables.doc)
}
***part3 : regression with stationary series
regress Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1


*****************Random effect & fixed effect ******************
xtreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 , fe
est store fereg
xtreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 , re
est store rereg
hausman fereg rereg


*****************LSDV & fixed effect & Random effect ******************
reg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 i.country_n
outreg2 using plot_table/tables3.doc, replace ctitle(Model 1: LSDV ) addstat("Adjusted Rsquard", e(r2_a))
xtreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 , fe
outreg2 using plot_table/tables3.doc, ctitle(Model 2: Fixed effect ) addstat("Adjusted Rsquard", e(r2_a))
xtreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 , re
outreg2 using plot_table/tables3.doc, ctitle(Model 3: Random effect ) 


*****************between estimator & fixed effect & pooled regression ******************
reg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1
outreg2 using plot_table/tables4.doc, replace ctitle(Model 1: Pooled ols ) addstat("Adjusted Rsquard", e(r2_a))
xtreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 , fe
outreg2 using plot_table/tables4.doc, ctitle(Model 2: Fixed effect ) addstat("Adjusted Rsquard", e(r2_a))
xtreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 , be
outreg2 using plot_table/tables4.doc, ctitle(Model 3: Between ) addstat("Adjusted Rsquard", e(r2_a))



*****************homoskedasticity testing for errors(residuals)******************
reg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 i.country_n
estat hettest 


*****************omitted variable testing******************
reg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 i.country_n
estat ovtest

 
*****************exogenous testing and IV estimator******************
reg Ln_RDf1 Ln_GFCF Ln_GGFCE Ln_Employment Ln_Renewablef1 i.country_n
predict residual2, resid
format %17.0g residual2
reg Ln_GDP Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1 residual2 i.country_n 
test residual2

xtivreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_Employment Ln_Renewablef1 (Ln_RDf1 = Ln_Labor_eduf1 Ln_Internetf1), fe
outreg2 using plot_table/tables5.doc, ctitle(Model 1: FE_IV ) 


*****************Significant testing******************
xtivreg Ln_GDP Ln_GFCF Ln_GGFCE Ln_Employment Ln_Renewablef1 (Ln_RDf1 = Ln_Labor_eduf1 Ln_Internetf1), fe
test Ln_GFCF Ln_GGFCE Ln_RDf1 Ln_Employment Ln_Renewablef1


******************Export data******************
save "final_data_400100338.dta", replace




