*-- Author :    Michelangelo Mangano
C----------------------------------------------------------------------
      SUBROUTINE UPVETO(IPVETO)
C----------------------------------------------------------------------
C     subroutine to implement the MLM jet matching criterion
C----------------------------------------------------------------------
      IMPLICIT NONE
      include 'alpinput.inc'
C...GUP Event common block
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,
     &              IDUP(MAXNUP),ISTUP(MAXNUP),MOTHUP(2,MAXNUP),
     &              ICOLUP(2,MAXNUP),PUP(5,MAXNUP),VTIMUP(MAXNUP),
     &              SPINUP(MAXNUP)
C...HEPEVT commonblock.
      INTEGER NMXHEP,NEVHEP,NHEP,ISTHEP,IDHEP,JMOHEP,JDAHEP
      PARAMETER (NMXHEP=4000)
      COMMON/HEPEVT/NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),PHEP(5,NMXHEP),VHEP(4,NMXHEP)
      DOUBLE PRECISION PHEP,VHEP
      SAVE /HEPEVT/
C
      INCLUDE 'alpsho.inc'
      INTEGER IPVETO
C     CALSIM AND JET VARIABLES                             
      INTEGER NCY,NCPHI,NJMAX,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,ET,DELPHI,CPHCAL,SPHCAL,DELY,
     &     CTHCAL,STHCAL,PCJET,ETJET,PI
      PARAMETER (NCY=100)
      PARAMETER (NCPHI=60,PI=3.141593D0)
      COMMON/CALOR/DELY,DELPHI,ET(NCY,NCPHI),
     $     CTHCAL(NCY),STHCAL(NCY),CPHCAL(NCPHI),SPHCAL(NCPHI),YCMIN
     $     ,YCMAX
      PARAMETER (NJMAX=500)
      COMMON/GETCOM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(NCY,NCPHI),NCJET
C     
      DOUBLE PRECISION PSERAP
      INTEGER K(NJMAX),KP(NJMAX),kpj(njmax)
c local variables
      integer i,j,ihep,nmatch,jrmin
      double precision etajet,phijet,delr,dphi,delrmin
      double precision p(4,10),pt(10),eta(10),phi(10)
      integer idbg
      parameter (idbg=0)
c
      double precision tiny
      parameter (tiny=1d-3)
      integer icount
      data icount/0/
c
c      if(icount.eq.0) call hwuepr
c      icount=icount+1
c      return
      IPVETO=0
C      WRITE (*,*) 'ICKKW:', ICKKW
      IF(ICKKW.EQ.0) RETURN
C CHECK FOR EVENT ERROR OR ZERO WGT
      I=0
C     HERWIG/PYTHIA SPECIFIC
      IF (OPTPGS.EQ.'ALPPYT') THEN
         CALL ALSHERP(I)
      ELSE IF (OPTPGS.EQ.'ALPHER') THEN
         CALL ALSHERH(I)
      ELSE
         WRITE (*,*) 'invalid PGS option in alpsho.f'
         I=1
      ENDIF
C         
      IF(I.EQ.1) RETURN
C
      IF(IHRD.EQ.7.OR.IHRD.EQ.8.OR.IHRD.EQ.13) THEN
        WRITE(*,*) 'JET MATCHING FOR HARD PROCESS ',IHRD
     $       ,' NOT IMPLEMENTED, STOP'
        STOP
      ENDIF
C
c     reconstruct parton-level event
      if(idbg.eq.1) then
        write(1,*) ' '
        write(1,*) 'new event '
        write(1,*) 'PARTONS'
      endif
      do i=1,nljets
        ihep=i+njstart
        do j=1,4
          p(j,i)=pup(j,ihep)
        enddo
        pt(i)=sqrt(p(1,i)**2+p(2,i)**2)
        eta(i)=-log(tan(0.5d0*atan2(pt(i)+tiny,p(3,i))))
        phi(i)=atan2(p(2,i),p(1,i))
        if(idbg.eq.1) then
          write(1,*) pt(i),eta(i),phi(i)
        endif
      enddo
c     Start from the partonic system
      IF(NLJETS.GT.0) CALL ALPSOR(pt,nljets,KP,2)  
c     reconstruct showered jets
c     
      if(idbg.eq.1) then
        do i=1,nhep
          write(1,111) i,isthep(i),idhep(i),jmohep(1,i),jmohep(2,i)
     $         ,phep(1,i),phep(2,i),phep(3,i)
        enddo
 111  format(5(i4,1x),3(f12.5,1x))
      endif
c      CALL PYLIST(7)
c      CALL PYLIST(2)
c      CALL PYLIST(5)
      CALL CALINI
c      CALL CALDEL(2,2,NJLAST)
      CALL CALDEL(NPFST,NPLST,NJLAST)
      CALL GETJET(RCLUS,ETCLUS,ETACLMAX)
c     analyse only events with at least nljets-reconstrcuted jets
      IF(NCJET.GT.0) CALL ALPSOR(ETJET,NCJET,K,2)              
      if(idbg.eq.1) then
        write(1,*) 'JETS'
        do i=1,ncjet
          j=k(ncjet+1-i)
          ETAJET=PSERAP(PCJET(1,j))
          PHIJET=ATAN2(PCJET(2,j),PCJET(1,j))
          write(1,*) etjet(j),etajet,phijet
        enddo
      endif
      IF(NCJET.LT.NLJETS) GOTO 999
c     associate partons and jets, using min(delr) as criterion
      NMATCH=0
      DO I=1,NCJET
        KPJ(I)=0
      ENDDO
      DO I=1,NLJETS
        DELRMIN=1D5
        DO 110 J=1,NCJET
          IF(KPJ(J).NE.0) GO TO 110
          ETAJET=PSERAP(PCJET(1,J))
          PHIJET=ATAN2(PCJET(2,J),PCJET(1,J))
          DPHI=ABS(PHI(KP(NLJETS-I+1))-PHIJET)
          IF(DPHI.GT.PI) DPHI=2.*PI-DPHI
          DELR=SQRT((ETA(KP(NLJETS-I+1))-ETAJET)**2+(DPHI)**2)
          IF(DELR.LT.DELRMIN) THEN
            DELRMIN=DELR
            JRMIN=J
          ENDIF
 110    CONTINUE
        IF(DELRMIN.LT.1.5*RCLUS) THEN
          NMATCH=NMATCH+1
          KPJ(JRMIN)=I
        ENDIF
C     WRITE(*,*) 'PARTON-JET',I,' best match:',k(ncjet+1-jrmin)
c     $           ,delrmin
      ENDDO
      IF(NMATCH.LT.NLJETS) GOTO 999
C REJECT EVENTS WITH LARGER JET MULTIPLICITY FROM EXCLUSIVE SAMPLE
      IF(NCJET.GT.NLJETS.AND.IEXC.EQ.1) GOTO 999
      RETURN
c HERWIG/PYTHIA TERMINATION:
 999  IF (OPTPGS.EQ.'ALPPYT') THEN
         CALL ALSHENP
      ELSE IF (OPTPGS.EQ.'ALPHER') THEN
         CALL ALSHENH
      ELSE
         WRITE (*,*) 'invalid PGS option in alpsho.f'
      ENDIF
          
      IPVETO=1
      END


C----------------------------------------------------------------------
      SUBROUTINE UPINIT
C----------------------------------------------------------------------
C     HERWIG/PYTHIA UNIVERSAL EVENT INITIALITION ROUTINE
C----------------------------------------------------------------------
      IMPLICIT NONE
      INCLUDE 'alpsho.inc'
      INCLUDE 'alpinput.inc'
C
      CHARACTER *3 CSHO
C--   GUP Event common block
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,
     &     IDUP(MAXNUP),ISTUP(MAXNUP),MOTHUP(2,MAXNUP),
     &     ICOLUP(2,MAXNUP),PUP(5,MAXNUP),VTIMUP(MAXNUP),
     &     SPINUP(MAXNUP)
C--   GUP common block
      INTEGER MAXPUP
      PARAMETER(MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON /HEPRUP/ IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &     IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),
     &     XMAXUP(MAXPUP),LPRUP(MAXPUP)
C     CALSIM AND JET VARIABLES                             
      INTEGER NCY,NCPHI,NJMAX,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,PI,ET,DELPHI,CPHCAL,SPHCAL,DELY,
     &     CTHCAL,STHCAL,PCJET,ETJET
      PARAMETER (NCY=100)
      PARAMETER (NCPHI=60,PI=3.141593D0)
      COMMON/CALOR/DELY,DELPHI,ET(NCY,NCPHI),
     $     CTHCAL(NCY),STHCAL(NCY),CPHCAL(NCPHI),SPHCAL(NCPHI),YCMIN
     $     ,YCMAX
C
      INTEGER IEND,INORAD
      COMMON/SHVETO/IEND,INORAD(MAXNUP)
C     LOCAL VARIABLES
      CHARACTER*70 STDUMMY
      INTEGER I,NTMP,IHEPMIN
      DOUBLE PRECISION TMP
      DOUBLE PRECISION PBEAM1,PBEAM2
C     USER ACCESS TO MATCHING PARAMETERS
      INTEGER IUSRMAT
      PARAMETER (IUSRMAT=1)
C
C      WRITE(*,*) 'INPUT NAME OF FILE CONTAINING EVENTS'
C      WRITE(*,*) '(FOR "file.unw" ENTER "file")'
C      READ(*,*) FILENAME
      FILENAME=pgs_alpgen_stem
      CALL STRCATH(FILENAME,'.unw',TMPSTR)
      call GETUNIT(NUNIT)
      OPEN(UNIT=NUNIT,FILE=TMPSTR,STATUS='OLD')
      CALL STRCATH(FILENAME,'_unw.par',TMPSTR)
      CALL GETUNIT(NUNITINI)
      OPEN(UNIT=NUNITINI,FILE=TMPSTR,STATUS='OLD')
C     OPEN A LOG FILE
C      CALL ALSHCD(CSHO)
      IF (OPTPGS.EQ.'ALPHER') THEN
         CALL ALSHCDH(CSHO)
      ELSE IF (OPTPGS.EQ.'ALPPYT') THEN
         CALL ALSHCDP(CSHO)
      ELSE
         WRITE (*,*) 'invalid PGS option in alpsho.f'
         STOP
      ENDIF
C
      IF(CSHO.EQ.'HER') THEN
        CALL STRCATH(FILENAME,'.her-log',TMPSTR)
      ELSE 
        CALL STRCATH(FILENAME,'.pyt-log',TMPSTR)
      ENDIF
      CALL GETUNIT(NUNITOUT)
      OPEN(UNIT=NUNITOUT,FILE=TMPSTR,STATUS='UNKNOWN')
C     START READING FILE
      DO I=1,10000
        READ(NUNITINI,'(A)') STDUMMY
        IF(STDUMMY(1:4).EQ.'****') GOTO 10
        WRITE(*,*) STDUMMY
        WRITE(NUNITOUT,*) STDUMMY
      ENDDO
C
C     READ IN INPUT PARAMETERS
 10   READ(NUNITINI,*) IHRD
C
c     IF(IHRD.EQ.12) THEN
c     WRITE(*,*) 'HJET PROCESSES NOT AVAILABLE AS YET'
c     STOP
c     ENDIF
      READ(NUNITINI,*) MC,MB,MT,MW,MZ,MH
      DO I=1,1000
        READ(NUNITINI,*,ERR=20) NTMP,TMP 
        PARVAL(NTMP)=TMP
      ENDDO
 20   CONTINUE
      READ(NUNITINI,*) AVGWGT,ERRWGT
      READ(NUNITINI,*) UNWEV,TOTLUM
      WRITE(NUNITOUT,*) " "
      WRITE(NUNITOUT,*) "INPUT CROSS SECTION (PB):",AVGWGT," +/-",ERRWGT
      WRITE(NUNITOUT,*) "NUMBER OF INPUT EVENTS:",UNWEV
      WRITE(NUNITOUT,*) "INTEGRATED LUMINOSITY:",TOTLUM
C     WRITE PARAMETER VALUES
      CALL AHSPAR
      PBEAM1=DBLE(EBEAM)
      PBEAM2=DBLE(EBEAM)
      IH1=1
C     CONVERT PDF TYPES
      CALL PDFCONVH(NDNS,NTMP,PDFTYP)
C     DEFINE RANGE FOR PARTONS TO BE USED IN MATCHING
      NLJETS=PARVAL(10)     !  NJETS
      DO I=1,MAXNUP
        INORAD(I)=0
      ENDDO
      IF (OPTPGS.EQ.'ALPHER') THEN
         CALL ALSHCDH(CSHO)
      ELSE IF (OPTPGS.EQ.'ALPPYT') THEN
         CALL ALSHCDP(CSHO)
      ELSE
         WRITE (*,*) 'invalid PGS option in alpsho.f'
         STOP
      ENDIF
C      CALL ALSHCD(CSHO)
      IF(CSHO.EQ.'HER') THEN
        NPFST=149
        NPLST=149
C     HERWIG: ALL SHOWERS ORIGINATE FROM IHEP=6
        IEND=6
C     HERWIG: HEPEVT EVENT RECORD FOR FINAL STATE STARTS AT 7=6+1
        IHEPMIN=6
      ELSE
        NPFST=1
        NPLST=1
C     PYTHIA: ALL SHOWERS ORIGINATE FROM IHEP=O
        IEND=0
C     PYTHIA: HEPEVT EVENT RECORD FOR FINAL STATE STARTS AT 1=0+1
        IHEPMIN=0
        IDPRUP=661
      ENDIF
      IF(IHRD.LE.2) THEN
C        NLJETS=NPART-6
        NJSTART=4
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM THE W
        INORAD(IHEPMIN+2+NLJETS+1)=1
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM HEAVY QUARK
C     PAIR
        INORAD(IHEPMIN+1)=1
        INORAD(IHEPMIN+2)=1
      ELSEIF(IHRD.LE.4) THEN
C        NLJETS=NPART-4
        NJSTART=2
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM THE W
        IF(CSHO.EQ.'HER'.AND.NLJETS.EQ.0) THEN
C     ALLOW RADIATION FROM IHEPMIN+1 IN HERWIG WHEN NJET=0
          INORAD(IHEPMIN+NLJETS+1)=0
        ELSE 
          INORAD(IHEPMIN+NLJETS+1)=1
        ENDIF
      ELSEIF(IHRD.EQ.5) THEN
C        NLJETS=NPART-3*(NW+NZ)-NH-2
        NJSTART=2
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM THE W
        IF(CSHO.EQ.'HER'.AND.NLJETS.EQ.0.AND.(NW+NZ+NH).EQ.1) THEN
C     ALLOW RADIATION FROM IHEPMIN+1 IN HERWIG WHEN NJET=0 AND NW+NZ+NH
C     =1
          INORAD(IHEPMIN+NLJETS+1)=0
        ELSE 
          DO I=1,NW+NZ+NH
            INORAD(IHEPMIN+NLJETS+I)=1
          ENDDO
        ENDIF
      ELSEIF(IHRD.EQ.6) THEN
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM HEAVY QUARK
C     PAIR
        INORAD(IHEPMIN+1)=1
        INORAD(IHEPMIN+2)=1
        if(ihvy.eq.6) then
C          NLJETS=NPART-8
          NJSTART=4
        elseif(ihvy.eq.5) then
C          NLJETS=NPART-4
          NJSTART=4
        endif
        NJLAST=155
      ELSEIF(IHRD.EQ.9) THEN
C        NLJETS=NPART-2
        NJSTART=2
        NJLAST=155
      ELSEIF(IHRD.EQ.10) THEN
C        NLJETS=NPART-4
        NJSTART=2
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM THE W
        INORAD(IHEPMIN+NLJETS+1)=1
      ELSEIF(IHRD.EQ.11) THEN
C        NLJETS=NPART-2-NPH
        NJSTART=2
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING THE HARD PHOTONS
        DO I=1,NPH
          INORAD(IHEPMIN+NLJETS+I)=1
        ENDDO
      ELSEIF(IHRD.EQ.12) THEN
C        NLJETS=NPART-2-NH
        NJSTART=2
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING THE HIGGS DECAY PRODUCTS
        IF(NLJETS+NH.GT.1) THEN
          DO I=1,NH
            INORAD(IHEPMIN+NLJETS+I)=1
          ENDDO
        ELSE
          IF(CSHO.EQ.'HER'.AND.NLJETS.EQ.0) THEN
C     ALLOW RADIATION FROM IHEPMIN+1 IN HERWIG WHEN NJET=0
            INORAD(IHEPMIN+1)=0
          ELSE 
            INORAD(IHEPMIN+NLJETS+1)=1
          ENDIF
        ENDIF
      ELSEIF(IHRD.EQ.14) THEN
C        NLJETS=NPART-4-NPH
        NJSTART=2
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM THE W
        IF(CSHO.EQ.'HER'.AND.NLJETS.EQ.0.AND.NPH.EQ.0) THEN
C     ALLOW RADIATION FROM IHEPMIN+1 IN HERWIG WHEN NJET=0
          INORAD(IHEPMIN+NLJETS+1)=0
        ELSE 
          INORAD(IHEPMIN+NLJETS+1)=1
        ENDIF
      ELSEIF(IHRD.EQ.15) THEN
C        NLJETS=NPART-6-NPH
        NJSTART=2
        NJLAST=155
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM THE W
        INORAD(IHEPMIN+2+NLJETS+NPH+1)=1
C     DO NOT INCLUDE IN MATCHING RADIATION ORIGINATING FROM HEAVY QUARK
C     PAIR
C     NOTICE THAT HERE THE LIGHT JETS PRECEDE THE QQ PAIR
        INORAD(IHEPMIN+NLJETS+1)=1
        INORAD(IHEPMIN+NLJETS+2)=1
      ENDIF
C
C     INPUT JET MATCHING CRITERIA
      YCMAX=ETAJMAX+2*DRJMIN
      YCMIN=-YCMAX
      IF(ICKKW.EQ.1) THEN
        WRITE(*,*) ' '
        WRITE(*,*) 'INPUT 0 FOR INCLUSIVE JET SAMPLE, 1 FOR EXCLUSIVE'
        WRITE(*,*) '(SELECT 0 FOR HIGHEST PARTON MULTIPLICITY SAMPLE)' 
        WRITE(*,*) '(SELECT 1 OTHERWISE)'
        READ(*,*) IEXC
        IF(IUSRMAT.EQ.1) THEN
          WRITE(*,*) ' '
          WRITE(*,*) 'INPUT ET(CLUS), R(CLUS)'
          IF(NLJETS.GT.0) THEN
            WRITE(*,*) '(SUGGESTED VALUES:',PTJMIN,DRJMIN,')'
            READ(*,*) ETCLUS,RCLUS
          ELSE
            WRITE(*,*) '(MUST MATCH VALUES USED IN GENERATION',
     +           ' OF NJET>0 EVENTS)'
            READ(*,*) ETCLUS,RCLUS
            IF(IEXC.EQ.1) THEN
              WRITE(*,*) 'INPUT MAX(ETA) FOR JET VETO'
              WRITE(*,*) '(MUST MATCH ETAJMAX USED IN GENERATION',
     +             ' OF NJET>0 EVENTS)'
              READ(*,*) ETAJMAX
            ENDIF 
          ENDIF
          ETACLMAX=ETAJMAX+DRJMIN
        ELSEIF(IUSRMAT.EQ.0) THEN
          ETCLUS=PTJMIN
          RCLUS=DRJMIN
          ETACLMAX=ETAJMAX+DRJMIN
        ELSE
          WRITE(*,*) 'IUSRMAT=0 OR 1 ONLY VALID PARAMETERS'
          WRITE(*,*) 'FOR SETTING OF MATCHING PARAMETERS'
          STOP
        ENDIF
        WRITE(*,*) ' '
        WRITE(*,*) 'JET PARAMETERS FOR MATCHING:'
        WRITE(*,*) 'ET>',ETCLUS,' R=',RCLUS
        WRITE(*,*) 'DR(PARTON-JET)<',1.5*RCLUS
      ENDIF
C
C     FROM NOW ON, PROCESS THE INFORMATION READ IN, TO COMPLETE SETTING
C     UP THE GUP COMMON
C
C--   SET UP THE BEAMS
C--   ID'S OF BEAM PARTICLES
      IF(IH1.EQ.1) THEN
        IDBMUP(1) = 2212
      ELSEIF(IH1.EQ.-1) THEN
        IDBMUP(1) =-2212
      ELSE
        WRITE(*,*) 'BEAM 1 NOT PROPERLY INITIALISED, STOP'
        STOP
      ENDIF
      IF(IH2.EQ.1) THEN
        IDBMUP(2) = 2212
      ELSEIF(IH2.EQ.-1) THEN
        IDBMUP(2) =-2212
      ELSE
        WRITE(*,*) 'BEAM 2 NOT PROPERLY INITIALISED, STOP'
        STOP
      ENDIF
      EBMUP(1) = ABS(PBEAM1)
      EBMUP(2) = ABS(PBEAM2)
C--   PDF'S FOR THE BEAMS; WILL BE EVALUATED USING THE NDNS VARIABLE
C     READ IN EARLIER
      PDFGUP(1) = -1
      PDFGUP(2) = -1
      PDFSUP(1) = -1
      PDFSUP(2) = -1
C--   WHAT DO DO WITH THE WEIGHTS(WE ARE GENERATING UNWEIGHTED EVENTS)
      IDWTUP = 3
C--   ONLY ONE PROCESS
      NPRUP  = 1
C--   CROSS SECTION
      XSECUP(1) = avgwgt
C--   ERROR ON THE CROSS SECTION
      XERRUP(1) = errwgt
C--   MAXIMUM WEIGHT
      XMAXUP(1) = avgwgt
C--   HERWIG/PYTHIA SPECIFIC PART
      IF (OPTPGS.EQ.'ALPHER') THEN
         CALL ALSHINH(I)
      ELSE IF (OPTPGS.EQ.'ALPPYT') THEN
         CALL ALSHINP(I)
      ELSE
         WRITE (*,*) 'invalid PGS option in alpsho.f'
         STOP
      ENDIF
C      CALL ALSHIN(I)
      LPRUP(1) = I
      END

C     DECK  ID>, UPEVNT.
*     CMZ :-        -13/02/02  07.20.46  by  Peter Richardson
*--   Author :    Michelangelo Mangano
C----------------------------------------------------------------------
      SUBROUTINE UPEVNT
C----------------------------------------------------------------------
c     Puts Alpgen event into GUPI common block HEPEU
c----------------------------------------------------------------------
      implicit none
      INCLUDE 'alpsho.inc'
      INCLUDE 'alpinput.inc'
C--   GUP Event common block
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,
     &     IDUP(MAXNUP),ISTUP(MAXNUP),MOTHUP(2,MAXNUP),
     &     ICOLUP(2,MAXNUP),PUP(5,MAXNUP),VTIMUP(MAXNUP),
     &     SPINUP(MAXNUP)
C--   GUP Run common block
      INTEGER MAXPUP
      PARAMETER(MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON /HEPRUP/ IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &     IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),
     &     XMAXUP(MAXPUP),LPRUP(MAXPUP)
c     
c     local variables
      INTEGER INIT
      DATA INIT/0/
      CHARACTER *3 CSHO
      INTEGER MAXPAR
      PARAMETER (MAXPAR=100)
      INTEGER NEV,IPROC,IFL(MAXPAR)
      REAL SQ,SP(3,MAXPAR),SM(MAXPAR),SWGTRES
      INTEGER I,IUP,IWCH,IST
      REAL *8 TMP,WGTRES
C     LOCAL VARIABLES FOR TOP DECAYS
      INTEGER IT,ITB,IW,IWDEC,IBUP,IWUP
C     LOCAL VARIABLES TOP HIGGS DECAYS
      INTEGER IH
C     LOCAL VARIABLES FOR GAUGE BOSON  DECAYS
      INTEGER IVSTART,IVEND,NVB
C     
C UPDATE MAXIMUM NMBER OF ALLOWED ERRORS
      IF (OPTPGS.EQ.'ALPHER') THEN
         CALL ALSHERH(I)
      ELSE IF (OPTPGS.EQ.'ALPPYT') THEN 
         CALL ALSHERP(I)
      ELSE
         WRITE (*,*) 'invalid PGS option in alpsho.f'
         STOP
      ENDIF
C      WRITE (*,*) 'aaron debug, i=', I
C      CALL ALSHER(I)
C
      IST=0
C     INPUT EVENT NUMBER, PROCESS TYPE, N PARTONS, SAMPLE'S AVERAGE
C     WEIGHT AND QSCALE
      READ(NUNIT,2,END=500,ERR=501) NEV,IPROC,NPART,SWGTRES,SQ
 2    FORMAT(I8,1X,I4,1X,I2,2(1X,E12.6))
C     FLAVOUR, COLOUR AND Z-MOMENTUM OF INCOMING PARTONS
      READ(NUNIT,8) IFL(1),ICOLUP(1,1),ICOLUP(2,1),SP(3,1)
      READ(NUNIT,8) IFL(2),ICOLUP(1,2),ICOLUP(2,2),SP(3,2)
C     FLAVOUR, COLOUR, 3-MOMENTUM AND MASS OF OUTGOING PARTONS
      DO I=3,NPART
        READ(NUNIT,9) IFL(I),ICOLUP(1,I),ICOLUP(2,I),SP(1,I),SP(2,I)
     $       ,SP(3,I),SM(I)
      ENDDO
 8    FORMAT(I8,1X,2(I4,1X),F10.3)
 9    FORMAT(I8,1X,2(I4,1X),4(1X,F10.3))
C     
C     START PROCESSING INPUT DATA
C     
C     SCALES AND WEIGHTS
      SCALUP=DBLE(SQ)
      IF(IDWTUP.EQ.3) THEN
	XWGTUP=DBLE(SWGTRES) !AVGWGT
      ELSE
        WRITE(*,*) 'ONLY UNWEIGHTED EVENTS ACCEPTED AS INPUT, STOP'
        STOP
      ENDIF
c     
c---  incoming lines
      do 100 i=1,2
        iup=i
        idup(iup)=ifl(i)
        istup(iup)=-1
        mothup(1,iup)=0
        mothup(2,iup)=0
        pup(1,iup)=0.
        pup(2,iup)=0.
        pup(3,iup)=dble(Sp(3,iup))
        pup(4,iup)=abs(pup(3,iup))
        pup(5,iup)=0d0
 100  continue
c---  outgoing lines
      do 110 i=3,npart
        iup=i
        idup(iup)=ifl(i)
        istup(iup)=1
        mothup(1,iup)=1
        mothup(2,iup)=2
        pup(1,iup)=dble(Sp(1,i))
        pup(2,iup)=dble(Sp(2,i))
        pup(3,iup)=dble(Sp(3,i))
        pup(5,iup)=dble(Sm(i))
        tmp=(pup(5,iup)**2+pup(1,iup)**2+pup(2,iup)**2+pup(3,iup)**2)
        pup(4,iup)=sqrt(tmp)
 110  continue
c     
      nup=npart
c---  set up colour structure labels
      Do iup=1,nup
        if(icolup(1,iup).ne.0) icolup(1,iup)=icolup(1,iup)+500
        if(icolup(2,iup).ne.0) icolup(2,iup)=icolup(2,iup)+500
      Enddo
c     
c     
c     and now consider assignements specific to individual hard
C     processes
c     
c---  W/Z/gamma b bbar + jets, or W/Z + jets
      if (ihrd.le.4.or.ihrd.eq.10) then
        iwch=0
        do iup=nup-1,nup
          mothup(1,iup)=nup+1
          mothup(2,iup)=0
          if(ihrd.ne.2) iwch=iwch+idup(iup)
c     electron+nubar -> 11 + (-12) = -1 => W-
c     positron+nu    -> -11+ 12    =  1 => W+
        enddo
        iup=nup+1
        If (iwch.gt.0) then
          idup(iup)=24
        Elseif (iwch.lt.0) then
          idup(iup)=-24
        Else
          idup(iup)=23
        Endif
        istup(iup)=2
        mothup(1,iup)=1
        mothup(2,iup)=2
        tmp=pup(4,iup-2)+pup(4,iup-1)
        pup(4,iup)=tmp
        tmp=tmp**2
        do i=1,3
          pup(i,iup)=pup(i,iup-2)+pup(i,iup-1)
          tmp=tmp-pup(i,iup)**2
        enddo
        pup(5,iup)=sqrt(tmp)
        nup=nup+1
        icolup(1,nup)=0
        icolup(2,nup)=0
c---  nW + mZ + kH + jets
      elseif (ihrd.eq.5) then
c     find first gauge bosons
        ivstart=0
        ivend=0
        do i=1,npart
          if(abs(idup(i)).eq.24.or.idup(i).eq.23) then
            istup(i)=2
            if(ivstart.eq.0) ivstart=i
            ivend=i+1
          endif
        enddo
        nvb=ivend-ivstart
c     decay products pointers, starting from the end
        do i=1,nvb
          mothup(1,npart-2*i+2)=ivend-i
          mothup(1,npart-2*i+1)=ivend-i
          mothup(2,npart-2*i+2)=0
          mothup(2,npart-2*i+1)=0
        enddo
c---  t tbar + jets
c     t tb jets f fbar f fbar W+ b W- bbar
      elseif (ihrd.eq.6.and.abs(ifl(3)).eq.6) then
c     reset top status codes
        istup(3)=2
        istup(4)=2
        if(ifl(3).eq.6) then
          it=3
          itb=4
        else
          it=4
          itb=3
        endif
c     reconstruct W's from decay products
        do iw=1,2
          iwdec=nup-5+2*iw
          iwup=nup+iw
          ibup=iwup+2
          iwch=0
          do iup=iwdec,iwdec+1
            mothup(1,iup)=iwup
            mothup(2,iup)=0
            iwch=iwch-mod(idup(iup),2)
c     electron+nubar -> 11 + (-12) = -1 => W-
c     d + ubar -> 1 + (-2) = -1 => W-
c     positron+nu    -> -11+ 12    =  1 => W+
c     u + dbar -> 2 + (-1) = 1 => W+
          enddo
          If (iwch.gt.0) then
            idup(iwup)=24
            idup(ibup)=5
            mothup(1,iwup)=it
            mothup(2,iwup)=0
            mothup(1,ibup)=it
            mothup(2,ibup)=0
          Elseif (iwch.lt.0) then
            idup(iwup)=-24
            idup(ibup)=-5
            mothup(1,iwup)=itb
            mothup(2,iwup)=0
            mothup(1,ibup)=itb
            mothup(2,ibup)=0
          Endif
          istup(iwup)=2
          istup(ibup)=1
c     reconstruct W momentum
          tmp=pup(4,iwdec)+pup(4,iwdec+1)
          pup(4,iwup)=tmp
          tmp=tmp**2
          do i=1,3
            pup(i,iwup)=pup(i,iwdec)+pup(i,iwdec+1)
            tmp=tmp-pup(i,iwup)**2
          enddo
          pup(5,iwup)=sqrt(tmp)
c     reconstruct b momentum
          tmp=pup(4,mothup(1,iwup))-pup(4,iwup)
          pup(4,ibup)=tmp 
          tmp=tmp**2
          do i=1,3
            pup(i,ibup)=pup(i,mothup(1,iwup))-pup(i,iwup)
            tmp=tmp-pup(i,ibup)**2
          enddo
          pup(5,ibup)=sqrt(tmp)
          icolup(1,iwup)=0
          icolup(2,iwup)=0
          icolup(1,ibup)=icolup(1,mothup(1,iwup))
          icolup(2,ibup)=icolup(2,mothup(1,iwup))
        enddo
c     stop
        nup=nup+4
c---  H t tbar + jets
c     H t tb jets f fbar f fbar W+ b W- bbar
      elseif (ihrd.eq.8.and.abs(ifl(4)).eq.6) then
c     reset top status codes
        istup(4)=2
        istup(5)=2
        if(ifl(4).eq.6) then
          it=4
          itb=5
        else
          it=5
          itb=4
        endif
c     reconstruct W's from decay products
        do iw=1,2
          iwdec=nup-5+2*iw
          iwup=nup+iw
          ibup=iwup+2
          iwch=0
          do iup=iwdec,iwdec+1
            mothup(1,iup)=iwup
            mothup(2,iup)=0
            iwch=iwch-mod(idup(iup),2)
c     electron+nubar -> 11 + (-12) = -1 => W-
c     d + ubar -> 1 + (-2) = -1 => W-
c     positron+nu    -> -11+ 12    =  1 => W+
c     u + dbar -> 2 + (-1) = 1 => W+
          enddo
          If (iwch.gt.0) then
            idup(iwup)=24
            idup(ibup)=5
            mothup(1,iwup)=it
            mothup(2,iwup)=0
            mothup(1,ibup)=it
            mothup(2,ibup)=0
          elseif (iwch.lt.0) then
            idup(iwup)=-24
            idup(ibup)=-5
            mothup(1,iwup)=itb
            mothup(2,iwup)=0
            mothup(1,ibup)=itb
            mothup(2,ibup)=0
          endif
          istup(iwup)=2
          istup(ibup)=1
c     reconstruct W momentum
          tmp=pup(4,iwdec)+pup(4,iwdec+1)
          pup(4,iwup)=tmp
          tmp=tmp**2
          do i=1,3
            pup(i,iwup)=pup(i,iwdec)+pup(i,iwdec+1)
            tmp=tmp-pup(i,iwup)**2
          enddo
          pup(5,iwup)=sqrt(tmp)
c     reconstruct b momentum
          tmp=pup(4,mothup(1,iwup))-pup(4,iwup)
          pup(4,ibup)=tmp 
          tmp=tmp**2
          do i=1,3
            pup(i,ibup)=pup(i,mothup(1,iwup))-pup(i,iwup)
            tmp=tmp-pup(i,ibup)**2
          enddo
          pup(5,ibup)=sqrt(tmp)
          icolup(1,iwup)=0
          icolup(2,iwup)=0
          icolup(1,ibup)=icolup(1,mothup(1,iwup))
          icolup(2,ibup)=icolup(2,mothup(1,iwup))
        enddo
c     stop
        nup=nup+4
c---  SINGLE TOP
c     Input: T  
c     output: jets t b w f fbar t b w f fbar 
      elseif (ihrd.eq.13) then
        nw=1
        if(itopprc.ge.3) nw=2
c     assign mass to the incoming bottom quark, if required
        DO I=1,2
          IF(ABS(IFL(I)).EQ.5) THEN
            IUP=I
            PUP(5,IUP)=mb
            PUP(4,IUP)=SQRT(PUP(3,IUP)**2+PUP(5,IUP)**2)
          ENDIF
        ENDDO
        istup(3)=2
        it=0
        itb=0
        if(ifl(3).eq.6) then
          it=3
        elseif(ifl(3).eq.-6) then
          itb=3
        else
          write(*,*) 'wrong assumption about top position, stop'
          stop
        endif
c
c     TOP DECAY
c     reconstruct W's from decay products
c
c iwdec: 1st W decay product.
        if(nw.eq.1) then
          iwdec=nup-1
        elseif(nw.eq.2) then
          iwdec=nup-3
        endif
c put W and b  at the end
        iwup=nup+1
        ibup=iwup+1
c
        iwch=0
        do iup=iwdec,iwdec+1
          mothup(1,iup)=iwup
          mothup(2,iup)=0
          iwch=iwch-mod(idup(iup),2)
c     electron+nubar -> 11 + (-12) = -1 => W-
c     d + ubar -> 1 + (-2) = -1 => W-
c     positron+nu    -> -11+ 12    =  1 => W+
c     u + dbar -> 2 + (-1) = 1 => W+
        enddo
        If (iwch.gt.0) then
          idup(iwup)=24
          idup(ibup)=5
          mothup(1,iwup)=it
          mothup(2,iwup)=0
          mothup(1,ibup)=it
          mothup(2,ibup)=0
        Elseif (iwch.lt.0) then
          idup(iwup)=-24
          idup(ibup)=-5
          mothup(1,iwup)=itb
          mothup(2,iwup)=0
          mothup(1,ibup)=itb
          mothup(2,ibup)=0
        Endif
        istup(iwup)=2
        istup(ibup)=1
c     reconstruct W momentum
        tmp=pup(4,iwdec)+pup(4,iwdec+1)
        pup(4,iwup)=tmp
        tmp=tmp**2
        do i=1,3
          pup(i,iwup)=pup(i,iwdec)+pup(i,iwdec+1)
          tmp=tmp-pup(i,iwup)**2
        enddo
        pup(5,iwup)=sqrt(tmp)
c     reconstruct b momentum
        tmp=pup(4,mothup(1,iwup))-pup(4,iwup)
        pup(4,ibup)=tmp 
        tmp=tmp**2
        do i=1,3
          pup(i,ibup)=pup(i,mothup(1,iwup))-pup(i,iwup)
          tmp=tmp-pup(i,ibup)**2
        enddo
c        write(*,*) (pup(i,ibup),i=1,4),sqrt((tmp))
        pup(5,ibup)=sqrt(tmp)
        icolup(1,iwup)=0
        icolup(2,iwup)=0
        icolup(1,ibup)=icolup(1,mothup(1,iwup))
        icolup(2,ibup)=icolup(2,mothup(1,iwup))
c     
        nup=nup+2
        if(nw.eq.2) then
c
c     W DECAY
c
c iwdec: 1st W decay product. 
          iwdec=nup-3
c iwup: location of the W in the event record
          iwup=nup-6
          iwch=0
          do iup=iwdec,iwdec+1
            mothup(1,iup)=iwup
            mothup(2,iup)=0
            iwch=iwch-mod(idup(iup),2)
c     electron+nubar -> 11 + (-12) = -1 => W-
c     d + ubar -> 1 + (-2) = -1 => W-
c     positron+nu    -> -11+ 12    =  1 => W+
c     u + dbar -> 2 + (-1) = 1 => W+
          enddo
          istup(iwup)=2
          icolup(1,iwup)=0
          icolup(2,iwup)=0
        endif
      endif
c     herwig debugging:
c      call HWUPUP
      return
c     
c     
c     end of file
 500  ist=1
c     error reading file
 501  if(ist.eq.0) ist=2
C     RESET CROSS-SECTION INFORMATION FOR END OF RUN AND FINALIZE
      IF(IST.GT.0) THEN

         IF (OPTPGS.EQ.'ALPHER') THEN
            CALL ALSFINH
         ELSE IF (OPTPGS.EQ.'ALPPYT') THEN 
            CALL ALSFINP
         ELSE
            WRITE (*,*) 'invalid PGS option in alpsho.f'
            STOP
         ENDIF
C        CALL ALSFIN
      ENDIF
      close(Nunit)
      close(NunitOut)
      END

c-------------------------------------------------------------------
      subroutine AHspar
c     set list of parameters types and assign default values
c-------------------------------------------------------------------
      implicit none
      INCLUDE 'alpsho.inc'
c
      ih2=parval(2)
      ebeam=parval(3)
      ndns=parval(4)
      ickkw=parval(7)
      ihvy=parval(11)
      ihvy2=parval(12)
      nw=parval(13)
      nz=parval(14)
      nh=parval(15)
      nph=parval(16)
      ptjmin=parval(30)
      ptbmin=parval(31)
      ptcmin=parval(32)
      ptlmin=parval(33)
      metmin=parval(34)
      ptphmin=parval(35)
      etajmax=parval(40)
      etabmax=parval(41)
      etacmax=parval(42)
      etalmax=parval(43)
      etaphmax=parval(44)
      drjmin=parval(50)
      drbmin=parval(51)
      drcmin=parval(52)
      drlmin=parval(55)
      drphjmin=parval(56)
      drphlmin=parval(57)
      mllmin=parval(61)
      mllmax=parval(62)
      itopprc=parval(102)
c
      end

CDECK  ID>, STRNUM.
*CMZ :-        -13/02/02  07.20.46  by  Peter Richardson
*-- Author :    Michelangelo Mangano
C----------------------------------------------------------------------
      subroutine strnumH(string,num)
C----------------------------------------------------------------------
c- writes the number num on the string string starting at the blank
c- following the last non-blank character
C----------------------------------------------------------------------
      character * (*) string
      character * 20 tmp
      l = len(string)
      write(tmp,'(i15)')num
      j=1
      dowhile(tmp(j:j).eq.' ')
        j=j+1
      enddo
      ipos = istrlH(string)
      ito = ipos+1+(15-j)
      if(ito.gt.l) then
         write(*,*)'error, string too short'
         write(*,*) string
         stop
      endif
      string(ipos+1:ito)=tmp(j:)
      end

      function istrlH(string)
c returns the position of the last non-blank character in string
      character * (*) string
      i = len(string)
      dowhile(i.gt.0.and.string(i:i).eq.' ')
         i=i-1
      enddo
      istrlH= i
      end
CDECK  ID>, STRCATH.
*CMZ :-        -13/02/02  07.20.46  by  Peter Richardson
*-- Author :    Michelangelo Mangano
C----------------------------------------------------------------------
      subroutine strcatH(str1,str2,str)
C----------------------------------------------------------------------
c concatenates str1 and str2 into str. Ignores trailing blanks of str1,str2
C----------------------------------------------------------------------
      character *(*) str1,str2,str
      l1=istrlH(str1)
      l2=istrlH(str2)
      l =len(str)
      if(l.lt.l1+l2) then
        write(*,*) str1,str2
          write(*,*) 'error: l1+l2>l in strcatH'
          write(*,*) 'l1=',l1,' str1=',str1
          write(*,*) 'l2=',l2,' str2=',str2
          write(*,*) 'l=',l
          stop
      endif
      if(l1.ne.0) str(1:l1)=str1(1:l1)
      if(l2.ne.0) str(l1+1:l1+l2)=str2(1:l2)
      if(l1+l2+1.le.l) str(l1+l2+1:l)= ' '
      end
c-------------------------------------------------------------------
      subroutine pdfconvH(nin,nout,type)
c-------------------------------------------------------------------
c converts ALPHA convention for PDF namings to hvqpdf conventions
      implicit none
      integer nin,nout
      character*25 type
      character*25 pdftyp(20,2)
      data pdftyp/
c cteq sets
     $     'CTEQ4M ','CTEQ4L ','CTEQ4HJ',
     $     'CTEQ5M ','CTEQ5L ','CTEQ5HJ',
     $     'CTEQ6M ','CTEQ6L ',12*' ',
C MRST SETS
     $     'MRST99 ',
     $     'MRST01; as=0.119','MRST01; as=0.117','MRST01; as=0.121'
     $     ,'MRST01J; as=0.121','MRST02LO',14*' '/
      integer pdfmap(20,2)
      data pdfmap/
     $   81,83,88,   101,103, 104,   131,133, 12*0,
     $  111,  185,186,187,188,189,   14*0/
c
      nout=pdfmap(mod(nin ,100),1+nin /100)
      type=pdftyp(mod(nin ,100),1+nin /100)
      
      end

C-----------------------------------------------------------------------
C----Calorimeter simulation obtained from Frank Paige 23 March 1988-----
C
C          USE
C
C     CALL CALINI
C     CALL CALSIM
C
C          THEN TO FIND JETS WITH A SIMPLIFIED VERSION OF THE UA1 JET
C          ALGORITHM WITH JET RADIUS RJET AND MINIMUM SCALAR TRANSVERSE
C          ENERGY EJCUT
C            (RJET=1., EJCUT=5. FOR UA1)
C          USE
C
C     CALL GETJET(RJET,EJCUT)
C
C
C-----------------------------------------------------------------------
C 
C          ADDED BY MIKE SEYMOUR: PARTON-LEVEL CALORIMETER. ALL PARTONS
C          ARE CONSIDERED TO BE HADRONS, SO IN FACT RESEM IS IGNORED
C
C     CALL CALPAR
C
C          HARD PARTICLE CALORIMETER. ONLY USES THOSE PARTICLES WHICH
C          CAME FROM THE HARD PROCESS, AND NOT THE UNDERLYING EVENT
C
C     CALL CALHAR
C
C-----------------------------------------------------------------------
      SUBROUTINE CALINI
C                
C          INITIALIZE CALORIMETER FOR CALSIM AND GETJET.  NOTE THAT
C          BECAUSE THE INITIALIZATION IS SEPARATE, CALSIM CAN BE
C          CALLED MORE THAN ONCE TO SIMULATE PILEUP OF SEVERAL EVENTS.
C
      IMPLICIT NONE
      INTEGER NCY,NCPHI,NJMAX,IPHI,IY,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,ET,DELPHI,PHIX,CPHCAL,SPHCAL,DELY,
     &  YX,THX,CTHCAL,STHCAL,PCJET,ETJET,PI
      PARAMETER (NCY=100)
      PARAMETER (NCPHI=60,PI=3.141593D0)
      COMMON/CALOR/DELY,DELPHI,ET(NCY,NCPHI),
     $CTHCAL(NCY),STHCAL(NCY),CPHCAL(NCPHI),SPHCAL(NCPHI),YCMIN,YCMAX
      PARAMETER (NJMAX=500)
      COMMON/GETCOM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(NCY,NCPHI),NCJET
      LOGICAL FSTCAL
      DATA FSTCAL/.TRUE./
C
C          INITIALIZE ET ARRAY.
      DO 100 IPHI=1,NCPHI
      DO 100 IY=1,NCY
100   ET(IY,IPHI)=0.
C
      IF (FSTCAL) THEN
C          CALCULATE TRIG. FUNCTIONS.
        DELPHI=2.*PI/FLOAT(NCPHI)
        DO 200 IPHI=1,NCPHI
        PHIX=DELPHI*(IPHI-.5)
        CPHCAL(IPHI)=COS(PHIX)
        SPHCAL(IPHI)=SIN(PHIX)
200     CONTINUE
        DELY=(YCMAX-YCMIN)/FLOAT(NCY)
        DO 300 IY=1,NCY
        YX=DELY*(IY-.5)+YCMIN
        THX=2.*ATAN(EXP(-YX))
        CTHCAL(IY)=COS(THX)
        STHCAL(IY)=SIN(THX)
300     CONTINUE
        FSTCAL=.FALSE.
      ENDIF
      END
C
      SUBROUTINE CALSIM
C                
C          SIMPLE CALORIMETER SIMULATION.  ASSUME UNIFORM Y AND PHI
C          BINS
C...HEPEVT commonblock.
      INTEGER NMXHEP,NEVHEP,NHEP,ISTHEP,IDHEP,JMOHEP,JDAHEP
      PARAMETER (NMXHEP=4000)
      COMMON/HEPEVT/NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),PHEP(5,NMXHEP),VHEP(4,NMXHEP)
      DOUBLE PRECISION PHEP,VHEP
      SAVE /HEPEVT/
      INTEGER NCY,NCPHI,NJMAX,IHEP,ID,IY,IPHI,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,YIP,PSERAP,
     &  PHIIP,DELY,DELPHI,EIP,ET,STHCAL,CTHCAL,CPHCAL,SPHCAL,
     &  PCJET,ETJET,PI
      PARAMETER (NCY=100)
      PARAMETER (NCPHI=60,PI=3.141593D0)
      COMMON/CALOR/DELY,DELPHI,ET(NCY,NCPHI),
     $CTHCAL(NCY),STHCAL(NCY),CPHCAL(NCPHI),SPHCAL(NCPHI),YCMIN,YCMAX
      PARAMETER (NJMAX=500)
      COMMON/GETCOM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(NCY,NCPHI),NCJET
C
C          FILL CALORIMETER
C
      DO 200 IHEP=1,NHEP
      IF (ISTHEP(IHEP).EQ.1) THEN
        YIP=PSERAP(PHEP(1,IHEP))
        IF(YIP.LT.YCMIN.OR.YIP.GT.YCMAX) GOTO 200
        ID=ABS(IDHEP(IHEP))
C---EXCLUDE TOP QUARK, LEPTONS, PROMPT PHOTONS
        IF ((ID.GE.11.AND.ID.LE.16).OR.ID.EQ.6.OR.ID.EQ.22) GOTO 200
C
        PHIIP=ATAN2(PHEP(2,IHEP),PHEP(1,IHEP))
        IF(PHIIP.LT.0.) PHIIP=PHIIP+2.*PI
        IY=INT((YIP-YCMIN)/DELY)+1
        IPHI=INT(PHIIP/DELPHI)+1
        EIP=PHEP(4,IHEP)
C            WEIGHT BY SIN(THETA)
        ET(IY,IPHI)=ET(IY,IPHI)+EIP*STHCAL(IY)
      ENDIF
  200 CONTINUE
  999 END
      SUBROUTINE GETJET(RJET,EJCUT,ETAJCUT)
C                
C          SIMPLE JET-FINDING ALGORITHM (SIMILAR TO UA1).
C
C     FIND HIGHEST REMAINING CELL > ETSTOP AND SUM SURROUNDING
C          CELLS WITH--
C            DELTA(Y)**2+DELTA(PHI)**2<RJET**2
C            ET>ECCUT.
C          KEEP JETS WITH ET>EJCUT AND ABS(ETA)<ETAJCUT
C          THE UA1 PARAMETERS ARE RJET=1.0 AND EJCUT=5.0
C                  
      IMPLICIT NONE
      INTEGER NCY,NCPHI,NJMAX,IPHI,IY,JETNO,J,K,NCJET,NPHI1,NPHI2,NY1,
     &  NY2,IPASS,IYMX,IPHIMX,ITLIS,IPHI1,IPHIX,IY1,IYX
      DOUBLE PRECISION YCMIN,YCMAX,PI,ETJET,PCJET,RJET,DELPHI,DELY,
     &  ETMAX,ET,ETSTOP,RR,ECCUT,PX,STHCAL,CPHCAL,SPHCAL,CTHCAL,EJCUT
      PARAMETER (NCY=100)
      PARAMETER (NCPHI=60,PI=3.141593D0)
      COMMON/CALOR/DELY,DELPHI,ET(NCY,NCPHI),
     &CTHCAL(NCY),STHCAL(NCY),CPHCAL(NCPHI),SPHCAL(NCPHI),YCMIN,YCMAX
      PARAMETER (NJMAX=500)
      COMMON/GETCOM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(NCY,NCPHI),NCJET
      DOUBLE PRECISION ETAJCUT,PSERAP
C
C          PARAMETERS
      DATA ECCUT/0.1D0/
      DATA ETSTOP/1.5D0/
      DATA ITLIS/6/
C
C          INITIALIZE
C
      DO 100 IPHI=1,NCPHI
      DO 100 IY=1,NCY
100   JETNO(IY,IPHI)=0
      DO 110 J=1,NJMAX
      ETJET(J)=0.
      DO 110 K=1,4
110   PCJET(K,J)=0.
      NCJET=0
      NPHI1=RJET/DELPHI
      NPHI2=2*NPHI1+1
      NY1=RJET/DELY
      NY2=2*NY1+1
      IPASS=0
C
C          FIND HIGHEST CELL REMAINING
C
1     ETMAX=0.
      DO 200 IPHI=1,NCPHI
      DO 210 IY=1,NCY
      IF(ET(IY,IPHI).LT.ETMAX) GOTO 210
      IF(JETNO(IY,IPHI).NE.0) GOTO 210
      ETMAX=ET(IY,IPHI)
      IYMX=IY
      IPHIMX=IPHI
210   CONTINUE
200   CONTINUE
      IF(ETMAX.LT.ETSTOP) RETURN
C
C          SUM CELLS
C
      IPASS=IPASS+1
      IF(IPASS.GT.NCY*NCPHI) THEN
        WRITE(ITLIS,8888) IPASS
8888    FORMAT(//' ERROR IN GETJET...IPASS > ',I6)
        RETURN
      ENDIF
      NCJET=NCJET+1
      IF(NCJET.GT.NJMAX) THEN
        WRITE(ITLIS,9999) NCJET
9999    FORMAT(//' ERROR IN GETJET...NCJET > ',I5)
        RETURN
      ENDIF
      DO 300 IPHI1=1,NPHI2
      IPHIX=IPHIMX-NPHI1-1+IPHI1
      IF(IPHIX.LE.0) IPHIX=IPHIX+NCPHI
      IF(IPHIX.GT.NCPHI) IPHIX=IPHIX-NCPHI
      DO 310 IY1=1,NY2
      IYX=IYMX-NY1-1+IY1
      IF(IYX.LE.0) GOTO 310
      IF(IYX.GT.NCY) GOTO 310
      IF(JETNO(IYX,IPHIX).NE.0) GOTO 310
      RR=(DELY*(IY1-NY1-1))**2+(DELPHI*(IPHI1-NPHI1-1))**2
      IF(RR.GT.RJET**2) GOTO 310
      IF(ET(IYX,IPHIX).LT.ECCUT) GOTO 310
      PX=ET(IYX,IPHIX)/STHCAL(IYX)
C          ADD CELL TO JET
      PCJET(1,NCJET)=PCJET(1,NCJET)+PX*STHCAL(IYX)*CPHCAL(IPHIX)
      PCJET(2,NCJET)=PCJET(2,NCJET)+PX*STHCAL(IYX)*SPHCAL(IPHIX)
      PCJET(3,NCJET)=PCJET(3,NCJET)+PX*CTHCAL(IYX)
      PCJET(4,NCJET)=PCJET(4,NCJET)+PX
      ETJET(NCJET)=ETJET(NCJET)+ET(IYX,IPHIX)
      JETNO(IYX,IPHIX)=NCJET
310   CONTINUE
300   CONTINUE
C
C          DISCARD JET IF ET < EJCUT.
C
      IF(ETJET(NCJET).GT.EJCUT.AND.ABS(PSERAP(PCJET(1,NCJET))).LT
     $     .ETAJCUT) GOTO 1
      ETJET(NCJET)=0.
      DO 400 K=1,4
400   PCJET(K,NCJET)=0.
      NCJET=NCJET-1
      GOTO 1
      END
C-----------------------------------------------------------------------
      SUBROUTINE CALDEL(ISTLO,ISTHI,ISTOP)
C     LABEL ALL PARTICLES WITH STATUS BETWEEN ISTLO AND ISTHI (UNTIL A
C     PARTICLE WITH STATUS ISTOP IS FOUND) AS FINAL-STATE, CALL CALSIM
C     AND THEN PUT LABELS BACK TO NORMAL
C-----------------------------------------------------------------------
      IMPLICIT NONE
      INTEGER MAXNUP
      PARAMETER(MAXNUP=500)
      INTEGER IEND,INORAD
      COMMON/SHVETO/IEND,INORAD(MAXNUP)
C...HEPEVT commonblock.
      INTEGER NMXHEP,NEVHEP,NHEP,ISTHEP,IDHEP,JMOHEP,JDAHEP
      PARAMETER (NMXHEP=4000)
      COMMON/HEPEVT/NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),PHEP(5,NMXHEP),VHEP(4,NMXHEP)
      DOUBLE PRECISION PHEP,VHEP
      SAVE /HEPEVT/
      INTEGER ISTOLD(NMXHEP),IHEP,IST,ISTLO,ISTHI,ISTOP,IMO,icount
      LOGICAL FOUND
      FOUND=.FALSE.
      DO 10 IHEP=1,NHEP
        IST=ISTHEP(IHEP)
        ISTOLD(IHEP)=IST
        IF (IST.EQ.ISTOP) FOUND=.TRUE.
        IF (IST.GE.ISTLO.AND.IST.LE.ISTHI.AND..NOT.FOUND) THEN
C     FOUND A RADIATED PARTON, CHECK MOTHER
          IMO=IHEP
 1        IMO=JMOHEP(1,IMO)
          IF(IMO.EQ.IEND) THEN
C     PARENTHOOD OK
            IST=1
c            write(2,*) ihep,ist
            GOTO 9
          ENDIF
          IF(INORAD(IMO).EQ.1) THEN
C     PARTON COMES FROM A VETOED MOTHER
            IST=0
            GOTO 9
          ELSE
C     CHECK GRANDMOTHER
            GOTO 1
          ENDIF
        ELSE
          IST=0
        ENDIF
 9      ISTHEP(IHEP)=IST
 10   CONTINUE
      CALL CALSIM
      DO 20 IHEP=1,NHEP
        ISTHEP(IHEP)=ISTOLD(IHEP)
 20   CONTINUE
      END
C-----------------------------------------------------------------------
      FUNCTION PSERAP(P)
C     PSEUDO-RAPIDITY (-LOG TAN THETA/2)
C-----------------------------------------------------------------------
      DOUBLE PRECISION PSERAP,P(3),PT,PL,TINY,THETA
      PARAMETER (TINY=1D-3)
      PT=SQRT(P(1)**2+P(2)**2)+TINY
      PL=P(3)
      THETA=ATAN2(PT,PL)
      PSERAP=-LOG(TAN(0.5*THETA))
      END
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
      SUBROUTINE ALPSOR(A,N,K,IOPT)
C-----------------------------------------------------------------------
C     Sort A(N) into ascending order
C     IOPT = 1 : return sorted A and index array K
C     IOPT = 2 : return index array K only
C-----------------------------------------------------------------------
      DOUBLE PRECISION A(N),B(5000)
      INTEGER N,I,J,IOPT,K(N),IL(5000),IR(5000)
      IF (N.GT.5000) then
        write(*,*) 'Too many entries to sort in alpsrt, stop'
        stop
      endif
      if(n.le.0) return
      IL(1)=0
      IR(1)=0
      DO 10 I=2,N
      IL(I)=0
      IR(I)=0
      J=1
   2  IF(A(I).GT.A(J)) GOTO 5
   3  IF(IL(J).EQ.0) GOTO 4
      J=IL(J)
      GOTO 2
   4  IR(I)=-J
      IL(J)=I
      GOTO 10
   5  IF(IR(J).LE.0) GOTO 6
      J=IR(J)
      GOTO 2
   6  IR(I)=IR(J)
      IR(J)=I
  10  CONTINUE
      I=1
      J=1
      GOTO 8
  20  J=IL(J)
   8  IF(IL(J).GT.0) GOTO 20
   9  K(I)=J
      B(I)=A(J)
      I=I+1
      IF(IR(J)) 12,30,13
  13  J=IR(J)
      GOTO 8
  12  J=-IR(J)
      GOTO 9
  30  IF(IOPT.EQ.2) RETURN
      DO 31 I=1,N
  31  A(I)=B(I)
 999  END
C-----------------------------------------------------------------------
      subroutine getunit(n)
      implicit none
      integer n,i
      logical yes
      do i=10,100
        inquire(unit=i,opened=yes)
        if(.not.yes) goto 10
      enddo
      write(*,*) 'no free units to write to available, stop'
      stop
 10   n=i
      end

