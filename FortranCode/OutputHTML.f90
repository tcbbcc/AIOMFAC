!****************************************************************************************
!*   :: Purpose ::                                                                      *
!*   Create an output file in HTML markup format with an overall mixture data header    *
!*   and individual tables for all components / species (in case of ions).              *
!*   This output format is used for showning the results on the AIOMFAC-web webpage.    *   
!*                                                                                      *
!*   :: Author & Copyright ::                                                           *
!*   Andi Zuend, (andi.zuend@gmail.com)                                                 *
!*   Dept. Atmospheric and Oceanic Sciences, McGill University (2013 - present)         *
!*                                                                                      *
!*   -> created:        2011                                                            *
!*   -> latest changes: 2019/09/24                                                      *
!*                                                                                      *
!*   :: License ::                                                                      *
!*   This program is free software: you can redistribute it and/or modify it under the  *
!*   terms of the GNU General Public License as published by the Free Software          *
!*   Foundation, either version 3 of the License, or (at your option) any later         *
!*   version.                                                                           *
!*   The AIOMFAC model code is distributed in the hope that it will be useful, but      *
!*   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or      *
!*   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more      *
!*   details.                                                                           *
!*   You should have received a copy of the GNU General Public License along with this  *
!*   program. If not, see <http://www.gnu.org/licenses/>.                               *
!*                                                                                      *
!****************************************************************************************
SUBROUTINE OutputHTML(fname, VersionNo, nspecmax, npoints, watercompno, cpnameinp, T_K, px, out_data, out_viscdata)

!module variables:
USE ModSystemProp, ONLY : compname, compsubgroupsHTML, NGS, NKNpNGS, ninput, nneutral
USE ModSubgroupProp, ONLY : subgrnameHTML

IMPLICIT NONE
!interface variables:
CHARACTER(LEN=*),INTENT(IN) :: fname 
CHARACTER(LEN=*),INTENT(IN) :: VersionNo
INTEGER(4),INTENT(IN) ::  nspecmax, npoints, watercompno
CHARACTER(LEN=200),DIMENSION(nspecmax),INTENT(IN) :: cpnameinp   !list of assigned component names (from input file)
REAL(8),DIMENSION(npoints),INTENT(IN) :: T_K
INTEGER(4),DIMENSION(nspecmax),INTENT(INOUT) :: px
REAL(8),DIMENSION(7,npoints,NKNpNGS),INTENT(IN) :: out_data
REAL(8),DIMENSION(3,npoints),INTENT(IN) :: out_viscdata
!--
!local variables:
CHARACTER(LEN=:),ALLOCATABLE :: cn
CHARACTER(LEN=5) :: tlen
CHARACTER(LEN=50) :: subntxt, Iformat
CHARACTER(LEN=150) :: cnformat, tformat, txtn
CHARACTER(LEN=400) :: outtxtleft
CHARACTER(LEN=3000) :: txtsubs, mixturestring
INTEGER(4) ::  i, k, kms, pointi, qty, unitx
REAL(8) :: RH
!...................................................................................

k = MAX(2, CEILING(LOG10(REAL(nspecmax))) )
WRITE(tlen,'(I0)') k
Iformat = "I"//TRIM(tlen)//"."//TRIM(tlen)  !variable integer specifier
cnformat = "("//Iformat//")"                !constructed format specifier
ALLOCATE(CHARACTER(LEN=k) :: cn)
!--
OPEN (NEWUNIT = unitx, FILE = fname, STATUS = "UNKNOWN")
outtxtleft = ADJUSTL("<h3>AIOMFAC-web, version "//VersionNo//"</h3>")
WRITE(unitx,'(A400)') outtxtleft
!create a character string of the mixture as a series of its components and add links to the components:
kms = LEN(mixturestring)
mixturestring = '<a href="#'//TRIM(ADJUSTL(compname(1)))//'">'//TRIM(ADJUSTL(compname(1)))//'</a>' !first component
!loop over all further components / species:
DO i = 2,nspecmax
    IF (INT(out_data(6,px(i),i)) == 0) THEN !neutral component
        txtn = '<a href="#'//TRIM(ADJUSTL(compname(i)))//'">'//TRIM(ADJUSTL(compname(i)))//'</a>'
    ELSE !ion (with its own link)
        txtn = '<a href="#'//TRIM(ADJUSTL(subgrnameHTML(INT(out_data(6,px(i),i)))))//'">'//TRIM(ADJUSTL(subgrnameHTML(INT(out_data(6,px(i),i) ))))//'</a>'
    ENDIF
    k = LEN_TRIM(mixturestring) +LEN_TRIM(' + '//TRIM(txtn) )
    IF (k < kms - 50) THEN
        mixturestring = TRIM(mixturestring)//' + '//TRIM(ADJUSTL(txtn))
    ELSE
        qty = nspecmax -i
        WRITE(subntxt,'(I0)') qty
        mixturestring = TRIM(mixturestring)//' + '//TRIM(subntxt)//' additional components ...'
        EXIT
    ENDIF
ENDDO
mixturestring = ADJUSTL(TRIM(mixturestring))
WRITE(tlen,'(I5.5)') LEN_TRIM(mixturestring)
tformat = '(A24, A'//tlen//')'  !dynamic format specifier
WRITE(unitx, tformat) "<p>Mixture name: &nbsp;", ADJUSTL(mixturestring)
tformat = '(A45,' //TRIM(Iformat)//')'
WRITE(unitx, tformat) "<br> Number of independent input components: ", ninput
WRITE(unitx, tformat) "<br> Number of different neutral components: ", nneutral
WRITE(unitx, tformat) "<br> Number of different inorganic ions    : ", NGS
WRITE(unitx,*) "</p>"
outtxtleft = ADJUSTL('<p> The AIOMFAC output is tabulated for each component/species individually below. </p>')
WRITE(unitx,'(A400)') outtxtleft
WRITE(unitx,*) '<br>'
!--
outtxtleft = ADJUSTL('<table class="tablekey">')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<caption id="tablekeycapt"> Table key </caption>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td id="tablekeyc1">no.</td><td id="tablekeyc2">: </td><td id="tablekeyc3"> composition point number;</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>T [K]</td><td>: </td><td> absolute temperature;</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>RH [%]</td><td>: </td><td> relative humidity in equilibrium with the liquid mixture (bulk conditions);</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>w(j) [-]</td><td>: </td><td> weight fraction (mass fraction) of species "j";</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>x_i(j) [-]</td><td>: </td><td> mole fraction of species "j", calculated on the basis of completely dissociated inorganic ions; exception: the partial dissociation of bisulfate (<span class="chemf">HSO<sub>4</sub><sup>-</sup> &#8596; H<sup>+</sup> + SO<sub>4</sub><sup>2-</sup></span>) is explicitly considered when present in the mixture; </td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>m_i(j) [mol/kg]</td><td>: </td><td> molality of species "j" [mol(j)/(kg solvent mixture)], where "solvent mixture" refers to the electrolyte-free mixture (water + organics); </td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>a_coeff_x(j) [-]</td><td>: </td><td> activity coefficient of "j", defined on mole fraction basis (used for non-ionic components) with pure (liquid) component "j" reference state;</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>a_coeff_m(j) [-]</td><td>: </td><td> activity coefficient of "j", defined on molality basis (used for inorg. ions) with reference state of infinite dilution of "j" in pure water;</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>a_x(j) [-]</td><td>: </td><td> activity of "j", defined on mole fraction basis (pure component reference state);</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>a_m(j) [-]</td><td>: </td><td> activity of "j", defined on molality basis (used for inorg. ions) with reference state of infinite dilution of "j" in pure water;</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>log<sub>10</sub>(&eta;/[Pa.s])</td><td>: </td><td> base-10 log of the dynamic viscosity of the mixture;</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>log<sub>10</sub>(&eta;&nbsp;sens./[Pa.s])</td><td>: </td><td> base-10 log of the estimated sensitivity of the dynamic viscosity of the mixture; see details <a href="../help.html#viscosity">here</a>;</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('<tr><td>flag</td><td>: </td><td> error/warning flag, a non-zero value (error/warning number) indicates that a numerical issue or a warning occurred at this data point, suggesting evaluation with caution (warnings) or exclusion (errors) of this data point; see also the <a href="../AIOMFAC-model/List_of_Error_and_Warning_Codes.pdf">List_of_Error_and_Warning_Codes.pdf</a>.</td></tr>')
WRITE(unitx,'(A400)') outtxtleft
outtxtleft = ADJUSTL('</table>')
WRITE(unitx,'(A400)') outtxtleft
WRITE(unitx,*) '<br>'
WRITE(unitx,*) '<br>'

!--
!data table for mixture viscosity output
WRITE(unitx,*) '<br>'
!write component properties table above data table:
outtxtleft = ADJUSTL('<table class="datatabname">')
WRITE(unitx,'(A400)') outtxtleft
WRITE(unitx,*) '<tbody>'
WRITE(unitx,'(A61)') "<tr><td>Properties of this phase: mixture viscosity</td></tr>"
WRITE(unitx,*) '</tbody>'
WRITE(unitx,*) '</table>'
!write table column headers:
outtxtleft = ADJUSTL('<table class="datatable">')
WRITE(unitx,'(A400)') outtxtleft
WRITE(unitx,*) '<thead>'
txtsubs = ADJUSTL("<tr><th> no. </th><th>&nbsp;</th><th> T [K] </th><th>&nbsp;</th><th> RH [%] </th><th>&nbsp;</th><th> log<sub>10</sub>(&eta;/[Pa.s])</th><th>&nbsp;</th><th> log<sub>10</sub>(&eta;&nbsp;sens./[Pa.s]) </th><th>&nbsp;</th><th> flag </th></tr> ")
WRITE(tlen,'(I0)') LEN_TRIM(txtsubs)
tformat = '(A'//tlen//')'
WRITE(unitx,tformat) ADJUSTL(txtsubs) 
WRITE(unitx,*) '</thead>'
WRITE(unitx,*) '<tbody>'
!--
!write data to table:
DO pointi = 1,npoints  !loop over composition points
    IF (watercompno > 0) THEN !water is present in mixture
        RH = out_data(5,pointi,watercompno)*100.0D0 !RH in %
        IF (RH > 1000.0D0 .OR. RH < 0.0D0) THEN
            RH = -99.99D0
        ENDIF
    ELSE
        RH = 0.0D0
    ENDIF
    tformat = '(A8,I5.3,"</td><td>&nbsp;</td><td>",F7.2,"</td><td>&nbsp;</td><td>",F7.2,"</td><td>&nbsp;</td><td>",2(ES12.5,"</td><td>&nbsp;</td><td>"),I2,A10)'
    WRITE(unitx, tformat) "<tr><td>", pointi, T_K(pointi), RH, out_viscdata(1,pointi), out_viscdata(2,pointi), INT(out_viscdata(3,pointi)), "</td></tr>"
ENDDO !pointi
WRITE(unitx,*) '</tbody>'
WRITE(unitx,*) '</table>'
WRITE(unitx,*) '<a href="#top">&uarr; Top</a>'
WRITE(unitx,*) "<br>"
WRITE(unitx,*) "<br>"

!write individual data tables for each component / ionic species:
DO i = 1,nspecmax
    WRITE(cn,cnformat) i !component / species number as character string
    IF (INT(out_data(6,px(i),i)) == 0) THEN !neutral component
        WRITE(unitx,*) '<br>'
        txtn = ADJUSTL('<a id="'//TRIM(ADJUSTL(compname(i)))//'"></a>')
        WRITE(unitx,'(A150)') txtn
        !write component properties table above data table:
        outtxtleft = ADJUSTL('<table class="datatabname">')
        WRITE(unitx,'(A400)') outtxtleft
        WRITE(unitx,*) '<tbody>'
        tformat = '(A73,'//TRIM(Iformat)//',A10)'
        WRITE(unitx,tformat) "<tr><td> Mixture's component, #  </td> <td> &nbsp; : &nbsp; ", i ,"</td></tr>"
        txtn = TRIM(ADJUSTL(compname(i)))
        txtn = TRIM(txtn)//"</td></tr>"
        WRITE(tlen,'(I5.5)') LEN_TRIM(txtn)
        tformat = '(A66, A'//tlen//')' 
        WRITE(unitx, tformat) "<tr><td> Component's name </td> <td> &nbsp; : &nbsp; ", ADJUSTL(txtn)
        txtsubs = '<span class="chemf">'//TRIM(compsubgroupsHTML(i))//"</span></td></tr>"
        WRITE(tlen,'(I5.5)') LEN_TRIM(txtsubs)
        tformat = '(A71, A'//tlen//')' 
        WRITE(unitx, tformat) "<tr><td> Component's subgroups </td> <td> &nbsp; : &nbsp; ", ADJUSTL(txtsubs)
        WRITE(unitx,*) '</tbody>'
        WRITE(unitx,*) '</table>'
        !write table column headers:
        outtxtleft = ADJUSTL('<table class="datatable">')
        WRITE(unitx,'(A400)') outtxtleft
        WRITE(unitx,*) '<thead>'
        outtxtleft = ADJUSTL("<tr><th> no. </th><th>&nbsp;</th><th> T [K] </th><th>&nbsp;</th><th> RH [%] </th><th>&nbsp;</th><th> w("//cn//")</th><th>&nbsp;</th><th> x_i("//cn//")</th><th>&nbsp;</th><th> m_i("//cn//")</th><th>&nbsp;</th><th> a_coeff_x("//cn//")</th><th>&nbsp;</th><th> a_x("//cn//")</th><th>&nbsp;</th><th> flag </th></tr> ")
        WRITE(unitx,'(A400)') outtxtleft
        !--
    ELSE IF (INT(out_data(6,px(i),i)) < 240) THEN !cation
        WRITE(unitx,*) '<br>'
        txtn = '<a id="'//TRIM(ADJUSTL(subgrnameHTML(INT(out_data(6,px(i),i)))))//'"></a>'
        WRITE(unitx,'(A150)') txtn !link target
        !---
        !write component properties table above data table:
        outtxtleft = ADJUSTL('<table class="datatabname">')
        WRITE(unitx,'(A400)') outtxtleft
        WRITE(unitx,*) '<tbody>'
        tformat = '(A71,'//TRIM(Iformat)//',A10)'
        WRITE(unitx,tformat) "<tr><td> Mixture's species, # </td> <td> &nbsp; : &nbsp; ", i ,"</td></tr>"
        subntxt = TRIM(ADJUSTL(subgrnameHTML(INT(out_data(6,px(i),i)))))
        qty = LEN_TRIM(subntxt)
        txtn = ADJUSTL(subntxt(2:qty-1)) !to print the ion name without the enclosing parathesis ()
        txtn = '<span class="chemf">'//TRIM(txtn)//"</span></td></tr>"
        WRITE(tlen,'(I5.5)') LEN_TRIM(txtn)
        tformat = '(A63, A'//tlen//')' 
        WRITE(unitx, tformat) "<tr><td> Cation's name </td> <td> &nbsp; : &nbsp; ", ADJUSTL(txtn)
        txtsubs = '<span class="chemf">'//TRIM(subntxt)//"</span></td></tr>"
        WRITE(tlen,'(I5.5)') LEN_TRIM(txtsubs)
        tformat = '(A68, A'//tlen//')' 
        WRITE(unitx, tformat) "<tr><td> Cation's subgroups </td> <td> &nbsp; : &nbsp; ", ADJUSTL(txtsubs)
        WRITE(unitx,*) '</tbody>'
        WRITE(unitx,*) '</table>'
        !write data table column headers:
        outtxtleft = '<table class="datatable">'
        WRITE(tlen,'(I5.5)') LEN_TRIM(outtxtleft)
        tformat = '(A'//tlen//')' 
        WRITE(unitx, tformat) ADJUSTL(outtxtleft)
        WRITE(unitx,*) '<thead>'
        outtxtleft = ADJUSTL('<tr><th> no. </th><th>&nbsp;</th><th> T [K] </th><th>&nbsp;</th><th> RH [%] </th><th>&nbsp;</th><th> w('//cn//')</th><th>&nbsp;</th><th> x_i('//cn//')</th><th>&nbsp;</th><th> m_i('//cn//')</th><th>&nbsp;</th><th> a_coeff_m('//cn//')</th><th>&nbsp;</th><th> a_m('//cn//')</th><th>&nbsp;</th><th> flag </th></tr> ')
        WRITE(unitx,'(A400)') outtxtleft
        !--
    ELSE IF (INT(out_data(6,px(i),i)) > 240) THEN !anion
        WRITE(unitx,*) '<br>'
        txtn = '<a id="'//TRIM(ADJUSTL(subgrnameHTML(INT(out_data(6,px(i),i)))))//'"></a>'
        WRITE(unitx,'(A150)') txtn
        !---
        !write component properties table above data table:
        outtxtleft = ADJUSTL('<table class="datatabname">')
        WRITE(unitx,'(A400)') outtxtleft
        WRITE(unitx,*) '<tbody>'
        tformat = '(A71,'//TRIM(Iformat)//',A10)'
        WRITE(unitx,tformat) "<tr><td> Mixture's species, # </td> <td> &nbsp; : &nbsp; ", i ,"</td></tr>"
        subntxt = TRIM(ADJUSTL(subgrnameHTML(INT(out_data(6,px(i),i)))))
        qty = LEN_TRIM(subntxt)
        txtn = ADJUSTL(subntxt(2:qty-1)) !to print the ion name without the enclosing parathesis ()
        txtn = '<span class="chemf">'//TRIM(txtn)//"</span></td></tr>"
        WRITE(tlen,'(I5.5)') LEN_TRIM(txtn)
        tformat = '(A63, A'//tlen//')' 
        WRITE(unitx, tformat)  "<tr><td> Anion's name </td> <td> &nbsp; : &nbsp; ", ADJUSTL(txtn)
        txtsubs = '<span class="chemf">'//TRIM(subntxt)//"</span></td></tr>"
        WRITE(tlen,'(I5.5)') LEN_TRIM(txtsubs)
        tformat = '(A68, A'//tlen//')' 
        WRITE(unitx, tformat) "<tr><td> Anion's subgroups </td> <td> &nbsp; : &nbsp; ", ADJUSTL(txtsubs)
        WRITE(unitx,*) '</tbody>'
        WRITE(unitx,*) '</table>'
        !write data table column headers:
        outtxtleft = ADJUSTL('<table class="datatable">')
        WRITE(unitx,'(A400)') outtxtleft
        WRITE(unitx,*) '<thead>'
        outtxtleft = ADJUSTL("<tr><th> no. </th><th>&nbsp;</th><th> T [K] </th><th>&nbsp;</th><th> RH [%] </th><th>&nbsp;</th><th> w("//cn//")</th><th>&nbsp;</th><th> x_i("//cn//")</th><th>&nbsp;</th><th> m_i("//cn//")</th><th>&nbsp;</th><th> a_coeff_m("//cn//")</th><th>&nbsp;</th><th> a_m("//cn//")</th><th>&nbsp;</th><th> flag </th></tr> ")
        WRITE(unitx,'(A400)') outtxtleft
        !--
    ELSE
        !error
    ENDIF
    !--
    WRITE(unitx,*) '</thead>'
    WRITE(unitx,*) '<tbody>'
    !write data to table:
    DO pointi = 1,npoints  !loop over composition points
        IF (watercompno > 0) THEN !water is present in mixture
            RH = out_data(5,pointi,watercompno)*100.0D0 !RH in %
            IF (RH > 1000.0D0 .OR. RH < 0.0D0) THEN
                RH = -99.99D0
            ENDIF
        ELSE
            RH = 0.0D0
        ENDIF
        tformat = '(A8,I5.3,"</td><td>&nbsp;</td><td>",F7.2,"</td><td>&nbsp;</td><td>",F7.2,"</td><td>&nbsp;</td><td>",5(ES12.5,"</td><td>&nbsp;</td><td>"),I2,A10)'
        WRITE(unitx, tformat) "<tr><td>", pointi, T_K(pointi), RH, (out_data(k,pointi,i), k = 1,5), INT(out_data(7,pointi,i)), "</td></tr>"
    ENDDO !pointi
    WRITE(unitx,*) '</tbody>'
    WRITE(unitx,*) '</table>'
    WRITE(unitx,*) '<a href="#top">&uarr; Top</a>'
    WRITE(unitx,*) "<br>"
    WRITE(unitx,*) "<br>"
ENDDO

CLOSE(unitx)
        
END SUBROUTINE OutputHTML