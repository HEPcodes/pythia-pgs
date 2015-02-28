C******************************************************
C*          MadEvent - Pythia interface.              *
C*           Version 4.2, 4 March 2007                *
C*                                                    *
C*  - Improvement of matching routines                *
C*                                                    *
C*  Version 4.1                                       *
C*                                                    *
C*  - Possibility to use several files                *
C*                                                    *
C*  Version 4.0                                       *
C*                                                    *
C*  - Routines for matching of ME and PS              *
C*                                                    *
C*  Version 3.8                                       *
C*                                                    *
C*  - Give the event number in the event file in the  *
C*    new variable IEVNT in UPPRIV                    *
C*                                                    *
C*  Version 3.7                                       *
C*                                                    *
C*  - Set mass of massless outgoing particles to      *
C*    Pythia mass (PMAS(I,1))                         *
C*                                                    *
C*  Version 3.6                                       *
C*                                                    *
C*  - Removed the 1st # from the event file header    *
C*                                                    *
C*  Version 3.5                                       *
C*                                                    *
C*  - Reads according to the new LH event file format *
C*  - Now only LNHIN, LNHOUT and MSCAL in UPPRIV      *
C*                                                    *
C*  Version 3.4                                       *
C*                                                    *
C*  - Reads particle masses from event file           *
C*                                                    *
C*  Version 3.3                                       *
C*                                                    *
C*  - Added option MSCAL in common block UPPRIV to    *
C*    choose between fix (0, default) or event-based  *
C*    (1) scale for Pythia parton showering (SCALUP). *
C*  - Fixed bug in reading the SLHA file              *
C*                                                    *
C*  Version 3.2                                       *
C*                                                    *
C*  - Reading the SLHA format param_card from the     *
C*    banner                                          *
C*  - Added support for lpp1/lpp2 = 2 or 3            *
C*  - Removed again support for different MadEvent    *
C*    processes in different files (no longer         *
C*    necessary with new multiple processes support   *
C*    in MadGraph/MadEvent                            *
C*                                                    *
C*  Version 3.1                                       *
C*  - Added support for different MadEvent processes  *
C*    in different files                              *
C*  - Fixed bug in e+e- collisions                    *
C*                                                    *
C*     Written by J.Alwall, alwall@fyma.ucl.ac.be     *
C*      Earlier versions by S.Mrenna, M.Kirsanov      *
C*                                                    *
C******************************************************
C*                                                    *
C* Instructions:                                      *
C* Please use the common block UPPRIV:                *
C* - The logical unit LNHIN must be an opened         *
C*   MadEvent event file                              *
C* - The output unit LNHOUT is by default 6 (std out) *
C* - Set MSCAL to 1 if a dynamical scale is desired   *
C*   for parton showers rather than the one given as  *
C*   factorization scale by MadEvent (otherwise 0)    *
C* - IEVNT gives the number of the event in the event *
C*   file                                             *
C* - ICKKW is set automatically depending on whether  *
C*   the events generated are matched or not          *
C*                                                    *
C******************************************************

C*********************************************************************
C...UPINIT
C...Routine called by PYINIT to set up user-defined processes.
C*********************************************************************      
      SUBROUTINE UPINIT
      
      IMPLICIT NONE
      CHARACTER*132 CHAR_READ

C...Pythia parameters.
      INTEGER MSTP,MSTI,MRPY
      DOUBLE PRECISION PARP,PARI,RRPY
      COMMON/PYPARS/MSTP(200),PARP(200),MSTI(200),PARI(200)
      COMMON/PYDATR/MRPY(6),RRPY(100)

C...User process initialization commonblock.
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON/HEPRUP/IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &   IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),XMAXUP(MAXPUP),
     &   LPRUP(MAXPUP)

C...Extra commonblock to transfer run info.
      INTEGER LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE
      COMMON/UPPRIV/LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE

C...Inputs for the matching algorithm
      double precision etcjet,rclmax,etaclmax,qcut,clfact
      integer maxjets,minjets,iexcfile,ktsche,mektsc,nexcres,excres(30)
      integer nremres, remres(30)
      integer nqmatch,nexcproc,iexcproc(MAXPUP),iexcval(MAXPUP)
      logical nosingrad,showerkt,jetprocs
      common/MEMAIN/etcjet,rclmax,etaclmax,qcut,clfact,maxjets,minjets,
     $   iexcfile,ktsche,mektsc,nexcres,excres,nremres,remres,
     $   nqmatch,nexcproc,iexcproc,iexcval,nosingrad,showerkt,jetprocs

C...Parameter arrays (local)
      integer maxpara
      parameter (maxpara=1000)
      integer npara,iseed
      character*20 param(maxpara),value(maxpara)      

C...Lines to read in assumed never longer than 200 characters. 
      INTEGER MAXLEN,IBEG,IPR,I
      PARAMETER (MAXLEN=200)
      CHARACTER*(MAXLEN) STRING

C...Functions
      INTEGER iexclusive
      EXTERNAL iexclusive

C...Format for reading lines.
      CHARACTER*6 STRFMT
      CHARACTER*20 CGIVE
C...Store temporary line
      CHARACTER*1000 TMPLINE
      integer index0

      STRFMT='(A000)'
      WRITE(STRFMT(3:5),'(I3)') MAXLEN

C...Extract the model parameter card and read it.
      CALL MODELPAR(LNHIN)

c...Read the <init> block information

C...Loop until finds line beginning with "<init>" or "<init ". 
  100 READ(LNHIN,STRFMT,END=130,ERR=130) STRING
C...Pick out random number seed and use for PYR initialization
      IF(INDEX(STRING,'iseed').NE.0)THEN
         READ(STRING,*) iseed
         IF(iseed.gt.0) THEN
            WRITE(LNHOUT,*) 'Initializing PYR with random seed ',iseed
            MRPY(1) = iseed
            MRPY(2) = 0
         ENDIF
      ENDIF
      IBEG=0
  110 IBEG=IBEG+1
C...Allow indentation.
      IF(STRING(IBEG:IBEG).EQ.' '.AND.IBEG.LT.MAXLEN-5) GOTO 110 
      IF(STRING(IBEG:IBEG+5).NE.'<init>'.AND.
     &STRING(IBEG:IBEG+5).NE.'<init ') GOTO 100


C...Read first line of initialization info.
 111  READ(LNHIN,'(a1000)',END=130) TMPLINE
      READ(TMPLINE,*,END=130,ERR=112) IDBMUP(1),IDBMUP(2),EBMUP(1),
     &EBMUP(2),PDFGUP(1),PDFGUP(2),PDFSUP(1),PDFSUP(2),IDWTUP,NPRUP
      TMPLINE = ''
      goto 114

C...Skip the <generator line if present 
 112  index0 = index(TMPLINE, "<generator")
      if (index0.eq.0) goto 130
 113  index0 = index(TMPLINE, "</generator>")
      if (index0.gt.0) goto 111
      index0 = index(TMPLINE, "2212")
      if (index0.gt.0) goto 130

      READ(LNHIN,*,END=130) TMPLINE
      goto 113
C...Read NPRUP subsequent lines with information on each process.
 114  DO 120 IPR=1,NPRUP
        READ(LNHIN,*,END=130,ERR=130) XSECUP(IPR),XERRUP(IPR),
     &  XMAXUP(IPR),LPRUP(IPR)
  120 CONTINUE

C...Set PDFLIB or LHAPDF pdf number for Pythia

      IF(PDFSUP(1).NE.19070.AND.(PDFSUP(1).NE.0.OR.PDFSUP(2).NE.0))THEN
c     Not CTEQ5L, which is standard in Pythia
         CALL PYGIVE('MSTP(52)=2')
c     The following works for both PDFLIB and LHAPDF (where PDFGUP(1)=0)
c     But note that the MadEvent output uses the LHAPDF numbering scheme
        IF(PDFSUP(1).NE.0)THEN
           MSTP(51)=1000*PDFGUP(1)+PDFSUP(1)
        ELSE
           MSTP(51)=1000*PDFGUP(2)+PDFSUP(2)
        ENDIF
      ENDIF

C...Initialize widths and partial widths for resonances.
      CALL PYINRE
        
C...Calculate xsec reduction due to non-decayed resonances
C...based on first event only!
C...This has been turned off since it doesn't work well with recent Pythia versions
c      CALL BRSUPP

      REWIND(LNHIN)

C...Extract cuts and matching parameters
      CALL read_params(LNHIN,npara,param,value,maxpara)

      call get_integer(npara,param,value," ickkw ",ickkw,0)
      if(ickkw.eq.1)then
         call get_integer(npara,param,value," ktscheme ",mektsc,1)
         write(*,*)'Running matching with ME ktscheme ',mektsc
         call get_integer(npara,param,value," maxjetflavor ",nqmatch,5)
         write(*,*)'Set nqmatch to ',nqmatch
c        Set number of active flavors in final state shower to nqmatch
         write(CGIVE,'(a,i1)') 'MSTJ(45)=',nqmatch
         call PYGIVE(CGIVE)
      endif
C
C...Set kt clustering scheme (if not already set)
C
      IF(ABS(IDBMUP(1)).EQ.11.AND.ABS(IDBMUP(2)).EQ.11.AND.
     $     IDBMUP(1).EQ.-IDBMUP(2).AND.ktsche.EQ.0)THEN
         ktsche=1
      ELSE IF(ktsche.EQ.0) THEN
         ktsche=4313
      ENDIF

C...Enhance primordial kt
c      CALL PYGIVE('PARP(91)=2.5')
c      CALL PYGIVE('PARP(93)=15')


      IF(ickkw.gt.0.and.(NPRUP.gt.1.or.iexclusive(LPRUP(1)).ne.-1))
     $     CALL set_matching(LNHIN,npara,param,value)

C...For photon initial states from protons: Set proton not to break up
      CALL PYGIVE('MSTP(98)=1')

C...Reset event numbering
      IEVNT=0

      RETURN

C...Error exit: give up if initalization does not work.
  130 WRITE(*,*) ' Failed to read LHEF initialization information.'
      WRITE(*,*) ' Event generation will be stopped.'
      STOP  
      END

C*********************************************************************      
C...UPEVNT
C...Routine called by PYEVNT or PYEVNW to get user process event
C*********************************************************************
      SUBROUTINE UPEVNT

      IMPLICIT NONE

C...Pythia parameters.
      INTEGER MSTP,MSTI
      DOUBLE PRECISION PARP,PARI
      COMMON/PYPARS/MSTP(200),PARP(200),MSTI(200),PARI(200)

C...User process initialization commonblock.
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON/HEPRUP/IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &   IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),XMAXUP(MAXPUP),
     &   LPRUP(MAXPUP)
C...User process event common block.
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,IDUP(MAXNUP),
     &   ISTUP(MAXNUP),MOTHUP(2,MAXNUP),ICOLUP(2,MAXNUP),PUP(5,MAXNUP),
     &   VTIMUP(MAXNUP),SPINUP(MAXNUP)
C...Pythia common blocks
      INTEGER PYCOMP,KCHG,MINT
      DOUBLE PRECISION PMAS,PARF,VCKM,VINT
C...Particle properties + some flavour parameters.
      COMMON/PYDAT2/KCHG(500,4),PMAS(500,4),PARF(2000),VCKM(4,4)
      COMMON/PYINT1/MINT(400),VINT(400)

C...Extra commonblock to transfer run info.
      INTEGER LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE
      COMMON/UPPRIV/LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE

C...Inputs for the matching algorithm
      double precision etcjet,rclmax,etaclmax,qcut,clfact
      integer maxjets,minjets,iexcfile,ktsche,mektsc,nexcres,excres(30)
      integer nremres, remres(30)
      integer nqmatch,nexcproc,iexcproc(MAXPUP),iexcval(MAXPUP)
      logical nosingrad,showerkt,jetprocs
      common/MEMAIN/etcjet,rclmax,etaclmax,qcut,clfact,maxjets,minjets,
     $   iexcfile,ktsche,mektsc,nexcres,excres,nremres,remres,
     $   nqmatch,nexcproc,iexcproc,iexcval,nosingrad,showerkt,jetprocs

C...Commonblock to transfer event-by-event matching info
      INTEGER NLJETS,NQJETS,IEXC,Ifile
      DOUBLE PRECISION PTCLUS
      COMMON/MEMAEV/PTCLUS(20),NLJETS,NQJETS,IEXC,Ifile

C...Commonblock to keep systematics info
      LOGICAL USESYST
      CHARACTER*1000 SYSTSTR(6)
      DOUBLE PRECISION SMIN,SCOMP,SMAX
      COMMON/SYST/USESYST,SYSTSTR,SMIN,SCOMP,SMAX

C...Local variables
      INTEGER I,J,IBEG,NEX,KP(MAXNUP),MOTH,NUPREAD,II,iexcl
      INTEGER irem(5),nrem,NPART,ndirect,nfinal
      DOUBLE PRECISION PSUM,ESUM,PM1,PM2,A1,A2,A3,A4,A5
      DOUBLE PRECISION SCALLOW(MAXNUP),PNONJ(4),PMNONJ!,PT2JETS
C...Lines to read in assumed never longer than 200 characters. 
      INTEGER MAXLEN
      PARAMETER (MAXLEN=200)
      CHARACTER*(MAXLEN) STRING

C...Functions
      INTEGER iexclusive
      EXTERNAL iexclusive

C...Format for reading lines.
      CHARACTER*6 STRFMT
      CHARACTER*1 CDUM

C...  integer for parsing string
      integer index0, index1, index2 

      STRFMT='(A000)'
      WRITE(STRFMT(3:5),'(I3)') MAXLEN



C...Loop until finds line beginning with "<event>" or "<event ". 
  100 READ(LNHIN,STRFMT,END=900,ERR=900) STRING
      IBEG=0
  110 IBEG=IBEG+1
C...Allow indentation.
      IF(STRING(IBEG:IBEG).EQ.' '.AND.IBEG.LT.MAXLEN-6) GOTO 110 
      IF(STRING(IBEG:IBEG+6).NE.'<event>'.AND.
     &STRING(IBEG:IBEG+6).NE.'<event ') GOTO 100

C...Read first line of event info.
      READ(LNHIN,*,END=900,ERR=900) NUPREAD,IDPRUP,XWGTUP,SCALUP,
     &AQEDUP,AQCDUP

C...Read NUP subsequent lines with information on each particle.
      ESUM=0d0
      PSUM=0d0
      NEX=2
      NUP=1
      NREM=0
      DO 120 I=1,NUPREAD
        READ(LNHIN,*,END=900,ERR=900) IDUP(NUP),ISTUP(NUP),
     &  MOTHUP(1,NUP),MOTHUP(2,NUP),ICOLUP(1,NUP),ICOLUP(2,NUP),
     &  (PUP(J,NUP),J=1,5),VTIMUP(NUP),SPINUP(NUP)
C...Reset resonance momentum to prepare for mass shifts
        DO J=1,nremres
           IF(ISTUP(NUP).EQ.2 .AND. IDUP(NUP).EQ.remres(J)) THEN
              NREM=NREM+1
              IF(NREM.GT.5)THEN
                 WRITE(*,*)'TOO MANY REMOVED RESONANCES IN ONE EVENT'
                 NREM=NREM-1
                 EXIT
              ENDIF
              IREM(NREM)=I
              GOTO 120
           ENDIF
        ENDDO
        IF(ISTUP(NUP).EQ.2) PUP(3,NUP)=0
        IF(ISTUP(NUP).EQ.1)THEN
          NEX=NEX+1
           IF(PUP(5,NUP).EQ.0D0.AND.IABS(IDUP(NUP)).GT.3
     $         .AND.IDUP(NUP).NE.21.AND.IDUP(NUP).NE.22) THEN
C...Set massless particle masses to Pythia default. Adjust z-momentum. 
              PUP(5,NUP)=PMAS(IABS(PYCOMP(IDUP(NUP))),1)
              PUP(3,NUP)=SIGN(SQRT(MAX(0d0,PUP(4,NUP)**2-PUP(5,NUP)**2-
     $           PUP(1,NUP)**2-PUP(2,NUP)**2)),PUP(3,NUP))
           ENDIF
           PSUM=PSUM+PUP(3,NUP)
C...Set mother resonance momenta
           MOTH=MOTHUP(1,NUP)
           DO J=1,NREM
              IF (MOTH .eq. IREM(J)) THEN
                 MOTHUP(1,NUP)=1
                 MOTHUP(2,NUP)=2
                 MOTH=1
              ENDIF
           ENDDO
           DO J=NREM,1,-1
              IF(MOTH.GT.IREM(J)) THEN
                 MOTH=MOTH-1
                 MOTHUP(1,NUP)=MOTHUP(1,NUP)-1
                 MOTHUP(2,NUP)=MOTHUP(2,NUP)-1
              ENDIF
           ENDDO
           DO WHILE (MOTH.GT.2)
              PUP(3,MOTH)=PUP(3,MOTH)+PUP(3,NUP)
              MOTH=MOTHUP(1,MOTH)
           ENDDO
        ENDIF
        NUP=NUP+1
  120 CONTINUE
      NUP=NUP-1

C...Increment event number
      IEVNT=IEVNT+1

C..Adjust mass of resonances
      DO I=1,NUP
         IF(ISTUP(I).EQ.2)THEN
            PUP(5,I)=SQRT(PUP(4,I)**2-PUP(1,I)**2-PUP(2,I)**2-
     $             PUP(3,I)**2)
         ENDIF
      ENDDO

C...Adjust energy and momentum of incoming particles
C...In massive case need to solve quadratic equation
c      PM1=PUP(5,1)**2
c      PM2=PUP(5,2)**2
c      A1=4d0*(ESUM**2-PSUM**2)
c      A2=ESUM**2-PSUM**2+PM2-PM1
c      A3=2d0*PSUM*A2
c      A4=A3/A1
c      A5=(A2**2-4d0*ESUM**2*PM2)/A1
c
c      PUP(3,2)=A4+SIGN(SQRT(A4**2+A5),PUP(3,2))
c      PUP(3,1)=PSUM-PUP(3,2)
c      PUP(4,1)=SQRT(PUP(3,1)**2+PM1)
c      PUP(4,2)=SQRT(PUP(3,2)**2+PM2)

      ESUM=PUP(4,1)+PUP(4,2)

C...Assuming massless incoming particles - otherwise Pythia adjusts
C...the momenta to make them massless
c      IF(IDBMUP(1).GT.100.AND.IDBMUP(2).GT.100)THEN
c        DO I=1,2
c          PUP(3,I)=0.5d0*(PSUM+SIGN(ESUM,PUP(3,I)))
c          PUP(5,I)=0d0
c        ENDDO
c        PUP(4,1)=ABS(PUP(3,1))
c        PUP(4,2)=ESUM-PUP(4,1)
c      ENDIF
        
C...If you want to use some other scale for parton showering then the 
C...factorisation scale given by MadEvent, please implement the function PYMASC
C...(example function included below) 

      IF(ickkw.eq.0.AND.MSCAL.GT.0) CALL PYMASC(SCALUP)
c      IF(MINT(35).eq.3.AND.ickkw.EQ.1) SCALUP=SQRT(PARP(67))*SCALUP
      
C...Read generation scale for all FS particles (as comment in event file or in <scale)
      IF(ickkw.eq.1)THEN
        READ(LNHIN,'(a1000)',END=900,ERR=130) SYSTSTR(1)
        if (SYSTSTR(1)(1:1).eq.'#')then
           READ(SYSTSTR(1),*,END=130,ERR=130) CDUM,(PTCLUS(I),I=1,NEX)
        else if (SYSTSTR(1)(1:6).eq.'<scale')then
           index0 = 1
           index1 = 1
           index2 = 1
           DO I=1,20
             index0=index2+INDEX(SYSTSTR(1)(index2+1:1000), 
     $                            'pt_clust_')
             if (index0.eq.index2) goto 130
             index1 = index0+INDEX(SYSTSTR(1)(index0:1000), '"')-1
             index2 = index1+INDEX(SYSTSTR(1)(index1+1:1000), '"')
             read(SYSTSTR(1)(index1+1:index2-1),*,END=130) PTCLUS(I)
           ENDDO
           
        endif
 130    CONTINUE
        SYSTSTR(1)=''
      ENDIF

C...Read systematics information
      READ(LNHIN,'(a)',END=900,ERR=140) SYSTSTR(1)
      USESYST=.false.
      if(SYSTSTR(1)(1:7).EQ.'<mgrwt>')then
         USESYST=.true.
         DO I=1,6
            READ(LNHIN,'(a)',END=900,ERR=140) SYSTSTR(I)
         ENDDO
         SMIN=0d0
         SCOMP=QCUT
         SMAX=0d0
      else
         BACKSPACE(LNHIN)
      endif
 140  CONTINUE

      IF(ickkw.gt.0) THEN
c
c   Sort particles so direct particles come first, decayed afterwards
c
         ndirect=2
         nfinal=0
         do i=3,NUP
            if(ISTUP(i).eq.1) nfinal=nfinal+1
            if(ISTUP(i).eq.1.and.MOTHUP(1,i).le.2)THEN
               ndirect=ndirect+1
               if (i.gt.ndirect) then
c              This particle needs to be moved down to come before resonances
                  CALL SHIFTPART(i,ndirect,nfinal)
               endif
            endif
         enddo

c
c   Set up number of jets
c
         NLJETS=0
         NQJETS=0
         NPART=0
         do i=3,NUP
            if(ISTUP(i).ne.1) cycle
            NPART=NPART+1
c           Remove non-partons and partons originating from t-channel singlets
            if(iabs(IDUP(i)).gt.nqmatch.and.IDUP(i).ne.21) cycle
            if(MOTHUP(1,i).gt.2) cycle
C     Remove final-state partons that combine to color singlets
            IF((ABS(IDBMUP(1)).NE.11.OR.IDBMUP(1).NE.-IDBMUP(2)).AND.
     $           nosingrad) THEN
               DO II=3,NUP
                  IF(II.NE.i.AND.ISTUP(II).EQ.1)THEN
                     IF((IDUP(II).EQ.-IDUP(i).OR.
     $                    IDUP(i).EQ.21.AND.IDUP(II).EQ.21).AND.
     $                    ICOLUP(1,II).EQ.ICOLUP(2,i).AND.
     $                    ICOLUP(2,II).EQ.ICOLUP(1,i))then
c                        print *,'Found color singlet'
                        CALL PYLIST(7)
                        GOTO 150
                     endif
                  ENDIF
               ENDDO
            ENDIF
            NLJETS=NLJETS+1
            if(ptclus(NPART).gt.(2-1d-3)*sqrt(ebmup(1)*ebmup(2))) cycle
            NQJETS=NQJETS+1
 150        continue
         enddo
      
         if(jetprocs) IDPRUP=LPRUP(NLJETS-MINJETS+1)

         IF(ickkw.eq.1) THEN
c   ... and decide whether exclusive or inclusive
            iexcl=iexclusive(IDPRUP)
            if((IEXCFILE.EQ.0.and.NLJETS.eq.MAXJETS.or.
     $           iexcl.eq.0).and.
     $           iexcl.ne.1)then
               IEXC=0
            else if(iexcl.eq.-1)then
               IEXC=-1
            else
               IEXC=1
            endif
         ENDIF
      ENDIF

      RETURN

C...Error exit, typically when no more events.
  900 WRITE(*,*) ' Failed to read LHEF event information,'
      WRITE(*,*) ' assume end of file has been reached.'
      NUP=0
      MINT(51)=2
      RETURN
      END

C****************************************************************
C     SHIFTPART
C     Move a particle from iold to inew, keeping all mother info
C****************************************************************
      SUBROUTINE SHIFTPART(iold, inew, nfinal)
      implicit none

c     Arguments
      integer iold, inew, nfinal

C...User process event common block.
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,IDUP(MAXNUP),
     &   ISTUP(MAXNUP),MOTHUP(2,MAXNUP),ICOLUP(2,MAXNUP),PUP(5,MAXNUP),
     &   VTIMUP(MAXNUP),SPINUP(MAXNUP)

C...Commonblock to transfer event-by-event matching info
      INTEGER NLJETS,NQJETS,IEXC,Ifile
      DOUBLE PRECISION PTCLUS
      COMMON/MEMAEV/PTCLUS(20),NLJETS,NQJETS,IEXC,Ifile

c...Local variables
      integer ipart(6),i,j
      double precision ppart(7)

c     Move particle in place iold to inew
      do i=iold,inew+1,-1
c     Switch places between i and i-1
         ipart(1)=IDUP(i)
         ipart(2)=ISTUP(i)
         ipart(3)=MOTHUP(1,i)
         ipart(4)=MOTHUP(2,i)
         ipart(5)=ICOLUP(1,i)
         ipart(6)=ICOLUP(2,i)
         do j=1,5
            ppart(j)=PUP(j,i)
         enddo
         ppart(6)=VTIMUP(i)
         ppart(7)=SPINUP(i)

         IDUP(i)=IDUP(i-1)
         ISTUP(i)=ISTUP(i-1)
         MOTHUP(1,i)=MOTHUP(1,i-1)
         MOTHUP(2,i)=MOTHUP(2,i-1)
         ICOLUP(1,i)=ICOLUP(1,i-1)
         ICOLUP(2,i)=ICOLUP(2,i-1)
         do j=1,5
            PUP(j,i)=PUP(j,i-1)
         enddo
         VTIMUP(i)=VTIMUP(i-1)
         SPINUP(i)=SPINUP(i-1)

         IDUP(i-1)=ipart(1)
         ISTUP(i-1)=ipart(2)
         MOTHUP(1,i-1)=ipart(3)
         MOTHUP(2,i-1)=ipart(4)
         ICOLUP(1,i-1)=ipart(5)
         ICOLUP(2,i-1)=ipart(6)
         do j=1,5
            PUP(j,i-1)=ppart(j)
         enddo
         VTIMUP(i-1)=ppart(6)
         SPINUP(i-1)=ppart(7)

         if(ISTUP(i).eq.2) then
c        Fix mother info for resonances
            do j=i+1,NUP
               if(MOTHUP(1,j).eq.i-1) MOTHUP(1,j)=i
               if(MOTHUP(2,j).eq.i-1) MOTHUP(2,j)=i
            enddo
         endif         
      enddo

c     Move ptclus from nfinal to inew-2
      do i=nfinal,inew-1,-1
c        Switch places between i and i-1
         ppart(1)=ptclus(i)
         ptclus(i)=ptclus(i-1)
         ptclus(i-1)=ppart(1)
      enddo

      return
      end

C*********************************************************************
C...UPVETO
C...Subroutine to implement the MLM jet matching criterion
C*********************************************************************
      SUBROUTINE UPVETO(IPVETO)

      IMPLICIT NONE

C...Pythia common blocks
      INTEGER MINT
      DOUBLE PRECISION VINT
      COMMON/PYINT1/MINT(400),VINT(400)
      INTEGER MSTP,MSTI
      DOUBLE PRECISION PARP,PARI
      COMMON/PYPARS/MSTP(200),PARP(200),MSTI(200),PARI(200)

C...GUP Event common block
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,
     &              IDUP(MAXNUP),ISTUP(MAXNUP),MOTHUP(2,MAXNUP),
     &              ICOLUP(2,MAXNUP),PUP(5,MAXNUP),VTIMUP(MAXNUP),
     &              SPINUP(MAXNUP)
C...User process initialization commonblock.
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON/HEPRUP/IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &   IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),XMAXUP(MAXPUP),
     &   LPRUP(MAXPUP)
C...HEPEVT commonblock.
      INTEGER NMXHEP,NEVHEP,NHEP,ISTHEP,IDHEP,JMOHEP,JDAHEP
      PARAMETER (NMXHEP=4000)
      COMMON/HEPEVT/NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),PHEP(5,NMXHEP),VHEP(4,NMXHEP)
      DOUBLE PRECISION PHEP,VHEP
      SAVE /HEPEVT/
      INTEGER IPVETO
C...GETJET commonblocks
      INTEGER MNCY,MNCPHI,NCY,NCPHI,NJMAX,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,DELY,DELPHI,ET,STHCAL,CTHCAL,CPHCAL,
     &  SPHCAL,PCJET,ETJET
      PARAMETER (MNCY=200)
      PARAMETER (MNCPHI=200)
      COMMON/CALORM/DELY,DELPHI,ET(MNCY,MNCPHI),
     $CTHCAL(MNCY),STHCAL(MNCY),CPHCAL(MNCPHI),SPHCAL(MNCPHI),
     $YCMIN,YCMAX,NCY,NCPHI
      PARAMETER (NJMAX=500)
      COMMON/GETCOMM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(MNCY,MNCPHI),
     $NCJET
      DOUBLE PRECISION PI
      PARAMETER (PI=3.141593D0)
C     
      DOUBLE PRECISION PSERAP
      INTEGER K(NJMAX),KP(NJMAX),kpj(njmax)

C...Variables for the kT-clustering
      INTEGER NMAX,NN,NJET,NSUB,JET,NJETM,IHARD,IP1,IP2
      DOUBLE PRECISION PP,PJET
      DOUBLE PRECISION ECUT,Y,YCUT,RAD
      PARAMETER (NMAX=512)
      DIMENSION JET(NMAX),Y(NMAX),PP(4,NMAX),PJET(4,NMAX),
     $   PJETM(4,NMAX)
      INTEGER NNM
      DOUBLE PRECISION YM(NMAX),PPM(4,NMAX),PJETM

C...kt clustering common block
      INTEGER NMAXKT,NUM,HIST
      PARAMETER (NMAXKT=512)
      DOUBLE PRECISION PPP,KT,ETOT,RSQ,KTP,KTS,KTLAST
      COMMON /KTCOMM/ETOT,RSQ,PPP(9,NMAXKT),KTP(NMAXKT,NMAXKT),
     $   KTS(NMAXKT),KT(NMAXKT),KTLAST(NMAXKT),HIST(NMAXKT),NUM

C...Extra commonblock to transfer run info.
      INTEGER LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE
      COMMON/UPPRIV/LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE

C...Inputs for the matching algorithm
C   clfact determines how close jets must be matched in cone-jets.
C   Default=1.5. Matching if within clfact*RCLMAX 

      double precision etcjet,rclmax,etaclmax,qcut,clfact
      integer maxjets,minjets,iexcfile,ktsche,mektsc,nexcres,excres(30)
      integer nremres, remres(30)
      integer nqmatch,nexcproc,iexcproc(MAXPUP),iexcval(MAXPUP)
      logical nosingrad,showerkt,jetprocs
      common/MEMAIN/etcjet,rclmax,etaclmax,qcut,clfact,maxjets,minjets,
     $   iexcfile,ktsche,mektsc,nexcres,excres,nremres,remres,
     $   nqmatch,nexcproc,iexcproc,iexcval,nosingrad,showerkt,jetprocs

C...Commonblock to transfer event-by-event matching info
      INTEGER NLJETS,NQJETS,IEXC,Ifile
      DOUBLE PRECISION PTCLUS
      COMMON/MEMAEV/PTCLUS(20),NLJETS,NQJETS,IEXC,Ifile

C...Commonblock to keep systematics info
      LOGICAL USESYST
      CHARACTER*1000 SYSTSTR(6)
      DOUBLE PRECISION SMIN,SCOMP,SMAX
      COMMON/SYST/USESYST,SYSTSTR,SMIN,SCOMP,SMAX

      INTEGER nvarev
      PARAMETER (nvarev=10)

      REAL*4 varev(nvarev)
      COMMON/HISTDAT/varev


C   local variables
      double precision tiny
      parameter (tiny=1d-3)
      integer icount
      data icount/0/
      integer idbg
      data idbg/0/

      integer i,j,ihep,nmatch,jrmin,KPT(MAXNUP),nres,ii
      double precision etajet,phijet,delr,dphi,delrmin,ptjet
      double precision p(4,10),pt(10),eta(10),phi(10),pttmp,emax
      double precision ptsort(20)
      INTEGER ISTOLD(NMXHEP),IST,IMO,NPART,IPART(MAXNUP),NREM,IREM(20)
      logical norad(20)

      

c      if(NLJETS.EQ.2)then
c        idbg=1
c      else
c        idbg=0
c      endif

      if(idbg.eq.1) write(LNHOUT,*) 'Event: ',IEVNT

      IPVETO=0
c     Return if not MLM matching (or non-matched subprocess)
      
      IF(ICKKW.LE.0.OR.IEXC.eq.-1) RETURN

      IF(NLJETS.LT.MINJETS.OR.NLJETS.GT.MAXJETS)THEN
        if(idbg.eq.1)
     $     WRITE(LNHOUT,*) 'Failed due to NLJETS ',NLJETS,' < ',MINJETS,
     $        ' or > ',MAXJETS
         GOTO 999
      ENDIF

C   Throw event if it contains an excluded resonance
      NRES=0
      DO I=1,NUP
        IF(ISTUP(I).EQ.2)THEN
           DO J=1,nexcres
              IF(IDUP(I).EQ.EXCRES(J)) NRES=NRES+1
           ENDDO
        ENDIF
      ENDDO
      IF(NRES.GT.0)THEN
         if(idbg.eq.1)
     $        PRINT *,'Event',IEVNT,' thrown because of ',NRES,
     $        ' excluded resonance(s)'
c     CALL PYLIST(7)
         GOTO 999
      ENDIF

C   Set up vetoed mothers
c      DO I=1,MAXNUP
c        INORAD(I)=0
c      ENDDO
c      DO IHEP=1,NUP-2      
c        if(ISTHEP(ihep).gt.1.and.iabs(IDHEP(ihep)).gt.8) then
c        if(iabs(IDHEP(ihep)).gt.5.and.IDHEP(ihep).ne.21) then
c          INORAD(ihep)=1
c        endif
c      ENDDO

c
c     reconstruct parton-level event
c     Set norad for daughters of decayed particles, to not include
c     radiation from these in matched jets
c
      if(idbg.eq.1) then
        write(LNHOUT,*) ' '
        write(LNHOUT,*) 'new event '
c        CALL PYLIST(1)
        CALL PYLIST(7)
        CALL PYLIST(5)
        write(*,*) 'ptclus: ',(ptclus(j),j=1,nup-2)
        write(LNHOUT,*) 'PARTONS'
      endif
      i=0
      NPART=0
      NREM=0
      do ihep=3,nup
        NORAD(ihep)=.false.
        if(ISTUP(ihep).eq.1) then
           NPART=NPART+1
           IPART(ihep-2)=NPART
        else
           cycle
        endif
        if((ABS(IDBMUP(1)).NE.11.OR.IDBMUP(1).NE.-IDBMUP(2)).AND.
     $        MOTHUP(1,ihep).gt.2) goto 100
c     Remove non-partons and partons originating from t-channel singlets        
        if(iabs(IDUP(ihep)).gt.nqmatch.and.IDUP(ihep).ne.21.or.
     $           PTCLUS(NPART).gt.(2-1d-3)*sqrt(ebmup(1)*ebmup(2))) then
c          Store line number for partons that are removed, for
c          additional FSR matching
           if((iabs(IDUP(ihep)).le.5.or.IDUP(ihep).eq.21).and.
     $          MOTHUP(1,ihep).le.2) then
              NREM=NREM+1
              IREM(NREM)=ihep-2
              if (idbg.eq.1) write(*,*) 'Remove parton ',IREM(NREM),
     $             ' from matching'
           endif
           cycle
        endif
c     If quark or gluon making singlet system with other final-state parton
c     remove (since unseen singlet resonance) unless e+e- collision
        IF((ABS(IDBMUP(1)).NE.11.OR.IDBMUP(1).NE.-IDBMUP(2)).AND.
     $       nosingrad)THEN
           DO II=3,NUP
              IF(II.NE.ihep.AND.ISTUP(II).EQ.1)THEN
                 IF((IDUP(II).EQ.-IDUP(ihep).OR.
     $                IDUP(ihep).EQ.21.AND.IDUP(II).EQ.21).AND.
     $                ICOLUP(1,II).EQ.ICOLUP(2,ihep).AND.
     $                ICOLUP(2,II).EQ.ICOLUP(1,ihep))
     $                GOTO 100
              ENDIF
           ENDDO
        ENDIF
        i=i+1
        do j=1,4
          p(j,i)=pup(j,ihep)
        enddo
        pt(i)=sqrt(p(1,i)**2+p(2,i)**2)
        eta(i)=-log(tan(0.5d0*atan2(pt(i)+tiny,p(3,i))))
        phi(i)=atan2(p(2,i),p(1,i))
        ptsort(i)=PTCLUS(NPART)
        if(idbg.eq.1) then
          write(LNHOUT,*) pt(i),eta(i),phi(i)
        endif
        cycle
 100    norad(ihep)=.true.
      enddo
 
      if(i.ne.NQJETS)then
        print *,'Error in UPVETO: Wrong number of jets found ',i,NQJETS
        CALL PYLIST(7)
        CALL PYLIST(5)
        print *,'ptclus: ',(ptclus(j),j=1,nup-2)
        stop
      endif

      if(idbg.eq.1)
     $     write(LNHOUT,*) 'NQJETS,NLJETS=',NQJETS,NLJETS

      emax=(2-1d-3)*sqrt(ebmup(1)*ebmup(2))
C     Set status for non-clustering partons to 2
      DO ihep=1,NHEP
c     Remove final-state radiation from heavy quarks (should be treated separately)
c     Also remove radiation from partons originating from colorless t-channels
         IF(ISTHEP(ihep).eq.1.AND.JMOHEP(1,ihep).gt.0.AND.
     $      ISTHEP(JMOHEP(1,ihep)).EQ.2.AND.(
     $        iabs(IDHEP(JMOHEP(1,ihep))).GT.nqmatch.and.
     $        IDHEP(JMOHEP(1,ihep)).ne.21.or.
     $        ptclus(IPART(JMOHEP(1,ihep))).gt.emax)) then
          if(idbg.eq.1) write(*,*) 'Remove line ',ihep,' from matching'
          ISTHEP(ihep)=2
         ENDIF
c     Remove non-partons from event record
         IF(ISTHEP(ihep).EQ.1.AND.iabs(IDHEP(ihep)).GT.nqmatch.AND.
     $        IDHEP(ihep).NE.21) THEN
            ISTHEP(ihep)=2
         ELSEIF(ISTHEP(ihep).EQ.1.AND.JMOHEP(1,ihep).GT.0) then
            IMO=JMOHEP(1,ihep)
            DO WHILE(IMO.GT.0)
c           Trace mothers, if non-radiating => daughter is decay - remove
              IF(IMO.le.NUP-2.and.norad(IMO+2)) GOTO 105
              IMO=JMOHEP(1,IMO)
            ENDDO
            cycle
 105        ISTHEP(ihep)=2
         ENDIF
      ENDDO

      CALL ALPSOR(ptsort,nqjets,KP,1)

c     Print out HEPEVT record
      if(idbg.eq.1)then
         write(LNHOUT,*) 'After removing non-partons'
         CALL PYLIST(5)
         write(LNHOUT,*) 'ptsort: ',(ptsort(j),j=1,i)
      endif

C     Prepare histogram filling
      DO I=1,4
         varev(1+I)=-1
      ENDDO

      IF(ICKKW.EQ.2) GOTO 150

      IF(MSTP(61).eq.0..and.MSTP(71).eq.0)then
c     No showering - just print out event
      ELSE IF(qcut.le.0d0)then  !     Cone jet matching
      IF(clfact.EQ.0d0) clfact=1.5d0

c      CALL PYLIST(7)
c      CALL PYLIST(2)
c      CALL PYLIST(5)
c     Start from the partonic system
      IF(NQJETS.GT.0) CALL ALPSOR(pt,nqjets,KP,2)  
c     reconstruct showered jets
c     
      YCMAX=ETACLMAX+RCLMAX
      YCMIN=-YCMAX
      CALL CALINIM
      CALL CALDELM(1,1)
      CALL GETJETM(RCLMAX,ETCJET,ETACLMAX)
c     analyse only events with at least nqjets-reconstructed jets
      IF(NCJET.GT.0) CALL ALPSOR(ETJET,NCJET,K,2)              
      if(idbg.eq.1) then
        write(LNHOUT,*) 'JETS'
        do i=1,ncjet
          j=k(ncjet+1-i)
          ETAJET=PSERAP(PCJET(1,j))
          PHIJET=ATAN2(PCJET(2,j),PCJET(1,j))
          write(LNHOUT,*) etjet(j),etajet,phijet
        enddo
      endif
      IF(NCJET.LT.NQJETS) THEN
        if(idbg.eq.1)
     $     WRITE(LNHOUT,*) 'Failed due to NCJET ',NCJET,' < ',NQJETS
        GOTO 999
      endif
c     associate partons and jets, using min(delr) as criterion
      NMATCH=0
      DO I=1,NCJET
        KPJ(I)=0
      ENDDO
      DO I=1,NQJETS
        DELRMIN=1D5
        DO 110 J=1,NCJET
          IF(KPJ(J).NE.0) GO TO 110
          ETAJET=PSERAP(PCJET(1,J))
          PHIJET=ATAN2(PCJET(2,J),PCJET(1,J))
          DPHI=ABS(PHI(KP(NQJETS-I+1))-PHIJET)
          IF(DPHI.GT.PI) DPHI=2.*PI-DPHI
          DELR=SQRT((ETA(KP(NQJETS-I+1))-ETAJET)**2+(DPHI)**2)
          IF(DELR.LT.DELRMIN) THEN
            DELRMIN=DELR
            JRMIN=J
          ENDIF
 110    CONTINUE
        IF(DELRMIN.LT.clfact*RCLMAX) THEN
          NMATCH=NMATCH+1
          KPJ(JRMIN)=I
        ENDIF
C     WRITE(*,*) 'PARTON-JET',I,' best match:',k(ncjet+1-jrmin)
c     $           ,delrmin
      ENDDO
      IF(NMATCH.LT.NQJETS)  THEN
        if(idbg.eq.1)
     $     WRITE(LNHOUT,*) 'Failed due to NMATCH ',NMATCH,' < ',NQJETS
        GOTO 999
      endif
C REJECT EVENTS WITH LARGER JET MULTIPLICITY FROM EXCLUSIVE SAMPLE
      IF(NCJET.GT.NQJETS.AND.IEXC.EQ.1)  THEN
        if(idbg.eq.1)
     $     WRITE(LNHOUT,*) 'Failed due to NCJET ',NCJET,' > ',NQJETS
        GOTO 999
      endif
C     VETO EVENTS WHERE MATCHED JETS ARE SOFTER THAN NON-MATCHED ONES
      IF(IEXC.NE.1) THEN
        J=NCJET
        DO I=1,NQJETS
          IF(KPJ(K(J)).EQ.0) GOTO 999
          J=J-1
        ENDDO
      ENDIF

      else                      ! qcut.gt.0

      if(showerkt) then
C     Use "shower emission pt method"
C     Veto events where first shower emission has kt > YCUT

        IF(NQJETS.EQ.0)THEN
           VINT(358)=0
        ENDIF

        IF(idbg.eq.1) THEN
           PRINT *,'Using shower emission pt method'
           PRINT *,'qcut, ptsort(1), vint(357),vint(358),vint(360): ',
     $          qcut,ptsort(1),vint(357),vint(358),vint(360)
        ENDIF
        SMIN=PTSORT(1)
        
        IF(NQJETS.GT.0.AND.PTSORT(1)**2.LT.QCUT**2) THEN
c       Assume QCUT is smallest allowed, so cut even if USESYST
          if(idbg.eq.1)
     $       WRITE(LNHOUT,*) 'Failed due to KT ',
     $       PTSORT(1),' < ',QCUT
          GOTO 999
        ENDIF

c        PRINT *,'Y,VINT:',SQRT(Y(NQJETS+1)),SQRT(VINT(390))

        IF(IEXC.EQ.1)THEN
           SCOMP=qcut
        ELSE IF(NQJETS.GT.0)THEN
           SCOMP=PTSORT(1)
        ELSE
           SCOMP=1d10           
        ENDIF

        IF(mektsc.eq.1)THEN
           SMAX=MAX(VINT(357),VINT(358))
        ELSE
           SMAX=MAX(VINT(360),VINT(358))
        ENDIF
        
        IF(.NOT.USESYST.AND.SMAX.GT.SCOMP)THEN
           if(idbg.eq.1)
     $          WRITE(LNHOUT,*),
     $          'Failed due to ',SMAX,' > ',SCOMP
          GOTO 999
        ENDIF

      else                      ! not shower kt method

C---FIND FINAL STATE COLOURED PARTICLES
        NN=0
        DO IHEP=1,NHEP
          IF (ISTHEP(IHEP).EQ.1) THEN
            PTJET=sqrt(PHEP(1,IHEP)**2+PHEP(2,IHEP)**2)
            ETAJET=ABS(LOG(MIN((SQRT(PTJET**2+PHEP(3,IHEP)**2)+
     $       ABS(PHEP(3,IHEP)))/PTJET,1d5)))
            IF(ETAJET.GT.etaclmax) cycle
            NN=NN+1
            IF (NN.GT.NMAX) then
              CALL PYLIST(2)
              PRINT *, 'Too many particles: ', NN
              NN=NN-1
              GOTO 120
            endif
            DO I=1,4
              PP(I,NN)=PHEP(I,IHEP)
            ENDDO
            if(idbg.eq.1) write(*,*) 'Particle ',IHEP,
     $           ' included for ktclus'
          ELSE if(idbg.eq.1)THEN
            PRINT *,'Skipping particle ',IHEP,ISTHEP(IHEP),IDHEP(IHEP)
          ENDIF
        ENDDO

c     Set starting value for SCOMP
        IF(IEXC.EQ.1)THEN
           SCOMP=qcut
        ELSE IF(NQJETS.GT.0)THEN
           SCOMP=PTSORT(1)
        ELSE
           SCOMP=1d10           
        ENDIF

C...Cluster event to find values of Y including jet matching but not veto of too many jets
 120    ECUT=1
        NCJET=0
        IF (NN.GT.1) then
C   Now perform jet clustering at the value chosen in qcut
           CALL KTCLUS(KTSCHE,PP,NN,ECUT,Y,*999)
           YCUT=QCUT**2
           NCJET=0
C     Reconstruct jet momenta
          CALL KTRECO(MOD(KTSCHE,10),PP,NN,ECUT,YCUT,YCUT,PJET,JET,
     $       NCJET,NSUB,*999)        

        ELSE IF (NN.EQ.1) THEN

          Y(1)=PP(1,1)**2+PP(2,1)**2
          IF(Y(1).GT.YCUT)THEN
            NCJET=1
            DO I=1,4
              PJET(I,1)=PP(I,1)
            ENDDO
          ENDIF

        ENDIF

        if(idbg.eq.1) then
          write(LNHOUT,*) 'JETS'
          do i=1,ncjet
            PTJET =SQRT(PJET(1,i)**2+PJET(2,i)**2)
            ETAJET=PSERAP(PJET(1,i))
            PHIJET=ATAN2(PJET(2,i),PJET(1,i))
            write(LNHOUT,*) ptjet,etajet,phijet
          enddo
          write(LNHOUT,*) 'sqrt(YJETS): ',(sqrt(Y(i)),i=1,min(NN,4))
        endif

        IF(NQJETS.EQ.0) THEN
           SMIN=1d10
        ELSE
           SMIN=SQRT(Y(NQJETS))
        ENDIF

        IF(SMIN.LT.QCUT) THEN
c       Assume QCUT is smallest allowed, so cut even if USESYST
          if(idbg.eq.1)
     $       WRITE(LNHOUT,*) 'Failed due to Y(NQJETS) ',SMIN,' < ',QCUT
          GOTO 999
        endif

        YCUT=SCOMP**2

C...Right number of jets - but the right jets?        
C     Count jets only to the NHARD:th jet
        IF(NQJETS.GT.0)THEN
           YCUT=Y(NQJETS)
           CALL KTRECO(MOD(KTSCHE,10),PP,NN,ECUT,YCUT,YCUT,PJET,JET,
     $          NCJET,NSUB,*999)
           YCUT=SCOMP**2
        ENDIF
        IF(IEXC.GT.0.AND.NCJET.GT.0)THEN
           SMAX=sqrt(Y(NQJETS+1))
        ELSE
c          For highest mult. sample, only use parton-jet matching below
           SMAX=SCOMP
        ENDIF
        IF(.NOT.USESYST.AND.SMAX.GT.SCOMP) THEN
           if(idbg.eq.1)
     $       WRITE(LNHOUT,*) 'Failed due to Y(NQJETS+1) ',SMAX,' > ',
     $          SCOMP
           GOTO 999
        ENDIF

C     Cluster jets with hard partons, one at a time
        DO I=1,NQJETS
          DO J=1,4
            PPM(J,I)=PJET(J,I)
          ENDDO
        ENDDO

        NJETM=NQJETS

        DO 140 IHARD=1,NQJETS
          NN=NJETM+1
          DO J=1,4
            PPM(J,NN)=p(J,IHARD)
          ENDDO
          CALL KTCLUS(KTSCHE,PPM,NN,ECUT,Y,*999)

          SMAX=MAX(SMAX,sqrt(Y(NN)))
          IF(.NOT.USESYST.AND.SMAX.GT.SCOMP) THEN
C       Parton not clustered
             if(idbg.eq.1)
     $            WRITE(LNHOUT,*) 'Failed due to parton ',IHARD,
     $            ' not clustered: ',Y(NN)
            GOTO 999
          ENDIF
          
C       Find jet clustered with parton

          IP1=HIST(NN)/NMAXKT
          IP2=MOD(HIST(NN),NMAXKT)
          IF(IP2.NE.NN.OR.IP1.LE.0)THEN
c         This cut applies even if USESYST
             if(idbg.eq.1)
     $            WRITE(LNHOUT,*) 'Failed due to parton ',IHARD,
     $            ' not clustered: ',IP1,IP2,NN,HIST(NN)
            GOTO 999
          ENDIF
C     Remove jet clustered with parton
          DO I=IP1,NJETM-1
            DO J=1,4
              PPM(J,I)=PPM(J,I+1)
            ENDDO
          ENDDO
          NJETM=NJETM-1
 140   CONTINUE

C     Now take care of partons that were excluded from matching
C     (b:s or VBF-type forward jets)

      IF(NLJETS.GT.0.OR.IEXC.EQ.1)THEN
        DO IHARD=1,NREM
          NN=0
          DO IHEP=1,NHEP
             IF(IHEP.eq.IREM(IHARD).OR.
     $            JMOHEP(1,IHEP).eq.IREM(IHARD))THEN
                NN=NN+1
                DO J=1,4
                   PPM(J,NN)=PHEP(J,IHEP)
                ENDDO
             ENDIF
          ENDDO
          CALL KTCLUS(KTSCHE,PPM,NN,ECUT,Y,*999)
          SMAX=MAX(SMAX,sqrt(Y(2)))
          IF(SMAX.GT.SCOMP.AND..NOT.USESYST) THEN
C       Parton not clustered
             if(idbg.eq.1)
     $            WRITE(LNHOUT,*) 'Failed due to excluded parton ',
     $            IREM(IHARD),' radiated too much: ',SMAX,SCOMP
             GOTO 999
          ENDIF
        ENDDO
      ENDIF

      endif                     ! pt-ordered showers
      endif                     ! qcut.gt.0

C...Cluster particles with |eta| < etaclmax for histograms
 150  NN=0
      DO IHEP=1,NHEP
         IF (ISTHEP(IHEP).EQ.1
     $        .AND.(ABS(IDHEP(IHEP)).LE.5.OR.IDHEP(IHEP).EQ.21)) THEN
            PTJET=sqrt(PHEP(1,IHEP)**2+PHEP(2,IHEP)**2)
            ETAJET=ABS(LOG(MIN((SQRT(PTJET**2+PHEP(3,IHEP)**2)+
     $           ABS(PHEP(3,IHEP)))/PTJET,1d5)))
            IF(ETAJET.GT.etaclmax) cycle
            NN=NN+1
            IF (NN.GT.NMAX) then
               CALL PYLIST(2)
               PRINT *, 'Too many particles: ', NN
               NN=NN-1
               GOTO 160
            ENDIF
            DO I=1,4
               PP(I,NN)=PHEP(I,IHEP)
            ENDDO
         ELSE if(idbg.eq.1)THEN
            PRINT *,'Skipping particle ',IHEP,ISTHEP(IHEP),IDHEP(IHEP)
         ENDIF
      ENDDO
      
 160  ECUT=1
      IF (NN.GT.1) THEN
         CALL KTCLUS(KTSCHE,PP,NN,ECUT,Y,*999)
      ELSE IF(NN.EQ.1) THEN
         Y(1)=PP(1,NN)**2+PP(2,NN)**2
      ENDIF

      DO I=1,MIN(NN,4)
         varev(1+I)=SQRT(Y(I))
      ENDDO


      RETURN
 4001 FORMAT(50E15.6)
c HERWIG/PYTHIA TERMINATION:
 999  IPVETO=1
      END

C*********************************************************************
C   PYMASC
C   Implementation of scale used in Pythia parton showers
C*********************************************************************
      SUBROUTINE PYMASC(scale)
      IMPLICIT NONE

C...Arguments
      REAL*8 scale

C...Functions
      REAL*8 SMDOT5

C...User process initialization commonblock.
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON/HEPRUP/IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &   IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),XMAXUP(MAXPUP),
     &   LPRUP(MAXPUP)
C...User process event common block.
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,IDUP(MAXNUP),
     &   ISTUP(MAXNUP),MOTHUP(2,MAXNUP),ICOLUP(2,MAXNUP),PUP(5,MAXNUP),
     &   VTIMUP(MAXNUP),SPINUP(MAXNUP)

C...Extra commonblock to transfer run info.
      INTEGER LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE
      COMMON/UPPRIV/LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE

C...Local variables
      INTEGER ICC1,ICC2,IJ,IDC1,IDC2,IC,IC1,IC2
      REAL*8 QMIN,QTMP

C   Just use the scale read off the event record
      scale=SCALUP

C   Alternatively:

C...  Guesses for the correct scale
C     Assumptions:
C     (1) if the initial state is a color singlet, then
C     use s-hat for the scale
C     
C     (2) if color flow to the final state, use the minimum
C     of the dot products of color connected pairs
C     (times two for consistency with above)

        QMIN=SMDOT5(PUP(1,1),PUP(1,2))
        ICC1=1
        ICC2=2
C     
C     For now, there is no generic way to guarantee the "right"
C     scale choice.  Here, we take the HERWIG pt. of view and
C     choose the dot product of the colored connected "primary"
C     pairs.
C     

        DO 101 IJ=1,NUP
          IF(MOTHUP(2,IJ).GT.2) GOTO 101
          IDC1=ICOLUP(1,IJ)
          IDC2=ICOLUP(2,IJ)
          IF(IDC1.EQ.0) IDC1=-1
          IF(IDC2.EQ.0) IDC2=-2
          
          DO 201 IC=IJ+1,NUP
            IF(MOTHUP(2,IC).GT.2) GOTO 201
            IC1=ICOLUP(1,IC)
            IC2=ICOLUP(2,IC)
            IF(ISTUP(IC)*ISTUP(IJ).GE.1) THEN
              IF(IDC1.EQ.IC2.OR.IDC2.EQ.IC1) THEN
                QTMP=SMDOT5(PUP(1,IJ),PUP(1,IC))
                IF(QTMP.LT.QMIN) THEN
                  QMIN=QTMP
                  ICC1=IJ
                  ICC2=IC
                ENDIF
              ENDIF
            ELSEIF(ISTUP(IC)*ISTUP(IJ).LE.-1) THEN
              IF(IDC1.EQ.IC1.OR.IDC2.EQ.IC2) THEN
                QTMP=SMDOT5(PUP(1,IJ),PUP(1,IC))          
                IF(QTMP.LT.QMIN) THEN
                  QMIN=QTMP
                  ICC1=IJ
                  ICC2=IC
                ENDIF
              ENDIF
            ENDIF
 201      CONTINUE
 101    CONTINUE

        scale=QMIN

      RETURN
      END

C...SMDOT5
C   Helper function

      FUNCTION SMDOT5(V1,V2)
      IMPLICIT NONE
      REAL*8 SMDOT5,TEMP
      REAL*8 V1(5),V2(5)
      INTEGER I

      SMDOT5=0D0
      TEMP=V1(4)*V2(4)
      DO I=1,3
        TEMP=TEMP-V1(I)*V2(I)
      ENDDO

      SMDOT5=SQRT(ABS(TEMP))

      RETURN
      END

C*********************************************************************
      
C...modelpar
C...Checks if model is mssm and extracts SLHA file
C...Reads all particle masses and SM parameters in any case

      SUBROUTINE MODELPAR(iunit)

      IMPLICIT NONE

C...Three Pythia functions return integers, so need declaring.
      INTEGER IMSS
      DOUBLE PRECISION RMSS
C...Supersymmetry parameters.
      COMMON/PYMSSM/IMSS(0:99),RMSS(0:99)
C...Pythia common blocks
      INTEGER PYCOMP,MSTU,MSTJ,KCHG
      DOUBLE PRECISION PARU,PARJ,PMAS,PARF,VCKM
C...Parameters.
      COMMON/PYDAT1/MSTU(200),PARU(200),MSTJ(200),PARJ(200)
C...Particle properties + some flavour parameters.
      COMMON/PYDAT2/KCHG(500,4),PMAS(500,4),PARF(2000),VCKM(4,4)
C...Inputs for the matching algorithm
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      double precision etcjet,rclmax,etaclmax,qcut,clfact
      integer maxjets,minjets,iexcfile,ktsche,mektsc,nexcres,excres(30)
      integer nremres, remres(30)
      integer nqmatch,nexcproc,iexcproc(MAXPUP),iexcval(MAXPUP)
      logical nosingrad,showerkt,jetprocs
      common/MEMAIN/etcjet,rclmax,etaclmax,qcut,clfact,maxjets,minjets,
     $   iexcfile,ktsche,mektsc,nexcres,excres,nremres,remres,
     $   nqmatch,nexcproc,iexcproc,iexcval,nosingrad,showerkt,jetprocs

C...Local variables      
      CHARACTER*132 buff,block_name
      CHARACTER*8 model
      INTEGER iunit,ivalue
      DOUBLE PRECISION value
      LOGICAL block_found
      INTEGER i,ifail
      
      buff=' '
      do 100 while(buff.ne.'</slha>' .and.
     $     buff(1:21).ne.'# End param_card.dat')
        read(iunit,'(a132)',end=105,err=98) buff
        
        if(buff.eq.'<slha>' .or.
     $       buff(1:23).eq.'# Begin param_card.dat')then
c       Write out the SLHA file to unit 24
          open(24,status='scratch')
          do while(.true.)
            read(iunit,'(a132)',end=99,err=98) buff
            if(buff.eq.'</slha>' .or.
     $           buff(1:21).eq.'# End param_card.dat') goto 105
            write(24,'(a80)') buff
          end do
        endif
        
        call case_trap2(buff,len_trim(buff))
c     Find and store model used
        if(buff(1:14).eq.'# begin model')then
          read(iunit,'(a132)',end=99,err=98) buff
          model=buff
        endif
c     Find and store QED or HIG order used
c        if(index(buff,'qed').gt.0.or.index(buff,'hig').gt.0)then
c          read(buff(index(buff,'=')+1:),*,err=100) ivalue
c          nosingrad=nosingrad.or.(ivalue.ge.2)
c          if(nosingrad) print *,'Set nosingrad to .true.'
c        endif
 100  continue
 105  continue
      REWIND(iunit)
      REWIND(24)


C...Read the SLHA file
      block_found=.false.
      do 200 while(.true.)
        read(24,'(a132)',end=205,err=98) buff
        call case_trap2(buff,len_trim(buff))
c      Look for "block" to find SM and mass parameters
         if(buff(1:1).eq.'b')then
            block_name=buff(7:)
            block_found=.true.
         endif
         if (block_found) then
            do 10 while(.true.)
               read(24,'(a132)',end=205,err=98) buff
               if(buff.eq.''.or.buff(1:1).eq.'#') goto 10
               if(buff(1:1).ne.' ') then
                  block_found=.false.
                  backspace(24)
                  goto 200
               endif
               if(block_name(1:8).eq.'sminputs')then
                  read(buff,*) ivalue,value
                  print *,'Reading parameter ',block_name(1:8),
     $                 ivalue,value
                  if(ivalue.eq.1) PARU(103)=1d0/value
                  if(ivalue.eq.2) PARU(105)=value
                  if(ivalue.eq.4) PMAS(23,1)=value
                  if(ivalue.eq.6) PMAS(6,1)=value
                  if(ivalue.eq.7) PMAS(15,1)=value
               endif
 10         continue
         endif
 200  continue
 205  continue
      PARU(102)  = 0.5d0-sqrt(0.25d0-
     $     PARU(1)/sqrt(2d0)*PARU(103)/PARU(105)/PMAS(23,1)**2)
      REWIND(24)
      
      write(*,*) 'Reading model: ',model

c      open(24,FILE='SLHA.dat',ERR=91)
c     Pick out SM parameters
c      CALL READSMLHA(iunit)

c      if(index(model,'mssm').ne.0) then
c         call PYGIVE('IMSS(1) = 11')
c         CALL PYSLHA(1,0,IFAIL)
c      endif

c     Just give the LUN to Pythia, and let it take care of initialization
      call PYGIVE('IMSS(21)= 24') ! Logical unit number of SLHA spectrum file
      if(model(1:2).ne.'sm'.and.model(1:4).ne.'mssm') then
         call PYGIVE('IMSS(22)= 24') ! Logical unit number of SLHA decay file
c     Let Pythia read all new particles ("qnumbers")
c         CALL PYSLHA(0,0,IFAIL)
      endif
c     Let Pythia read all masses and, if possible, decays 
c      CALL PYSLHA(5,0,IFAIL)
c      CALL PYSLHA(2,0,IFAIL)
c     Stop Pythia from reading particles and decays a second time
c      if(model(1:2).ne.'sm'.and.model(1:4).ne.'mssm') then
c         call PYGIVE('IMSS(21)= 0') ! Logical unit number of SLHA spectrum file
c         call PYGIVE('IMSS(22)= 0') ! Logical unit number of SLHA decay file
c      endif
      RETURN

 90   WRITE(*,*)'Could not open file SLHA.dat for writing'
      WRITE(*,*)'Quitting...'
      STOP
 98   WRITE(*,*)'Unexpected error reading file'
      WRITE(*,*)'Quitting...'
      STOP
 99   WRITE(*,*)'Unexpected end of file'
      WRITE(*,*)'Quitting...'
      STOP

      END

C*********************************************************************

      subroutine BRSUPP

      IMPLICIT NONE

C...Three Pythia functions return integers, so need declaring.
      INTEGER PYCOMP,MWID
      DOUBLE PRECISION WIDS

C...Resonance width and secondary decay treatment.
      COMMON/PYINT4/MWID(500),WIDS(500,5)

C...User process initialization commonblock.
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON/HEPRUP/IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &   IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),XMAXUP(MAXPUP),
     &   LPRUP(MAXPUP)
C...User process event common block.
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,IDUP(MAXNUP),
     &   ISTUP(MAXNUP),MOTHUP(2,MAXNUP),ICOLUP(2,MAXNUP),PUP(5,MAXNUP),
     &   VTIMUP(MAXNUP),SPINUP(MAXNUP)

C...Extra commonblock to transfer run info.
      INTEGER LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE
      COMMON/UPPRIV/LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE

      INTEGER I,J,IBEG
      INTEGER IPR,isup
      DOUBLE PRECISION SUPPCS
      LOGICAL SUPDONE(MAXPUP)
      DATA SUPDONE/MAXPUP*.false./

C...Lines to read in assumed never longer than 200 characters. 
      INTEGER MAXLEN
      PARAMETER (MAXLEN=200)
      CHARACTER*(MAXLEN) STRING

C...Format for reading lines.
      CHARACTER*6 STRFMT
      STRFMT='(A000)'
      WRITE(STRFMT(3:5),'(I3)') MAXLEN

C...Loop until finds line beginning with "<event>" or "<event ". 
  100 READ(LNHIN,STRFMT,END=130,ERR=130) STRING
      IBEG=0
  110 IBEG=IBEG+1
C...Allow indentation.
      IF(STRING(IBEG:IBEG).EQ.' '.AND.IBEG.LT.MAXLEN-6) GOTO 110 
      IF(STRING(IBEG:IBEG+6).NE.'<event>'.AND.
     &STRING(IBEG:IBEG+6).NE.'<event ') GOTO 100

C...Read first line of event info.
      READ(LNHIN,*,END=130,ERR=130) NUP,IDPRUP,XWGTUP,SCALUP,
     &AQEDUP,AQCDUP

      do IPR=1,NPRUP
         if(IDPRUP .eq. LPRUP(IPR))then
            isup=IPR
            exit
         endif
      enddo

      if(SUPDONE(isup)) GOTO 100

C...Read NUP subsequent lines with information on each particle.
      DO 120 I=1,NUP
        READ(LNHIN,*,END=130,ERR=130) IDUP(I),ISTUP(I),
     &  MOTHUP(1,I),MOTHUP(2,I),ICOLUP(1,I),ICOLUP(2,I),
     &  (PUP(J,I),J=1,5),VTIMUP(I),SPINUP(I)
  120 CONTINUE

      SUPPCS=1.
      do I=3,NUP
        if (ISTUP(I).EQ.1.AND.(IABS(IDUP(I)).GE.23.OR.
     $     (IABS(IDUP(I)).GE.6.AND.IABS(IDUP(I)).LE.8)))
     $     THEN
          WRITE(LNHOUT,*) 'Resonance ',IDUP(I), ' has BRTOT ',
     $       wids(PYCOMP(IDUP(I)),2)
          if(wids(PYCOMP(IDUP(I)),2).lt.0.95) then
            SUPPCS=SUPPCS*wids(PYCOMP(IDUP(I)),2)
          endif
        endif
      enddo
      if(SUPPCS.gt.0)then
         write(*,*)'Multiplying cross section for process ',
     $        IDPRUP,' by ',SUPPCS
         XSECUP(isup)=XSECUP(isup)*SUPPCS
      else
         write(*,*) 'Warning! Got cross section suppression 0 ',
     $        'for process ',IDPRUP
         write(*,*) 'No cross section reduction done'
      endif

      SUPDONE(isup)=.true.
      do i=1,NPRUP
         if(.not. SUPDONE(i)) GOTO 100
      enddo

 130  RETURN
      END
      
      subroutine case_trap2(name,n)
c**********************************************************
c   change the string to lowercase if the input is not
c**********************************************************
      implicit none
c   
c   ARGUMENT
c   
      character(*) name
      integer n
c   
c   LOCAL
c   
      integer i,k

      do i=1,n
        k=ichar(name(i:i))
        if(k.ge.65.and.k.le.90) then !upper case A-Z
          k=ichar(name(i:i))+32   
          name(i:i)=char(k)        
        endif
      enddo

      return
      end

c----------------------------------------------------------------------
c   READ_PARAMS
c   Read the parameters from the run_card in the MadEvent event file
c----------------------------------------------------------------------

      subroutine read_params(iunit,npara,param,value,maxpara)
      implicit none

c   
c   arguments
c   
      integer iunit
      character*20 param(*),value(*)
      integer npara,maxpara

C...User process initialization commonblock.
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON/HEPRUP/IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &   IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),XMAXUP(MAXPUP),
     &   LPRUP(MAXPUP)
C...User process event common block.
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,IDUP(MAXNUP),
     &   ISTUP(MAXNUP),MOTHUP(2,MAXNUP),ICOLUP(2,MAXNUP),PUP(5,MAXNUP),
     &   VTIMUP(MAXNUP),SPINUP(MAXNUP)

c   
c   local
c   
      logical fopened
      character*20 ctemp
      integer k,i,l1,l2,j,jj
      character*132 buff
      integer NPARTS,KNTEV,NJETS,MAXNJ,NREAD
      parameter(MAXNJ=6)
      double precision WTEVNT,XSTOT(MAXNJ),DUMMY,WTMAX
c   
c----------
c   start
c----------

      NREAD=0

c   
c   read the input-card.dat
c   
      npara=1
      param(1)=' '
      value(1)=' '
      WTMAX=0D0
c   
c   read in values
c   
      buff=' '
      do while(index(buff,'<mgruncard>').eq.0 .and.
     $     index(buff,'Begin run_card.dat').eq.0)
        read(iunit,'(a132)',end=99,err=99) buff
        call case_trap2(buff,20)
      enddo
      do 10 while(index(buff,'</mgruncard>').eq.0 .and.
     $     index(buff,'End run_card.dat').eq.0 .and.
     $     npara.le.maxpara)
        read(iunit,'(a132)',end=99,err=99) buff
        call case_trap2(buff,20)
        if(buff.eq.' ') then
          goto 10
        endif

        if(index(buff,'=').ne.0) then
          l1=index(buff,'=')
          l2=index(buff,'!')
          if(l2.eq.0) l2=l1+20  !maybe there is no comment...
c       
          value(npara)=buff(1:l1-1)
          ctemp=value(npara)
          call case_trap2(ctemp,20)
          value(npara)=ctemp
c       
          param(npara)=" "//buff(l1+1:l2-1)
          ctemp=param(npara)
          call case_trap2(ctemp,20)
          param(npara)=ctemp
c       
          npara=npara+1
        endif
 10   continue

      REWIND(iunit)

      return

 99   WRITE(*,*)'Unexpected error reading file'
      WRITE(*,*)'Quitting...'
      STOP
      end

C*********************************************************************      
C...set_matching
C...Sets parameters for the matching, i.e. cuts and jet multiplicities
C*********************************************************************      

      SUBROUTINE set_matching(iunit,npara,param,value)
      implicit none
c   
c   arguments
c   
      integer iunit,npara
      character*20 param(*),value(*)

C...Pythia parameters.
      INTEGER MSTP,MSTI
      DOUBLE PRECISION PARP,PARI
      COMMON/PYPARS/MSTP(200),PARP(200),MSTI(200),PARI(200)

C...User process initialization commonblock.
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      INTEGER IDBMUP,PDFGUP,PDFSUP,IDWTUP,NPRUP,LPRUP
      DOUBLE PRECISION EBMUP,XSECUP,XERRUP,XMAXUP
      COMMON/HEPRUP/IDBMUP(2),EBMUP(2),PDFGUP(2),PDFSUP(2),
     &   IDWTUP,NPRUP,XSECUP(MAXPUP),XERRUP(MAXPUP),XMAXUP(MAXPUP),
     &   LPRUP(MAXPUP)

C...User process event common block.
      INTEGER MAXNUP
      PARAMETER (MAXNUP=500)
      INTEGER NUP,IDPRUP,IDUP,ISTUP,MOTHUP,ICOLUP
      DOUBLE PRECISION XWGTUP,SCALUP,AQEDUP,AQCDUP,PUP,VTIMUP,SPINUP
      COMMON/HEPEUP/NUP,IDPRUP,XWGTUP,SCALUP,AQEDUP,AQCDUP,IDUP(MAXNUP),
     &   ISTUP(MAXNUP),MOTHUP(2,MAXNUP),ICOLUP(2,MAXNUP),PUP(5,MAXNUP),
     &   VTIMUP(MAXNUP),SPINUP(MAXNUP)

C...Extra commonblock to transfer run info.
      INTEGER LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE
      COMMON/UPPRIV/LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE

C...Inputs for the matching algorithm
      double precision etcjet,rclmax,etaclmax,qcut,clfact
      integer maxjets,minjets,iexcfile,ktsche,mektsc,nexcres,excres(30)
      integer nremres, remres(30)
      integer nqmatch,nexcproc,iexcproc(MAXPUP),iexcval(MAXPUP)
      logical nosingrad,showerkt,jetprocs
      common/MEMAIN/etcjet,rclmax,etaclmax,qcut,clfact,maxjets,minjets,
     $   iexcfile,ktsche,mektsc,nexcres,excres,nremres,remres,
     $   nqmatch,nexcproc,iexcproc,iexcval,nosingrad,showerkt,jetprocs

C...Commonblock to transfer event-by-event matching info
      INTEGER NLJETS,NQJETS,IEXC,Ifile
      DOUBLE PRECISION PTCLUS
      COMMON/MEMAEV/PTCLUS(20),NLJETS,NQJETS,IEXC,Ifile

C...Local variables
      INTEGER I,MAXNJ,NREAD,MINJ,MAXJ
      parameter(MAXNJ=6)
      DOUBLE PRECISION XSTOT(MAXNJ),XSECTOT
      DOUBLE PRECISION ptjmin,etajmax,drjmin,ptbmin,etabmax,xqcut

C...Functions
      INTEGER iexclusive
      EXTERNAL iexclusive

C...Need lower scale for final state radiation in e+e-
      IF(IABS(IDBMUP(1)).EQ.11.AND.IABS(IDBMUP(2)).EQ.11) then
        CALL PYGIVE('PARP(71)=1')
      ENDIF

C...CRUCIAL FOR JET-PARTON MATCHING: CALL UPVETO, ALLOW JET-PARTON MATCHING
      call pygive('MSTP(143)=1')

C     
C...Check jet multiplicities and set processes
C
      DO I=1,MAXNJ
        XSTOT(I)=0D0
      ENDDO
      MINJ=MAXNJ
      MAXJ=0
      NREAD=0
      DO WHILE(.true.)
        CALL UPEVNT()
        IF(NUP.eq.0) goto 20
        IF(IEXC.EQ.-1) cycle
        if(NLJETS.GT.MAXJ) MAXJ=NLJETS
        if(NLJETS.LT.MINJ) MINJ=NLJETS
c        XSTOT(NLJETS+1)=XSTOT(NLJETS+1)+XWGTUP
        XSTOT(NLJETS+1)=XSTOT(NLJETS+1)+1
        NREAD=NREAD+1
      ENDDO

 20   continue

      REWIND(iunit)

      write(LNHOUT,*) 'Minimum number of jets in file: ',MINJ
      write(LNHOUT,*) 'Maximum number of jets in file: ',MAXJ

      XSECTOT=0d0
      DO I=1,NPRUP
         XSECTOT=XSECTOT+XSECUP(I)
      ENDDO

      IF(NPRUP.eq.1.AND.MINJ.lt.MAXJ)THEN
C...If different process ids not set by user, set by jet number
         jetprocs=.true.
         IF(IEXCFILE.eq.0.AND.iexclusive(LPRUP(1)).ne.1) THEN
            nexcproc=1
            IEXCPROC(1)=MAXJ-MINJ
            IEXCVAL(1)=0
         ENDIF
         NPRUP=1+MAXJ-MINJ
         DO I=MINJ,MAXJ
            XSECUP(1+I-MINJ) = XSECTOT*XSTOT(I+1)/NREAD
            XMAXUP(1+I-MINJ) = XMAXUP(1)
            LPRUP(1+I-MINJ)  = I-MINJ
         ENDDO
      ELSE IF(IEXCFILE.EQ.0) THEN
C...Check if any IEXCPROC set, then set IEXCFILE=1
         DO I=1,NPRUP
            IF(iexclusive(LPRUP(I)).EQ.0) IEXCFILE=1
         ENDDO
      ENDIF

      WRITE(LNHOUT,*) ' Number of Events Read:: ',NREAD
      WRITE(LNHOUT,*) ' Total cross section (pb):: ',XSECTOT
      WRITE(LNHOUT,*) ' Process   Cross Section (pb):: '
      DO I=1,NPRUP
        WRITE(LNHOUT,'(I5,E23.5)') I,XSECUP(I)
      ENDDO

      IF(MINJETS.EQ.-1) MINJETS=MINJ
      IF(MAXJETS.EQ.-1) MAXJETS=MAXJ
      write(LNHOUT,*) 'Minimum number of jets allowed: ',MINJETS
      write(LNHOUT,*) 'Maximum number of jets allowed: ',MAXJETS
      write(LNHOUT,*) 'IEXCFILE = ',IEXCFILE
      write(LNHOUT,*) 'jetprocs = ',jetprocs
      DO I=1,NPRUP
         write(LNHOUT,*) 'IEXCPROC(',LPRUP(I),') = ',
     $        iexclusive(LPRUP(I))
      ENDDO

      CALL FLUSH()

C...Run PYPTFS instead of PYSHOW
c        CALL PYGIVE("MSTJ(41)=12")

c***********************************************************************
c   Read in jet cuts
c***********************************************************************

        call get_real   (npara,param,value," ptj " ,ptjmin,7d3)
        call get_real   (npara,param,value," etaj " ,etajmax,1d5)
        call get_real   (npara,param,value," ptb " ,ptbmin,7d3)
        call get_real   (npara,param,value," etab " ,etabmax,1d5)
        call get_real   (npara,param,value," drjj " ,drjmin,1d5)
        call get_real   (npara,param,value," xqcut " ,xqcut,0d0)

        if(qcut.lt.xqcut) then
           if(showerkt) then
              qcut=xqcut
           else
              qcut=min(max(1.4*xqcut,xqcut+10),2*xqcut)
           endif
        endif
        if(xqcut.le.0)then
           write(*,*) 'Warning! ME generation QCUT = 0. QCUT set to 0!'
           qcut=0
        endif

c        etajmax=min(etajmax,etabmax)
c        ptjmin=max(ptjmin,ptbmin)

c      IF(ICKKW.EQ.1) THEN
c        WRITE(*,*) ' '
c        WRITE(*,*) 'INPUT 0 FOR INCLUSIVE JET SAMPLE, 1 FOR EXCLUSIVE'
c        WRITE(*,*) '(SELECT 0 FOR HIGHEST PARTON MULTIPLICITY SAMPLE)' 
c        WRITE(*,*) '(SELECT 1 OTHERWISE)'
c        READ(*,*) IEXCFILE
c      ENDIF
        
C     INPUT PARAMETERS FOR CONE ALGORITHM

        IF(ETCJET.LE.PTJMIN)THEN
           ETCJET=MAX(PTJMIN+5,1.2*PTJMIN)
        ENDIF

        RCLMAX=DRJMIN
        ETACLMAX=ETAJMAX
        IF(ETACLMAX.LT.0) ETACLMAX=1D5
        IF(qcut.le.0)THEN
          WRITE(*,*) 'JET CONE PARAMETERS FOR MATCHING:'
          WRITE(*,*) 'ET>',ETCJET,' R=',RCLMAX
          WRITE(*,*) 'DR(PARTON-JET)<',1.5*RCLMAX
          WRITE(*,*) 'ETA(JET)<',ETACLMAX
        ELSE IF(ickkw.eq.1) THEN
          WRITE(*,*) 'KT JET PARAMETERS FOR MATCHING:'
          WRITE(*,*) 'QCUT=',qcut
          WRITE(*,*) 'ETA(JET)<',ETACLMAX
          WRITE(*,*) 'Note that in ME generation, qcut = ',xqcut
          if(showerkt.and.MSTP(81).LT.20)THEN
            WRITE(*,*)'WARNING: "shower kt" needs pT-ordered showers'
            WRITE(*,*)'         Setting MSTP(81)=',20+MOD(MSTP(81),10)
            MSTP(81)=20+MOD(MSTP(81),10)
          endif
        else if(ickkw.eq.2)then
c     Turn off color coherence suppressions (leave this to ME)
          CALL PYGIVE('MSTP(62)=2')
          CALL PYGIVE('MSTP(67)=0')
          if(MSTP(81).LT.20)THEN
            WRITE(*,*)'WARNING: Must run CKKW with pt-ordered showers'
            WRITE(*,*)'         Setting MSTP(81)=',20+MOD(MSTP(81),10)
            MSTP(81)=20+MOD(MSTP(81),10)
          endif
        endif
      return
      end

      subroutine get_real(npara,param,value,name,var,def_value)
c----------------------------------------------------------------------------------
c   finds the parameter named "name" in param and associate to "value" in value 
c----------------------------------------------------------------------------------
      implicit none

c   
c   arguments
c   
      integer npara
      character*20 param(*),value(*)
      character*(*)  name
      real*8 var,def_value
c   
c   local
c   
      logical found
      integer i
c   
c   start
c   
      i=1
      found=.false.
      do while(.not.found.and.i.le.npara)
        found = (index(param(i),name).ne.0)
        if (found) read(value(i),*) var
c     if (found) write (*,*) name,var
        i=i+1
      enddo
      if (.not.found) then
        write (*,*) "Warning: parameter ",name," not found"
        write (*,*) "         setting it to default value ",def_value
        var=def_value
      else
        write(*,*),'Found parameter ',name,var
      endif
      return

      end
c   

      subroutine get_integer(npara,param,value,name,var,def_value)
c----------------------------------------------------------------------------------
c   finds the parameter named "name" in param and associate to "value" in value 
c----------------------------------------------------------------------------------
      implicit none
c   
c   arguments
c   
      integer npara
      character*20 param(*),value(*)
      character*(*)  name
      integer var,def_value
c   
c   local
c   
      logical found
      integer i
c   
c   start
c   
      i=1
      found=.false.
      do while(.not.found.and.i.le.npara)
        found = (index(param(i),name).ne.0)
        if (found) read(value(i),*) var
c     if (found) write (*,*) name,var
        i=i+1
      enddo
      if (.not.found) then
        write (*,*) "Warning: parameter ",name," not found"
        write (*,*) "         setting it to default value ",def_value
        var=def_value
      else
        write(*,*)'Found parameter ',name,var
      endif
      return

      end

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
C----Calorimeter simulation obtained from Frank Paige 23 March 1988-----
C
C          USE
C
C     CALL CALINIM
C     CALL CALSIMM
C
C          THEN TO FIND JETS WITH A SIMPLIFIED VERSION OF THE UA1 JET
C          ALGORITHM WITH JET RADIUS RJET AND MINIMUM SCALAR TRANSVERSE
C          ENERGY EJCUT
C            (RJET=1., EJCUT=5. FOR UA1)
C          USE
C
C     CALL GETJETM(RJET,EJCUT)
C
C
C-----------------------------------------------------------------------
C 
C          ADDED BY MIKE SEYMOUR: PARTON-LEVEL CALORIMETER. ALL PARTONS
C          ARE CONSIDERED TO BE HADRONS, SO IN FACT RESEM IS IGNORED
C
C     CALL CALPARM
C
C          HARD PARTICLE CALORIMETER. ONLY USES THOSE PARTICLES WHICH
C          CAME FROM THE HARD PROCESS, AND NOT THE UNDERLYING EVENT
C
C     CALL CALHARM
C
C-----------------------------------------------------------------------
      SUBROUTINE CALINIM
C                
C          INITIALIZE CALORIMETER FOR CALSIMM AND GETJETM.  NOTE THAT
C          BECAUSE THE INITIALIZATION IS SEPARATE, CALSIMM CAN BE
C          CALLED MORE THAN ONCE TO SIMULATE PILEUP OF SEVERAL EVENTS.
C
      IMPLICIT NONE
C...GETJET commonblocks
      INTEGER MNCY,MNCPHI,NCY,NCPHI,NJMAX,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,DELY,DELPHI,ET,STHCAL,CTHCAL,CPHCAL,
     &  SPHCAL,PCJET,ETJET
      PARAMETER (MNCY=200)
      PARAMETER (MNCPHI=200)
      COMMON/CALORM/DELY,DELPHI,ET(MNCY,MNCPHI),
     $CTHCAL(MNCY),STHCAL(MNCY),CPHCAL(MNCPHI),SPHCAL(MNCPHI),
     $YCMIN,YCMAX,NCY,NCPHI
      PARAMETER (NJMAX=500)
      COMMON/GETCOMM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(MNCY,MNCPHI),
     $     NCJET

      INTEGER IPHI,IY
      DOUBLE PRECISION PI,PHIX,YX,THX
      PARAMETER (PI=3.141593D0)
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
      SUBROUTINE CALSIMM
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

C...GETJET commonblocks
      INTEGER MNCY,MNCPHI,NCY,NCPHI,NJMAX,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,DELY,DELPHI,ET,STHCAL,CTHCAL,CPHCAL,
     &  SPHCAL,PCJET,ETJET
      PARAMETER (MNCY=200)
      PARAMETER (MNCPHI=200)
      COMMON/CALORM/DELY,DELPHI,ET(MNCY,MNCPHI),
     $CTHCAL(MNCY),STHCAL(MNCY),CPHCAL(MNCPHI),SPHCAL(MNCPHI),
     $YCMIN,YCMAX,NCY,NCPHI
      PARAMETER (NJMAX=500)
      COMMON/GETCOMM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(MNCY,MNCPHI),
     $     NCJET

      INTEGER IHEP,ID,IY,IPHI
      DOUBLE PRECISION PI,YIP,PSERAP,PHIIP,EIP
      PARAMETER (PI=3.141593D0)
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
      SUBROUTINE GETJETM(RJET,EJCUT,ETAJCUT)
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
C...GETJET commonblocks
      INTEGER MNCY,MNCPHI,NCY,NCPHI,NJMAX,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,DELY,DELPHI,ET,STHCAL,CTHCAL,CPHCAL,
     &  SPHCAL,PCJET,ETJET
      PARAMETER (MNCY=200)
      PARAMETER (MNCPHI=200)
      COMMON/CALORM/DELY,DELPHI,ET(MNCY,MNCPHI),
     $CTHCAL(MNCY),STHCAL(MNCY),CPHCAL(MNCPHI),SPHCAL(MNCPHI),
     $YCMIN,YCMAX,NCY,NCPHI
      PARAMETER (NJMAX=500)
      COMMON/GETCOMM/PCJET(4,NJMAX),ETJET(NJMAX),JETNO(MNCY,MNCPHI),
     $     NCJET

      INTEGER IPHI,IY,J,K,NPHI1,NPHI2,NY1,
     &  NY2,IPASS,IYMX,IPHIMX,ITLIS,IPHI1,IPHIX,IY1,IYX
      DOUBLE PRECISION PI,RJET,
     &  ETMAX,ETSTOP,RR,ECCUT,PX,EJCUT
      PARAMETER (PI=3.141593D0)
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
8888    FORMAT(//' ERROR IN GETJETM...IPASS > ',I6)
        RETURN
      ENDIF
      NCJET=NCJET+1
      IF(NCJET.GT.NJMAX) THEN
        WRITE(ITLIS,9999) NCJET
9999    FORMAT(//' ERROR IN GETJETM...NCJET > ',I5)
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
      SUBROUTINE CALDELM(ISTLO,ISTHI)
C     LABEL ALL PARTICLES WITH STATUS BETWEEN ISTLO AND ISTHI (UNTIL A
C     PARTICLE WITH STATUS ISTOP IS FOUND) AS FINAL-STATE, CALL CALSIMM
C     AND THEN PUT LABELS BACK TO NORMAL
C-----------------------------------------------------------------------
      IMPLICIT NONE
      INTEGER MAXNUP
      PARAMETER(MAXNUP=500)
C...HEPEVT commonblock.
      INTEGER NMXHEP,NEVHEP,NHEP,ISTHEP,IDHEP,JMOHEP,JDAHEP
      PARAMETER (NMXHEP=4000)
      COMMON/HEPEVT/NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),PHEP(5,NMXHEP),VHEP(4,NMXHEP)
      DOUBLE PRECISION PHEP,VHEP
      SAVE /HEPEVT/
      INTEGER ISTOLD(NMXHEP),IHEP,IST,ISTLO,ISTHI,ISTOP,IMO,icount


      CALL CALSIMM
      END

C****************************************************
C iexclusive returns whether exclusive process or not
C****************************************************

      integer function iexclusive(iproc)
      implicit none
      
      integer iproc, i

C...Inputs for the matching algorithm
      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
      double precision etcjet,rclmax,etaclmax,qcut,clfact
      integer maxjets,minjets,iexcfile,ktsche,mektsc,nexcres,excres(30)
      integer nremres, remres(30)
      integer nqmatch,nexcproc,iexcproc(MAXPUP),iexcval(MAXPUP)
      logical nosingrad,showerkt,jetprocs
      common/MEMAIN/etcjet,rclmax,etaclmax,qcut,clfact,maxjets,minjets,
     $   iexcfile,ktsche,mektsc,nexcres,excres,nremres,remres,
     $   nqmatch,nexcproc,iexcproc,iexcval,nosingrad,showerkt,jetprocs
      
      iexclusive=-2
      do i=1,nexcproc
         if(iproc.eq.iexcproc(i)) then
            iexclusive=iexcval(i)
            return
         endif
      enddo

      return
      end

C***********************************
C Common block initialization block
C***********************************      

      BLOCK DATA MEPYDAT

      INTEGER MAXPUP
      PARAMETER (MAXPUP=100)
C...Inputs for the matching algorithm
      double precision etcjet,rclmax,etaclmax,qcut,clfact
      integer maxjets,minjets,iexcfile,ktsche,mektsc,nexcres,excres(30)
      integer nremres, remres(30)
      integer nqmatch,nexcproc,iexcproc(MAXPUP),iexcval(MAXPUP)
      logical nosingrad,showerkt,jetprocs
      common/MEMAIN/etcjet,rclmax,etaclmax,qcut,clfact,maxjets,minjets,
     $   iexcfile,ktsche,mektsc,nexcres,excres,nremres,remres,
     $   nqmatch,nexcproc,iexcproc,iexcval,nosingrad,showerkt,jetprocs

C...GETJET commonblocks
      INTEGER MNCY,MNCPHI,NCY,NCPHI,NJMAX,JETNO,NCJET
      DOUBLE PRECISION YCMIN,YCMAX,DELY,DELPHI,ET,STHCAL,CTHCAL,CPHCAL,
     &  SPHCAL,PCJET,ETJET
      PARAMETER (MNCY=200)
      PARAMETER (MNCPHI=200)
      COMMON/CALORM/DELY,DELPHI,ET(MNCY,MNCPHI),
     $CTHCAL(MNCY),STHCAL(MNCY),CPHCAL(MNCPHI),SPHCAL(MNCPHI),
     $YCMIN,YCMAX,NCY,NCPHI

C...Extra commonblock to transfer run info.
      INTEGER LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE
      COMMON/UPPRIV/LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE

C...Initialization statements
      DATA qcut,clfact,etcjet/0d0,0d0,0d0/
      DATA ktsche,mektsc,maxjets,minjets,nexcres/0,1,-1,-1,0/
      DATA nqmatch/0/
      DATA nexcproc/0/
      DATA iexcproc/MAXPUP*-1/
      DATA iexcval/MAXPUP*-2/
      DATA nosingrad,showerkt,jetprocs/.false.,.false.,.false./

      DATA NCY,NCPHI/50,60/

      DATA LNHIN,LNHOUT,MSCAL,IEVNT,ICKKW,ISCALE/77,6,0,0,0,1/

      END


