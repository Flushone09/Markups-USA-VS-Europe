/*Definir les 3 librairies (2 sources et 1 pour les resultats)*/
Libname EU "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup" ;
Libname AM "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\ameco3" ;
Libname in "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\Résultats" ;
/************************************************** IMPORTER LES DATA 
***************************************************************************
/
/*AMECO : Data pour calculer les couts en capital : rt = Pi[(I_reel + 
Delta)]*/
/*Deflateur de l'investissement*/
Proc import out = Pi
Datafile = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\ameco3\Price.xlsx"
Dbms = xlsx replace ;
Getnames = Yes ;
Run ;
/*Taux d'interet reel LT*/
Proc import out = Ir
Datafile = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\ameco3\Real LT interest rates.xlsx"
Dbms = xlsx replace ;
Getnames = Yes ;
Run ;
Proc sort data = Pi ; by country;
Run;
Proc sort data = Ir ; by country;
Run;
Proc transpose data = Pi Out = Pi (Rename= (col1=Pi _LABEL_=Annee) 
drop=_NAME_);
by country ;
var _: ;
Run;
Proc transpose data = Ir Out = Ir (Rename= (col1=Ir _LABEL_=Annee) 
drop=_NAME_);
by country ;
var _: ;
Run;
Proc sort data = Pi; by annee;run;
Proc sort data = Ir; by annee;
Run;

Data Rt ; Merge Pi Ir;
By annee ;
Run;
Data Rt; set Rt;
Ir = Ir * 0.01 ;
Pi = Pi * 0.01 ;
Run;
/*Créons les différents niveaux de taux de dépreciation*/
/*Certaines variables sont en texte, mettons les en numérique avec char = 
char * 1 */
Data Rt ; set Rt ;
t = Annee * 1 ;
rt_5 = Pi * (Ir + 0.05) ;
rt_8 = Pi * (Ir + 0.08) ;
rt_10 = Pi * (Ir + 0.10) ;
Drop Annee;
Run;
Data Rt; Set Rt;
Select(Country);
when ("Austria","Belgium","Italy","Finland","France","Germany") id_country = 
lowcase(substr(Country, 1, 3));
when ("Spain") 
id_country = "esp" ;
when ("Netherlands") 
id_country = "nld" ;
when ("United States") 
id_country = "usa" ;
otherwise delete;
end;
Run;
Proc sort Data = Rt;
By id_country t;
Run;
/*EU KLEMS : Data sur les pays*/
/*Créer macrovariable*/
/*Pays*/
%let pays = aus#bel#esp#ita#fin#fra#ger#nld#usa ; /*Normalement des 
espaces mais le # est utile car aucun nom de fichier n'en contient*/
%put pays : &pays ;
/*Feuilles du fichier escel : les variables */
%let sheet = GO#II#COMP#CAP_QI ;
%put sheet: &sheet ;
/*Créer macro de comptage avec Count(var, dlm)*/
%let nb_pays = %sysfunc(countw(&pays,"#")) ; /*SAS compte le nombre 
d'arguments*/
%put nb_pays : &nb_pays ;
%let nb_sheet = %sysfunc(countw(&sheet,"#")) ;
%put nb_sheet : &nb_sheet ;
/*pour desactiver les message de la LOG */
options mlogic nonotes ; /*options notes ;*/

/*Macro d'importation : boucle de feuilles insérer dans boucle de fichier 
*/
%macro import ;
%do i = 1 %to &nb_pays ; /*Macro boucle sur les pays : de 1 à nb_pays 
définit juste avant */
%do j = 1 %to &nb_sheet ; /*Macro boucle sur les feuilles */
%let pays_imp = %scan(&pays , &i, "#") ; /* la fonction Scan 
va 'lire" les i pays à importer */
%let sheet_imp = %scan(&sheet, &j, "#") ;
%put &pays_imp ; /*On affiche dans la log juste pour verifier 
qu'il a bien reconnu les différent pays */
%put &sheet_imp ;
Proc import out = &pays_imp.&sheet_imp /* . pour indiquer 
la fin du nom de la macrovariable*/
Datafile = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\EU KMLEs\&pays_imp._output_17ii.xlsx"
Dbms = xlsx replace ;
Sheet = &sheet_imp ;
Run ;
%end;
%end ;
%mend ;
/*Lancer la macro */
%import ;
/********************************* ISOLER LES INFORMATIONS 
*********************************************************/
/* On veut :
-Enlever les dates inexploitables
-Trier par description avant de transposer
-Transposer
-Selection des 50 secteurs
-Change type Annee en t
-Trie par t */
%let table = AusGO#AusII#AusCOMP#AusCAP_QI#BelGO#BelII#BelCOMP#BelCAP_QI#EspGO#EspII#EspCOMP#EspCAP_QI#FinGO#FinII#FinCOMP#FinCAP_QI#FraGO#FraII#FraCOMP#FraCAP_QI#GerGO#GerII#GerCOMP#GerCAP_QI#NldGO#NldII#NldCOMP#NldCAP_QI#UsaGO#UsaII#UsaCOMP#UsaCAP_QI#itaGO#itaII#itaCOMP#itaCAP_QI#;
%put table : &table ;
%let nb_table = %sysfunc(countw(&table,"#")) ;
%put nb_table : &nb_table ; /*32 tables*/

%let name=GO#COMP#CAP_QI#II;
%let nbname= %sysfunc(countw(&name,"#"));
%put nbname : &nbname;
/* Enlever les années inexploitables*/
%macro drop; 
%do n = 1 %to &nb_table ;
%let table_e1 = %scan(&table , &n, "#") ;
%put &table_e1 ;
%do a=1 %to &nbname ;
%let nom=%scan(&name,&a,"#");
%put nom : &nom ;
%do an=1970 %to 1979;
Data &table_e1 ; set &table_e1 ;
drop &nom&an ;
%end;
%end;
%end;
run;

%mend;
%drop;
%macro sec;
%do n = 1 %to &nb_table ;
%let table_e1 = %scan(&table , &n, "#") ;
%put &table_e1 ;
Data &table_e1 ; set &table_e1 ;
if code = "F" then code = "45" ;
else if code = "H" then code = "55" ;
else if code = "L" then code = "75" ;
else if code = "M-N" then code = "80-85" ;
else if code ="D-E" then code ="40-41";
%end;
Run;
%mend;
%sec;
/* on doit trier pour transposer*/
%macro sort;
%do n = 1 %to &nb_table ;
%let table_e1 = %scan(&table , &n, "#") ;
%put &table_e1 ;
Proc sort data = &table_e1;
by desc;
Run;
%end;
%mend;
%sort ;
/* traiter l'erreur de sortage*/ 

%macro fra(tab) ; 
data &tab; set &tab;
if _N_ < 9 then delete; 
run;
%mend ; 
%fra (fraii);
%fra (frago); 
%fra (fracap_qi); 
%fra (fracomp);
/* on doit trier pour transposer*/
%macro transpose2 ;
%do n = 1 %to &nb_table ;
%let table_e1 = %scan(&table , &n, "#") ;
%put &table_e1 ;
proc transpose data = &table_e1 out = 
&table_e1 (Rename=(col1=variable _LABEL_= Annee) drop=_NAME_);
by desc code;
var : ;
%end
Run ;
%mend;
%transpose2;
%macro num ;
%do n = 1 %to &nb_table ;
%let table_e1 = %scan(&table , &n, "#") ;
%put &table_e1 ;
%do a=1 %to &nbname ;
%let nom=%scan(&name,&a,"#");
%put nom : &nom ;
data &table_e1; set &table_e1 ;
t = input(compress(annee,"&name"), 8.);
%end;
%end;
run;
%mend;
%num;
%macro sort;
%do n = 1 %to &nb_table ;
%let table_e1 = %scan(&table , &n, "#") ;
%put &table_e1 ;
Proc sort data = &table_e1 ;
by t;
Run;
%end;

%mend;
%sort;

%macro modification ;
%do n = 1 %to &nb_table ;
%let table_e1 = %scan(&table , &n, "#") ;
%put &table_e1 ;
/* on doit trier pour transposer*/
Proc sort data = &table_e1;
by desc;
Run;
/*on transpose et on indique la variable*/
proc transpose data = &table_e1 out = 
&table_e1(Rename=(col1=variable _LABEL_= Annee) drop=_NAME_) ;
by desc code;
var _: ;
Run ;
/*Conserver les 50 secteurs */
Data &table_e1 ; Set &table_e1;
If code in("15","16-18","19",
"20-21","22-23","24-25","26-27","28""29-30""31-33",
"34","35","36","37","40-41","45",
"50","51","52","55","60","61","62",
"63","64","65","66","67","70","71",
"72","73","74","75","80","85","90",
"91","92","93");
Run ; 
/*On change la variable annee */
data &table_e1; set &table_e1 ;
t = substr(Annee, 3,6)* 1;
drop Annee;
Run;
/* On trie par annee*/
Proc sort data = &table_e1 ;
by t;
Run;
%end ;
%mend ;
%modification ;
/**************************************** FUSIONNER PAR PAYS 
****************************************************/
/*On commence par définir les variables correspondantes*/
%let table_GO = AusGO#BelGO#EspGO#ItaGO#FinGO#FraGO#GerGO#NldGO#UsaGO;
%let table_II = AusII#BelII#EspII#ItaII#FinII#FraII#GerII#NldII#UsaII;
%let table_COMP = AusCOMP#BelCOMP#EspCOMP#ItaCOMP#FinCOMP#FraCOMP#GerCOMP#NldCOMP#UsaCOMP;
%let table_CAP_QI = AusCAP_QI#BelCAP_QI#EspCAP_QI#itaCAP_QI#FinCAP_QI#FraCAP_QI#GerCAP_QI#NldCAP_QI#UsaCAP_QI;
%put table_GO : &table_GO ;
%put table_II : &table_II ;
%put table_COMP : &table_COMP ;
%put table_CAP_QI : &table_CAP_QI ;
%let nb_table_GO = %sysfunc(countw(&table_GO,"#"));
%put nb_table_GO : &nb_table_GO ;
%let nb_table_II = %sysfunc(countw(&table_II,"#"));
%put nb_table_II : &nb_table_II ;
%let nb_table_COMP = %sysfunc(countw(&table_COMP,"#"));
%put nb_table_COMP : &nb_table_COMP ;
%let nb_table_CAP_QI = %sysfunc(countw(&table_CAP_QI,"#"));
%put nb_table_CAP_QI : &nb_table_CAP_QI ;
%macro etape2_1;
%do k = 1 %to &nb_table_GO ;
%let table_GO_n = %scan(&table_GO , &k, "#") ;
%put &table_GO_n ;
/* On donne le nom à la variable*/
Data &table_GO_n ; set &table_GO_n;
Rename variable = GO ;
Run;
%end ;
%mend ;
%macro etape2_2;
%do l = 1 %to &nb_table_II ;
%let table_II_n = %scan(&table_II , &l, "#") ;
%put &table_II_n ;
/* On donne le nom à la variable*/
Data &table_II_n ; set &table_II_n;
Rename variable = II ;
Run;
%end ;
%mend ;
%macro etape2_3;
%do m = 1 %to &nb_table_COMP ;
%let table_COMP_n = %scan(&table_COMP , &m, "#") ;
%put &table_COMP_n ;
/* On donne le nom à la variable*/
Data &table_COMP_n ; set &table_COMP_n;
Rename variable = COMP ;
Run;
%end ;
%mend ;
%macro etape2_4;
%do p = 1 %to &nb_table_CAP_QI ;
%let table_CAP_QI_n = %scan(&table_CAP_QI , &p, "#") ;
%put &table_CAP_QI_n ;
/* On donne le nom à la variable*/
Data &table_CAP_QI_n ; set &table_CAP_QI_n;
Rename variable = CAP_QI ;
Run;
%end ;
%mend ;
%etape2_1; /* GO pour les ptQt*/
%etape2_2; /* II pour les mtMt*/
%etape2_3; /* COMP pour les wtNt*/
%etape2_4; /* CAP_QI pour les Kt*/
/*Maintenant, réunissons les feuilles pour obtenir une table par pays */
%macro pays;
%do i = 1 %to &nb_pays ;
%let pays_imp = %scan(&pays , &i, "#") ; 
%put &pays_imp ;
/* Jointure SQL mutlitable */
Proc SQL;
Create Table &pays_imp As
Select &pays_imp.GO.*, &pays_imp.II.II, 
&pays_imp.COMP.COMP, &pays_imp.CAP_QI.CAP_QI
From &pays_imp.GO LEFT JOIN &pays_imp.II
ON &pays_imp.GO.code=&pays_imp.II.code AND 
&pays_imp.GO.t=&pays_imp.II.t
LEFT JOIN &pays_imp.COMP
ON &pays_imp.II.code=&pays_imp.COMP.code AND 
&pays_imp.II.t=&pays_imp.COMP.t
LEFT JOIN &pays_imp.CAP_QI
ON &pays_imp.COMP.code=&pays_imp.CAP_QI.code AND 
&pays_imp.COMP.t=&pays_imp.CAP_QI.t
Group by &pays_imp.GO.code, &pays_imp.GO.t
;
Quit;
/* definir id_coutry et les variables en informat numéric 
*/
Data &pays_imp ; set &pays_imp ;
id_country = "&pays_imp" ;
ptQt = input(GO, numx.) ;
mtMt = input(II, numx.) ;
wtNt = input(COMP, numx.) ;
Kt = input(CAP_QI, numx.);
Drop GO II COMP CAP_QI ;
Run;
/* Ordonner les variables */
Data &pays_imp;
Retain desc code id_country t ptQt mtMt wtNt Kt ;
Set &pays_imp;
Run;
%end ;
%mend ;
%pays;
/****************************************** TABLE COMPLETE 
*****************************************************/
/*Regrouper l'information*/
Data Area ; Set aus bel esp ita ger fra fin nld usa ;
Run;
data Area  ; set in.Area; run;
data area ; set area ; drop Annee; run; 
/* Enrichir la table avec le Rt*/
Proc sql ;
Create Table Area_b AS
Select Area.*, Rt.rt_5, Rt.rt_8, Rt.rt_10
From Area INNER JOIN Rt
On Area.id_country=Rt.id_country And Area.t=Rt.t
;
Quit ;
/* Ajouter le Type de secteur*/
Data Area_b ; set Area_b ;
If code < 50 Then type = "Manufacturing & Construction";
Else type = "Services" ;
Run;
/*Créer les variables des équations*/
/* Croissance = Xt - Xt-1 , les lag donnent le X-1 */
Data Area_b ; Set Area_b ;
d_ptQt = log(ptQt) - lag(log(ptQt)) ;
d_mtMt = log(mtMt) - lag(log(mtMt)) ;
d_wtNt = log(wtNt) - lag(log(wtNt)) ;
d_Kt = log(Kt) - lag(log(Kt)) ;
d_rt_5 = log(rt_5) - lag(log(rt_5)) ; /* 5%*/
d_rt_8 = log(rt_8) - lag(log(rt_8)) ; /* 8%*/
d_rt_10 = log(rt_10) - lag(log(rt_10)); /* 10%*/
Run;
/*Ensuite pour le Capital, selon l'equation : d_rtKt = (d_rt + d_Kt) */
Data Area_b ; Set Area_b ;
d_rtKt_5 = ( d_rt_5 + d_Kt );
d_rtKt_8 = ( d_rt_8 + d_Kt );
d_rtKt_10 = ( d_rt_10 + d_Kt );
Run;
/*Enfin les parts */
Data Area_b ; set Area_b ;
a_Mt = (mtMt / ptQt) ;
a_Nt = (wtNt / ptQt) ;
a_Kt = (1 - a_Nt - a_Mt) ;
Run;
/*Créer Yt et Xt pour appliquer l'équation (5) */
Data Area_b ; Set Area_b ;
Yt_5 = d_ptQt - (a_Mt * d_mtMt) - (a_Nt * d_wtNt) - (a_Kt * d_rtKt_5) ;
Yt_8 = d_ptQt - (a_Mt * d_mtMt) - (a_Nt * d_wtNt) - (a_Kt * d_rtKt_8) ;
Yt_10 = d_ptQt - (a_Mt * d_mtMt) - (a_Nt * d_wtNt) - (a_Kt * d_rtKt_10) ;
Xt_5 = ( d_ptQt - d_rtKt_5 ) ;
Xt_8 = ( d_ptQt - d_rtKt_8 ) ;
Xt_10 = ( d_ptQt - d_rtKt_10 ) ;
Run;
/*Ayant créé un décalage, il faut aussi le faire pour les pays*/
/* Sinon la derniere variable d'une pays et la 1ere d'un autre serait liées 
ATTENTION */
Data Area_b ; Set Area_b ;
lag_country = lag(id_country) ;
lag_code = lag(code) ;
Run;
Data Area_b ; Set Area_b ;
If code NE lag_code Then Do Yt_5 = . ; End ;
If code NE lag_code Then Do Yt_8 = . ; End ;
If code NE lag_code Then Do Yt_10 = . ; End ;
If code NE lag_code Then Do Xt_5 = . ; End ;
If code NE lag_code Then Do Xt_8 = . ; End ;
If code NE lag_code Then Do Xt_10 = . ; End ;
Run;
Data Area_b ; set Area_b ;
desc = lowcase(desc);
Run;
/*Créer les tables finales avec Yt et Xt*/
Data FINALE_5 ; Set Area_b ;
Keep desc code type id_country t Yt_5 Xt_5 ;
Run;
Data FINALE_8 ; Set Area_b ;
Keep desc code type id_country t Yt_8 Xt_8 ;
Run;
Data FINALE_10 ; Set Area_b ;
Keep desc code type id_country t Yt_10 Xt_10 ;
Run;
/* DECOUPAGE EN 2 PERIODES */
/* Periode 1981-1992*/
Data Finale_5_P1 ; Set Finale_5;
where t < 1993 ;
Run;
Data Finale_8_P1 ; Set Finale_8;
where t < 1993 ;
Run;
Data Finale_10_P1 ; Set Finale_10;
where t < 1993 ;
Run;
/*Periode 1993 -2006/2007 */
Data Finale_5_P2 ; Set Finale_5;
where t > 1992 ;
Run;
Data Finale_8_P2 ; Set Finale_8;
where t > 1992 ;
Run;
Data Finale_10_P2 ; Set Finale_10;
where t > 1992 ;
Run;
/*Pour simplifier, on va renommer les X et Y indicés _taux_periode en X et 
Y */
%let finales = Finale_5#Finale_8#Finale_10#Finale_5_p1#Finale_8_p1#Finale_10_p1#Finale_5_p2#Finale_8_p2#Finale_10_p2 ;
%put finales : &finales ;
%let nb_finales = %sysfunc(countw(&finales,"#")) ;
%put nb_finales : &nb_finales ; /*9 tables*/
%let degré = _5#_8#_10 ;
%put degré : &degré ;
%let nb_degré = %sysfunc(countw(&degré,"#")) ;
%put nb_degré : &nb_degré ; /*3 degrés*/
/*Aussi, on remarque qu'il y a beaucoup de valeurs manquantes ce qui ne 
servira pas au estimations
On supprime donc les secteurs dont les Yt et Xt sont égals à VALEUR 
MANQUANTE . */
%macro rename ;
%do zi = 1 %to &nb_finales ;
%do zj = 1 %to &nb_degré ;
%let finales_named = %scan(&finales , &zi, "#") ;
%let degré_named = %scan(&degré , &zj, "#") ;
%put &finales_named ;
%put &degré_named ;
/*Renommer les Y et X pour se faciliter*/
Data &finales_named ; Set &finales_named ;
Rename Yt&degré_named = Y Xt&degré_named = X ;
Run;
%end;
%end;
%mend ;
%rename;

/************************************* MCO POUR OBTENIR LES BETAS 
*********************************************************/
/*On remarque qu'il y a beaucoup de valeurs manquantes ce qui ne servira 
pas au estimations
On supprime donc les secteurs dont les Yt et Xt sont égals à VALEUR 
MANQUANTE . */
%macro Dropvaleursmanquantes ;
%do zi = 1 %to &nb_finales ;
%let finales_estim = %scan(&finales , &zi, "#") ;
%put &finales_estim ;
/* Si Y est . on supprimer */
Data &finales_estim ; set &finales_estim ;
If Y EQ "." then delete;
Run;
%end;
%mend ;run;

%Dropvaleursmanquantes ;
/*Avec les différentes tables correspondants aux différents taux et au 
différente periodes, afin d'obtenir
Pour la periode GLOBALE, P1 et P2 on utlise une macro*/
/*Attention, il faut trier les tables par la variable par laquelle on 
souhaite regresser*/
/* A - ESTIMATIONS PAS PAYS PAR SECTEUR */
/* La c'est le plus intéréssant avec grande table détaillée*/
%macro MCOparpaysetparsecteur ;
%do zi = 1 %to &nb_finales ;
%let finales_estim = %scan(&finales , &zi, "#") ;
%put &finales_estim ;
/*Estimation des beta par pays*/
Proc sort data = &finales_estim ;
By id_country code ;
Run;
ODS SELECT NONE ;
ODS OUTPUT ParameterEstimates = 
BETA_&finales_estim._PAYS_SECTEUR ;
Proc Reg Data = &finales_estim ;
Model Y = X / noint white ; 
By id_country code ;
Run;

Quit;
ODS SELECT ALL ;
%end;
%mend ;
%MCOparpaysetparsecteur;
/* B - ESTIMATIONS PAR PAYS ET PAR TYPE D'ACTIVITE */
%macro MCOparpaysetparcodeetpartype ;
%do zi = 1 %to &nb_finales ;
%let finales_estim = %scan(&finales , &zi, "#") ;
%put &finales_estim ;
/*Estimation des beta par pays par secteur par type*/
Proc sort data = &finales_estim ;
By id_country code type ;
Run;
ODS SELECT NONE ;
ODS OUTPUT ParameterEstimates = BETA_&finales_estim._PAYS_TYPE 
;
Proc Reg Data = &finales_estim ;
Model Y = X / noint white ; 
By id_country code type ;
Run;
Quit;
ODS SELECT ALL ;
%end;
%mend ;
%MCOparpaysetparcodeetpartype;
/******************************************* ESTIMATION DES MARKUPS 
******************************************/
%let betas = 5_PAYS_SECTEUR#8_PAYS_SECTEUR#10_PAYS_SECTEUR#5_p1_PAYS_SECTEUR#8_p1_PAYS_SECTEUR#10_p1_PAYS_SECTEUR#5_p2_PAYS_SECTEUR#8_p2_PAYS_SECTEUR#10_p2_PAYS_SECTEUR#5_PAYS_TYPE#8_PAYS_TYPE#10_PAYS_TYPE#5_p1_PAYS_TYPE#8_p1_PAYS_TYPE#10_p1_PAYS_TYPE#5_p2_PAYS_TYPE#8_p2_PAYS_TYPE#10_p2_PAYS_TYPE;
%put betas : &betas ;
%let nb_betas = %sysfunc(countw(&betas,"#")) ;
%put nb_betas : &nb_betas ; /*18 tables*/
%macro Markup ;
%do zz = 1 %to &nb_betas ;
%let betas_estim = %scan(&betas , &zz, "#") ;
%put &betas_estim ;
/*Estimations des Markup */
Data Markup_&betas_estim ; Set Beta_Finale_&betas_estim ;
Markup = 1/(1 - Estimate) ;
Markup = round(Markup,0.01);
Rename id_country = Pays Estimate = Beta_chapeau ;

Drop Model Dependent Variable HCCMethod ;
/*If Markup = 1 then delete ; Si on fait avec une constante */
Run;
%end;
%mend ;
%Markup;
/************************************** STATS DESCRIPTIVES 
**********************************************************/
/* MARKUPS MOYEN (estimé par pays avec means) */
%let taux = 5#8#10 ;
%put taux : &taux ;
%let nb_taux = %sysfunc(countw(&taux,"#")) ;
%put nb_taux : &nb_taux ; /* 3 tables*/
%macro Markups_moyens ;
%do a = 1 %to &nb_taux ;
%let taux_estim = %scan(&taux , &a, "#") ;
%put &taux_estim;
Data Markup_Moyen_&taux_estim ; Set 
Markup_&taux_estim._pays_secteur ;
keep Pays code Markup;
Run;
/* Attention va créer des doublons */
Proc SQL;
Create Table Markup_Moyen_&taux_estim As
Select Markup_Moyen_&taux_estim..*, Area_b.desc
From Markup_Moyen_&taux_estim INNER JOIN Area_b
ON Markup_Moyen_&taux_estim..code = Area_b.code
;
Quit;
/*Supprimer les doublons*/
Proc SQL;
Create table Markup_Moyen_&taux_estim As
Select DISTINCT * 
From Markup_Moyen_&taux_estim 
;
Quit;
ODS RTF File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\Proc 
Means Markup_Moyen_&taux_estim..rtf" ;
Proc means Data = Markup_Moyen_&taux_estim;
by Pays;
Run;
ODS RTF Close;
%end;
%mend ;
%Markups_moyens ;
/***************************** PAR SECTEUR PAR PAYS
****************************************/

/* Objectif : sortir les annexes */
%let markups = 5#5_p1#5_p2#8#8_p1#8_p2#10#10_p1#10_p2 ;
%put markups : &markups ;
%let nb_markups = %sysfunc(countw(&markups,"#")) ;
%put nb_markups : &nb_markups ; /*9 tables*/
;
%macro Resultats ;
%do jj = 1 %to &nb_markups ;
%let markups_estim = %scan(&markups , &jj, "#") ;
%put &markups_estim ;
/*Feuille d'annexe à part */
Data Annexe_&markups_estim ; Set 
Markup_&markups_estim._pays_secteur ;
keep Pays code Markup;
Run;
/* On ne garde pas EU */
Data Annexe_&markups_estim ; set Annexe_&markups_estim ;
If Pays EQ "eur" then delete;
Run;
/* Attention va créer des doublons */
Proc SQL;
Create Table Annexe_&markups_estim As
Select Annexe_&markups_estim..*, Area_b.desc
From Annexe_&markups_estim INNER JOIN Area_b
ON Annexe_&markups_estim..code = Area_b.code
;
Quit;
/*Supprimer les doublons*/
Proc SQL;
Create table Annexe_&markups_estim As
Select DISTINCT * 
From Annexe_&markups_estim 
;
Quit;
/*Trier avant de transposer*/
Proc Sort Data = Annexe_&markups_estim ; 
By code desc ;
Run;
/*Pour avoir Markup par secteur par pays*/
Proc Transpose Data= Annexe_&markups_estim Out = 
Annexe_&markups_estim._tableau ;
By code desc ;
Var Markup ;
Run;
Data Annexe_&markups_estim._tableau ; Set 
Annexe_&markups_estim._tableau ;
Rename 
 COL1 = Austria
 COL2 = Belgium
 COL3 = Spain
 COL4 = Finland
 COL5 = France

 COL6 = Germany
 COL7 = Netherlands
 COL8 = USA ;
Drop _NAME_;
Run;
%end;
%mend ;
%Resultats;
/** Sortir les annexes **/
%macro Annexes ;
%do jj = 1 %to &nb_markups ;
%let markups_estim = %scan(&markups , &jj, "#") ;
%put &markups_estim ;
ODS RTF FILE = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\Markup 
par Secteurs par Pays (pour &markups_estim).rtf" ;
OPTIONS NODATE NONUMBER ; /*sinon affiche date creation et 
pagination */
PROC REPORT DATA = Annexe_&markups_estim._tableau
STYLE(REPORT) = [ background = white
 bordercolor = white
 borderwidth = .2 cm ]
STYLE(HEADER) = [ background = white
 font_size = 9 pt
 font_weight = medium ]
STYLE(COLUMN) = [ font_size = 9 pt ]
;
COLUMN code desc Austria Belgium Spain 
 code desc Finland France Germany
 code desc Italy Netherlands USA ;
 DEFINE Code / CENTER STYLE(COLUMN)=[cellwidth = 1.5 cm] 
;
 DEFINE desc / LEFT STYLE(COLUMN)=[cellwidth = 
11 cm] DISPLAY "Sector";
 DEFINE Austria / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
 DEFINE Belgium / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
 DEFINE Spain / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
ODS TEXT = "";
DEFINE Finland / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
 DEFINE France / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
 DEFINE Germany / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
ODS TEXT = "";
 DEFINE Italy / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
DEFINE Netherlands / CENTER STYLE(COLUMN)=[cellwidth = 2 cm] 
;
DEFINE USA / CENTER STYLE(COLUMN)=[cellwidth = 
2 cm] ;

RUN;
RUN;
ODS RTF CLOSE ;
%end;
%mend ;
%Annexes;
/* PAR SECTEUR POUR USA ET EU (pour periode globale)*/
%let comparaison = _5#_8#_10 ;
%put comparaison : &comparaison ;
%let nb_comparaison = %sysfunc(countw(&comparaison,"#")) ;
%put nb_comparaison : &nb_comparaison ; /* 3 tables*/
%macro EUvsUSA ;
%do ii = 1 %to &nb_comparaison ;
%let comparaison_EUvsUSA = %scan(&comparaison , &ii, "#") ;
%put &comparaison_EUvsUSA ;
/*Isoler les données */
Data Type&comparaison_EUvsUSA ; set 
Markup&comparaison_EUvsUSA._pays_type ;
keep Pays code type Markup;
Run;
/*Eliminer pour comparer juste EU et USA*/
Data Type&comparaison_EUvsUSA ; set Type&comparaison_EUvsUSA;
If Pays in("eur","usa");
Run;
/*Créer les deux tables EU et USA*/
Data Type&comparaison_EUvsUSA._eur ; set 
Type&comparaison_EUvsUSA;
If Pays EQ "usa" then delete;
Run;
Data Type&comparaison_EUvsUSA._usa ; set 
Type&comparaison_EUvsUSA;
If Pays EQ "eur" then delete;
Run;
/*EXPORTER SOUS EXCEL*/
ODS Excel File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\EU 
vs USA (Type&comparaison_EUvsUSA).xlsx";
Proc Print Data = Type&comparaison_EUvsUSA._eur Noobs ;
Run;
Proc Print Data = Type&comparaison_EUvsUSA._usa Noobs ;
Run;
ODS Excel Close;
%end;
%mend ;
%EUvsUSA ;
/*Markup moyen par type EU vs USA */
%let table = Type_5#Type_8#Type_10 ;
%put table : &table ;
%let nb_table = %sysfunc(countw(&table,"#")) ;
%put nb_table : &nb_table ; /* 3 tables*/
%macro EUvsUSA_type ;
%do t = 1 %to &nb_table ;
%let table_type = %scan(&table , &t, "#") ;
%put &table_type;
ODS RTF File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\EU VS USA pour 
&table_type..rtf" ;
Proc means Data = &table_type._eur;
by type;
Run;
Proc means Data = &table_type._usa;
by type;
Run;
ODS RTF Close;
%end;
%mend ;
%EUvsUSA_type ;
/* Faire les markup moyen par types selon les pays pour 8%*/
ODS RTF File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\Type moyens par 
pays 8.rtf" ;
Proc means Data = Markup_8_pays_type;
by Pays type;
Run;
Ods Rtf Close;
/*Markup moyen par pays entre p1 et p2*/
ODS RTF File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\Proc means par 
pays p1 (8).rtf" ;
Proc means Data = Markup_8_p1_pays_type;
by Pays;
Run;
Ods Rtf Close;
ODS RTF File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\Proc means par 
pays p2 (8).rtf" ;
Proc means Data = Markup_8_p2_pays_type;
by Pays;
Run;
Ods Rtf Close;
/*Les markups moyens par secteur*/
ODS RTF File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\Markups moyens par 
secteurs (8).rtf" ;
Proc means Data = Annexe_8;
by code;
Run;
Ods Rtf Close;
/*Les markups moyens sur la periode*/
Proc Sort Data = Annexe_8 ;
by Markup ;
Run;
ODS RTF File = "D:\mes cours\mes Cours créteil\Master\Projet mémoire\Markup\code essaye\resultat\Markups moyen.rtf"
;
Proc means Data = Annexe_8;
Run;
Ods Rtf Close;
/*Proc Datasets Kill lib = work memtype = data ;
Run;*/
/* sert à vider la work en effacant les datas - sort une print de la tache 
effectuée
permet aussi de modifier certaines options de table ou des noms de 
variables*
