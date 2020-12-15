;Vortex Tracker II v1.0 PT3 player for ZX Spectrum
;(c)2004,2007 S.V.Bulba <vorobey@mail.khstu.ru>
;http://bulba.untergrund.net (http://bulba.at.kz)

;Release number
Release EQU "7"

;Features
;--------
;-Can be compiled at any address (i.e. no need rounding ORG
; address).
;-Variables (VARS) can be located at any address (not only after
;code block).
;-INIT subroutine detects module version and rightly generates
; both note and volume tables outside of code block (in VARS).
;-Two portamento (spc. command 3xxx) algorithms (depending of
; module version).
;-New 1.XX and 2.XX special command behaviour (only for PT v3.7
; and higher).
;-Any Tempo value are accepted (including Tempo=1 and Tempo=2).
;-Fully compatible with Ay_Emul PT3 player codes.
;-See also notes at the end of this source code.

;Limitations
;-----------
;-Can run in RAM only (self-modified code is used).

;Warning!!! PLAY subroutine can crash if no module are loaded
;into RAM or INIT subroutine was not called before.

;Call MUTE or INIT one more time to mute sound after stopping
;playing 

	ORG #C000

;Test codes (commented)
;	CALL START
;	EI
;_LP	HALT
;	CALL START+5
;	XOR A
;	IN A,(#FE)
;	CPL
;	AND 15
;	JR Z,_LP
;	JR START+8

TonA	EQU 0
TonB	EQU 2
TonC	EQU 4
Noise	EQU 6
Mixer	EQU 7
AmplA	EQU 8
AmplB	EQU 9
AmplC	EQU 10
Env	EQU 11
EnvTp	EQU 13

;Entry and other points
;START initialization
;START+3 initialization with module address in HL
;START+5 play one quark
;START+8 mute
;START+10 setup and status flags
;START+11 pointer to current position value in PT3 module;
;After INIT (START+11) points to Postion0-1 (optimization)

START
	LD HL,MDLADDR
	JR INIT
	JP PLAY
	JR MUTE
SETUP	DB 0 ;set bit0 to 1, if you want to play without looping
	     ;bit7 is set each time, when loop point is passed
CrPsPtr	DW 0 

;Identifier
	DB "=VTII PT3 Player r.",Release,"="

CHECKLP	LD HL,SETUP
	SET 7,(HL)
	BIT 0,(HL)
	RET Z
	POP HL
	LD HL,DelyCnt
	INC (HL)
	LD HL,ChanA+CHP.NtSkCn
	INC (HL)
MUTE	XOR A
	LD H,A
	LD L,A
	LD (AYREGS+AmplA),A
	LD (AYREGS+AmplB),HL
	JP ROUT_A0

INIT
;HL - AddressOfModule

	LD (MODADDR),HL
	LD (MDADDR2),HL
	PUSH HL
	LD DE,100
	ADD HL,DE
	LD A,(HL)
	LD (Delay),A
	PUSH HL
	POP IX
	ADD HL,DE
	LD (CrPsPtr),HL
	LD E,(IX+102-100)
	ADD HL,DE
	INC HL
	LD (LPosPtr),HL
	POP DE
	LD L,(IX+103-100)
	LD H,(IX+104-100)
	ADD HL,DE
	LD (PatsPtr),HL
	LD HL,169
	ADD HL,DE
	LD (OrnPtrs),HL
	LD HL,105
	ADD HL,DE
	LD (SamPtrs),HL
	LD HL,SETUP
	RES 7,(HL)

;note table data depacker
	LD DE,T_PACK
	LD BC,T1_+(2*49)-1
TP_0	LD A,(DE)
	INC DE
	CP 15*2
	JR NC,TP_1
	LD H,A
	LD A,(DE)
	LD L,A
	INC DE
	JR TP_2
TP_1	PUSH DE
	LD D,0
	LD E,A
	ADD HL,DE
	ADD HL,DE
	POP DE
TP_2	LD A,H
	LD (BC),A
	DEC BC
	LD A,L
	LD (BC),A
	DEC BC
	SUB #F8*2
	JR NZ,TP_0

	LD HL,VARS
	LD (HL),A
	LD DE,VARS+1
	LD BC,VAR0END-VARS-1
	LDIR
	INC A
	LD (DelyCnt),A
	LD HL,#F001 ;H - CHP.Volume, L - CHP.NtSkCn
	LD (ChanA+CHP.NtSkCn),HL
	LD (ChanB+CHP.NtSkCn),HL
	LD (ChanC+CHP.NtSkCn),HL

	LD HL,EMPTYSAMORN
	LD (AdInPtA),HL ;ptr to zero
	LD (ChanA+CHP.OrnPtr),HL ;ornament 0 is "0,1,0"
	LD (ChanB+CHP.OrnPtr),HL ;in all versions from
	LD (ChanC+CHP.OrnPtr),HL ;3.xx to 3.6x and VTII

	LD (ChanA+CHP.SamPtr),HL ;S1 There is no default
	LD (ChanB+CHP.SamPtr),HL ;S2 sample in PT3, so, you
	LD (ChanC+CHP.SamPtr),HL ;S3 can comment S1,2,3; see
				    ;also EMPTYSAMORN comment

	LD A,(IX+13-100) ;EXTRACT VERSION NUMBER
	SUB #30
	JR C,L20
	CP 10
	JR C,L21
L20	LD A,6
L21	LD (Version),A
	PUSH AF
	CP 4
	LD A,(IX+99-100) ;TONE TABLE NUMBER
	RLA
	AND 7

;NoteTableCreator (c) Ivan Roshin
;A - NoteTableNumber*2+VersionForNoteTable
;(xx1b - 3.xx..3.4r, xx0b - 3.4x..3.6x..VTII1.0)

	LD HL,NT_DATA
	PUSH DE
	LD D,B
	ADD A,A
	LD E,A
	ADD HL,DE
	LD E,(HL)
	INC HL
	SRL E
	SBC A,A
	AND #A7 ;#00 (NOP) or #A7 (AND A)
	LD (L3),A
	EX DE,HL
	POP BC ;BC=T1_
	ADD HL,BC

	LD A,(DE)
	ADD A,T_
	LD C,A
	ADC A,T_/256
	SUB C
	LD B,A
	PUSH BC
	LD DE,NT_
	PUSH DE

	LD B,12
L1	PUSH BC
	LD C,(HL)
	INC HL
	PUSH HL
	LD B,(HL)

	PUSH DE
	EX DE,HL
	LD DE,23
	LD IXH,8

L2	SRL B
	RR C
L3	DB #19	;AND A or NOP
	LD A,C
	ADC A,D	;=ADC 0
	LD (HL),A
	INC HL
	LD A,B
	ADC A,D
	LD (HL),A
	ADD HL,DE
	DEC IXH
	JR NZ,L2

	POP DE
	INC DE
	INC DE
	POP HL
	INC HL
	POP BC
	DJNZ L1

	POP HL
	POP DE

	LD A,E
	CP TCOLD_1
	JR NZ,CORR_1
	LD A,#FD
	LD (NT_+#2E),A

CORR_1	LD A,(DE)
	AND A
	JR Z,TC_EXIT
	RRA
	PUSH AF
	ADD A,A
	LD C,A
	ADD HL,BC
	POP AF
	JR NC,CORR_2
	DEC (HL)
	DEC (HL)
CORR_2	INC (HL)
	AND A
	SBC HL,BC
	INC DE
	JR CORR_1

TC_EXIT

	POP AF

;VolTableCreator (c) Ivan Roshin
;A - VersionForVolumeTable (0..4 - 3.xx..3.4x;
			   ;5.. - 3.5x..3.6x..VTII1.0)

	CP 5
	LD HL,#11
	LD D,H
	LD E,H
	LD A,#17
	JR NC,M1
	DEC L
	LD E,L
	XOR A
M1      LD (M2),A

	LD IX,VT_+16
	LD C,#10

INITV2  PUSH HL

	ADD HL,DE
	EX DE,HL
	SBC HL,HL

INITV1  LD A,L
M2      DB #7D
	LD A,H
	ADC A,0
	LD (IX),A
	INC IX
	ADD HL,DE
	INC C
	LD A,C
	AND 15
	JR NZ,INITV1

	POP HL
	LD A,E
	CP #77
	JR NZ,M3
	INC E
M3      LD A,C
	AND A
	JR NZ,INITV2

	JP ROUT_A0

;pattern decoder
PD_OrSm	LD (IX-12+CHP.Env_En),0
	CALL SETORN
	LD A,(BC)
	INC BC
	RRCA

PD_SAM	ADD A,A
PD_SAM_	LD E,A
	LD D,0
SamPtrs EQU $+1
	LD HL,#2121
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
MODADDR EQU $+1
	LD HL,#2121
	ADD HL,DE
	LD (IX-12+CHP.SamPtr),L
	LD (IX-12+CHP.SamPtr+1),H
	JR PD_LOOP

PD_VOL	RLCA
	RLCA
	RLCA
	RLCA
	LD (IX-12+CHP.Volume),A
	JR PD_LP2
	
PD_EOff	LD (IX-12+CHP.Env_En),A
	LD (IX-12+CHP.PsInOr),A
	JR PD_LP2

PD_SorE	DEC A
	JR NZ,PD_ENV
	LD A,(BC)
	INC BC
	LD (IX-12+CHP.NNtSkp),A
	JR PD_LP2

PD_ENV	CALL SETENV
	JR PD_LP2

PD_ORN	CALL SETORN
	JR PD_LOOP

PD_ESAM	LD (IX-12+CHP.Env_En),A
	LD (IX-12+CHP.PsInOr),A
	CALL NZ,SETENV
	LD A,(BC)
	INC BC
	JR PD_SAM_

PTDECOD LD A,(IX-12+CHP.Note)
	LD (PrNote+1),A
	LD L,(IX-12+CHP.CrTnSl)
	LD H,(IX-12+CHP.CrTnSl+1)
	LD (PrSlide+1),HL

PD_LOOP	LD DE,#2010
PD_LP2	LD A,(BC)
	INC BC
	ADD A,E
	JR C,PD_OrSm
	ADD A,D
	JR Z,PD_FIN
	JR C,PD_SAM
	ADD A,E
	JR Z,PD_REL
	JR C,PD_VOL
	ADD A,E
	JR Z,PD_EOff
	JR C,PD_SorE
	ADD A,96
	JR C,PD_NOTE
	ADD A,E
	JR C,PD_ORN
	ADD A,D
	JR C,PD_NOIS
	ADD A,E
	JR C,PD_ESAM
	ADD A,A
	LD E,A
	LD HL,SPCCOMS+#FF20-#2000
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	PUSH DE
	JR PD_LOOP

PD_NOIS	LD (Ns_Base),A
	JR PD_LP2

PD_REL	RES 0,(IX-12+CHP.Flags)
	JR PD_RES
	
PD_NOTE	LD (IX-12+CHP.Note),A
	SET 0,(IX-12+CHP.Flags)
	XOR A

PD_RES	LD (PDSP_+1),SP
	LD SP,IX
	LD H,A
	LD L,A
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
PDSP_	LD SP,#3131

PD_FIN	LD A,(IX-12+CHP.NNtSkp)
	LD (IX-12+CHP.NtSkCn),A
	RET

C_PORTM RES 2,(IX-12+CHP.Flags)
	LD A,(BC)
	INC BC
;SKIP PRECALCULATED TONE DELTA (BECAUSE
;CANNOT BE RIGHT AFTER PT3 COMPILATION)
	INC BC
	INC BC
	LD (IX-12+CHP.TnSlDl),A
	LD (IX-12+CHP.TSlCnt),A
	LD DE,NT_
	LD A,(IX-12+CHP.Note)
	LD (IX-12+CHP.SlToNt),A
	ADD A,A
	LD L,A
	LD H,0
	ADD HL,DE
	LD A,(HL)
	INC HL
	LD H,(HL)
	LD L,A
	PUSH HL
PrNote	LD A,#3E
	LD (IX-12+CHP.Note),A
	ADD A,A
	LD L,A
	LD H,0
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	POP HL
	SBC HL,DE
	LD (IX-12+CHP.TnDelt),L
	LD (IX-12+CHP.TnDelt+1),H
	LD E,(IX-12+CHP.CrTnSl)
	LD D,(IX-12+CHP.CrTnSl+1)
Version EQU $+1
	LD A,#3E
	CP 6
	JR C,OLDPRTM ;Old 3xxx for PT v3.5-
PrSlide	LD DE,#1111
	LD (IX-12+CHP.CrTnSl),E
	LD (IX-12+CHP.CrTnSl+1),D
OLDPRTM	LD A,(BC) ;SIGNED TONE STEP
	INC BC
	EX AF,AF'
	LD A,(BC)
	INC BC
	AND A
	JR Z,NOSIG
	EX DE,HL
NOSIG	SBC HL,DE
	JP P,SET_STP
	CPL
	EX AF,AF'
	NEG
	EX AF,AF'
SET_STP	LD (IX-12+CHP.TSlStp+1),A
	EX AF,AF'
	LD (IX-12+CHP.TSlStp),A
	LD (IX-12+CHP.COnOff),0
	RET

C_GLISS	SET 2,(IX-12+CHP.Flags)
	LD A,(BC)
	INC BC
	LD (IX-12+CHP.TnSlDl),A
	AND A
	JR NZ,GL36
	LD A,(Version) ;AlCo PT3.7+
	CP 7
	SBC A,A
	INC A
GL36	LD (IX-12+CHP.TSlCnt),A
	LD A,(BC)
	INC BC
	EX AF,AF'
	LD A,(BC)
	INC BC
	JR SET_STP

C_SMPOS	LD A,(BC)
	INC BC
	LD (IX-12+CHP.PsInSm),A
	RET

C_ORPOS	LD A,(BC)
	INC BC
	LD (IX-12+CHP.PsInOr),A
	RET

C_VIBRT	LD A,(BC)
	INC BC
	LD (IX-12+CHP.OnOffD),A
	LD (IX-12+CHP.COnOff),A
	LD A,(BC)
	INC BC
	LD (IX-12+CHP.OffOnD),A
	XOR A
	LD (IX-12+CHP.TSlCnt),A
	LD (IX-12+CHP.CrTnSl),A
	LD (IX-12+CHP.CrTnSl+1),A
	RET

C_ENGLS	LD A,(BC)
	INC BC
	LD (Env_Del),A
	LD (CurEDel),A
	LD A,(BC)
	INC BC
	LD L,A
	LD A,(BC)
	INC BC
	LD H,A
	LD (ESldAdd),HL
	RET

C_DELAY	LD A,(BC)
	INC BC
	LD (Delay),A
	RET
	
SETENV	LD (IX-12+CHP.Env_En),E
	LD (AYREGS+EnvTp),A
	LD A,(BC)
	INC BC
	LD H,A
	LD A,(BC)
	INC BC
	LD L,A
	LD (EnvBase),HL
	XOR A
	LD (IX-12+CHP.PsInOr),A
	LD (CurEDel),A
	LD H,A
	LD L,A
	LD (CurESld),HL
C_NOP	RET

SETORN	ADD A,A
	LD E,A
	LD D,0
	LD (IX-12+CHP.PsInOr),D
OrnPtrs	EQU $+1
	LD HL,#2121
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
MDADDR2	EQU $+1
	LD HL,#2121
	ADD HL,DE
	LD (IX-12+CHP.OrnPtr),L
	LD (IX-12+CHP.OrnPtr+1),H
	RET

;ALL 16 ADDRESSES TO PROTECT FROM BROKEN PT3 MODULES
SPCCOMS DW C_NOP
	DW C_GLISS
	DW C_PORTM
	DW C_SMPOS
	DW C_ORPOS
	DW C_VIBRT
	DW C_NOP
	DW C_NOP
	DW C_ENGLS
	DW C_DELAY
	DW C_NOP
	DW C_NOP
	DW C_NOP
	DW C_NOP
	DW C_NOP
	DW C_NOP

CHREGS	XOR A
	LD (Ampl),A
	BIT 0,(IX+CHP.Flags)
	PUSH HL
	JP Z,CH_EXIT
	LD (CSP_+1),SP
	LD L,(IX+CHP.OrnPtr)
	LD H,(IX+CHP.OrnPtr+1)
	LD SP,HL
	POP DE
	LD H,A
	LD A,(IX+CHP.PsInOr)
	LD L,A
	ADD HL,SP
	INC A
	CP D
	JR C,CH_ORPS
	LD A,E
CH_ORPS	LD (IX+CHP.PsInOr),A
	LD A,(IX+CHP.Note)
	ADD A,(HL)
	JP P,CH_NTP
	XOR A
CH_NTP	CP 96
	JR C,CH_NOK
	LD A,95
CH_NOK	ADD A,A
	EX AF,AF'
	LD L,(IX+CHP.SamPtr)
	LD H,(IX+CHP.SamPtr+1)
	LD SP,HL
	POP DE
	LD H,0
	LD A,(IX+CHP.PsInSm)
	LD B,A
	ADD A,A
	ADD A,A
	LD L,A
	ADD HL,SP
	LD SP,HL
	LD A,B
	INC A
	CP D
	JR C,CH_SMPS
	LD A,E
CH_SMPS	LD (IX+CHP.PsInSm),A
	POP BC
	POP HL
	LD E,(IX+CHP.TnAcc)
	LD D,(IX+CHP.TnAcc+1)
	ADD HL,DE
	BIT 6,B
	JR Z,CH_NOAC
	LD (IX+CHP.TnAcc),L
	LD (IX+CHP.TnAcc+1),H
CH_NOAC EX DE,HL
	EX AF,AF'
	LD L,A
	LD H,0
	LD SP,NT_
	ADD HL,SP
	LD SP,HL
	POP HL
	ADD HL,DE
	LD E,(IX+CHP.CrTnSl)
	LD D,(IX+CHP.CrTnSl+1)
	ADD HL,DE
CSP_	LD SP,#3131
	EX (SP),HL
	XOR A
	OR (IX+CHP.TSlCnt)
	JR Z,CH_AMP
	DEC (IX+CHP.TSlCnt)
	JR NZ,CH_AMP
	LD A,(IX+CHP.TnSlDl)
	LD (IX+CHP.TSlCnt),A
	LD L,(IX+CHP.TSlStp)
	LD H,(IX+CHP.TSlStp+1)
	LD A,H
	ADD HL,DE
	LD (IX+CHP.CrTnSl),L
	LD (IX+CHP.CrTnSl+1),H
	BIT 2,(IX+CHP.Flags)
	JR NZ,CH_AMP
	LD E,(IX+CHP.TnDelt)
	LD D,(IX+CHP.TnDelt+1)
	AND A
	JR Z,CH_STPP
	EX DE,HL
CH_STPP SBC HL,DE
	JP M,CH_AMP
	LD A,(IX+CHP.SlToNt)
	LD (IX+CHP.Note),A
	XOR A
	LD (IX+CHP.TSlCnt),A
	LD (IX+CHP.CrTnSl),A
	LD (IX+CHP.CrTnSl+1),A
CH_AMP	LD A,(IX+CHP.CrAmSl)
	BIT 7,C
	JR Z,CH_NOAM
	BIT 6,C
	JR Z,CH_AMIN
	CP 15
	JR Z,CH_NOAM
	INC A
	JR CH_SVAM
CH_AMIN	CP -15
	JR Z,CH_NOAM
	DEC A
CH_SVAM	LD (IX+CHP.CrAmSl),A
CH_NOAM	LD L,A
	LD A,B
	AND 15
	ADD A,L
	JP P,CH_APOS
	XOR A
CH_APOS	CP 16
	JR C,CH_VOL
	LD A,15
CH_VOL	OR (IX+CHP.Volume)
	LD L,A
	LD H,0
	LD DE,VT_
	ADD HL,DE
	LD A,(HL)
CH_ENV	BIT 0,C
	JR NZ,CH_NOEN
	OR (IX+CHP.Env_En)
CH_NOEN	LD (Ampl),A
	BIT 7,B
	LD A,C
	JR Z,NO_ENSL
	RLA
	RLA
	SRA A
	SRA A
	SRA A
	ADD A,(IX+CHP.CrEnSl) ;SEE COMMENT BELOW
	BIT 5,B
	JR Z,NO_ENAC
	LD (IX+CHP.CrEnSl),A
NO_ENAC	LD HL,AddToEn
	ADD A,(HL) ;BUG IN PT3 - NEED WORD HERE.
		   ;FIX IT IN NEXT VERSION?
	LD (HL),A
	JR CH_MIX
NO_ENSL RRA
	ADD A,(IX+CHP.CrNsSl)
	LD (AddToNs),A
	BIT 5,B
	JR Z,CH_MIX
	LD (IX+CHP.CrNsSl),A
CH_MIX	LD A,B
	RRA
	AND #48
CH_EXIT	LD HL,AYREGS+Mixer
	OR (HL)
	RRCA
	LD (HL),A
	POP HL
	XOR A
	OR (IX+CHP.COnOff)
	RET Z
	DEC (IX+CHP.COnOff)
	RET NZ
	XOR (IX+CHP.Flags)
	LD (IX+CHP.Flags),A
	RRA
	LD A,(IX+CHP.OnOffD)
	JR C,CH_ONDL
	LD A,(IX+CHP.OffOnD)
CH_ONDL	LD (IX+CHP.COnOff),A
	RET

PLAY    XOR A
	LD (AddToEn),A
	LD (AYREGS+Mixer),A
	DEC A
	LD (AYREGS+EnvTp),A
	LD HL,DelyCnt
	DEC (HL)
	JR NZ,PL2
	LD HL,ChanA+CHP.NtSkCn
	DEC (HL)
	JR NZ,PL1B
AdInPtA	EQU $+1
	LD BC,#0101
	LD A,(BC)
	AND A
	JR NZ,PL1A
	LD D,A
	LD (Ns_Base),A
	LD HL,(CrPsPtr)
	INC HL
	LD A,(HL)
	INC A
	JR NZ,PLNLP
	CALL CHECKLP
LPosPtr	EQU $+1
	LD HL,#2121
	LD A,(HL)
	INC A
PLNLP	LD (CrPsPtr),HL
	DEC A
	ADD A,A
	LD E,A
	RL D
PatsPtr	EQU $+1
	LD HL,#2121
	ADD HL,DE
	LD DE,(MODADDR)
	LD (PSP_+1),SP
	LD SP,HL
	POP HL
	ADD HL,DE
	LD B,H
	LD C,L
	POP HL
	ADD HL,DE
	LD (AdInPtB),HL
	POP HL
	ADD HL,DE
	LD (AdInPtC),HL
PSP_	LD SP,#3131
PL1A	LD IX,ChanA+12
	CALL PTDECOD
	LD (AdInPtA),BC

PL1B	LD HL,ChanB+CHP.NtSkCn
	DEC (HL)
	JR NZ,PL1C
	LD IX,ChanB+12
AdInPtB	EQU $+1
	LD BC,#0101
	CALL PTDECOD
	LD (AdInPtB),BC

PL1C	LD HL,ChanC+CHP.NtSkCn
	DEC (HL)
	JR NZ,PL1D
	LD IX,ChanC+12
AdInPtC	EQU $+1
	LD BC,#0101
	CALL PTDECOD
	LD (AdInPtC),BC

Delay	EQU $+1
PL1D	LD A,#3E
	LD (DelyCnt),A

PL2	LD IX,ChanA
	LD HL,(AYREGS+TonA)
	CALL CHREGS
	LD (AYREGS+TonA),HL
	LD A,(Ampl)
	LD (AYREGS+AmplA),A
	LD IX,ChanB
	LD HL,(AYREGS+TonB)
	CALL CHREGS
	LD (AYREGS+TonB),HL
	LD A,(Ampl)
	LD (AYREGS+AmplB),A
	LD IX,ChanC
	LD HL,(AYREGS+TonC)
	CALL CHREGS
;	LD A,(Ampl) ;Ampl = AYREGS+AmplC
;	LD (AYREGS+AmplC),A
	LD (AYREGS+TonC),HL

	LD HL,(Ns_Base_AddToNs)
	LD A,H
	ADD A,L
	LD (AYREGS+Noise),A

AddToEn EQU $+1
	LD A,#3E
	LD E,A
	ADD A,A
	SBC A,A
	LD D,A
	LD HL,(EnvBase)
	ADD HL,DE
	LD DE,(CurESld)
	ADD HL,DE
	LD (AYREGS+Env),HL

	XOR A
	LD HL,CurEDel
	OR (HL)
	JR Z,ROUT_A0
	DEC (HL)
	JR NZ,ROUT
Env_Del	EQU $+1
	LD A,#3E
	LD (HL),A
ESldAdd	EQU $+1
	LD HL,#2121
	ADD HL,DE
	LD (CurESld),HL

ROUT	XOR A
ROUT_A0	LD DE,#FFBF
	LD BC,#FFFD
	LD HL,AYREGS
LOUT	OUT (C),A
	LD B,E
	OUTI 
	LD B,D
	INC A
	CP 13
	JR NZ,LOUT
	OUT (C),A
	LD A,(HL)
	AND A
	RET M
	LD B,E
	OUT (C),A
	RET

NT_DATA	DB (T_NEW_0-T1_)*2
	DB TCNEW_0-T_
	DB (T_OLD_0-T1_)*2+1
	DB TCOLD_0-T_
	DB (T_NEW_1-T1_)*2+1
	DB TCNEW_1-T_
	DB (T_OLD_1-T1_)*2+1
	DB TCOLD_1-T_
	DB (T_NEW_2-T1_)*2
	DB TCNEW_2-T_
	DB (T_OLD_2-T1_)*2
	DB TCOLD_2-T_
	DB (T_NEW_3-T1_)*2
	DB TCNEW_3-T_
	DB (T_OLD_3-T1_)*2
	DB TCOLD_3-T_

T_

TCOLD_0	DB #00+1,#04+1,#08+1,#0A+1,#0C+1,#0E+1,#12+1,#14+1
	DB #18+1,#24+1,#3C+1,0
TCOLD_1	DB #5C+1,0
TCOLD_2	DB #30+1,#36+1,#4C+1,#52+1,#5E+1,#70+1,#82,#8C,#9C
	DB #9E,#A0,#A6,#A8,#AA,#AC,#AE,#AE,0
TCNEW_3	DB #56+1
TCOLD_3	DB #1E+1,#22+1,#24+1,#28+1,#2C+1,#2E+1,#32+1,#BE+1,0
TCNEW_0	DB #1C+1,#20+1,#22+1,#26+1,#2A+1,#2C+1,#30+1,#54+1
	DB #BC+1,#BE+1,0
TCNEW_1 EQU TCOLD_1
TCNEW_2	DB #1A+1,#20+1,#24+1,#28+1,#2A+1,#3A+1,#4C+1,#5E+1
	DB #BA+1,#BC+1,#BE+1,0

EMPTYSAMORN EQU $-1
	DB 1,0,#90 ;delete #90 if you don't need default sample

;first 12 values of tone tables (packed)

T_PACK	DB #06EC*2/256,#06EC*2
	DB #0755-#06EC
	DB #07C5-#0755
	DB #083B-#07C5
	DB #08B8-#083B
	DB #093D-#08B8
	DB #09CA-#093D
	DB #0A5F-#09CA
	DB #0AFC-#0A5F
	DB #0BA4-#0AFC
	DB #0C55-#0BA4
	DB #0D10-#0C55
	DB #066D*2/256,#066D*2
	DB #06CF-#066D
	DB #0737-#06CF
	DB #07A4-#0737
	DB #0819-#07A4
	DB #0894-#0819
	DB #0917-#0894
	DB #09A1-#0917
	DB #0A33-#09A1
	DB #0ACF-#0A33
	DB #0B73-#0ACF
	DB #0C22-#0B73
	DB #0CDA-#0C22
	DB #0704*2/256,#0704*2
	DB #076E-#0704
	DB #07E0-#076E
	DB #0858-#07E0
	DB #08D6-#0858
	DB #095C-#08D6
	DB #09EC-#095C
	DB #0A82-#09EC
	DB #0B22-#0A82
	DB #0BCC-#0B22
	DB #0C80-#0BCC
	DB #0D3E-#0C80
	DB #07E0*2/256,#07E0*2
	DB #0858-#07E0
	DB #08E0-#0858
	DB #0960-#08E0
	DB #09F0-#0960
	DB #0A88-#09F0
	DB #0B28-#0A88
	DB #0BD8-#0B28
	DB #0C80-#0BD8
	DB #0D60-#0C80
	DB #0E10-#0D60
	DB #0EF8-#0E10

;vars from here can be stripped
;you can move VARS to any other address

VARS

;ChannelsVars
	STRUCT	CHP
;reset group
PsInOr	DB 0
PsInSm	DB 0
CrAmSl	DB 0
CrNsSl	DB 0
CrEnSl	DB 0
TSlCnt	DB 0
CrTnSl	DW 0
TnAcc	DW 0
COnOff	DB 0
;reset group

OnOffD	DB 0

;IX for PTDECOD here (+12)
OffOnD	DB 0
OrnPtr	DW 0
SamPtr	DW 0
NNtSkp	DB 0
Note	DB 0
SlToNt	DB 0
Env_En	DB 0
Flags	DB 0
 ;Enabled - 0,SimpleGliss - 2
TnSlDl	DB 0
TSlStp	DW 0
TnDelt	DW 0
NtSkCn	DB 0
Volume	DB 0
	ENDS

ChanA	DS CHP
ChanB	DS CHP
ChanC	DS CHP

;GlobalVars
DelyCnt	DB 0
CurESld	DW 0
CurEDel	DB 0
Ns_Base_AddToNs
Ns_Base	DB 0
AddToNs	DB 0

AYREGS

VT_	DS 256 ;CreatedVolumeTableAddress

EnvBase	EQU VT_+14

T1_	EQU VT_+16 ;Tone tables data depacked here

T_OLD_1	EQU T1_
T_OLD_2	EQU T_OLD_1+24
T_OLD_3	EQU T_OLD_2+24
T_OLD_0	EQU T_OLD_3+2
T_NEW_0	EQU T_OLD_0
T_NEW_1	EQU T_OLD_1
T_NEW_2	EQU T_NEW_0+24
T_NEW_3	EQU T_OLD_3

NT_	DS 192 ;CreatedNoteTableAddress

;local var
Ampl	EQU AYREGS+AmplC

VAR0END	EQU VT_+16 ;INIT zeroes from VARS to VAR0END-1

VARSEND EQU $

MDLADDR EQU $

;Release 0 steps:
;11.Sep.2004 - Note tables creator
;12.Sep.2004 - Volume tables creator; INIT subroutine
;13.Sep.2004 - Play counters, position counters
;14.Sep.2004 - Patterns decoder subroutine
;15.Sep.2004 - Resting (no code)
;16.Sep.2004 - CHREGS subroutine; global debugging; 1st stable
;version was born
;17.Sep.2004 - Debugging and optimization. First release!
;Release 1 steps:
;20.Sep.2004 - local vars moved to code (selfmodified code
;smaller and faster)
;22.Sep.2004 - added mute sound entry at START+8; position
;pointer moved to START+11; added setup and status byte at
;START+10 noloop mode and loop passed flags added
;Release 2 steps:
;28.Sep.2004 - Optimization: code around CHREGS's volume and
;vibrato faster now; zeroing PD_RES through stack; Ton and Ampl
;moved from channel vars to global ones; first position selector
;removed from INIT; optimization for packers(Ivan Roshin method)
;Release 3 steps:
;2.Oct.2004 - optimization in INIT and PD_LOOP (thanks to Ivan
;Roshin)
;4.Oct.2004 - load delay from (hl) in INIT (2 bytes shorter)
;5.Oct.2004 - optimization in PD_LOOP (->PD_LP2)
;7.Oct.2004 - swaping some commands for better packing
;Release 4 steps:
;9.Oct.2004 - optimization around LD HL,SPCCOMS (thanks to Ivan
;Roshin); in PTDECOD swapped BC and DE to optimize C_PORTM;
;removed sam and orn len and loop channel vars; CHREGS totally
;optimized
;Release 5 steps:
;11.Oct.2004 - PD_OrSm and C_PORTM optimized; Ivan Roshin's
;volume tables creator algorithm (51 bytes shorter than mine)
;12.Oct.2004 - Ivan Roshin's note tables creator algorithm (74
;bytes shorter than mine)
;Release 6 steps:
;14.Oct.2004 - loop and next position calculations moved to INIT
;15.Oct.2004 - AdInPt moved to code
;19.Oct.2004 - Env_Del moved to code
;20.Oct.2004 - Version PUSH and POP (1 byte shorter, thanks to
;Ivan Roshin)
;22.Oct.2004 - Env_En moved from Flags' bit to byte (shorter and
;faster code)
;25.Oct.2004 - SETENV optimized
;29.Oct.2004 - Optimized around AddToEn (SBC A,A, thanks to Ivan
;Roshin)
;3.Nov.2004 - Note tables data was compressed; with depacker it
;is 9 bytes shorter than uncompressed (thanks to Ivan Roshin)
;4.Nov.2004 - default sample and ornament both are fixed now
;and placed into code block (6 bytes shorter)
;7.Nov.2004 - LD A,(Ns_Base):LD L,A changed to LD HL,(Ns_Base)
;(thanks to Dima Bystrov)
;9.Nov.2004 - Ns_Base and AddToNs are merged to Ns_Base_AddToNs;
;LD A,255 changed to DEC A (at start of PLAY); added ROUT_A0
;12.Nov.2004 - NtSkCn&Volume are merged (8 bytes smaller init);
;LD BC,T1_ changed to PUSH DE...POP BC in note table creator
;19.Dec.2004 - NT_DATA reorganized (6 bytes shorter, thanks to
;Ivan Roshin); C_PORTM and C_GLISS are merged via SET_STP (48
;tacts slower, but 8 bytes smaller, thanks to Ivan Roshin)
;Release 7 steps:
;29.Apr.2007 - SjAsm adaptation; new 1.xx and 2.xx
;interpretation for PT 3.7+.

;Tests in IMMATION TESTER V1.0 by Andy Man/POS (thanks to
;Himik's ZxZ for help):
;Module name/author	Min tacts	Max tacts	Average
;Spleen/Nik-O		1720		9256		5500
;Chuta/Miguel		1720		9496		5500
;Zhara/Macros		4536		8744		5500

;Size:
;Code block #651 bytes
;Variables #21D bytes (can be stripped)
;Size in RAM #651+#21D=#86E (2158) bytes

;Notes:
;Pro Tracker 3.4r can not be detected by header, so PT3.4r tone
;tables really used only for modules of 3.3 and older versions.
