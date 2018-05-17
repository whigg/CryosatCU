      subroutine Out_nc(ipr_nc,npr_nc,n_iter)
C +
C +------------------------------------------------------------------------+
C | MAR OUTPUT                                             30-03-2002  MAR |
C |   SubRoutine Out_nc is used to write the main Model Variables          |
C |                                      on  a NetCDF file                 |
C +------------------------------------------------------------------------+
C |                                                                        |
C |   INPUT: ipr_nc: Current time step    number                           |
C |   ^^^^^^         (starting from ipr_nc=1, which => new file creation)  |
C |          npr_nc: Total  'time slices' number (max value of ipr_nc)     |
C |                                                                        |
C |   OUTPUT: NetCDF File adapted to IDL Graphic Software                  |
C |   ^^^^^^                                                               |
C |                                                                        |
C |   CAUTION: 1) This Routine requires the usual NetCDF library,          |
C |   ^^^^^^^^    and the complementary access library  'libUN.a'          |
C |                                                                        |
C |                                                                        |
C |                                                                        |
C |                                                                        |
C |                                                                        |
C +------------------------------------------------------------------------+
C +
C +
      IMPLICIT NONE
C +
C +
C +--General Variables
C +  =================
C +
      include 'MARphy.inc'
C +
      include 'MARdim.inc'
      include 'MARgrd.inc'
      include 'MAR_SV.inc'
      include 'MAR_GE.inc'
C +
      include 'MAR_RA.inc'
      include 'MAR_DY.inc'
      include 'MAR_HY.inc'
C +
      include 'MAR_SL.inc'
      include 'MARsSN.inc'
      include 'MAR_SN.inc'
      include 'MAR_TV.inc'
C +
      include 'MAR_WK.inc'
C +
      include 'MAR_IO.inc'
C +
      integer  ipr_nc,npr_nc,n_iter
C +
C +
C +--Local   Variables
C +  =================
C +
C +--Physics
C +  -------
C +
      integer            isnTop           
      integer            lsnTop
      real               rhoAir
      real               TsolAV(mx,my,llx)
      real               HsolAV(mx,my,llx)
      real               HgrdAV(mx,my)
      real               cuHobs(mx,my)         ! Interpol.Observ.Snow Height
      real               cuTobs(mx,my)         ! Interpol.Observ.Snow Temper.
      real               Tgrd_1(mx,my)         ! Simulated Mos.1 Snow Temper.
      real               Tgrd_2(mx,my)         ! Simulated Mos.2 Snow Temper.
      real               TgrdAV(mx,my)         ! Simulated       Snow Temper.
      common/CdPobs/     cuHobs,cuTobs,TgrdAV  !
C +
      real               snow0(mx,my),rain0(mx,my)
      common/Out2rr_loc/ snow0       ,rain0
C +...                   snow0 : Integrated Snow over Previous Time Interval
C +                      rain0 : Integrated Rain over Previous Time Interval
C +
C +--OUTPUT for Stand Alone NetCDF File
C +  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      real          SOsoNC(mx,my,nvx)          ! Absorbed Solar Radiation
      real          IRsoNC(mx,my,nvx)          ! Absorbed IR    Radiation
      real          HSsoNC(mx,my,nvx)          ! Absorbed Sensible Heat Flux
      real          HLsoNC(mx,my,nvx)          ! Absorbed Latent   Heat Flux
      real          HLs_NC(mx,my,nvx)          ! Evaporation
      real          HLv_NC(mx,my,nvx)          ! Transpiration
      real          eta_NC(mx,my,nvx)          ! Soil Humidity
      common/writNC/SOsoNC,IRsoNC              !
     .             ,HSsoNC,HLsoNC              !
     .             ,HLs_NC,HLv_NC,eta_NC       !
C +
C +
C +--netcdf file set up
C +  ------------------
C +
      integer    Lfnam      , Ltit    , Luni    , Lnam    , Llnam
      PARAMETER (Lfnam  = 40, Ltit= 90, Luni= 31, Lnam= 13, Llnam=50)
C +...Length of char strings 
C +
      integer    NdimNC
      PARAMETER (NdimNC = 5)
C +...Number of defined spatial dimensions (exact)
C +
      integer    MXdim
      PARAMETER (MXdim  = 72000)
C +...Maximum Number of all dims: recorded Time Steps
C +   and also maximum of spatial grid points for each direction. 
C +
      integer    MX_var
      PARAMETER (MX_var = 80)
C +...Maximum Number of Variables 
C +
      integer    NattNC
      PARAMETER (NattNC = 2)
C +...Number of real attributes given to all variables
C +
      INTEGER            RCODE
C +
      integer            moisNC(MXdim)
      integer            jourNC(MXdim)
      real               yearNC(MXdim)
      real               dateNC(MXdim)
      common/dateyear/   yearNC,dateNC
      real               timeNC(MXdim)
      real               VALdim(MXdim,0:NdimNC)
      integer            nDFdim(      0:NdimNC)
      common/c_nDFdim/   nDFdim
      integer            NvatNC(NattNC)
      CHARACTER*(Lnam)   NAMdim(      0:NdimNC)
      CHARACTER*(Luni)   UNIdim(      0:NdimNC)
      CHARACTER*(Lnam)   SdimNC(4,MX_var)       
      CHARACTER*(Luni)   unitNC(MX_var)
      CHARACTER*(Lnam)   nameNC(MX_var)
      CHARACTER*(Llnam)  lnamNC(MX_var)
      CHARACTER*(Lfnam)  fnamNC
      common/Out_nc_loc/ fnamNC
C +...                   fnamNC: To retain file name.
C +
      CHARACTER*(Ltit )  tit_NC
      CHARACTER*(Lnam)   NAMrat(NattNC)
      CHARACTER*120      tmpINP
C +
      integer            n1000 ,n100a ,n100  ,n10_a ,n10   ,n1
      integer            m10   ,jd10  ,jd1   ,MMXstp,it    ,iu
      integer            itotNC,NtotNC,ID__nc,msc   ,mois  ,mill
      real               starti,starta(1),DayLen,vmulti
C +
C +
C +--NetCDF File Initialization
C +  ==========================
C +
      IF (ipr_nc.eq.1) THEN
C +
          n1000 = 1 +     iyrrGE/1000
          n100a =     mod(iyrrGE,1000)
          n100  = 1 +     n100a /100
          n10_a =     mod(n100a ,100)
          n10   = 1 +     n10_a /10
          n1    = 1 + mod(n10_a ,10)
          m10   = 1 +     mmarGE/10
          m1    = 1 + mod(mmarGE,10)
          jd10  = 1 +     jdarGE/10
          jd1   = 1 + mod(jdarGE,10)
C +
C +
C +--Output File Label
C +  -----------------
C +
        fnamNC = 'ANI.'
     .         // labnum(n1000) // labnum(n100)
     .         // labnum(  n10) // labnum(  n1)
     .         // labnum(  m10) // labnum(  m1)
     .         // labnum( jd10) // labnum( jd1)
     .         // '.' // explIO
     .         // '.nc    '
C +
C +
C +--Output Title
C +  ------------
C +
        tit_NC = 'MAR'
     .         // ' - Exp: ' // explIO
     .         // ' - '
     .         // labnum(n1000) // labnum(n100)
     .         // labnum(  n10) // labnum(  n1)
     .         // labnum(  m10) // labnum(  m1)
     .         // labnum( jd10) // labnum( jd1)
C +
C +
C +--Create File / Write Constants
C +  -----------------------------
        MMXstp = MXdim
C +...  To check array bounds... silently
C +
C +--Time Variable (hour)
C +  ~~~~~~~~~~~~~~~~~~~~
C +
C +...  To define a NetCDF dimension (size, name, unit):
        nDFdim(0)= npr_nc                              ! .NOT. NF_UNLIMITED
        nDFdim(0)= 0                                   !       NF_UNLIMITED
        NAMdim(0)= 'time'                              !
        UNIdim(0)= 'HOURS since 1901-01-15 00:00:00'   ! ferret time set up
C +
C +...  Check temporary arrays: large enough ?
        IF (npr_nc.gt.MMXstp)
     &  STOP '*** Out_nc - ERROR : MXdim to low ***'
C +
              starti     = jhurGE + minuGE/60.d0 + jsecGE/3600.d0
C +...        starti :     Starting Time (= current time in the day)
C +
              starta(1)  = 
     .                 (351+(iyrrGE  -1902) *365       ! Nb Days before iyrrGE
     .                     +(iyrrGE  -1901) /  4       ! Nb Leap Years
     .                     + njyrGE(mmarGE)            ! Nb Days before mmarGE
     .                     + njybGE(mmarGE)            ! (including Leap Day)
     .                 *max(0,1-mod(iyrrGE,4))         !
     .                     + jdarGE     -1      )*  24 !
     .                 +jhurGE                         !
     .               + (minuGE *60 +jsecGE      )/3600.!
C +
        DO it = 1,npr_nc
              timeNC(it)   = starti    + (it-1) * n_iter  *dt / 3600.
C +...                                         n_iter: #iter between output
C +
              VALdim(it,0) = starta(1) + (it-1) * n_iter  *dt / 3600.
C +...        VALdim(  ,0) : values of the dimension # 0 (time) 

C +--Time Variable (date)
C +  ~~~~~~~~~~~~~~~~~~~~
              dateNC(it) =          timeNC(it)
              jourNC(it) = jdarGE + timeNC(it) / 24.d0
        END DO
                  mois       =  mmarGE
                  mill       =  iyrrGE
        DO it = 1,npr_nc
          IF     (jourNC(it).gt.njmoGE(mois))                     THEN ! CTR
            DO iu=it,npr_nc
                  jourNC(iu) =  jourNC(iu) - njmoGE(mois)
            END DO
                  mois       =  mois + 1
              IF (mois.gt.12)                                     THEN ! CTR
                  mois       =         1
                  mill       =  mill + 1
              END IF                                                   ! CTR
          END IF                                                       ! CTR
                  moisNC(it) =  mois
                  yearNC(it) =  mill
C +
          IF     (dateNC(it).gt.24.d0-epsi)                       THEN ! CTR
                  DayLen     =  24.d0
            DO iu=it,npr_nc
                  dateNC(iu) = mod(dateNC(iu),DayLen)
            END DO
          END IF                                                       ! CTR
        END DO
C +
        DO it = 1,npr_nc
              dateNC(it) =  dateNC(it)
     .             + 1.d+2 *jourNC(it)
     .             + 1.d+4 *moisNC(it)

C +--Time: Additional Correction: current time in the year (NOT in MAR)
C +  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
              VALdim(it,0)= VALdim(it,0)
     .             + 24. *((jourNC(1)-1)+njyrGE(moisNC(1)))
        END DO
C +

C     Define horizontal spatial dimensions :    
C +   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
C +
C +...  Check temporary arrays: large enough ?
        IF (    mx .gt.MMXstp.or.my.gt.MMXstp
     &      .or.mzz.gt.MMXstp.or.mw.gt.MMXstp)
     &    STOP '*** Out_nc - ERROR : MXdim to low ***'
C +
C +...To define NetCDF dimensions (size, name, unit):
C +
        DO i = 1, mx
          VALdim(i,1) = xxkm(i)
        END DO
          nDFdim(1)   = mx
          NAMdim(1)   = 'x'
          UNIdim(1)   = 'km'
C +
        DO j = 1, my
          VALdim(j,2) = yykm(j)
        END DO
          nDFdim(2)   = my
          NAMdim(2)   = 'y'
          UNIdim(2)   = 'km'
C +
          VALdim(1,3) =-0.02
          VALdim(2,3) =-0.06
          VALdim(3,3) =-0.20
          VALdim(4,3) =-0.72
        IF (llx.gt.4)                                              THEN ! CTR
          vmulti      = 2.00d0
          do k = 5, llx
          VALdim(k,3) = 0.72d0       *vmulti**(k-4)
          enddo
        END IF
          do k = 5, llx
          VALdim(k,3) =-VALdim(k  ,3)
          enddo
C +
          nDFdim(3)   =  llx
          NAMdim(3)   = 'level'
          UNIdim(3)   = 'm'
C +...    For levels k
C +
        do k = 1,llx-1
          VALdim(k  ,4) = 0.5*(VALdim(k,3)+VALdim(k+1,3))
        enddo
           k =   llx
          VALdim(k  ,4) =      VALdim(k,3)
     .                       +(VALdim(k,3)-VALdim(k-1,3))*0.5d0
C +
          nDFdim(4)   =  llx
          NAMdim(4)   = 'level2'
          UNIdim(4)   = 'm'
C +...    For levels k+1/2 (to be modified)
C +
        do k = 1, nvx
          VALdim(k,5) = k 
        enddo
          nDFdim(5)   = nvx
          NAMdim(5)   = 'sector'
          UNIdim(5)   = '[index]'
C +...    For Surface Sectors 
C +
C +--Variable's Choice (Table SISVAT_StA.dat)
C +  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
C +
        OPEN(unit=10,status='unknown',file='Out_nc.ctr')
C +
        itotNC = 0
 980    CONTINUE
          READ (10,'(A120)',end=990) tmpINP
          IF (tmpINP(1:4).eq.'    ')                                THEN 
            itotNC = itotNC + 1
            READ (tmpINP,'(4x,5A9,A12,A50)')
     &          nameNC(itotNC)  ,SdimNC(1,itotNC),SdimNC(2,itotNC),
     &          SdimNC(3,itotNC),SdimNC(4,itotNC),
     &          unitNC(itotNC)  ,lnamNC(itotNC)
C +...          nameNC: Name
C +             SdimNC: Names of Selected Dimensions (max.4/variable) 
C +             unitNC: Units
C +             lnamNC: Long_name, a description of the variable
C +
          ENDIF
        GOTO 980
 990    CONTINUE
C +
        CLOSE(unit=10)
C +
        NtotNC = itotNC 
C +...  NtotNC : Total number of variables writen in NetCDF file.
C +
C +--List of NetCDF attributes given to all variables:
C +  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
C +...  The "actual_range" is the (min,max)
C +     of all data for each variable:
        NAMrat(1) = 'actual_range'
        NvatNC(1) = 2

C +...  The "[var]_range" is NOT of attribute type,
C +     it is a true variable containing the (min,max) for
C +     each level, for 4D (space+time) variables only
C +     (automatic handling by UN library;
C +      must be the LAST attribute)
        NAMrat(NattNC) = '[var]_range'
        NvatNC(NattNC) = 2
C +
C +--Automatic Generation of the NetCDF File Structure
C +  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
C +
C +     **************
        CALL UNscreate (fnamNC,tit_NC,
     &                  NdimNC, nDFdim, MXdim , NAMdim, UNIdim, VALdim,
     &                  MX_var, NtotNC, nameNC, SdimNC, unitNC, lnamNC,
     &                  NattNC, NAMrat, NvatNC,
     &                  ID__nc) 
C +     **************
C +
C +
C +--Write Time - Constants
C +  ~~~~~~~~~~~~~~~~~~~~~~
        DO j=1,my
        DO i=1,mx
          Wkxy1(i,j) =  GElonh(i,j) * 15.d0
C +...    Conversion: Hour->degrees
C +
          WKxy2(i,j) =  GElatr(i,j) / degrad
C +...    Conversion: rad ->degrees
C +
          WKxy3(i,j) =  isolSL(i,j)
C +...    Conversion to REAL type (integer not allowed)
C +
        END DO
        END DO
C +
C +       ************
          CALL UNwrite (ID__nc, 'lon   ', 1  , mx    , my, 1 , Wkxy1)
          CALL UNwrite (ID__nc, 'lat   ', 1  , mx    , my, 1 , Wkxy2)
          CALL UNwrite (ID__nc, 'sh    ', 1  , mx    , my, 1 , sh)
          CALL UNwrite (ID__nc, 'isol  ', 1  , mx    , my, 1 , Wkxy3)
C +       ************
C +
C +--Re-Open file if already created.
C +  ================================
C +
C +
      ELSE
C +
C +     ************
        CALL UNwopen (fnamNC,ID__nc)
C +     ************
C +
      END IF
C +
C +
C +--Write Time-dependent variables:
C +  ===============================
C +
C +--UNLIMITED Time Dimension
C +  ------------------------
C +
      IF (nDFdim(0).eq.0)                         THEN !
           starta(1) = (351+(iyrrGE  -1902) *365       ! Nb Days before iyrrGE
     .                     +(iyrrGE  -1901) /  4       ! Nb Leap Years
     .                     + njyrGE(mmarGE)            ! Nb Days before mmarGE
     .                     + njybGE(mmarGE)            ! (including Leap Day)
     .                 *max(0,1-mod(iyrrGE,4))         !
     .                     + jdarGE     -1      )*  24 !
     .                 +jhurGE                         !
     .               + (minuGE *60 +jsecGE      )/3600.!
C +
C +     ************
        CALL UNwrite (ID__nc, 'time   ',ipr_nc, 1, 1, 1, starta(1))
C +     ************
C +
      END IF
C +
C +     ************
        CALL UNwrite (ID__nc, 'date   ',ipr_nc, 1, 1, 1, dateNC(ipr_nc))
        CALL UNwrite (ID__nc, 'year   ',ipr_nc, 1, 1, 1, yearNC(ipr_nc))
C +     ************
C +
C +
C +--Absorbed Solar and IR Radiations
C +  --------------------------------
C +
      DO j=1,my
      DO i=1,mx
          WKxy1(i,j) = RAdsol(i,j)  *  (1. -albeSL(i,j))
          WKxy2(i,j) = RAD_ir(i,j) 
     .               - stefan * tviRA(i,j) * tviRA(i,j) 
     .                        * tviRA(i,j) * tviRA(i,j)
C +
C +
C +--Precipitation
C +  -------------
C +
C +--Snow
C +  ~~~~
          WKxy3(i,j) =(snowHY(i,j)-snow0(i,j)) *1000.
          snow0(i,j) = snowHY(i,j)
C +
C +--Rain
C +  ~~~~
          WKxy4(i,j) =(rainHY(i,j)-rain0(i,j)) *1000.
          rain0(i,j) = rainHY(i,j)
      END DO
      END DO
C +
C +
C +   ************
      CALL UNwrite (ID__nc, 'pstar  ', ipr_nc, mx, my, 1      , pstDY )
      CALL UNwrite (ID__nc, 'coszen ', ipr_nc, mx, my, 1      , czenGE)
      CALL UNwrite (ID__nc, 'albedo ', ipr_nc, mx, my, 1      , albeSL)
      CALL UNwrite (ID__nc, 'net_SW ', ipr_nc, mx, my, 1      , WKxy1 )
      CALL UNwrite (ID__nc, 'net_LW ', ipr_nc, mx, my, 1      , WKxy2 )
      CALL UNwrite (ID__nc, 'ppSnow ', ipr_nc, mx, my, 1      , WKxy3 )
      CALL UNwrite (ID__nc, 'tpSnow ', ipr_nc, mx, my, 1      , snowHY)
      CALL UNwrite (ID__nc, 'ppRain ', ipr_nc, mx, my, 1      , WKxy4 )
C +   ************
C +
C +
C +--Snow Properties, Mosaic 1
C +  -------------------------
C +
      DO j=1,my
      DO i=1,mx
           WKxy1(i,j)   = g1sSNo(i,j,1,max(1,nssSNo(1,1,1)))
           WKxy2(i,j)   = g2sSNo(i,j,1,max(1,nssSNo(1,1,1)))
C +
           WKxy3(i,j)   = 0.0
           WKxy4(i,j)   = 0.0
           WKxy5(i,j)   = 0.0
      DO k=1,mg
        DO msc=1,nvx
           WKxy3(i,j)   =  WKxy3(i,j)  
     .   +ifraTV(i,j,msc)*dzsSNo(i,j,msc,k)
        END DO
           WKxy4(i,j)   =  WKxy4(i,j)
     .                  + dzsSNo(i,j,  1,k)
           WKxy5(i,j)   =  WKxy5(i,j)
     .                  + dzsSNo(i,j,  1,k) *rosSNo(i,j,1,k) /ro_Wat
      END DO
           WKxy3(i,j)   =  WKxy3(i,j)           *0.01
C +
C +--Blowing Snow
C +  ~~~~~~~~~~~~
           WKxy7(i,j)   = SLuusl(i,j,1)
           WKxy8(i,j)   = SaltSN(i,j,1)
           rhoAir       =(pstDYn(1,1) +  ptopDY)*1.e3
     .                  /(tairDY(1,1,mz)*RDryAi)
           WKxy9(i,j)   =-SLussl(i,j,1) *dt *rhoAir          /ro_Wat
      END DO
      END DO
C +
C +
C +   ************
      CALL UNwrite (ID__nc, 'G1___1 ', ipr_nc, mx, my, 1      , WKxy1 )
      CALL UNwrite (ID__nc, 'G2___1 ', ipr_nc, mx, my, 1      , WKxy2 )
      CALL UNwrite (ID__nc, 'H_Snow ', ipr_nc, mx, my, 1      , WKxy3 )
      CALL UNwrite (ID__nc, 'HS_Obs ', ipr_nc, mx, my, 1      , cuHobs)
      CALL UNwrite (ID__nc, 'H_Sno1 ', ipr_nc, mx, my, 1      , WKxy4 )
      CALL UNwrite (ID__nc, 'HeSno1 ', ipr_nc, mx, my, 1      , WKxy5 )
      CALL UNwrite (ID__nc, 'ustar1 ', ipr_nc, mx, my, 1      , WKxy7 )
      CALL UNwrite (ID__nc, 'ustth1 ', ipr_nc, mx, my, 1      , WKxy8 )
      CALL UNwrite (ID__nc, 'BlowS1 ', ipr_nc, mx, my, 1      , WKxy9 )
C +   ************
C +
C +
C +--Snow Properties, Mosaic 2
C +  -------------------------
C +
      do j=1,my
      do i=1,mx
           WKxy1(i,j)   = 
     .    g1sSNo(i,j,min(2,nsx),max(1,nssSNo(1,1,min(2,nsx))))
           WKxy2(i,j)   = 
     .    g2sSNo(i,j,min(2,nsx),max(1,nssSNo(1,1,min(2,nsx))))
C +
           WKxy3(i,j)   = 0.0
           WKxy4(i,j)   = 0.0
           WKxy5(i,j)   = 0.0
C +
      DO k=1,nisSNo(i,j,min(2,nsx))
           WKxy3(i,j)   =  WKxy3(i,j)
     .                  + dzsSNo(i,j,min(2,nsx),k)
      END DO
      DO k=1,mg
           WKxy4(i,j)   =  WKxy4(i,j)
     .                  + dzsSNo(i,j,min(2,nsx),k)
           WKxy5(i,j)   =  WKxy5(i,j)
     .                  + dzsSNo(i,j,min(2,nsx),k) 
     .                   *rosSNo(i,j,min(2,nsx),k)        /ro_Wat
      END DO
           WKxy6(i,j)   = ifraTV(i,j,min(2,nvx))
C +
C +--Blowing Snow
C +  ~~~~~~~~~~~~
           WKxy7(i,j)   = SLuusl(i,j,min(2,mw ))
           WKxy8(i,j)   = SaltSN(i,j,min(2,nvx))
           rhoAir       =(pstDYn(1,1) +  ptopDY)*1.e3
     .                  /(tairDY(1,1,mz)*RDryAi)
           WKxy9(i,j)   =-SLussl(i,j,min(2,mw ))*dt*rhoAir/ro_Wat
      END DO
      END DO
C +
C +
C +   ************
      CALL UNwrite (ID__nc, 'G1___2 ', ipr_nc, mx, my, 1      , WKxy1 )
      CALL UNwrite (ID__nc, 'G2___2 ', ipr_nc, mx, my, 1      , WKxy2 )
      CALL UNwrite (ID__nc, 'H_SnoI ', ipr_nc, mx, my, 1      , WKxy3 )
      CALL UNwrite (ID__nc, 'H_Sno2 ', ipr_nc, mx, my, 1      , WKxy4 )
      CALL UNwrite (ID__nc, 'HeSno2 ', ipr_nc, mx, my, 1      , WKxy5 )
      CALL UNwrite (ID__nc, 'SeaIce ', ipr_nc, mx, my, 1      , WKxy6 )
      CALL UNwrite (ID__nc, 'ustar2 ', ipr_nc, mx, my, 1      , WKxy7 )
      CALL UNwrite (ID__nc, 'ustth2 ', ipr_nc, mx, my, 1      , WKxy8 )
      CALL UNwrite (ID__nc, 'BlowS2 ', ipr_nc, mx, my, 1      , WKxy9 )
C +   ************
C +
C +
C +--Soil Properties
C +  ---------------
C +
      DO j=1,my
      DO i=1,mx
          TgrdAV(i,j)   = 0.0d+0
          HgrdAV(i,j)   = 0.0d+0
        DO msc=1,nvx
          isntop        =         max(nssSNo(i,j,msc),1)
          lsntop        =         min(nssSNo(i,j,msc),1)
          TgrdAV(i,j)   =             TgrdAV(i,j)
     .   +ifraTV(i,j,msc)*((1-lsntop)*TsolTV(i,j,msc, 1)
     .                       +lsntop *tisSNo(i,j,msc,isntop))*0.01
          HgrdAV(i,j)   =             HgrdAV(i,j)
     .   +ifraTV(i,j,msc)*            psigTV(i,j,msc)        *0.01
        END DO
C +
           WKxy1(i,j)   =             TvegTV(i,j,1)
          Tgrd_1(i,j)   = ((1-lsntop)*TsolTV(i,j,1,1)
     .                       +lsntop *tisSNo(i,j,1,isntop))-TfSnow
C +
           WKxy2(i,j)   =             TvegTV(i,j,min(2,nvx))
          Tgrd_2(i,j)   = ((1-lsntop)*TsolTV(i,j,min(2,nvx),1)
     .                       +lsntop *tisSNo(i,j,min(2,nsx),isntop))
     .                                                     -TfSnow
C +
          TgrdAV(i,j)   =             TgrdAV(i,j)          -TfSnow
C +
      DO k=1,llx
          TsolAV(i,j,k) = 0.0d+0
          HsolAV(i,j,k) = 0.0d+0
        DO msc=1,nvx
          TsolAV(i,j,k) = TsolAV(i,j,k)
     .   +ifraTV(i,j,msc)*TsolTV(i,j,msc,k)
          HsolAV(i,j,k) = HsolAV(i,j,k)
     .   +ifraTV(i,j,msc)*eta_TV(i,j,msc,k)
        END DO
          TsolAV(i,j,k) = TsolAV(i,j,k) * 1.0e-2
          HsolAV(i,j,k) = HsolAV(i,j,k) * 1.0e-2
      END DO
      END DO
      END DO
C +
C +
C +   ************
      CALL UNwrite (ID__nc, 'TsolAV ', ipr_nc, mx, my, llx    , TsolAV)
      CALL UNwrite (ID__nc, 'Tveg_1 ', ipr_nc, mx, my, 1      , WKxy1 )
      CALL UNwrite (ID__nc, 'Tveg_2 ', ipr_nc, mx, my, 1      , WKxy2 )
      CALL UNwrite (ID__nc, 'Tsol_1 ', ipr_nc, mx, my, 1      , Tgrd_1)
      CALL UNwrite (ID__nc, 'Tsol_2 ', ipr_nc, mx, my, 1      , Tgrd_2)
      CALL UNwrite (ID__nc, 'TgrdAV ', ipr_nc, mx, my, 1      , TgrdAV)
      CALL UNwrite (ID__nc, 'TS_Obs ', ipr_nc, mx, my, 1      , cuTobs)
      CALL UNwrite (ID__nc, 'HsolAV ', ipr_nc, mx, my, llx    , HsolAV)
      CALL UNwrite (ID__nc, 'HgrdAV ', ipr_nc, mx, my, 1      , HgrdAV)
C +   ************
C +
C +
      DO j=1,my
      DO i=1,mx
        WKxy1(i,j) = SOsoNC(i,j,1)             ! Absorbed Solar Radiation
        WKxy2(i,j) = IRsoNC(i,j,1)             ! Absorbed IR    Radiation
        WKxy3(i,j) = HSsoNC(i,j,1)             ! Absorbed Sensible Heat Flux
        WKxy4(i,j) = HLsoNC(i,j,1)             ! Absorbed Latent   Heat Flux
        WKxy5(i,j) = SOsoNC(i,j,min(2,nsx))    ! Absorbed Solar Radiation
        WKxy6(i,j) = IRsoNC(i,j,min(2,nsx))    ! Absorbed IR    Radiation
        WKxy7(i,j) = HSsoNC(i,j,min(2,nsx))    ! Absorbed Sensible Heat Flux
        WKxy8(i,j) = HLsoNC(i,j,min(2,nsx))    ! Absorbed Latent   Heat Flux
      END DO
      END DO
C +
C +
C +   ************
      CALL UNwrite (ID__nc, 'Solar1 ', ipr_nc, mx, my, 1      , WKxy1 )
      CALL UNwrite (ID__nc, 'IR___1 ', ipr_nc, mx, my, 1      , WKxy2 )
      CALL UNwrite (ID__nc, 'HS___1 ', ipr_nc, mx, my, 1      , WKxy3 )
      CALL UNwrite (ID__nc, 'HL___1 ', ipr_nc, mx, my, 1      , WKxy4 )
      CALL UNwrite (ID__nc, 'Solar2 ', ipr_nc, mx, my, 1      , WKxy5 )
      CALL UNwrite (ID__nc, 'IR___2 ', ipr_nc, mx, my, 1      , WKxy6 )
      CALL UNwrite (ID__nc, 'HS___2 ', ipr_nc, mx, my, 1      , WKxy7 )
      CALL UNwrite (ID__nc, 'HL___2 ', ipr_nc, mx, my, 1      , WKxy8 )
C +   ************
C +
C +
      DO j=1,my
      DO i=1,mx
        WKxy1(i,j) = HLs_NC(i,j,1)             ! Evaporation
        WKxy2(i,j) = HLv_NC(i,j,1)             ! Transpiration
        WKxy3(i,j) = eta_NC(i,j,1)             ! Soil Humidity
        WKxy4(i,j) = CaSnTV(i,j,1)             ! Snow on Vegetation
        WKxy5(i,j) = HLs_NC(i,j,min(2,nsx))    ! Evaporation
        WKxy6(i,j) = HLv_NC(i,j,min(2,nsx))    ! Transpiration
        WKxy7(i,j) = eta_NC(i,j,min(2,nsx))    ! Soil Humidity
        WKxy8(i,j) = CaSnTV(i,j,min(2,nsx))    ! Snow on Vegetation
      END DO
      END DO
C +
C +
C +   ************
      CALL UNwrite (ID__nc, 'HLs__1 ', ipr_nc, mx, my, 1      , WKxy1 )
      CALL UNwrite (ID__nc, 'HLv__1 ', ipr_nc, mx, my, 1      , WKxy2 )
      CALL UNwrite (ID__nc, 'eta__1 ', ipr_nc, mx, my, 1      , WKxy3 )
      CALL UNwrite (ID__nc, 'VegSN1 ', ipr_nc, mx, my, 1      , WKxy4 )
      CALL UNwrite (ID__nc, 'HLs__2 ', ipr_nc, mx, my, 1      , WKxy5 )
      CALL UNwrite (ID__nc, 'HLv__2 ', ipr_nc, mx, my, 1      , WKxy6 )
      CALL UNwrite (ID__nc, 'eta__2 ', ipr_nc, mx, my, 1      , WKxy7 )
      CALL UNwrite (ID__nc, 'VegSN2 ', ipr_nc, mx, my, 1      , WKxy8 )
C +   ************
C +
C +
C +--That 's all, folks: NetCDF File Closure
C +  =======================================
C +
C +   ***********
      CALL NCCLOS (ID__nc,RCODE)
C +   ***********
C +
C +
C +--Work Arrays Reset
C +  =================
C +
      do j=1,my
      do i=1,mx
        WKxy1(i,j)   =0.0
        WKxy2(i,j)   =0.0
        WKxy3(i,j)   =0.0
        WKxy4(i,j)   =0.0
        WKxy5(i,j)   =0.0
        WKxy6(i,j)   =0.0
        WKxy7(i,j)   =0.0
        WKxy8(i,j)   =0.0
        WKxy9(i,j)   =0.0
      enddo
      enddo
C +
      return
      end