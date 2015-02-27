      subroutine InitEvolve(x,Q,f)
      implicit none
      character*16 s2		!*** unused s1 removed (jcp) ***
      real*8 x,Q,Q2,Q2fit,muR
      real*8 f(-6:6)		!*** unused pdf removed (jcp) ***
      integer order,EvlOrd,code
      save EvlOrd,Q2fit,muR
*
      EvlOrd=-1
      read(1,*) s2,Q2fit,muR
c	print *,'InitEvolve read s2=',s2,		!*** temporary ***
c     &	' Q2fit=',Q2fit,' muR=',muR			!*** temporary ***
      if (index(s2,'lo').eq.1) EvlOrd=0
      if (index(s2,'nlo').eq.1) EvlOrd=1
      if (index(s2,'nnlo').eq.1) EvlOrd=2
      if (EvlOrd.lt.0) then
         write(*,*) 'File description error:'
         write(*,*) 'Unknown PDF evolution order ',s2
         stop
      endif
      if (muR.ne.1.0d0) then
         write(*,*) '***********************************************'
         write(*,*) '* Note than the renormalization scale is      *'
         write(*,*) '* unequal to the factorization scale for this *'
         write(*,*) '* particular PDF set.                         *'
         write(*,*) '* See manual for proper use.                  *'
         write(*,*) '***********************************************'
      endif
      call readevolve
      return
*
      entry InitEvolveCode
      call initevolution(EvlOrd,Q2fit)
      return
*
      entry GetOrderPDF(order)
      order=EvlOrd
      return
*
      entry GetRenFac(Q)
      Q=muR
      return
*
      entry GetQ2fit(Q2)
      Q2=Q2fit
      return
*
      end
