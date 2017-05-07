*=======================================================================*
*									*
*						  TM			*
*		      A r c a d e   F a c t o r y			*
*		     -----------------------------			*
*			(C)-94 Digital Fiction.				*
*									*
*			     FACTORY CODE				*
*									*
*			       Version I				*
*									*
*		       Last update: 17:30 9/9-94			*
*									*
*		All programming by Richard Glenn Nielsen.		*
*									*
*=======================================================================*
;A1200 SaveFloppy, 2MbChip, 50buffers:	1:27
;A1200 Assemble, 2MbChip:		0:23
;A1200 Assemble, 68060 8Mb fast:	0:01
WB=0
*---------------
Start:		Lea	StartSP(pc),a0		;Save Stack Pointer
		Move.l	a7,(a0)			;+
		If WB=1
		Bsr.w	Init_Task
		EndIf
		Bsr.w	Prepare_Libs
		Bsr.w	Ask_Aga
		Bsr.w	Ask_Filter
		Jsr	Prepare_Fonts	;###
		Bsr.w	Prepare_Memory
		Bsr.w	Prepare_Screen
		Bsr.w	Ask_Devices
		Bsr.w	Keyboard_Init
		Lea	GameLay,a5	;###
		Jsr	Open_Layer	;###
*---------------
Main_Loop:	Bsr.w	Bob_Mouse_Piece
		Bsr.w	Choose_Pointer
		Bsr.w	Pict_Cross
		Bsr.w	Piec_Pixel
		Bsr.w	Update_Title
		Bsr.w	Maybe_Dir
		Bsr.w	Gadgets
		Bra.b	Main_Loop
*---------------
End:		Jsr	Modl_Stop
		Bsr.w	Close_File
		Bsr.w	Keyboard_Exit
		Bsr.w	Free_Layers
		Bsr.w	Free_Screen
		Bsr.w	Free_All_Lists
		Bsr.w	Free_Memories
		Jsr	Free_Fonts	;###
		Bsr.w	Free_Libs
		Bsr.w	Free_Dir
		If WB=1
		Bsr.w	End_Task
		EndIf
		Move.l	StartSP(pc),a7
		Move.l	ReturnCode(pc),d0	;Set ReturnCode
Quit:		Rts
StartSP:	Dc.l	0
ReturnCode:	Dc.l	0
*---------------
		Dc.b	'$VER: Arcade Factory 1.0 (25.10.94)',0

Pict_RP:	Blk.b	100,0
Pict_BM:	Dc	40
		Dc	256
		Dc.b	0
		Dc.b	5
		Dc	0
		Blk.l	8,0

PathName:	Blk.b	64,0
FileName:	Blk.b	32,0
		Cnop	0,4
InfoBlock:	Blk.b	260,0

SelN01:		Blk.b	32,0
SelN02:		Blk.b	32,0
SelN03:		Blk.b	32,0
SelN04:		Blk.b	32,0
SelN05:		Blk.b	32,0
SelN06:		Blk.b	32,0
SelN07:		Blk.b	32,0
SelN08:		Blk.b	32,0
SelN09:		Blk.b	32,0
SelN10:		Blk.b	32,0

VHdrBuf:	Blk.b	20,0
DataBuf:	Blk.b	32,0
LoadBuf:	Blk.b	12,0
Comm_FileName:	Blk.b	128,0
*=======================================================================*
*			     P I C T U R E				*
*=======================================================================*
Pict_Picture:	Lea	GPictAutoClip(pc),a0
		Btst	#0,4(a0)
		Bne.w	Pict_AutoClip
		Lea	GPictManuClip(pc),a0
		Btst	#0,4(a0)
		Bne.w	Pict_ManuClip
		;Lea	GPictPolyClip(pc),a0
		;Btst	#0,4(a0)
		;Bne.b	Pict_PolyClip
		Rts
*---------------
Pict_ClrMode:	Clr	PMC_Mod
		Rts
*---------------
Upd_PiecNameD:	Lea	Piec_Info,a3		;###
		Lea	Piec_NameUpd(pc),a4
		Jmp	Upd_UnitNameD		;###
*---------------
;Pict_PolyClip:	;Move	#$0f0,$dff180
;		Rts
*---------------
Pict_FullClip:	Bsr.b	Pict_ClrMode
		Lea	Pict_BM(pc),a3		;Any Picture there?
		Tst.l	8(a3)			;+
		Beq.b	PF_End			;+
		Lea	Sprite_Busy(pc),a1
		Bsr.w	Change_Sprite
		Clr	d4			;X Counter
		Clr	d5			;Y Counter

	PF_Loop:Lea	Pict_BM(pc),a0
		Move	d4,d0
		Move	d5,d1
		Bsr.w	Test_Pixel
		Beq.b	PF_Next

		Move	d4,d0
		Move	d5,d1
		Bsr.w	Ask_Clip_List
		Beq.b	PF_Scan
		Move	4(a0),d4		;Skip to end of clip
		Bra.b	PF_Next

	PF_Scan:Bsr.w	Scan_Piece
		Move	SX2(pc),d4

	PF_Next:Addq	#1,d4
		Cmp	Pict_SizeX(pc),d4
		Blo.b	PF_Loop
		Clr	d4
		Addq	#1,d5
		Cmp	Pict_SizeY(pc),d5
		Blo.b	PF_Loop
	PF_End:	Rts
*---------------
Pict_Store:	Clr	PS_Flag
		Bra.b	Store_Pieces
*---------------
Pict_StoreClr:	Move	#1,PS_Flag
Store_Pieces:	Move.l	Mem_Clip,a2	;###
		Move	#4096/8,PS_Cnt
	PS_Loop:Tst	(a2)
		Bmi.w	PS_Next
	*-- Store Piece
		Bsr.w	Store_Piece
		Bne.w	PS_Fail
	*-- Draw XOR box
		Move	(a2),SX1
		Move	02(a2),SY1
		Move	04(a2),SX2
		Move	06(a2),SY2
		Bsr.w	DrawBox
	*-- Clear Piece?
		Move	PS_Flag(pc),d0
		Beq.b	PS_NClr
	*-- Clear Piece from Screen
		Lea	PictLay,a5	;###
		Move.l	GfxBase,a6	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetAPen(a6)
		Lea	Pict_Gfx(pc),a4
		Move	(a2),d0
		Move	02(a2),d1
		Move	04(a2),d2
		Move	06(a2),d3
		Move	PictOffsX(pc),d7
		Sub	d7,d0
		Sub	d7,d2
		Move	PictOffsY(pc),d7
		Sub	d7,d1
		Sub	d7,d3
		Move.l	a2,-(a7)
		Bsr.w	ZBox
		Move.l	(a7)+,a2
	*-- Clear Piece from Picture
		Move.l	GfxBase,a6	;###
		Lea	Pict_RP(pc),a3
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	(a2),d0
		Move	02(a2),d1
		Move	04(a2),d2
		Move	06(a2),d3
		Jsr	RectFill(a6)

	PS_NClr:Move	#-1,(a2)	;Clear this entry in cliplist
	PS_Next:Addq	#8,a2
		Subq	#1,PS_Cnt
		Bne.w	PS_Loop
	PS_Fail:Rts
	PS_Flag:Dc	0	;Clear-flag
	PS_Cnt:	Dc	0	;ClipListCounter
*---------------
Pict_Zoom:	Lea	GPictZoom(pc),a4
		Btst	#0,4(a4)
		Beq.b	PZ_End
		Bra.b	Update_Zoom

	PZ_End:	Clr	UnDraw
		Move	#1,DrawRes
		Bsr.w	Pict_Update
		Lea	Pict_PictUpd(pc),a4
		Lea	PictLay,a5	;###
		Moveq.l	#11,d7
		Jmp	Draw_Some	;###
*---------------
Update_Zoom:	Clr	UnDraw
		Move	Pict_ZFact(pc),DrawRes
		Lea	Pict_PictUpd(pc),a4
		Lea	PictLay,a5	;###
		Moveq.l	#11,d7
		Jmp	Draw_Some	;###
*---------------
Pict_ZoomFactor:Move.l	Convert_Value,d0	;###
		Cmp	#2,d0
		Blt.b	PZF_End
		Cmp	#9,d0
		Bgt.b	PZF_End
		Move	d0,Pict_ZFact
	PZF_End:Bra.b	PM_TUpd
*---------------
Pict_ZoomPlus:	Cmp	#9,Pict_ZFact
		Beq.b	PM_End
		Addq	#1,Pict_ZFact
		Bra.b	PM_TUpd
*---------------
Pict_ZoomMinus:	Cmp	#2,Pict_ZFact
		Beq.b	PM_End
		Subq	#1,Pict_ZFact

	PM_TUpd:Move	Pict_ZFact(pc),d0
		Lea	Pict_ZFactT+1(pc),a0
		Moveq.l	#0,d7
		Jsr	Conv		;###
		Lea	GPictZoom(pc),a4
		Btst	#0,4(a4)
		Beq.b	PM_Not
		Bsr.b	Update_Zoom
	PM_Not:	Lea	PictLay,a5	;###
		Lea	Pict_ZFactUpd(pc),a4
		Moveq.l	#1,d7
		Jsr	Draw_Some	;###
	PM_End:	Rts
Pict_ZFact:	Dc	2
*---------------
Pict_ClrClips:	Bsr.w	Clr_Clip_List
		Lea	Pict_PictUpd(pc),a4
		Lea	PictLay,a5	;###
		Moveq.l	#5,d7
		Jmp	Draw_Some	;###
*---------------
Pict_OffsetX:
Pict_OffsetY:	Bsr.w	Pict_Update
		Bsr.w	Update_Picture
		Bra.w	Draw_All_Clips
*---------------
Scan_Piece:	;(D0=X,D1=Y)
		Move	d0,SX1
		Move	d0,SX2
		Move	d1,SY1
		Move	d1,SY2
		Lea	Pict_BM(pc),a3

		Move.l	a3,a0
		Move	SX1(pc),d0
		Move	SY1(pc),d1
		Bsr.w	Test_Pixel
		Beq.w	SP_None

	SP_Next:Clr.b	SFlag
		Subq	#1,SX1
		Bpl.b	SP_X1Ok
		Clr	SX1
		Bset	#0,SFlag
	SP_X1Ok:Subq	#1,SY1
		Bpl.b	SP_Y1Ok
		Clr	SY1
		Bset	#1,SFlag
	SP_Y1Ok:Addq	#1,SX2
		Move	Pict_SizeX(pc),d0
		Cmp	SX2(pc),d0
		Bgt.b	SP_X2Ok
		Subq	#1,d0
		Move	d0,SX2
		Bset	#2,SFlag
	SP_X2Ok:Addq	#1,SY2
		Move	Pict_SizeY(pc),d0
		Cmp	SY2(pc),d0
		Bgt.b	SP_Y2Ok
		Subq	#1,d0
		Move	d0,SY2
		Bset	#3,SFlag
	SP_Y2Ok:
	*-- Scan top line
		Move	SX1(pc),d3
	SP_LpT:	Move	d3,d0
		Move	SY1(pc),d1
		Move.l	a3,a0
		Bsr.w	Test_Pixel
		Bne.b	SP_NClT
		Addq	#1,d3
		Cmp	SX2(pc),d3
		Ble.b	SP_LpT
		Addq	#1,SY1
		Bset	#1,SFlag
	SP_NClT:
	*-- Scan bottom line
		Move	SX1(pc),d3
	SP_LpB:	Move	d3,d0
		Move	SY2(pc),d1
		Move.l	a3,a0
		Bsr.w	Test_Pixel
		Bne.b	SP_NClB
		Addq	#1,d3
		Cmp	SX2(pc),d3
		Ble.b	SP_LpB
		Subq	#1,SY2
		Bset	#3,SFlag
	SP_NClB:
	*-- Scan right line
		Move	SY1(pc),d3
	SP_LpR:	Move	SX2(pc),d0
		Move	d3,d1
		Move.l	a3,a0
		Bsr.b	Test_Pixel
		Bne.b	SP_NClR
		Addq	#1,d3
		Cmp	SY2(pc),d3
		Ble.b	SP_LpR
		Subq	#1,SX2
		Bset	#2,SFlag
	SP_NClR:
	*-- Scan left line
		Move	SY1(pc),d3	;Set counter
	SP_LpL:	Move	SX1(pc),d0	;X
		Move	d3,d1		;Y
		Move.l	a3,a0		;Bitmap
		Bsr.b	Test_Pixel	;Read Pixel
		Bne.b	SP_NClL		;If not 0, end scan
		Addq	#1,d3		;Add pixel coordinate
		Cmp	SY2(pc),d3	;Finished?
		Ble.b	SP_LpL		;No
		Addq	#1,SX1		;All clear, shrink box
		Bset	#0,SFlag
	SP_NClL:
		Cmp.b	#$f,SFlag	;All 4 sides clear?
		Bne.w	SP_Next		;No

		Bsr.b	Find_CL_Space
		Move.l	a0,d0
		Beq.b	SP_None
		Move.l	a0,-(a7)
		Bsr.w	DrawBox
		Move.l	(a7)+,a0
		Move	SX1(pc),(a0)+
		Move	SY1(pc),(a0)+
		Move	SX2(pc),(a0)+
		Move	SY2(pc),(a0)
	SP_None:Rts
*---------------
Test_Pixel:	;(D0=X, D1=Y, A0=Bitmap Struct, D0->Result)
		Mulu	(a0),d1		;BytesPerRow * Y
		Move	d0,d2		;Copy X
		Lsr	#3,d0		;X / 8
		Ext.l	d0		;Extend to longword
		Add.l	d0,d1		;Y=Y+X
		Not	d2		;Bit #
		Move.b	5(a0),d0	;Depth
		Addq	#8,a0		;Prepare to read plane addresses
	TP_Lp:	Move.l	(a0)+,a1	;Get plane address
		Btst	d2,0(a1,d1.l)	;Test bit
		Bne.b	TP_1		;Was it 1?
		Subq.b	#1,d0		;Next plane
		Bne.b	TP_Lp		;Finished?
		;Moveq.l	#0,d0	;Clear Result
		;Rts			;End
	TP_1:	;Moveq.l	#1,d0	;Set Result
		Rts			;End
SFlag:		Dc	0
SX1:		Dc	0
SY1:		Dc	0
SX2:		Dc	0
SY2:		Dc	0
*---------------
Find_CL_Space:	;(A0->Address)
		Move.l	Mem_Clip,a0	;###
		Move	#4096/8-1,d0
	FCLS_Lp:Tst	(a0)
		Bmi.b	FCLS_Ok
		Addq	#8,a0
		Dbf	d0,FCLS_Lp
		Sub.l	a0,a0
	FCLS_Ok:Rts
*---------------
Clr_Clip_List:	Move.l	Mem_Clip,a0	;###
		Move	#4096/4-1,d0
	CCL_Lp:	Move.l	#-1,(a0)+
		Dbf	d0,CCL_Lp
		Rts
*---------------
Ask_Clip_List:	;(D0=PictX, D1=PictY, A0->Address, D7->Flag)
		Move.l	Mem_Clip,a0	;###
		Move	#4096/8-1,d6
	ACL_Lp:	Cmp	(a0),d0
		Blo.b	ACL_Nxt
		Cmp	02(a0),d1
		Blo.b	ACL_Nxt
		Cmp	04(a0),d0
		Bhi.b	ACL_Nxt
		Cmp	06(a0),d1
		Bhi.b	ACL_Nxt
		Bra.b	ACL_Ok
	ACL_Nxt:Addq	#8,a0
		Dbf	d6,ACL_Lp
		Clr.l	d7
		Rts
	ACL_Ok:	Moveq.l	#-1,d7
		Rts
*---------------
Store_Piece:	;(A2=ClipListAddress)
	*-- Calculate SizeX,SizeY,BytWidth,BytSize
		Clr.l	d0
		Move	04(a2),d0	;X2
		Move	(a2),d1		;X1
		Sub	d1,d0
		Addq	#1,d0
		Move	d0,SP_SizeX
		Move	d0,d1
		And	#$f,d1
		Beq.b	SP_NRem		;No remainder
		Add	#$10,d0
		And	#$fff0,d0
	SP_NRem:Lsr	#3,d0		;Divide by 8 (8bits/byte)
		Move	d0,SP_BytWidth
		Clr.l	d1
		Move	06(a2),d1	;Y2
		Move	02(a2),d2	;Y1
		Sub	d2,d1
		Addq	#1,d1
		Move	d1,SP_SizeY
		Mulu	d1,d0		;SizeY * SizeX
		Move	d0,SP_PlaneSize
		Move	Pict_Depth(pc),d6	;Get Depth
		Addq	#2,d6		;Add 2 planes for masks
		Mulu	d6,d0		;Multiply it
		Add	#28,d0		;Header
		Move.l	d0,SP_BytSize
		Move	SP_SizeY(pc),d6
		Lsl	#6,d6
		Move	SP_BytWidth(pc),d0
		Lsr	#1,d0
		Addq	#1,d0
		Or	d0,d6
		Move	d6,SP_BltSize

		Lea	PiecList,a4	;###
		Jsr	Find_Unit_Space	;###
		Move.l	a0,Piec_ListAdr
		Bne.b	SP_NEr1
		Jmp	Mess_MemErr	;###
	SP_NEr1:Move	d7,Cur_Piec
	*-- Allocate memory.
		Clr.l	d0
		Move.l	SP_BytSize(pc),d0
		Move.l	#$10002,d1		;ChipMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,SP_Address
		Bne.b	SP_NEr2
		Jmp	Mess_CMemErr
	SP_NEr2:Move.l	Piec_ListAdr(pc),a0
		Move.l	SP_Address(pc),(a0)
		Move	#%111,4(a0)		;Set Flags = New
		Move	#1,6(a0)		;Clear Path	$$$
		Bsr.w	Unnamed
	*-- Store piece header data
		Move.l	(a0),a1			;Get Piece Address
		Clr	(a1)+			;Write Id
		Move.l	SP_BytSize(pc),(a1)+	;Write BytSize
		Move	SP_SizeX(pc),(a1)+	;Write SizeX
		Move	SP_SizeY(pc),(a1)+	;Write SizeY
		Move	Pict_Depth(pc),(a1)+	;Write Depth		
		Move	SP_PlaneSize(pc),(a1)+	;Write PlaneSize
		Move	SP_BytWidth(pc),(a1)+	;Write ByteWidth
		Move	SP_BltSize(pc),(a1)+	;Write BltSize
		Move	#$8000,(a1)+		;Write Flags
		Move.l	SP_BytSize(pc),a0
		Sub	SP_PlaneSize(pc),a0
		Sub	SP_PlaneSize(pc),a0
		Move.l	a0,(a1)+		;Write CollMaskOffset
		Add	SP_PlaneSize(pc),a0
		Move.l	a0,(a1)+		;Write BlitMaskOffset
	*-- Store piece bitmap data
		Lea	Piec_BM(pc),a0
		Move	SP_BytWidth(pc),(a0)
		Move	SP_SizeY(pc),02(a0)
		Move	Pict_Depth(pc),d7
		Move.b	d7,05(a0)
		Move.l	SP_Address(pc),a1
		Add	#28,a1
		Move	SP_PlaneSize(pc),d0
		Addq.l	#8,a0
		Move	Pict_Depth(pc),d1
	SP_BmLp:Move.l	a1,(a0)+
		Add	d0,a1
		Subq	#1,d1
		Bne.b	SP_BmLp

		Move.l	GfxBase,a6	;###
		Lea	Piec_RP(pc),a1
		Jsr	InitRastPort(a6)
		Lea	Piec_BM(pc),a0
		Lea	Piec_RP(pc),a1
		Move.l	a0,4(a1)

		Lea	Pict_BM(pc),a0	;SrcBM
		Move	(a2),d0		;SrcX
		Move	02(a2),d1	;SrcY
		Lea	Piec_RP(pc),a1	;DestRP
		Clr.l	d2		;DestX
		Clr.l	d3		;DestY
		Move	SP_SizeX(pc),d4	;SizeX
		Move	SP_SizeY(pc),d5	;SizeY
		Move	#$c0,d6		;Minterm
		Move.l	GfxBase,a6	;###
		Jsr	BltBitMapRastPort(a6)
	*-- Calculate masks
		Movem.l	d0-d7/a0-a6,-(a7)
		Moveq.l	#1,d2
		Bsr.w	Calc_Mask
		Moveq.l	#2,d2
		Bsr.w	Calc_Mask
		Movem.l	(a7)+,d0-d7/a0-a6
	*-- Show piece in piece window if opened
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Change_Piec
		Movem.l	(a7)+,d0-d7/a0-a6
	SP_End:	Clr.l	d7
		Rts

SP_Id:		Dc	0
SP_BytSize:	Dc.l	0
SP_SizeX:	Dc	0
SP_SizeY:	Dc	0
SP_Depth:	Dc	0
SP_Address:	Dc.l	0
SP_BytWidth:	Dc	0
SP_PlaneSize:	Dc	0
SP_BltSize:	Dc	0
Piec_ListAdr:	Dc.l	0
*---------------
Pict_ManuClip:	Lea	Pict_BM(pc),a0
		Tst.l	8(a0)		;Any Picture?
		Beq.w	PMC_End

		Move	ClipX(pc),d0
		Move	ClipY(pc),d1

		Tst	PMC_Mod
		Bne.b	PMC_Md2

		Move	d0,PMC_X1
		Move	d1,PMC_Y1

		Move	ClipX(pc),ClipX1
		Move	ClipY(pc),ClipY1
		Bsr.w	Draw_Cross

		Clr	UnDraw
		Eor	#1,PMC_Mod

		Move	ClipX(pc),d0
		Move	ClipY(pc),d1
		Bsr.w	Ask_Clip_List
		Beq.b	PMC_NEx
		Move	(a0),SX1
		Move	#-1,(a0)+
		Move	(a0)+,SY1
		Move	(a0)+,SX2
		Move	(a0),SY2
		Bsr.w	DrawBox
		Clr	PMC_Mod
		Bra.b	PMC_End
	PMC_NEx:Rts

	PMC_Md2:Move	d0,PMC_X2
		Move	d1,PMC_Y2

		Clr	UnDraw
		Eor	#1,PMC_Mod

		Bsr.w	Find_CL_Space
		Move.l	a0,d0
		Beq.b	PMC_End

		Move	PMC_X1(pc),d0
		Cmp	PMC_X2(pc),d0
		Ble.b	PMC_XOk
		Move	PMC_X2(pc),PMC_X1
		Move	d0,PMC_X2
	PMC_XOk:
		Move	PMC_Y1(pc),d0
		Cmp	PMC_Y2(pc),d0
		Ble.b	PMC_YOk
		Move	PMC_Y2(pc),PMC_Y1
		Move	d0,PMC_Y2
	PMC_YOk:
		Move	PMC_X1(pc),(a0)+
		Move	PMC_Y1(pc),(a0)+
		Move	PMC_X2(pc),(a0)+
		Move	PMC_Y2(pc),(a0)
	PMC_End:Rts

	PMC_Mod:Dc	0
	PMC_X1:	Dc	0
	PMC_Y1:	Dc	0
	PMC_X2:	Dc	0
	PMC_Y2:	Dc	0
*---------------
Pict_AutoClip:	Lea	Pict_BM(pc),a0
		Tst.l	8(a0)		;BitMap empty?
		Beq.b	PAC_End
		Lea	Sprite_Busy(pc),a1
		Bsr.w	Change_Sprite
		Lea	Pict_Gfx(pc),a4
		Lea	PictLay,a5	;###
		Jsr	Calc_Coord	;###
		Clr.l	d0
		Move	LayX,d0		;###
		Sub	X1,d0	;###
		Divu	DrawRes(pc),d0
		Clr.l	d1
		Move	LayY,d1		;###
		Sub	Y1,d1	;###
		Divu	DrawRes(pc),d1

		Move	PictOffsX(pc),d7
		Add	d7,d0
		Move	PictOffsY(pc),d7
		Add	d7,d1

		Bsr.w	Ask_Clip_List
		Beq.b	PAC_NEx
		Move	(a0),SX1
		Move	#-1,(a0)+
		Move	(a0)+,SY1
		Move	(a0)+,SX2
		Move	(a0),SY2
		Bsr.w	DrawBox
		Bra.b	PAC_End
	PAC_NEx:Bsr.w	Scan_Piece
	PAC_End:Rts
*---------------
Pict_Remove:	Lea	Pict_BM(pc),a0		;Any Picture?
		Tst.l	8(a0)			;+
		Beq.b	PR_End			;+ No
		Clr.l	8(a0)			;Clear Picture BM
		Lea	Mem_Picture,a5		;Free BM Memory ###
		Jsr	Free_Mem		;+	###
		Lea	PictNameDL(pc),a0	;Remove name of Picture
		Lea	NoPictT(pc),a1		;+
		Move.l	a1,10(a0)		;+
		Bsr.w	Clr_Clip_List		;Clear Clip List
		Move	#'BX',Pict_FrBx		;Turn gfx area into a BX
		Lea	PictLay,a5		;Update Picture window ###
		Lea	DrawList_Pict(pc),a4	;+
		Jsr	Draw_All		;+	###
	PR_End:	Rts				;End
*---------------
Calc_Mask:	;(D2: 1=Collision 2=Draw, Cur_Piec=Piece)
		Tst	d2
		Beq.b	CM_End
		Bsr.w	Get_Piec_LAdr
		Move.l	(a2),a2
	*-- Calculate mask
		Move.l	a2,a1
		Add	#28,a1
		Move.l	a1,a4
		Move	12(a2),d0	;BplSize
		Mulu	10(a2),d0	;Depth
		Add.l	d0,a4
		Cmp	#2,d2
		Bne.b	CM_Ok
		Add	12(a2),a4	;BplSize
	CM_Ok:	Move	12(a2),d0	;BplSize
		Lsr	#1,d0
		Subq	#1,d0
	CM_BLp:	Move.l	a1,a3
		Move	10(a2),d1	;Depth
		Clr	d7
	CM_DLp:	Or	(a3),d7
		Add	12(a2),a3	;BplSize
		Subq	#1,d1
		Bne.b	CM_DLp
		Move	d7,(a4)+
		Addq	#2,a1
		Dbf	d0,CM_BLp
	CM_End:	Rts
*---------------
Draw_All_Clips:	Move.l	Mem_Clip,a2	;###
		Move	#4096/8-1,d6
	DAC_Lp:	Tst	(a2)
		Bmi.b	DAC_Nxt
		Move	(a2),SX1
		Move	02(a2),SY1
		Move	04(a2),SX2
		Move	06(a2),SY2
		Bsr.w	DrawBox
	DAC_Nxt:Addq	#8,a2
		Dbf	d6,DAC_Lp
		Rts
*---------------
Pict_Update:	Lea	Pict_BM(pc),a3
		Tst.l	8(a3)		;BitMap empty?
		Beq.w	PU_Empt
	*-- Calculate frame sizes
		Lea	PictLay,a5	;###
		Lea	Pict_Gfx(pc),a4
		Jsr	Calc_Coord	;###
		Move	X2,d0	;###
		Sub	X1,d0	;###
		Move	d0,ClipSizeX
		Move	Y2,d0	;###
		Sub	Y1,d0	;###
		Move	d0,ClipSizeY

		Move	Pict_SizeX(pc),d0
		Cmp	ClipSizeX(pc),d0
		Bgt.b	PU_OkX
		Lea	Pict_Prop_X(pc),a0
		Move	#$ffff,2(a0)
		Clr	6(a0)
		Bra.b	NoOverX

	PU_OkX:	Lea	Pict_Prop_X(pc),a0
		Clr.l	d0
		Move	ClipSizeX(pc),d0
		Swap	d0
		Divu	Pict_SizeX(pc),d0
		And.l	#$0000ffff,d0
		Divu	DrawRes(pc),d0
		Move	d0,2(a0)

		Move	6(a0),d1
		And.l	#$ffff,d0
		And.l	#$ffff,d1
		Add.l	d0,d1
		Swap	d1
		Tst	d1
		Beq.b	NoOverX
		Swap	d1
		Sub	d1,6(a0)
	NoOverX:	
		Move	Pict_SizeY(pc),d0
		Cmp	ClipSizeY(pc),d0
		Bgt.b	PU_OkY
		Lea	Pict_Prop_Y(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Bra.b	NoOverY

	PU_OkY:	Lea	Pict_Prop_Y(pc),a0
		Clr.l	d0
		Move	ClipSizeY(pc),d0
		Swap	d0
		Divu	Pict_SizeY(pc),d0
		And.l	#$0000ffff,d0
		Divu	DrawRes(pc),d0
		Move	d0,4(a0)

		Move	8(a0),d1
		And.l	#$ffff,d0
		And.l	#$ffff,d1
		Add.l	d0,d1
		Swap	d1
		Tst	d1
		Beq.b	NoOverY
		Swap	d1
		Sub	d1,8(a0)
	NoOverY:	
		Lea	Pict_Prop_X(pc),a0
		Clr.l	d0
		Move	6(a0),d0
		Move	Pict_SizeX(pc),d1
		Subq	#1,d1
		Mulu	d1,d0
		Swap	d0
		Move	d0,PictOffsX
		
		Lea	Pict_Prop_Y(pc),a0
		Clr.l	d0
		Move	8(a0),d0
		Move	Pict_SizeY(pc),d1
		Subq	#1,d1
		Mulu	d1,d0
		Swap	d0
		Move	d0,PictOffsY
		Rts

	PU_Empt:Lea	Pict_Prop_X(pc),a0
		Move	#$ffff,2(a0)
		Clr	6(a0)
		Lea	Pict_Prop_Y(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Rts

PictOffsX:	Dc	0
PictOffsY:	Dc	0
ClipSizeX:	Dc	0
ClipSizeY:	Dc	0
*---------------
Convert_IFF:	;(A0=IFF-Address, D7->Status)
		Lea	LoadBuf(pc),a2
		Cmp.l	#'FORM',(a2)+
		Bne.b	I_Err
		Move.l	(a2)+,d7
		Move.l	a0,a1
		Add.l	d7,a1
		Sub	#12,a1
		Cmp.l	#'ILBM',(a2)+
		Bne.b	I_Err

	I_Srch:	Cmp.l	a1,a0
		Bge.b	I_End
		Move.l	(a0)+,d1
		Move.l	(a0)+,d2
		Btst	#0,d2
		Beq.b	I_Even
		Addq.l	#1,d2
	I_Even:	Cmp.l	#'BMHD',d1
		Beq.b	I_BMHD
		Cmp.l	#'CMAP',d1
		Beq.w	I_CMAP
		Cmp.l	#'BODY',d1
		Beq.w	I_BODY
		Cmp.l	#'CAMG',d1
		Beq.b	I_CAMG
		Add.l	d2,a0
		Bra.b	I_Srch

	I_Err:	Moveq.l	#-1,d7		;Set errorflag
		Rts
	I_End:	Clr.l	d7		;No errors
		Rts

	I_BMHD:	Move	(a0),d0
		Move	d0,Pict_RealSizeX
		Cmp	#320,d0
		Bge.b	I_TinyX
		Move	#320,d0
	I_TinyX:Move	d0,Pict_SizeX
		
		Move	2(a0),d0
		Move	d0,Pict_RealSizeY
		Cmp	#256,d0
		Bge.b	I_TinyY
		Move	#256,d0
	I_TinyY:Move	d0,Pict_SizeY

		Clr	d0
		Move.b	8(a0),d0
		Move	d0,Pict_Depth
		Move.b	10(a0),Compr

		Lea	Pict_BM(pc),a4
		Move	Pict_SizeX(pc),d0
		Lsr	#3,d0
		Move	d0,(a4)
		Move	Pict_SizeY(pc),2(a4)
		Move	Pict_Depth(pc),d0
		Move.b	d0,5(a4)

		Add.l	d2,a0
		Bra.w	I_Srch

	I_CAMG:	Move	(a0),CAMG
		Add.l	d2,a0
		Bra.w	I_Srch

	I_CMAP:	Move.l	a0,a4
		Move.l	Mem_Palette,a3	;###
		Moveq.l	#1,d0
		Move	Pict_Depth(pc),d1
		Lsl	d1,d0
		Subq	#1,d0
	I_CMAPL:Clr	d3
		Clr	d4
		Clr	d5
		Move.b	(a4)+,d3
		Move.b	(a4)+,d4
		Move.b	(a4)+,d5

		Clr.b	(a3)+
		Move.b	d3,(a3)+
		Move.b	d4,(a3)+
		Move.b	d5,(a3)+
		Dbf	d0,I_CMAPL
		Add.l	d2,a0
		Bra.w	I_Srch

	I_BODY:	Move	Pict_SizeX(pc),d3
		Lsr	#3,d3
		Mulu	Pict_SizeY(pc),d3
		Move.l	d3,BplSiz

		Movem.l	d0-d7/a0-a6,-(a7)
		Lea	Mem_Picture,a5	;###
	*-- Calculate Size Picture mem. D0=SizeX/8*Depth*SizeY
		Move	Pict_SizeX(pc),d0
		Lsr	#3,d0
		Mulu	Pict_Depth(pc),d0
		Mulu	Pict_SizeY(pc),d0
		Jsr	Alloc_Chip_Mem	;###
		Bne.b	I_NErr
		Jmp	Mess_CMemErr
	I_NErr:	Movem.l	(a7)+,d0-d7/a0-a6
		Move.l	Mem_Picture,a2	;###

		Move.l	a0,a3
		Clr	d3
		Clr.l	d0
		Move	Pict_RealSizeX(pc),d0
		Divu	#8,d0
		Move	d0,XByte
		Swap	d0
		Tst	d0
		Beq.b	I_NRem
		Addq	#1,XByte
	I_NRem:
		Move.b	Compr(pc),d0
		Beq.b	I_Com0
		Cmp.b	#1,d0
		Beq.b	I_Com1
		Bra.w	I_Err

	I_Com0:	
	I_NLpY:	Moveq.l	#0,d6
		Clr	d4

	I_NLpD:	Move	XByte(pc),d1
		Subq	#1,d1

	I_NLp0:	Move.b	(a3)+,0(a2,d6.l)
		Addq.l	#1,d6
		Dbf	d1,I_NLp0

		Move.l	BplSiz(pc),d0
		Add.l	d0,d6
		Sub	XByte(pc),d6
		Addq	#1,d4
		Cmp	Pict_Depth(pc),d4
		Bne.b	I_NLpD

		Add	XByte(pc),a2

		Move	Pict_SizeX(pc),d0
		Lsr	#3,d0
		Sub	XByte(pc),d0
		Add	d0,a2

		Addq	#1,d3
		Cmp	Pict_RealSizeY(pc),d3
		Bne.b	I_NLpY

		Btst	#0,d2
		Beq.b	I_NOk
		Addq.l	#1,d2
	I_NOk:	Add.l	d2,a0
		Bra.w	I_Srch

	I_Com1:	
	I_LpY:	Moveq.l	#0,d6
		Clr	d4
	I_LpD:	Moveq.l	#0,d5
	
	I_LpX:	Clr	d0
		Move.b	(a3)+,d0
		Bmi.b	I_Set

		Move	d0,d1
	I_Lp0:	Move.b	(a3)+,0(a2,d6.l)
		Addq.l	#1,d6
		Dbf	d1,I_Lp0
		Bra.b	I_Next

	I_Set:	Neg.b	d0
		Move	d0,d1
	I_Lp1:	Move.b	(a3),0(a2,d6.l)
		Addq.l	#1,d6
		Dbf	d1,I_Lp1
		Addq.l	#1,a3

	I_Next:	Addq	#1,d5
		Add	d0,d5
		Cmp	XByte(pc),d5
		Blt.b	I_LpX

		Move.l	BplSiz(pc),d0
		Add.l	d0,d6
		Sub	XByte(pc),d6
		Addq	#1,d4
		Cmp	Pict_Depth(pc),d4
		Bne.b	I_LpD

		Add	XByte(pc),a2
		Move	Pict_SizeX(pc),d0
		Lsr	#3,d0
		Sub	XByte(pc),d0
		Add	d0,a2

		Addq	#1,d3
		Cmp	Pict_RealSizeY(pc),d3
		Bne.b	I_LpY

		Btst	#0,d2
		Beq.b	I_Ok
		Addq.l	#1,d2
	I_Ok:	Add.l	d2,a0
		Bra.w	I_Srch

Pict_RealSizeX:	Dc	0
Pict_RealSizeY:	Dc	0
Pict_SizeX:	Dc	0
Pict_SizeY:	Dc	0
Pict_Depth:	Dc	5
CAMG:		Dc	0
BplSiz:		Dc.l	0
XByte:		Dc	0
Compr:		Dc.b	0,0
*---------------
Choose_Pointer:	Move.l	Screen_Struct,a0	;Get XY	###
		Move	18(a0),RawX
		Move	16(a0),RawY
		Jsr	Which_Layer		;Calculate Layer XY ###

		Lea	Pict_BM(pc),a0
		Tst.l	8(a0)			;Any Picture?
		Beq.b	CP_Piec

		Lea	Pict_Gfx(pc),a4
		Lea	PictLay,a5	;###
		Move.l	#'PICT',d7
		Bsr.w	Check_Area
		Bne.w	CP_Gfx
	*-- Find current piece, and check if it exists
	CP_Piec:Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)		;Any Piece?
		Beq.b	CP_Anim		;No

		Lea	Piec_GfxArea(pc),a4
		Lea	PiecLay,a5	;###
		Move.l	#'PIEC',d7
		Bsr.w	Check_Area
		Bne.w	CP_Gfx

	CP_Anim:Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	CP_Move

		Lea	Anim_Gfx(pc),a4
		Lea	AnimLay,a5	;###
		Move.l	#'ANIM',d7
		Bsr.w	Check_Area
		Beq.b	CP_Move
	*-- Are we picking an Animation Piece?
		Lea	GAnim_Pick(pc),a0
		Btst	#0,4(a0)
		Bne.b	CP_Ar
		Bra.b	CP_Gfx

	CP_Move:Jsr	Get_Move_LAdr		;###
		Tst.l	(a2)
		Beq.b	CP_Back

		Lea	GMove_Move,a4		;###
		Lea	MoveLay,a5	;###
		Move.l	#'MOVE',d7
		Bsr.b	Check_Area
		Bne.b	CP_Gfx

	CP_Back:Jsr	Get_Back_LAdr		;###
		Tst.l	(a2)
		Beq.b	CP_Ar

		Lea	Back_Gfx,a4		;###
		Lea	BackLay,a5		;###
		Move.l	#'BACK',d7
		Bsr.b	Check_Area
		Beq.b	CP_Ar
	*-- Are we picking a Background Piece?
		Lea	GBack_Pick,a0		;###
		Btst	#0,4(a0)
		Bne.b	CP_Ar
		Bra.b	CP_Gfx

	CP_Ar:	Lea	Sprite_Arrow(pc),a1
		Bra.w	Change_Sprite

	CP_Gfx:	Move	Pointer_Off(pc),d0
		Beq.b	CP_Cr
		Lea	Sprite_Null(pc),a1
		Bra.w	Change_Sprite

	CP_Cr:	Lea	Sprite_Cross(pc),a1
		Bra.w	Change_Sprite

Pointer_Off:	Dc	0
*---------------
Check_Area:	;Check if Pointer is within graphics area of any layer
		Jsr	Calc_Coord	;###
		Move.l	LayL,a0		;###
		Cmp.l	4(a0),d7
		Bne.b	CA_No
		Move	LayX,d0		;###
		Cmp	X1,d0		;###
		Blt.b	CA_No
		Cmp	X2,d0		;###
		Bgt.b	CA_No
		Move	LayY,d0		;###
		Cmp	Y1,d0		;###
		Blt.b	CA_No
		Cmp	Y2,d0		;###
		Bgt.b	CA_No
		Moveq.l	#1,d7
		Rts
	CA_No:	Clr.l	d7
		Rts
*---------------
Pict_Cross:	Lea	Pict_BM(pc),a0
		Tst.l	8(a0)			;Any Picture?
		Beq.w	PC_Quit

		Lea	Pict_Gfx(pc),a4
		Lea	PictLay,a5	;###
		Jsr	Calc_Coord	;###
		Move.l	Screen_Struct,a0	;Get XY	###
		Move	18(a0),RawX
		Move	16(a0),RawY
		Jsr	Which_Layer		;Calculate Layer XY ###

		Move.l	LayL,a0		;###
		Cmp.l	#'PICT',4(a0)
		Bne.w	PC_End

		Move	LayX,d0		;###
		Cmp	X1,d0		;###
		Blt.w	PC_End
		Cmp	X2,d0		;###
		Bge.w	PC_End
		Move	LayY,d0		;###
		Cmp	Y1,d0		;###
		Blt.w	PC_End
		Cmp	Y2,d0		;###
		Bge.b	PC_End

		Clr.l	d0
		Move	LayX,d0		;###
		Sub	X1,d0		;###
		Divu	DrawRes(pc),d0

		Clr.l	d1
		Move	LayY,d1		;###
		Sub	Y1,d1		;###
		Divu	DrawRes(pc),d1

		Move	PictOffsX(pc),d7
		Add	d7,d0
		Move	PictOffsY(pc),d7
		Add	d7,d1

		Move	d0,ClipX
		Move	d1,ClipY

		Move	ClipX(pc),d0
		Cmp	ClipX1(pc),d0
		Bne.b	PC_Move
		Move	ClipY(pc),d0
		Cmp	ClipY1(pc),d0
		Bne.b	PC_Move
		Bra.b	PC_Quit
		
	PC_Move:Move	UnDraw(pc),d0
		Beq.b	No_Last
		Bsr.b	Draw_Cross
		Clr	UnDraw
		
	No_Last:Move	ClipX(pc),ClipX1
		Move	ClipY(pc),ClipY1
		Bsr.b	Draw_Cross
		Move	#-1,UnDraw
	PC_Quit:Rts
	PC_End:	Move	UnDraw(pc),d0
		Beq.b	No_Last2
		Bsr.b	Draw_Cross
		Clr	UnDraw
		Move	#-1,ClipX1
		Move	#-1,ClipY1
No_Last2:	Rts
*---------------
Draw_Cross:	Lea	GPictManuClip(pc),a0
		Btst	#0,4(a0)
		Bne.b	DC_Yes
		Rts

	DC_Yes:	Move	PMC_Mod(pc),d0
		Beq.b	DC_Cros

		Move	PMC_X1(pc),SX1
		Move	PMC_Y1(pc),SY1
		Move	ClipX1(pc),SX2
		Bmi.b	DC_End
		Move	ClipY1(pc),SY2
		Bra.b	DrawBox

	DC_Cros:Move.l	GfxBase,a6	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move	#$ff00,d0
		Move	Pict_Depth(pc),d1
		Rol	d1,d0
		Move.b	d0,24(a3)

		Move.l	a3,a1
		Moveq.l	#3,d0
		Jsr	SetDrMd(a6)
		
		Lea	Pict_Gfx(pc),a4
		Move	ClipX1(pc),d0
		Move	PictOffsX(pc),d7
		Sub	d7,d0
		Bmi.b	DC_End
		Moveq.l	#0,d1
		Move	d0,d2
		Move	#1256,d3
		Bsr.w	ZBox

		Lea	Pict_Gfx(pc),a4
		Moveq.l	#0,d0
		Move	ClipY1(pc),d1
		Move	PictOffsY(pc),d7
		Sub	d7,d1
		Move	#1320,d2
		Move	d1,d3
		Bsr.w	ZBox
		
		Move.b	#$ff,24(a3)

	DC_End:	Rts
ClipX:		Dc	0
ClipY:		Dc	0
ClipX1:		Dc	-1
ClipY1:		Dc	-1
UnDraw:		Dc	0
*---------------
DrawBox:	Move	SX1(pc),DBX1
		Move	SX2(pc),DBX2
		Move	SY1(pc),DBY1
		Move	SY2(pc),DBY2

		Move	DBX1(pc),d0
		Cmp	DBX2(pc),d0
		Ble.b	DB_XOk
		Move	DBX2(pc),DBX1
		Move	d0,DBX2
	DB_XOk:
		Move	DBY1(pc),d0
		Cmp	DBY2(pc),d0
		Ble.b	DB_YOk
		Move	DBY2(pc),DBY1
		Move	d0,DBY2
	DB_YOk:
		Move	PictOffsX(pc),d0
		Sub	d0,DBX1
		Sub	d0,DBX2
		Move	PictOffsY(pc),d0
		Sub	d0,DBY1
		Sub	d0,DBY2
		
		Lea	PictLay(pc),a5
		Move.l	GfxBase,a6	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move	#$ff00,d0
		Move	Pict_Depth(pc),d1
		Rol	d1,d0
		Move.b	d0,24(a3)
		Move.l	a3,a1
		Moveq.l	#3,d0
		Jsr	SetDrMd(a6)

		Move	DBY1(pc),d0
		Cmp	DBY2(pc),d0
		Beq.b	DB_Tal1
		Move	DBX1(pc),d0
		Cmp	DBX2(pc),d0
		Beq.w	DB_Wid1

		Lea	Pict_Gfx(pc),a4
		Move	DBX1(pc),d0
		Move	DBY1(pc),d1
		Move	DBX2(pc),d2
		Subq	#1,d2
		Move	DBY1(pc),d3
		Bsr.w	ZBox

		Lea	Pict_Gfx(pc),a4
		Move	DBX2(pc),d0
		Move	DBY1(pc),d1
		Move	DBX2(pc),d2
		Move	DBY2(pc),d3
		Subq	#1,d3
		Bsr.w	ZBox

		Lea	Pict_Gfx(pc),a4
		Move	DBX1(pc),d0
		Addq	#1,d0
		Move	DBY2(pc),d1
		Move	DBX2(pc),d2
		Move	DBY2(pc),d3
		Bsr.w	ZBox

		Lea	Pict_Gfx(pc),a4
		Move	DBX1(pc),d0
		Move	DBY1(pc),d1
		Addq	#1,d1
		Move	DBX1(pc),d2
		Move	DBY2(pc),d3
		Bsr.w	ZBox
		Bra.b	DB_Fi

	DB_Tal1:Lea	Pict_Gfx(pc),a4
		Move	DBX1(pc),d0
		Move	DBY1(pc),d1
		Move	DBX2(pc),d2
		Move	d1,d3
		Bsr.w	ZBox
		Bra.b	DB_Fi

	DB_Wid1:Lea	Pict_Gfx(pc),a4
		Move	DBX1(pc),d0
		Move	DBY1(pc),d1
		Move	d0,d2
		Move	DBY2(pc),d3
		Bsr.w	ZBox
	DB_Fi:	Move.b	#$ff,24(a3)
		Rts

	DBX1:	Dc	0
	DBX2:	Dc	0
	DBY1:	Dc	0
	DBY2:	Dc	0
*---------------
Load_Module:	Lea	Sprite_Disk(pc),a1
		Bsr.w	Change_Sprite

		Lea	Comm_FileName(pc),a0
		Bsr.w	Get_File_Length
		Bne.b	LM_NEr1
		Jmp	Mess_FileErr
	LM_NEr1:Move.l	d7,File_Len

		Lea	Comm_FileName(pc),a0
		Bsr.w	Open_Old_File
		Bne.b	LM_NEr2
		Jmp	Mess_FileErr
	LM_NEr2:
		Lea	LoadBuf(pc),a0
		Moveq.l	#12,d0
		Bsr.w	Read_File

;Load_Module:
		Lea	ModlList,a4	;###
		Jsr	Find_Unit_Space	;###
		Move.l	a0,Modl_ListAdr
		Bne.b	LM_NEr3
		Jmp	Mess_MemErr
	LM_NEr3:
		Move	d7,Cur_Modl
	*-- Allocate memory.
		Move.l	File_Len(pc),d0		;Get file length
		Add.l	#20,d0			;Add space for header
		Moveq.l	#$2,d1			;ChipMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,LM_Address

		Bne.b	LM_NEr4
		Jmp	Mess_CMemErr
	LM_NEr4:

		Move.l	Modl_ListAdr(pc),a1
		Move.l	LM_Address(pc),(a1)+
		Move	#%111,(a1)+		;Set Flags = New
		Clr	(a1)+			;Clear Path
	*-- Copy Filename to Unit
		Lea	FileName,a0		;###
		Moveq.l	#22,d0
	LMd_NaL:Move.b	(a0)+,d1
		Cmp.b	#'a',d1
		Blo.b	LMd_NUp
		Cmp.b	#'z',d1
		Bhi.w	LRS_NUp
		Sub.b	#32,d1
	LMd_NUp:Move.b	d1,(a1)+
		Dbf	d0,LMd_NaL
		Clr.b	(a1)+
	*-- Store Module header data
		Move.l	Modl_ListAdr(pc),a0
		Move.l	(a0),a1			;Get Sample Address

		Clr	(a1)+			;Write Id
		Move.l	File_Len(pc),d0		;Write BytSize
		Add.l	#20,d0			;+
		Move.l	d0,(a1)+		;+

		Move	#65535,(a1)+		;Write Volume
		Clr.l	(a1)+			;Write Unused
		Clr.l	(a1)+			;Write Unused
		Clr.l	(a1)+			;Write Unused

		Lea	LoadBuf(pc),a0
		Move.l	(a0)+,(a1)+
		Move.l	(a0)+,(a1)+
		Move.l	(a0)+,(a1)+
		Move.l	a1,a0
		Move.l	File_Len(pc),d0
		Sub	#12,d0
		Bsr.w	Read_File
		Bsr.w	Close_File
		Jmp	Change_Modl		;###
LM_Address:	Dc.l	0
Modl_ListAdr:	Dc.l	0
*---------------
Load_IFF:	Lea	Sprite_Disk(pc),a1
		Bsr.w	Change_Sprite

		Lea	Comm_FileName(pc),a0
		Bsr.w	Get_File_Length

		Bne.b	LI_NEr1
		Jmp	Mess_FileErr
	LI_NEr1:
		Move.l	d7,File_Len

		Lea	Comm_FileName(pc),a0
		Bsr.w	Open_Old_File
		Bne.b	LI_NEr2
		Jmp	Mess_FileErr
	LI_NEr2:

		Lea	LoadBuf(pc),a0
		Moveq.l	#12,d0
		Bsr.w	Read_File

		Lea	LoadBuf(pc),a0
		Cmp.l	#'FORM',(a0)
		Bne.b	LI_NIff

		Cmp.l	#'8SVX',8(a0)
		Beq.w	Load_8SVX
		
		Cmp.l	#'ILBM',8(a0)
		Beq.w	Load_ILBM
		
	LI_NIff:Bra.w	Load_Module
		;Bra.w	Load_RawSample

		;Bsr.w	Close_File
		;Rts
*---------------
Load_RawSample:	Lea	SmplList,a4		;###
		Jsr	Find_Unit_Space		;###
		Move.l	a0,Smpl_ListAdr
		Bne.b	LRS_NE1
		Jmp	Mess_MemErr
	LRS_NE1:
		Move	d7,Cur_Smpl
	*-- Allocate memory.
		Move.l	File_Len(pc),d0		;Get file length
		Add.l	#20,d0			;Add space for header
		Moveq.l	#$2,d1			;ChipMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,LS_Address

		Bne.b	LRS_NE2
		Jmp	Mess_CMemErr
	LRS_NE2:

		Move.l	Smpl_ListAdr(pc),a1
		Move.l	LS_Address(pc),(a1)+
		Move	#%111,(a1)+		;Set Flags = New
		Clr	(a1)+			;Clear Path
	*-- Copy Filename to Unit
		Lea	FileName,a0		;###
		Moveq.l	#22,d0
	LRS_NaL:Move.b	(a0)+,d1
		Cmp.b	#'a',d1
		Blo.b	LRS_NUp
		Cmp.b	#'z',d1
		Bhi.b	LRS_NUp
		Sub.b	#32,d1
	LRS_NUp:Move.b	d1,(a1)+
		Dbf	d0,LRS_NaL
		Clr.b	(a1)+
	*-- Store Sample header data
		Move.l	Smpl_ListAdr(pc),a0
		Move.l	(a0),a1			;Get Sample Address

		Clr	(a1)+			;Write Id
		Move.l	File_Len(pc),d0		;Write BytSize
		Add.l	#20,d0			;+
		Move.l	d0,(a1)+		;+
		Clr	(a1)+			;Write Flags
		Move	#19886,(a1)+		;Write Frequency
		Move	#32767,(a1)+		;Write Volume
		Clr.l	(a1)+			;Write LoopStart
		Move.l	File_Len(pc),(a1)+	;Write LoopEnd

		Lea	LoadBuf(pc),a0
		Move.l	(a0)+,(a1)+
		Move.l	(a0)+,(a1)+
		Move.l	(a0)+,(a1)+
		Move.l	a1,a0
		Move.l	File_Len(pc),d0
		Sub	#12,d0
		Bsr.w	Read_File
		Bsr.w	Close_File
		Jmp	Change_Smpl	;###
*---------------
Load_8SVX:	Lea	SmplList,a4	;###
		Jsr	Find_Unit_Space	;###
		Move.l	a0,Smpl_ListAdr

		Bne.b	L8_NE1
		Jmp	Mess_MemErr
	L8_NE1:
		Move	d7,Cur_Smpl

	LS_Loop:Lea	LoadBuf(pc),a0
		Moveq.l	#8,d0
		Bsr.w	Read_File
		Tst	d0
		Beq.w	LS_NIff

		Lea	LoadBuf(pc),a0
		Cmp.l	#'BODY',(a0)
		Beq.b	LS_Body
		Cmp.l	#'VHDR',(a0)
		Beq.b	LS_VHdr

		Lea	DataBuf(pc),a0
		Lea	LoadBuf(pc),a1
		Move.l	4(a1),d0
		Bsr.w	Read_File
		Bra.b	LS_Loop

	LS_VHdr:Lea	VHdrBuf(pc),a0
		Lea	LoadBuf(pc),a1
		Move.l	4(a1),d0
		Bsr.w	Read_File
		Bra.b	LS_Loop
	LS_Body:
	*-- Allocate memory.
		Lea	LoadBuf(pc),a1		;Get length of BODY
		Move.l	4(a1),d0		;+
		Add.l	#20,d0			;Add space for header
		Moveq.l	#$2,d1			;ChipMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,LS_Address
		Bne.b	L8_NE2
		Jmp	Mess_CMemErr
	L8_NE2:

		Move.l	Smpl_ListAdr(pc),a1
		Move.l	LS_Address(pc),(a1)+
		Move	#%111,(a1)+		;Set Flags = New
		Clr	(a1)+			;Clear Path
	*-- Copy Filename to Unit
		Lea	FileName,a0		;###
		Moveq.l	#22,d0
SMoveNameLoop:	Move.b	(a0)+,d1
		Cmp.b	#'a',d1
		Blo.b	SNoUpper
		Cmp.b	#'z',d1
		Bhi.b	SNoUpper
		Sub.b	#32,d1
SNoUpper:	Move.b	d1,(a1)+
		Dbf	d0,SMoveNameLoop
		Clr.b	(a1)+
	*-- Store Sample header data
		Move.l	Smpl_ListAdr(pc),a0
		Move.l	(a0),a1			;Get Sample Address

		Clr	(a1)+			;Write Id
		Lea	LoadBuf(pc),a0		;Write BytSize
		Move.l	4(a0),d0		;+
		Add.l	#20,d0			;+
		Move.l	d0,(a1)+		;+
		Clr	(a1)+			;Write Flags
		Lea	VHdrBuf(pc),a0		;Write Frequency
		Move	12(a0),(a1)+		;+
		Move	#32767,(a1)+		;Write Volume
		Move.l	(a0),(a1)+		;Write LoopStart
		Move.l	(a0),d0			;Write LoopEnd
		Add.l	4(a0),d0		;+
		Move.l	d0,(a1)+		;+

		Move.l	a1,a0
		Lea	LoadBuf(pc),a1
		Move.l	4(a1),d0
		Bsr.w	Read_File
		Bsr.w	Close_File
		Jsr	Change_Smpl		;###
	LS_NIff:Rts
SFile_Len:	Dc.l	0
LS_Address:	Dc.l	0
Smpl_ListAdr:	Dc.l	0
*---------------
Load_ILBM:	Sub.l	#12,File_Len
		Lea	Mem_Iff(pc),a5	;Try to free Mem_Iff just incase
		Jsr	Free_Mem	;###
		Lea	Mem_Iff(pc),a5
		Move.l	File_Len(pc),d0
		Jsr	Alloc_Any_Mem	;###
		Bne.b	LP_NEr1
		Jsr	Mess_MemErr	;###
		Bsr.w	Close_File
		Bra.w	LP_End

	LP_NEr1:Move.l	Mem_Iff(pc),a0
		Move.l	File_Len(pc),d0
		Bsr.w	Read_File
		
		Bsr.w	Close_File
		
		Lea	Sprite_Busy(pc),a1
		Bsr.w	Change_Sprite

		Lea	Mem_Picture(pc),a5	;Free old picture
		Jsr	Free_Mem	;###
		Lea	Pict_BM(pc),a0
		Clr.l	8(a0)
		Bsr.w	Clr_Clip_List
		Lea	PictNameDL(pc),a0
		Lea	NoPictT(pc),a1
		Move.l	a1,10(a0)
		Move	#'BX',Pict_FrBx

		Move.l	Mem_Iff(pc),a0
		Bsr.w	Convert_IFF

		Beq.b	LI_NEr
		Jmp	Mess_IffCErr	;###
	LI_NEr:
		Lea	Mem_Iff(pc),a5
		Jsr	Free_Mem	;###

		Lea	Pict_BM+8(pc),a1
		Move.l	Mem_Picture(pc),a0
		Move.l	BplSiz(pc),d1
		Move	Pict_Depth(pc),d0
	LP_BmLp:Move.l	a0,(a1)+
		Add.l	d1,a0
		Subq	#1,d0
		Bne.b	LP_BmLp

		Move.l	GfxBase,a6	;###
		Lea	Pict_RP(pc),a1
		Jsr	InitRastPort(a6)
		Lea	Pict_BM(pc),a0
		Lea	Pict_RP(pc),a1
		Move.l	a0,4(a1)

		Lea	FileName(pc),a0
		Lea	PictNameT(pc),a1
		Moveq.l	#30,d0
MoveNameLoop:	Move.b	(a0)+,d1
		Cmp.b	#'a',d1
		Blo.b	NoUpper
		Cmp.b	#'z',d1
		Bhi.b	NoUpper
		Sub.b	#32,d1
NoUpper:	Move.b	d1,(a1)+
		Dbf	d0,MoveNameLoop
		Clr.b	(a1)+

		Lea	PictNameDL(pc),a0
		Lea	PictNameT(pc),a1
		Move.l	a1,10(a0)
		Move	#'FR',Pict_FrBx

		Bsr.w	ReDraw_All
	LP_End:	Rts

File_Len:	Dc.l	0
*---------------
Draw_Picture:	Lea	Pict_BM(pc),a0		;BitMap empty?
		Tst.l	8(a0)			;+
		Beq.w	DrawPict_End		;Yes

		Lea	Pict_Gfx(pc),a4
		Lea	PictLay(pc),a5
		Bsr.w	Calc_Coord
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move.l	GfxBase,a6	;###
		Move	LoCol(pc),d0
		Move.l	a3,a1
		Jsr	SetAPen(a6)
		Moveq.l	#0,d0
		Move.l	a3,a1
		Jsr	SetDrMd(a6)
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Move	X2(pc),d2
		Move	Y2(pc),d3
		Move.l	a3,a1
		Jsr	RectFill(a6)

Update_Picture:	Lea	Pict_BM(pc),a0		;BitMap empty?
		Tst.l	8(a0)			;+
		Beq.b	DrawPict_End		;Yes

		Lea	Pict_Gfx(pc),a4
		Lea	PictLay(pc),a5
		Bsr.w	Calc_Coord
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move.l	a3,a1
		Lea	GPictZoom(pc),a0
		Btst	#0,4(a0)
		Bne.b	DrawPict_Zoom

		Lea	Pict_BM(pc),a0
		Move.l	a0,BG_SrcBM
		Move	PictOffsX(pc),BG_SrcX
		Move	PictOffsY(pc),BG_SrcY
		Bsr.b	Blit_Gfx
DrawPict_End:	Rts

DrawPict_Zoom:	Lea	Pict_BM(pc),a0
		Move.l	a0,Z_SrcBM
		Move	PictOffsX(pc),Z_SrcX
		Move	PictOffsY(pc),Z_SrcY
		Move	Pict_ZFact(pc),Z_Factor
		Move.l	a1,Z_DstRP
		Move	Pict_SizeX(pc),Z_Width
		Lea	Zoom_BM(pc),a4
		Move.l	a4,Z_DstBM
		Bsr.w	Zoom
	*-- Blit zoomed gfx to screen
		Lea	Zoom_BM(pc),a0
		Move.l	a0,BG_SrcBM
		Clr	BG_SrcX
		Clr	BG_SrcY
		Move.l	Z_DstRP(pc),a1
		Bsr.b	Blit_Gfx
		Bra.w	Free_Zoom
BG_SrcBM:	Dc.l	0
BG_SrcX:	Dc	0
BG_SrcY:	Dc	0
*---------------
Blit_Gfx:	;(Blit from SrcBM to DstRP within X1,Y1,X2,Y2,
		;using source offset SrcX,SrcY)
		;(BG_SrcBM.L, X1.W, Y1.W, X2.W, Y2.W)
		;(BG_SrcX.W, BG_SrcY.W, A1=DstRP)
		Move.l	BG_SrcBM(pc),a0		;BitMap empty?
		Tst.l	8(a0)			;+
		Beq.b	BG_End			;Yes

		Move.l	GfxBase,a6	;###
		Move	X1(pc),d2
		Move	Y1(pc),d3
		Move	X2(pc),d4
		Move	Y2(pc),d5
		Sub	d2,d4
		Sub	d3,d5
		Addq	#1,d4
		Addq	#1,d5
		Move	#$c0,d6
		Move	BG_SrcX(pc),d0
		Move	BG_SrcY(pc),d1
		Jsr	BltBitMapRastPort(a6)
	BG_End:	Rts
*---------------
Blit_Msk:	;(BG_SrcBM.L, X1.W, Y1.W, X2.W, Y2.W)
		;(BG_SrcX.W, BG_SrcY.W, A1=DstRP)
		Move.l	BG_SrcBM(pc),a0		;BitMap empty?
		Tst.l	8(a0)			;+
		Beq.b	BM_End			;Yes

		Move.l	GfxBase,a6	;###
		Move.l	a1,a3
		Move	MdCol(pc),d0
		Jsr	SetAPen(a6)

		Move	X1(pc),d2
		Move	Y1(pc),d3
		Move	X2(pc),d4
		Move	Y2(pc),d5
		Sub	d2,d4
		Sub	d3,d5
		Addq	#1,d4
		Addq	#1,d5
		Move	BG_SrcX(pc),d0
		Move	BG_SrcY(pc),d7
		Move.l	BG_SrcBM(pc),a0
		Move	(a0),d1			;BytWidth
		Move.l	8(a0),a0		;Get Mask address
		Mulu	d1,d7
		Add	d7,a0
		Move.l	a3,a1
		Jsr	BltTemplate(a6)
	BM_End:	Rts
*---------------
Zoom:		;(Z_SrcBM.L, Z_DstBM.L, Z_SrcX.W, Z_SrcY.W, Z_Factor.W)
		;(X1.W, Y1.W, X2.W, Y2.W, Z_Width.W)
		Move.l	Z_SrcBM(pc),a0		;BitMap empty?
		Tst.l	8(a0)			;+
		Beq.w	Z_End			;Yes
	*-- Allocate memory
		Lea	Mem_Zoom(pc),a5
		Move.l	Z_SrcBM(pc),a3
		Move.b	5(a3),d0
		Ext.w	d0
		Mulu	#10240,d0
		Jsr	Alloc_Chip_Mem	;###
		Beq.w	Z_End
	*-- Create Zoom_BM structure
		Move.l	Z_SrcBM(pc),a3
		Move.l	Z_DstBM(pc),a4
		Move.b	5(a3),5(a4)		;Depth
		Addq	#8,a4
		Move.l	a4,a1
		Move.l	Mem_Zoom(pc),a0
		Move.b	5(a3),d0		;Get number of bitplanes
	BplLp:	Move.l	a0,(a1)+
		Add	#10240,a0		;Add bitplane size
		Subq.b	#1,d0
		Bne.b	BplLp
	*-- Check SrcBM and Window sizes
		Move	X2(pc),d0
		Sub	X1(pc),d0
		Addq	#1,d0

		Move	Z_Width(pc),d1
		Mulu	Z_Factor(pc),d1
		Cmp	d1,d0
		Ble.b	Z_NOvX

		Move	d0,d5
		Sub	d1,d5
		Asr	#1,d5
		Move	d1,d0
		Move	X1(pc),X2
		Add	d0,X2
		Subq	#1,X2
		Add	d5,X1
		Add	d5,X2

	Z_NOvX:	Move	d0,Z_SizeX

		Move	Y2(pc),d0
		Sub	Y1(pc),d0
		Addq	#1,d0

		Move.l	Z_SrcBM(pc),a0
		Move	2(a0),d1
		Mulu	Z_Factor(pc),d1
		Cmp	d1,d0
		Ble.b	Z_NOvY

		Move	d0,d5
		Sub	d1,d5
		Asr	#1,d5
		Move	d1,d0
		Move	Y1(pc),Y2
		Add	d0,Y2
		Subq	#1,Y2
		Add	d5,Y1
		Add	d5,Y2

	Z_NOvY:	Move	d0,Z_SizeY

		Move	X1(pc),Piec_XLayPos
		Move	Y1(pc),Piec_YLayPos
	*-- Zoom it
		Move.b	5(a3),d4
		Addq	#8,a3
	Z_Loop:	Bsr.w	Zoom_Bpl
		Addq	#4,a3
		Addq	#4,a4
		Subq.b	#1,d4
		Bne.b	Z_Loop
	Z_End:	Rts
*---------------
Free_Zoom:	;(Free Zoomed Units Memory)
		Lea	Mem_Zoom(pc),a5
		Bra.w	Free_Mem
*---------------
Free_ZBuf:	;(Free Zoomed Bobs Memory)
		Lea	Mem_ZGfx(pc),a5
		Bsr.w	Free_Mem
		Lea	Mem_ZMsk(pc),a5
		Bra.w	Free_Mem
*---------------
Free_GfxBuf:	;(Free Unit Gfx Buffer Memory)
		Lea	Mem_GfxBuf(pc),a5
		Bra.w	Free_Mem
*---------------
Init_ZBufRP:	;(Initialize Units Gfx Buffer RastPort)
		Move.l	GfxBase(pc),a6
		Lea	ZBuf_RP(pc),a1
		Jsr	InitRastPort(a6)
		Lea	ZBuf_BM(pc),a0
		Lea	ZBuf_RP(pc),a1
		Move.l	a0,4(a1)
		Rts
*---------------
Zoom_BM:	Dc	40,256,4,0	;BM for Zoomed Units
		Blk.l	8,0
ZBob_BM:	Dc	40,256,4,0	;BM for Zoomed Bobs
		Blk.l	8,0
ZBuf_BM:	Dc	40,256,4,0	;BM for Unit Gfx Buffer
		Blk.l	8,0
ZBuf_RP:	Blk.b	100,0		;RP for Unit Gfx Buffer
*---------------
Z_DstRP:	Dc.l	0
Z_SrcBM:	Dc.l	0
Z_DstBM:	Dc.l	0
Z_SrcAdr:	Dc.l	0
Z_DstAdr:	Dc.l	0
Z_SrcX:		Dc	0
Z_SrcY:		Dc	0
Z_SizeX:	Dc	0
Z_SizeY:	Dc	0
Z_Width:	Dc	0
Z_Factor:	Dc	0
*---------------
Zoom_Bpl:	
	*-- Zoom X
		Move.l	GfxBase(pc),a6	;Take over the Blitter
		Jsr	OwnBlitter(a6)	;+
		Lea	$dff000,a6	;Set custom chip start add
		Move	Z_SrcX(pc),a2	;Set Src counter
		Sub.l	a5,a5		;Clear Dst counter

	ZX_BFin:Btst	#14,$2(a6)
		Bne.b	ZX_BFin
		
		Move.l	Z_SrcBM(pc),a0
		Move	(a0),d0
		Subq	#2,d0
		Move	d0,$64(a6)	;AMOD=Src
		Move	#38,$62(a6)	;BMOD=Bck
		Move	#38,$66(a6)	;DMOD=Dst
		Move	#$ffff,$46(a6)	;LWM
		Clr	$42(a6)		;CON1
	*-- Precalc BLTSIZE (D1)
		Clr.l	d1
		Move	Z_SizeY(pc),d1
		Divu	Z_Factor(pc),d1
		Addq	#2,d1
		Lsl	#6,d1
		Addq	#1,d1
	*-- Precalc SrcAdr
		Move.l	(a3),a0		;Obj Pt
		Move	Z_SrcY(pc),d5	;YOffset*BytesPerRow
		Move.l	Z_SrcBM(pc),a1	;+
		Mulu	(a1),d5		;+
		Add.l	d5,a0
		Move.l	a0,Z_SrcAdr
	*-- Precalc DstAdr
		Move.l	(a4),a1
		Move.l	#256,d5
		Divu	Z_Factor(pc),d5
		Move	#255,d6
		Sub	d5,d6
		Mulu	#40,d6
		Add.l	d6,a1
		Move.l	a1,Z_DstAdr
	
	ZX_Lp1:	Move	Z_Factor(pc),d0
	ZX_Lp2:	Move	a2,d5		;Copy Obj Counter
		Move	d5,d6		;Copy Obj Counter
		And	#$f,d5		;Mask Obj remainder
		Lsr	#3,d6		;Divide by 8
		Move	a5,d2		;Copy Dest Counter
		Move	d2,d7		;Copy Dest Counter
		And	#$f,d2		;Mask Dest remainder
		Lsr	#3,d7		;Divide by 8
		Add.b	#16,d2
		Sub.b	d5,d2
		Cmp.b	#15,d2
		Bgt.b	ZX_Ok
		Sub	#40,d7
	ZX_Ok:	Not.b	d5
		And.b	#$f,d5
		Clr	d3		;Clear Mask
		Bset	d5,d3		;Make Mask
		And	#$f,d2
		Ror	#4,d2
		Or	#$dfc,d2
	
		Move.l	Z_SrcAdr(pc),a0
		Add	d6,a0
		Move.l	Z_DstAdr(pc),a1
		Add	d7,a1
	ZX_Wait:Btst	#14,$2(a6)
		Bne.b	ZX_Wait
		Move.l	a0,$50(a6)	;APT=Src
		Move.l	a1,$4c(a6)	;BPT=Bck
		Move.l	a1,$54(a6)	;DPT=Dst
		Move	d3,$44(a6)	;AFWM
		Move	d2,$40(a6)	;CON0
		Move	d1,$58(a6)	;SIZE
		Addq	#1,a5
		Cmp	Z_SizeX(pc),a5
		Beq.b	ZX_End
		Subq	#1,d0
		Bne.b	ZX_Lp2
		Addq	#1,a2
		Bra.b	ZX_Lp1
	ZX_End:	Move.l	GfxBase(pc),a6	
		Jsr	DisownBlitter(a6)
	*-- Zoom Y
		Move.l	(a4),a1			;Get Zoom plane address
		Move.l	a1,a2			;Copy it
		Move.l	#256,d1			;To bottom
		Divu	Z_Factor(pc),d1		;Divide by ZoomFactor
		Move	#255,d5			;Subtract from bottom
		Sub	d1,d5			;+
		Mulu	#40,d5			;Multiply by 40
		Add	d5,a1			;And add it
		Clr	d1			;Clear counter
	ZoomY3:	Move	Z_Factor(pc),d0		;Set zoom counter
	ZoomY2:	Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Move.l	(a1)+,(a2)+
		Addq	#1,d1
		Cmp	Z_SizeY(pc),d1
		Beq.b	ZoomYE
		Sub	#40,a1
		Subq	#1,d0
		Bne.b	ZoomY2
		Add	#40,a1
		Bra.b	ZoomY3
	ZoomYE:	Rts
*---------------
DrawList_Pict:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Picture8T
		Dc	'TX',076,009,-01,5
		Dc.l	DashT
PictNameDL:	Dc	'TX',085,009,-01,5
		Dc.l	NoPictT

		Dc	'BX',000,011,-01,027
		
GPictSelect:	Dc	'GD'
		Dc.l	$020100e1,0,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

GPictRemove:	Dc	'GD'
		Dc.l	$0201002b,0,Pict_Remove
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_Remove-Im
		
GPictFullClip:	Dc	'GD'
		Dc.l	$0201002c,0,Pict_FullClip
		Dc	'BX',033,013,045,025
		Dc	'IM',035,015,9,Im_FullClip-Im

GPictAutoClip:	Dc	'GD'
		Dc.l	$0201062d,Pict_Excl_Clip,Pict_ClrMode
		Dc	'BX',046,013,058,025
		Dc	'IM',048,017,5,Im_AutoClip-Im
		
GPictManuClip:	Dc	'GD'
		Dc.l	$0201062e,Pict_Excl_Clip,Pict_ClrMode
		Dc	'BX',059,013,071,025
		Dc	'IM',061,016,7,Im_ManuClip-Im

;GPictPolyClip:	Dc	'GD'
;		Dc.l	$0201062f,Pict_Excl_Clip,Pict_ClrMode
;		Dc	'BX',072,013,084,025
;		Dc	'IM',074,015,9,Im_PolyClip-Im

GPictClrClips:	Dc	'GD'
		Dc.l	$02010030,0,Pict_ClrClips
		Dc	'BX',076,013,088,025
		Dc	'IM',078,015,9,Im_ClrClips-Im

GPictStore:	Dc	'GD'
		Dc.l	$02010031,0,Pict_Store
		Dc	'BX',093,013,105,025
		Dc	'IM',095,017,5,Im_Store-Im

GPictStoreClr:	Dc	'GD'
		Dc.l	$02010032,0,Pict_StoreClr
		Dc	'BX',106,013,118,025
		Dc	'IM',108,017,5,Im_StoreClr-Im

GPictZoom:	Dc	'GD'
		Dc.l	$02010209,0,Pict_Zoom
		Dc	'BX',123,013,135,025
		Dc	'IM',125,015,9,Im_Zoom-Im
		
		Dc	'BX',136,013,169,025

		Dc	'GD'
		Dc.l	$02030a35,1,Pict_ZoomFactor
		Dc	'RC',138,015,147,023
Pict_ZFactUpd:	Dc	'TX',141,022,-01,5
		Dc.l	Pict_ZFactT

		Dc	'GD'
		Dc.l	$02010034,0,Pict_ZoomMinus
		Dc	'BX',150,015,158,023
		Dc	'IM',152,019,1,Im_Minus-Im
		
		Dc	'GD'
		Dc.l	$02010033,0,Pict_ZoomPlus
		Dc	'BX',159,015,167,023
		Dc	'IM',161,017,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

Pict_FrBx:	Dc	'BX',000,028,-10,-10
Pict_PictUpd:	Dc	'GD'
		Dc.l	$010000f8,0,Pict_Picture
Pict_Gfx:	Dc	'DF',003,031,-13,-13
		Dc	'RO'
		Dc.l	Pict_Update
		Dc	'RO'
		Dc.l	Draw_Picture
		Dc	'RO'
		Dc.l	Draw_All_Clips

		Dc	'GD'
		Dc.l	$02020000,Pict_Prop_X,Pict_OffsetX
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',020,-07,-40,-03

		Dc	'GD'
		Dc.l	$02020000,Pict_Prop_Y,Pict_OffsetY
		Dc	'BX',-09,028,-01,-10
		Dc	'BX',-07,050,-03,-34

		Dc	'XX'

Pict_Prop_X:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
Pict_Prop_Y:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,65535		;KnobX,Y
		Dc	0,0		;PosX,Y
Pict_Excl_Clip:	Dc.l	GPictAutoClip
		Dc.l	GPictManuClip
		;Dc.l	GPictPolyClip
		Dc.l	0
NoPictT:	Dc.b	'NO PICTURE LOADED',0
PictNameT:	Blk.b	32,0
Pict_ZFactT:	Dc.b	'2',0
		Even
*=======================================================================*
*			       P I E C E				*
*=======================================================================*
Piec_New:	Lea	PiecList,a4	;###
		Moveq.l	#4,d5		;Depth. ***
	*-- Get list space.
		Bsr.w	Find_Unit_Space		;This routine saves regs.
		Move.l	a0,PN_LstA
		Beq.w	Mess_MemErr
	*-- Allocate memory.
		Move	d5,d4
		Addq	#2,d5
		Mulu	#2,d5
		Add	#28,d5
		Move.l	d5,d0			;ByteSize
		Moveq.l	#2,d1			;ChipMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Tst.l	d0
		Beq.w	Mess_MemErr
	*-- Write to list.
		Move.l	PN_LstA(pc),a0
		Move.l	d0,(a0)
		Move	#%111,4(a0)		;Set Flags = New
		Move	#1,6(a0)			;Clear Path	$$$
		Bsr.w	Unnamed
	*-- Store new Unit.
		Move.l	(a0),a1		;Get Unit Address
		Clr	(a1)+		;Id
		Move.l	d5,(a1)+	;BytSize
		Move	#1,(a1)+	;XSize
		Move	#1,(a1)+	;YSize
		Move	d4,(a1)+	;Depth
		Move	#2,(a1)+	;BplSize
		Move	#2,(a1)+	;ByteWidth
		Move	#$42,(a1)+	;BltSize
		Move.b	#$80,(a1)+	;Flags
		Clr.b	(a1)+		;Value
		Subq.l	#4,d5		;ColMaskOff
		Move.l	d5,(a1)+	;+
		Addq.l	#2,d5		;BltMaskOff
		Move.l	d5,(a1)+	;+
	PN_BLp:	Move	#$8000,(a1)+	;BitMaps
		Subq	#1,d4		;+
		Bne.b	PN_BLp		;+
		Move	#$8000,(a1)+	;ColMask
		Move	#$8000,(a1)+	;BltMask
		Move	d7,Cur_Piec
		Bra.w	Change_Piec
	PN_LstA:Dc.l	0
*---------------
Piec_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Piec_Graphics:	Clr	Piec_Showing
		Bra.b	Piec_GfxSel_Com
*---------------
Piec_BltShadow:	Move	#2,Piec_Showing
		Bra.b	Piec_GfxSel_Com
*---------------
Piec_ColShadow:	Move	#1,Piec_Showing
		Bra.w	Piec_GfxSel_Com
*---------------
Piec_GfxSel_Com:Move.l	HitGd(pc),a4
		Lea	PiecLay(pc),a5
		Btst	#0,4(a4)	;Trying to unpush?
		Bne.b	PG_Ok		;+
		Bset	#0,4(a4)	;Push in
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
	PG_Ok:	Lea	Piec_GfxUpd(pc),a4
		Bra.w	Draw_All
Piec_Showing:	Dc	0
*---------------
Piec_CalcShadow:Lea	Piec_Info,a3	;###
		Bsr.w	Update_UnitBuf
		Move	Piec_Showing(pc),d2
		Bsr.w	Calc_Mask

		Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)
		Beq.b	PCS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate

		Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bra.w	Draw_All
	PCS_Ed:	Rts
*---------------
Piec_ZoomFactor:Move.l	Convert_Value(pc),d0
		Cmp	#2,d0
		Blt.b	PcZF_E
		Cmp	#9,d0
		Bgt.b	PcZF_E
		Move	d0,Piec_ZFact
	PcZF_E:	Bra.b	Piec_PM_TUpd
*---------------
Piec_Zoom:	Lea	GPiecZoom(pc),a4
		Btst	#0,4(a4)
		Beq.b	Piec_ZEnd

Piec_UpdZoom:	Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bra.w	Draw_All

Piec_ZEnd:	Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bra.w	Draw_All
*---------------
Piec_ZoomPlus:	Cmp	#9,Piec_ZFact
		Beq.b	Piec_PM_End
		Addq	#1,Piec_ZFact
		Bra.b	Piec_PM_TUpd
*---------------
Piec_ZoomMinus:	Cmp	#2,Piec_ZFact
		Beq.b	Piec_PM_End
		Subq	#1,Piec_ZFact

Piec_PM_TUpd:	Move	Piec_ZFact(pc),d0
		Lea	Piec_ZFactT+1(pc),a0
		Moveq.l	#0,d7
		Bsr.w	Conv
		Lea	GPiecZoom(pc),a4
		Btst	#0,4(a4)
		Beq.b	Piec_PM_Not
		Bsr.b	Piec_UpdZoom
Piec_PM_Not:	Lea	PiecLay(pc),a5
		Lea	Piec_ZFactUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some
Piec_PM_End:	Rts
Piec_ZFact:	Dc	2
*---------------
Piec_Draw:	Lea	DrawLay(pc),a5
		Bra.w	Open_Layer
*---------------
Change_Piec:
	*-- Find current piece, and check if it exists
		Bsr.w	Get_Piec_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	CP_End

		Bsr.w	Upd_PiecNameD

		Lea	PiecLay(pc),a5
		Lea	Piec_GfxUpd(pc),a4
		Bsr.w	Draw_All
		Lea	Piec_NameUpd(pc),a4
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Bsr.w	Upd_PiecColl
		Lea	PiecLay(pc),a5
		Lea	GPiec_Coll(pc),a4
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Lea	Piec_Info,a3	;###
		Bsr.w	Upd_SelcUnit
	CP_End:	Rts
*---------------
Piec_Piece:	
	*-- Draw window open?
		Lea	DrawLay(pc),a0
		Tst.l	(a0)
		Beq.b	PP_NFH
	*-- Are we drawing FloodFill?
		Lea	GDrawFill(pc),a4
		Btst	#0,4(a4)
		Bne.b	Piec_FloodFill
	*-- Are we drawing FreeHand?
		Lea	GDrawFreeHand(pc),a4
		Btst	#0,4(a4)
		Beq.b	PP_NFH

		Lea	Piec_Info,a3	;###
		Bsr.w	Update_UnitBuf
	PP_Lop:	
		Bsr.w	Piec_Pixel
		Clr	PDraw_Undraw
		
		Move	LayX(pc),d0
		Move	LayY(pc),d1
		Sub	Piec_XLayPos(pc),d0
		Sub	Piec_YLayPos(pc),d1
		Lea	GPiecZoom(pc),a4
		Btst	#0,4(a4)
		Beq.b	PP_NZo
		Ext.l	d0
		Ext.l	d1
		Divu	Piec_ZFact(pc),d0
		Divu	Piec_ZFact(pc),d1
	PP_NZo:	Move	Left_Color(pc),d7
		Move	Piec_Showing(pc),d2
		Bsr.w	Piec_Pixel_Set
		Bsr.w	Check_Left_Up
		Beq.b	PP_Lop
	PP_NFH:	Rts
*---------------
Piec_FloodFill:	Lea	Piec_Info,a3	;###
		Bsr.w	Update_UnitBuf

		Move	LayX(pc),d0
		Move	LayY(pc),d1
		Sub	Piec_XLayPos(pc),d0
		Sub	Piec_YLayPos(pc),d1
		Lea	GPiecZoom(pc),a4
		Btst	#0,4(a4)
		Beq.b	PFF_NZo
		Ext.l	d0
		Ext.l	d1
		Divu	Piec_ZFact(pc),d0
		Divu	Piec_ZFact(pc),d1
	PFF_NZo:
	*-- Find current piece, and check if it exists
		Move.l	Mem_PiecList(pc),a2
		Move	Cur_Piec,d3	;###
		Ext.l	d3
		Lsl.l	#5,d3		;Multiply by 32		
		Add.l	d3,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	PFF_Ed		;No
		Or	#2,4(a2)	;Set NeedsUpdate
		Move.l	(a2),a2		;Get PieceData Address
	*-- Check Limits
		Tst	d0
		Bmi.w	PFF_Ed
		Tst	d1
		Bmi.w	PFF_Ed
		Cmp	6(a2),d0	;SizeX
		Bge.w	PFF_Ed
		Cmp	8(a2),d1	;SizeY
		Bge.w	PFF_Ed

		Move	d0,PFF_X
		Move	d1,PFF_Y
	*-- Create BitMap and RastPort for Piece
		Lea	Piec_BM(pc),a0

		Move	14(a2),(a0)	;ByteWidth
		Move	8(a2),02(a0)	;YSize

		Move.l	a2,a1

		Move	Piec_Showing(pc),d2
		Beq.b	PFF_Gfx
		Add.l	20(a2),a1	;BltMaskOff
		Cmp	#1,d2
		Beq.b	PFF_Msk
		Add	12(a2),a1	;BplSize

	PFF_Msk:Move.b	#1,05(a0)
		Move.l	a1,08(a0)
		Bra.b	PFF_Fil

	PFF_Gfx:Move	10(a2),d7	;Depth
		Move.b	d7,05(a0)
		Add	#28,a1
		Move	12(a2),d0	;BplSize
		Addq.l	#8,a0
		Move	d7,d1
	PFF_BLp:Move.l	a1,(a0)+
		Add	d0,a1
		Subq	#1,d1
		Bne.b	PFF_BLp

	PFF_Fil:Move.l	GfxBase,a6	;###
		Lea	Piec_RP(pc),a1
		Jsr	InitRastPort(a6)
		Lea	Piec_BM(pc),a0
		Lea	Piec_RP(pc),a1
		Move.l	a0,4(a1)

		Lea	Mem_TmpRas(pc),a5	;Try to free TmpRas just incase
		Bsr.w	Free_Mem

		Lea	Mem_TmpRas(pc),a5
		Clr.l	d0
		Move	12(a2),d0	;BplSize
		Lea	TmpRas(pc),a3
		Move.l	d0,4(a3)
		Bsr.w	Alloc_Chip_Mem
		Beq.w	Mess_CMemErr

		Move.l	Mem_TmpRas(pc),a5
		Lea	TmpRas(pc),a3
		Move.l	a5,(a3)
		Lea	Piec_RP(pc),a1
		Move.l	a3,12(a1)	;12=TmpRas

		Move.l	GfxBase,a6	;###
		Lea	Piec_RP(pc),a1
		Move	Left_Color(pc),d0
		Move	Piec_Showing(pc),d1
		Beq.b	PFF_Col
		Tst	d0
		Beq.b	PFF_Col
		Moveq.l	#1,d0
	PFF_Col:Jsr	SetAPen(a6)
	*-- Flood it!
		Lea	Piec_RP(pc),a1
		Move	PFF_X(pc),d0	;X
		Move	PFF_Y(pc),d1	;Y
		Moveq.l	#1,d2		;Mode
		Jsr	Flood(a6)

		Lea	Mem_TmpRas(pc),a5
		Bsr.w	Free_Mem

		Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bsr.w	Draw_All

	PFF_Ed:	Rts

	PFF_X:	Dc	0
	PFF_Y:	Dc	0

TmpRas:		Dc.l	0	;RasPtr
		Dc.l	0	;Size
*---------------
Piec_Pixel:	Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)
		Beq.w	PPx_Qut

		Lea	Piec_GfxArea(pc),a4
		Lea	PiecLay(pc),a5
		Bsr.w	Calc_Coord
		Move.l	Screen_Struct,a0	;Get XY	###
		Move	18(a0),RawX
		Move	16(a0),RawY
		Jsr	Which_Layer		;Calculate Layer XY ###

		Move.l	LayL,a0		;###
		Cmp.l	#'PIEC',4(a0)
		Bne.w	PPx_Ed

		Move	LayX,d0		;###
		Cmp	X1(pc),d0
		Blt.w	PPx_Ed
		Cmp	X2(pc),d0
		Bge.w	PPx_Ed
		Move	LayY,d0		;###
		Cmp	Y1(pc),d0
		Blt.w	PPx_Ed
		Cmp	Y2(pc),d0
		Bge.w	PPx_Ed

		Move	LayX(pc),d0
		Move	LayY(pc),d1
		Sub	Piec_XLayPos(pc),d0
		Sub	Piec_YLayPos(pc),d1
		Move	#1,PDraw_Zoom
		Lea	GPiecZoom(pc),a4
		Btst	#0,4(a4)
		Beq.b	PPx_NZo
		Ext.l	d0
		Ext.l	d1
		Divu	Piec_ZFact(pc),d0
		Divu	Piec_ZFact(pc),d1
		Move	Piec_ZFact(pc),PDraw_Zoom
	PPx_NZo:
		Move	d0,PDraw_X
		Move	d1,PDraw_Y

		Move	PDraw_X(pc),d0
		Cmp	PDraw_LastX(pc),d0
		Bne.b	PPx_Mov
		Move	PDraw_Y(pc),d0
		Cmp	PDraw_LastY(pc),d0
		Bne.b	PPx_Mov
		Bra.b	PPx_Qut
		
	PPx_Mov:Move	PDraw_Undraw(pc),d0
		Beq.b	PPx_NLs
		Move	PDraw_LastCol(pc),d7
		Bsr.b	Draw_Pixel
		Clr	PDraw_Undraw
		
	PPx_NLs:Move	PDraw_X(pc),PDraw_LastX
		Move	PDraw_Y(pc),PDraw_LastY
		Move	Left_Color(pc),d7
		Bsr.b	Draw_Pixel
		Move	#-1,PDraw_Undraw
	PPx_Qut:Rts
	PPx_Ed:	Move	PDraw_Undraw(pc),d0
		Beq.b	PPx_NL2
		Move	PDraw_LastCol(pc),d7
		Bsr.b	Draw_Pixel
		Clr	PDraw_Undraw
		Move	#-1,PDraw_LastX
		Move	#-1,PDraw_LastY
	PPx_NL2:Rts
*---------------
Draw_Pixel:
	*-- Draw window open?
		Lea	DrawLay(pc),a0
		Tst.l	(a0)
		Beq.w	DPx_End
	*-- Are we drawing FreeHand?
		Lea	GDrawFreeHand(pc),a4
		Btst	#0,4(a4)
		Beq.w	DPx_End

		Move.l	GfxBase,a6	;###
		Lea	PiecLay(pc),a5
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move.l	a3,a1
		Moveq.l	#1,d0
		Jsr	SetDrMd(a6)
		
		Move.l	a3,a1
		Move	d7,d0
		Move	Piec_Showing(pc),d1
		Beq.b	DPx_Col
		Tst	d7
		Beq.b	DPx_Col
		Move	MdCol(pc),d0
	DPx_Col:Jsr	SetAPen(a6)
		
		Lea	Piec_GfxDef(pc),a4
		
		Move	PDraw_LastX(pc),d0
		Bmi.w	DPx_End
		Move	PDraw_LastY(pc),d1
		Move	d0,d2
		Move	d1,d3
	*-- Draw Pixel
		Tst.l	(a5)
		Beq.w	DPx_End
		Move.l	d0,-(a7)
		Bsr.w	Calc_Coord
		Move.l	(a7)+,d0

		Movem.l	d0-d7/a0-a6,-(a7)

;Piec_Pixel_Tst:	;(D0=X, D1=Y, D7->Color, Cur_Piec=Piece)
		;(D2: 0=Graphics 1=CollMask 2=BlitMask)

		Move.l	d0,-(a7)
		Bsr.w	Get_Piec_LAdr
		Move.l	(a7)+,d0
		
		Move.l	(a2),a2
		Move	Piec_Showing(pc),d2
		Bsr.w	CPiec_Pixel_Tst
		Move	d7,PDraw_LastCol
		Movem.l	(a7)+,d0-d7/a0-a6
		Tst	PDraw_LastCol
		Bmi.b	DPx_End

		Muls	PDraw_Zoom(pc),d0
		;Add	X1(pc),d0
		Muls	PDraw_Zoom(pc),d2
		Add	PDraw_Zoom(pc),d2
		;Add	X1(pc),d2
		Subq	#1,d2

		Add	Piec_XLayPos(pc),d0
		Add	Piec_XLayPos(pc),d2
		Cmp	X1(pc),d2
		Blt.b	DPx_End
		Cmp	X1(pc),d0
		Bge.b	DPx_BXU
		Move	X1(pc),d0
	DPx_BXU:Cmp	X2(pc),d0
		Bgt.b	DPx_End
		Cmp	X2(pc),d2
		Blt.b	DPx_BX
		Move	X2(pc),d2

	DPx_BX:	Muls	PDraw_Zoom(pc),d1
		;Add	Y1(pc),d1
		Muls	PDraw_Zoom(pc),d3
		Add	PDraw_Zoom(pc),d3
		;Add	Y1(pc),d3
		Subq	#1,d3

		Add	Piec_YLayPos(pc),d1
		Add	Piec_YLayPos(pc),d3
		Cmp	Y1(pc),d3
		Blt.b	DPx_End
		Cmp	Y1(pc),d1
		Bge.b	DPx_BYU
		Move	Y1(pc),d1
	DPx_BYU:Cmp	Y2(pc),d1
		Bgt.b	DPx_End
		Cmp	Y2(pc),d3
		Blt.b	DPx_BY
		Move	Y2(pc),d3

	DPx_BY:	
		Move.l	(a5),a1
		Move.l	12(a1),a1
		Move.l	GfxBase(pc),a6
		Jsr	RectFill(a6)
	DPx_End:Rts

PDraw_Zoom:	Dc	0
PDraw_Undraw:	Dc	0
PDraw_X:	Dc	0
PDraw_Y:	Dc	0
PDraw_LastX:	Dc	0
PDraw_LastY:	Dc	0
PDraw_LastCol:	Dc	0
*---------------
Piec_Load:	Move.l	PiecList(pc),a4
		Move.l	(a4),a4
		Move	Cur_Piec(pc),d4
		Move.l	#'PIEC',d0
		Bsr.w	Load_Unit
		Bra.w	Change_Piec
*---------------
Piec_Pixel_Set:	;(D0=X, D1=Y, D7=Color, Cur_Piec=Piece)
		;(D2: 0=Graphics 1=CollMask 2=BlitMask)
	*-- Find current piece, and check if it exists
		Move.l	Mem_PiecList(pc),a2
		Move	Cur_Piec(pc),d3
		Ext.l	d3
		Lsl.l	#5,d3		;Multiply by 32		
		Add.l	d3,a2
		Tst.l	(a2)		;Any Piece?
		Beq.b	PPS_Ed		;No
		Or	#2,4(a2)	;Set NeedsUpdate
		Move.l	(a2),a2		;Get PieceData Address
	*-- Check Limits
		Tst	d0
		Bmi.b	PPS_Ed
		Tst	d1
		Bmi.b	PPS_Ed
		Cmp	6(a2),d0	;SizeX
		Bge.b	PPS_Ed
		Cmp	8(a2),d1	;SizeY
		Bge.b	PPS_Ed

		Move.l	a2,a1
		Mulu	14(a2),d1
		Move	d0,d4
		Lsr	#3,d4
		Add	d4,d1
		Not	d0

		Tst	d2
		Beq.b	PPS_Gfx
		Add.l	20(a2),a1
		Cmp	#1,d2
		Beq.b	PPS_Msk
		Add	12(a2),a1

	PPS_Msk:Bset	d0,0(a1,d1.w)
		Tst	d7
		Bne.b	PPS_MOk
		Bclr	d0,0(a1,d1.w)
	PPS_MOk:Rts

	PPS_Gfx:Clr	d4
	PPS_Lp:	Bset	d0,28(a1,d1.w)
		Btst	d4,d7
		Bne.b	PPS_Ok
		Bclr	d0,28(a1,d1.w)
	PPS_Ok:	Add	12(a2),a1	;Add to next Bpl
		Addq	#1,d4
		Cmp	10(a2),d4	;Number of Bpls
		Bne.b	PPS_Lp
	PPS_Ed:	Rts
*---------------
Piec_Pixel_Tst:	;(D0=X, D1=Y, D7->Color, A2=Piece)
		;(D2: 0=Graphics 1=CollMask 2=BlitMask)

		Move.l	Mem_PiecBuf(pc),a2
	*-- Check Limits
CPiec_Pixel_Tst:
		Tst	d0
		Bmi.b	PPT_Lm
		Tst	d1
		Bmi.b	PPT_Lm
		Cmp	6(a2),d0	;SizeX
		Bge.b	PPT_Lm
		Cmp	8(a2),d1	;SizeY
		Bge.b	PPT_Lm

		Move.l	a2,a1
		Mulu	14(a2),d1
		Move	d0,d4
		Lsr	#3,d4
		Add	d4,d1
		Not	d0

		Moveq.l	#0,d7
		Tst	d2
		Beq.b	PPT_Gfx
		Add.l	20(a2),a1
		Cmp	#1,d2
		Beq.b	PPT_Msk
		Add	12(a2),a1

	PPT_Msk:Btst	d0,0(a1,d1.w)
		Beq.b	PPT_MOk
		Moveq.l	#1,d7
	PPT_MOk:Rts

	PPT_Gfx:Clr	d4
	PPT_Lp:	Btst	d0,28(a1,d1.w)
		Beq.b	PPT_Ok
		Bset	d4,d7
	PPT_Ok:	Add	12(a2),a1	;Add to next Bpl
		Addq	#1,d4
		Cmp	10(a2),d4	;Number of Bpls
		Bne.b	PPT_Lp
	PPT_Ed:	Rts
	PPT_Lm:	Moveq.l	#-1,d7
		Rts
*---------------
Get_Piec_LAdr:	Move.l	Mem_PiecList(pc),a2
		Clr.l	d0
		Move	Cur_Piec(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Update_PiecBuf:	Lea	Piec_Info(pc),a3
		Bra.w	Update_UnitBuf
*---------------
Piec_Trim:	Bsr.b	Get_Piec_LAdr
		Tst.l	(a2)
		Beq.w	PT_End
		Or	#2,4(a2)		;Set NeedsUpdate

		Lea	Sprite_Busy(pc),a1
		Bsr.w	Change_Sprite

		Move	Piec_Showing(pc),d2
		Bsr.b	Update_PiecBuf
		Move	#-1,TrimX
		Move	#-1,TrimY
		
	PT_Lp:	Move	TrimX(pc),d0
		Move	TrimY(pc),d1
		Bsr.w	Piec_Pixel_Tst
		Cmp	#0,d7
		Bgt.b	PT_No

		Move	TrimX(pc),d0
		Move	TrimY(pc),d1
		Subq	#1,d0
		Clr	d7
		Bsr.w	Piec_Pixel_Set
		
		Move	TrimX(pc),d0
		Move	TrimY(pc),d1
		Addq	#1,d0
		Clr	d7
		Bsr.w	Piec_Pixel_Set
		
		Move	TrimX(pc),d0
		Move	TrimY(pc),d1
		Subq	#1,d1
		Clr	d7
		Bsr.w	Piec_Pixel_Set
		
		Move	TrimX(pc),d0
		Move	TrimY(pc),d1
		Addq	#1,d1
		Clr	d7
		Bsr.w	Piec_Pixel_Set

	PT_No:	Move.l	Mem_PiecBuf(pc),a2

		Addq	#1,TrimX
		Move	6(a2),d0
		Addq	#1,d0
		Cmp	TrimX(pc),d0
		Bgt.b	PT_Lp

		Move	#-1,TrimX
		Addq	#1,TrimY
		Move	8(a2),d0
		Addq	#1,d0
		Cmp	TrimY(pc),d0
		Bgt.w	PT_Lp

		Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bsr.w	Draw_All

	PT_End:	Rts

TrimX:		Dc	0
TrimY:		Dc	0
*---------------
Piec_FlipY:	Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)
		Beq.b	PFY_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	Sprite_Busy(pc),a1
		Bsr.w	Change_Sprite
		Bsr.w	Update_PiecBuf
		Bsr.w	Get_Piec_LAdr
		Move.l	(a2),a2
		Move.l	Mem_PiecBuf(pc),a3
		Move.l	a2,a4
		Move	10(a2),d7	;Depth
		Addq	#1,d7
		Add	#28,a3		;Header
		Add	#28,a4		;Header
	PFY_DLp:Add	12(a2),a3	;BplSize
		Move	8(a2),d1	;YSize
	PFY_LLp:Sub	14(a2),a3	;ByteWidth
		Move	14(a2),d0
	PFY_WLp:Move	(a3)+,(a4)+
		Subq	#2,d0
		Bgt.b	PFY_WLp
		Sub	14(a2),a3	;ByteWidth
		Subq	#1,d1
		Bne.b	PFY_LLp
		Add	12(a2),a3	;BplSize
		Dbf	d7,PFY_DLp
		Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bsr.w	Draw_All
	PFY_End:Rts
*---------------
Piec_FlipX:	Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)
		Beq.b	PFX_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	Sprite_Busy(pc),a1
		Bsr.w	Change_Sprite
		Bsr.w	Update_PiecBuf
		Bsr.w	Get_Piec_LAdr
		Move.l	(a2),a2

		Clr	d1		;Forward Counter
		Move	6(a2),d2	;Backward Counter
		Subq	#1,d2

	PFX_XLp:Move	10(a2),d0	;Calc Total Y Size
		Addq	#2,d0		;+
		Mulu	8(a2),d0	;+

		Move.l	Mem_PiecBuf(pc),a3
		Move.l	a2,a4
		Add	#28,a3		;Header
		Add	#28,a4		;Header

		Move	d1,d4
		Lsr	#3,d4
		Add	d4,a3
		Move	d2,d5
		Lsr	#3,d5
		Add	d5,a4

		Move	d1,d4
		Not	d4
		And	#$7,d4
		Move	d2,d5
		Not	d5
		And	#$7,d5

		Move	14(a2),d6
	PFX_YLp:Bclr	d5,(a4)
		Btst	d4,(a3)
		Beq.b	PFX_NoB
		Bset	d5,(a4)
	PFX_NoB:Add	d6,a3
		Add	d6,a4

		Subq	#1,d0
		Bne.b	PFX_YLp

		Addq	#1,d1
		Subq	#1,d2
		Bpl.b	PFX_XLp

		Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bsr.w	Draw_All
	PFX_End:Rts
*---------------
Piec_CopyShadow:;(D2: 1=From Col to Blt  2=From Blt to Col)
		Lea	Piec_Info(pc),a3
		Bsr.w	Update_UnitBuf
		Move	Piec_Showing(pc),d2
		Beq.b	PCS_End
		Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)
		Beq.b	PCS_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a2
		Move.l	a2,a0
		Move.l	a2,a1
		Add.l	20(a2),a0
		Add.l	24(a2),a1
		Cmp	#1,d2
		Bne.b	PCS_2
		Exg.l	a0,a1
	PCS_2:	Move	12(a2),d0
	PCS_Lp:	Move.b	(a0)+,(a1)+
		Subq	#1,d0
		Bne.b	PCS_Lp

		Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bsr.w	Draw_All

	PCS_End:Rts
*---------------
Piec_Undo:	Lea	Piec_Info(pc),a3
		Bsr.w	Unit_Undo

		Lea	Piec_GfxUpd(pc),a4
		Lea	PiecLay(pc),a5
		Bra.w	Draw_All
*---------------
Upd_PiecColl:	Lea	GPiec_Coll(pc),a0
		Lea	Im_Blank-Im,a3		;###
		Bsr.w	Get_Piec_LAdr
		Move.l	(a2),a2
		Tst	18(a2)
		Bpl.b	UPC_Yes
		Lea	Im_Check5-Im,a3		;###
	UPC_Yes:Move	a3,32(a0)
		Rts
*---------------
Piec_Collision:	Bsr.b	CheckMark5
		Move	#$8000,d3
		Tst	d7
		Bne.b	PC_No
		Clr	d3
	PC_No:	Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)
		Beq.b	PC_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),d1
		Beq.b	PC_Ed
		Move.l	d1,a2
		Move	d3,18(a2)
	PC_Ed:	Rts
*---------------
CheckMark5:	Move.l	HitGd(pc),a4
		Move.l	a4,a0
		Lea	Im_Blank-Im,a2	;###
		Clr	CM5_Flg
		Lea	Im_Check5-Im,a1	;###
		Cmp	32(a0),a1
		Beq.b	CM5_Yes
		Move.l	a1,a2
		Move	#1,CM5_Flg
	CM5_Yes:Move	a2,32(a0)
		Move.l	LayL(pc),a5
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Move	CM5_Flg(pc),d7
		Rts
	CM5_Flg:Dc	0
*---------------
Draw_Piece:
	*-- Find current piece, and check if it exists
		Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)		;Any Piece?
		Beq.w	DP_End		;No
		Move.l	(a2),a2		;Get PieceData Address
	*-- Write stuff to Piec_BM
		Lea	Piec_BM(pc),a1
		Move	14(a2),(a1)+		;Write BytWidth to BM
		Move	08(a2),(a1)+		;Write SizeY to BM
		Move	10(a2),(a1)+		;Write Depth to BM
		Clr	(a1)+
		Move.l	a2,a0
		Add	#28,a0
		Move	10(a2),d0
		Subq	#1,d0
	DP_BplL:Move.l	a0,(a1)+
		Add	12(a2),a0		;Add BplSize
		Dbf	d0,DP_BplL
	*-- Check if piece is within frame
		Lea	PiecLay(pc),a5
		Lea	Piec_GfxArea(pc),a4
		Bsr.w	Calc_Coord

		Move	6(a2),d4	;SizeX
		Move	8(a2),d5	;SizeY

		Move	X1(pc),d2
		Addq	#3,d2
		Move	d2,d0
		Add	6(a2),d0
		Addq	#2,d0
		Sub	X2(pc),d0
		Blt.b	DP_NOvX
		Move	X2(pc),d4
		Sub	X1(pc),d4
		Subq	#5,d4
		Moveq.l	#-2,d0
	DP_NOvX:Addq	#2,d0
		Asr	#1,d0
		Sub	d0,d2

		Move	Y1(pc),d3
		Addq	#3,d3
		Move	d3,d1
		Add	8(a2),d1
		Addq	#2,d1
		Sub	Y2(pc),d1
		Blt.b	DP_NOvY
		Move	Y2(pc),d5
		Sub	Y1(pc),d5
		Subq	#5,d5
		Moveq.l	#-2,d1
	DP_NOvY:Addq	#2,d1
		Asr	#1,d1
		Sub	d1,d3

		Move	d2,Piec_XLayPos
		Move	d3,Piec_YLayPos

		Lea	PiecLay(pc),a5
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move	Piec_Showing(pc),d0	;Graphics?
		Beq.b	DP_NMsk
	*-- Get Mask address
	DP_Msk:	Move.l	a2,a0
		Add.l	24(a2),a0
		
		Move	Piec_Showing(pc),d0
		Cmp	#1,d0			;BltMsk?
		Bne.b	DP_NAdC
		Sub	12(a2),a0		;BplSize
	DP_NAdC:
		Lea	Piec_BM(pc),a1
		Move.l	a0,8(a1)
		Move.b	#1,5(a1)
	DP_NMsk:
		Lea	GPiecZoom(pc),a0
		Btst	#0,4(a0)
		Bne.b	DP_Zoom

		Move	Piec_Showing(pc),d0	;Graphics?
		Bne.w	DP_Mask
	*-- Blit Piece
		Lea	Piec_BM(pc),a0
		Move.l	a3,a1
		Move	#$c0,d6		;Minterm
		Moveq.l	#0,d0		;OffsetX
		Moveq.l	#0,d1		;OffsetY
		Jsr	BltBitMapRastPort(a6)
	DP_End:	Rts

	DP_Zoom:Lea	Piec_BM(pc),a0
		Move.l	a0,Z_SrcBM
		Clr	Z_SrcX
		Clr	Z_SrcY
		Move	Piec_ZFact(pc),Z_Factor
		Lea	PiecLay(pc),a5
		Move.l	(a5),a1
		Move.l	12(a1),a1
		Move.l	a1,Z_DstRP
		Addq	#3,X1
		Addq	#3,Y1
		Subq	#3,X2
		Subq	#3,Y2
		Move	6(a2),Z_Width
		Lea	Zoom_BM(pc),a4
		Move.l	a4,Z_DstBM
		Bsr.w	Zoom

		Move	Piec_Showing(pc),d0	;Graphics?
		Bne.b	DP_ZMsk
	*-- Blit zoomed gfx to screen
		Lea	Zoom_BM(pc),a0
		Move.l	a0,BG_SrcBM
		Clr	BG_SrcX
		Clr	BG_SrcY
		Move.l	Z_DstRP(pc),a1
		Bsr.w	Blit_Gfx
		Bra.w	Free_Zoom

	DP_ZMsk:
	*-- Blit zoomed gfx to screen
		Lea	Zoom_BM(pc),a0
		Move.l	a0,BG_SrcBM
		Clr	BG_SrcX
		Clr	BG_SrcY
		Move.l	Z_DstRP(pc),a1
		Bsr.w	Blit_Msk
		Bra.w	Free_Zoom
	*-- Blit mask
	DP_Mask:Move.l	a3,a1
		Move	MdCol(pc),d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	LoCol(pc),d0
		Jsr	SetBPen(a6)
		Move.l	a3,a1
		Moveq.l	#1,d0
		Jsr	SetDrMd(a6)
		Lea	Piec_BM(pc),a1
		Move.l	8(a1),a0		;Get Mask address
		Clr.l	d0
		Move	14(a2),d1	;BytWidth
		Move.l	a3,a1
		Jmp	BltTemplate(a6)

Piec_XLayPos:	Dc	0
Piec_YLayPos:	Dc	0
*---------------
Check_Piece:	Lea	Piec_Jump(pc),a0
		Move	PiecList_Len(pc),d0
		Beq.b	CP_NoUn
	*-- Find current piece, and check if it exists
		Bsr.w	Get_Piec_LAdr
		Tst.l	(a2)		;Any Piece?
		Beq.b	CP_NoGr		;No
		Lea	Piec_Gfx(pc),a1
		Move.l	a1,(a0)
		Rts

	CP_NoUn:Lea	Piec_NoUnit(pc),a1
		Move.l	a1,(a0)
		Rts
	CP_NoGr:Lea	Piec_NoGfx(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_Piec:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Piece8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Piec_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im
		
		Dc	'GD'
		Dc.l	$02010010,0,Piec_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Piec_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'GD'
		Dc.l	$02010016,0,Piec_Draw
		Dc	'BX',046,013,058,025
		Dc	'IM',048,015,9,Im_Draw-Im

		Dc	'GD'
		Dc.l	$02010017,0,Piec_CalcShadow
		Dc	'BX',063,013,075,025
		Dc	'IM',065,015,9,Im_Calculate-Im

		Dc	'GD'
		Dc.l	$02010018,0,Piec_CopyShadow
		Dc	'BX',076,013,088,025
		Dc	'IM',078,015,9,Im_Equal-Im

		Dc	'GD'
		Dc.l	$02010019,0,Piec_Trim
		Dc	'BX',089,013,101,025
		Dc	'IM',091,015,9,Im_Trim-Im

		Dc	'RO'
		Dc.l	Upd_PiecColl
		Dc	'BX',106,013,140,025
		Dc	'TX',109,022,-01,5
		Dc.l	CollT

GPiec_Coll:	Dc	'GD'
		Dc.l	$0201003b,0,Piec_Collision
		Dc	'BX',130,015,138,023
		Dc	'IM',132,017,5,Im_Check5-Im

		Dc	'BX',000,028,-01,040

		Dc	'RO'
		Dc.l	Upd_PiecNameD

Piec_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Piec_Name
		Dc	'RC',003,030,-24,038
		Dc	'TX',005,037,-01,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Piec_Info,Unit_BrowseUp
		Dc	'BX',-21,030,-13,038
		Dc	'IM',-19,033,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Piec_Info,Unit_BrowseDn
		Dc	'BX',-12,030,-04,038
		Dc	'IM',-10,033,3,Im_DArr-Im

		Dc	'BX',000,041,-01,057

GPiecGfx:	Dc	'GD'
		Dc.l	$0201071b,Piec_Mask_Excl,Piec_Graphics
		Dc	'BX',003,043,015,055
		Dc	'IM',005,045,9,Im_Graphics-Im

GPiecBltMsk:	Dc	'GD'
		Dc.l	$0201061c,Piec_Mask_Excl,Piec_BltShadow
		Dc	'BX',016,043,028,055
		Dc	'IM',018,045,9,Im_Mask-Im

GPiecColMsk:	Dc	'GD'
		Dc.l	$0201061d,Piec_Mask_Excl,Piec_ColShadow
		Dc	'BX',029,043,041,055
		Dc	'IM',031,045,9,Im_Collision-Im

GPiecZoom:	Dc	'GD'
		Dc.l	$02010209,0,Piec_Zoom
		Dc	'BX',046,043,058,055
		Dc	'IM',048,045,9,Im_Zoom-Im

		Dc	'BX',059,043,093,055

		Dc	'GD'
		Dc.l	$02030a35,1,Piec_ZoomFactor
		Dc	'RC',062,045,071,053
Piec_ZFactUpd:	Dc	'TX',065,052,-01,5
		Dc.l	Piec_ZFactT

		Dc	'GD'
		Dc.l	$02010034,0,Piec_ZoomMinus
		Dc	'BX',074,045,082,053
		Dc	'IM',076,049,1,Im_Minus-Im
		
		Dc	'GD'
		Dc.l	$02010033,0,Piec_ZoomPlus
		Dc	'BX',083,045,091,053
		Dc	'IM',085,047,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$0201001e,0,Piec_FlipX
		Dc	'BX',098,043,110,055
		Dc	'IM',100,045,9,Im_FlipX-Im

		Dc	'GD'
		Dc.l	$0201001f,0,Piec_FlipY
		Dc	'BX',111,043,123,055
		Dc	'IM',113,045,9,Im_FlipY-Im

		Dc	'GD'
		Dc.l	$0201000b,0,Piec_Undo
		Dc	'BX',128,043,140,055
		Dc	'IM',130,045,9,Im_Undo-Im

		Dc	'GD'
		Dc.l	$02020000,PiecPropY,0
		Dc	'BX',-09,058,-01,-10
		Dc	'BX',-07,061,-03,-34

		Dc	'GD'
		Dc.l	$02020000,PiecPropX,0
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',020,-07,-40,-03

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

Piec_GfxUpd:	Dc	'RO'
		Dc.l	Check_Piece

		Dc	'JP'
Piec_Jump:	Dc.l	Piec_NoUnit

Piec_NoUnit:	Dc	'BX',000,058,-10,-10
		Dc	'TX',003,067,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Piec_NoGfx:	Dc	'BX',000,058,-10,-10
		Dc	'TX',003,067,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Piec_Load
		Dc	'BX',-37,060,-13,068
		Dc	'TX',-34,067,-01,5
		Dc.l	LoadT
		Dc	'XX'

Piec_Gfx:	Dc	'GD'
		Dc.l	$01000000,0,Piec_Piece
Piec_GfxArea:	Dc	'FR',000,058,-10,-10
		Dc	'RO'
		Dc.l	Draw_Piece
Piec_GfxDef:	Dc	'DF',003,061,-13,-13
		Dc	'XX'

PiecPropX:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
PiecPropY:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,65535		;KnobX,Y
		Dc	0,0		;PosX,Y

Piec_Mask_Excl:	Dc.l	GPiecGfx
		Dc.l	GPiecBltMsk
		Dc.l	GPiecColMsk
		Dc.l	0

Piec_ZFactT:	Dc.b	'2',0
		Even
*---------------
DrawList_Draw:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Draw8T

GDrawFreeHand:	Dc	'GD'
		Dc.l	$0201060a,Draw_Excl_1,0
		Dc	'BX',000,011,012,023
		Dc	'IM',002,013,9,Im_FreeHand-Im

GDrawFill:	Dc	'GD'
		Dc.l	$02010685,Draw_Excl_1,0
		Dc	'BX',000,024,012,036
		Dc	'IM',002,026,9,Im_Fill-Im

GDrawLine:	Dc	'GD'
		Dc.l	$02010684,Draw_Excl_1,0
		Dc	'BX',013,011,025,023
		Dc	'IM',015,013,9,Im_Line-Im

GDrawFillBox:	Dc	'GD'
		Dc.l	$0201067b,Draw_Excl_1,0
		Dc	'BX',013,024,025,036
		Dc	'IM',015,027,7,Im_FillBox-Im

		Dc	'BX',026,011,038,036

GDraw_Pixel:	Dc	'GD'
		Dc.l	$02010683,Draw_Excl_Br,0
		Dc	'DF',026,011,030,018
		Dc	'IM',028,015,1,Im_Pixel-Im

GDraw_Square1:	Dc	'GD'
		Dc.l	$02010683,Draw_Excl_Br,0
		Dc	'DF',026,019,031,027
		Dc	'IM',028,023,2,Im_Square1-Im

GDraw_Square2:	Dc	'GD'
		Dc.l	$02010683,Draw_Excl_Br,0
		Dc	'DF',026,028,031,036
		Dc	'IM',028,031,3,Im_Square2-Im

GDraw_Dot3:	Dc	'GD'
		Dc.l	$02010683,Draw_Excl_Br,0
		Dc	'DF',031,011,038,019
		Dc	'IM',032,013,5,Im_Dot3-Im

GDraw_Dot2:	Dc	'GD'
		Dc.l	$02010683,Draw_Excl_Br,0
		Dc	'DF',032,020,038,028
		Dc	'IM',033,022,4,Im_Dot2-Im

GDraw_Dot1:	Dc	'GD'
		Dc.l	$02010683,Draw_Excl_Br,0
		Dc	'DF',032,029,038,036
		Dc	'IM',034,031,3,Im_Dot1-Im

		Dc	'GD'
		Dc.l	$0100004f,0,Draw_PickColor
		Dc	'FR',039,011,051,036
		Dc	'RO'
		Dc.l	Upd_SelColor

		Dc	'FR',052,011,-01,-01
		Dc	'GD'
		Dc.l	$000000a9,0,Draw_SelectColor
		Dc	'DF',055,014,-04,-04
		Dc	'RO'
		Dc.l	Draw_Palette

		Dc	'XX'

Draw_Excl_1:	Dc.l	GDrawFreeHand
		Dc.l	GDrawLine
		Dc.l	GDrawFillBox
		Dc.l	GDrawFill
		Dc.l	0
Draw_Excl_Br:	Dc.l	GDraw_Pixel
		Dc.l	GDraw_Square1
		Dc.l	GDraw_Square2
		Dc.l	GDraw_Dot1
		Dc.l	GDraw_Dot2
		Dc.l	GDraw_Dot3
		Dc.l	0
*=======================================================================*
*			  A N I M A T I O N				*
*=======================================================================*
Anim_New:	Lea	AnimList(pc),a4
		Lea	New_Anim(pc),a2
		Bsr.w	Unit_New
		Move	d7,Cur_Anim
		Bra.w	Change_Anim
New_Anim:	Dc	0	;Id
		Dc.l	14	;BytSize
		Dc.b	1	;Frames
		Dc.b	2	;Delay
		Dc.b	0	;Control
		Dc.b	0	;Direction
		Dc	12	;FrameOffsets
		Dc.b	1	;Duration
		Dc.b	0	;Pieces
*---------------
Anim_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Anim_Delay:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	AD_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value(pc),d0
		Move.b	d0,7(a0)
		Lea	T_DelayN+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
		Lea	AnimLay(pc),a5
		Lea	Anim_DelayUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some
	AD_Ed:	Rts
*---------------
Anim_DelayPlus:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	ADP_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Addq.b	#1,7(a0)
		Cmp.b	#99,7(a0)
		Ble.b	ADP_NOv
		Move.b	#1,7(a0)
	ADP_NOv:Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
	ADP_End:Rts
*---------------
Anim_DelayMinus:Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	ADM_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Subq.b	#1,7(a0)
		Cmp.b	#1,7(a0)
		Bge.b	ADM_NUn
		Move.b	#99,7(a0)
	ADM_NUn:Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
	ADM_End:Rts
*---------------
Anim_Control:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	ACO_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a2
		Lea	8(a2),a2
		Lea	Anim_ConUpd(pc),a0
		Lea	ACO_Lst(pc),a1
		Bsr.w	Gd_Choice
	ACO_End:Rts
	ACO_Lst:Dc	Im_Loop-Im	;0
		Dc	Im_Bounce-Im	;1
		Dc	Im_Once-Im	;2
		Dc	Im_Rnd-Im	;3
		Dc	0
*---------------
Anim_Direction:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	ADI_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a2
		Lea	9(a2),a2
		Lea	Anim_DirUpd(pc),a0
		Lea	ADI_Lst(pc),a1
		Bsr.w	Gd_Choice
	ADI_End:Rts
	ADI_Lst:Dc	Im_Forward-Im	;0
		Dc	Im_Backward-Im	;1
		Dc	0
*---------------
Anim_Play:	Clr	Cur_AnimPiece

		Bsr.b	Prep_Choose_Frame
	*-- Draw and update everything
	AP_Loop:Bsr.w	Upd_PlayNumbD
		Bsr.w	Upd_PlayNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG

		Move.l	GfxBase(pc),a6
		Jsr	WaitTOF(a6)

		Bsr.w	Draw_Frame
			;Move	#$060,$dff180
	*-- Wait
		Move	CF_Delay(pc),d7
		Move.l	CF_Adr(pc),a0	;Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
		Clr	d0
		Move.b	(a1),d0
		Mulu	d0,d7
		Subq	#1,d7
	AP_Wait:
	*-- Mouse button?
		Bsr.w	Check_Left_Dn
		Bne.b	AP_End
		Subq	#1,d7
		Bmi.b	AP_WEnd
		Move.l	GfxBase(pc),a6
		Jsr	WaitTOF(a6)
		Bra.b	AP_Wait
	AP_WEnd:
		Bsr.b	Choose_Frame
		Beq.b	AP_Loop
	AP_End:	Rts
*---------------
Prep_Choose_Frame:
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	AP_End
		Move.l	(a2),a0
		Move.l	a0,CF_Adr

		Clr	d0
		Move.b	6(a0),d0
		Move	d0,CF_Total
		Clr	d0
		Move.b	7(a0),d0
		Move	d0,CF_Delay
		
		Move.b	8(a0),CF_Control
		Move.b	9(a0),CF_Direction

		Move	#1,Cur_Frame
		Move	#1,CF_Delta
		Move.b	CF_Direction(pc),d0
		Beq.b	CF_DrOk
		Move	CF_Total(pc),Cur_Frame
		Move	#-1,CF_Delta
	CF_DrOk:Rts

CF_Adr:		Dc.l	0
CF_Total:	Dc	0
CF_Delay:	Dc	0
CF_Control:	Dc.b	0
CF_Direction:	Dc.b	0
CF_Delta:	Dc	0
*---------------
Choose_Frame:	;(Choose next Anim frame)
		Cmp.b	#3,CF_Control		;Random?
		Bne.b	CF_NCn3
		Cmp	#1,CF_Total
		Beq.w	CF_End
	CF_Try:	Jsr	GetRnd	;###
		Move	Rnd,d0	;###
		Mulu	CF_Total(pc),d0
		Swap	d0
		Addq	#1,d0
		Cmp	Cur_Frame(pc),d0
		Beq.b	CF_Try
		Move	d0,Cur_Frame
		Bra.w	CF_End

	CF_NCn3:Move	Cur_Frame(pc),d0	;Last Frame?
		Cmp	CF_Total(pc),d0
		Bne.b	CF_NLst

		Move.b	CF_Control(pc),d0	;Loop?
		Bne.b	CF_NCL0
		Move.b	CF_Direction(pc),d0	;Forward?
		Bne.b	CF_NCL0
		Move	#1,Cur_Frame
		Bra.w	CF_End

	CF_NCL0:Cmp.b	#1,CF_Control		;PingPong?
		Bne.b	CF_NCL1
		Move	CF_Delta(pc),d0
		Bmi.b	CF_Nxt
		Neg	CF_Delta
		Bra.b	CF_Nxt

	CF_NCL1:Cmp.b	#2,CF_Control		;Once?
		Bne.b	CF_NCL2
		Move.b	CF_Direction(pc),d0	;Forward?
		Beq.b	CF_Quit

	CF_NCL2:Bra.b	CF_N1st

	CF_NLst:Cmp	#1,Cur_Frame		;First Frame?
		Bne.b	CF_N1st

		Move.b	CF_Control(pc),d0	;Loop?
		Bne.b	CF_NCF0
		Cmp.b	#1,CF_Direction
		Bne.b	CF_NCF0
		Move	CF_Total(pc),Cur_Frame
		Bra.b	CF_End

	CF_NCF0:Cmp.b	#1,CF_Control		;PingPong?
		Bne.b	CF_NCF1
		Move	CF_Delta(pc),d0
		Bpl.b	CF_Nxt
		Neg	CF_Delta
		Bra.b	CF_Nxt

	CF_NCF1:Cmp.b	#2,CF_Control		;Once?
		Bne.b	CF_NCF2
		Move.b	CF_Direction(pc),d0	;Backward?
		Bne.b	CF_Quit
	CF_NCF2:
	CF_N1st:
	CF_Nxt:	Move	CF_Delta(pc),d0
		Add	d0,Cur_Frame

	CF_End:	Moveq.l	#0,d0
		Rts
	CF_Quit:Moveq.l	#-1,d0
		Rts
*---------------
Anim_PlayScreen:Jsr	Get_Screen_Mem
		Jsr	Get_Bob_Mem
	*-- Fill in test object
		Bsr.w	Find_Object_Vacancy
		Move	#$8000,(a5)
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	APS_NAn
		Move.l	(a2),a0
		Bsr.b	Prep_Object_Anim
		Move	#32767,40(a5)

	APS_NAn:Clr	GM_OutCnt

		Jsr	Erase
		Move	#'AN',Play_Mode
		Jsr	Leave_Dos	;###
		Jsr	Chip		;Feed Custom Chips ###
		Jsr	Game_Palette	;###

	APS_M1:	Jsr	Game_Background	;###
		Btst	#6,$bfe001
		Bne.b	APS_M1

	APS_M3:	Moveq.l	#127,d0
	APS_M2:	Btst	#6,$bfe001
		Beq.b	APS_M3
		Dbf	d0,APS_M2

		Jsr	Enter_Dos	;###
		Jsr	Free_Play_Mem
	APS_End:Rts
*---------------
Prep_Object_Anim:	;(A5=ObjectListAdr, A0=AnimAdr)
		Move.l	a0,16(a5)	;GraphicsPtr
		Bset	#1,1(a5)	;Set Animation bit.
		Clr	d0
		Move.b	6(a0),d0
		Move	d0,28(a5)	;AnimTotal
		Clr	d0
		Move.b	7(a0),d0
		Move	d0,30(a5)	;AnimDelay
		Move.b	8(a0),32(a5)	;AnimCon
		Move.b	9(a0),33(a5)	;AnimDir
		Move	#1,36(a5)	;AnimFrame
		Move	#1,34(a5)	;AnimDelta
		Move.b	33(a5),d0	;Check AnimDir
		Beq.b	POA_DOk
		Move	28(a5),36(a5)	;AnimFrame=AnimTotal
		Move	#-1,34(a5)	;AnimDelta
	POA_DOk:Clr	38(a5)		;AnimTimer=0
		Cmp.b	#3,32(a5)
		Bne.b	POA_NRn
		Bsr.w	GetRnd
		Move	Rnd(pc),d0
		Mulu	28(a5),d0	;Rnd*AnimTotal
		Swap	d0
		Addq	#1,d0
		Move	d0,36(a5)
	POA_NRn:
	*-- Get WaitValue
		Move	30(a5),d7	;AnimDelay
		Move	36(a5),d0	;AnimFrame
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
		Clr	d0
		Move.b	(a1),d0
		Mulu	d0,d7
		Subq	#1,d7
		Move	d7,38(a5)
		Rts
*---------------
Find_Object_Vacancy:	;(A5->ObjectListAdr)
		Move.l	Mem_Objects(pc),a5
		Moveq.l	#64,d7
	FOV_Lp:	Move	(a5),d0
		Bpl.b	FOV_Yes
		Add	#256,a5
		Subq	#1,d7
		Bne.b	FOV_Lp
		Sub.l	a5,a5
	FOV_Yes:Rts
*---------------
Anim_PrevFrame:	Subq	#1,Cur_Frame
		Bsr.w	BP_Rem
		Move	#-1,LX
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bra.w	Draw_Frame
*---------------
Anim_NextFrame:	Addq	#1,Cur_Frame
		Bsr.w	BP_Rem
		Move	#-1,LX
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bra.w	Draw_Frame
*---------------
Anim_ToStart:	Move	#1,Cur_Frame
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bra.w	Draw_Frame
*---------------
Anim_ToEnd:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	ATE_End
		Move.l	(a2),a3
		Move.b	6(a3),d0	;Total
		Ext	d0
		Move	d0,Cur_Frame
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bsr.w	Draw_Frame
	ATE_End:Rts
*---------------
Anim_Frame:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	AF_Ed
		Move.l	(a2),a0
		Move.l	Convert_Value(pc),d0
		Move	d0,Cur_Frame
		Bsr.w	BP_Rem
		Move	#-1,LX
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bsr.w	Draw_Frame
	AF_Ed:	Rts
*---------------
Anim_FrameProp:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	AFP_End
	*-- Read prop and calculate frame number
		Move.l	(a2),a3
		Lea	FrameProp(pc),a0
		Clr.l	d0
		Move	6(a0),d0
		Clr.l	d1
		Move	2(a0),d1
		Lsr	#1,d1
		Add.l	d1,d0
		Clr	d2
		Move.b	6(a3),d2	;Get Total
		Mulu	d2,d0
		Divu	#65535,d0
		Addq	#1,d0
		Move	d0,Cur_Frame
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Draw_Frame
	AFP_End:Rts
*---------------
Anim_RepeatMinus:
		Moveq.l	#-1,d7
		Bra.b	AR_Comn
*---------------
Anim_RepeatPlus:Moveq.l	#1,d7
	AR_Comn:Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	AR_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
	*-- Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Add and check
		Add.b	d7,(a1)
		Cmp.b	#1,(a1)
		Bge.b	AR_NUn
		Move.b	#99,(a1)
	AR_NUn:	Cmp.b	#99,(a1)
		Ble.b	AR_NOv
		Move.b	#1,(a1)
	AR_NOv:
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
	AR_End:	Rts
*---------------
Anim_Repeat:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	AR_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
	*-- Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
		Move.l	Convert_Value(pc),d0
		Move.b	d0,(a1)
		Lea	T_RepeatN+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
		Lea	AnimLay(pc),a5
		Lea	Anim_RepeatUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some
	AR_Ed:	Rts
*---------------
Anim_Total:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	AT_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value(pc),d0
		Move.b	d0,d1
		Move.b	d0,AD_Tot
		Sub.b	6(a0),d1
		Beq.b	AD_No
		Bmi.b	AD_Mi
		Ext.w	d1
		Move	d1,AAF_Amount
		Bsr.b	AAF_Com
		Bra.b	AD_No
	AD_Mi:	Ext.w	d1
		Neg	d1
		Move	d1,ADF_Amount
		Bsr.w	ADF_Com
	AD_No:	Bsr.w	Get_Anim_LAdr
		Move.l	(a2),a0
		Move.b	AD_Tot(pc),d0
		Move.b	d0,6(a0)
		Lea	T_TotalN+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
		Lea	AnimLay(pc),a5
		Lea	Anim_TotalUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some
	AT_Ed:	Rts
	AD_Tot:	Dc	0
*---------------
Anim_AddFrame:	Move	#1,AAF_Amount
	AAF_Com:
	*-- Get list address (A2)
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.w	AAF_End
		Move.l	a2,AAF_ListAdr
		Bsr.w	Update_AnimBuf
	*-- Find Frame (A1->Address)
		Move.l	Mem_AnimBuf(pc),a0
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1

		Clr	d0		;Get number of Pieces	
		Move.b	1(a1),d0	;+
		Lsl	#3,d0		;8 bytes per Piece
		Addq	#2,d0		;Plus 2 for Repeat & Pieces
		Move	d0,AAF_FrameAdd
		Addq	#2,d0		;Plus 2 for FrameOffset
		Mulu	AAF_Amount(pc),d0	;* Number of copies
		Move	d0,AAF_BytesAdd
		Move	AAF_Amount(pc),d0
		Add	d0,d0		;2 bytes per FrameOffset
		Move	d0,AAF_OffstAdd
	*-- Free old Anim
		Move.l	AAF_ListAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Anim
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0
		Add	AAF_BytesAdd(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	AAF_ListAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_MemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Anim address
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	AAF_BytesAdd(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Clr	d7			;Total
		Move.b	(a2)+,d7		;+
		Add	AAF_Amount(pc),d7	;+
		Move.b	d7,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Delay
		Move	(a2)+,(a1)+		;Control, Direction
	*-- Copy FrameOffsets
		Move	AAF_OffstAdd(pc),d1
		Clr	d0
	AAF_LFO:Move	(a2)+,d2
		Add	d1,d2
		Move	d2,(a1)+
		Addq	#1,d0
		Cmp	Cur_Frame(pc),d0
		Bne.b	AAF_NoF

		Move	AAF_Amount(pc),d3
	AAF_LIO:Add	AAF_FrameAdd(pc),d2
		Move	d2,(a1)+
		Addq	#1,d0
		Subq	#1,d3
		Bne.b	AAF_LIO
		Move	AAF_BytesAdd(pc),d1
	AAF_NoF:Cmp	d7,d0
		Bne.b	AAF_LFO
	*-- Copy from start to edit point
		Moveq.l	#1,d6
	AAF_C2L:Cmp	Cur_Frame(pc),d6
		Beq.b	AAF_C2E
		
		Move.b	(a2)+,(a1)+		;Repeat
		Move.b	(a2)+,d0		;Pieces
		Move.b	d0,(a1)+		;+
	AAF_C1L:Tst.b	d0
		Beq.b	AAF_C1E
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Subq.b	#1,d0			;Count number of Pieces
		Bra.b	AAF_C1L			;Loop

	AAF_C1E:Addq	#1,d6			;Count Frames
		Bra.b	AAF_C2L			;Loop
	*-- Add Frames
	AAF_C2E:Move	AAF_Amount(pc),d3
	AAF_C3L:Addq	#1,d6
		Clr	d0
	AAF_C6L:Move.b	0(a2,d0.w),(a1)+
		Addq	#1,d0
		Cmp	AAF_FrameAdd(pc),d0
		Bne.b	AAF_C6L

		Dbf	d3,AAF_C3L
		Add	AAF_FrameAdd(pc),a2
	*-- Copy from edit point to end
	AAF_C4L:Cmp	d7,d6			;Count>Total?
		Bgt.b	AAF_C4E			;Yes, end
		
		Move.b	(a2)+,(a1)+		;Repeat
		Move.b	(a2)+,d0		;Pieces
		Move.b	d0,(a1)+		;+
	AAF_C5L:Tst.b	d0
		Beq.b	AAF_C5E
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Subq.b	#1,d0			;Count number of Pieces
		Bra.b	AAF_C5L			;Loop

	AAF_C5E:Addq	#1,d6			;Count Frames
		Bra.b	AAF_C4L			;Loop
	AAF_C4E:
		Bsr.w	Get_Anim_LAdr
		Move.l	(a2),a0
		Cmp.b	#99,6(a0)
		Ble.b	AAF_NOv
		Move.b	#99,6(a0)
	AAF_NOv:
		Addq	#1,Cur_Frame
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bsr.w	Draw_Frame
	AAF_End:Rts
AAF_ListAdr:	Dc.l	0
AAF_Amount:	Dc	0
AAF_FrameAdd:	Dc	0
AAF_BytesAdd:	Dc	0
AAF_OffstAdd:	Dc	0
*---------------
Anim_DelFrame:	Move	#1,ADF_Amount

	ADF_Com:Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.w	ADF_End
		Move.l	a2,ADF_ListAdr

		Move.l	(a2),a0
		Clr	d0
		Move.b	6(a0),d0
		Sub	ADF_Amount(pc),d0
		Cmp	#1,d0
		Blt.w	ADF_End

		Bsr.w	Update_AnimBuf

		Move.l	ADF_ListAdr(pc),a0
		Move.l	(a0),a0
	*-- Find out how many bytes shorter anim will be
		Clr	d7			;ByteCnt
		Clr	d4			;DeleteFrameCnt
		Move	Cur_Frame(pc),d3	;FrameCnt
	*-- Find Frame (A1->Address)
	ADF_SLp:Move.l	Mem_AnimBuf(pc),a0
		Move	d3,d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1

		Clr	d6			;Get number of Pieces
		Move.b	1(a1),d6		;+
		Lsl	#3,d6			;* 8 bytes per Piece
		Addq	#2,d6			;+ 2 for Repeat & Pieces
		Addq	#2,d6			;+ 2 for FrameOffset
		Add	d6,d7
		
		Addq	#1,d3
		Move.l	Mem_AnimBuf(pc),a0
		Cmp.b	6(a0),d3		;Total
		Ble.b	ADF_NOv
		Moveq.l	#1,d3
	ADF_NOv:
		Addq	#1,d4
		Cmp	ADF_Amount(pc),d4
		Bne.b	ADF_SLp

		Move	d7,ADF_BytesSub
	*-- Free old Anim
		Move.l	ADF_ListAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Anim
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0
		Sub	ADF_BytesSub(pc),d0
		Moveq.l	#0,d1		;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	ADF_ListAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Anim address
		Move.l	a1,ADF_AdrCnt
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub	ADF_BytesSub(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Clr	d7			;Total
		Move.b	(a2)+,d7		;+
		Sub	ADF_Amount(pc),d7	;+
		Move.b	d7,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Delay
		Move	(a2)+,(a1)+		;Control, Direction
	*-- Skip X bytes for FrameOffsets
		Move.l	a1,a3	;Save start address for FrameOffsets
		Add	d7,d7	;Total*2
		Add	d7,a1

		Clr	d4
		Moveq.l	#1,d7	;FrameCounter
		
		Clr	ADF_LoopFlg
		Move.l	Mem_AnimBuf(pc),a0	;Get buffer address
		Clr	d0
		Move.b	6(a0),d0		;Total Frames
		Sub	Cur_Frame(pc),d0	;Minus Current Frame
		Addq	#1,d0			;Plus 1 = Frames Left
		Sub	ADF_Amount(pc),d0	;Do we have to loop?
		Bpl.b	ADF_NLp			;No
		Move	#1,ADF_LoopFlg		;Yes, set flag
		Neg	d0
		Move	d0,d7
		Addq	#1,d7
	ADF_NLp:
	ADF_CLp:
	*-- Have we reached current frame (which should be deleted)
		Cmp	Cur_Frame(pc),d7
		Bne.b	ADF_NCu
		Add	ADF_Amount(pc),d7	;Skip frames to delete
	ADF_NCu:
	*-- Find Frame (A2->Address)
		Move.l	Mem_AnimBuf(pc),a0
		Move	d7,d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a2

		Move.l	a1,d0
		Sub.l	ADF_AdrCnt(pc),d0
		Move	d0,(a3)+
	*-- Copy frame
		Move.b	(a2)+,(a1)+		;Repeat
		Move.b	(a2)+,d0		;Pieces
		Move.b	d0,(a1)+		;+
	ADF_C1L:Tst.b	d0
		Beq.b	ADF_C1E
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Subq.b	#1,d0			;Count number of Pieces
		Bra.b	ADF_C1L			;Loop
	ADF_C1E:
		Addq	#1,d7

		Addq	#1,d4
		Move.l	ADF_ListAdr(pc),a0
		Move.l	(a0),a0
		Cmp.b	6(a0),d4
		Bne.b	ADF_CLp
	*-- Select current frame
		Move	Cur_Frame(pc),d7

		Move.l	ADF_ListAdr(pc),a0
		Move.l	(a0),a0
		Cmp.b	6(a0),d7	;Total
		Ble.b	ADF_SCF
		Moveq.l	#1,d7
	ADF_SCF:Move	d7,Cur_Frame

		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bsr.w	Draw_Frame
	ADF_End:Rts
ADF_AdrCnt:	Dc.l	0
ADF_ListAdr:	Dc.l	0
ADF_Amount:	Dc	0
ADF_BytesSub:	Dc	0
ADF_LoopFlg:	Dc	0
*---------------
Anim_PiecePick:	Lea	GAnim_Pick(pc),a0
		Btst	#0,4(a0)	;Button up?
		Bne.b	APP_End
		Clr	Cur_AnimPiece
	APP_End:Bra.w	Draw_Frame
*---------------
Anim_PieceDel:
	*-- Get list address (A2)
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.w	APD_End
		Move.l	a2,APD_LAdr

		Move.l	(a2),a0
	*-- Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
		Move.b	1(a1),d0	;Any Pieces in current frame?
		Beq.w	APD_End		;No
		Move	Cur_AnimPiece(pc),d0	;Any Piece selected?
		Beq.w	APD_End		;No
		Cmp.b	1(a1),d0	;CurrentPiece > TotalPieces?
		Bgt.w	APD_End		;Yes

		Bsr.w	Update_AnimBuf
	*-- Free old Anim
		Move.l	APD_LAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Anim
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get BytSize
		Subq.l	#8,d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	APD_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Anim address
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Subq.l	#8,d0
		Move.l	d0,(a1)+		;+
		Clr	d7			;Total
		Move.b	(a2)+,d7		;+
		Move.b	d7,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Delay
		Move	(a2)+,(a1)+		;Control, Direction
	*-- Copy FrameOffsets
		Clr	d1
		Clr	d0
	APD_LFO:Move	(a2)+,d2
		Sub	d1,d2
		Move	d2,(a1)+
		Addq	#1,d0
		Cmp	Cur_Frame(pc),d0
		Bne.b	APD_NoF
		Moveq.l	#8,d1
	APD_NoF:Cmp	d7,d0
		Bne.b	APD_LFO
	*-- Copy from start to end
		Moveq.l	#1,d6
	APD_C2L:Cmp	d7,d6			;Count>Total?
		Bgt.b	APD_C2E			;Yes, end

		Move.b	(a2)+,(a1)+		;Repeat
		Move.b	(a2)+,d0		;Pieces
		Move.b	d0,d5
		Cmp	Cur_Frame(pc),d6	;Is this current Frame?
		Bne.b	APD_NSb			;No
		Subq.b	#1,d0			;Minus 1 Piece
	APD_NSb:Move.b	d0,(a1)+

		Clr	d2			;Clear Piece Counter
	APD_C1L:Tst.b	d5
		Beq.b	APD_C1E

		Addq	#1,d2			;Count Pieces
		Move.l	(a2)+,d3		;Piecedata
		Move.l	(a2)+,d4		;+
		Cmp	Cur_Frame(pc),d6	;Is this current Frame?
		Bne.b	APD_Ski			;No
		Cmp	Cur_AnimPiece(pc),d2	;Is this current Piece?
		Beq.b	APD_SkP			;Yes, skip copy

	APD_Ski:Move.l	d3,(a1)+
		Move.l	d4,(a1)+
	APD_SkP:Subq.b	#1,d5			;Count number of Pieces.
		Bra.b	APD_C1L			;Loop

	APD_C1E:Addq	#1,d6			;Count Frames
		Bra.b	APD_C2L			;Loop
	APD_C2E:Clr	Cur_AnimPiece
		Bsr.w	Draw_Frame
	APD_End:Clr	Cur_AnimPiece
		Rts
APD_LAdr:	Dc.l	0
Cur_AnimPiece:	Dc	0
*---------------
Anim_Origo:	Bsr.w	Draw_Origo
		Bra.w	Anim_PiecePick
*---------------
Anim_Coll:	Bsr.w	Draw_Frame
		Bra.w	Anim_PiecePick
*---------------
Anim_Undo:	Lea	Anim_Info(pc),a3
		Bsr.w	Unit_Undo
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bra.w	Draw_Frame
*---------------
Anim_OffsetX:	Rts
*---------------
Anim_OffsetY:	Rts
*---------------
Anim_Anim:
	*-- Are we moving Origo?
		Lea	GAnim_Origo(pc),a0
		Btst	#0,4(a0)
		Bne.w	MoveOrigo
	*-- Are we picking a Piece?
		Lea	GAnim_Pick(pc),a0
		Btst	#0,4(a0)
		Bne.w	PickPiece
	*-- Are we editing Collision?
		Lea	GAnim_Coll(pc),a0
		Btst	#0,4(a0)
		Bne.w	PickPiece
	*-- Get list address (A2)
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.w	AA_End
		Move.l	a2,AA_LAdr
		Bsr.w	Update_AnimBuf
	*-- Free old Anim
		Move.l	AA_LAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Anim
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get BytSize
		Addq.l	#8,d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	AA_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Anim address
		Move.l	Mem_AnimBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Addq.l	#8,d0
		Move.l	d0,(a1)+		;+
		Clr	d7			;Total
		Move.b	(a2)+,d7		;+
		Move.b	d7,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Delay
		Move	(a2)+,(a1)+		;Control, Direction
	*-- Copy FrameOffsets
		Clr	d1
		Clr	d0
	AA_LFO:	Move	(a2)+,d2
		Add	d1,d2
		Move	d2,(a1)+
		Addq	#1,d0
		Cmp	Cur_Frame(pc),d0
		Bne.b	AA_NoF
		Moveq.l	#8,d1
	AA_NoF:	Cmp	d7,d0
		Bne.b	AA_LFO
	*-- Copy from start to edit point
		Moveq.l	#1,d6
	AA_C2L:	Cmp	Cur_Frame(pc),d6
		Beq.b	AA_C2E
		
		Move.b	(a2)+,(a1)+		;Repeat
		Move.b	(a2)+,d0		;Pieces
		Move.b	d0,(a1)+		;+
	AA_C1L:	Tst.b	d0
		Beq.b	AA_C1E
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Subq.b	#1,d0			;Count number of Pieces.
		Bra.b	AA_C1L			;Loop

	AA_C1E:	Addq	#1,d6			;Count Frames
		Bra.b	AA_C2L			;Loop
	*-- Add Piece
	AA_C2E:	Move.b	(a2)+,(a1)+		;Repeat
		Move.b	(a2)+,d0		;Pieces
		Addq.b	#1,d0			;+ Add one Piece
		Move.b	d0,(a1)+		;+
		Subq.b	#1,d0
		
	AA_C3L:	Tst.b	d0
		Beq.b	AA_C3E
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Subq.b	#1,d0			;Count number of Pieces
		Bra.b	AA_C3L			;Loop
	AA_C3E:
		Move	Cur_Piec(pc),(a1)+	;Piece
		Move	BP_X(pc),d2		;X-Offset
		Sub	#87,d2			;+
		Sub	DF_OrigoX(pc),d2	;+
		Move	d2,(a1)+		;+
		Move	BP_Y(pc),d2		;Y-Offset
		Sub	#31,d2			;+
		Sub	DF_OrigoY(pc),d2	;+
		Move	d2,(a1)+		;+
	*-- Find current piece, and check if it exists
		Move	Cur_Piec(pc),d2
		Move.l	Mem_PiecList(pc),a3
		Ext.l	d2
		Lsl.l	#5,d2		;Multiply by 32		
		Add.l	d2,a3
		Move.l	(a3),a3		;Get PieceData Address
		Move.b	18(a3),d2	;Flags
	*-- Flip Y ?
		Bclr	#5,d2
		Lea	GAnim_FlipY(pc),a0
		Btst	#0,4(a0)
		Beq.b	AA_NFlY
		Bset	#5,d2
	AA_NFlY:
		Move.b	d2,(a1)+	
		Move.b	19(a3),(a1)+
	*-- Copy from edit point to end
		Addq	#1,d6
	AA_C4L:	Cmp	d7,d6			;Count>Total?
		Bgt.b	AA_C4E			;Yes, end
		
		Move.b	(a2)+,(a1)+		;Repeat
		Move.b	(a2)+,d0		;Pieces
		Move.b	d0,(a1)+		;+
	AA_C5L:	Tst.b	d0
		Beq.b	AA_C5E
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Subq.b	#1,d0			;Count number of Pieces
		Bra.b	AA_C5L			;Loop

	AA_C5E:	Addq	#1,d6			;Count Frames
		Bra.b	AA_C4L			;Loop
	AA_C4E:
	*-- Drop Piece bob
		Lea	Mem_SaveBack(pc),a5
		Bsr.w	Free_Mem
		Clr	BP_SaveFlg
	AA_End:	Rts
	AA_LAdr:Dc.l	0
*---------------
Anim_Load:	Bsr.w	Get_Anim_LAdr
		Move.l	(a2),d0
		Bne.b	AL_Ed
		Move.l	AnimList(pc),a4
		Move.l	(a4),a4
		Move	Cur_Anim(pc),d4
		Move.l	#'ANIM',d0
		Bsr.w	Load_Unit
	*-- Show Anim in Anim window if opened
		Bsr.w	Change_Anim

		Bsr.w	Load_AnimPieces
		Move	#1,Cur_Frame
		Bsr.w	Change_Anim
	AL_Ed:	Rts
*---------------
Comm_PieceUp:	Moveq.l	#0,d6
		Moveq.l	#-1,d7
		Bra.b	Comm_PieceMove
Comm_PieceDn:	Moveq.l	#0,d6
		Moveq.l	#1,d7
		Bra.b	Comm_PieceMove
Comm_PieceLf:	Moveq.l	#-1,d6
		Moveq.l	#0,d7
		Bra.b	Comm_PieceMove
Comm_PieceRg:	Moveq.l	#1,d6
		Moveq.l	#0,d7
		Bra.w	Comm_PieceMove

Comm_PieceMove:	Move	Last_Pick,d0	;###
		Cmp	#'BA',d0
		Beq.b	Back_PieceMove
		Cmp	#'AN',d0
		Beq.b	Anim_PieceMove
		Rts

Anim_PieceMove:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	APM_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
	*-- Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Move the Piece.
		Move	Cur_AnimPiece(pc),d0
		Beq.b	APM_End
		Subq	#1,d0
		Mulu	#8,d0
		Addq.l	#2,a1
		Add.l	d0,a1
		Add	d6,2(a1)
		Add	d7,4(a1)
		Bsr.w	Draw_Frame
	APM_End:Rts

Back_PieceMove:	Jsr	Get_Back_LAdr	;###
		Tst.l	(a2)
		Beq.b	BPM_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
		Add	#100,a1	;BackHeader
	*-- Move the Piece.
		Move	Cur_BackPiece,d0	;###
		Beq.b	BPM_End
		Subq	#1,d0
		Mulu	#8,d0
		Add.l	d0,a1
		Add	d6,2(a1)
		Add	d7,4(a1)
		Jsr	Draw_Back	;###
	BPM_End:Rts
*---------------
Load_AnimPieces:
	*-- Get list address (A2)
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	LAP_End
	*-- Get Address
		Move.l	(a2),a0			;Get Anim address
	*-- Count Frames
		Clr	d3
	LAP_FLp:Addq	#1,d3
	*-- Find Frame (A1->Address)
		Move	d3,d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,d4
	*-- Loop through Pieces
	LAP_Nxt:Subq.b	#1,d4
		Bmi.b	LAP_Fin

		Move	(a1),Cur_Piec
		Movem.l	a0-a6/d0-d7,-(a7)
		Bsr.w	Piec_Load
		Movem.l	(a7)+,a0-a6/d0-d7
		
		Addq	#8,a1
		Bra.b	LAP_Nxt

	LAP_Fin:Movem.l	a0-a6/d0-d7,-(a7)
		Move	d3,Cur_Frame
		Bsr.w	Draw_Frame
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Movem.l	(a7)+,a0-a6/d0-d7

		Cmp.b	6(a0),d3
		Bne.b	LAP_FLp

	LAP_End:Rts
*---------------
Bob_Mouse_Piece:
		;(D0=Piece, D1:0=Normal/1=Zoom, D2=X, D3=Y)
	*-- Get mouse position
		Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
	*-- Check if mouse is within gfx area of the correct layer
		Move.l	LayL(pc),a0
		Cmp.l	#'ANIM',4(a0)
		Beq.b	BP_Anim
		Cmp.l	#'BACK',4(a0)
		Beq.w	BP_Back
		Bra.w	BP_Out

	BP_Anim:
	*-- Any Anim here?
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.w	BP_None
	*-- Are we moving Origo?
		Lea	GAnim_Origo(pc),a0
		Btst	#0,4(a0)
		Bne.w	BP_None
	*-- Are we picking a Piece?
		Lea	GAnim_Pick(pc),a0
		Btst	#0,4(a0)
		Bne.w	BP_None
	*-- Are we editing collision?
		Lea	GAnim_Coll(pc),a0
		Btst	#0,4(a0)
		Bne.w	BP_None
	*-- Find coordinates of gfx area
		Lea	Anim_Gfx(pc),a4
		Lea	AnimLay(pc),a5
		Bsr.w	Calc_Coord
		Move	LayX(pc),d0
		Cmp	X1(pc),d0
		Blt.w	BP_Out
		Cmp	X2(pc),d0
		Bgt.w	BP_Out
		Move	LayY(pc),d0
		Cmp	Y1(pc),d0
		Blt.w	BP_Out
		Cmp	Y2(pc),d0
		Bgt.w	BP_Out

		Lea	AnimLay(pc),a5	;***
		Move.l	a5,BP_Lay
		Bra.w	Bob_Piece
*---------------
Bob_Piece:	Move	Cur_Piec(pc),d0	;***
		Moveq.l	#0,d1			;***
	*-- Find current piece, and check if it exists
		Move.l	Mem_PiecList(pc),a2
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	BP_None		;No
		Move.l	(a2),a2		;Get PieceData Address
	*-- Write stuff to Piec_BM
		Move.l	BP_Lay(pc),a3
		Lea	GBack_FlipY,a0	;###
		Cmp.l	#'ANIM',4(a3)
		Bne.b	BP_NAn
		Lea	GAnim_FlipY(pc),a0
	BP_NAn:
		Btst	#0,4(a0)
		Beq.b	BP_NFl
		Movem.l	d0-d7/a0-a6,-(a7)
		Move	Cur_Piec(pc),DB_FlpPc
		Jsr	DB_FlipY	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Move.l	Mem_FlipBuf,a2	;###
	BP_NFl:
		Lea	Piec_BM(pc),a1
		Move	14(a2),(a1)+	;Write BytWidth to BM
		Move	08(a2),(a1)+	;Write SizeY to BM
		Move	10(a2),(a1)+	;Write Depth to BM
		Clr	(a1)+
		Move.l	a2,a0
		Add	#28,a0
		Move	10(a2),d0
		Subq	#1,d0
	BP_BplL:Move.l	a0,(a1)+
		Add	12(a2),a0	;Add BplSize
		Dbf	d0,BP_BplL
	*-- Get size & pos
		Move	6(a2),d4	;SizeX
		Move	8(a2),d5	;SizeY
		Move	LayX(pc),d2
		Move	LayY(pc),d3
	*-- Find center of Piece
		Move	d4,d0	;X
		Lsr	#1,d0
		Sub	d0,d2

		Move	d5,d0	;Y
		Lsr	#1,d0
		Sub	d0,d3

		Move	d2,BP_X
		Move	d3,BP_Y
	*-- Clip top & left edge of Piece
		Clr	BP_OffX
		Move	X1(pc),d0
		Sub	d2,d0
		Blt.b	BP_NUnX
		Move	d0,BP_OffX
		Add	d0,d2
		Sub	d0,d4
	BP_NUnX:
		Clr	BP_OffY
		Move	Y1(pc),d0
		Sub	d3,d0
		Blt.b	BP_NUnY
		Move	d0,BP_OffY
		Add	d0,d3
		Sub	d0,d5
	BP_NUnY:
	*-- Clip bottom & right edge of Piece
		Move	d2,d0
		Add	d4,d0
		Sub	X2(pc),d0
		Ble.b	BP_NOvX
		Sub	d0,d4
		Addq	#1,d4
	BP_NOvX:
		Move	d3,d0
		Add	d5,d0
		Sub	Y2(pc),d0
		Ble.b	BP_NOvY
		Sub	d0,d5
		Addq	#1,d5
	BP_NOvY:
		Move.l	BP_Lay(pc),a5	;***
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3

		;Tst	d1
		;Bne.b	BP_Zoom
	*-- Detect movement
		Cmp	LX(pc),d2
		Bne.b	BP_Move
		Cmp	LY(pc),d3
		Bne.b	BP_Move
		Cmp	LSX(pc),d4
		Bne.b	BP_Move
		Cmp	LSY(pc),d5
		Bne.b	BP_Move
		Bra.w	BP_End		

	BP_Move:Move	d2,TX
		Move	d3,TY
		Move	d4,TSX
		Move	d5,TSY

		Bsr.w	BP_Rem
	*-- Save background
		Lea	Save_RP(pc),a1
		Move.l	GfxBase(pc),a6
		Jsr	InitRastPort(a6)
	*-- Calculate SaveSize
		Move	TSX(pc),d0
		Move	d0,d1
		And	#$f,d1
		Beq.b	BP_NRem		;No remainder
		Add	#$10,d0
		And	#$fff0,d0
	BP_NRem:Lsr	#3,d0		;Divide by 8 (8bits/byte)
		Move	d0,BP_BytWidth
		Move	TSY(pc),d1
		Mulu	d1,d0		;SizeY * SizeX
		Move	d0,BP_PlaneSize
		Mulu	10(a2),d0	;Multiply depth
		Move	d0,BP_BytSize

		Lea	Mem_SaveBack(pc),a5
		Clr.l	d0
		Move	BP_BytSize(pc),d0
		Bsr.w	Alloc_Chip_Mem
	*-- Write stuff to Save_BM
		Lea	Save_BM(pc),a1
		Move	BP_BytWidth(pc),(a1)+	;Write BytWidth to BM
		Move	TSY(pc),(a1)+	;Write SizeY to BM
		Move	10(a2),(a1)+	;Write Depth to BM
		Clr	(a1)+
		Lea	Mem_SaveBack(pc),a0
		Move.l	(a0),a0
		Move	10(a2),d0
		Subq	#1,d0
	BP_BpL:	Move.l	a0,(a1)+
		Add	BP_PlaneSize(pc),a0	;Add BplSize
		Dbf	d0,BP_BpL

		Lea	Save_BM(pc),a0
		Lea	Save_RP(pc),a1
		Move.l	a0,4(a1)

		Move.l	BP_Lay(pc),a5	;***
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move	#1,BP_SaveFlg
		Move.l	a3,a0
		Lea	Save_RP(pc),a1
		Move	TX(pc),d0
		Move	TY(pc),d1
		Moveq.l	#0,d2
		Moveq.l	#0,d3
		Move	TSX(pc),d4
		Move	TSY(pc),d5
		Move	#$c0,d6
		Jsr	ClipBlit(a6)

		Move.l	BP_Lay(pc),a5
		Move.l	a5,Rem_Lay

		Move	TX(pc),LX
		Move	TY(pc),LY
		Move	TSX(pc),LSX
		Move	TSY(pc),LSY

		Move	TX(pc),d2
		Move	TY(pc),d3
		Move	TSX(pc),d4
		Move	TSY(pc),d5
	*-- Get Mask address
		Move.l	a2,d7		;Address of BltMask
		Add.l	24(a2),d7	;+ ok
	*-- Blit Piece
		Lea	Piec_BM(pc),a0
		Move.l	a3,a1
		Move	#$e2,d6		;Minterm
		Move	BP_OffX(pc),d0	;OffsetX
		Move	BP_OffY(pc),d1	;OffsetY
		Move.l	d7,a2
		Jsr	BltMaskBitMapRastPort(a6)

	BP_None:Rts

	BP_Out:	Bra.w	BP_Rem

	BP_Rem:	
	*-- Replace background
		Tst	BP_SaveFlg
		Beq.b	Not1
		
		Move.l	Rem_Lay(pc),a5	;***
		Tst.l	(a5)
		Beq.b	BP_NLay
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Lea	Save_RP(pc),a0
		Move.l	a3,a1
		Moveq.l	#00,d0
		Moveq.l	#00,d1
		Move	LX(pc),d2
		Move	LY(pc),d3
		Move	LSX(pc),d4
		Move	LSY(pc),d5
		Move	#$c0,d6
		Jsr	ClipBlit(a6)
	BP_NLay:Clr	BP_SaveFlg

		Lea	Mem_SaveBack(pc),a5
		Bsr.w	Free_Mem
	Not1:
	BP_End:	Rts

Rem_Lay:	Dc.l	0
BP_Lay:		Dc.l	0
BP_SaveFlg:	Dc	0
TX:		Dc	0
TY:		Dc	0
TSX:		Dc	0
TSY:		Dc	0
LX:		Dc	0
LY:		Dc	0
LSX:		Dc	0
LSY:		Dc	0
BP_OffX:	Dc	0
BP_OffY:	Dc	0
BP_BytWidth:	Dc	0
BP_BytSize:	Dc	0
BP_PlaneSize:	Dc	0
BP_X:		Dc	0
BP_Y:		Dc	0
	
	BP_Zoom:Lea	Piec_BM(pc),a0
		Move.l	a0,Z_SrcBM
		Clr	Z_SrcX
		Clr	Z_SrcY
		Move	Piec_ZFact(pc),Z_Factor
		Lea	PiecLay(pc),a5
		Move.l	(a5),a1
		Move.l	12(a1),a1
		Move.l	a1,Z_DstRP
		Addq	#3,X1
		Addq	#3,Y1
		Subq	#3,X2
		Subq	#3,Y2
		Move	6(a2),Z_Width
		Lea	Zoom_BM(pc),a4
		Move.l	a4,Z_DstBM
		Bsr.w	Zoom
		Bsr.w	Blit_Gfx
		Bra.w	Free_Zoom

Save_RP:	Blk.b	100,0
Save_BM:	Dc	0	;00 - BytWidth
		Dc	0	;02 - PixelHeight
		Dc.b	0	;04
		Dc.b	0	;05 - Depth
		Dc	0	;06
		Blk.l	8,0	;08 - Bitplanes
*---------------
MoveOrigo:	Bsr.w	Draw_Origo
	*-- Get list address (A2)
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	MO_End
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Get Address
		Move.l	(a2),a0			;Get Anim address
	*-- Count Frames
		Clr	d3
	MO_FLp:	Addq	#1,d3
	*-- Find Frame (A1->Address)
		Move	d3,d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,d4
	*-- Loop through Pieces
	MO_Nxt:	Subq.b	#1,d4
		Bmi.b	MO_Fin
		Addq	#2,a1

		Move	(a1),d2
		Sub	LayX(pc),d2
		Add	#87,d2
		Add	DF_OrigoX(pc),d2
		Move	d2,(a1)+

		Move	(a1),d2
		Sub	LayY(pc),d2
		Add	#31,d2
		Add	DF_OrigoY(pc),d2
		Move	d2,(a1)+

		Addq	#2,a1
		Bra.b	MO_Nxt

	MO_Fin:	Cmp.b	6(a0),d3
		Bne.b	MO_FLp

		Bsr.w	Update_AnimBuf

	MO_End:	Move	LayX(pc),d2
		Sub	#87,d2
		Move	d2,DF_OrigoX
		Move	LayY(pc),d2
		Sub	#31,d2
		Move	d2,DF_OrigoY
		Bra.b	Draw_Origo
*---------------
Check_Origo:	Lea	GAnim_Origo(pc),a0
		Btst	#0,4(a0)
		Beq.b	CO_No
		Bsr.b	Draw_Origo
	CO_No:	Rts
*---------------
Draw_Origo:	Move	AnimList_Len(pc),d0
		Beq.b	DO_End
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	DO_End

		Move	DrawRes(pc),DO_Res
		Move	#1,DrawRes

		Lea	AnimLay(pc),a5
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	a3,a1
		Moveq.l	#3,d0
		Jsr	SetDrMd(a6)
		
		Lea	Anim_Gfx(pc),a4
		Move	DF_OrigoX(pc),d0
		;Move	PictOffsX(pc),d7
		;Sub	d7,d0
		Move	DF_OrigoY(pc),d1
		Move	d1,d3
		Sub	#18,d1
		Add	#18,d3
		Move	d0,d2
		Bsr.w	ZBox

		Lea	Anim_Gfx(pc),a4
		Move	DF_OrigoX(pc),d0
		Move	d0,d2
		Sub	#18,d0
		Add	#18,d2
		Move	DF_OrigoY(pc),d1
		;Move	PictOffsY(pc),d7
		;Sub	d7,d1
		Move	d1,d3
		Bsr.w	ZBox
		Move	DO_Res(pc),DrawRes
	DO_End:	Rts
	DO_Res:	Dc	0
*---------------
Gd_Choice:	Addq.b	#1,(a2)
	GC_Agn:	Move.b	(a2),d0
		Ext.w	d0
		Add	d0,d0
		Move	0(a1,d0.w),d1
		Bne.b	GC_Ok
		Clr.b	(a2)
		Bra.b	GC_Agn
	GC_Ok:	Move	d1,10+8(a0)
		Move.l	LayL(pc),a5
		Move.l	a0,a4
		Moveq.l	#2,d7
		Bra.w	Draw_Some
*---------------
Draw_Frame:	Bsr.w	Get_Anim_LAdr	;Any Anim?
		Tst.l	(a2)		;+
		Beq.w	DF_Fin		;+ No!
		Lea	AnimLay(pc),a5	;Layer Open?
		Tst.l	(a5)		;+
		Beq.w	DF_Stop		;+ No!
	*-- Clear gfx area
		Lea	Anim_Gfx(pc),a4
		Lea	AnimLay(pc),a5
		Bsr.w	Calc_Coord
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Move	X2(pc),d2
		Move	Y2(pc),d3
		Jsr	RectFill(a6)

		Bsr.w	Get_Anim_LAdr
		Move.l	(a2),a0
	*-- Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,DF_Pieces
		Move.l	a1,DF_Address
		Clr	DF_PieceCnt
	*-- Draw Frame
	DF_Nxt:	Addq	#1,DF_PieceCnt
		Subq.b	#1,DF_Pieces
		Bmi.w	DF_Fin
		Move.l	DF_Address(pc),a1
		Move	(a1)+,DF_Piece
		Move	(a1)+,DF_X
		Move	(a1)+,DF_Y
		Move.b	(a1)+,DF_Flags
		Move.b	(a1)+,DF_Value
		Move.l	a1,DF_Address

		Move	DF_Piece(pc),d0
	*-- Find Piece, and check if it exists
		Move.l	Mem_PiecList(pc),a2
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	DF_None		;No
		Move.l	(a2),a2		;Get PieceData Address
	*-- Write stuff to Piec_BM
		Btst	#5,DF_Flags
		Beq.b	DF_NFl
		Movem.l	d0-d7/a0-a6,-(a7)
		Move	DF_Piece(pc),DB_FlpPc
		Jsr	DB_FlipY	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Move.l	Mem_FlipBuf,a2	;###
	DF_NFl:
		Lea	Piec_BM(pc),a1
		Move	14(a2),(a1)+	;Write BytWidth to BM
		Move	08(a2),(a1)+	;Write SizeY to BM
		Move	10(a2),(a1)+	;Write Depth to BM
		Clr	(a1)+
		Move.l	a2,a0
		Add	#28,a0
		Move	10(a2),d0
		Subq	#1,d0
	DF_BplL:Move.l	a0,(a1)+
		Add	12(a2),a0	;Add BplSize
		Dbf	d0,DF_BplL
	*-- Get size & pos
		Move	6(a2),d4	;SizeX
		Move	8(a2),d5	;SizeY
		Move	DF_X(pc),d2
		Add	X1(pc),d2
		Add	DF_OrigoX(pc),d2
		Move	DF_Y(pc),d3
		Add	Y1(pc),d3
		Add	DF_OrigoY(pc),d3
	*-- Clip top & left edge of Piece
		Clr	DF_OffX
		Move	X1(pc),d0
		Sub	d2,d0
		Blt.b	DF_NUnX
		Move	d0,DF_OffX
		Add	d0,d2
		Sub	d0,d4
		Ble.w	DF_Out
	DF_NUnX:
		Clr	DF_OffY
		Move	Y1(pc),d0
		Sub	d3,d0
		Blt.b	DF_NUnY
		Move	d0,DF_OffY
		Add	d0,d3
		Sub	d0,d5
		Ble.b	DF_Out
	DF_NUnY:
	*-- Clip bottom & right edge of Piece
		Move	d2,d0
		Add	d4,d0
		Sub	X2(pc),d0
		Ble.b	DF_NOvX
		Sub	d0,d4
		Addq	#1,d4
		Ble.b	DF_Out
	DF_NOvX:
		Move	d3,d0
		Add	d5,d0
		Sub	Y2(pc),d0
		Ble.b	DF_NOvY
		Sub	d0,d5
		Addq	#1,d5
		Ble.b	DF_Out
	DF_NOvY:
	*-- Are we editing Collision?
		Lea	GAnim_Coll(pc),a0
		Btst	#0,4(a0)
		Bne.b	DF_Coll
	*-- Get Mask address
		Move.l	a2,d7		;Address of BltMask
		Add.l	24(a2),d7	;+ ok
	*-- Blit Piece
		Move	Cur_AnimPiece(pc),d0
		Cmp	DF_PieceCnt(pc),d0
		Beq.b	DF_Mask
		Lea	Piec_BM(pc),a0
		Move.l	a3,a1
		Move	DF_OffX(pc),d0	;OffsetX
		Move	DF_OffY(pc),d1	;OffsetY
		Move.l	d7,a2
		Move	DF_PieceCnt(pc),d7
		Cmp	#1,d7
		Beq.b	DF_NMsk
		Move	#$e2,d6		;Minterm
		Jsr	BltMaskBitMapRastPort(a6)
		Bra.b	DF_End
	DF_NMsk:Move	#$c0,d6		;Minterm
		Jsr	BltBitMapRastPort(a6)
	DF_None:
	DF_Out:
	DF_End:	Bra.w	DF_Nxt

	DF_Fin:	Bra.w	Check_Origo
	DF_Stop:Rts

	DF_Coll:
	*-- Get Mask address
		Move.l	a2,d7		;Address of ColMask
		Add.l	20(a2),d7	;+ ok
	*-- Blit Collision Mask
		Moveq.l	#0,d0
		Move.l	a3,a1
		Jsr	SetDrMd(a6)
		Move	MdCol(pc),d0
		Move.b	DF_Flags(pc),d1
		Bmi.b	DF_On
		Move	BkCol(pc),d0
	DF_On:	Move.l	a3,a1
		Jsr	SetAPen(a6)
		Lea	Piec_BM(pc),a5
		Move.l	d7,a0		;Src
		Move.l	a3,a1		;DstRP
		Move	(a5),d1		;SrcMod
		Move	DF_OffX(pc),d0	;SrcX
		Move	DF_OffY(pc),d7	;OffsetY
		Mulu	d1,d7
		Add	d7,a0
		Jsr	BltTemplate(a6)
		Bra.b	DF_End
	*-- Blit Mask
	DF_Mask:Moveq.l	#0,d0
		Move.l	a3,a1
		Jsr	SetDrMd(a6)
		Move	HiCol(pc),d0
		Move.l	a3,a1
		Jsr	SetAPen(a6)
		Lea	Piec_BM(pc),a5
		Move.l	d7,a0		;Src
		Move.l	a3,a1		;DstRP
		Move	(a5),d1		;SrcMod
		Move	DF_OffX(pc),d0	;SrcX
		Move	DF_OffY(pc),d7	;OffsetY
		Mulu	d1,d7
		Add	d7,a0
		Jsr	BltTemplate(a6)
		Bra.b	DF_End

DF_OrigoX:	Dc	30
DF_OrigoY:	Dc	30
DF_OffX:	Dc	0
DF_OffY:	Dc	0
DF_BytWidth:	Dc	0
DF_BytSize:	Dc	0
DF_PlaneSize:	Dc	0

DF_PieceCnt:	Dc	0
DF_Pieces:	Dc.b	0,0
DF_Address:	Dc.l	0

DF_Piece:	Dc	0
DF_X:		Dc	0
DF_Y:		Dc	0
DF_Flags:	Dc.b	0
DF_Value:	Dc.b	0

Cur_Frame:	Dc	1
Cur_Repeat:	Dc	1
*---------------
PickPiece:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.w	PP_Fin
		Move.l	(a2),a0
	*-- Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,PP_Pieces
		Move.l	a1,PP_Address
	*-- Find coordinates of gfx area
		Lea	Anim_Gfx(pc),a4
		Lea	AnimLay(pc),a5
		Bsr.w	Calc_Coord
		Clr	PP_PieceCnt
		Clr	Cur_AnimPiece
	*-- Draw Frame
	PP_Nxt:	Addq	#1,PP_PieceCnt
		Subq.b	#1,PP_Pieces
		Bmi.w	PP_Fin
		Move.l	PP_Address(pc),a1
		Move	(a1)+,PP_Piece
		Move	(a1)+,PP_X1
		Move	(a1)+,PP_Y1
		Move.b	(a1)+,PP_Flags
		Move.b	(a1)+,PP_Value
		Move.l	a1,PP_Address

		Move	PP_Piece(pc),d0
		Moveq.l	#0,d1		;***
	*-- Find current piece, and check if it exists
		Move.l	Mem_PiecList(pc),a2
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	PP_None		;No
		Move.l	(a2),a2		;Get PieceData Address
		Move	PP_X1(pc),d0
		Add	6(a2),d0
		Move	d0,PP_X2
		Move	PP_Y1(pc),d0
		Add	8(a2),d0
		Move	d0,PP_Y2
		Move	LayX(pc),d0
		Sub	#87,d0
		Sub	DF_OrigoX(pc),d0
		Cmp	PP_X1(pc),d0
		Blt.b	PP_None
		Cmp	PP_X2(pc),d0
		Bgt.b	PP_None

		Sub	PP_X1(pc),d0
		Move	d0,PP_XOff

		Move	LayY(pc),d0
		Sub	#31,d0
		Sub	DF_OrigoY(pc),d0
		Cmp	PP_Y1(pc),d0
		Blt.b	PP_None
		Cmp	PP_Y2(pc),d0
		Bgt.b	PP_None
		
		Sub	PP_Y1(pc),d0
		Move	d0,PP_YOff

		Move	Cur_AnimPiece(pc),d0
		Bne.b	PP_NAl
		Move	PP_PieceCnt(pc),Cur_AnimPiece
	PP_NAl:
		Btst	#5,PP_Flags
		Beq.b	PP_NFl
		Move	PP_Piece(pc),DB_FlpPc
		Jsr	DB_FlipY	;###
		Move.l	Mem_FlipBuf,a2	;###
	PP_NFl:
		Move	PP_XOff(pc),d0
		Move	PP_YOff(pc),d1
		Moveq.l	#0,d2
		Jsr	CPiec_Pixel_Tst
		Tst	d7
		Ble.b	PP_None

		Move	PP_PieceCnt(pc),Cur_AnimPiece
	PP_None:
	PP_Out:
	PP_End:	Bra.w	PP_Nxt
	PP_Fin:	
	*-- Are we editing Collision?
		Lea	GAnim_Coll(pc),a0
		Btst	#0,4(a0)
		Beq.b	PP_NoCl

		Bsr.w	Get_Anim_LAdr
		Or	#2,4(a2)		;Set NeedsUpdate
		
		Move.l	(a2),a0
	*-- Find Frame
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Find Piece
		Addq	#2,a1
		Move	Cur_AnimPiece(pc),d0
		Beq.b	PP_NoCl
		Subq	#1,d0
		Lsl	#3,d0
		Add	d0,a1

		Move.b	6(a1),d0
		Bchg	#7,d0
		Move.b	d0,6(a1)
		Clr	Cur_AnimPiece

	PP_NoCl:Move	#'AN',Last_Pick
		Bsr.w	Draw_Frame
	*-- Show piece in piece window if opened
		Bsr.w	Get_Anim_LAdr
		Move.l	(a2),a0
	*-- Find Frame
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Find Piece
		Addq	#2,a1
		Move	Cur_AnimPiece(pc),d0
		Beq.b	PP_No
		Subq	#1,d0
		Lsl	#3,d0
		Add	d0,a1
		Move	(a1),Cur_Piec

		Bsr.w	Change_Piec
	PP_No:	Rts

PP_PieceCnt:	Dc	0
PP_Pieces:	Dc.b	0,0
PP_Address:	Dc.l	0

PP_XOff:	Dc	0
PP_YOff:	Dc	0
PP_Flags:	Dc.b	0
PP_Value:	Dc.b	0
PP_Piece:	Dc	0
PP_X1:		Dc	0
PP_Y1:		Dc	0
PP_X2:		Dc	0
PP_Y2:		Dc	0
*---------------
Upd_AnimButtG:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	UABG_E
		Move.l	(a2),a3

		Lea	Anim_DirUpd(pc),a0
		Lea	ADI_Lst(pc),a1
		Move.b	9(a3),d0
		Ext	d0
		Add	d0,d0
		Move	0(a1,d0.w),d1
		Move	d1,10+8(a0)

		Lea	Anim_ConUpd(pc),a0
		Lea	ACO_Lst(pc),a1
		Move.b	8(a3),d0
		Ext	d0
		Add	d0,d0
		Move	0(a1,d0.w),d1
		Move	d1,10+8(a0)

		Lea	AnimLay(pc),a5
		Lea	Anim_DirUpd(pc),a4
		Moveq.l	#2,d7
		Bsr.w	Draw_Some

		Lea	Anim_ConUpd(pc),a4
		Moveq.l	#2,d7
		Bsr.w	Draw_Some
	UABG_E:	Rts
*---------------
Upd_AnimPropD:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	UFP_End
		Move.l	(a2),a3

		Lea	FrameProp(pc),a0	;Calc prop percentages
		Move.l	#65535,d0
		Move.b	6(a3),d2
		Ext	d2
		Divu	d2,d0			;Total
		Move	d0,2(a0)		;%KnobX
		Move	Cur_Frame(pc),d1
		Subq	#1,d1
		Mulu	#65535,d1
		Move.b	6(a3),d2
		Ext	d2
		Divu	d2,d1			;Total

		Move	d1,d2			;Check if prop overflows
		Not	d2
		Cmp	d2,d0
		Bls.b	UFP_NOv
		Move.l	#$10000,d1
		Sub	d0,d1
	UFP_NOv:Move	d1,6(a0)		;%PosX
	UFP_End:Rts
*---------------
Upd_AnimNumbD:	Move	AnimList_Len(pc),d0
		Beq.w	UAG_End
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.w	UAG_End

		Bsr.w	Get_Anim_LAdr
		Move.l	(a2),a0
		Clr	d0
		Move.b	6(a0),d0
		Lea	T_TotalN+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv

		Bsr.w	Get_Anim_LAdr
		Move.l	(a2),a0
		Clr	d0
		Move.b	7(a0),d0
		Lea	T_DelayN+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv

Upd_PlayNumbD:	Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	UAG_End
		Move.l	(a2),a0
	*-- Frame
		Cmp	#1,Cur_Frame
		Bge.b	UAG_TNotUnder
		Move.b	6(a0),d0
		Ext	d0
		Move	d0,Cur_Frame
UAG_TNotUnder:	Move.b	6(a0),d0
		Ext	d0
		Cmp	Cur_Frame(pc),d0
		Bge.b	UAG_TNotOver
		Move	#1,Cur_Frame
UAG_TNotOver:
		Move	Cur_Frame(pc),d0
		Lea	T_FrameN+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv

		Bsr.w	Get_Anim_LAdr
		Move.l	(a2),a0
	*-- Find Frame (A1->Address)
		Move	Cur_Frame(pc),d0
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1

		Clr	d0
		Move.b	(a1),d0
		Lea	T_RepeatN+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
	UAG_End:Rts
*---------------
Upd_AnimNumbG:	Lea	AnimLay(pc),a5
		Lea	Anim_TotalUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some

		Lea	Anim_DelayUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some

Upd_PlayNumbG:	Lea	AnimLay(pc),a5
		Lea	Anim_FrameUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some

		Lea	Anim_RepeatUpd(pc),a4
		Moveq.l	#1,d7
		Bra.w	Draw_Some
*---------------
Upd_AnimPropG:	Lea	AnimLay(pc),a5
		Lea	Anim_FPUpd(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Upd_AnimNameD:	Lea	Anim_Info(pc),a3
		Lea	Anim_NameUpd(pc),a4
		Bra.w	Upd_UnitNameD
*---------------
Upd_AnimNameG:	Lea	AnimLay(pc),a5
		Lea	Anim_NameUpd(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Update_AnimBuf:	Lea	Anim_Info(pc),a3
		Bra.w	Update_UnitBuf
*---------------
Update_UnitBuf:	;(A3=UnitInfo)
		Move.l	a3,Undoable
	*-- Free old buffer
		Move.l	12(a3),a5	;Get Mem_UnitBuf
		Bsr.w	Free_Mem
	*-- Find current Unit, and check if it exists
		Bsr.b	Get_Unit_LAdr
		Tst.l	(a2)
		Beq.b	UUB_End
		Move.l	(a2),a4
	*-- Allocate new Unit buffer
		Move.l	12(a3),a5	;Get Mem_UnitBuf
		Move.l	2(a4),d0
		Cmp.l	#'PIEC',16(a3)
		Beq.b	UUB_Ch
		Cmp.l	#'SMPL',16(a3)
		Beq.b	UUB_Ch
		Bsr.w	Alloc_Any_Mem
		Beq.w	Mess_MemErr
		Bra.b	UUB_Ok
	UUB_Ch:	Bsr.w	Alloc_Chip_Mem
		Beq.w	Mess_MemErr
	*-- Copy Unit to buffer
	UUB_Ok:	Move.l	12(a3),a1	;Get Mem_UnitBuf
		Move.l	(a1),a1
		Move.l	2(a4),d0
		Subq	#1,d0
	UUB_CLp:Move.b	(a4)+,(a1)+
		Dbf	d0,UUB_CLp
	UUB_End:Rts
*---------------
Get_Unit_LAdr:	;(A3=UnitInfo)
		Move.l	2(a3),a2	;Get Mem_AnimList
		Move.l	(a2),a2		;+
		Clr.l	d0
		Move	(a3),d0		;Get Cur_Unit
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Get_Anim_LAdr:	Move.l	Mem_AnimList(pc),a2
		Clr.l	d0
		Move	Cur_Anim(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Change_Anim:
	*-- Find current Anim, and check if it exists
		Bsr.b	Get_Anim_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	CA_End
		Move	#1,Cur_Frame
		Bsr.b	Check_Anim
	*-- Center Origo
		Lea	Anim_Gfx(pc),a4
		Lea	AnimLay(pc),a5
		Bsr.w	Calc_Coord
		Move	X2(pc),d0
		Sub	X1(pc),d0
		Lsr	#1,d0
		Move	d0,DF_OrigoX
		Move	Y2(pc),d0
		Sub	Y1(pc),d0
		Lsr	#1,d0
		Move	d0,DF_OrigoY
	*-- Update anim on screen
		Clr	Cur_AnimPiece
		Bsr.w	Upd_AnimNameD
		Bsr.w	Upd_AnimNameG
		Bsr.w	Upd_AnimNumbD
		Bsr.w	Upd_AnimNumbG
		Bsr.w	Upd_AnimPropD
		Bsr.w	Upd_AnimPropG
		Bsr.w	Upd_AnimButtG
		Lea	Anim_GfxUpd(pc),a4
		Lea	AnimLay(pc),a5
		Bsr.w	Draw_All
		Lea	Anim_Info(pc),a3
		Bsr.w	Upd_SelcUnit
	CA_End:	Rts
*---------------
Check_Anim:	Lea	Anim_Jump(pc),a0
		Move	AnimList_Len(pc),d0
		Beq.b	CA_NoUn
	*-- Find current Anim, and check if it exists
		Move.l	Mem_AnimList(pc),a2
		Move	Cur_Anim(pc),d0
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Anim?
		Beq.b	CA_NoGr		;No
		Lea	Anim_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CA_NoUn:Lea	Anim_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CA_NoGr:Lea	Anim_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
	BP_Back:	;(D0=Piece, D1:0=Normal/1=Zoom, D2=X, D3=Y)
	*-- Any Back here?
		Jsr	Get_Back_LAdr	;###
		Tst.l	(a2)
		Beq.b	BBP_Ed
	*-- Are we picking a Piece?
		Lea	GBack_Pick,a0	;###
		Btst	#0,4(a0)
		Bne.w	BP_None
	*-- Are we editing collision?
		Lea	GBack_Coll,a0	;###
		Btst	#0,4(a0)
		Bne.w	BP_None
	*-- Find coordinates of gfx area
		Lea	Back_Gfx,a4	;###
		Lea	BackLay(pc),a5
		Bsr.w	Calc_Coord
	*-- Get mouse position
		Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
	*-- Check if mouse is within gfx area of the correct layer
		Move	LayX(pc),d0
		Cmp	X1(pc),d0
		Blt.w	BP_Out
		Cmp	X2(pc),d0
		Bgt.w	BP_Out
		Move	LayY(pc),d0
		Cmp	Y1(pc),d0
		Blt.w	BP_Out
		Cmp	Y2(pc),d0
		Bgt.w	BP_Out

		Lea	BackLay(pc),a5	;***
		Move.l	a5,BP_Lay
		Bsr.w	Bob_Piece
	BBP_Ed:	Rts
*---------------
DrawList_Anim:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Animation8T

		Dc	'RO'
		Dc.l	Upd_AnimPropD
		Dc	'RO'
		Dc.l	Upd_AnimNumbD

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Anim_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Anim_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Anim_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-04,025

		Dc	'RO'
		Dc.l	Upd_AnimNameD

Anim_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Anim_Name
		Dc	'RC',049,015,-26,023
		Dc	'TX',051,022,-77,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Anim_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Anim_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

		Dc	'BX',000,028,083,-01

		Dc	'TX',003,038,-01,5
		Dc.l	DelayT
		Dc	'GD'
		Dc.l	$02030a00,2,Anim_Delay
		Dc	'RC',046,031,060,039
Anim_DelayUpd:	Dc	'TX',049,038,-01,5
		Dc.l	T_DelayN

		Dc	'GD'
		Dc.l	$02010052,0,Anim_DelayMinus
		Dc	'BX',063,031,071,039
		Dc	'IM',065,035,1,Im_Minus-Im

		Dc	'GD'
		Dc.l	$02010053,0,Anim_DelayPlus
		Dc	'BX',072,031,080,039
		Dc	'IM',074,033,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$0201000c,0,Anim_Control
Anim_ConUpd:	Dc	'BX',003,042,015,054
		Dc	'IM',005,044,9,Im_Loop-Im
		
		Dc	'GD'
		Dc.l	$02010008,0,Anim_Direction
Anim_DirUpd:	Dc	'BX',016,042,028,054
		Dc	'IM',018,046,5,Im_Forward-Im
		
		Dc	'GD'
		Dc.l	$0201000d,0,Anim_Play
		Dc	'BX',029,042,041,054
		Dc	'IM',031,045,7,Im_Play-Im
		
		Dc	'GD'
		Dc.l	$0201000e,0,Anim_PlayScreen
		Dc	'BX',042,042,054,054
		Dc	'IM',044,044,9,Im_PlayScr-Im

		Dc	'GD'
		Dc.l	$02010004,0,Anim_PrevFrame
		Dc	'BX',055,042,067,054
		Dc	'IM',057,045,7,Im_PrevFrame-Im

		Dc	'GD'
		Dc.l	$02010003,0,Anim_NextFrame
		Dc	'BX',068,042,080,054
		Dc	'IM',070,045,7,Im_NextFrame-Im

		Dc	'GD'
		Dc.l	$02010006,0,Anim_ToStart
		Dc	'BX',003,057,011,065
		Dc	'IM',005,059,5,Im_ToStart-Im

Anim_FPUpd:	Dc	'GD'
		Dc.l	$0202000f,FrameProp,Anim_FrameProp
		Dc	'BX',012,057,071,065
		Dc	'BX',019,059,049,063

		Dc	'GD'
		Dc.l	$02010007,0,Anim_ToEnd
		Dc	'BX',072,057,080,065
		Dc	'IM',074,059,5,Im_ToEnd-Im

		Dc	'TX',003,075,-01,5
		Dc.l	FrameT

		Dc	'GD'
		Dc.l	$02030a12,2,Anim_Frame
		Dc	'RC',038,068,052,076
Anim_FrameUpd:	Dc	'TX',041,075,-01,5
		Dc.l	T_FrameN

		Dc	'TX',055,075,-01,5
		Dc.l	OfT

		Dc	'GD'
		Dc.l	$02030a13,2,Anim_Total
		Dc	'RC',066,068,080,076
Anim_TotalUpd:	Dc	'TX',069,075,-01,5
		Dc.l	T_TotalN

		Dc	'GD'
		Dc.l	$02010001,0,Anim_AddFrame
		Dc	'BX',003,079,015,091
		Dc	'IM',005,081,9,Im_AddFrame-Im

		Dc	'GD'
		Dc.l	$02010002,0,Anim_DelFrame
		Dc	'BX',016,079,028,091
		Dc	'IM',018,081,9,Im_DelFrame-Im

GAnim_Coll:	Dc	'GD'
		Dc.l	$02010662,Anim_Excl,Anim_Coll
		Dc	'BX',052,079,064,091
		Dc	'IM',054,081,9,Im_Collision-Im

GAnim_Origo:	Dc	'GD'
		Dc.l	$02010664,Anim_Excl,Anim_Origo
		Dc	'BX',068,079,080,091
		Dc	'IM',070,081,9,Im_Origo-Im

GAnim_Pick:	Dc	'GD'
		Dc.l	$02010614,Anim_Excl,Anim_PiecePick
		Dc	'BX',003,094,015,106
		Dc	'IM',005,096,9,Im_Pick-Im

		Dc	'GD'
		Dc.l	$02010015,0,Anim_PieceDel
		Dc	'BX',016,094,028,106
		Dc	'IM',018,096,9,Im_ClrClips-Im

GAnim_FlipY:	Dc	'GD'
		Dc.l	$0201021f,0,0	;Anim_FlipY
		Dc	'BX',052,094,064,106
		Dc	'IM',054,096,9,Im_FlipY-Im

		Dc	'GD'
		Dc.l	$0201000b,0,Anim_Undo
		Dc	'BX',068,094,080,106
		Dc	'IM',070,096,9,Im_Undo-Im

		Dc	'TX',003,116,-01,5
		Dc.l	RepeatT

		Dc	'GD'
		Dc.l	$02030a6d,2,Anim_Repeat
		Dc	'RC',046,109,060,117
Anim_RepeatUpd:	Dc	'TX',049,116,-01,5
		Dc.l	T_RepeatN

		Dc	'GD'
		Dc.l	$02010052,0,Anim_RepeatMinus
		Dc	'BX',063,109,071,117
		Dc	'IM',065,113,1,Im_Minus-Im

		Dc	'GD'
		Dc.l	$02010053,0,Anim_RepeatPlus
		Dc	'BX',072,109,080,117
		Dc	'IM',074,111,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$02020000,AnimPropY,Anim_OffsetY
		Dc	'BX',-09,028,-01,-10
		Dc	'BX',-07,038,-03,-24

		Dc	'GD'
		Dc.l	$02020000,AnimPropX,Anim_OffsetX
		Dc	'BX',084,-09,-10,-01
		Dc	'BX',094,-07,-20,-03

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

Anim_GfxUpd:	Dc	'RO'
		Dc.l	Check_Anim

		Dc	'JP'
Anim_Jump:	Dc.l	Anim_No

Anim_Yes:	Dc	'GD'
		Dc.l	$01000000,0,Anim_Anim
Anim_Gfx:	Dc	'DF',087,031,-13,-13
		Dc	'FR',084,028,-10,-10
		Dc	'RO'
		Dc.l	Draw_Frame
		Dc	'XX'

Anim_No:	Dc	'BX',084,028,-10,-10
		Dc	'TX',087,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Anim_Load
		Dc	'BX',-37,030,-13,038
		Dc	'TX',-34,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Anim_None:	Dc	'BX',084,028,-10,-10
		Dc	'TX',087,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Anim_Excl:	Dc.l	GAnim_Coll
		Dc.l	GAnim_Pick
		Dc.l	GAnim_Origo
		Dc.l	0

T_DelayN:	Dc.b	' 0',0
T_RepeatN:	Dc.b	' 0',0
T_FrameN:	Dc.b	' 0',0
T_TotalN:	Dc.b	' 0',0
Anim_ZFactT:	Dc.b	'2',0
		Even
AnimDigProp:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
FrameProp:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
AnimPropX:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
AnimPropY:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,65535		;KnobX,Y
		Dc	0,0		;PosX,Y
*=======================================================================*
*				 D E S K				*
*=======================================================================*
Desk_Quit:	Lea	QuitLay(pc),a5
		Bra.w	Open_Layer
*---------------
Desk_Drag:	Tst	LayY
		Bne.b	DD_NNul
		Move	#1,LayY
	DD_NNul:Move.l	Screen_Struct(pc),a0
		Move	16(a0),d1
		Move	d1,d2
		Sub	LayY(pc),d1
		Cmp	DD_Y(pc),d1
		Bne.b	DD_Mov
		Tst	d2
		Bne.b	DD_NoMv
	DD_Mov:	Move	d1,DD_Y
		Move.l	IntBase(pc),a6
		Move.l	Screen_Struct(pc),a0
		Move	10(a0),d7
		Add	d1,d7
		Bpl.b	DD_Ok
		Sub	d7,d1
	DD_Ok:	Clr	d0
		Jsr	MoveScreen(a6)
	DD_NoMv:Bsr.w	Check_Left_Up
		Beq.b	Desk_Drag
		Rts
	DD_Y:	Dc	0
*---------------
Desk_Info:	Lea	InfoLay(pc),a5
		Bra.w	Open_Layer
*---------------
Desk_WorkBench:	Move.l	IntBase(pc),a6
		Eor	#1,DWB_Flg
		Bne.b	DWB_Cl
		Jmp	OpenWorkBench(a6)
	DWB_Cl:	Jmp	CloseWorkBench(a6)
	DWB_Flg:Dc	0
*---------------
Desk_Prefs:	Lea	PrefLay(pc),a5
		Bra.w	Open_Layer
*---------------
Desk_Depth:	Move.l	IntBase(pc),a6
		Move.l	Screen_Struct(pc),a0
		Cmp.l	60(a6),a0	;Is FirstScreen?
		Beq.b	DD_Back
		Jmp	ScreenToFront(a6)
	DD_Back:Jmp	ScreenToBack(a6)
*---------------
Fill_Desk:	Move.l	GfxBase(pc),a6	;Fill layer with BkCol
		Move.l	DeskLay(pc),a1
		Move.l	12(a1),a1
		Move	BkCol(pc),d0
		Jmp	SetRast(a6)
*---------------
Info_Desk:	;(Get & convert to ASCII AvailMem & SystemTime)
		Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer
		Move.l	LayL(pc),a5		;Search
		Move.l	18(a5),a4
		Bsr.w	SrchAll
		Beq.w	ID_Mem
		Clr.l	d0
		Move.b	5(a4),d0
		Beq.w	ID_Mem
		Cmp	#$f8,d0
		Bge.b	ID_Cord
		Cmp	Last_Help(pc),d0
		Beq.w	ID_Time
		Move	d0,Last_Help
		Add.l	d0,d0		;Multiply by 2
		Lea	Help_Tab,a1	;###
		Move	0(a1,d0.w),d1
		Lea	Help,a1
		Add	d1,a1
		Lea	MemI_Upd(pc),a0
		Move.l	a1,10(a0)
		Bsr.w	ID_Center
		Lea	DeskLay(pc),a5
		Lea	Help_Upd(pc),a4
		Moveq.l	#2,d7
		Bsr.w	Draw_Some
		Bra.w	ID_Time

	ID_Cord:Lea	Pict_BM(pc),a0
		Tst.l	8(a0)		;BitMap empty?
		Beq.b	ID_Mem
		Lea	Pict_Gfx(pc),a4
		Lea	PictLay(pc),a5
		Bsr.w	Calc_Coord
		Clr.l	d0
		Move	LayX(pc),d0
		Sub	X1(pc),d0
		Divu	DrawRes(pc),d0
		Add	PictOffsX(pc),d0
		Move	d0,ID_X
		Clr.l	d1
		Move	LayY(pc),d1
		Sub	Y1(pc),d1
		Divu	DrawRes(pc),d1
		Add	PictOffsY(pc),d1
		Move	d1,ID_Y

	ID_No:	Clr	Last_Help
		Lea	MemI_Upd(pc),a0
		Lea	Coord(pc),a1
		Move.l	a1,10(a0)
		Move	ID_X(pc),d0
		Lea	XCoord+5(pc),a0
		Moveq.l	#4,d7
		Bsr.w	Conv
		Move	ID_Y(pc),d0
		Lea	YCoord+5(pc),a0
		Moveq.l	#4,d7
		Bsr.w	Conv
		Bra.b	ID_Time
	ID_X:	Dc	0
	ID_Y:	Dc	0

	ID_Mem:	Clr	Last_Help
		Lea	MemI_Upd(pc),a0
		Lea	Mem(pc),a1
		Move.l	a1,10(a0)
		Move.l	4.w,a6
		Moveq.l	#$2,d1
		Jsr	AvailMem(a6)
		Divu	#1024,d0
		Lea	CMem+4(pc),a0
		Moveq.l	#3,d7
		Bsr.w	Conv
		Moveq.l	#$4,d1
		Jsr	AvailMem(a6)
		Divu	#1024,d0
		Lea	FMem+4(pc),a0
		Moveq.l	#3,d7
		Bsr.w	Conv

	ID_Time:Bsr.b	ID_Center
		Lea	Sec(pc),a0
		Lea	Mic(pc),a1
		Move.l	IntBase(pc),a6
		Jsr	CurrentTime(a6)
		Move.l	Sec(pc),d1
		Move.l	d1,d0
		Lsr.l	#2,d0
		Divu	#60*60*24/4,d0
		Mulu	#60*60*24/4,d0
		Lsl.l	#2,d0
		Sub.l	d0,d1
		Move.l	d1,d0
		Divu	#60*60,d0
		Move	d0,d2
		Mulu	#60*60,d2
		Sub.l	d2,d1
		Lea	Hr+2(pc),a0
		Moveq.l	#1,d7
		Bsr.w	Conv
		Move.l	d1,d0
		Divu	#60,d0
		Move	d0,d2
		Mulu	#60,d2
		Sub.l	d2,d1
		Lea	Mn+2(pc),a0
		Moveq.l	#1,d7
		Bsr.w	Conv
		Move.l	d1,d0
		Lea	Sc+2(pc),a0
		Moveq.l	#1,d7
		Bra.w	Conv

	ID_Center:
		Move.l	DeskLay(pc),a3
		Move.l	12(a3),a3
		Move.l	GfxBase(pc),a6
		Move.l	a3,a1
		Lea	Font5,a0	;###
		Move.l	(a0),a0
		Jsr	SetFont(a6)
		Moveq.l	#-1,d3
		Move.l	MemI_Upd+10(pc),a2
	ID_Cent:Addq	#1,d3
		Tst.b	(a2)+
		Bne.b	ID_Cent
		Move	d3,d0
		Move.l	MemI_Upd+10(pc),a0
		Move.l	a3,a1
		Jsr	TextLength(a6)
		Moveq.l	#83,d1
		Sub	d0,d1
		Lsr	#1,d1
		Add	#13,d1
		Move	d1,MemI_Upd+2
		Rts
Sec:		Dc.l	0
Mic:		Dc.l	0
Mem:		Dc.b	'C:'
CMem:		Dc.b	'    K F:'
FMem:		Dc.b	'    K',0
Time:
Hr:		Dc.b	'  :'
Mn:		Dc.b	'  .'
Sc:		Dc.b	'  ',0
Coord:		Dc.b	'X='
XCoord:		Dc.b	'      Y='
YCoord:		Dc.b	'     ',0
		Even
Last_Help:	Dc	0
*---------------
Quit_Quit:	Bra.w	End
*---------------
Quit_Clear:	Lea	QuitLay(pc),a5
		Bsr.w	Close_Layer
		Bsr.w	Free_All_Lists
		Bra.w	ReDraw_All
*---------------
Ask_Aga:	Bclr	#0,Prf_GfxFlags
		Clr	AGA
;			Move	#16,Palt_RGB_P
		Move.l	GfxBase(pc),a6
		Btst	#2,$ec(a6)
		Beq.b	AA_Ed
		Bset	#0,Prf_GfxFlags
		Move	#1,AGA
;			Move	#1,Palt_RGB_P
	AA_Ed:	Rts
	AGA:	Dc	0
*---------------
Pref_Aga:	;	Move	#16,Palt_RGB_P
		Bchg	#0,Prf_GfxFlags
		Beq.w	PA_NAa
		;	Move	#1,Palt_RGB_P
	PA_NAa:	Bsr.b	Upd_Pref_AgaD
		Bsr.b	Upd_Pref_AgaG
		Jmp	Change_Palt	;###
*---------------
Upd_Pref_AgaD:	Lea	GPref_Aga(pc),a4
		Move	#Im_Blank-Im,d0
		Btst	#0,Prf_GfxFlags
		Beq.b	UPA_NAg
		Move	#Im_Check5-Im,d0
	UPA_NAg:Move	d0,32(a4)
		Rts
*---------------
Upd_Pref_AgaG:	Lea	GPref_Aga(pc),a4
		Lea	PrefLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Ask_Filter:	Bclr	#0,Prf_AudioFlags
		Btst	#1,$bfe001
		Bne.b	AF_E
		Bset	#0,Prf_AudioFlags
	AF_E:	Rts
*---------------
Pref_Filter:	Bset	#1,$bfe001
		Bchg	#0,Prf_AudioFlags
		Bne.b	PF_NAa
		Bclr	#1,$bfe001
	PF_NAa:	Bsr.b	Upd_Pref_FltD
		Bra.b	Upd_Pref_FltG
*---------------
Upd_Pref_FltD:	Lea	GPref_Filter(pc),a4
		Move	#Im_Blank-Im,d0
		Btst	#0,Prf_AudioFlags
		Beq.b	UPD_Off
		Move	#Im_Check5-Im,d0
	UPD_Off:Move	d0,32(a4)
		Rts
*---------------
Upd_Pref_FltG:	Lea	GPref_Filter(pc),a4
		Lea	PrefLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Pref_Hires:	Bchg	#1,Prf_GfxFlags
		Bsr.b	Upd_Pref_HirD
		Bsr.b	Upd_Pref_HirG
		Bsr.w	Upd_Pref_ColD
		Bra.w	Upd_Pref_ColG
*---------------
Upd_Pref_HirD:	Lea	GPref_Hires(pc),a4
		Move	#Im_Blank-Im,d0
		Btst	#1,Prf_GfxFlags
		Beq.b	UPH_Off
		Move	#Im_Check5-Im,d0

		Move	AGA(pc),d1
		Bne.b	UPH_Aa
		Btst	#1,Prf_GfxFlags
		Beq.b	UPH_Aa
		Cmp	#4,Prf_Depth
		Ble.b	UPH_Aa
		Move	#4,Prf_Depth
	UPH_Aa:	
	UPH_Off:Move	d0,32(a4)
		Rts
*---------------
Upd_Pref_HirG:	Lea	GPref_Hires(pc),a4
		Lea	PrefLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Pref_Interlace:	Bchg	#2,Prf_GfxFlags
		Bsr.b	Upd_Pref_IntD
		Bra.b	Upd_Pref_IntG
*---------------
Upd_Pref_IntD:	Lea	GPref_Interlace(pc),a4
		Move	#Im_Blank-Im,d0
		Btst	#2,Prf_GfxFlags
		Beq.b	UPI_Off
		Move	#Im_Check5-Im,d0
	UPI_Off:Move	d0,32(a4)
		Rts
*---------------
Upd_Pref_IntG:	Lea	GPref_Interlace(pc),a4
		Lea	PrefLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Pref_Colors:	Move.l	Convert_Value,d0	;###
	*-- Find exponent.
		Moveq.l	#8,d2
	PrC_L:	Btst	d2,d0
		Bne.b	PrC_Fin
		Subq	#1,d2
		Cmp	#1,d2
		Bne.b	PrC_L
		Bra.b	PrC_E
	PrC_Fin:Move	d2,Prf_Depth

		Moveq.l	#8,d6
		Move	AGA(pc),d0
		Bne.b	PrC_Aa
		Moveq.l	#6,d6
		Btst	#1,Prf_GfxFlags
		Beq.b	PrC_Aa
		Moveq.l	#4,d6
	PrC_Aa:	
		Move	Prf_Depth(pc),d7
		Cmp	d6,d7
		Ble.b	PrAC_E
		Move	d6,Prf_Depth
		
	PrC_E:	Bsr.b	Upd_Pref_ColD
		Bsr.b	Upd_Pref_ColG
		Rts
*---------------
Pref_AddColors:	Moveq.l	#8,d6
		Move	AGA(pc),d0
		Bne.b	PrAC_Aa
		Moveq.l	#6,d6
		Btst	#1,Prf_GfxFlags
		Beq.b	PrAC_Aa
		Moveq.l	#4,d6
	PrAC_Aa:Move	Prf_Depth(pc),d7
		Cmp	d6,d7
		Beq.b	PrAC_E
		Addq	#1,d7
		Move	d7,Prf_Depth
		Bsr.b	Upd_Pref_ColD
		Bsr.b	Upd_Pref_ColG
	PrAC_E:	Rts
*---------------
Pref_DelColors:	Move	Prf_Depth(pc),d7
		Cmp	#2,d7
		Beq.b	PrDC_E
		Subq	#1,d7
		Move	d7,Prf_Depth
		Bsr.b	Upd_Pref_ColD
		Bsr.b	Upd_Pref_ColG
	PrDC_E:	Rts
*---------------
Upd_Pref_ColD:	Clr	d0
		Move	Prf_Depth(pc),d1
		Bset	d1,d0
		Lea	Pref_ColorsNT+3(pc),a0
		Move	#$8102,d7
		Jmp	Conv		;###
*---------------
Upd_Pref_ColG:	Lea	PrefLay,a5	;###
		Lea	GPref_Colors(pc),a4
		Moveq.l	#1,d7
		Jmp	Draw_Some	;###
*---------------
Pref_UpdPaNmD:	Lea	GPref_PaltName(pc),a5
		Clr.l	20(a5)
		Move	Prf_Palette(pc),d0
		Bmi.b	PUPa_Ed
		Ext.l	d0
		Move.l	Mem_PaltList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	PUPa_Ed:Rts
*---------------
Pref_UpdPaNmG:	Lea	PrefLay,a5	;###
		Lea	GPref_PaltName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Pref_Palt:	Lea	PaltLay,a5	;###
		Jmp	Open_Layer
*---------------
Pref_UsePalt:	Move	PaltList_Len,d0		;###
		Beq.b	PUPa_E
		Jsr	Get_Palt_LAdr	;###
		Tst.l	(a2)
		Beq.b	PUPa_E
		Move	Cur_Palt,Prf_Palette	;Write Palette	###
		Bsr.b	Pref_UpdPaNmD
		Bsr.b	Pref_UpdPaNmG
	PUPa_E:	Rts
*---------------
Pref_RemPalt:	Move	#-1,Prf_Palette		;Write 'No Palette'	###
		Bsr.b	Pref_UpdPaNmD
		Bra.b	Pref_UpdPaNmG
*---------------
Pref_PaltName:	Move	Prf_Palette(pc),d0
		Bmi.b	PPaN_Ed
		Move	d0,Cur_Palt
		Lea	PaltLay,a5	;###
		Tst.l	(a5)
		Beq.b	PPaN_Op
		Jsr	Change_Palt	;###
		Lea	PaltLay,a5	;###
	PPaN_Op:Jmp	Open_Layer	;###
	PPaN_Ed:Rts
*---------------
PrefData:
Prf_GfxFlags:	Dc.b	%00111000
Prf_AudioFlags:	Dc.b	%00000000
Prf_Palette:	Dc	-1
Prf_Depth:	Dc	4
Prf_LoCol:	Dc.b	0
Prf_MdCol:	Dc.b	1
Prf_HiCol:	Dc.b	2
Prf_BkCol:	Dc.b	3
		Blk.b	6,0
*---------------
Pref_UpdScreen:	Bsr.w	Free_Layers
		Bsr.w	Free_Screen
		Bsr.w	Prepare_Screen
		Rts
*---------------
Update_Prefs:	Bsr.w	Upd_Pref_AgaD
		Bsr.w	Upd_Pref_AgaG
		Bsr.w	Pref_UpdPaNmD
		Bsr.w	Pref_UpdPaNmG

		Move	Prf_Palette(pc),d0
		Bmi.b	UP_NPa
		Move	d0,Cur_Palt
		Move.l	PaltList(pc),a4
		Move.l	(a4),a4
		Move	Cur_Palt(pc),d4
		Move.l	#'PALT',d0
		Bsr.w	Load_Unit
		Jsr	Change_Palt	;###
	UP_NPa:
		Bra.w	Update_TitleBar
*---------------
DrawList_Desk:	Dc	'RO'
		Dc.l	Fill_Desk
		
Title_Start:	Dc	'GD'
		Dc.l	$02010005,0,Desk_Quit
		Dc	'BX',000,000,012,010
		Dc	'IM',003,002,7,Im_Close-Im

Help_Upd:	Dc	'BX',013,000,094,010
MemI_Upd:	Dc	'TX',017,008,-01,5
		Dc.l	Mem

		Dc	'GD'
		Dc.l	$02000047,0,Desk_Drag
		Dc	'BX',095,000,-96,010
		Dc	'TX',099,010,-01,8
		Dc.l	Arcade8T
		Dc	'TX',153,010,-01,8
		Dc.l	Factory8T
		Dc	'TX',215,010,-01,8
		Dc.l	Version8T

		Dc	'BX',-95,000,-53,010
TimeI_Upd:	Dc	'TX',-93,008,-01,5
		Dc.l	Time

		Dc	'GD'
		Dc.l	$02010036,0,Desk_Info
		Dc	'BX',-52,000,-40,010
		Dc	'IM',-50,002,7,Im_Info-Im

		Dc	'GD'
		Dc.l	$0201004a,0,Desk_Prefs
		Dc	'BX',-39,000,-27,010
		Dc	'IM',-37,002,7,Im_Prefs-Im

		Dc	'GD'
		Dc.l	$02010048,0,Desk_WorkBench
		Dc	'BX',-26,000,-14,010
		Dc	'IM',-24,002,7,Im_WorkBench-Im

		Dc	'GD'
		Dc.l	$02010049,0,Desk_Depth
		Dc	'BX',-13,000,-01,010
		Dc	'IM',-11,002,7,Im_Depth-Im

		Dc	'XX'
*---------------
DrawList_Quit:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Quit8T

		Dc	'BX',000,011,-1,-1
		Dc	'TX',018,019,-01,5
		Dc.l	SureT

		Dc	'GD'
		Dc.l	$02010000,0,Quit_Quit
		Dc	'BX',003,-21,049,-13
		Dc	'TX',017,-14,-01,5
		Dc.l	QuitT
		
		Dc	'GD'
		Dc.l	$02010000,0,Quit_Clear
		Dc	'BX',050,-21,-04,-13
		Dc	'TX',061,-14,-01,5
		Dc.l	ClearT
		
		Dc	'GD'
		Dc.l	$020100f1,0,0
		Dc	'BX',003,-11,-04,-03
		Dc	'TX',036,-04,-01,5
		Dc.l	CancelT

		Dc	'XX'
*---------------
DrawList_Pref:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Preferences8T

		Dc	'BX',000,011,081,053

		Dc	'RO'
		Dc.l	Upd_Pref_HirD
		Dc	'TX',003,020,-01,5
		Dc.l	HiresT
GPref_Hires:	Dc	'GD'
		Dc.l	$02010000,0,Pref_Hires
		Dc	'BX',070,013,078,021
		Dc	'IM',072,015,5,Im_Blank-Im

		Dc	'RO'
		Dc.l	Upd_Pref_IntD
		Dc	'TX',003,030,-01,5
		Dc.l	InterlaceT
GPref_Interlace:Dc	'GD'
		Dc.l	$02010000,0,Pref_Interlace
		Dc	'BX',070,023,078,031
		Dc	'IM',072,025,5,Im_Blank-Im

		Dc	'TX',003,040,-01,5
		Dc.l	ColorsT
		Dc	'RO'
		Dc.l	Upd_Pref_ColD
		Dc	'GD'
		Dc.l	$02030a00,3,Pref_Colors
		Dc	'RC',040,033,059,041
GPref_Colors:	Dc	'TX',043,040,-01,5
		Dc.l	Pref_ColorsNT
		Dc	'GD'
		Dc.l	$02010000,0,Pref_DelColors
		Dc	'BX',061,033,069,041
		Dc	'IM',063,037,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010000,0,Pref_AddColors
		Dc	'BX',070,033,078,041
		Dc	'IM',072,035,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$02010000,0,Pref_UpdScreen
		Dc	'BX',003,043,078,051
		Dc	'TX',009,050,-01,5
		Dc.l	Pref_UpdScreenT

		Dc	'BX',082,011,-01,053

		Dc	'RO'
		Dc.l	Upd_Pref_AgaD
		Dc	'TX',085,020,-01,5
		Dc.l	AgaT
GPref_Aga:	Dc	'GD'
		Dc.l	$02010000,0,Pref_Aga
		Dc	'BX',-12,013,-04,021
		Dc	'IM',-10,015,5,Im_Blank-Im

		Dc	'RO'
		Dc.l	Upd_Pref_FltD
		Dc	'TX',085,030,-01,5
		Dc.l	FilterT
GPref_Filter:	Dc	'GD'
		Dc.l	$02010000,0,Pref_Filter
		Dc	'BX',-12,023,-04,031
		Dc	'IM',-10,025,5,Im_Blank-Im

		Dc	'BX',000,054,-01,-01

		Dc	'GD'
		Dc.l	$02010000,0,Pref_Palt
		Dc	'BX',003,056,015,068
		Dc	'IM',005,058,9,Im_Palette-Im
		Dc	'GD'
		Dc.l	$02010000,0,Pref_UsePalt
		Dc	'BX',016,056,028,068
		Dc	'IM',018,060,5,Im_Store-Im
		Dc	'RO'
		Dc.l	Pref_UpdPaNmD
		Dc	'GD'
		Dc.l	$02010000,0,Pref_PaltName
GPref_PaltName:	Dc	'BX',029,056,-17,068
		Dc	'TX',032,065,-36,5
		Dc.l	0
		Dc	'GD'
		Dc.l	$02010000,0,Pref_RemPalt
		Dc	'BX',-16,056,-04,068
		Dc	'IM',-14,058,9,Im_ClrClips-Im

		Dc	'XX'

AgaT:		Dc.b	'AGA FEATURES:',0
FilterT:	Dc.b	'AUDIO FILTER:',0
ColorsT:	Dc.b	'COLORS:',0
HiresT:		Dc.b	'HIRES:',0
InterlaceT:	Dc.b	'INTERLACE:',0
Pref_ColorsNT:	Dc.b	' 16',0
Pref_UpdScreenT:Dc.b	'UPDATE SCREEN',0
		Even
*=======================================================================*
*			     S P R I T E S				*
*=======================================================================*
;Sprite_Help:
;	Dc	15,-6,-13
;	Dc	0,0
;	Dc	%0000000000000000,%0000111000000000
;	Dc	%0000111000000000,%0011000110000000
;	Dc	%0011111110000000,%0100000001000000
;	Dc	%0111000111000000,%1000111000100000
;	Dc	%0110000011000000,%1001000100100000
;	Dc	%0000000011000000,%0110000100100000
;	Dc	%0000000110000000,%0000001001000000
;	Dc	%0000001110000000,%0000010001000000
;	Dc	%0000001100000000,%0000010010000000
;	Dc	%0000011000000000,%0000100100000000
;	Dc	%0000011000000000,%0000100100000000
;	Dc	%0000000000000000,%0000011000000000
;	Dc	%0000011000000000,%0000100100000000
;	Dc	%0000011000000000,%0000100100000000
;	Dc	%0000000000000000,%0000011000000000
;	Dc.l	0
Sprite_Arrow:
	Dc	10,-2,-1
	Dc	0,0
	Dc	%0000000000000000,%1111111100000000
	Dc	%0111110000000000,%1000001000000000
	Dc	%0111100000000000,%1000010000000000
	Dc	%0111100000000000,%1000010000000000
	Dc	%0111110000000000,%1000001000000000
	Dc	%0100111000000000,%1011000100000000
	Dc	%0000011100000000,%1100100010000000
	Dc	%0000001110000000,%1000010001000000
	Dc	%0000000100000000,%0000001010000000
	Dc	%0000000000000000,%0000000100000000
	Dc.l	0
Sprite_Cross:
	Dc	15,-8,-7
	Dc	0,0
	Dc	%0000000000000000,%0000001110000000
	Dc	%0000000100000000,%0000001010000000
	Dc	%0000000100000000,%0000001010000000
	Dc	%0000000100000000,%0000001010000000
	Dc	%0000000000000000,%0000001110000000
	Dc	%0000000000000000,%0000000000000000
	Dc	%0000000000000000,%1111100000111110
	Dc	%0111000000011100,%1000100000100010
	Dc	%0000000000000000,%1111100000111110
	Dc	%0000000000000000,%0000000000000000
	Dc	%0000000000000000,%0000001110000000
	Dc	%0000000100000000,%0000001010000000
	Dc	%0000000100000000,%0000001010000000
	Dc	%0000000100000000,%0000001010000000
	Dc	%0000000000000000,%0000001110000000
	Dc.l	0
Sprite_Disk:
	Dc	11,-2,-1
	Dc	0,0
	Dc	%0000000000000000,%1111111111100000
	Dc	%0101111101000000,%1010000010100000
	Dc	%0101111100000000,%1010000011100000
	Dc	%0101111101000000,%1010000010100000
	Dc	%0101111101000000,%1010000010100000
	Dc	%0100000001000000,%1011111110100000
	Dc	%0111111111000000,%1000000000100000
	Dc	%0110000011000000,%1001111100100000
	Dc	%0110100011000000,%1001011100100000
	Dc	%0110100011000000,%1001011100100000
	Dc	%0000000000000000,%0111111111100000
	Dc.l	0
Sprite_Busy:
	Dc	13,-2,-1
	Dc	0,0
	Dc	%0000000000000000,%0000011100000000
	Dc	%0000011100000000,%0001100011000000
	Dc	%0001110111000000,%0010001000100000
	Dc	%0010111111100000,%0101000000010000
	Dc	%0011011101100000,%0100100010010000
	Dc	%0111101011110000,%1000010100001000
	Dc	%0101110111010000,%1010001000101000
	Dc	%0111111111110000,%1000000000001000
	Dc	%0011111111100000,%0100000000010000
	Dc	%0011111111100000,%0100000000010000
	Dc	%0001110111000000,%0010001000100000
	Dc	%0000011100000000,%0001100011000000
	Dc	%0000000000000000,%0000011100000000
	Dc.l	0
Sprite_Null:
	Dc	0,0,0
	Dc	0,0
	Dc.l	0
*---------------
Change_Sprite:	;(A1=Sprite data pointer)
		Move.l	IntBase(pc),a6
		Move.l	Window_Struct(pc),a0
		Move	(a1)+,d0
		Moveq.l	#16,d1
		Move	(a1)+,d2
		Move	(a1)+,d3
	*-- Move image to chip ram
		Move	d0,d4
		Move.l	Mem_PointerBuf(pc),a2
		Addq	#4,a2
		Addq	#4,a1
	CS_Move:Move.l	(a1)+,(a2)+
		Dbf	d4,CS_Move
		
		Move.l	Mem_PointerBuf(pc),a1
		Jmp	SetPointer(a6)
*=======================================================================*
*			       S E L E C T				*
*=======================================================================*
Selc_Prop1:	Bsr.w	Sort_Name_Dir
		Bsr.w	Show_Dir
		Lea	SelcLay(pc),a5
		Lea	Selc_Dir(pc),a4
		Moveq.l	#31,d7
		Bra.w	Draw_Some
*---------------
Selc_SelName:	Move.l	Mem_DirList(pc),a4	;Get DirList start adr

		Lea	SelcProp1(pc),a0
		Move	8(a0),d0
		Mulu	ShowLen(pc),d0
		Divu	#65535,d0
		Move.l	HitGd(pc),a0
		Add.l	6(a0),d0
		Lsl	#2,d0
		Add	d0,a4

		Lea	FileName(pc),a5
		Move.l	(a4)+,a1		;Get item address
		Tst	2(a1)
		Beq.b	IsFile
		Cmp	#-1,2(a1)
		Beq.b	IsDir
		Cmp	#-2,2(a1)
		Beq.w	IsDisk
		Cmp	#-3,2(a1)
		Beq.w	IsUnit
		
		Move.l	4(a1),d0
		Subq	#1,d0
		Move	d0,Unit_Selc
		
		Addq	#8,a1
	SS_NmL0:Move.b	(a1)+,(a5)+
		Bne.b	SS_NmL0

		Lea	SelcLay(pc),a5
		Lea	Selc_PathUpd(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some

		Move.l	Read_Unit(pc),a0
		Move	Unit_Selc(pc),(a0)
		Move.l	8(a0),a0
		Jmp	(a0)

Unit_Selc:	Dc	0

	IsFile:	Addq	#8,a1
	SS_NmL1:Move.b	(a1)+,(a5)+
		Bne.b	SS_NmL1

		Lea	SelcLay(pc),a5
		Lea	Selc_PathUpd(pc),a4
		Moveq.l	#9,d7
		Bra.w	Draw_Some

	IsDir:	Lea	PathName(pc),a0
	NoNull:	Tst.b	(a0)+
		Bne.b	NoNull
		Subq	#1,a0
		Cmp.b	#':',-1(a0)
		Beq.b	HasDiv
		Cmp.b	#'/',-1(a0)
		Beq.b	HasDiv
		Move.b	#'/',(a0)+
	HasDiv:		
		Addq	#8,a1
	SS_NmL2:Move.b	(a1)+,(a0)+
		Bne.b	SS_NmL2
		Subq	#1,a0
		Move.b	#'/',(a0)+
		Clr.b	(a0)+

		Lea	SelcLay(pc),a5
		Lea	Selc_PathUpd(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some

		Bra.w	Directory

	IsDisk:	Lea	PathName(pc),a0
		Addq	#8,a1
	SS_NmL3:Move.b	(a1)+,(a0)+
		Bne.b	SS_NmL3

		Lea	SelcLay(pc),a5
		Lea	Selc_PathUpd(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some

		Bra.w	Directory

	IsUnit:	Lea	Unit_Info(pc),a0
		Move.l	4(a1),d0
		Mulu	Item_Size(pc),d0
		Add.l	d0,a0
		Move.l	a0,Read_Unit
		
		Lea	PathName(pc),a0
		Addq	#8,a1
	SS_NmL4:Move.b	(a1)+,(a0)+
		Bne.b	SS_NmL4
		Move.b	#':',-1(a0)
		Clr.b	(a0)

		Lea	GSelc_Title(pc),a0
		Lea	UnitsDiskT(pc),a1
		Move.l	a1,(a0)
		Lea	Selc_UnitDL(pc),a0
		Move.l	a0,GSelc_Jump

		Lea	SelcLay(pc),a5
		Lea	DrawList_Selc(pc),a4
		Bsr.w	Draw_All

		Bsr.w	Read_UnitList

		Move.l	Read_Unit(pc),a3
		Bra.w	Upd_SelcUnit
*---------------
Selc_Parent:	Lea	PathName(pc),a0
		Move.l	a0,a1
	SP_NulL:Tst.b	(a0)+
		Bne.b	SP_NulL
		Subq	#2,a0

	SP_FDiv:Cmp.l	a1,a0
		Ble.b	SP_Quit
		Subq	#1,a0
		Cmp.b	#':',(a0)
		Beq.b	SP_Foun
		Cmp.b	#'/',(a0)
		Beq.b	SP_Foun
		Bra.b	SP_FDiv
	SP_Foun:Addq	#1,a0
		Clr.b	(a0)

		Lea	SelcLay(pc),a5
		Lea	Selc_PathUpd(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some

		Bsr.w	Directory
	SP_Quit:Rts
*---------------
Selc_Load:	Move.l	Read_Unit(pc),d0
		Bne.b	SL_LdUn
		Bsr.b	Join_FileName
		Bra.w	Load_IFF

	SL_LdUn:Move.l	Read_Unit(pc),a0
		Move.l	16(a0),d0	;'XXXX'
		Move.l	2(a0),a4
		Move.l	(a4),a4
		Move	Unit_Selc(pc),d4
		Bsr.w	Load_Unit

		Move.l	Read_Unit(pc),a0
		Move	Unit_Selc(pc),(a0)
		Move.l	8(a0),a0
		Jmp	(a0)
*---------------
Selc_Save:	Move.l	Read_Unit(pc),a3
		Bra.w	Update_Common
*---------------
Selc_Copy:	Move.l	Read_Unit(pc),d0
		Bne.b	SL_CpUn
		Rts

	SL_CpUn:Move.l	Read_Unit(pc),a0
		Lea	2(a0),a4
		Move.l	2(a0),a2
		Move.l	(a2),a2
	*-- Find Unit
		Move	Unit_Selc(pc),d4
		Ext.l	d4
		Lsl.l	#5,d4
		Add.l	d4,a2
		Tst.l	(a2)
		Beq.b	SC_End
		Move.l	(a2),a2
		Bsr.w	Unit_New
		Move.l	Read_Unit(pc),a0
		Move	d7,(a0)
	*-- Show New Unit
		Move.l	Read_Unit(pc),a0
		Move.l	8(a0),a0
		Jsr	(a0)
		Bsr.w	Read_UnitList
	SC_End:	Rts
*---------------
Join_FileName:	Lea	Comm_FileName(pc),a1
		Lea	PathName(pc),a0
	JFN_L1:	Move.b	(a0)+,(a1)+
		Bne.b	JFN_L1
		Subq	#1,a1
		Cmp.b	#':',-1(a1)
		Beq.b	JFN_Ok
		Cmp.b	#'/',-1(a1)
		Beq.b	JFN_Ok
		Move.b	#'/',(a1)+
	JFN_Ok:	Lea	FileName(pc),a0
	JFN_L2:	Move.b	(a0)+,(a1)+
		Bne.b	JFN_L2
		Rts
*---------------
Ask_Devices:	Clr.l	Read_Unit
		Clr	DirGoing
		Bsr.w	Free_Dir
		Lea	SelcProp1(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Clr	DirLen

		Move.l	Mem_DirList(pc),a3
		Move.l	a3,DirCount

		Move.l	DosBase(pc),a0	;Enter DosBase
		Move.l	34(a0),a0	;Enter RootNode
		Move.l	24(a0),d0	;Enter DosInfo
		Lsl.l	#2,d0		;+
		Move.l	d0,a0		;+
		Move.l	4(a0),d0	;Enter DevList
		Lsl.l	#2,d0		;+
		Move.l	d0,a0		;+
		Move.l	a0,DevList

		Move.l	DevList(pc),a2
	AD_Nxt:	Tst.l	4(a2)		;Is it a Device(=0)? (Dir=1)
		Beq.b	AD_Yes
		Cmp.l	#2,4(a2)	;Is it a Volume(=2)?
		Beq.b	AD_Yes
		Bra.b	AD_Skip		;Skip it

	AD_Yes:	Move.l	40(a2),d0	;Get Name
		Lsl.l	#2,d0		;+
		Move.l	d0,a1		;+
		Move.b	(a1)+,d1	;Get StringLength
		Ext	d1
		Move	d1,d7
		Move.l	a1,a5
	*-- Skip name if found in list.
		Lea	DevSkipList(pc),a3
	AD_CLp:	Tst.l	(a3)
		Beq.b	AD_Ok

		Clr	d0
	AD_Cmp:	Move.b	0(a1,d0.w),d1
		Cmp.b	0(a3,d0.w),d1
		Bne.b	AD_Not
		Addq	#1,d0
		Cmp	#4,d0
		Bne.b	AD_Cmp
		Bra.b	AD_Skip

	AD_Not:	Addq	#4,a3
		Bra.b	AD_CLp

	AD_Ok:	Move.l	DirCount(pc),a3

		Clr.l	d0
		Move	d7,d0		;Save stringlength
		Add	#2+4+2+2,d0	;Add :+Zero, Len, DirFlag, MemSize
		Move	d0,d5
		
		Move.l	#$10000,d1	;Allocate AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,(a3)+

		Move.l	d0,a4
		Move	d5,(a4)+
		Move	#-2,(a4)+
		Move.l	#-1,(a4)+
	AD_Name:Move.b	(a5)+,(a4)+
		Subq	#1,d7
		Bne.b	AD_Name
		Move.b	#':',(a4)

		Addq	#1,DirLen
		Move.l	a3,DirCount

	AD_Skip:Move.l	(a2),d0
		Beq.b	AD_End
		Lsl.l	#2,d0
		Move.l	d0,a2
		Bra.w	AD_Nxt
	AD_End:	Bsr.w	Sort_Name_Dir
		Bra.w	Update_Dir

DevList:	Dc.l	0

DevSkipList:	Dc.b	'PRT',0
		Dc.b	'SER',0
		Dc.b	'PAR',0
		Dc.b	'CON',0
		Dc.b	'RAW',0
		Dc	0
*---------------
Read_UnitList:	Lea	Sprite_Busy(pc),a1
		Bsr.w	Change_Sprite

		Clr	DirGoing
		Bsr.w	Free_Dir
		Lea	SelcProp1(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Clr	DirLen

		Move.l	Mem_DirList(pc),a3
		Move.l	a3,DirCount

		Move.l	Read_Unit(pc),a0
		
		Move	6(a0),d6	;ListLength=0?
		Beq.b	RUL_End

		Move.l	2(a0),a4
		Move.l	(a4),a4
		Clr	UnitCnt
	RUL_Nxt:	
	*-- Count length of string
		Move	4(a4),d0
		Btst	#0,d0
		Beq.b	RUL_Skp

		Move.l	a4,a3
		Addq	#8,a3
		Moveq.l	#0,d7
	RUL_Len:Addq	#1,d7
		Tst.b	(a3)+
		Bne.b	RUL_Len

	RUL_Ok:	Move.l	DirCount(pc),a3

		Clr.l	d0
		Move	d7,d0		;Copy stringlength
		Add	#2+4+2+2,d0	;Add :+Zero, Len, DirFlag, MemSize
		Move	d0,d5
		
		Move.l	#$10000,d1	;Allocate AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,(a3)+

		Move.l	d0,a0
		Move	d5,(a0)+
		Move	#1,(a0)+
		Move	UnitCnt(pc),d0
		Addq	#1,d0
		Ext.l	d0
		Move.l	d0,(a0)+
		Move.l	a4,a5
		Addq	#8,a5
	RUL_Nam:Move.b	(a5)+,(a0)+
		Subq	#1,d7
		Bne.b	RUL_Nam

		Addq	#1,DirLen
		Move.l	a3,DirCount

	RUL_Skp:Add	#32,a4
		Addq	#1,UnitCnt
		Cmp	UnitCnt(pc),d6	;(D6=ListLength)
		Bne.b	RUL_Nxt
	RUL_End:Bsr.w	Sort_Name_Dir
		Bra.w	Update_Dir
Read_Unit:	Dc.l	0
UnitCnt:	Dc	0
*---------------
Ask_Units:	Clr.l	Read_Unit
		Clr	DirGoing
		Bsr.w	Free_Dir
		Lea	SelcProp1(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Clr	DirLen

		Move.l	Mem_DirList(pc),a3
		Move.l	a3,DirCount

		Lea	Unit_Info(pc),a4
		Clr	UnitsCnt
	AU_Nxt:	
	*-- Count length of string
		Move	(a4),d3
		Bmi.b	AU_End
		Move.l	20(a4),a3
		Moveq.l	#0,d7
	AU_Len:	Addq	#1,d7
		Tst.b	(a3)+
		Bne.b	AU_Len

		Move.l	DirCount(pc),a3

		Clr.l	d0
		Move	d7,d0		;Copy stringlength
		Add	#2+4+2+2,d0	;Add :+Zero, Len, DirFlag, MemSize
		Move	d0,d5
		
		Move.l	#$10000,d1	;Allocate AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,(a3)+

		Move.l	d0,a0
		Move	d5,(a0)+
		Move	#-3,(a0)+
		Move	UnitsCnt(pc),d0
		Ext.l	d0
		Move.l	d0,(a0)+
		Move.l	20(a4),a5
	AU_Nam:	Move.b	(a5)+,(a0)+
		Subq	#1,d7
		Bne.b	AU_Nam

		Addq	#1,DirLen
		Move.l	a3,DirCount

		Add	Item_Size(pc),a4
		Addq	#1,UnitsCnt
		Bra.b	AU_Nxt
	AU_End:	Bsr.w	Sort_Name_Dir
		Bra.w	Update_Dir
UnitsCnt:	Dc	0
*---------------
Maybe_Dir:	Move	DirGoing(pc),d0
		Beq.b	MD_End
		Move.l	DirCount(pc),a3

		Move.l	FileLock(pc),d1
		Lea	InfoBlock(pc),a0
		Move.l	a0,d2
		Move.l	DosBase(pc),a6
		Jsr	ExNext(a6)
		Tst.l	d0
		Beq.w	Dir_End

		Lea	InfoBlock(pc),a0
		Addq.l	#8,a0

		Clr.l	d0
	FindNul:Addq	#1,d0		;Search Zero
		Tst.b	(a0)+		;+
		Bne.b	FindNul		;+
		Move	d0,d7		;Save stringlength
		Add	#1+4+2+2,d0	;Add Zero, Len, DirFlag, MemSize
		Move	d0,d5
		
		Move.l	#$10000,d1	;Allocate AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,(a3)+

		Lea	InfoBlock(pc),a0

		Move.l	d0,a4
		Move	d5,(a4)+
		Clr	d2
		Tst.l	4(a0)
		Bmi.b	IsFil
		Moveq.l	#-1,d2
	IsFil:	Move	d2,(a4)+
		Move.l	124(a0),(a4)+
		Addq.l	#8,a0
	NameLp:	Move.b	(a0)+,(a4)+
		Dbf	d7,NameLp

		Addq	#1,DirLen
		Move.l	a3,DirCount

		Cmp	#10,DirLen
		Bgt.b	MD_UpPr
		Bsr.w	Update_Dir
	MD_End:	Rts

	MD_UpPr:Move.l	#$ffff,d0
		Mulu	#10,d0
		Divu	DirLen(pc),d0
		Lea	SelcProp1(pc),a0
		Move	d0,4(a0)

		Lea	SelcLay(pc),a5
		Tst.l	(a5)		;Selector Open?
		Beq.b	MD_End
		Lea	Selc_Prop(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some

	Dir_End:Bsr.w	Sort_Name_Dir
		Bsr.b	Update_Dir
		Clr	DirGoing
		Rts
*---------------
Directory:	Lea	Sprite_Disk(pc),a1
		Bsr.w	Change_Sprite

		Bsr.w	Free_Dir
		Lea	SelcProp1(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		
		Clr.l	Read_Unit

		Clr	DirLen

		Lea	PathName(pc),a0
		Tst.b	(a0)		;No PathName?
		Beq.b	DirErr		;+
		Move.l	a0,d1
		Moveq.l	#-2,d2
		Move.l	DosBase(pc),a6
		Jsr	Lock(a6)
		Move.l	d0,FileLock
		Beq.b	DirErr
		Move.l	FileLock(pc),d1
		Lea	InfoBlock(pc),a0
		Move.l	a0,d2
		Move.l	DosBase(pc),a6
		Jsr	Examine(a6)
		Tst.l	d0
		Beq.b	DirErr

		Move.l	Mem_DirList(pc),a3
		Move.l	a3,DirCount
		Move	#1,DirGoing

	DirErr:	Rts
DirGoing:	Dc	0
DirCount:	Dc.l	0
*---------------
Update_Dir:	Move.l	#$ffff,d0
		Cmp	#10,DirLen
		Ble.b	UD_Tiny
		Mulu	#10,d0
		Divu	DirLen(pc),d0
	UD_Tiny:Lea	SelcProp1(pc),a0
		Move	d0,4(a0)

		Bsr.b	Show_Dir

		Lea	SelcLay(pc),a5
		Tst.l	(a5)		;Selector Open?
		Beq.b	UD_End
		Lea	Selc_Dir(pc),a4
		Moveq.l	#34,d7
		Bsr.w	Draw_Some
	UD_End:	Rts
*---------------
Show_Dir:	Move.l	Mem_DirList(pc),a4	;Get DirList start adr
		Move	DirLen(pc),ShowLen

		Lea	SelcProp1(pc),a0
		Move	8(a0),d0
		Mulu	DirLen(pc),d0
		Divu	#65535,d0
		Lsl	#2,d0
		Add	d0,a4

		Lea	Selc_Dir(pc),a2
		Add	#10,a2		;Add BX
		Lea	SelN01(pc),a5
		Moveq.l	#9,d7
ShowDirL:	Clr.b	(a5)
		Tst.l	(a4)		;Any item here?
		Beq.b	ShowNoDir	;No
		Move.l	(a4)+,a1	;Get item address
	*-- Make dirs white
		Bclr	#0,4(a2)	;It could be a file/unit
		Tst	2(a1)		;Check Dir_Type
		Bpl.b	SD_Fi		;It's a file/unit
		Bset	#0,4(a2)	;It's a dir! Make it white
	SD_Fi:	Add	#14+10+14,a2	;Add GD,DF,TX

		Addq	#8,a1
		Move.l	a5,a3	

		Moveq.l	#25,d1
ShowNameL:	Move.b	(a1)+,d0
		Cmp.b	#'a',d0
		Blo.b	CapsOn
		Cmp.b	#'z',d0
		Bhi.b	CapsOn
		Sub.b	#32,d0
	CapsOn:	Move.b	d0,(a3)+
		Dbf	d1,ShowNameL
		Clr.b	(a3)

ShowNoDir:	Add	#32,a5
		Dbf	d7,ShowDirL
		Rts
ShowLen:	Dc	0
*---------------
Free_Dir:	Clr	Unit_Selc
		Move.l	Mem_DirList(pc),a4	;Get DirList start adr
		Move	DirLen(pc),d7
		Subq	#1,d7
	FD_Lp:	Tst.l	(a4)			;Any item here?
		Beq.b	FD_No			;No
		Move.l	(a4),a1			;Get item address
		Clr.l	(a4)+			;Clear address
		Clr.l	d0			;Get size
		Move	(a1),d0			;+
		Move.l	4.w,a6
		Jsr	FreeMem(a6)
	FD_No:	Dbf	d7,FD_Lp
		Rts
*---------------
Sort_Name_Dir:	Moveq.l	#0,d6
		Move.l	Mem_DirList(pc),a4	;Get DirList start adr
		Move	DirLen(pc),d7		;Get length of dir
		Subq	#2,d7			;Sub for dfb and last
		Blt.b	SN_End			;Less than 2 = nothing to sort
	SN_DirL:Move.l	(a4)+,a0		;Get item and add to next item
		Move.l	(a4),a1			;Get next item
		Addq	#8,a0
		Addq	#8,a1

	SN_Equ:	Move.l	(a1)+,d0
		Cmp.l	(a0)+,d0
		Bhi.b	SN_Ok
		Beq.b	SN_Equ

		Move.l	(a4),d6
		Move.l	-4(a4),(a4)
		Move.l	d6,-4(a4)

	SN_Ok:	Dbf	d7,SN_DirL
		Tst.l	d6
		Bne.b	Sort_Name_Dir
	SN_End:	Rts
*---------------
DirLen:		Dc	0
FileLock:	Dc.l	0
*---------------
Path_Change:	Lea	GSelc_Title(pc),a0
		Lea	ChangePathT(pc),a1
		Move.l	a1,(a0)
		Lea	Selc_ChgPathDL(pc),a0
		Bra.b	Path_Comm
*---------------
Path_Add:	Lea	GSelc_Title(pc),a0
		Lea	AddPathT(pc),a1
		Move.l	a1,(a0)
		Lea	Selc_AddPathDL(pc),a0
Path_Comm:	Move.l	a0,GSelc_Jump
		Lea	SelcLay(pc),a5
		Tst.l	(a5)
		Beq.b	PA_NOp
		Lea	DrawList_Selc(pc),a4
		Bsr.w	Draw_All
	PA_NOp:	Bra.w	Open_Layer
*---------------
Path_Delete:	Move	#1,Game_NeedUpd
		Lea	GPath_Path1(pc),a0
		Moveq.l	#3,d0
	PD_Lp:	Btst	#0,4(a0)
		Bne.b	PD_Fnd
		Add	#38,a0
		Dbf	d0,PD_Lp
		Rts
	PD_Fnd:	Bclr	#0,4(a0)
		Move.l	34(a0),a0
		Clr.b	(a0)
		Bsr.w	Upd_PathListD
		Bra.w	Upd_PathListG
*---------------
Selc_Change:	Move	#1,Game_NeedUpd
		Lea	GPath_Path1(pc),a0
		Moveq.l	#3,d0
	PC_Lp:	Btst	#0,4(a0)
		Bne.b	PC_Fnd
		Add	#38,a0
		Dbf	d0,PC_Lp
		Rts
	PC_Fnd:	Bclr	#0,4(a0)
		Move.l	34(a0),a0
		Bra.w	SA_Vac
*---------------
Selc_Add:	Move	#1,Game_NeedUpd
	*-- Has list memory been allocated?
		Move.l	Mem_PathList(pc),d0
		Beq.b	SA_Mem
	*-- Find vacancy
		Move.l	Mem_PathList(pc),a0
		Move	PathList_Len(pc),d7	;Total
	SA_FVa:	Tst	d7
		Beq.b	SA_Str
		Tst.b	(a0)
		Beq.b	SA_Vac
		Add	#128,a0
		Subq	#1,d7
		Bra.b	SA_FVa
	*-- List needs to be stretched with 128 bytes
	SA_Str:	Lea	SA_MTmp(pc),a4
		Lea	Mem_PathList(pc),a5
		Move.l	(a5),(a4)
		Move.l	4(a5),4(a4)
		Clr.l	(a5)
		Move	PathList_Len(pc),d0
		Addq	#1,d0
		Move	d0,PathList_Len
		Lsl	#7,d0	;*128
		Ext.l	d0
		Move	d0,d5
		Bsr.w	Alloc_Any_Mem

		Move.l	(a5),a1
		Move.l	(a4),a0

		Move	PathList_Len(pc),d0
		Subq	#1,d0
		Lsl	#7,d0	;*128

	SA_CpL:	Move.b	(a0)+,(a1)+
		Subq	#1,d0
		Bne.b	SA_CpL

		Lea	SA_MTmp(pc),a5
		Bsr.w	Free_Mem
		Bra.b	Selc_Add
	*-- Allocate list memory
	SA_Mem:	Lea	Mem_PathList(pc),a5
		Move.l	#128,d0
		Bsr.w	Alloc_Any_Mem
		Move	#1,PathList_Len
		Bra.w	Selc_Add
	*-- We found vacancy. Insert New Path
	SA_Vac:	Lea	PathName(pc),a1
	SA_Lp:	Move.b	(a1)+,d0
		Cmp.b	#'a',d0
		Blo.b	SA_NLo
		Cmp.b	#'z',d0
		Bhi.b	SA_NLo
		Sub	#32,d0
	SA_NLo:	Move.b	d0,(a0)+
		Bne.b	SA_Lp

		Bsr.w	Upd_PathListD
		Bsr.b	Upd_PathListG
		Bsr.b	Upd_PathPropD
		Bsr.b	Upd_PathPropG
	SA_End:	Rts

PathList_Len:	Dc	0
PathList_Skip:	Dc	0
	SA_MTmp:Dc.l	0,0
*---------------
Path_Browse:	Lea	Path_Prop(pc),a2
		Move	4(a2),d0
		Moveq.l	#4,d1
		Swap	d1
		Divu	d0,d1
		Move	8(a2),d0
		Addq	#1,d0
		Mulu	d1,d0
		Divu	#65535,d0
		Move	d0,PathList_Skip
		Bsr.b	Upd_PathListD
		Bra.b	Upd_PathListG
*---------------
Upd_PathPropD:	Moveq.l	#-1,d6
		Move.l	Mem_PathList(pc),d0
		Beq.b	UPP_Ed
		Move	PathList_Len(pc),d1
		Clr	d7
		Move.l	d0,a0
	UPP_Lp:	Tst.b	(a0)
		Beq.b	UPP_No
		Addq	#1,d7
	UPP_No:
		Add	#128,a0
		Subq	#1,d1
		Bne.b	UPP_Lp
		
		Cmp	#4,d7
		Ble.b	UPP_Ed

		Moveq.l	#4,d6
		Swap	d6
		Divu	d7,d6
	UPP_Ed:
		Lea	Path_Prop(pc),a2
		Move	d6,4(a2)
		Rts
*---------------
Upd_PathPropG:	Lea	Path_Prop(pc),a4
		Lea	PathLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Upd_PathListG:	Lea	GPath_Path1(pc),a0	;Unmark all lines
		Moveq.l	#3,d0
	UPLG_L:	Bclr	#0,4(a0)
		Add	#38,a0
		Dbf	d0,UPLG_L

		Lea	PathLay(pc),a5
		Tst.l	(a5)
		Beq.b	UPLG_E
		Lea	GPath_List(pc),a4
		Bsr.w	Draw_All
	UPLG_E:	Rts
*---------------
Upd_PathListD:	Lea	GPath_Path1(pc),a1
		Clr.l	34(a1)
		Clr.l	34+38(a1)
		Clr.l	34+76(a1)
		Clr.l	34+114(a1)
		Move.l	Mem_PathList(pc),d0
		Beq.b	UPL_Ed
		Move.l	d0,a2
		Move	PathList_Len(pc),d7

		Move	PathList_Skip(pc),d0
	UPL_Sk:	Tst	d0
		Beq.b	UPL_Ok
		Tst.b	(a2)
		Beq.b	UPL_Nul
		Subq	#1,d0
	UPL_Nul:Add	#128,a2
		Subq	#1,d7
		Beq.b	UPL_Ed
		Bra.b	UPL_Sk
	UPL_Ok:	

		Moveq.l	#3,d3
	UPL_Lp:	Tst.b	(a2)
		Beq.b	UPL_No
		Move.l	a2,34(a1)
		Add	#38,a1
		Add	#128,a2
		Subq	#1,d7
		Beq.b	UPL_Ed
		Dbf	d3,UPL_Lp
	UPL_Ed:	Rts	

	UPL_No:	Add	#128,a2
		Subq	#1,d7
		Beq.b	UPL_Ed
		Bra.b	UPL_Lp
*---------------
Selc_UpdtAllUnit:
		Move.l	Read_Unit(pc),d0
		Beq.b	SUAU_E
		Move.l	d0,a3
		Jsr	Game_UpdateUnit		;###
	SUAU_E:	Rts
*---------------
Selc_LoadAllUnit:
		Move.l	Read_Unit(pc),d0
		Beq.b	SLAU_E
		Move.l	d0,a3
		Jsr	Game_LoadAllUnit	;###
	SLAU_E:	Rts
*---------------
Selc_SaveAs:	Rts
*---------------
DrawList_Path:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	PathList8T

		Dc	'BX',000,011,-01,23

		Dc	'GD'
		Dc.l	$02010080,0,Path_Add
		Dc	'BX',003,013,037,021
		Dc	'TX',013,020,-01,5
		Dc.l	AddT

		Dc	'GD'
		Dc.l	$0201008a,0,Path_Change
		Dc	'BX',042,013,076,021
		Dc	'TX',045,020,-01,5
		Dc.l	ChangeT

		Dc	'GD'
		Dc.l	$02010081,0,Path_Delete
		Dc	'BX',081,013,115,021
		Dc	'TX',084,020,-01,5
		Dc.l	DeleteT

GPath_List:	Dc	'BX',000,024,-10,-01
		Dc	'RO'
		Dc.l	Upd_PathListD

GPath_Path1:	Dc	'GD'
		Dc.l	$02010682,Path_Excl_List,0
		Dc	'DF',000,025,-10,031
		Dc	'TX',003,031,-14,5
		Dc.l	0

GPath_Path2:	Dc	'GD'
		Dc.l	$02010682,Path_Excl_List,0
		Dc	'DF',000,032,-10,038
		Dc	'TX',003,038,-14,5
		Dc.l	0

GPath_Path3:	Dc	'GD'
		Dc.l	$02010682,Path_Excl_List,0
		Dc	'DF',000,039,-10,045
		Dc	'TX',003,045,-14,5
		Dc.l	0

GPath_Path4:	Dc	'GD'
		Dc.l	$02010682,Path_Excl_List,0
		Dc	'DF',000,046,-10,052
		Dc	'TX',003,052,-14,5
		Dc.l	0

		Dc	'RO'
		Dc.l	Upd_PathPropD

		Dc	'GD'
		Dc.l	$02020000,Path_Prop,Path_Browse
		Dc	'BX',-09,024,-01,-10
		Dc	'BX',-07,026,-03,-12

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

		Dc	'XX'

Path_Excl_List:	Dc.l	GPath_Path1
		Dc.l	GPath_Path2
		Dc.l	GPath_Path3
		Dc.l	GPath_Path4
		Dc.l	0

Path_Prop:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,32767		;KnobX,Y
		Dc	0,0		;PosX,Y
*---------------
DrawList_Selc:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Selector8T
		Dc	'TX',084,009,-01,5
		Dc.l	DashT
		Dc	'TX',093,009,-01,5
GSelc_Title:	Dc.l	GameT

		Dc	'BX',000,011,128,023

		Dc	'GD'
		Dc.l	$0201007d,0,Ask_Units
		Dc	'BX',003,013,041,021
		Dc	'TX',010,020,-01,5
		Dc.l	UnitsT

		Dc	'GD'
		Dc.l	$0201007e,0,Ask_Devices
		Dc	'BX',045,013,083,021
		Dc	'TX',052,020,-01,5
		Dc.l	DisksT

		Dc	'GD'
		Dc.l	$0201007f,0,Selc_Parent
		Dc	'BX',087,013,125,021
		Dc	'TX',092,020,-01,5
		Dc.l	ParentT

Selc_Dir:	Dc	'BX',000,024,119,-28

		Dc	'GD'
		Dc.l	$0201007c,0,Selc_SelName
		Dc	'DF',000,025,119,031
		Dc	'TX',003,031,-58,5
		Dc.l	SelN01
		Dc	'GD'
		Dc.l	$0201007c,1,Selc_SelName
		Dc	'DF',000,032,119,038
		Dc	'TX',003,038,-58,5
		Dc.l	SelN02
		Dc	'GD'
		Dc.l	$0201007c,2,Selc_SelName
		Dc	'DF',000,039,119,045
		Dc	'TX',003,045,-58,5
		Dc.l	SelN03
		Dc	'GD'
		Dc.l	$0201007c,3,Selc_SelName
		Dc	'DF',000,046,119,052
		Dc	'TX',003,052,-58,5
		Dc.l	SelN04
		Dc	'GD'
		Dc.l	$0201007c,4,Selc_SelName
		Dc	'DF',000,053,119,059
		Dc	'TX',003,059,-58,5
		Dc.l	SelN05
		Dc	'GD'
		Dc.l	$0201007c,5,Selc_SelName
		Dc	'DF',000,060,119,066
		Dc	'TX',003,066,-58,5
		Dc.l	SelN06
		Dc	'GD'
		Dc.l	$0201007c,6,Selc_SelName
		Dc	'DF',000,067,119,073
		Dc	'TX',003,073,-58,5
		Dc.l	SelN07
		Dc	'GD'
		Dc.l	$0201007c,7,Selc_SelName
		Dc	'DF',000,074,119,080
		Dc	'TX',003,080,-58,5
		Dc.l	SelN08
		Dc	'GD'
		Dc.l	$0201007c,8,Selc_SelName
		Dc	'DF',000,081,119,087
		Dc	'TX',003,087,-58,5
		Dc.l	SelN09
		Dc	'GD'
		Dc.l	$0201007c,9,Selc_SelName
		Dc	'DF',000,088,119,094
		Dc	'TX',003,094,-58,5
		Dc.l	SelN10

Selc_Prop:	Dc	'GD'
		Dc.l	$02020000,SelcProp1,Selc_Prop1
		Dc	'BX',120,024,128,-28
		Dc	'BX',122,045,126,-38

Selc_PathUpd:	Dc	'BX',000,-27,-01,-01		

		Dc	'TX',003,-17,-01,5
		Dc.l	PathT
		Dc	'GD'
		Dc.l	$02030200,31,Directory
		Dc	'RC',025,-25,-03,-15
		Dc	'TX',028,-15,-31,8
		Dc.l	PathName

		Dc	'TX',003,-05,-01,5
		Dc.l	NameT
		Dc	'GD'
		Dc.l	$02030270,31,0
		Dc	'RC',025,-13,-03,-03
		Dc	'TX',028,-03,-31,8
		Dc.l	FileName

		Dc	'BX',129,011,174,-28

		Dc	'JP'
GSelc_Jump:	Dc.l	Selc_AddPathDL

SelcProp1:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,65535		;KnobX,Y
		Dc	0,0		;PosX,Y

UnitsDiskT:	Dc.b	'UNITS / DISK',0
ChangePathT:	Dc.b	'CHANGE PATH',0
AddPathT:	Dc.b	'ADD PATH',0
		Even
*---------------
Selc_AddPathDL:	Dc	'GD'
		Dc.l	$02010000,0,0	;Selc_MakeDir
		Dc	'BX',132,013,171,021
		Dc	'TX',135,020,-01,5
		Dc.l	MakeDirT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_Add
		Dc	'BX',132,025,171,033
		Dc	'TX',145,032,-01,5
		Dc.l	AddT

		Dc	'GD'
		Dc.l	$020100f1,0,0
		Dc	'BX',132,034,171,042
		Dc	'TX',138,041,-01,5
		Dc.l	CancelT

		Dc	'XX'
*---------------
Selc_ChgPathDL:	Dc	'GD'
		Dc.l	$02010000,0,0	;Selc_MakeDir
		Dc	'BX',132,013,171,021
		Dc	'TX',135,020,-01,5
		Dc.l	MakeDirT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_Change
		Dc	'BX',132,025,171,033
		Dc	'TX',138,032,-01,5
		Dc.l	ChangeT

		Dc	'GD'
		Dc.l	$020100f1,0,0
		Dc	'BX',132,034,171,042
		Dc	'TX',138,041,-01,5
		Dc.l	CancelT

		Dc	'XX'
*---------------
Selc_GameDL:	Dc	'GD'
		Dc.l	$02010000,0,Selc_LoadGame
		Dc	'BX',132,013,171,021
		Dc	'TX',143,020,-01,5
		Dc.l	LoadT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_SaveGame
		Dc	'BX',132,022,171,030
		Dc	'TX',143,029,-01,5
		Dc.l	SaveT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_LoadAllGame
		Dc	'BX',132,034,171,042
		Dc	'TX',135,041,-01,5
		Dc.l	LoadAllT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_UpdtAllGame
		Dc	'BX',132,043,171,051
		Dc	'TX',135,050,-01,5
		Dc.l	UpdtAllT

		Dc	'XX'
*---------------
Selc_UnitDL:	Dc	'GD'
		Dc.l	$02010000,0,Selc_Load
		Dc	'BX',132,013,171,021
		Dc	'TX',143,020,-01,5
		Dc.l	LoadT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_Save
		Dc	'BX',132,022,171,030
		Dc	'TX',143,029,-01,5
		Dc.l	SaveT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_Delete
		Dc	'BX',132,034,171,042
		Dc	'TX',138,041,-01,5
		Dc.l	DeleteT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_Remove
		Dc	'BX',132,043,171,051
		Dc	'TX',138,050,-01,5
		Dc.l	RemoveT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_Copy
		Dc	'BX',132,052,171,060
		Dc	'TX',143,059,-01,5
		Dc.l	CopyT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_SaveAs
		Dc	'BX',132,064,171,072
		Dc	'TX',135,071,-01,5
		Dc.l	SaveAsT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_LoadAllUnit
		Dc	'BX',132,076,171,084
		Dc	'TX',135,083,-01,5
		Dc.l	LoadAllT

		Dc	'GD'
		Dc.l	$02010000,0,Selc_UpdtAllUnit
		Dc	'BX',132,085,171,093
		Dc	'TX',135,092,-01,5
		Dc.l	UpdtAllT

		Dc	'XX'
*=======================================================================*
*			      S Y S T E M				*
*=======================================================================*
Piec_RP:	Blk.b	100,0
Piec_BM:	Dc	0	;00 - BytWidth
		Dc	0	;02 - PixelHeight
		Dc.b	0	;04
		Dc.b	0	;05 - Depth
		Dc	0	;06
		Blk.l	8,0	;08 - Bitplanes
*---------------
Common_Undo:	Move.l	Undoable(pc),d0
		Beq.b	CU_End
		Move.l	d0,a3
		Bsr.b	Unit_Undo
		Move.l	8(a3),a0
		Jsr	(a0)
	CU_End:	Rts
Undoable:	Dc.l	0
*---------------
Unit_Undo:
	*-- Get list address (A2)
		Bsr.w	Get_Unit_LAdr
		Tst.l	(a2)
		Beq.b	UU_End
		Move.l	a2,UU_LAdr
	*-- Copy buffer to buffer2
		Move.l	12(a3),a0	;Get Mem_UnitBuf
		Lea	UU_Mem2(pc),a1
		Move.l	(a0),(a1)
		Beq.b	UU_End
		Move.l	4(a0),4(a1)
		Clr.l	(a0)
		Bsr.w	Update_UnitBuf
	*-- Free old Anim
		Move.l	UU_LAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Anim
		Clr.l	d0
		Move.l	UU_Mem2(pc),a0
		Move.l	2(a0),d0
		Cmp.l	#'PIEC',16(a3)
		Beq.b	UU_Ch
		Cmp.l	#'SMPL',16(a3)
		Beq.b	UU_Ch
		Moveq.l	#0,d1			;AnyMem
		Bra.b	UU_Ok
	UU_Ch:	Moveq.l	#2,d1			;ChipMem
	UU_Ok:	Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	UU_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_MemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Copy buffer2 to Anim
		Move.l	(a0),a1			;Get Anim address
		Move.l	UU_Mem2(pc),a2		;Get buffer address
		Move.l	2(a2),d0		;Length
		Subq	#1,d0
	UU_CLp:	Move.b	(a2)+,(a1)+
		Dbf	d0,UU_CLp
	*-- Free old buffer2
		Lea	UU_Mem2(pc),a5
		Bsr.w	Free_Mem
	UU_End:	Rts
	UU_LAdr:Dc.l	0
	UU_Mem2:Dc.l	0,0
*---------------
Free_All_Lists:	Lea	Unit_Info(pc),a5;Get start of info list
	FAL_Lp:	Tst.l	(a5)		;End of pointers?
		Bmi.b	FAL_Ed		;Yes
		Bsr.b	Free_List	;Free list
		Add	Item_Size(pc),a5;Next list
		Bra.b	FAL_Lp		;Loop
	FAL_Ed:	Rts			;End
*---------------
Free_List:	;( A5=List Pointer Address )
		Move.l	2(a5),a4	;Get XxxxList pointer
		Tst.l	(a4)		;Any list?
		Beq.b	FL_Ed		;No
		Move.l	(a4),a4		;Get XxxxList
		Move	6(a5),d7	;Get length of list for counter
		Beq.b	FL_Ed		;List is already empty
		Clr	6(a5)		;Set length=0
	FL_Lp:	Bsr.b	Free_Unit	;Free the Unit
		Add	#32,a4		;Next Unit
		Subq	#1,d7		;Count
		Bne.b	FL_Lp		;Finished?
	FL_Ed:	Rts			;End
*---------------
Free_Unit:	;( A4=Unit Address )
		Tst.l	(a4)		;Any unit here?
		Beq.b	FU_NoUn		;No
		Move.l	(a4),a1		;Get Unit Address
		Move.l	02(a1),d0	;Get Unit Size
		Clr.l	(a4)		;Clear Unit from list
		And	#~2,4(a4)	;Clear NeedsUpdate
		Move.l	4.w,a6		;Free its memory
		Jsr	FreeMem(a6)	;+
	FU_NoUn:Rts			;End
*---------------
ZPixel:		;(D0=X, D1=Y, A5=Layer, A4=Clip)
		Tst.l	(a5)
		Beq.b	ZPixE
		Move.l	d0,-(a7)
		Bsr.w	Calc_Coord
		Move.l	(a7)+,d0
		
		Mulu	DrawRes(pc),d0
		Add	X1(pc),d0
		Move	d0,d2
		Add	DrawRes(pc),d2
		Subq	#1,d2

		Cmp	X2(pc),d0
		Bge.b	ZPixE
		Cmp	X2(pc),d2
		Blt.b	ZPixX
		Move	X2(pc),d2
		;Subq	#1,d2

	ZPixX:	Mulu	DrawRes(pc),d1
		Add	Y1(pc),d1
		Move	d1,d3
		Add	DrawRes(pc),d3
		;Subq	#1,d3

		Cmp	Y2(pc),d1
		Bge.b	ZPixE
		Cmp	Y2(pc),d3
		Blt.b	ZPixY
		Move	Y2(pc),d3
		Subq	#1,d3

	ZPixY:	Move.l	(a5),a1
		Move.l	12(a1),a1
		Move.l	GfxBase(pc),a6
		Jsr	RectFill(a6)
	ZPixE:	Rts
*---------------
ZBox:		;(D0=X1, D1=Y1, D2=X2, D3=Y2, A5=Layer, A4=Clip)
		Tst.l	(a5)
		Beq.w	ZBoxE
		Move.l	d0,-(a7)
		Bsr.w	Calc_Coord
		Move.l	(a7)+,d0
		
		Muls	DrawRes(pc),d0
		Add	X1(pc),d0
		Muls	DrawRes(pc),d2
		Add	DrawRes(pc),d2
		Add	X1(pc),d2
		Subq	#1,d2

		Cmp	X1(pc),d2
		Blt.b	ZBoxE
		Cmp	X1(pc),d0
		Bge.b	ZBoxXU
		Move	X1(pc),d0
	ZBoxXU:	Cmp	X2(pc),d0
		Bgt.b	ZBoxE
		Cmp	X2(pc),d2
		Blt.b	ZBoxX
		Move	X2(pc),d2
		;Subq	#1,d2

	ZBoxX:	Muls	DrawRes(pc),d1
		Add	Y1(pc),d1
		Muls	DrawRes(pc),d3
		Add	DrawRes(pc),d3
		Add	Y1(pc),d3
		Subq	#1,d3

		Cmp	Y1(pc),d3
		Blt.b	ZBoxE
		Cmp	Y1(pc),d1
		Bge.b	ZBoxYU
		Move	Y1(pc),d1
	ZBoxYU:	Cmp	Y2(pc),d1
		Bgt.b	ZBoxE
		Cmp	Y2(pc),d3
		Blt.b	ZBoxY
		Move	Y2(pc),d3
		;Subq	#1,d3

	ZBoxY:	Move.l	(a5),a1
		Move.l	12(a1),a1
		Move.l	GfxBase(pc),a6
		Jsr	RectFill(a6)
	ZBoxE:	Rts
*---------------
ZLine:		;(D0=X1, D1=Y1, D2=X2, D3=Y2, A5=Layer, A4=Clip)
	*++
		Rts
DrawRes:	Dc	1
*---------------
Free_Layers:	Lea	LayerList(pc),a5
	FL_Lop:	Tst.l	(a5)
		Bmi.b	FL_End
		Bsr.b	Close_Layer
		Add	#30,a5
		Bra.b	FL_Lop
	FL_End:	Rts
*---------------
Close_Layer:	;(A5=Layer)
		Tst.l	(a5)
		Beq.b	NoLay
		Move.l	LayBase(pc),a6
		Move.l	Layer_Info(pc),a0
		Move.l	(a5),a1
		Jsr	DeleteLayer(a6)
		Clr.l	(a5)
	
		Move.l	GfxBase(pc),a6
		Lea	DeskLay(pc),a4
		Tst.l	(a4)
		Beq.b	NoLay
		Move.l	(a4),a4
		Move.l	12(a4),a4
		Move.l	a4,a1
		Move	BkCol(pc),d0
		Jsr	SetAPen(a6)
		Move.l	a4,a1
		Move	08(a5),d0
		Move	10(a5),d1
		Move	12(a5),d2
		Move	14(a5),d3
		Jsr	RectFill(a6)
	NoLay:	Rts
*---------------
Get_File_Length:;(A0=FileName, D7->Length)
		Move.l	DosBase(pc),a6
		Move.l	a0,d1
		Moveq.l	#-2,d2
		Jsr	Lock(a6)
		Move.l	d0,d6
		Beq.b	FLFail
		Move.l	d6,d1
		Lea	InfoBlock(pc),a0
		Move.l	a0,d2
		Jsr	Examine(a6)
		Move.l	d6,d1
		Jsr	UnLock(a6)
		Lea	InfoBlock(pc),a0
		Move.l	124(a0),d7
		Rts
	FLFail:	Clr.l	d7
		Rts
*---------------
Delete_File:	;(A0=FileName, D7->Status)
		Move.l	a0,d1
		Move.l	DosBase(pc),a6
		Jsr	DeleteFile(a6)
		Move.l	d0,d7
		Rts
*---------------
Open_New_File:	;(A0=FileName, D7->Status)
		Move.l	#1006,d2
		Bra.b	Open_File
*---------------
Open_Old_File:	;(A0=FileName, D7->Status)
		Move.l	#1005,d2
Open_File:	Move.l	a0,d1
		Move.l	DosBase(pc),a6
		Jsr	Open(a6)
		Lea	File_Handle(pc),a0
		Move.l	d0,(a0)
		Move.l	d0,d7
		Rts
File_Handle:	Dc.l	0
*---------------
Read_File:	;(A0=Address, D0=Length)
		Move.l	a0,d2
		Move.l	d0,d3
		Move.l	File_Handle(pc),d1
		Move.l	DosBase(pc),a6
		Jmp	Read(a6)
*---------------
Write_File:	;(A0=Address, D0=Length)
		Move.l	a0,d2
		Move.l	d0,d3
		Move.l	File_Handle(pc),d1
		Move.l	DosBase(pc),a6
		Jmp	Write(a6)
*---------------
Close_File:	Move.l	File_Handle(pc),d1
		Beq.b	CF_Ed
		Move.l	DosBase(pc),a6
		Jsr	Close(a6)
		Clr.l	File_Handle
	CF_Ed:	Rts
*---------------
Unnamed:	;(Store name in Unit List. A0=Address)
		Move	#1,Game_NeedUpd
		Move.l	#'UNNA',08(a0)
		Move.l	#'MED ',12(a0)

		Move	UN_Cnt(pc),d0
		Lea	20(a0),a1
		Moveq.l	#3,d6
	UN_Lp:	And.l	#$ffff,d0
		Divu	#10,d0
		Move.l	d0,d3
		Swap	d3
		Add.b	#48,d3
		Move.b	d3,-(a1)
		Dbf	d6,UN_Lp

		Clr.l	20(a0)
		Clr.l	24(a0)
		Clr.l	28(a0)
		Addq	#1,UN_Cnt	;Create new 4 digits
		Rts
	UN_Cnt:	Dc	0
*---------------
Keyboard_Init:	;(Initialize Keyboard)
		Move.l	4.w,a6			;ExecBase
		Lea	ConName(pc),a0		;Get "console.device"
		Lea	IO_Req(pc),a1		;IO Buffer
		Moveq.l	#-1,d0			;Flags
		Moveq.l	#0,d1			;Unit
		Jsr	OpenDevice(a6)		;Open Console.Device
		Tst.l	d0			;Error?
		Bne.b	KI_End			;Yes
		Move.l	IO_Req+20(pc),ConBase	;Get Console Device
	KI_End:	Rts
ConName:	Dc.b	'console.device',0,0
ConBase:	Dc.l	0
*---------------
Keyboard_Exit:	;(Exit Keyboard)
		Lea	IO_Req(pc),a1
		Move.l	4.w,a6
		Jmp	CloseDevice(a6)
	IO_Req:	Blk.b	32,0
*---------------
Update_Title:	Btst	#4,Prf_GfxFlags
		Beq.b	UT_End
		Bsr.w	Info_Desk
		Lea	DeskLay(pc),a5
		Lea	MemI_Upd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some
		Lea	TimeI_Upd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some
	UT_End:	Rts
*---------------
Init_Task:	Move.l	4.w,a6
		Sub.l	a1,a1
		Jsr	FindTask(a6)
		Move.l	d0,Own_Task
		Move.l	d0,a4		;Start from Workbench?
		Tst.l	172(a4)		;PR_CLI
		Bne.b	NoWB1
		Lea	92(a4),a0	;Get Message PR_MsgPort
		Jsr	WaitPort(a6)
		Lea	92(a4),a0	;PR_MsgPort
		Jsr	GetMsg(a6)
		Move.l	d0,WBenchMsg
	NoWB1:	Rts
*---------------
End_Task:	Move.l	WBenchMsg(pc),d0
		Beq.b	NoWB2
		Move.l	4.w,a6
		Jsr	Forbid(a6)
		Move.l	WBenchMsg(pc),a1
		Jsr	ReplyMsg(a6)
	NoWB2:	Moveq.l	#0,d0
		Rts
WBenchMsg:	Dc.l 0
Own_Task:	Dc.l 0
*---------------
Fatal_Error:	;(A0=Pointer to Error Message)
		Move.l	#103,ReturnCode	;ReturnCode = OutOfMemory!
		Move.l	4.w,a6
		Lea	AlertLb(pc),a1
		Clr.l	d0
		Jsr	OpenLibrary(a6)
		Move.l	d0,d2
		Beq.b	AlertEd
		Move.l	d2,a6
		Clr.l	d0
		Lea	AlertTx(pc),a0
		Moveq.l	#45,d1
		Jsr	DisplayAlert(a6)
		Move.l	4.w,a6
		Move.l	d2,a1
		Jsr	CloseLibrary(a6)
	AlertEd:Bra.w	End
	AlertLb:Dc.b	'intuition.library',0
	AlertTx:Dc.b	0,104,13
		Dc.b	'A r c a d e  F a c t o r y   '
		Dc.b	'E r r o r   R e p o r t'
		Dc.b	0,1,0,140,24
		Dc.b	"Unable to start! Probably not enough memory."
		Dc.b	0,1,0,212,35,'(Press any mouse button!)',0,0
*---------------
Prepare_Memory:	;(Allocate memory on startup)
		Lea	Mem_ImageBuf(pc),a5
		Moveq.l	#32,d0
		Bsr.w	Alloc_Chip_Mem
		Beq.w	Fatal_Error

		Lea	Mem_PointerBuf(pc),a5
		Moveq.l	#72,d0
		Bsr.w	Alloc_Chip_Mem
		Beq.w	Fatal_Error

		Lea	Mem_Clip(pc),a5
		Move.l	#4096,d0
		Bsr.w	Alloc_Any_Mem
		Beq.w	Fatal_Error
		Bsr.w	Clr_Clip_List

		Lea	Mem_DirList(pc),a5
		Move.l	#4*2048,d0
		Bsr.w	Alloc_Any_Mem
		Beq.w	Fatal_Error

		Lea	Mem_FreeHand(pc),a5
		Move.l	#4096,d0
		Bsr.w	Alloc_Any_Mem
		Beq.w	Fatal_Error

		Lea	Mem_ScrnText(pc),a5
		Move.l	#2048,d0
		Bsr.w	Alloc_Any_Mem
		Beq.w	Fatal_Error

		Lea	Mem_Null(pc),a5
		Moveq.l	#8,d0
		Bsr.w	Alloc_Chip_Mem
		Beq.w	Fatal_Error

		Lea	Mem_Palette(pc),a5
		Move.l	#1024,d0
		Bsr.w	Alloc_Any_Mem
		Beq.w	Fatal_Error

		Move.l	Mem_Palette(pc),a0
		Lea	Def_Palette(pc),a1
	DPal_L:	Clr	d0
		Move.b	(a1)+,d0
		Bmi.b	DPal_E
		Lsl	#2,d0
		Move.b	(a1)+,1(a0,d0.w)
		Move.b	(a1)+,2(a0,d0.w)
		Move.b	(a1)+,3(a0,d0.w)
		Bra.b	DPal_L

	DPal_E:	Rts

Def_Palette:	Dc.l	$00000000,$01332233,$04443355,$02665577
		Dc.l	$059988aa,$06ccbbdd,$03eeddff,$070000ff
		Dc.l	$084444ff,$098888ff,$0a008800,$0b00ff00
		Dc.l	$0c88ff88,$0dff0000,$0eff6600,$0fffdd00
		Dc.l	$11ffdd00,$12000000,$ff000000
*---------------
Free_Memories:	Lea	Memory_List(pc),a5
	FM_Loop:Tst.l	(a5)
		Bmi.b	FM_End
		Bsr.w	Free_Mem
		Addq.l	#8,a5
		Bra.b	FM_Loop
	FM_End:	Rts
*---------------
Prepare_Libs:	Lea	IntBase(pc),a2
		Bsr.b	OpLib
		Beq.w	Fatal_Error
		Lea	DosBase(pc),a2
		Bsr.b	OpLib
		Beq.w	Fatal_Error
		Lea	GfxBase(pc),a2
		Bsr.b	OpLib
		Beq.w	Fatal_Error
		Lea	LayBase(pc),a2
		Bsr.b	OpLib
		Beq.w	Fatal_Error
		Rts
	OpLib:	Tst.l	(a2)		;*** Library opened?
		Bne.b	LibOpen		;*** Yes, abort
		Move.l	4.w,a6		;Get ExecBase
		Lea	4(a2),a1	;Get library name
		Clr.l	d0		;Any version
		Jsr	OpenLibrary(a6)	;Call OpenLibrary
		Move.l	d0,(a2)		;Save library base
	LibOpen:Rts			;Label = ***
*---------------
Free_Libs:	Lea	LayBase(pc),a2
		Bsr.b	ClLib
		Lea	GfxBase(pc),a2
		Bsr.b	ClLib
		Lea	DosBase(pc),a2
		Bsr.b	ClLib
		Lea	IntBase(pc),a2
		Bra.w	ClLib

	ClLib:	Move.l	4.w,a6		;Get ExecBase
		Tst.l	(a2)		;Library opened?
		Beq.s	LibClsd		;No, abort
		Move.l	(a2),a1		;Get library base
		Jsr	CloseLibrary(a6);Call CloseLibrary
		Clr.l	(a2)		;*** Clear library base
	LibClsd:Rts
*---------------
Prepare_Screen:	;(Open Screen, Backdrop Window, and LayerInfo)
	*-- Read Preferences
		Move	Prf_Depth(pc),Screen_Depth
		Lea	DeskLay(pc),a0
		Moveq.l	#$0002,d0
		Move	#320,Screen_XSize
		Move	#320,Window_XSize
		Move	#319,12(a0)
		Move	#319,LimX2
		Btst	#1,Prf_GfxFlags
		Beq.b	NHi
		Bset	#15,d0
		Move	#640,Screen_XSize
		Move	#640,Window_XSize
		Move	#639,12(a0)
		Move	#639,LimX2
	NHi:
		Move	#256,Screen_YSize
		Move	#256,Window_YSize
		Move	#255,14(a0)
		Move	#255,LimY2
		Btst	#2,Prf_GfxFlags
		Beq.b	NIn
		Bset	#2,d0
		Move	#512,Screen_YSize
		Move	#512,Window_YSize
		Move	#511,14(a0)
		Move	#511,LimY2
	NIn:	Move	d0,Screen_ViewModes
	*-- Prepare Screen
		Move.l	Screen_Struct(pc),d0	;Screen Opened?
		Bne.b	ScrOpen			;Yes, Abort
		Move.l	IntBase(pc),a6		;Get IntBase
		Lea	NewScreen_Struct(pc),a0	;Get NewScreen Structure
		Jsr	OpenScreen(a6)		;Open Screen
		Lea	Screen_Struct(pc),a0	;Save Screen Struct
		Move.l	d0,(a0)			;+
		Beq.w	Fatal_Error		;If Error, Abort
		Lea	WinScr(pc),a0		;ScrStruct into WinDefs
		Move.l	d0,(a0)			;+
		Move.l	Screen_Struct(pc),a0	;Write Palette to Screen
		Bsr.w	Write_Palette		;+
		Move.l	IntBase(pc),a6		;Get IntBase
		Lea	NewWindow_Struct(pc),a0	;Get NewWindow Structure
		Jsr	OpenWindow(a6)		;Open Window
		Lea	Window_Struct(pc),a0	;Save Window Address
		Move.l	d0,(a0)			;+
		Beq.w	Fatal_Error		;If Error, Abort
		Move.l	d0,a1			;Get Message Port Adr
		Lea	Message_Port(pc),a0	;+
		Move.l	86(a1),(a0)		;+
		Move.l	LayBase(pc),a6		;Get LayBase
		Jsr	NewLayerInfo(a6)	;Create Layer Info
		Lea	Layer_Info(pc),a0	;Save Layer Info Address
		Move.l	d0,(a0)			;+
		Beq.w	Fatal_Error		;If Error, Abort
		Bsr.w	Find_Colors		;Find suitable colors
		Lea	DeskLay(pc),a5		;Open Desk Layer
		Bsr.w	Open_Layer		;+
		Beq.w	Fatal_Error		;Error?
		Bsr.w	Update_Title		;Update TitleBar
		Move.l	IntBase(pc),a6		;Screen to front
		Move.l	Screen_Struct(pc),a0	;+
		Jsr	ScreenToFront(a6)	;+
	ScrOpen:Rts				;End
*---------------
Free_Screen:	;(Close LayerInfo, Backdrop Window and Screen)
		Move.l	Layer_Info(pc),d0	;LayerInfo Exists?
		Beq.b	NoLyI			;No, Skip Dispose
		Move.l	Layer_Info(pc),a0	;Get LayerInfo
		Move.l	LayBase(pc),a6		;Get LayBase
		Jsr	DisposeLayerInfo(a6)	;Dispose LayerInfo
		Lea	Layer_Info(pc),a0	;Clear LayerInfo
		Clr.l	(a0)			;+
	NoLyI:	Move.l	Window_Struct(pc),d0	;Window Open?
		Beq.b	NoWin			;No, Skip Close
		Move.l	d0,a0			;Get Window Address
		Move.l	IntBase(pc),a6		;Get IntBase
		Jsr	CloseWindow(a6)		;Close Window
		Lea	Window_Struct(pc),a0	;Clear Window Address
		Clr.l	(a0)			;+
	NoWin:	Move.l	Screen_Struct(pc),d0	;Screen Opened?
		Beq.b	NoScr			;No, Abort
		Move.l	d0,a0			;Get Screen Struct
		Move.l	IntBase(pc),a6		;Get IntBase
		Jsr	CloseScreen(a6)		;Call CloseScreen
		Lea	Screen_Struct(pc),a0	;Clear Screen Handle
		Clr.l	(a0)			;+
	NoScr:	Rts				;End
*---------------
NewWindow_Struct:
		Dc	0,0	;X/Y-Position
Window_XSize:	Dc	320	;X-Size
Window_YSize:	Dc	256	;Y-Size
		Dc.b	0,0	;Detail/Block Pen
		Dc.l	$418	;IDCMP=MouseMove+MouseButtons+RawKeys
		Dc.l	$11840	;Flags=RMBTrap+Activate+Borderless+Simple
		Dc.l	0,0,0	;Gadgets, Checkmark, Text
WinScr:		Dc.l	0	;Screen
		Dc.l	0	;BitMap
		Dc	0,0	;Min X/Y
		Dc	640,512	;Max X/Y
		Dc	15	;Screen Type
*---------------
ReDraw_All:	Bsr.w	Find_Colors
		Move.l	Screen_Struct(pc),a0
		Bsr.w	Write_Palette
		Lea	LayerList(pc),a5
	RD_Lp:	Tst.l	(a5)
		Bmi.b	RD_End
		Beq.b	RD_Clsd
		Move.l	18(a5),a4
		Bsr.w	Draw_All
	RD_Clsd:Add	#30,a5
		Bra.b	RD_Lp
	RD_End:	Rts
*---------------
DrawDF:		Add	#10,a4
		Bra.w	Draw_Next
*---------------
DrawJS:		Addq	#6,a4
		Move.l	a4,RetAdr
		Move.l	-4(a4),a4
		Bra.w	Draw_Next
*---------------
DrawRT:		Move.l	RetAdr(pc),a4
		Bra.w	Draw_Next
	RetAdr:	Dc.l	0
*---------------
DrawRO:		Move.l	02(a4),a0
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	(a0)
		Movem.l	(a7)+,d0-d7/a0-a6
		Addq	#6,a4
		Bra.w	Draw_Next
*---------------
DrawJP:		Move.l	02(a4),a4
		Bra.w	Draw_Next
*---------------
DrawGD:		Cmp.b	#$02,3(a4)
		Bne.b	DrawGD1
		Move.l	a5,LayL
		Move.l	a4,HitGd
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	UpdateProp
		Movem.l	(a7)+,d0-d7/a0-a6
	DrawGD1:Clr.b	Invert
		Btst	#0,4(a4)
		Beq.b	DrawGDE
		Move.b	2(a4),Invert
		Addq.b	#1,Invert
	DrawGDE:Add	#14,a4
		Bra.w	Draw_Next
*---------------
DrawRC:		Bsr.w	Calc_Coord
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	HiCol(pc),d0
		Move.b	Invert(pc),d1
		Bne.b	DrawRC1
		Move	LoCol(pc),d0
	DrawRC1:Jsr	SetAPen(a6)
		Bsr.w	DL_Rectangle
		Move.l	a3,a1
		Move	MdCol(pc),d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Move	X2(pc),d2
		Move	Y2(pc),d3
		Addq	#1,d0
		Addq	#1,d1
		Subq	#1,d2
		Subq	#1,d3
		Cmp	d0,d2
		Ble.b	DrawRC2
		Cmp	d1,d3
		Ble.b	DrawRC2
		Jsr	RectFill(a6)
	DrawRC2:Add	#10,a4
		Bra.w	Draw_Next
*---------------
DrawBX:		Bsr.w	Calc_Coord
		Bsr.w	DL_3DBox
		Move.l	a3,a1
		Move	MdCol(pc),d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Move	X2(pc),d2
		Move	Y2(pc),d3
		Addq	#1,d0
		Addq	#1,d1
		Subq	#1,d2
		Subq	#1,d3
		Cmp	d0,d2
		Ble.b	DrawBX1
		Cmp	d1,d3
		Ble.b	DrawBX1
		Jsr	RectFill(a6)
	DrawBX1:Add	#10,a4
		Bra.w	Draw_Next
*---------------
DrawFR:		Bsr.w	Calc_Coord
		Move.b	Invert(pc),d6
		Clr.b	Invert
		Bsr.w	DL_3DBox
		Move.l	a3,a1
		Move	MdCol(pc),d0
		Jsr	SetAPen(a6)
		Addq	#1,X1
		Addq	#1,Y1
		Subq	#1,X2
		Subq	#1,Y2
		Bsr.w	DL_Rectangle
		Addq	#1,X1
		Addq	#1,Y1
		Subq	#1,X2
		Subq	#1,Y2
		Not.b	Invert
		Bsr.w	DL_3DBox
		Move.b	d6,Invert
		Addq	#1,X1
		Addq	#1,Y1
		Subq	#1,X2
		Subq	#1,Y2
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Move	X2(pc),d2
		Move	Y2(pc),d3
		Jsr	RectFill(a6)
		Add	#10,a4
		Bra.w	Draw_Next
*---------------
DrawTX:		Move.l	a3,a1
		Move	8(a4),d0
		Cmp	#5,d0
		Bne.b	DrawTX5
		Lea	Font5,a0
	DrawTX5:
		Cmp	#8,d0
		Bne.b	DrawTX8
		Lea	Font8,a0
	DrawTX8:
		Move.l	(a0),a0
		Jsr	SetFont(a6)
		Move.l	a3,a1
		Move	HiCol(pc),d0
		Move.b	Invert(pc),d1
		Bne.b	DrawTX1
		Move	LoCol(pc),d0
	DrawTX1:Jsr	SetAPen(a6)
		Move.l	a3,a1
		Moveq.l	#1,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Bsr.w	Calc_Coord
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Jsr	Move(a6)
		;Move.l	a3,a1		;Find Background Color
		;Move	X1(pc),d0
		;Move	Y1(pc),d1
		;Subq	#1,d0
		;Subq	#1,d1
		;Jsr	ReadPixel(a6)
			Move	MdCol(pc),d0
		Move.l	a3,a1
		Jsr	SetBPen(a6)	
		Clr	d3
		Move.l	10(a4),d0
		Beq.b	DrawTX2
		Move.l	d0,a2
	DrawTX3:Addq	#1,d3
		Tst.b	(a2)+
		Bne.b	DrawTX3
	DrawTX4:Subq	#1,d3
		Ble.b	DrawTX2
		Move	d3,d0
		Move.l	10(a4),a0
		Move.l	a3,a1
		Jsr	TextLength(a6)
		Cmp	X2(pc),d0
		Bgt.b	DrawTX4

		Move	d3,d0
		Move.l	10(a4),a0
		Move.l	a3,a1
		Jsr	Text(a6)
	DrawTX2:Add	#14,a4
		Bra.w	Draw_Next
*---------------
DrawIM:		Move.l	a3,a1
		Move	HiCol(pc),d0
		Move.b	Invert(pc),d1
		Bne.b	DrawIM1
		Move	LoCol(pc),d0
	DrawIM1:Jsr	SetAPen(a6)
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Bsr.w	Calc_Coord
	*-- Move Image to chipram incase it's in fastram
		Move.l	Mem_ImageBuf(pc),a0
		Lea	Im,a1	;###
		Add	8(a4),a1
		Move.l	a0,a2
		Move	6(a4),d0
		Move	d0,d5
		Subq	#1,d0
	DrawIM2:Move	(a1)+,(a2)+
		Dbf	d0,DrawIM2

		Moveq.l	#7,d0
		Moveq.l	#2,d1
		Move.l	a3,a1
		Move	X1(pc),d2
		Move	Y1(pc),d3
		Moveq.l	#9,d4
		Jsr	BltTemplate(a6)
		Add	#10,a4
		Bra.w	Draw_Next
*---------------
DL_3DBox:	Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	HiCol(pc),d0
		Move.b	Invert(pc),d1
		Bne.b	DL_3DBox_Inv1
		Move	LoCol(pc),d0
DL_3DBox_Inv1:	Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X2(pc),d0
		Move	Y1(pc),d1
		Jsr	Move(a6)
		Move.l	a3,a1
		Move	X2(pc),d0
		Move	Y2(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Addq	#1,d0
		Move	Y2(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	LoCol(pc),d0
		Move.b	Invert(pc),d1
		Bne.b	DL_3DBox_Inv2
		Move	HiCol(pc),d0
DL_3DBox_Inv2:	Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y2(pc),d1
		Jsr	Move(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	X2(pc),d0
		Subq	#1,d0
		Move	Y1(pc),d1
		Jmp	Draw(a6)
*---------------
DL_Rectangle:	Move.l	a3,a1
		Move	X2(pc),d0
		Move	Y1(pc),d1
		Jsr	Move(a6)
		Move.l	a3,a1
		Move	X2(pc),d0
		Move	Y2(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y2(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	X2(pc),d0
		Move	Y1(pc),d1
		Jmp	Draw(a6)
*---------------
Gadgets:	;(Gadget handler routine)
		Move.l	Message_Port(pc),a0	;Get Message
		Move.l	4.w,a6			;+
		Jsr	GetMsg(a6)		;+
		Lea	Message(pc),a0		;+
		Move.l	d0,(a0)			;+
		Beq.b	GdEnd			;No message
		Move.l	d0,a0			
		Move	32(a0),RawX		;Get mouse XY from mess
		Move	34(a0),RawY		;+
		Move.l	20(a0),d7		;Read mousebuttons
		Move	24(a0),d5		;Get Code

		Move	24(a0),IECode		;Key Code
		Move	26(a0),IEQual		;Qualifiers
		Move.l	28(a0),IEAddr		;Pointer to Old Keys

		Bsr.w	Reply
		Btst	#10,d7			;RAWKEY?
		Bne.b	RawKey
		Btst	#3,d7			;MOUSEBUTTONS?
		Bne.w	MouseButtons
	GdEnd:	Rts
*---------------
RawKey:		Move.l	Active_StGd(pc),d0
		Beq.w	Decode_RawKey
		
GetKey:		Move	IECode(pc),d0		;Get Code
		Tst.b	d0			;Bit 7 - Key release?
		Bmi.w	GK_End			;Yes, skip

		Move	IEQual(pc),d1
		And	#3,d1			;Left/Right Shift
		Bne.b	GK_Sh

		Cmp	#$44,d0			;Return?
		Beq.w	GK_Ret
		Cmp	#$43,d0			;Enter?
		Beq.w	GK_Ent
		Cmp	#$45,d0			;Escape
		Beq.w	GK_Esc

		Move.l	Active_StGd(pc),a5
		Tst.l	34(a5)
		Beq.w	GK_Ret

		Cmp	#$4f,d0			;LeftArrow?
		Beq.w	GK_Lft
		Cmp	#$4e,d0			;RightArrow?
		Beq.w	GK_Rgt
		Cmp	#$41,d0			;BackSpace?
		Beq.w	GK_Bck
		Cmp	#$46,d0			;Delete?
		Beq.w	GK_Del
		Bra.b	GK_NSh

	GK_Sh:	Cmp	#$41,d0			;Clear?
		Beq.w	GK_Clr
		Cmp	#$46,d0			;Clear?
		Beq.w	GK_Clr
		Cmp	#$4f,d0			;ToStart?
		Beq.w	GK_TSt
		Cmp	#$4e,d0			;ToEnd?
		Beq.w	GK_TEd
	GK_NSh:
	*-- Convert to ASCII
		Lea	Event(pc),a0		;Get Event Structure
		Lea	Key_Buffer(pc),a1	;Convert Buffer
		Moveq.l	#8,d1			;Max 8 Characters
		Sub.l	a2,a2			;A2=0 - Default Keymap
		Move.l	ConBase(pc),a6		;Get Console.Device Base
		Jsr	-48(a6)			;RawKeyConvert to ASCII
		Tst	d0			;Any Characters?
		Beq.w	GK_End			;No
		Lea	Key_Buffer(pc),a0	;Get 1 Character
		Move.b	(a0),d0			;+

		Move.l	Active_StGd(pc),a0
		Add	#14+10,a0		;Add 'GD'+'RC'
		Move	8(a0),d1		;Get Font
		Cmp	#5,d1			;Are we using Font5
		Bne.b	GK_NCp
		Cmp.b	#'a',d0
		Blt.b	GK_NCp
		Cmp.b	#'z',d0
		Bgt.b	GK_NCp
		Sub.b	#32,d0

	GK_NCp:	Move.l	Active_StGd(pc),a0
		Btst	#3,4(a0)
		Beq.b	GK_NNo
		Cmp.b	#'+',d0
		Beq.b	GK_NNo
		Cmp.b	#'-',d0
		Beq.b	GK_NNo
		Cmp.b	#'0',d0
		Blt.b	GK_End
		Cmp.b	#'9',d0
		Bgt.b	GK_End

	GK_NNo:	Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a1		;Get String
		Move	Cursor_Pos(pc),d1
	*-- Find length of string
		Moveq.l	#-1,d3
		Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a2		;Get String
	GK_Len:	Addq	#1,d3
		Tst.b	(a2)+
		Bne.b	GK_Len
		Addq	#1,d3
		Cmp	8(a5),d3		;MaxLength
		Bgt.b	GK_Rpl

	GK_Ins:	Move	8(a5),d3
		Subq	#1,d3
		Cmp	Cursor_Pos(pc),d3
		Beq.b	GK_InL
		Addq	#1,Cursor_Pos
	GK_InL:	Move.b	0(a1,d1.w),d2
		Move.b	d0,0(a1,d1.w)
		Beq.b	GK_InE
		Addq	#1,a1
		Move	d2,d0
		Bra.b	GK_InL
	GK_InE:	Addq	#1,d1
		Bsr.w	StGd_UpdGfx
	GK_End:	Rts

	GK_Rpl:	Move	8(a5),d3
		Subq	#1,d3
		Cmp	Cursor_Pos(pc),d3
		Beq.b	GK_NCr
		Addq	#1,Cursor_Pos
	GK_NCr:	Move.b	d0,0(a1,d1.w)
		Bra.w	StGd_UpdGfx

	GK_Lft:	Move	Cursor_Pos(pc),d0
		Beq.b	GK_NLf
		Subq	#1,Cursor_Pos
		Bsr.w	StGd_UpdGfx
	GK_NLf:	Rts

	GK_Rgt:	Move	Cursor_Pos(pc),d0
		Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a1		;Get String
		Move.b	0(a1,d0.w),d7
		Beq.b	GK_NRg
		Move	8(a5),d3
		Subq	#1,d3
		Cmp	Cursor_Pos(pc),d3
		Beq.b	GK_NRg
		Addq	#1,Cursor_Pos
		Bsr.w	StGd_UpdGfx
	GK_NRg:	Rts

	GK_Bck:	Move	Cursor_Pos(pc),d0
		Beq.b	GK_NBk
		Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a1		;Get String
	GK_LBk:	Addq	#1,a1
		Move.b	-1(a1,d0.w),-2(a1,d0.w)
		Bne.b	GK_LBk
		Subq	#1,Cursor_Pos
		Bsr.w	StGd_UpdGfx
	GK_NBk:	Rts

	GK_Del:	Move	Cursor_Pos(pc),d0
		Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a1		;Get String
	GK_LDl:	Addq	#1,a1
		Move.b	0(a1,d0.w),-1(a1,d0.w)
		Bne.b	GK_LDl
		Bsr.w	StGd_UpdGfx
	GK_NDl:	Rts

	GK_Clr:	Clr	Cursor_Pos
		Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a1		;Get String
		Move	8(a5),d0		;Get MaxLength
	GK_ClL:	Clr.b	(a1)+
		Dbf	d0,GK_ClL
		Bra.w	StGd_UpdGfx

	GK_TSt:	Clr	Cursor_Pos
		Bra.w	StGd_UpdGfx

	GK_TEd:
	*-- Find length of string
		Moveq.l	#-1,d3
		Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a1		;Get String
	GK_Ln2:	Addq	#1,d3
		Tst.b	(a1)+
		Bne.b	GK_Ln2
		Cmp	8(a5),d3
		Blt.b	GK_NOv
		Move	8(a5),d3
		Subq	#1,d3
	GK_NOv:	Move	d3,Cursor_Pos
		Bra.w	StGd_UpdGfx

	GK_Esc:	Lea	Cancel_Buf(pc),a0
		Move.l	Active_StGd(pc),a5
		Tst.l	34(a5)
		Beq.b	GK_Ret
		Move.l	34(a5),a1		;Get String
		Move	8(a5),d0		;Get MaxLength
	GK_CnL:	Move.b	(a0)+,(a1)+
		Dbf	d0,GK_CnL
	GK_Ret:
	GK_Ent:	Bra.w	Deactive_StGd

Cancel_Buf:	Blk.b	34,0
Number_Buf:	Blk.b	34,0
Number_Old:	Dc.l	0

Cursor_Pos:	Dc	0

Event:		Dc.l	0
IEClass:	Dc.b	$01	;Class:	RAWKEY
		Dc.b	0	;SubClass
IECode:		Dc	0	;Code
IEQual:		Dc	0	;Qualifier
IEAddr:		Dc.l	0	;EventAddress
		Dc.l	0	;X,Y
		Dc.l	0,0	;TimeStamp
Key_Buffer:	Blk.b	8,0
Active_StGd:	Dc.l	0
Active_StGdLay:	Dc.l	0
*---------------
StGd_UpdGfx:	Move.l	Active_StGdLay(pc),a5
		Move.l	Active_StGd(pc),a4

		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Add	#14,a4		;Add 'GD'

		Bsr.w	Calc_Coord
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	MdCol(pc),d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Move	X2(pc),d2
		Move	Y2(pc),d3
		Addq	#1,d0
		Addq	#1,d1
		Subq	#1,d2
		Subq	#1,d3
		Cmp	d0,d2
		Ble.b	SUG_Ov
		Cmp	d1,d3
		Ble.b	SUG_Ov
		Jsr	RectFill(a6)
	SUG_Ov:	Add	#10,a4

		Move.l	a3,a1
		Move	8(a4),d0
		Cmp	#5,d0
		Bne.b	SUG_F5
		Lea	Font5,a0
	SUG_F5:
		Cmp	#8,d0
		Bne.b	SUG_F8
		Lea	Font8,a0
	SUG_F8:
		Move.l	(a0),a0
		Jsr	SetFont(a6)
		Move.l	a3,a1
		Move	HiCol(pc),d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Bsr.w	Calc_Coord
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Jsr	Move(a6)
	*-- Find length of string
		Moveq.l	#-1,d3
		Move.l	10(a4),a2
	SUG_Lp:	Addq	#1,d3
		Tst.b	(a2)+
		Bne.b	SUG_Lp

;	SUG_Len:Subq	#1,d3
;		Ble.w	DrawTX2
;		Move	d3,d0
;		Move.l	10(a4),a0
;		Move.l	a3,a1
;		Jsr	TextLength(a6)
;		Cmp	X2(pc),d0
;		Bgt.b	SUG_Len

		Move.l	a3,a1
		Moveq.l	#1,d0
		Jsr	SetDrMd(a6)
	*-- Write to Cursor Position
		Move.l	a3,a1
		Move	HiCol(pc),d0
		Jsr	SetAPen(a6)	
		Move.l	a3,a1
		Move	MdCol(pc),d0
		Jsr	SetBPen(a6)	
		Move.l	a3,a1
		Move	Cursor_Pos(pc),d0
		Beq.b	SUG_Nul
		Move.l	10(a4),a0
		Jsr	Text(a6)
	*-- Write Cursor Position
	SUG_Nul:Move.l	a3,a1
		Move	LoCol(pc),d0
		Jsr	SetAPen(a6)	
		Move.l	a3,a1
		Move	HiCol(pc),d0
		Jsr	SetBPen(a6)	
		Move.l	a3,a1
		Moveq.l	#1,d0
		Move.l	10(a4),a0
		Add	Cursor_Pos(pc),a0
		Tst.b	(a0)
		Bne.b	SUG_OkC
		Lea	SpaceCharT(pc),a0
	SUG_OkC:Jsr	Text(a6)
	*-- Write from Cursor Position
		Move.l	a3,a1
		Move	HiCol(pc),d0
		Jsr	SetAPen(a6)	
		Move.l	a3,a1
		Move	MdCol(pc),d0
		Jsr	SetBPen(a6)	
		Move.l	a3,a1
		Move	d3,d0
		Sub	Cursor_Pos(pc),d0
		Subq	#1,d0
		Ble.b	SUG_End
		Move.l	10(a4),a0
		Add	Cursor_Pos(pc),a0
		Addq	#1,a0
		Jsr	Text(a6)
	SUG_End:Rts
SpaceCharT:	Dc.b	' ',0
*---------------
Decode_RawKey:	Move.l	ScrnLay(pc),d0	;Screen window open?
		Beq.b	DRK_NSc
		Move	Scrn_TextOn,d0	;###
		Beq.b	DRK_NSc
		Jmp	Scrn_GetText	;###

	DRK_NSc:Lea	RawKey_NoQual(pc),a0
		Move	IEQual(pc),d0
		And.b	#$03,d0
		Beq.b	DRK_Lp
		Lea	RawKey_Shift(pc),a0
	DRK_Lp:	Move.b	(a0),d0
		Bmi.b	DRK_End
		Cmp.b	d0,d5
		Beq.b	DRK_Jmp
		Addq.l	#6,a0
		Bra.b	DRK_Lp
	DRK_End:Rts
	DRK_Jmp:Move.l	2(a0),a0
		Jmp	(a0)

RawKey_NoQual:	Dc.b	$01,0		;1
		Dc.l	Anim_PrevFrame
		Dc.b	$02,0		;2
		Dc.l	Anim_NextFrame
		Dc.b	$03,0		;3
		Dc.l	Piec_BrowseUp
		Dc.b	$04,0		;4
		Dc.l	Piec_BrowseDn
		Dc.b	$05,0		;5
		Dc.l	Comm_BrowseUp
		Dc.b	$06,0		;6
		Dc.l	Comm_BrowseDn
		Dc.b	$14,0		;T
		Dc.l	Back_TopWard
		Dc.b	$15,0		;Y
		Dc.l	Comm_FlipY
		Dc.b	$16,0		;U
		Dc.l	Common_Undo
		Dc.b	$19,0		;P
		Dc.l	Comm_PickPiece
		Dc.b	$22,0		;D
		Dc.l	Key_Draw
		Dc.b	$23,0		;F
		Dc.l	Anim_AddFrame
		Dc.b	$33,0		;C
		Dc.l	Comm_Collision
		Dc.b	$35,0		;B
		Dc.l	Back_BottomWard
		Dc.b	$37,0		;M
		Dc.l	Comm_Magnify
		Dc.b	$38,0		;,
		Dc.l	Comm_MagMinus
		Dc.b	$39,0		;.
		Dc.l	Comm_MagPlus
		Dc.b	$41,0		;BackSpace
		Dc.l	Comm_DelPart
		Dc.b	$44,0		;Return
		Dc.l	Comm_Play
		Dc.b	$46,0		;Del
		Dc.l	Toggle_Pointer
		Dc.b	$4c,0		;Up
		Dc.l	Comm_PieceUp
		Dc.b	$4d,0		;Down
		Dc.l	Comm_PieceDn
		Dc.b	$4e,0		;Right
		Dc.l	Comm_PieceRg
		Dc.b	$4f,0		;Left
		Dc.l	Comm_PieceLf
		Dc.b	$59,0		;F10
		Dc.l	Toggle_Title
		Dc.b	$00,0		;`
		Dc.l	Close_One
		Dc.b	-1,0

RawKey_Shift:	Dc.b	$01,0		;1
		Dc.l	Anim_ToStart
		Dc.b	$02,0		;2
		Dc.l	Anim_ToEnd
		Dc.b	$03,0		;3
		Dc.l	Save_Desk
		Dc.b	$14,0		;T
		Dc.l	Back_ToTop
		Dc.b	$23,0		;F
		Dc.l	Anim_DelFrame
		Dc.b	$35,0		;B
		Dc.l	Back_ToBottom
		Dc.b	$44,0		;Return
		Dc.l	Comm_PlayScr
		Dc.b	$00,0		;~
		Dc.l	Close_All
		Dc.b	-1,0
*---------------
Piec_BrowseUp:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	Piec_Info(pc),a3
		Bra.w	Unit_BrUp
*---------------
Piec_BrowseDn:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	Piec_Info(pc),a3
		Bra.w	Unit_BrDn
*---------------
Unit_BrowseCm:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?

		Cmp.l	#'MPRT',4(a5)
		Bne.b	UBC_NMp
		Lea	Move_Info(pc),a3
		Bra.b	UBC_Ok
	UBC_NMp:
	
		Lea	Unit_Info(pc),a3
	UBC_Lp:	Tst	(a3)
		Bmi.b	UBC_End
		Move.l	4(a5),d0
		Cmp.l	16(a3),d0
		Beq.b	UBC_Ok
		Add	Item_Size(pc),a3
		Bra.b	UBC_Lp

	UBC_Ok:	Moveq.l	#1,d0
		Rts

	UBC_End:Clr.l	d0
		Rts

Comm_BrowseUp:	Bsr.b	Unit_BrowseCm
		Beq.b	UBC_End
		Bra.w	Unit_BrUp

Comm_BrowseDn:	Bsr.b	Unit_BrowseCm
		Beq.b	UBC_End
		Bra.w	Unit_BrDn
*---------------
Save_Desk:	Move.l	Screen_Struct(pc),a5
		Lea	184(a5),a5
		Bra.w	Save_IFF
*---------------
Close_One:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'DESK',4(a5)
		Beq.b	CO_End
		Bsr.w	Close_Layer
	CO_End:	Rts
*---------------
Close_All:	Lea	GameLay(pc),a5
	CAL_Lop:Tst.l	(a5)
		Bmi.b	CAL_End
		Bsr.w	Close_Layer
		Add	#30,a5
		Bra.b	CAL_Lop
	CAL_End:Rts
*---------------
Comm_Play:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'BACK',4(a5)
		Beq.w	Back_PlayScreen
		Cmp.l	#'ANIM',4(a5)
		Beq.w	Anim_Play
		Cmp.l	#'WEAP',4(a5)
		Beq.w	Weap_PlayScreen
		Cmp.l	#'OBJC',4(a5)
		Beq.w	Objc_PlayScreen
		Cmp.l	#'MOVE',4(a5)
		Beq.w	Move_PlayScreen
		Cmp.l	#'MPRT',4(a5)
		Beq.w	Move_PlayScreen
		Cmp.l	#'LEVL',4(a5)
		Beq.b	CP_Levl
		Cmp.l	#'MODL',4(a5)
		Beq.b	CP_Modl
		Cmp.l	#'SONG',4(a5)
		Beq.b	CP_Song
		Cmp.l	#'SMPL',4(a5)
		Beq.b	CP_Smpl
		Cmp.l	#'SOND',4(a5)
		Beq.b	CP_Sond
		Rts

	CP_Levl:Jmp	Levl_PlayScreen
	CP_Modl:Jmp	Modl_Play
	CP_Song:Jmp	Song_Play
	CP_Smpl:Jmp	Smpl_Play
	CP_Sond:Jmp	Sond_Play
*---------------
Comm_PlayScr:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'BACK',4(a5)
		Beq.w	Back_PlayScreen
		Cmp.l	#'ANIM',4(a5)
		Beq.w	Anim_PlayScreen
		Cmp.l	#'WEAP',4(a5)
		Beq.w	Weap_PlayScreen
		Cmp.l	#'OBJC',4(a5)
		Beq.w	Objc_PlayScreen
		Cmp.l	#'MOVE',4(a5)
		Beq.w	Move_PlayScreen
		Cmp.l	#'MPRT',4(a5)
		Beq.w	Move_PlayScreen
		Cmp.l	#'LEVL',4(a5)
		Beq.b	CPS_Lev
		Cmp.l	#'MODL',4(a5)
		Beq.b	CPS_Mod
		Cmp.l	#'SONG',4(a5)
		Beq.b	CPS_Sng
		Cmp.l	#'SMPL',4(a5)
		Beq.b	CPS_Smp
		Cmp.l	#'SOND',4(a5)
		Beq.b	CPS_Snd
		Cmp.l	#'SCRN',4(a5)
		Beq.b	CPS_Scr
		Cmp.l	#'SEVN',4(a5)
		Beq.b	CPS_Scr
		Rts

	CPS_Lev:Jmp	Levl_PlayScreen
	CPS_Mod:Jmp	Modl_Play
	CPS_Sng:Jmp	Song_Play
	CPS_Smp:Jmp	Smpl_Play
	CPS_Snd:Jmp	Sond_Play
	CPS_Scr:Jmp	Scrn_PlayScreen
*---------------
Comm_DelPart:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?

		Cmp.l	#'BACK',4(a5)
		Bne.b	CDP_NBk
		Bsr.w	BP_Rem
		Move	#-1,LSX
		Bra.w	Back_PieceDel
	CDP_NBk:
		Cmp.l	#'ANIM',4(a5)
		Bne.b	CDP_NAn
		Bsr.w	BP_Rem
		Move	#-1,LSX
		Bra.w	Anim_PieceDel
	CDP_NAn:
		Cmp.l	#'LEVL',4(a5)
		Bne.b	CDP_NLv
		Jmp	Levl_DelEvent	;###
	CDP_NLv:
		Cmp.l	#'OBJC',4(a5)
		Bne.b	CDP_NOb
		Bra.w	Objc_DelEvent
	CDP_NOb:
		Cmp.l	#'MPRT',4(a5)
		Bne.b	CDP_NMp
		Bra.w	Move_DelPart
	CDP_NMp:
		Cmp.l	#'MOVE',4(a5)
		Bne.b	CDP_NMv
		Bra.w	Move_DelPart
	CDP_NMv:
		Cmp.l	#'SCRN',4(a5)
		Bne.b	CDP_NSc
		Jmp	Scrn_DelEvent	;###
	CDP_NSc:
		Cmp.l	#'SEVN',4(a5)
		Bne.b	CDP_NSe
		Jmp	Scrn_DelEvent	;###
	CDP_NSe:
		Cmp.l	#'FONT',4(a5)
		Bne.b	CDP_NFo
		Jmp	Font_DelPiece	;###
	CDP_NFo:
		Rts
*---------------
Key_Draw:	Bsr.w	Piec_Draw
		Lea	DrawLay(pc),a5
		Lea	GDrawFreeHand(pc),a4
		Bset	#0,4(a4)
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Comm_Magnify:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'PICT',4(a5)
		Beq.b	CM_Pict
		Cmp.l	#'PIEC',4(a5)
		Beq.b	CM_Piec
		Rts
	CM_Pict:Lea	GPictZoom(pc),a4
		Bchg	#0,4(a4)
		Lea	PictLay(pc),a5
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Bra.w	Pict_Zoom
	CM_Piec:Lea	GPiecZoom(pc),a4
		Bchg	#0,4(a4)
		Lea	PiecLay(pc),a5
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Bra.w	Piec_Zoom
*---------------
Comm_MagPlus:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'PICT',4(a5)
		Beq.w	Pict_ZoomPlus
		Cmp.l	#'PIEC',4(a5)
		Beq.w	Piec_ZoomPlus
		Rts
*---------------
Comm_MagMinus:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'PICT',4(a5)
		Beq.w	Pict_ZoomMinus
		Cmp.l	#'PIEC',4(a5)
		Beq.w	Piec_ZoomMinus
		Rts
*---------------
Comm_PickPiece:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'BACK',4(a5)
		Beq.b	CPP_Bk
		Cmp.l	#'ANIM',4(a5)
		Beq.b	CPP_An
		Rts

	CPP_Bk:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	GBack_Pick(pc),a4
		Bchg	#0,4(a4)
		Lea	BackLay(pc),a5
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Bra.w	Back_PiecePick

	CPP_An:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	GAnim_Pick(pc),a4
		Bchg	#0,4(a4)
		Lea	AnimLay(pc),a5
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Bra.w	Anim_PiecePick
*---------------
Comm_Collision:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'BACK',4(a5)
		Beq.b	CC_Bk
		Cmp.l	#'ANIM',4(a5)
		Beq.b	CC_An
		Rts

	CC_Bk:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	GBack_Coll(pc),a4
		Bchg	#0,4(a4)
		Lea	BackLay(pc),a5
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Bra.w	Back_Coll

	CC_An:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	GAnim_Coll(pc),a4
		Bchg	#0,4(a4)
		Lea	AnimLay(pc),a5
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		Bra.w	Anim_Coll
*---------------
Comm_FlipY:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a5		;Still on gadget?
		Cmp.l	#'BACK',4(a5)
		Beq.b	CFY_Bk
		Cmp.l	#'ANIM',4(a5)
		Beq.b	CFY_An
		Rts

	CFY_Bk:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	GBack_FlipY(pc),a4
		Bchg	#0,4(a4)
		Lea	BackLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some

	CFY_An:	Bsr.w	BP_Rem
		Move	#-1,LSX
		Lea	GAnim_FlipY(pc),a4
		Bchg	#0,4(a4)
		Lea	AnimLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Toggle_Title:	Bchg	#4,Prf_GfxFlags
Update_TitleBar:Btst	#4,Prf_GfxFlags
		Bne.b	TT_On
		Clr	LimY1
		Move	#'XX',Title_Start
		Bra.w	Fill_Desk

	TT_On:	Move	#11,LimY1
	*-- Check all layers
		Lea	GameLay(pc),a4
	TT_Lop:	Tst.l	(a4)
		Bmi.b	TT_End
		Beq.b	TT_Clsd
		Bsr.w	Check_Layer_Size

		Movem.l	d0-d7/a0-a6,-(a7)
		Move.l	a4,a5
		Bsr.w	Close_Layer
		Bsr.w	Open_Layer
		Movem.l	(a7)+,d0-d7/a0-a6

	TT_Clsd:Add	#30,a4
		Bra.b	TT_Lop
	TT_End:	
		Move	#'GD',Title_Start
		Lea	DeskLay(pc),a5
		Lea	DrawList_Desk(pc),a4
		Bra.w	Draw_All
*---------------
Toggle_Pointer:	Not	Pointer_Off
		Rts
*---------------
MouseButtons:	Cmp.b	#$68,d5			;Left Down?
		Beq.b	LeftDown		;Yes
		Cmp.b	#$69,d5			;Right Down?
		Beq.b	RightDown		;Yes
		Rts			
*---------------
Reply:		Move.l	4.w,a6			;Reply Message
		Move.l	Message(pc),a1
		Jmp	ReplyMsg(a6)
Message:	Dc.l	0
*---------------
LeftDown:	Bsr.w	Deactive_StGd
		Bsr.w	Which_Layer
		Move.l	LayL(pc),a5		;Search
		Move.l	18(a5),a4
		Bsr.w	SrchAll
		Beq.w	GdEnd
		Cmp.b	#$00,3(a4)
		Beq.w	Gd_Silent
		Cmp.b	#$01,3(a4)
		Beq.w	Gd_Logic
		Cmp.b	#$02,3(a4)
		Beq.w	Gd_Prop
		Cmp.b	#$03,3(a4)
		Beq.w	Gd_Logic	;String
		Rts
*---------------
RightDown:	Lea	Sprite_Arrow(pc),a1	;Arrow Pointer
		Bsr.w	Change_Sprite
		Lea	OpenLay(pc),a4
		
		Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),d0
		Move	16(a0),d1
		Sub	#58,d0
		Move	d0,08(a4)
		Move	d1,10(a4)
		Add	#116,d0
		Add	#95,d1
		Move	d0,12(a4)
		Move	d1,14(a4)
		Bsr.w	Check_Layer_Limits
		
		Lea	OpenLay(pc),a5		;Open OPEN Layer
		Bsr.w	Open_Layer
		Clr.l	LastGd
	
	RLoop:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
	
		Clr.l	HitGd
		Move.l	LayL(pc),a0		;On OPEN Layer?
		Cmp.l	#'OPEN',4(a0)
		Bne.b	NoSrch
		Lea	OpenLay(pc),a5		;Check for gadget hits
		Move.l	18(a5),a4
		Bsr.w	SrchAll
		
	NoSrch:	Move.l	LastGd(pc),a4		;Same Gadget?
		Cmp.l	HitGd(pc),a4
		Beq.b	NPush
		
		Move.l	LastGd(pc),d0		;Any gadget to unpush?
		Beq.b	NUnPush
		Move.l	d0,a4			;UnPush
		Bclr	#0,4(a4)
		Lea	OpenLay(pc),a5
		Clr	d0
		Move.b	2(a4),d0
		Move	d0,d7
		Addq	#1,d7
		Bsr.w	Draw_Some
		
	NUnPush:Move.l	HitGd(pc),LastGd	;Save Gadget Pointer
		
		Move.l	HitGd(pc),d0		;Any Gadget to Push?
		Beq.b	NPush
		Move.l	d0,a4			;Push
		Bset	#0,4(a4)
		Lea	OpenLay(pc),a5
		Clr	d0
		Move.b	2(a4),d0
		Move	d0,d7
		Addq	#1,d7
		Bsr.w	Draw_Some
		
	NPush:	Bsr.w	Check_Right_Up		;Right button released?
		Beq.w	RLoop			;No
		Lea	OpenLay(pc),a5		;Close OPEN Layer
		Bsr.w	Close_Layer
		
		Move.l	HitGd(pc),d0		;Any Choice Made?
		Beq.b	NChoice
		Move.l	d0,a4			;Push (Restore Drawlist)
		Bclr	#0,4(a4)
		
		Move.l	6(a4),a5		;Open Layer
		Bsr.w	Open_Layer
	NChoice:Rts
*---------------
Gd_Silent:	Bra.w	Distribute_Gadgets
*---------------
Gd_Logic:	Move.b	4(a4),OrgSt
		Bchg	#0,4(a4)		;Push gadget
		Move.b	4(a4),OnOff
		Moveq.l	#1,d0
		Add.b	2(a4),d0
		Move	d0,d7
		Bsr.w	Draw_Some
		Move.l	HitGd(pc),LastGd	;Remember gadget
		Move.l	LayL(pc),LastLr

	RelVer:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
	
		Move.l	LayL(pc),a5		;Still on gadget?
		Move.l	18(a5),a4
		Bsr.w	SrchAll
		Move.l	LastLr(pc),a5
		Move.l	LastGd(pc),a4
		Move.b	OrgSt(pc),4(a4)
		Bchg	#0,4(a4)
		Move.l	HitGd(pc),d0
		Cmp.l	LastGd(pc),d0
		Beq.b	StillOn
		Move.b	OrgSt(pc),4(a4)

	StillOn:Move.b	OnOff(pc),d6
		Move.b	4(a4),d7
		Eor.b	d7,d6
		Btst	#0,d6			;Draw new state
		Beq.b	NoDraw
		Move.b	4(a4),OnOff
		Moveq.l	#1,d0
		Add.b	2(a4),d0
		Move	d0,d7
		Bsr.w	Draw_Some

	NoDraw:	Bsr.w	Check_Left_Up
		Beq.b	RelVer			;No

	Verify:
	*-- User has now released mousebutton
		Btst	#1,4(a4)
		Bne.b	Toggle
		Move.b	OrgSt(pc),4(a4)		;UnPush gadget
		Move.b	OnOff(pc),d6
		Move.b	4(a4),d7
		Eor.b	d7,d6
		Btst	#0,d6			;Draw new state
		Beq.b	NoDraw2
		Move.b	4(a4),OnOff
		Move.l	LastLr(pc),a5
		Move.l	LastGd(pc),a4
		Moveq.l	#1,d0
		Add.b	2(a4),d0
		Move	d0,d7
		Bsr.w	Draw_Some
	NoDraw2:
	Toggle:
	*-- Check if user canceled
		Move.l	HitGd(pc),a4
		Cmp.l	LastGd(pc),a4
		Bne.w	GdEnd
	*-- Handle Exclude option
		Btst	#2,4(a4)	;Exclude?
		Beq.b	NoExcl
		Move.l	6(a4),a0
	ExclNxt:Move.l	(a0)+,d0
		Beq.b	ExclEnd		;End of ExcludeList?
		Move.l	d0,a4
		Cmp.l	HitGd(pc),a4	;Same gadget?
		Beq.b	ExclNxt
		Btst	#0,4(a4)	;Is down?
		Beq.b	ExclNxt
		Bclr	#0,4(a4)	;Unpush it
		Move.l	LayL(pc),a5	;Draw it
		Moveq.l	#1,d0
		Add.b	2(a4),d0
		Move	d0,d7
		Move.l	a0,-(a7)
		Bsr.w	Draw_Some
		Move.l	(a7)+,a0
		Bra.b	ExclNxt
	ExclEnd:
	NoExcl:	Cmp.b	#$03,3(a4)	;Was it a String Gadget?
		Beq.w	Gd_String	;Yes
		Bra.w	Distribute_Gadgets

LastGd:		Dc.l	0
LastLr:		Dc.l	0
OnOff:		Dc	0
OrgSt:		Dc	0
*---------------
Gd_Prop:
	*-- Did we hit the box or the knob?
		Move.l	LayL(pc),a5
		Move.l	HitGd(pc),a4
		Add	#14+10,a4	;Add one 'GD' and one 'BX'
		Bsr.w	Calc_Coord
		
		Move.l	HitGd(pc),a3
		Move.l	6(a3),a3
		Move.b	(a3),d1
		Btst	#3,d1		;Is knob free X?
		Beq.b	NoFreeX1
		
		Move	X1(pc),d0
		Cmp	LayX(pc),d0
		Bgt.w	HitBoxNeg
		
		Move	X2(pc),d0
		Cmp	LayX(pc),d0
		Blt.w	HitBoxPos
		
NoFreeX1:	Move.l	HitGd(pc),a3
		Move.l	6(a3),a3
		Move.b	(a3),d1
		Btst	#2,d1		;Is knob free Y?
		Beq.b	NoFreeY1
		
		Move	Y1(pc),d0
		Cmp	LayY(pc),d0
		Bgt.w	HitBoxNeg
		
		Move	Y2(pc),d0
		Cmp	LayY(pc),d0
		Blt.w	HitBoxPos
NoFreeY1:	
	*-- We hit the knob
		Move	RawX(pc),LKnobX
		Move	RawY(pc),LKnobY
	*-- Calculate box sizes
		Move.l	LayL(pc),a5
		Move.l	HitGd(pc),a4
		Add	#14,a4		;Add one 'GD'
		Bsr.w	Calc_Coord
		Move	X2(pc),d0
		Sub	X1(pc),d0
		Subq	#4,d0
		Move	d0,BoxLenX
		Move	Y2(pc),d0
		Sub	Y1(pc),d0
		Subq	#4,d0
		Move	d0,BoxLenY
	*-- Get start positions
		Move.l	HitGd(pc),a3
		Move.l	6(a3),a3
		Clr.l	d0
		Move	6(a3),d0
		Move.l	d0,RKnobX
		Clr.l	d0
		Move	8(a3),d0
		Move.l	d0,RKnobY

MoveKnob:	Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		
		Move.l	HitGd(pc),a3
		Move.l	6(a3),a3
		Move.b	(a3),d1
		Btst	#3,d1		;Is knob free X?
		Bne.w	FreeX1
		Btst	#2,d1		;Is knob free Y?
		Bne.b	FreeY1
		Rts

	FreeY1:	Move	RawY(pc),d0
		Sub	LKnobY(pc),d0

		Move.l	#65536,d2
		Divu	BoxLenY(pc),d2
		And.l	#$ffff,d0
		And.l	#$ffff,d2
		Muls	d0,d2

		Move.l	RKnobY(pc),d3
		Add.l	d2,d3
		Move.l	d3,RKnobY
		Bpl.b	NoNegY
		Clr	d1
		Bra.b	NoFlowY0

	NoNegY:	Move.l	HitGd(pc),a3
		Move.l	6(a3),a3
		Clr.l	d0
		Move	4(a3),d0	;Get %KnobY
		Move.l	RKnobY(pc),d1	;Get %PosY
		Move.l	d1,d2
		Add.l	d0,d2		;Is %PosY+%KnobY=Overflow?
		Swap	d2
		Tst	d2
		Beq.b	NoFlowY0
		Move.l	#$ffff,d1
		Sub	d0,d1
NoFlowY0:	Move	RawY(pc),LKnobY
		Cmp	8(a3),d1
		Beq.b	NoActionY
		Move	d1,8(a3)

		Bsr.w	UpdateProp
		Bsr.w	UpdatePropG
NoActionY:	Bsr.w	Check_Left_Up
		Beq.w	MoveKnob
		Bra.w	Prop_End

	FreeX1:	Move	RawX(pc),d0
		Sub	LKnobX(pc),d0

		Move.l	#65536,d2
		Divu	BoxLenX(pc),d2
		And.l	#$ffff,d0
		And.l	#$ffff,d2
		Muls	d0,d2

		Move.l	RKnobX(pc),d3
		Add.l	d2,d3
		Move.l	d3,RKnobX
		Bpl.b	NoNegX
		Clr	d1
		Bra.b	NoFlowX0

	NoNegX:	Move.l	HitGd(pc),a3
		Move.l	6(a3),a3
		Clr.l	d0
		Move	2(a3),d0	;Get %KnobX
		Move.l	RKnobX(pc),d1	;Get %PosX
		Move.l	d1,d2
		Add.l	d0,d2		;Is %PosX+%KnobX=Overflow?
		Swap	d2
		Tst	d2
		Beq.b	NoFlowX0
		Move.l	#$ffff,d1
		Sub	d0,d1
NoFlowX0:	Move	RawX(pc),LKnobX
		Cmp	6(a3),d1
		Beq.b	NoActionX
		Move	d1,6(a3)

		Bsr.w	UpdateProp
		Bsr.w	UpdatePropG
NoActionX:	Bsr.w	Check_Left_Up
		Beq.w	MoveKnob
		Bra.w	Prop_End

LKnobX:		Dc	0
LKnobY:		Dc	0
RKnobX:		Dc.l	0
RKnobY:		Dc.l	0

HitBoxNeg:	
	*-- We hit the box in its negative end
		Move.l	HitGd(pc),a3
		Move.l	6(a3),a3

		Move.b	(a3),d1
		Btst	#3,d1		;Is knob free X?
		Beq.b	NoFreeX3
		Clr.l	d0
		Move	2(a3),d0	;Get %KnobX
		Clr.l	d1
		Move	6(a3),d1	;Get %PosX
		Sub.l	d0,d1
		Bpl.b	NoFlowX1
		Clr	d1
NoFlowX1:	Move	d1,6(a3)

NoFreeX3:	Move.b	(a3),d1
		Btst	#2,d1		;Is knob free Y?
		Beq.b	NoFreeY3
		Clr.l	d0
		Move	4(a3),d0	;Get %KnobY
		Clr.l	d1
		Move	8(a3),d1	;Get %PosY
		Sub.l	d0,d1
		Bpl.b	NoFlowY1
		Clr	d1
NoFlowY1:	Move	d1,8(a3)

NoFreeY3:	Bsr.b	UpdateProp
		Bsr.w	UpdatePropG
		Bra.w	Prop_End

HitBoxPos:	
	*-- We hit the box in its positive end
		Move.l	HitGd(pc),a3
		Move.l	6(a3),a3

		Move.b	(a3),d1
		Btst	#3,d1		;Is knob free X?
		Beq.b	NoFreeX4
		Clr.l	d0
		Move	2(a3),d0	;Get %KnobX
		Clr.l	d1
		Move	6(a3),d1	;Get %PosX
		Add.l	d0,d1
		Move.l	d1,d2		;Is %PosX+%KnobX=Overflow?
		Add.l	d0,d2
		Swap	d2
		Tst	d2
		Beq.b	NoFlowX2
		Move.l	#$ffff,d1
		Sub	d0,d1
NoFlowX2:	Move	d1,6(a3)

NoFreeX4:	Move.b	(a3),d1
		Btst	#2,d1		;Is knob free Y?
		Beq.b	NoFreeY4
		Clr.l	d0
		Move	4(a3),d0	;Get %KnobY
		Clr.l	d1
		Move	8(a3),d1	;Get %PosY
		Add.l	d0,d1
		Move.l	d1,d2		;Is %PosY+%KnobY=Overflow?
		Add.l	d0,d2
		Swap	d2
		Tst	d2
		Beq.b	NoFlowY2
		Move.l	#$ffff,d1
		Sub	d0,d1
NoFlowY2:	Move	d1,8(a3)

NoFreeY4:	Bsr.b	UpdateProp
		Bsr.w	UpdatePropG
		Bra.w	Prop_End

UpdateProp:	
	*-- Calculate box sizes
		Move.l	LayL(pc),a5
		Move.l	HitGd(pc),a4
		Add	#14,a4		;Add one 'GD'
		Bsr.w	Calc_Coord
		Move	X2(pc),d0
		Sub	X1(pc),d0
		Subq	#4,d0
		Move	d0,BoxLenX
		Move	Y2(pc),d0
		Sub	Y1(pc),d0
		Subq	#4,d0
		Move	d0,BoxLenY
	*-- Update knob coordinates
		Move.l	LayL(pc),a5
		Move.l	HitGd(pc),a4
		Add	#14+10,a4	;Add one 'GD' and one 'BX'

		Move.l	HitGd(pc),a3
		Move.l	6(a3),a3

		Move.b	(a3),d1
		Btst	#3,d1		;Is knob free X?
		Beq.b	NoFreeX2

		Move	-10+2(a4),d0	;Get BoxX1
		Addq	#2,d0
		Move	6(a3),d1	;Get %PosX
		Clr.l	d2
		Move	BoxLenX(pc),d2
		Mulu	d1,d2
		Swap	d2		;Divu #65536,d2
		Add	d2,d0
		Move	d0,2(a4)	;Put KnobX1
		
		Move	2(a3),d1	;Get %KnobX
		Clr.l	d2
		Move	BoxLenX(pc),d2
		Mulu	d1,d2
		Swap	d2		;Divu #65536,d2
		Add	d2,d0
		Addq	#1,d0
		Move	d0,6(a4)	;Put KnobX2

NoFreeX2:	Move.b	(a3),d1
		Btst	#2,d1		;Is knob free Y?
		Beq.b	NoFreeY2

		Move	-10+4(a4),d0	;Get BoxY1
		Addq	#2,d0
		Move	8(a3),d1	;Get %PosY
		Clr.l	d2
		Move	BoxLenY(pc),d2
		Mulu	d1,d2
		Swap	d2		;Divu #65536,d2
		Add	d2,d0
		Move	d0,4(a4)	;Put KnobY1
		
		Move	4(a3),d1	;Get %KnobY
		Clr.l	d2
		Move	BoxLenY(pc),d2
		Mulu	d1,d2
		Swap	d2		;Divu #65536,d2
		Add	d2,d0
		Addq	#1,d0
		Move	d0,8(a4)	;Put KnobY2
NoFreeY2:	Rts
UpdatePropG:
	*-- Update graphics
		Move.l	LayL(pc),a5
		Move.l	HitGd(pc),a4
		Clr	d0
		Move.b	2(a4),d0
		Move	d0,d7
		Addq	#1,d7
		Bsr.w	Draw_Some

		Movem.l	a0-a7/a0-a6,-(a7)
		Bsr.w	Distribute_Gadgets
		Movem.l	(a7)+,a0-a7/a0-a6

Prop_End:	Rts

BoxLenX:	Dc	0
BoxLenY:	Dc	0
*---------------
Gd_String:	Move.l	Active_StGd(pc),d0	;Any Active StringGd?
		Beq.b	GS_InAc
		Bsr.w	Deactive_StGd
	GS_InAc:Move.l	HitGd(pc),Active_StGd
		Move.l	LayL(pc),Active_StGdLay

		Move.l	Active_StGdLay(pc),a5
		Move.l	Active_StGd(pc),a4

		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Add	#14+10,a4	;Add 'GD'+'RC'
		Move.l	a3,a1
		Move	8(a4),d0

		Cmp	#5,d0
		Bne.b	GS_F5
		Lea	Font5,a0
	GS_F5:
		Cmp	#8,d0
		Bne.b	GS_F8
		Lea	Font8,a0
	GS_F8:
		Move.l	(a0),a0
		Jsr	SetFont(a6)
		Bsr.w	Calc_Coord
	*-- Find length of string
		Moveq.l	#-1,d3
		Tst.l	10(a4)
		Beq.w	GS_End
		Move.l	10(a4),a2
	GS_Lp:	Addq	#1,d3
		Tst.b	(a2)+
		Bne.b	GS_Lp

		Clr	d4
		Tst	d3
		Beq.b	GS_Ok
		
	GS_Len:	Move	d4,d0
		Addq	#1,d0
		Move.l	10(a4),a0
		Move.l	a3,a1
		Jsr	TextLength(a6)
		Move	X1(pc),d1
		Add	d0,d1
		Cmp	LayX(pc),d1
		Bgt.b	GS_Ok

		Addq	#1,d4
		Cmp	d4,d3
		Bne.b	GS_Len

	GS_Ok:	Move.l	Active_StGd(pc),a5
		Cmp	8(a5),d4
		Blt.b	GS_NOv
		Move	8(a5),d4
		Subq	#1,d4
	GS_NOv:	Move	d4,Cursor_Pos
		Bsr.w	StGd_UpdGfx
	*-- Copy to cancel buffer
		Lea	Cancel_Buf(pc),a0
		Lea	Number_Buf(pc),a2
		Move.l	Active_StGd(pc),a5
		Move.l	34(a5),a1		;Get String
		Move	8(a5),d0		;Get MaxLength
	GS_CnL:	Move.b	(a1),(a0)+
		Move.b	(a1)+,(a2)+
		Dbf	d0,GS_CnL
	*-- Replace String with buffer if number
		Move.l	Active_StGd(pc),a0
		Btst	#3,4(a0)
		Beq.b	GS_End
		Move.l	34(a5),Number_Old
		Lea	Number_Buf(pc),a0
		Move.l	a0,34(a5)
	GS_End:	Rts
*---------------
Deactive_StGd:	Move.l	Active_StGdLay(pc),a5	;Unpush gadget
		Move.l	Active_StGd(pc),d0
		Beq.w	DS_Nul
		Move.l	d0,a4
		Moveq.l	#1,d7
		Add.b	2(a4),d7
		Bclr	#0,4(a4)
		Bsr.w	Draw_Some
		Move.l	HitGd(pc),SaveHit
		Move.l	LayL(pc),SaveLay
	*-- Convert ASCII to value if NumbersOnly=1
		Move.l	Active_StGd(pc),a5
		Tst.l	34(a5)
		Beq.w	DS_Nul
		Btst	#3,4(a5)		;NumbersOnly=1 ?
		Beq.w	DS_NNo
		Move.l	34(a5),a0		;Get String
		Lea	Convert_Value(pc),a1
		Clr.l	(a1)
		Clr.l	d2
		Move.b	#'+',d1

	DS_CLp:	Move.b	(a0)+,d0
		Beq.b	DS_Sgn
		Cmp.b	#'+',d0
		Beq.b	DS_Sgn
		Cmp.b	#'-',d0
		Beq.b	DS_Sgn
		Bra.b	DS_NSg

	DS_Sgn:	Cmp.b	#'+',d1
		Bne.b	DS_NPl
		Add.l	d2,Convert_Value
	DS_NPl:	Cmp.b	#'-',d1
		Bne.b	DS_NMi
		Sub.l	d2,Convert_Value
	DS_NMi:	
		Move.b	d0,d1
		Beq.b	DS_Fin
		Clr.l	d2

	DS_NSg:	Cmp.b	#'0',d0
		Blt.b	DS_NFg
		Cmp.b	#'9',d0
		Bgt.b	DS_NFg
		Sub.b	#'0',d0

		Move.l	d2,d3
		Mulu	#10,d3
		Move.l	d2,d4
		Swap	d4
		Mulu	#10,d4
		Swap	d4
		Clr	d4
		Move.l	d3,d2
		Add.l	d4,d2
		
		Ext.w	d0
		Ext.l	d0
		Add.l	d0,d2
	DS_NFg:	Bra.b	DS_CLp
	DS_Fin:
	*-- Replace buffer with string if number
		Move.l	Active_StGd(pc),a0
		Btst	#3,4(a0)
		Beq.b	DS_NNo
		Move.l	Number_Old(pc),34(a5)
		
	DS_NNo:	Move.l	Active_StGdLay(pc),LayL
		Move.l	Active_StGd(pc),HitGd
		Beq.b	DS_No

		Clr.l	Active_StGd
		Bra.w	Distribute_Gadgets
	DS_No:	Move.l	SaveHit(pc),HitGd
		Move.l	SaveLay(pc),LayL
		Rts

	DS_Nul:	Clr.l	Active_StGd
		Rts

SaveHit:	Dc.l	0
SaveLay:	Dc.l	0
Convert_Value:	Dc.l	0
*---------------
Save_IFF:	;(A5=BitMap)
		Tst.l	8(a5)		;Any BitMap?
		Beq.w	SI_End		;No
	*-- Calculate Size
		Clr	d0
		Move.b	5(a5),d0	;Get Depth
		Mulu	(a5),d0		;BytesPerRow * Depth
		Mulu	2(a5),d0	; * Rows
		Add.l	#12+28+12+8+104+100,d0	;Add FORM,BMHD,CAMG,BODY,CMAP
						;+Safety buffer
	*-- Allocate Save Buffer memory
		Move.l	a5,SI_BitMap
		Lea	Mem_SaveBuf(pc),a5
		Bsr.w	Alloc_Any_Mem
		Beq.w	Mess_MemErr
	*-- Write data to Save Buffer
		Move.l	(a5),a0		;Get Address
		Move.l	SI_BitMap(pc),a5

		Move.l	#'FORM',(a0)+
		Clr.l	(a0)+
		Move.l	#'ILBM',(a0)+
		
		Move.l	#'BMHD',(a0)+
		Move.l	#20,(a0)+
		Move	(a5),d0
		Lsl	#3,d0
		Move	d0,(a0)+	;Width
		Move	2(a5),(a0)+	;Height
		Clr.l	(a0)+		;?
		Move.b	5(a5),(a0)+	;Depth
		Clr.b	(a0)+		;0
		Clr.b	(a0)+		;Compr
		Clr.b	(a0)+		;0
		Move.l	#$0011,(a0)+	;?
		Move	(a5),d0
		Lsl	#3,d0
		Move	d0,(a0)+	;ScrWidth
		Move	2(a5),(a0)+	;ScrHeight

		Move.l	#'CMAP',(a0)+
	*-- 2^Depth*3
		Moveq.l	#1,d0
		Clr.l	d1
		Move.b	5(a5),d1
		Rol.l	d1,d0
		Move	d0,d1
		Mulu	#3,d0
		Move.l	d0,(a0)+

		Move.l	Mem_Palette(pc),a1
	SI_CLp:	Move.b	(a1)+,d2
		Move.b	(a1)+,(a0)+
		Move.b	(a1)+,(a0)+
		Move.b	(a1)+,(a0)+
		Subq	#1,d1
		Bne.b	SI_CLp

		Move.l	#'CAMG',(a0)+
		Move.l	#4,(a0)+
		Clr.l	d0
		Move.b	5(a5),d0
		Ror.l	#4,d0
		Move.l	d0,(a0)+
		
		Move.l	#'BODY',(a0)+
		Clr	d0
		Move.b	5(a5),d0	;Get Depth
		Mulu	(a5),d0		;BytesPerRow * Depth
		Mulu	2(a5),d0	;* Rows
		Move.l	d0,(a0)+

		Clr.l	d3
		Clr	d1

	SI_YLp:	Clr	d0
		Lea	8(a5),a1

	SI_DLp:	Move.l	(a1)+,a2
		Clr.l	d2
		Add.l	d3,a2

	SI_XLp:	Move.b	(a2)+,(a0)+
		Addq	#1,d2
		Cmp	(a5),d2
		Bne.b	SI_XLp

		Addq	#1,d0
		Cmp.b	5(a5),d0
		Bne.b	SI_DLp

		Clr.l	d7
		Move	(a5),d7
		Add.l	d7,d3

		Addq	#1,d1
		Cmp	2(a5),d1
		Bne.b	SI_YLp
	*-- Write File
		Move.l	a0,SI_FileEnd

		Lea	SI_FileName(pc),a0
		Bsr.w	Open_New_File
		Bne.b	SI_NEr1
		Lea	Mem_SaveBuf(pc),a5
		Bsr.w	Free_Mem
		Bra.w	Mess_FileErr
		
	SI_NEr1:Lea	Mem_SaveBuf(pc),a5
		Move.l	(a5),a0		
		Move.l	SI_FileEnd(pc),d0
		Sub.l	a0,d0
		Move.l	d0,d1
		Subq.l	#8,d1
		Move.l	d1,4(a0)
		Bsr.w	Write_File	;*++ Error handling

		Bsr.w	Close_File

	SI_Err1:Lea	Mem_SaveBuf(pc),a5
		Bsr.w	Free_Mem
	SI_End:	Rts

SI_BitMap:	Dc.l	0
SI_FileName:	Dc.b	'DF0:TestIFF',0
SI_FileEnd:	Dc.l	0
*---------------
Quit_Layer:	Move.l	LayL(pc),a5
		Bra.w	Close_Layer
*---------------
Drag_Layer:	Move.l	LayL(pc),a5		;Close Layer
		Bsr.w	Close_Layer
		Clr	First

	DLLoop:	Move.l	Screen_Struct(pc),a0	;Read mouse XY
		Move.l	LayL(pc),a4
		Move	18(a0),d0
		Sub	LayX(pc),d0
		Sub	08(a4),d0
		Move	16(a0),d1
		Sub	LayY(pc),d1
		Sub	10(a4),d1
		Add	d0,08(a4)		;Adjust Layer Position
		Add	d0,12(a4)
		Add	d1,10(a4)
		Add	d1,14(a4)
		Bsr.w	Check_Layer_Limits

		Move	First(pc),d0		;Detect movement
		Beq.b	No1st
		Move	12(a4),d7
		Sub	LastX2(pc),d7
		Bne.b	MovXY
		Move	14(a4),d7
		Sub	LastY2(pc),d7
		Beq.b	NMovXY

	MovXY:	Bsr.w	Screen_Rect		;Remove old rectangle
	No1st:	Move	08(a4),LastX1		;Draw new rectangle
		Move	10(a4),LastY1
		Move	12(a4),LastX2
		Move	14(a4),LastY2
		Bsr.w	Screen_Rect
		Move	#1,First		;No longer first
	NMovXY:	Bsr.w	Check_Left_Up
		Beq.w	DLLoop

		Bsr.w	Screen_Rect		;Remove old rectangle
		Move.l	LayL(pc),a5		;Reopen layer at new pos
		Bra.w	Open_Layer
*---------------
Depth_Layer:	Move.l	LayL(pc),a1
		Move.l	(a1),a1
		Move.l	Layer_Info(pc),a0
		Move.l	LayBase(pc),a6
		Tst.l	(a1)
		Bne.b	DL_Frnt
		Jmp	BehindLayer(a6)
	DL_Frnt:Jmp	UpfrontLayer(a6)
*---------------
Size_Layer:	Move.l	LayL(pc),a5		;Close Layer
		Bsr.w	Close_Layer
		Clr	First
		Move.l	LayL(pc),a4
		Move	08(a4),ExX
		Move	10(a4),ExY

	SLLoop:	Move.l	Screen_Struct(pc),a0	;Read mouse XY
		Move.l	LayL(pc),a4
		Move	18(a0),d0
		Sub	LayX(pc),d0
		Sub	ExX(pc),d0
		Move	16(a0),d1
		Sub	LayY(pc),d1
		Sub	ExY(pc),d1
		Add	d0,12(a4)		;Adjust Layer Position
		Add	d1,14(a4)
		Add	d0,ExX
		Add	d1,ExY
	*-- Check layer size and position limits
		Bsr.w	Check_Layer_Size

		Move	First(pc),d0		;Detect movement
		Beq.b	SN1st
		Move	12(a4),d7
		Sub	LastX2(pc),d7
		Bne.b	SMovXY
		Move	14(a4),d7
		Sub	LastY2(pc),d7
		Beq.b	SNMovXY
	
	SMovXY:	Bsr.w	Screen_Rect		;Remove old rectangle
	SN1st:	Move	08(a4),LastX1		;Draw new rectangle
		Move	10(a4),LastY1
		Move	12(a4),LastX2
		Move	14(a4),LastY2
		Bsr.w	Screen_Rect
		Move	#1,First		;No longer first
	SNMovXY:Bsr.w	Check_Left_Up
		Beq.w	SLLoop
		
		Bsr.w	Screen_Rect		;Remove old rectangle
		Move.l	LayL(pc),a5		;Reopen layer at new pos
		Bra.w	Open_Layer
ExX:		Dc	0
ExY:		Dc	0
*---------------
;Open_Screens:	Lea	Screen_StructA(pc),a5
;		Bra.w	Open_1Screen
;
;Open_1Screen:	Tst.l	(a5)			;Screen Opened?
;		Bne.b	OS_Op			;Yes, Abort
;		Move.l	IntBase(pc),a6		;Get IntBase
;		Lea	NewScreen_StructA(pc),a0;Get NewScreen Structure
;		Jsr	OpenScreen(a6)		;Open Screen
;		Move.l	d0,(a5)			;Save Screen Struct
;		Beq.b	OS_End			;If Error, Abort
;	OS_Op:	Move.l	(a5),a0			;Write Palette
;		Bsr.b	Write_Palette		;+
;	OS_End:	Rts				;End
;*---------------
;Close_Screens:	Lea	Screen_StructA(pc),a5
;		Bra.w	Close_1Screen
;		
;Close_1Screen:	Tst.l	(a5)			;Screen Opened?
;		Beq.b	CS_Cl			;No, Abort
;		Move.l	(a5),a0			;Get Screen Struct
;		Move.l	IntBase(pc),a6		;Get IntBase
;		Jsr	CloseScreen(a6)		;Call CloseScreen
;		Clr.l	(a5)			;Clear Screen Handle
;	CS_Cl:	Rts				;End
;*---------------
;Swap_Screens:	Lea	Screen_StructA(pc),a0
;		Move.l	IntBase(pc),a6
;		Jmp	ScreenToFront(a6)
;*---------------
;NewScreen_StructA:
;ScreenA_XYPos:		Dc	0,0
;ScreenA_XYSize:		Dc	320,256
;ScreenA_Depth:		Dc	4
;ScreenA_PenColors:	Dc.b	0,1
;ScreenA_ViewModes:	Dc	$0002
;ScreenA_Type:		Dc	$018f	;NoIntRender Behind CustomScreen
;ScreenA_Font:		Dc.l	0
;ScreenA_Title:		Dc.l	0
;ScreenA_Gadgets:	Dc.l	0
;ScreenA_BitMap:		Dc.l	0

;Screen_StructA:		Dc.l	0
*---------------
PlusMinus:	Move.l	HitGd(pc),a5	;Get hit gadget
		Move.l	6(a5),a4	;Get PlusMinus structure

		Moveq.l	#-72,d6		;Length of string gd + minus gd
		Move	(a4),d7		;Get step value
		Move	32(a5),d0	;Plus or Minus?
		Cmp	#Im_Plus-Im,d0	;+ Let's see...
		Beq.b	PM_Plus		;+ Plus!
		Neg	d7		;+ Minus!
		Add	#34,d6		;Length of minus gadget
	PM_Plus:Move.l	34(a5,d6.w),a0	;Get string
	*-- Convert ASCII to value
		Move.l	a0,d0
		Beq.w	PM_Ed

		Lea	Convert_Value(pc),a1
		Clr.l	(a1)
		Clr.l	d2
		Move.b	#'+',d1

	PM_CLp:	Move.b	(a0)+,d0
		Beq.b	PM_Sgn
		Cmp.b	#'+',d0
		Beq.b	PM_Sgn
		Cmp.b	#'-',d0
		Beq.b	PM_Sgn
		Bra.b	PM_NSg

	PM_Sgn:	Cmp.b	#'+',d1
		Bne.b	PM_NPl
		Add.l	d2,Convert_Value
	PM_NPl:	Cmp.b	#'-',d1
		Bne.b	PM_NMi
		Sub.l	d2,Convert_Value
	PM_NMi:	
		Move.b	d0,d1
		Beq.b	PM_Fin
		Clr.l	d2

	PM_NSg:	Cmp.b	#'0',d0
		Blt.b	PM_NFg
		Cmp.b	#'9',d0
		Bgt.b	PM_NFg
		Sub.b	#'0',d0
		Mulu	#10,d2
		Ext.w	d0
		Ext.l	d0
		Add.l	d0,d2
	PM_NFg:	Bra.b	PM_CLp
	PM_Fin:
		Move.l	Convert_Value,d5
		Add	d7,d5

		Cmp	4(a4),d5	;Check Max
		Ble.b	PM_NMx
		Move	4(a4),d5
	PM_NMx:
		Cmp	2(a4),d5	;Check Min
		Bge.b	PM_NMn
		Move	2(a4),d5
	PM_NMn:
		Ext.l	d5
		Move.l	d5,Convert_Value
		Move.l	10(a5,d6.w),d0	;Get routine
		Beq.b	PM_Ed
		Move.l	d0,a0
		Jmp	(a0)
	PM_Ed:	Rts
*---------------
Write_Palette:	;(A0=ScreenStructure)
		Add.l	#44,a0
		Move.l	a0,a5
		Move.l	Mem_Palette(pc),a3
		Move.l	GfxBase(pc),a6
		Clr.l	d6
		
		Moveq.l	#1,d7
		Move	Screen_Depth(pc),d0
		Lsl	d0,d7
		Cmp	#32,d7
		Bge.b	WP_Ok
		Moveq.l	#32,d7
	WP_Ok:	Subq	#1,d7
	WP_Lp:	Move.l	d6,d0
		Clr.l	d1
		Clr.l	d2
		Clr.l	d3
		Move.b	1(a3),d1
		Move.b	2(a3),d2
		Move.b	3(a3),d3
		Move.l	a5,a0

		Btst	#0,Prf_GfxFlags
		Beq.b	WP_NAa
		Move	AGA(pc),d5
		Beq.b	WP_NAa

		Ror.l	#8,d1
		Ror.l	#8,d2
		Ror.l	#8,d3
		Jsr	SetRGB8(a6)
		Bra.b	WP_Skip

	WP_NAa:	Lsr	#4,d1
		Lsr	#4,d2
		Lsr	#4,d3
		Jsr	SetRGB4(a6)

	WP_Skip:Addq.l	#1,d6
		Addq	#4,a3
		Dbf	d7,WP_Lp
		Rts
*---------------
Find_Colors:	;(Find LoCol, BkCol, MdCol, HiCol)
		Move	#$00,Red
		Move	#$00,Grn
		Move	#$00,Blu
		Bsr.b	Find_Col
		Lea	LoCol(pc),a0
		Move	d0,(a0)
		Move	#$30,Red
		Move	#$30,Grn
		Move	#$30,Blu
		Bsr.b	Find_Col
		Lea	BkCol(pc),a0
		Move	d0,(a0)
		Move	#$70,Red
		Move	#$70,Grn
		Move	#$70,Blu
		Bsr.b	Find_Col
		Lea	MdCol(pc),a0
		Move	d0,(a0)
		Move	#$ff,Red
		Move	#$ff,Grn
		Move	#$ff,Blu
		Bsr.b	Find_Col
		Lea	HiCol(pc),a0
		Move	d0,(a0)
		Rts
*---------------
Find_Col:	;(Red/Grn/Blu=ColorToFind, D0->ColorFound)
		Move.l	Mem_Palette(pc),a0
		Clr	d0
		Move	#999,RecVal

	FC_Lp:	Clr	d1
		Clr	d2
		Clr	d3
		Move.b	1(a0),d1
		Move.b	2(a0),d2
		Move.b	3(a0),d3
		Addq	#4,a0

		Sub	Red(pc),d3
		Bpl.b	FC_ROk
		Neg	d3
	FC_ROk:	Sub	Grn(pc),d2
		Bpl.b	FC_GOk
		Neg	d2
	FC_GOk:	Sub	Blu(pc),d1
		Bpl.b	FC_BOk
		Neg	d1
	FC_BOk:	Add	d2,d1
		Add	d3,d1
		Cmp	RecVal(pc),d1
		Bhs.b	FC_NoRc
		Move	d1,RecVal
		Move	d0,RecCol

	FC_NoRc:Addq	#1,d0
		Moveq.l	#1,d1
		Move	Screen_Depth(pc),d2
		Lsl	d2,d1
		Cmp	d1,d0
		Bne.b	FC_Lp
		Move	RecCol(pc),d0
		Rts
Red:	Dc	0
Grn:	Dc	0
Blu:	Dc	0
RecVal:	Dc	0
RecCol:	Dc	0
LoCol:	Dc	4
BkCol:	Dc	3
MdCol:	Dc	2
HiCol:	Dc	1
*---------------
Calc_Coord:	Move	2(a4),d0
		Bpl.b	CC_Pl1
		Add	12(a5),d0
		Sub	8(a5),d0
		Addq	#1,d0
	CC_Pl1:	Move	d0,X1
		Move	4(a4),d0
		Bpl.b	CC_Pl2
		Add	14(a5),d0
		Sub	10(a5),d0
		Addq	#1,d0
	CC_Pl2:	Move	d0,Y1
		Move	6(a4),d0
		Bpl.b	CC_Pl3
		Add	12(a5),d0
		Sub	8(a5),d0
		Addq	#1,d0
	CC_Pl3:	Move	d0,X2
		Move	8(a4),d0
		Bpl.b	CC_Pl4
		Add	14(a5),d0
		Sub	10(a5),d0
		Addq	#1,d0
	CC_Pl4:	Move	d0,Y2
		Rts
X1:		Dc	0
Y1:		Dc	0
X2:		Dc	0
Y2:		Dc	0
*---------------
LayerList:
DeskLay:Dc.l	0		;00 - Layer
	Dc.l	'DESK'		;04 - Name
	Dc	000,000,319,255	;08 - X1,Y1,X2,Y2
	Dc	$0041		;16 - Flags
	Dc.l	DrawList_Desk	;18 - DrawList
	Dc	000,000,320,256	;22 - MinX,MinY,MaxX,MaxY
GameLay:Dc.l	0
	Dc.l	'GAME'
	Dc	050,040,267,102
	Dc	$0002
	Dc.l	DrawList_Game
	Dc	000,000,320,256
PictLay:Dc.l	0
	Dc.l	'PICT'
	Dc	000,011,319,255
	Dc	$0002
	Dc.l	DrawList_Pict
	Dc	185,059,320,256
PiecLay:Dc.l	0
	Dc.l	'PIEC'
	Dc	176,048,319,187
	Dc	$0002
	Dc.l	DrawList_Piec
	Dc	143,079,320,256
AnimLay:Dc.l	0
	Dc.l	'ANIM'
	Dc	000,048,177,168
	Dc	$0002
	Dc.l	DrawList_Anim
	Dc	177,120,320,256
MoveLay:Dc.l	0
	Dc.l	'MOVE'
	Dc	000,019,278,224
	Dc	$0002
	Dc.l	DrawList_Move
	Dc	000,000,320,256
MPrtLay:Dc.l	0
	Dc.l	'MPRT'
	Dc	000,100,185,212
	Dc	$0002
	Dc.l	DrawList_MPrt
	Dc	000,000,320,256
ObjcLay:Dc.l	0
	Dc.l	'OBJC'
	Dc	050,011,214,188
	Dc	$0002
	Dc.l	DrawList_Objc
	Dc	164,177,320,256
BackLay:Dc.l	0
	Dc.l	'BACK'
	Dc	000,011,319,255
	Dc	$0002
	Dc.l	DrawList_Back
	Dc	163,068,320,256
LevlLay:Dc.l	0
	Dc.l	'LEVL'
	Dc	100,020,265,247
	Dc	$0002
	Dc.l	DrawList_Levl
	Dc	165,227,320,227
WaveLay:Dc.l	0
	Dc.l	'WAVE'
	Dc	100,020,265,157
	Dc	$0002
	Dc.l	DrawList_Wave
	Dc	165,227,320,227
SelcLay:Dc.l	0
	Dc.l	'SELC'
	Dc	084,133,258,255
	Dc	$0002
	Dc.l	DrawList_Selc
	Dc	000,000,320,256
OpenLay:Dc.l	0
	Dc.l	'OPEN'
	Dc	129,050,190,127
	Dc	$0002
	Dc.l	DrawList_Open
	Dc	000,000,319,255
QuitLay:Dc.l	0
	Dc.l	'QUIT'
	Dc	110,050,209,091
	Dc	$0002
	Dc.l	DrawList_Quit
	Dc	099,041,320,256
MessLay:Dc.l	0
	Dc.l	'MESS'
	Dc	060,050,259,062
	Dc	$0002
	Dc.l	DrawList_Mess
	Dc	000,000,320,256
InfoLay:Dc.l	0
	Dc.l	'INFO'
	Dc	074,040,246,143
	Dc	$0002
	Dc.l	DrawList_Info
	Dc	000,000,320,256
DrawLay:Dc.l	0
	Dc.l	'DRAW'
	Dc	100,100,229,136
	Dc	$0002
	Dc.l	DrawList_Draw
	Dc	000,000,320,256
ScrnLay:Dc.l	0
	Dc.l	'SCRN'
	Dc	000,011,319,255
	Dc	$0002
	Dc.l	DrawList_Scrn
	Dc	128,050,320,256
SEvnLay:Dc.l	0
	Dc.l	'SEVN'
	Dc	160,030,319,227
	Dc	$0002
	Dc.l	DrawList_SEvn
	Dc	152,197,320,197
SModLay:Dc.l	0
	Dc.l	'SMOD'
	Dc	000,030,159,227
	Dc	$0002
	Dc.l	DrawList_SMod
	Dc	152,197,320,197
FontLay:Dc.l	0
	Dc.l	'FONT'
	Dc	100,069,261,249
	Dc	$0002
	Dc.l	DrawList_Font
	Dc	161,149,320,149
PaltLay:Dc.l	0
	Dc.l	'PALT'
	Dc	100,100,254,241
	Dc	$0002
	Dc.l	DrawList_Palt
	Dc	154,120,320,256
PrefLay:Dc.l	0
	Dc.l	'PREF'
	Dc	078,040,242,110
	Dc	$0002
	Dc.l	DrawList_Pref
	Dc	000,000,320,256
ScrlLay:Dc.l	0
	Dc.l	'SCRL'
	Dc	100,100,277,249
	Dc	$0002
	Dc.l	DrawList_Scrl
	Dc	000,000,320,256
;GridLay:Dc.l	0
;	Dc.l	'GRID'
;	Dc	020,020,227,052
;	Dc	$0002
;	Dc.l	DrawList_Grid
;	Dc	000,000,320,256
WeapLay:Dc.l	0
	Dc.l	'WEAP'
	Dc	100,022,291,255
	Dc	$0002
	Dc.l	DrawList_Weap
	Dc	000,000,320,256
RequLay:Dc.l	0
	Dc.l	'REQU'
	Dc	100,040,219,078
	Dc	$0002
	Dc.l	DrawList_Requ
	Dc	000,000,320,256
SnapLay:Dc.l	0
	Dc.l	'SNAP'
	Dc	050,030,254,210
	Dc	$0002
	Dc.l	DrawList_Snap
	Dc	093,049,320,256
PathLay:Dc.l	0
	Dc.l	'PATH'
	Dc	050,030,168,083
	Dc	$0002
	Dc.l	DrawList_Path
	Dc	118,053,320,053
SondLay:Dc.l	0
	Dc.l	'SOND'
	Dc	000,011,177,255
	Dc	$0002
	Dc.l	DrawList_Sond
	Dc	104,150,320,256
SmplLay:Dc.l	0
	Dc.l	'SMPL'
	Dc	100,100,277,255
	Dc	$0002
	Dc.l	DrawList_Smpl
	Dc	000,000,320,256
SongLay:Dc.l	0
	Dc.l	'SONG'
	Dc	000,020,208,081
	Dc	$0002
	Dc.l	DrawList_Song
	Dc	191,061,320,256
ModlLay:Dc.l	0
	Dc.l	'MODL'
	Dc	000,090,178,134
	Dc	$0002
	Dc.l	DrawList_Modl
	Dc	178,044,320,256
InvnLay:Dc.l	0
	Dc.l	'INVN'
	Dc	000,050,178,120
	Dc	$0002
	Dc.l	DrawList_Invn
	Dc	178,070,178,070
OEvnLay:Dc.l	0
	Dc.l	'OEVN'
	Dc	000,050,178,194
	Dc	$0002
	Dc.l	DrawList_OEvn
	Dc	178,044,320,256
;LoggLay:Dc.l	0
;	Dc.l	'LOGG'
;	Dc	100,040,214,110
;	Dc	$0002
;	Dc.l	DrawList_Logg
;	Dc	000,000,320,256
PlayLay:Dc.l	0
	Dc.l	'PLAY'
	Dc	000,050,178,194
	Dc	$0002
	Dc.l	DrawList_Play
	Dc	178,044,320,256
InptLay:Dc.l	0
	Dc.l	'INPT'
	Dc	190,100,319,194
	Dc	$0002
	Dc.l	DrawList_Inpt
	Dc	100,044,320,256
	Dc.l	-1
*---------------
Memory_List:
Mem_FlipBuf:	Dc.l	0,0
Mem_Picture:	Dc.l	0,0
Mem_PiecBuf:	Dc.l	0,0
Mem_BackBuf:	Dc.l	0,0
Mem_AnimBuf:	Dc.l	0,0
Mem_MoveBuf:	Dc.l	0,0
Mem_ObjcBuf:	Dc.l	0,0
Mem_PaltBuf:	Dc.l	0,0
Mem_LevlBuf:	Dc.l	0,0
Mem_WaveBuf:	Dc.l	0,0
Mem_WeapBuf:	Dc.l	0,0
Mem_PlayBuf:	Dc.l	0,0
Mem_ScrnBuf:	Dc.l	0,0
Mem_SaveBack:	Dc.l	0,0
Mem_SaveBuf:	Dc.l	0,0
Mem_DirList:	Dc.l	0,0
Mem_ImageBuf:	Dc.l	0,0
Mem_PointerBuf:	Dc.l	0,0
Mem_PiecList:	Dc.l	0,0
Mem_AnimList:	Dc.l	0,0
Mem_BackList:	Dc.l	0,0
Mem_MoveList:	Dc.l	0,0
Mem_ObjcList:	Dc.l	0,0
Mem_LevlList:	Dc.l	0,0
Mem_WaveList:	Dc.l	0,0
Mem_PaltList:	Dc.l	0,0
Mem_FontList:	Dc.l	0,0
Mem_ScrnList:	Dc.l	0,0
Mem_WeapList:	Dc.l	0,0
Mem_SondList:	Dc.l	0,0
Mem_SmplList:	Dc.l	0,0
Mem_SongList:	Dc.l	0,0
Mem_ModlList:	Dc.l	0,0
Mem_PlayList:	Dc.l	0,0
Mem_Palette:	Dc.l	0,0
Mem_Clip:	Dc.l	0,0
Mem_Iff:	Dc.l	0,0
Mem_ScrollTab:	Dc.l	0,0
Mem_FreeHand:	Dc.l	0,0
Mem_ScrnText:	Dc.l	0,0
Mem_Screen:	Dc.l	0,0
Mem_SaveBack1:	Dc.l	0,0
Mem_SaveBack2:	Dc.l	0,0
Mem_SaveList1:	Dc.l	0,0
Mem_SaveList2:	Dc.l	0,0
Mem_Objects:	Dc.l	0,0
Mem_MaskBuffer:	Dc.l	0,0
Mem_Copper1:	Dc.l	0,0
Mem_PathList:	Dc.l	0,0
Mem_Null:	Dc.l	0,0
Mem_ZGfx:	Dc.l	0,0
Mem_ZMsk:	Dc.l	0,0
Mem_GfxBuf:	Dc.l	0,0
Mem_TmpRas:	Dc.l	0,0
Mem_Zoom:	Dc.l	0,0	;Adr.L,Size.L
		Dc.l	-1	;End of memory list
*---------------
NewScreen_Struct:
Screen_XYPos:		Dc	0,0
Screen_XSize:		Dc	320
Screen_YSize:		Dc	256
Screen_Depth:		Dc	4	;Desk depth
Screen_PenColors:	Dc.b	0,1
Screen_ViewModes:	Dc	$0002
Screen_Type:		Dc	$018f	;NoIntRender Behind CustomScreen
Screen_Font:		Dc.l	0
Screen_Title:		Dc.l	0
Screen_Gadgets:		Dc.l	0
Screen_BitMap:		Dc.l	0

Screen_Struct:		Dc.l	0
Layer_Info:		Dc.l	0
Window_Struct:		Dc.l	0
Message_Port:		Dc.l	0
*---------------
Conv:		Movem.l	d0-d7/d0-a6,-(a7)
		Move	d7,d6
		And	#$ff,d7
		Clr	d5
		Clr	ConvF
		Btst	#7+8,d6		;Write '-'?
		Beq.b	ConvLp		;No
		Tst	d0		;Is negative?
		Bpl.b	ConvLp		;No
		Neg	d0
		Move	#1,ConvF
		
	ConvLp:	And.l	#$ffff,d0
		Divu	#10,d0
		Move.l	d0,d3
		Swap	d3
		Add.b	#48,d3
		Tst	d0
		Bne.b	ConvN0
		Cmp.b	#'0',d3
		Bne.b	ConvN0
		Btst	#7+8,d6		;Write '-'?
		Beq.b	ConvNMi		;No
		Tst	ConvF		;Was is minus?
		Beq.b	ConvNMi		;No
		Move.b	#'-',d3		;Prepare a '-'
		Clr	ConvF		;Clear Minusflag
		Bra.b	ConvN0
	ConvNMi:Btst	#0+8,d6
		Beq.b	ConvN0
		Tst	d5
		Beq.b	ConvN0
		Move.b	#' ',d3
	ConvN0:	Move.b	d3,-(a0)
		Addq	#1,d5
		Dbf	d7,ConvLp
		Movem.l	(a7)+,d0-d7/d0-a6
		Rts
	ConvF:	Dc	0
*---------------
Which_Layer:	;(Find out which layer, and calculate coords)
		Move	RawX(pc),d0		;Which Layer
		Move	RawY(pc),d1
		Move.l	Layer_Info(pc),a0
		Move.l	LayBase(pc),a6
		Jsr	WhichLayer(a6)
		Clr.l	LayL			;Find Layer
		Lea	LayerList(pc),a0
	FindL:	Move.l	(a0),d1
		Cmp.l	d1,d0
		Beq.b	Found
		Add	#30,a0
		Bra.b	FindL
	Found:	Move.l	a0,LayL
		Move	RawX(pc),d1		;Calculate coordinates
		Sub	8(a0),d1
		Move	d1,LayX
		Move	RawY(pc),d1
		Sub	10(a0),d1
		Move	d1,LayY
		Rts
LayX:		Dc	0
LayY:		Dc	0
RawX:		Dc	0
RawY:		Dc	0
LayL:		Dc.l	0
*---------------
Open_Layer:	;(A5=Layer)
		Cmp.l	#'DESK',4(a5)
		Beq.b	OL_Ok
		Move.l	a5,a4
		Bsr.w	Check_Layer_Size
	OL_Ok:	Tst.l	(a5)			;Layer Open?
		Bne.b	LayOpen			;Yes, Abort
		Move.l	Layer_Info(pc),a0	;Get Layer Info
		Move.l	Screen_Struct(pc),a1	;Get Screen Structure
		Add	#$b8,a1			;Get Bitmap
		Move	08(a5),d0		;X1
		Move	10(a5),d1		;Y1
		Move	12(a5),d2		;X2
		Move	14(a5),d3		;Y2
		Move	16(a5),d4		;Get Flags
		Lea	0.w,a2			;No Bitmap
		Move.l	LayBase(pc),a6		;Get LayBase
		Jsr	CreateUpfrontLayer(a6)	;Open Layer
		Move.l	d0,(a5)			;Save Layer Address
		Beq.b	LayrErr			;If Error, Abort
		Move.l	18(a5),a4		;Draw Layer
		Bsr.w	Draw_All		;+
		Moveq.l	#-1,d7			;No Errors
		Rts
	LayOpen:Move.l	Layer_Info(pc),a0	;Bring Layer Upfront
		Move.l	(a5),a1			;+
		Move.l	LayBase(pc),a6		;+
		Moveq.l	#-1,d7			;+ No Errors
		Jmp	UpfrontLayer(a6)	;+
	LayrErr:Clr.l	d7			;Set ErrorFlag
		Rts				;End
*---------------
Find_Unit_Space:;(A4=XxxxList, A0->Address, D7->Number)
		Movem.l	d0-d6/a1-a6,-(a7)
		Move	#1,Game_NeedUpd
		Tst	4(a4)		;Length=0?
		Beq.b	FUS_Str		;Yes, Stretch
	FUS_Ag:	Move.l	(a4),a0		;Get XxxxList address
		Move.l	(a0),a0		;+
		Clr.l	d7		;Clear counter
	FUS_Lp:	Move	4(a0),d0	;Space?
		Btst	#0,d0		;+
		Beq.b	FUS_Suc		;Yes!
		Add	#32,a0		;Next
		Addq	#1,d7		;Inc counter
		Cmp	4(a4),d7	;Reached the end?
		Bne.b	FUS_Lp		;No
	*-- Stretch List
	FUS_Str:Clr.l	d0		;D0 = Old Length
		Move	4(a4),d0	;+
		Addq	#8,d0		;+ Add extra space
		Lsl.l	#5,d0		;+ Multiply by 32

		Lea	Mem_Temp(pc),a5	;A5 = New list MemLabel
		Clr.l	(a5)		;Clear MemLabel
		Bsr.w	Alloc_Any_Mem	;Allocate memory, (and clear it)
		Beq.b	FUS_Err		;Out of memory

		Move.l	(a4),a2		;A2 = Old list MemLabel
		Move.l	(a2),a0		;A0 = Old address
		Move.l	4(a2),d0	;D0 = Old size
		Beq.b	FUS_Zip		;Old size was 0?
		Move.l	(a5),a1		;A1 = New address
		Lsr.l	#2,d0		;Divide old size by 4
		Subq	#1,d0		;Subtract 1 for Dbf
	FUS_Mv:	Move.l	(a0)+,(a1)+	;Move it
		Dbf	d0,FUS_Mv	;+

		Move.l	a2,a5
		Bsr.w	Free_Mem	;Free Old list

	FUS_Zip:Lea	Mem_Temp(pc),a5	;A5 = New list MemLabel
		Move.l	(a5),(a2)	;Copy New list MemLabel
		Move.l	4(a5),4(a2)	;+

		Addq	#8,4(a4)
		Bra.b	FUS_Ag		;Try again
	FUS_Err:Sub.l	a0,a0		;Clear address
	FUS_Suc:Movem.l	(a7)+,d0-d6/a1-a6
		Rts			;End

Mem_Temp:	Dc.l	0,0
*---------------
IntBase:	Dc.l	0
		Dc.b	'intuition.library',0
DosBase:	Dc.l	0
		Dc.b	'dos.library',0
GfxBase:	Dc.l	0
		Dc.b	'graphics.library',0,0
LayBase:	Dc.l	0
		Dc.b	'layers.library',0,0
*---------------
Mess_CMemErr:	Lea	OutOfCMemT(pc),a0
		Bra.b	Display_Message
Mess_MemErr:	Lea	OutOfMemT(pc),a0
		Bra.b	Display_Message
Mess_IffCErr:	Lea	NotIffT(pc),a0
		Bra.b	Display_Message
Mess_FileErr:	Lea	NoFileT(pc),a0

Display_Message:;(A0=Pointer to message string)
		Move.l	a0,Mess_Ptr
		Lea	MessLay(pc),a5
		Move	#062,08(a5)
		Move	#090,10(a5)
		Move	#257,12(a5)
		Move	#102,14(a5)
		Bsr.w	Close_Layer
		Bsr.w	Open_Layer
		Bsr.w	Close_File
		Moveq.l	#-1,d7
		Move.l	StartSP,a7	;###
		Jmp	Main_Loop	;###
*---------------
Alloc_Chip_Mem:	;(D0=Size, A5=Label, D7->Status)
		Move.l	#$10002,d1	;ChipMem
		Bra.b	Alloc_Mem
*---------------
Alloc_Any_Mem:	;(D0=Size, A5=Label, D7->Status)
		Move.l	#$10000,d1	;AnyMem
Alloc_Mem:	Tst.l	(a5)
		Bne.b	Allocd_Mem
		Move.l	d0,4(a5)
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	d0,(a5)
Allocd_Mem:	Move.l	d0,d7
		Rts
*---------------
Free_Mem: 	;(A5=Label)
		Tst.l	(a5)
		Beq.b	Freed_Mem
		Move.l	(a5),a1
		Move.l	4(a5),d0
		Move.l	4.w,a6
		Jsr	FreeMem(a6)
		Clr.l	(a5)
Freed_Mem:	Rts
*---------------
Draw_All:	;(Draw complete drawlist. A5=Layer, A4=DrawList)
		Move	#32767,d7
Draw_Some:	Move	d7,DrawLines
		Tst.l	(a5)		;Layer open?
		Beq.w	Draw_End	;No!
		Clr.b	Invert
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3
Draw_Next:	Subq.b	#1,Invert
		Bpl.b	Draw_Inv
		Clr.b	Invert
Draw_Inv:	Subq	#1,DrawLines
		Bmi.b	Draw_End
		Move	(a4),d7
		Cmp	#'BX',d7
		Beq.w	DrawBX
		Cmp	#'IM',d7
		Beq.w	DrawIM
		Cmp	#'TX',d7
		Beq.w	DrawTX
		Cmp	#'GD',d7
		Beq.w	DrawGD
		Cmp	#'FR',d7
		Beq.w	DrawFR
		Cmp	#'RC',d7
		Beq.w	DrawRC
		Cmp	#'RO',d7
		Beq.w	DrawRO
		Cmp	#'JP',d7
		Beq.w	DrawJP
		Cmp	#'JS',d7
		Beq.w	DrawJS
		Cmp	#'RT',d7
		Beq.w	DrawRT
		Cmp	#'DF',d7
		Beq.w	DrawDF
Draw_End:	Rts
DrawLines:	Dc	0
Invert:		Dc	0
*---------------
Check_Left_Dn:	Move.b	#$68,d6
		Bra.b	Check_Button
*---------------
Check_Right_Up:	Move.b	#$69+$80,d6
		Bra.b	Check_Button
*---------------
Check_Left_Up:	Move.b	#$68+$80,d6
Check_Button:	Move.l	Message_Port(pc),a0	;Get Message
		Move.l	4.w,a6
		Jsr	GetMsg(a6)
		Lea	Message(pc),a0
		Move.l	d0,(a0)
		Beq.b	CB_No
		Move.l	d0,a0			;Read mousebuttons
		Move.l	20(a0),d4
		Move	24(a0),d5
		Bsr.w	Reply
		Btst	#3,d4			;MouseButtons?
		Beq.b	CB_No			;No
		Cmp.b	d6,d5			;Button Up/Dn?
		Beq.b	CB_Yes			;Yes
	CB_No:	Clr.l	d0
		Rts
	CB_Yes:	Moveq.l	#-1,d0
		Rts
*---------------
Check_Layer_Size:
		Move	LimY1(pc),d1
		Cmp	10(a4),d1
		Ble.b	CLS0
		Move	10(a4),d0
		Sub	d1,d0
		Sub	d0,14(a4)
		Move	d1,10(a4)
	CLS0:	
		Move	LimX2(pc),d1
		Cmp	12(a4),d1
		Bge.b	CLS1
		Move	12(a4),d0
		Sub	d1,d0
		Sub	d0,ExX
		Move	d1,12(a4)

	CLS1:	Move	LimY2(pc),d1
		Cmp	14(a4),d1
		Bge.b	CLS2
		Move	14(a4),d0
		Sub	d1,d0
		Sub	d0,ExY
		Move	d1,14(a4)

	CLS2:	Move	26(a4),d1
		Add	08(a4),d1
		Cmp	12(a4),d1
		Bge.b	CLS3
		Move	12(a4),d0
		Sub	d1,d0
		Sub	d0,ExX
		Move	d1,12(a4)

	CLS3:	Move	28(a4),d1
		Add	10(a4),d1
		Cmp	14(a4),d1
		Bge.b	CLS4
		Move	14(a4),d0
		Sub	d1,d0
		Sub	d0,ExY
		Move	d1,14(a4)

	CLS4:	Move	22(a4),d1
		Add	08(a4),d1
		Cmp	12(a4),d1
		Ble.b	CLS5
		Move	12(a4),d0
		Sub	d1,d0
		Sub	d0,ExX
		Move	d1,12(a4)

	CLS5:	Move	24(a4),d1
		Add	10(a4),d1
		Cmp	14(a4),d1
		Ble.b	CLS6
		Move	14(a4),d0
		Sub	d1,d0
		Sub	d0,ExY
		Move	d1,14(a4)
	CLS6:	Rts
*---------------
Screen_Rect:	Move.l	GfxBase(pc),a6
		Move.l	Screen_Struct(pc),a1
		Lea	84(a1),a3
		;Move	#$ffff,34(a3)	;Pattern
		Moveq.l	#2,d0
		Move.l	a3,a1
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	LastX1(pc),d0
		Move	LastY1(pc),d1
		Jsr	Move(a6)
		Move.l	a3,a1
		Move	LastX2(pc),d0
		Move	LastY1(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	LastX2(pc),d0
		Move	LastY2(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	LastX1(pc),d0
		Move	LastY2(pc),d1
		Jsr	Draw(a6)
		Move.l	a3,a1
		Move	LastX1(pc),d0
		Move	LastY1(pc),d1
		Addq	#1,d1
		Jmp	Draw(a6)
LastX1:	Dc	0
LastY1:	Dc	0
LastX2:	Dc	0
LastY2:	Dc	0
First:	Dc	0
*---------------
Check_Layer_Limits:
		Move	LimX1(pc),d1
		Cmp	08(a4),d1
		Ble.b	CLL1
		Move	8(a4),d0
		Sub	d1,d0
		Sub	d0,12(a4)
		Move	d1,08(a4)
	CLL1:	Move	LimY1(pc),d1
		Cmp	10(a4),d1
		Ble.b	CLL2
		Move	10(a4),d0
		Sub	d1,d0
		Sub	d0,14(a4)
		Move	d1,10(a4)
	CLL2:	Move	LimX2(pc),d1
		Cmp	12(a4),d1
		Bge.b	CLL3
		Move	12(a4),d0
		Sub	d1,d0
		Sub	d0,8(a4)
		Move	d1,12(a4)
	CLL3:	Move	LimY2(pc),d1
		Cmp	14(a4),d1
		Bge.b	CLL4
		Move	14(a4),d0
		Sub	d1,d0
		Sub	d0,10(a4)
		Move	d1,14(a4)
	CLL4:	Rts
LimX1:		Dc	0
LimY1:		Dc	11
LimX2:		Dc	319
LimY2:		Dc	255
*---------------
Distribute_Gadgets:
	*-- Check for system gadgets
		Move.l	HitGd(pc),a4
		Cmp.b	#$f1,5(a4)
		Beq.w	Quit_Layer
		Cmp.b	#$f2,5(a4)
		Beq.w	Drag_Layer
		Cmp.b	#$f3,5(a4)
		Beq.w	Depth_Layer
		Cmp.b	#$f4,5(a4)
		Beq.w	Size_Layer
	*-- Check for layer common gadgets
		Cmp.b	#$e1,5(a4)
		Beq.w	Common_Select
	*-- Jump to routine, if any
		Tst.l	10(a4)
		Beq.b	DG_NRtn
		Move.l	10(a4),a0
		Jmp	(a0)
	DG_NRtn:Rts
*---------------
SrchAll:	;(Search for gadget hits)
		Move	(a4),d7
		Cmp	#'BX',d7
		Beq.b	Srch10
		Cmp	#'IM',d7
		Beq.b	Srch10
		Cmp	#'TX',d7
		Beq.b	Srch14
		Cmp	#'GD',d7
		Beq.b	SrchGD
		Cmp	#'RC',d7
		Beq.b	Srch10
		Cmp	#'FR',d7
		Beq.b	Srch10
		Cmp	#'JP',d7
 		Beq.b	SrchJP
		Cmp	#'RO',d7
 		Beq.b	Srch06
		Cmp	#'DF',d7
 		Beq.b	Srch10
		Cmp	#'JS',d7
 		Beq.b	SrchJS
		Cmp	#'RT',d7
 		Beq.b	SrchRT
		Clr.l	HitGd
		Rts
	SrchJP:	Move.l	2(a4),a4
		Bra.b	SrchAll
	SrchRT:	Move.l	RetAdr(pc),a4
		Bra.b	SrchAll
	SrchJS:	Addq	#6,a4
		Move.l	a4,RetAdr
		Move.l	-4(a4),a4
		Bra.b	SrchAll
	Srch14:	Addq	#4,a4
	Srch10:	Addq	#4,a4
	Srch06:	Addq	#6,a4
		Bra.b	SrchAll
	SrchGD:	Add	#14,a4
		Bsr.w	Calc_Coord
		Sub	#14,a4
		Move	X1(pc),d0
		Cmp	LayX(pc),d0
		Bgt.b	Srch14
		Move	Y1(pc),d0
		Cmp	LayY(pc),d0
		Bgt.b	Srch14
		Move	X2(pc),d0
		Cmp	LayX(pc),d0
		Blt.b	Srch14
		Move	Y2(pc),d0
		Cmp	LayY(pc),d0
		Blt.b	Srch14
		Move.l	a4,HitGd
		Rts
HitGd:		Dc.l	0
*---------------
Common_Select:	Lea	GSelc_Title(pc),a0
		Lea	UnitsDiskT(pc),a1
		Move.l	a1,(a0)
		Lea	Selc_UnitDL(pc),a0
		Move.l	a0,GSelc_Jump
		Move.l	HitGd(pc),a0
		Move.l	6(a0),d0
		Beq.b	CS_NUn
		Move.l	d0,Read_Unit
		Lea	PathName,a0	;###
		Move.l	d0,a3
		Move.l	20(a3),a1
	CS_PaLp:Move.b	(a1)+,(a0)+
		Bne.b	CS_PaLp
		Move.b	#':',-(a0)
		Clr.b	1(a0)
		Move.l	a3,-(a7)
		Bsr.w	Read_UnitList
		Move.l	(a7)+,a3
		Bsr.b	Upd_SelcUnit
	CS_NUn:	Lea	SelcLay(pc),a5
		Tst.l	(a5)
		Beq.b	CS_NOp
		Lea	DrawList_Selc(pc),a4
		Bsr.w	Draw_All
	CS_NOp:	Bra.w	Open_Layer
*---------------
Upd_SelcUnit:	Cmp.l	Read_Unit(pc),a3
		Bne.b	USU_Ed
		Move	(a3),d0		;Get Cur_Unit
		Move	d0,Unit_Selc
		Bsr.w	Get_Unit_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	USU_Non
		Lea	FileName,a0	;###
		Lea	8(a2),a1
	USU_UnL:Move.b	(a1)+,(a0)+
		Bne.b	USU_UnL
	USU_Non:Lea	SelcLay(pc),a5
		Lea	Selc_PathUpd(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some
	USU_Ed:	Rts
*---------------
Draw_Palette:	Move	Screen_Depth(pc),d4
	*-- Decide size of each color, depending on number of planes
		Move	d4,d0
		Subq	#1,d0
		Bne.b	DP_1Pl
		Moveq.l	#36,d1
		Moveq.l	#20,d2
	DP_1Pl:	Subq	#1,d0
		Bne.b	DP_2Pl
		Moveq.l	#18,d1
		Moveq.l	#20,d2
	DP_2Pl:	Subq	#1,d0
		Bne.b	DP_3Pl
		Moveq.l	#18,d1
		Moveq.l	#10,d2
	DP_3Pl:	Subq	#1,d0
		Bne.b	DP_4Pl
		Moveq.l	#09,d1
		Moveq.l	#10,d2
	DP_4Pl:	Subq	#1,d0
		Bne.b	DP_5Pl
		Moveq.l	#09,d1
		Moveq.l	#05,d2
	DP_5Pl:	Subq	#1,d0
		Bne.b	DP_6Pl
		Moveq.l	#04,d1
		Moveq.l	#05,d2
	DP_6Pl:	Subq	#1,d0
		Bne.b	DP_7Pl
		Moveq.l	#04,d1
		Moveq.l	#02,d2
	DP_7Pl:	Subq	#1,d0
		Bne.b	DP_8Pl
		Moveq.l	#02,d1
		Moveq.l	#02,d2
	DP_8Pl:	Move	d1,PalX
		Move	d2,PalY
		Lea	DrawLay(pc),a5
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	GfxBase(pc),a6
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Moveq.l	#55,d6		;X
		Moveq.l	#14,d7		;Y
		Clr	d5		;Color
	DP_Loop:Move.l	a3,a1
		Move	d5,d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	d6,d0
		Move	d7,d1
		Move	d6,d2
		Move	d7,d3
		Add	PalX(pc),d2
		Subq	#1,d2
		Add	PalY(pc),d3
		Subq	#1,d3
		Jsr	RectFill(a6)
		Add	PalX(pc),d6
		Cmp	#127,d6
		Blt.b	NotLine
		Add	PalY(pc),d7
		Moveq.l	#55,d6
	NotLine:Addq	#1,d5
		Moveq.l	#1,d0
		Lsl	d4,d0
		Cmp	d0,d5
		Bne.b	DP_Loop
		Rts
PalX:		Dc	0
PalY:		Dc	0
*---------------
Draw_PickColor:	Lea	Sprite_Cross(pc),a1
		Bsr.w	Change_Sprite
		Bsr.w	Check_Left_Dn
		Beq.b	Draw_PickColor
		Bra.b	Draw_SelectColor
*---------------
Upd_SelColor:	Lea	DrawLay(pc),a5
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	GfxBase(pc),a6
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	Left_Color(pc),d0
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Moveq.l	#42,d0
		Moveq.l	#14,d1
		Moveq.l	#48,d2
		Moveq.l	#33,d3
		Jmp	RectFill(a6)
*---------------
Draw_SelectColor:
		Move.l	GfxBase(pc),a6
		Move.l	Screen_Struct(pc),a0
		Move.l	a0,a1
		Add	#84,a1
		Move	18(a0),d0	;Get ScreenX
		Move	16(a0),d1	;Get ScreenY
		Jsr	ReadPixel(a6)
		Move	d0,Left_Color
		Bsr.b	Upd_SelColor
		Bsr.w	Check_Left_Up
		Beq.b	Draw_SelectColor
		Rts
Left_Color:	Dc	1
*---------------
Upd_UnitNameD:	;(A3=Unit_Info, A4=Xxxx_NameUpd)
		Clr.l	34(a4)
		Move	6(a3),d7	;UnitList_Len
		Beq.b	UUN_Ed
		Bsr.w	Get_Unit_LAdr
		Move	4(a2),d0	;Flags
		Btst	#0,d0
		Beq.b	UUN_Ed
		Addq	#8,a2
		Move.l	a2,34(a4)
	UUN_Ed:	Rts
*---------------
DrawList_Open:	Dc	'BX',000,000,-01,-01
		Dc	'TX',030,011,-01,8
		Dc.l	Windows8T

		Dc	'GD'
		Dc.l	$02010001,PictLay,0
		Dc	'BX',003,012,057,020
		Dc	'TX',006,019,-01,5
		Dc.l	PictureT
		
		Dc	'GD'
		Dc.l	$02010001,PiecLay,0
		Dc	'BX',003,021,057,029
		Dc	'TX',006,028,-01,5
		Dc.l	PieceT
		
		Dc	'GD'
		Dc.l	$02010001,BackLay,0
		Dc	'BX',003,030,057,038
		Dc	'TX',006,037,-01,5
		Dc.l	BackgroundT
		
		Dc	'GD'
		Dc.l	$02010001,AnimLay,0
		Dc	'BX',003,039,057,047
		Dc	'TX',006,046,-01,5
		Dc.l	AnimationT
		
		Dc	'GD'
		Dc.l	$02010001,MoveLay,0
		Dc	'BX',003,048,057,056
		Dc	'TX',006,055,-01,5
		Dc.l	MovementT
		
		Dc	'GD'
		Dc.l	$02010001,ScrnLay,0
		Dc	'BX',003,057,057,065
		Dc	'TX',006,064,-01,5
		Dc.l	ScreenT
		
		Dc	'GD'
		Dc.l	$02010001,FontLay,0
		Dc	'BX',003,066,057,074
		Dc	'TX',006,073,-01,5
		Dc.l	FontT
		
		Dc	'GD'
		Dc.l	$02010001,PaltLay,0
		Dc	'BX',003,075,057,083
		Dc	'TX',006,082,-01,5
		Dc.l	PaletteT
		
		Dc	'GD'
		Dc.l	$02010001,PlayLay,0
		Dc	'BX',003,084,057,092
		Dc	'TX',006,091,-01,5
		Dc.l	PlayerT
		


		
		Dc	'GD'
		Dc.l	$02010001,ObjcLay,0
		Dc	'BX',058,012,-04,020
		Dc	'TX',061,019,-01,5
		Dc.l	ObjectT
		
		Dc	'GD'
		Dc.l	$02010001,WeapLay,0
		Dc	'BX',058,021,-04,029
		Dc	'TX',061,028,-01,5
		Dc.l	WeaponT
		
		Dc	'GD'
		Dc.l	$02010001,LevlLay,0
		Dc	'BX',058,030,-04,038
		Dc	'TX',061,037,-01,5
		Dc.l	LevelT
		
		Dc	'GD'
		Dc.l	$02010001,WaveLay,0
		Dc	'BX',058,039,-04,047
		Dc	'TX',061,046,-01,5
		Dc.l	WaveT
		
		Dc	'GD'
		Dc.l	$02010001,GameLay,0
		Dc	'BX',058,048,-04,056
		Dc	'TX',061,055,-01,5
		Dc.l	GameT
		
		Dc	'GD'
		Dc.l	$02010001,SmplLay,0
		Dc	'BX',058,057,-04,065
		Dc	'TX',061,064,-01,5
		Dc.l	SampleT
		
		Dc	'GD'
		Dc.l	$02010001,SondLay,0
		Dc	'BX',058,066,-04,074
		Dc	'TX',061,073,-01,5
		Dc.l	SoundT
		
		Dc	'GD'
		Dc.l	$02010001,ModlLay,0
		Dc	'BX',058,075,-04,083
		Dc	'TX',061,082,-01,5
		Dc.l	ModuleT
		
		Dc	'GD'
		Dc.l	$02010001,SongLay,0
		Dc	'BX',058,084,-04,092
		Dc	'TX',061,091,-01,5
		Dc.l	SongT
		

		Dc	'XX'
*---------------
Save_Unit:	;(D0=Type (PIEC/ANIM/Etc), D4=Unit No, A4=UnitList Adr)
		Movem.l	d0/d4/a4,-(a7)
		Lea	Sprite_Disk(pc),a1
		Bsr.w	Change_Sprite
		Movem.l	(a7)+,d0/d4/a4
	*-- Write type
		Lea	Unit_FileType(pc),a0
		Move.l	d0,(a0)
		Lea	Unit_Header(pc),a0
		Move.l	d0,(a0)
	*-- Find Unit
		Move	d4,d0
		Ext.l	d4
		Lsl.l	#5,d4
		Add.l	d4,a4
		Tst.l	(a4)		;Any unit here?
		Beq.b	SU_End		;No
	*-- Write File
		Move	6(a4),Unit_PathNo
		Bsr.b	Write_Hex
		Bsr.b	Make_FileName
		Lea	Comm_FileName,a0	;###
		Bsr.w	Open_New_File
		Beq.w	Mess_FileErr

		Lea	Unit_Header(pc),a0
		Moveq.l	#8,d0
		Bsr.w	Write_File

		Move.l	(a4),a0		;Get Unit Address
		Clr.l	d0		;Get Unit Size
		Move.l	02(a0),d0	;+
		Bsr.w	Write_File

		Bsr.w	Close_File

		;Lea	Unit_FileName(pc),a0
		;Move.l	a0,d1
		;Lea	8(a4),a0
		;Move.l	a0,d2
		;Jsr	SetComment(a6)

		And	#~%110,4(a4)	;Clear NeedsPath+NeedsUpdate
	SU_End:	Rts
Unit_PathNo:	Dc	0
Unit_Header:	Dc.b	'PIECAFDF'
Unit_FileType:	Dc.b	'PIEC.'
Unit_FileNo:	Dc.b	'0000.AFDF',0
		Even
*---------------
Make_FileName:	Move.l	Mem_PathList(pc),a0
		Move	Unit_PathNo(pc),d0
		Lsl	#7,d0
		Add	d0,a0
		Lea	Comm_FileName,a1	;###
	MFN_Lp1:Move.b	(a0)+,(a1)+
		Bne.b	MFN_Lp1
		Subq	#1,a1
		Lea	Unit_FileType(pc),a0
	MFN_Lp2:Move.b	(a0)+,(a1)+
		Bne.b	MFN_Lp2
		Rts
*---------------
Write_Hex:	;(Write Hex Number in filename. D0=Number)
		Lea	Unit_FileNo+4(pc),a0
		Moveq.l	#3,d7
	SU_NL:	Move	d0,d1
		And	#$f,d1
		Cmp	#10,d1
		Blt.b	SU_09
		Addq.b	#7,d1
	SU_09:	Add.b	#'0',d1
		Move.b	d1,-(a0)
		Lsr	#4,d0
		Dbf	d7,SU_NL
		Rts
*---------------
Load_Unit:	;(D0=Type (PIEC/ANIM/Etc), D4=Unit No, A4=UnitList Adr)
		Movem.l	d0/d4/a4,-(a7)
		Lea	Sprite_Disk(pc),a1
		Bsr.w	Change_Sprite
		Movem.l	(a7)+,d0/d4/a4
	*-- Write type
		Lea	Unit_FileType(pc),a0
		Move.l	d0,(a0)
	*-- Find UnitList Address
		Move	d4,d0
		Ext.l	d4
		Lsl.l	#5,d4
		Add.l	d4,a4
		Move.l	a4,Unit_ListAdr
		Tst.l	(a4)		;Any unit here?
		Bne.w	LU_End		;Yes
	*-- Open file, and read header
		Move	6(a4),Unit_PathNo
		Bsr.b	Write_Hex
		Bsr.b	Make_FileName
		Lea	Comm_FileName,a0	;###
		Bsr.w	Open_Old_File
		Beq.w	Mess_FileErr

		Lea	Unit_Buf(pc),a0
		Moveq.l	#8,d0
		Bsr.w	Read_File
	*-- Choose memory type
		Moveq.l	#$0,d6
		Cmp.l	#'PIEC',Unit_Buf
		Bne.b	LU_NPc
		Moveq.l	#$2,d6
	LU_NPc:	
		Cmp.l	#'SMPL',Unit_Buf
		Bne.b	LU_NSm
		Moveq.l	#$2,d6
	LU_NSm:	
		Cmp.l	#'MODL',Unit_Buf
		Bne.b	LU_NMd
		Moveq.l	#$2,d6
	LU_NMd:	
		Lea	Unit_Buf(pc),a0
		Moveq.l	#8,d0
		Bsr.w	Read_File
	*-- Allocate memory
		Clr.l	d0
		Move.l	Unit_Buf+2(pc),d0
		Move.l	d6,d1		;Memory type
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Tst.l	d0
		Beq.w	Mess_CMemErr

		Move.l	Unit_ListAdr(pc),a0
		Move.l	d0,(a0)
		And	#~110,04(a0)	;Clear NeedsPath+NeedsUpdate
	*-- Load Unit data
		Move.l	(a0),a0		;Get Unit Address
		Lea	Unit_Buf(pc),a1
		Move.l	(a1)+,(a0)+
		Move.l	(a1)+,(a0)+

		Clr.l	d0
		Move.l	Unit_Buf+2(pc),d0
		Subq.l	#8,d0
		Bsr.w	Read_File

		Bsr.w	Close_File
	LU_End:	Rts
Unit_Buf:	Blk.b	8
Unit_ListAdr:	Dc.l	0
*---------------
Unit_BrowseUp:	Move.l	HitGd(pc),a0
		Move.l	6(a0),a3
Unit_BrUp:	Move	(a3),d7		;Get current Unit
	UBU_Try:Subq	#1,d7
		Bmi.b	UBU_End
	*-- Check if Unit exists
		Move.l	2(a3),a2	;Get address of UnitList memory
		Move.l	(a2),a2
		Clr.l	d0
		Move	d7,d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	UBU_Try
		Move	d7,(a3)		;Save current Unit
		Move.l	8(a3),a0	;Address of unit update routine
		Jsr	(a0)
	UBU_End:Rts
*---------------
Unit_BrowseDn:	Move.l	HitGd(pc),a0
		Move.l	6(a0),a3
Unit_BrDn:	Move	(a3),d7		;Get current Unit
	UBD_Try:Addq	#1,d7
		Move	6(a3),d0	;Get length of UnitList
		Cmp	d7,d0
		Ble.b	UBD_End
	*-- Check if Unit exists
		Move.l	2(a3),a2	;Get address of UnitList memory
		Move.l	(a2),a2
		Clr.l	d0
		Move	d7,d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	UBD_Try
		Move	d7,(a3)		;Save current Unit
		Move.l	8(a3),a0	;Address of unit update routine
		Jsr	(a0)
	UBD_End:Rts
*---------------
Unit_Info:

Piec_Info:	;(PIEC = 0)
Cur_Piec:	Dc	0
PiecList:	Dc.l	Mem_PiecList
PiecList_Len:	Dc	0
		Dc.l	Change_Piec
		Dc.l	Mem_PiecBuf
		Dc.l	'PIEC'
		Dc.l	PieceT

Back_Info:	;(BACK = 1)
Cur_Back:	Dc	0
BackList:	Dc.l	Mem_BackList
BackList_Len:	Dc	0
		Dc.l	Change_Back
		Dc.l	Mem_BackBuf
		Dc.l	'BACK'
		Dc.l	BackgroundT

Anim_Info:	;(ANIM = 2)
Cur_Anim:	Dc	0
AnimList:	Dc.l	Mem_AnimList
AnimList_Len:	Dc	0
		Dc.l	Change_Anim
		Dc.l	Mem_AnimBuf
		Dc.l	'ANIM'
		Dc.l	AnimationT

Move_Info:	;(MOVE = 3)
Cur_Move:	Dc	0
MoveList:	Dc.l	Mem_MoveList
MoveList_Len:	Dc	0
		Dc.l	Change_Move
		Dc.l	Mem_MoveBuf
		Dc.l	'MOVE'
		Dc.l	MovementT

Objc_Info:	;(OBJC = 4)
Cur_Objc:	Dc	0
ObjcList:	Dc.l	Mem_ObjcList
ObjcList_Len:	Dc	0
		Dc.l	Change_Objc
		Dc.l	Mem_ObjcBuf
		Dc.l	'OBJC'
		Dc.l	ObjectT

Levl_Info:	;(LEVL = 5)
Cur_Levl:	Dc	0
LevlList:	Dc.l	Mem_LevlList
LevlList_Len:	Dc	0
		Dc.l	Change_Levl
		Dc.l	Mem_LevlBuf
		Dc.l	'LEVL'
		Dc.l	LevelT

Wave_Info:	;(WAVE = 6)
Cur_Wave:	Dc	0
WaveList:	Dc.l	Mem_WaveList
WaveList_Len:	Dc	0
		Dc.l	Change_Wave
		Dc.l	Mem_WaveBuf
		Dc.l	'WAVE'
		Dc.l	WaveT

Palt_Info:	;(PALT = 7)
Cur_Palt:	Dc	0
PaltList:	Dc.l	Mem_PaltList
PaltList_Len:	Dc	0
		Dc.l	Change_Palt
		Dc.l	Mem_PaltBuf
		Dc.l	'PALT'
		Dc.l	PaletteT

Font_Info:	;(FONT = 8)
Cur_Font:	Dc	0
FontList:	Dc.l	Mem_FontList
FontList_Len:	Dc	0
		Dc.l	Change_Font
		Dc.l	0
		Dc.l	'FONT'
		Dc.l	FontT

Scrn_Info:	;(SCRN = 9)
Cur_Scrn:	Dc	0
ScrnList:	Dc.l	Mem_ScrnList
ScrnList_Len:	Dc	0
		Dc.l	Change_Scrn
		Dc.l	Mem_ScrnBuf
		Dc.l	'SCRN'
		Dc.l	ScreenT

Weap_Info:	;(WEAP = 10)
Cur_Weap:	Dc	0
WeapList:	Dc.l	Mem_WeapList
WeapList_Len:	Dc	0
		Dc.l	Change_Weap
		Dc.l	Mem_WeapBuf
		Dc.l	'WEAP'
		Dc.l	WeaponT

Sond_Info:	;(SOND = 11)
Cur_Sond:	Dc	0
SondList:	Dc.l	Mem_SondList
SondList_Len:	Dc	0
		Dc.l	Change_Sond
		Dc.l	0
		Dc.l	'SOND'
		Dc.l	SoundT

Smpl_Info:	;(SMPL = 12)
Cur_Smpl:	Dc	0
SmplList:	Dc.l	Mem_SmplList
SmplList_Len:	Dc	0
		Dc.l	Change_Smpl
		Dc.l	0
		Dc.l	'SMPL'
		Dc.l	SampleT

Song_Info:	;(SONG = 13)
Cur_Song:	Dc	0
SongList:	Dc.l	Mem_SongList
SongList_Len:	Dc	0
		Dc.l	Change_Song
		Dc.l	0
		Dc.l	'SONG'
		Dc.l	SongT

Modl_Info:	;(MODL = 14)
Cur_Modl:	Dc	0
ModlList:	Dc.l	Mem_ModlList
ModlList_Len:	Dc	0
		Dc.l	Change_Modl
		Dc.l	0
		Dc.l	'MODL'
		Dc.l	ModuleT

Play_Info:	;(PLAY = 15)
Cur_Play:	Dc	0
PlayList:	Dc.l	Mem_PlayList
PlayList_Len:	Dc	0
		Dc.l	Change_Play
		Dc.l	Mem_PlayBuf
		Dc.l	'PLAY'
		Dc.l	PlayerT

Xxxx_Info:	;(XXXX = 14)
		Dc	-1

Item_Size:	Dc	2+4+2+4+4+4+4
*---------------
Unit_New:	;(A2=NewUnitData, A4=XxxxList, D7->Number)
	*-- Get list space.
		Bsr.w	Find_Unit_Space		;This routine saves regs.
		Move.l	a0,UN_LstA
		Beq.w	Mess_MemErr
	*-- Allocate memory.
		Move.l	2(a2),d0		;ByteSize
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Tst.l	d0
		Beq.w	Mess_MemErr
	*-- Write to list.
		Move.l	UN_LstA(pc),a0
		Move.l	d0,(a0)
		Move	#%111,4(a0)		;Set Flags = New
		Move	#1,6(a0)		;Clear Path	$$$
		Bsr.w	Unnamed
	*-- Store new Unit.
		Move.l	(a0),a1			;Get Anim Address
		Move.l	2(a2),d0
	UN_Lop:	Move.b	(a2)+,(a1)+
		Subq	#1,d0
		Bne.b	UN_Lop
		Rts
	UN_LstA:Dc.l	0
*---------------
DrawList_Mess:	Dc	'GD'
		Dc.l	$020000f2,0,0
		Dc	'DF',000,000,-18,-01
		Dc	'BX',000,000,-01,-01
		Dc	'GD'
		Dc.l	$020100f1,0,0
		Dc	'BX',-17,002,-03,-03
		Dc	'TX',-14,009,-01,5
		Dc.l	OkT
		Dc	'GD'
		Dc.l	$01ff0100,0,0
		Dc	'TX',003,011,-01,8
Mess_Ptr:	Dc.l	0
		Dc	'XX'
OutOfCMemT:	Dc.b	"Out of chip memory!   ",0
OutOfMemT:	Dc.b	"Out of memory!        ",0
NotIffT:	Dc.b	"Can't understand file!",0
NoFileT:	Dc.b	"File or path invalid! ",0
		Even
*---------------
Xxxx_Update:	Move.l	HitGd(pc),a3
		Move.l	6(a3),a3
Update_Common:	Move.l	a3,Requ_UnitInfo
		Move	(a3),Requ_UnitNo

		Bsr.w	Get_Unit_LAdr
		Tst.l	(a2)
		Beq.b	XU_End
		Lea	8(a2),a0
		Move.l	a0,GRequ_Name
		Move.l	20(a3),GRequ_Path

		Lea	Update8T,a0	;###
		Move.l	a0,GRequ_Title
		Lea	UpdateT,a0	;###
		Move.l	a0,GRequ_Confirm
		Lea	Requ_Update(pc),a0
		Move.l	a0,GRequ_Routine

		Lea	RequLay(pc),a5		;Open Layer
		Tst.l	(a5)
		Beq.b	XU_NOp
		Lea	DrawList_Requ(pc),a4
		Bsr.w	Draw_All
	XU_NOp:	Bsr.w	Open_Layer
	XU_End:	Rts
*---------------
Selc_Remove:	Move.l	Read_Unit(pc),a3
		Move.l	a3,Requ_UnitInfo
		Move	(a3),Requ_UnitNo

		Bsr.w	Get_Unit_LAdr
		Tst.l	(a2)
		Beq.b	SR_End
		Lea	8(a2),a0
		Move.l	a0,GRequ_Name
		Move.l	20(a3),GRequ_Path

		Lea	Remove8T,a0	;###
		Move.l	a0,GRequ_Title
		Lea	RemoveT,a0	;###
		Move.l	a0,GRequ_Confirm
		Lea	Requ_Remove(pc),a0
		Move.l	a0,GRequ_Routine

		Lea	RequLay(pc),a5		;Open Layer
		Tst.l	(a5)
		Beq.b	SR_NOp
		Lea	DrawList_Requ(pc),a4
		Bsr.w	Draw_All
	SR_NOp:	Bsr.w	Open_Layer
	SR_End:	Rts
*---------------
Selc_Delete:	Move.l	Read_Unit(pc),d0
		Bne.b	Selc_DelUnit
		Bra.b	Selc_DelFile
*---------------
Selc_DelUnit:	Move.l	Read_Unit(pc),a3
		Move.l	a3,Requ_UnitInfo
		Move	(a3),Requ_UnitNo

		Bsr.w	Get_Unit_LAdr
		Move	4(a2),d0
		Btst.l	#0,d0
		Beq.w	SD_End
		Lea	8(a2),a0
		Move.l	a0,GRequ_Name
		Move.l	20(a3),GRequ_Path

		Lea	Requ_DelUnit(pc),a0
		Move.l	a0,GRequ_Routine
		Bra.b	Selc_DelCommon

Conv_Name:	Moveq.l	#30,d7
	CN_Lp:	Move.b	(a0)+,d0
		Cmp.b	#'a',d0
		Blt.b	CN_Up
		Sub.b	#32,d0
	CN_Up:	Move.b	d0,(a1)+
		Dbf	d7,CN_Lp
		Clr.b	(a1)+
		Rts

Selc_DelFile:	Lea	PathName,a0	;###
		Lea	Requ_Path(pc),a1
		Bsr.b	Conv_Name

		Lea	FileName,a0	;###
		Lea	Requ_Name(pc),a1
		Bsr.b	Conv_Name

		Lea	Requ_Name(pc),a0
		Move.l	a0,GRequ_Name
		Lea	Requ_Path(pc),a0
		Move.l	a0,GRequ_Path
		Lea	Requ_DelFile(pc),a0
		Move.l	a0,GRequ_Routine

Selc_DelCommon:	Lea	Delete8T,a0	;###
		Move.l	a0,GRequ_Title
		Lea	DeleteT,a0	;###
		Move.l	a0,GRequ_Confirm

		Lea	RequLay(pc),a5		;Open Layer
		Tst.l	(a5)
		Beq.b	SD_NOp
		Lea	DrawList_Requ(pc),a4
		Bsr.w	Draw_All
	SD_NOp:	Bsr.w	Open_Layer
	SD_End:	Rts
Requ_Path:	Blk.b	32,0
Requ_Name:	Blk.b	32,0
*---------------
Requ_DelUnit:	Lea	RequLay(pc),a5		;Close Layer
		Bsr.w	Close_Layer		;+
		Move.l	Requ_UnitInfo(pc),a0
		Move.l	16(a0),d0	;'XXXX'
		Move.l	2(a0),a4
		Move.l	(a4),a4
		Move	Requ_UnitNo(pc),d4
		Bsr.b	Delete_Unit
		Bsr.w	Read_UnitList
		Move.l	Requ_UnitInfo(pc),a3
		Bsr.w	Unit_BrDn
		Move.l	Requ_UnitInfo(pc),a3
		Bra.w	Unit_BrUp
*---------------
Delete_Unit:	;(D0=Type (PIEC/ANIM/Etc), D4=Unit No, A4=UnitList Adr)
		Movem.l	d0/d4/a4,-(a7)
		Lea	Sprite_Disk(pc),a1
		Bsr.w	Change_Sprite
		Movem.l	(a7)+,d0/d4/a4
	*-- Write type
		Lea	Unit_FileType(pc),a0
		Move.l	d0,(a0)
	*-- Find UnitList Address
		Move	d4,d0
		Ext.l	d4
		Lsl.l	#5,d4
		Add.l	d4,a4
	*-- Delete it!
		Bsr.w	Write_Hex
		Move	6(a4),Unit_PathNo
		Bsr.w	Make_FileName
		Bsr.w	Free_Unit
		Clr.l	4(a4)		;Clear all flags and path
		Lea	Comm_FileName,a0	;###
		Bra.w	Delete_File
*---------------
Requ_DelFile:	Lea	RequLay(pc),a5
		Bsr.w	Close_Layer
		Bsr.w	Join_FileName
		Lea	Comm_FileName,a0	;###
		Bsr.w	Delete_File
		Bra.w	Directory
*---------------
Requ_Update:	Lea	RequLay(pc),a5		;Close Layer
		Bsr.w	Close_Layer		;+
		Move.l	Requ_UnitInfo(pc),a3	;Get UnitInfo
		Move.l	2(a3),a4		;Get Address of Unit
		Move.l	(a4),a4			;+
		Move	Requ_UnitNo(pc),d4	;Get Cur_Unit
		Move.l	16(a3),d0		;Get 'UNIT'
		Bra.w	Save_Unit
Requ_UnitInfo:	Dc.l	0
Requ_UnitNo:	Dc	0
*---------------
Requ_Remove:	Lea	RequLay(pc),a5		;Close Layer
		Bsr.w	Close_Layer		;+

		Move.l	Requ_UnitInfo(pc),a0
		Move	Requ_UnitNo(pc),d0
		Move.l	2(a0),a4
		Move.l	(a4),a4
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a4
		Bsr.w	Free_Unit

		Move.l	Requ_UnitInfo(pc),a0
		Move	Requ_UnitNo(pc),(a0)
		Move.l	8(a0),a0
		Jmp	(a0)
*---------------
DrawList_Requ:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
GRequ_Title:	Dc.l	0

		Dc	'BX',000,011,-1,-1
		Dc	'TX',003,019,-01,5
GRequ_Path:	Dc.l	0
		Dc	'TX',003,026,-01,5
GRequ_Name:	Dc.l	0

		Dc	'GD'
		Dc.l	$02010000,0
GRequ_Routine:	Dc.l	0
		Dc	'BX',003,-11,059,-03
		Dc	'TX',017,-04,-01,5
GRequ_Confirm:	Dc.l	0

		Dc	'GD'
		Dc.l	$020100f1,0,0
		Dc	'BX',062,-11,-04,-03
		Dc	'TX',076,-04,-01,5
		Dc.l	CancelT
		Dc	'XX'
*=======================================================================*
*			    M O V E M E N T				*
*=======================================================================*
Move_New:	Lea	MoveList(pc),a4
		Lea	New_Move(pc),a2
		Bsr.w	Unit_New
		Move	d7,Cur_Move
		Bra.w	Change_Move
New_Move:	Dc	0	;Id	00
		Dc.l	8	;Size	02
		Dc	0	;Parts	06
*---------------
Prep_Object_Move:	;(A5=ObjectListAdr, A0=MoveAdr)
		Clr.l	GM_XInt
		Clr.l	GM_YInt
		Clr	GM_DeltaX
		Clr	GM_DeltaY
		Clr.l	GM_DDXInt
		Clr.l	GM_DDYInt
		Clr.l	GM_VblCnt


		Move.l	08(a5),48(a5)	;Set new start X point.
		Move.l	12(a5),52(a5)	;Set new start Y point.
		Move.l	a0,20(a5)	;MovementPtr
		Bset	#5,1(a5)	;Set Movement bit.
		Lea	64-16(a5),a4
		Clr	d7
	*-- Initialize Movement Parts
	POM_Nxt:Add	#16,a4		;Next ObjectList MovementPart
		Move	d7,d0
		Cmp	6(a0),d7	;Any more Parts?
		Beq.b	POM_Fin		;+ No
		Add	d0,d0
		Move	08(a0,d0.w),d0
		Lea	00(a0,d0.w),a3
		Move	(a3),d2
		Cmp	#1,d2
		Beq.b	POM_Fre
		Cmp	#2,d2
		Beq.b	POM_Sin
		Cmp	#3,d2
		Beq.b	POM_Lin
		Addq	#1,d7		;Count Parts
		Bra.b	POM_Nxt

	POM_Fre:Clr	(a4)		;Clear coordinate counter
		Addq	#1,d7		;Count Parts
		Bra.b	POM_Nxt

	POM_Sin:Move	8(a3),(a4)	;Copy start angle
		Addq	#1,d7		;Count Parts
		Bra.b	POM_Nxt

	POM_Lin:Clr.l	(a4)		;Clear X counter
		Clr.l	4(a4)		;Clear Y counter
		Addq	#1,d7		;Count Parts
		Bra.b	POM_Nxt
	POM_Fin:Rts
*---------------
Move_PlayScreen:Move	#'MO',Play_Mode
		Jsr	Get_Screen_Mem	;###
		Jsr	Get_Bob_Mem	;###
	*-- Fill in test object
		Bsr.w	Find_Object_Vacancy
		Move	#$8000,(a5)

		Bsr.w	Get_Move_LAdr
		Tst.l	(a2)
		Beq.b	MPS_NMv
		Move.l	(a2),a0
		Bsr.w	Prep_Object_Move
	MPS_NMv:
		Bsr.w	Get_Anim_LAdr
		Tst.l	(a2)
		Beq.b	MPS_NAn
		Move.l	(a2),a0
		Bsr.w	Prep_Object_Anim
		Move	#32767,40(a5)

	MPS_NAn:Clr	GM_OutCnt

		Jsr	Erase
		Jsr	Leave_Dos	;###
		Jsr	Chip		;Feed Custom Chips ###
		Jsr	Game_Palette	;###

	MPS_M1:	Jsr	Game_Background	;###
		Btst	#6,$bfe001
		Bne.b	MPS_M1

	MPS_M3:	Moveq.l	#127,d0
	MPS_M2:	Btst	#6,$bfe001
		Beq.b	MPS_M3
		Dbf	d0,MPS_M2

		Jsr	Enter_Dos	;###
		Jsr	Free_Play_Mem	;###
	MPS_End:Rts
*---------------
Move_Name:	Move	#1,Game_NeedUpd
		Bsr.w	Upd_MoveNameD
		Bra.w	Upd_MoveNameG
*---------------
Move_AddPart:
	*-- Find current Movement, and check if it exists
		Bsr.w	Get_Move_LAdr
		Tst.l	(a2)
		Beq.w	MAP_End
		Move.l	a2,MAP_ListAdr
		Move.l	(a2),a0
		Bsr.w	Update_MoveBuf
	*-- Free old Movement
		Move.l	MAP_ListAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Find Part Length
		Lea	Move_NewParts(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2
		Move	2(a2),d0
		Addq	#2,d0			;Plus 2 for EventOffset
		Move	d0,MAP_BytesAdd
	*-- Allocate space for new Movement
		Move.l	Mem_MoveBuf(pc),a2	;Get buffer address
		Clr.l	d0
		Move.l	2(a2),d0
		Add	MAP_BytesAdd(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	MAP_ListAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_MemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Move address
		Move.l	Mem_MoveBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	MAP_BytesAdd(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Move	d7,Cur_Part		;New Part = Current Part
		Addq	#1,d7			;+
		Move	d7,(a1)+		;+
	*-- Copy PartOffsets
		Move	d7,d0
		Moveq.l	#10,d2

	MAP_LFO:Subq	#1,d0
		Tst	d0
		Beq.b	MAP_LIO
		Move	(a2)+,d2
		Addq	#2,d2
		Move	d2,(a1)+
		Bra.b	MAP_LFO

	MAP_LIO:Cmp	#1,d7
		Beq.b	MAP_One
	*-- Find Part (A5->Address)
		Move.l	Mem_MoveBuf(pc),a4
		Move	d7,d0
		Subq	#2,d0
		Add	d0,d0
		Move	08(a4,d0.w),d0
		Lea	00(a4,d0.w),a5

		Add	2(a5),d2
	MAP_One:Move	d2,(a1)+
	*-- Copy from start to end
		Moveq.l	#1,d6
	MAP_C2L:Cmp	d7,d6
		Beq.b	MAP_C2E
		
		Move	(a2)+,(a1)+		;Type
		Move	(a2)+,d0		;Size
		Move	d0,(a1)+		;+

		Subq	#4,d0

	MAP_C1L:Tst	d0
		Beq.b	MAP_C1E
		Move.b	(a2)+,(a1)+
		Subq	#1,d0			;Count number of bytes
		Bra.b	MAP_C1L			;Loop

	MAP_C1E:Addq	#1,d6			;Count Parts
		Bra.b	MAP_C2L			;Loop
	MAP_C2E:
	*-- Add Part.
		Lea	Move_NewParts(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2

		Clr	d2
	MAP_LpN:Move.b	(a2,d2.w),(a1)+
		Addq	#1,d2
		Cmp	2(a2),d2
		Bne.b	MAP_LpN

		Bsr.w	Upd_PartBut
		Bsr.w	Buffer_Freehand
		Bsr.w	Draw_Path
	MAP_End:Rts
MAP_ListAdr:	Dc.l	0
MAP_BytesAdd:	Dc	0

Move_NewParts:	Dc.l	Move_FrePart
		Dc.l	Move_SinPart
		Dc.l	Move_LinPart
		Dc.l	Move_ConPart
		Dc.l	Move_PosPart

Move_FrePart:	Dc	1,14		;Type,Size
		Dc.b	1		;Control	04
		Dc.b	-1		;FreeFlags	05
		Dc	1		;RecDelay	06
		Dc	0		;Smooth		08
		Dc	1		;PlaySpeed	10
		Dc	0		;Amount		12
Move_SinPart:	Dc	2,12		;Type,Size
		Dc	100		;SinWidth	04
		Dc	1024		;SinRate	06
		Dc	0		;SinStart	08
		Dc	0		;SinAngle	10
Move_LinPart:	Dc	3,12		;Type,Size
		Dc.l	-$20000		;SpeedX		04
		Dc.l	0		;SpeedY		08
Move_ConPart:	Dc	4,6		;Type,Size
		Dc	0		;---		04
Move_PosPart:	Dc	5,6		;Type,Size
		Dc	0		;---		04
*---------------
Move_DelPart:	Move	Cur_Part(pc),MDP_DelPart
		Bmi.w	MDP_End		;No Part Selected
	*-- Find current Movement, and check if it exists
		Bsr.w	Get_Move_LAdr
		Tst.l	(a2)
		Beq.w	MDP_End
		Move.l	a2,MDP_ListAdr
		Move.l	(a2),a0
		Tst	6(a0)
		Beq.w	MDP_End
		Bsr.w	Update_MoveBuf
	*-- Free old Movement
		Move.l	MDP_ListAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Find Part (A5->Address)
		Move.l	Mem_MoveBuf(pc),a4
		Move	MDP_DelPart(pc),d0
		Add	d0,d0
		Move	08(a4,d0.w),d0
		Lea	00(a4,d0.w),a5
		Move	2(a5),d0
		Addq	#2,d0
		Move	d0,MDP_BytesSub
	*-- Allocate space for new Movement
		Move.l	Mem_MoveBuf(pc),a2	;Get buffer address
		Clr.l	d0
		Move.l	2(a2),d0
		Sub	MDP_BytesSub(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	MDP_ListAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_MemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Move address
		Move.l	Mem_MoveBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub	MDP_BytesSub(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Subq	#1,d7			;+
		Move	d7,(a1)+		;+
	*-- Copy FrameOffsets
		Tst	d7
		Beq.b	MDP_FnP
		Clr	d0
		Moveq.l	#2,d3

	MDP_LFO:Cmp	MDP_DelPart(pc),d0	;Is part to delete?
		Beq.b	MDP_Skp

		Cmp	d7,d0
		Bgt.b	MDP_FnO

		Move	(a2)+,d2
		Sub	d3,d2
		Move	d2,(a1)+
		Bra.b	MDP_Nxt

	MDP_Skp:Addq.l	#2,a2
		Move	MDP_BytesSub(pc),d3

	MDP_Nxt:Addq	#1,d0
		Bra.b	MDP_LFO
	*-- Copy from start to end
	MDP_FnO:Clr	d6
	MDP_C2L:Cmp	d7,d6
		Bgt.b	MDP_FnP

		Cmp	MDP_DelPart(pc),d6
		Beq.b	MDP_Sk2

		Move	(a2)+,d1		;Type
		Move	(a2)+,d0		;Size
		Move	d1,(a1)+		;Type
		Move	d0,(a1)+		;Size

		Subq	#4,d0

	MDP_C1L:Tst	d0
		Beq.b	MDP_C1E
		Move.b	(a2)+,(a1)+
		Subq	#1,d0			;Count number of bytes
		Bra.b	MDP_C1L			;Loop

	MDP_Sk2:Move	2(a2),d0
		Add	d0,a2

	MDP_C1E:Addq	#1,d6			;Count Parts
		Bra.b	MDP_C2L

	MDP_FnP:Move	#-1,Cur_Part
		Bsr.w	Upd_PartBut
	MDP_End:Rts
MDP_ListAdr:	Dc.l	0
MDP_BytesSub:	Dc	0
MDP_DelPart:	Dc	0
*---------------
Move_SelPart:	Move.l	HitGd(pc),a0
		Btst	#0,4(a0)
		Beq.b	MSP_UnS
		Move.l	HitGd(pc),d0
		Lea	GMove_Part1(pc),a0
		Sub.l	a0,d0
		Divu	#34,d0
		Move	d0,Cur_Part
		Bsr.w	Buffer_Freehand
		Bsr.w	Draw_Path
		Bra.w	Upd_DataArea
	MSP_UnS:Move	#-1,Cur_Part
		Bsr.w	Draw_Path
		Bra.w	Upd_DataArea
Cur_Part:	Dc	-1
*---------------
MFre_Clear:	Clr	FreeHandLen
		Bsr.w	Insert_Freehand
		Bra.w	Draw_Path
*---------------
Move_Sum:	Lea	GMove_Sum(pc),a0
		Moveq.l	#6,d1
		Btst	#0,4(a0)
		Beq.b	MS_Off
		Moveq.l	#3,d1
	MS_Off:	Lea	GMove_Part1(pc),a0
		Moveq.l	#9,d7
	MS_Loop:Move.b	d1,4(a0)
		Add	#34,a0
		Dbf	d7,MS_Loop

		Bsr.w	Draw_Path
		Lea	GMove_Part1(pc),a4
		Lea	MPrtLay(pc),a5
		Bra.w	Draw_All
*---------------
Update_MoveBuf:	Lea	Move_Info(pc),a3
		Bra.w	Update_UnitBuf
*---------------
Upd_PartBut:	Bsr.w	Get_Move_LAdr
		Tst.l	(a2)
		Beq.b	UPB_Non
		Move.l	(a2),a0

		Move	6(a0),d0	;Get number of Parts
		Lea	GMove_Part1(pc),a3
		Clr	d1		;Clear space counter

	UPB_Lp:	Move	#'XX',(a3)	;Clear button
		Tst	d0		;Any more parts?
		Beq.b	UPB_End		;No

		Move	#'GD',(a3)	;Enable button
	*-- Select Image depending on Part type
		Move.l	a0,a4		;Find Part (A5->Address)
		Move	d1,d4
		Add	d4,d4
		Move	08(a4,d4.w),d4
		Lea	00(a4,d4.w),a5

		Move	(a5),d2		;Get Part type
		Lea	Part_Images(pc),a1
		Add	d2,d2
		Move	-2(a1,d2.w),32(a3)
	*-- Decide whether to press the button or not
		Bclr	#0,4(a3)
		Cmp	Cur_Part(pc),d1
		Bne.b	UPB_NPr
		Bset	#0,4(a3)

	UPB_NPr:Add	#34,a3		;Next button
		Subq	#1,d0		;Next Part
		Addq	#1,d1		;Any more space?
		Cmp	#10,d1		;+
		Ble.b	UPB_Lp		;No
	UPB_End:Bsr.b	Upd_DataArea
	UPB_Non:Rts

Part_Images:	Dc	Im_FreeHand-Im
		Dc	Im_Sine-Im
		Dc	Im_Line-Im
		Dc	Im_Position-Im
		Dc	Im_Joystick-Im
*---------------
Upd_DataArea:	Bsr.b	Get_Move_LAdr
	*-- Find Part (A5->Address)
		Move.l	(a2),a4
		Clr	d2	;Clear Part Type incase none selected
		Move	Cur_Part(pc),d0
		Bmi.b	UDA_NCr
		Add	d0,d0
		Move	08(a4,d0.w),d0
		Lea	00(a4,d0.w),a5
		Move	(a5),d2
	*-- Select DrawList depending on Part type
	UDA_NCr:Lea	Part_DrawL(pc),a1
		Lsl	#2,d2
		Move.l	00(a1,d2.w),a4
		Move.l	a4,GMove_DataJmp+2

		Lea	GMove_DataJmp(pc),a4
		Lea	MPrtLay(pc),a5
		Bsr.w	Draw_All
	UDA_End:Rts

Part_DrawL:	Dc.l	DrawList_MNul
		Dc.l	DrawList_MFre
		Dc.l	DrawList_MSin
		Dc.l	DrawList_MLin
		Dc.l	DrawList_MPos
		Dc.l	DrawList_MCon
*---------------
Get_Move_LAdr:	Move.l	Mem_MoveList(pc),a2
		Clr.l	d0
		Move	Cur_Move(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Change_Move:	Bsr.w	Check_Move
		Lea	MoveLay(pc),a5	;Layer Open?
		Tst.l	(a5)
		Beq.b	CM_Ed

		Move	#-1,Cur_Part
	*-- Find current Movement, and check if it exists
		Bsr.b	Get_Move_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	CM_Ed
	*-- Update Movement on screen
		Bsr.w	Upd_MoveNameD
		Bsr.w	Upd_MoveNameG
		Bsr.w	Upd_PartBut

		Lea	GMove_Move(pc),a4
		Lea	MoveLay(pc),a5
		Moveq.l	#1,d7
		Bsr.w	Draw_Some

		Bsr.w	Draw_Path
		Lea	Move_Info(pc),a3
		Bsr.w	Upd_SelcUnit
	CM_Ed:	Rts
*---------------
PlotPixel:	;( D2=X , D3=Y )
		Move.l	GfxBase(pc),a6
		Move.l	MoveLay(pc),a3
		Move.l	12(a3),a3

		Move.l	a3,a1
		Move	LoCol(pc),d0
		Jsr	SetAPen(a6)

		Move.l	a3,a1
		Move	d2,d0
		Move	d3,d1
		Add	DP_CX(pc),d0
		Add	DP_CY(pc),d1
		;Jmp	Draw(a6)
		Jmp	WritePixel(a6)
*---------------
PlotPoint:	;(D2=X, D3=Y, D7=HighLight)
		Clr	d7
		Add	DP_CX(pc),d2
		Add	DP_CY(pc),d3
		Subq	#1,d2
		Subq	#1,d3
		
		Move.l	GfxBase(pc),a6

		Move.l	MoveLay(pc),a3
		Move.l	12(a3),a3

		Move	LoCol(pc),d0
		Tst	d7
		Beq.b	PP_NHi1
		Move	HiCol(pc),d0
	PP_NHi1:Move.l	a3,a1
		Jsr	SetAPen(a6)

		Move.l	a3,a1
		Move	d2,d0
		Move	d3,d1
		Addq	#2,d2
		Addq	#2,d3
		Jsr	RectFill(a6)

		Move	HiCol(pc),d0
		Tst	d7
		Beq.b	PP_NHi2
		Move	LoCol(pc),d0
	PP_NHi2:Move.l	a3,a1
		Jsr	SetAPen(a6)

		Move.l	a3,a1
		Move	d2,d0
		Move	d3,d1
		Subq	#1,d0
		Subq	#1,d1
		Jmp	WritePixel(a6)
*---------------
Upd_MoveNameD:	;(Update current Move name)
		Lea	Move_NameUpd(pc),a4
			Lea	GMPrt_MoveName(pc),a5
		Clr.l	34(a4)
			Clr.l	(a5)
		Move	MoveList_Len(pc),d7
		Beq.b	UMoN_Ed
		Bsr.w	Get_Move_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	UMoN_Ed
		Addq	#8,a2
		Move.l	a2,34(a4)
			Move.l	a2,(a5)
	UMoN_Ed:Rts
*---------------
Upd_MoveNameG:	Lea	MPrtLay(pc),a5
		Lea	DrawList_MPrt(pc),a4
		Moveq.l	#13,d7
		Bsr.w	Draw_Some
		Lea	MoveLay(pc),a5
		Lea	Move_NameUpd(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Move_CLS:	Lea	GMove_Move(pc),a4
		Lea	MoveLay(pc),a5
		Moveq.l	#1,d7
		Bra.w	Draw_Some
*---------------
Move_Move:	Bsr.w	Get_MovePart
		Beq.w	MM_End
		Move.l	a1,a5

		Cmp	#1,(a5)
		Beq.w	MM_Fre
		Cmp	#2,(a5)
		Beq.w	MM_Sin
		Cmp	#3,(a5)
		Beq.b	MM_Lin
		Bra.w	MM_End
	*-- Handle Line Editing
	MM_Lin:	Lea	DPL_X2(pc),a0
		Bsr.w	Check_Point_Ca
		Beq.w	MM_NHit

	MML_Lp:	Move	LayX(pc),MM_X
		Move	LayY(pc),MM_Y

		Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY
		Move.l	LayL(pc),a0
		Cmp.l	#'MOVE',4(a0)
		Bne.b	MML_NMv
	*-- Detect movement
		Move	MM_X(pc),d0
		Cmp	LayX(pc),d0
		Bne.b	MML_Mv
		Move	MM_Y(pc),d0
		Cmp	LayY(pc),d0
		Bne.b	MML_Mv
		Bra.b	MML_NMv

	MML_Mv:	Move	LayX(pc),d0
		Sub	DP_CX(pc),d0
		Sub	DPL_X1(pc),d0
		Swap	d0
		Clr	d0
		Asr.l	#4,d0
		Move.l	d0,4(a5)

		Move	LayY(pc),d0
		Sub	DP_CY(pc),d0
		Sub	DPL_Y1(pc),d0
		Swap	d0
		Clr	d0
		Asr.l	#4,d0
		Move.l	d0,8(a5)

		Bsr.w	Draw_Path
		
	MML_NMv:Bsr.w	Check_Left_Up
		Beq.w	MML_Lp
		Bra.w	MM_End
	*-- Handle Sine Editing
	MM_Sin:	Bra.w	MM_End
	*-- Handle Freehand Editing
	MM_Fre:	Move	06(a5),FH_Rate	;RecDelay
		Lea	GMFre_Rec(pc),a0
		Btst	#0,4(a0)
		Beq.w	MM_End

		Move.l	MoveLay(pc),a3
		Move.l	12(a3),a3

		Move.l	GfxBase(pc),a6
		Jsr	WaitTOF(a6)

		Move	LayX(pc),d0
		Move	LayY(pc),d1
		Move.l	a3,a1
		Jsr	Move(a6)

		Move	LoCol(pc),d0
		Move.l	a3,a1
		Jsr	SetAPen(a6)

		Move	#-1,MM_LX	;First

	MM_Loop:Move.l	GfxBase(pc),a6
		Move	LayX(pc),d0
		Move	LayY(pc),d1
		Move.l	a3,a1
		Jsr	WritePixel(a6)
	*-- Store coordinates in table
		Move	FreeHandLen(pc),d6
		Lsl	#2,d6
		Move.l	Mem_FreeHand(pc),a0
		Move	LayX(pc),00(a0,d6.w)
		Move	LayY(pc),02(a0,d6.w)
		Addq	#1,FreeHandLen

		Move	FH_Rate(pc),MM_RCnt
	MM_Rate:Jsr	WaitTOF(a6)
		Subq	#1,MM_RCnt
		Bne.b	MM_Rate

		Move.l	Screen_Struct(pc),a0	;Get XY
		Move	18(a0),RawX
		Move	16(a0),RawY
		Bsr.w	Which_Layer		;Calculate Layer XY

		Bsr.w	Check_Left_Up
		Beq.b	MM_Loop
		Bsr.w	Insert_Freehand
		Bra.w	MM_End

	MM_NHit:
	MM_End:	Rts

	MM_X:	Dc	0
	MM_Y:	Dc	0
	MM_RCnt:Dc	0
	MM_LX:	Dc	-1
	MM_LY:	Dc	-1
	FH_Rate:Dc	1
*---------------
Draw_Path:	Lea	GMove_Sum(pc),a0
		Btst	#0,4(a0)
		Bne.w	DP_Sum

		Lea	MoveLay(pc),a5
		Lea	GMove_Move(pc),a4
		Bsr.w	Calc_Coord
		Move	X2(pc),d0
		Sub	X1(pc),d0
		Move	Y2(pc),d1
		Sub	Y1(pc),d1
		Lsr	#1,d0
		Lsr	#1,d1
		Add	X1(pc),d0
		Add	Y1(pc),d1
		Move	d0,DP_CX
		Move	d1,DP_CY
		
		Bsr.w	Move_CLS
		Bsr.w	Get_MovePart
		Beq.w	DS_E
		Move.l	a1,a5

		Cmp	#1,(a5)
		Beq.w	DP_Fre
		Cmp	#2,(a5)
		Beq.w	DP_Sin
		Cmp	#3,(a5)
		Beq.b	DP_Lin
		Bra.w	DS_E
	*-- Draw Line Path
	DP_Lin:	Clr.l	d6
		Clr.l	d7
		Move.l	d6,d2
		Move.l	d7,d3
		Swap	d2
		Swap	d3
		Move	d2,DPL_X1
		Move	d3,DPL_Y1
		Bsr.w	PlotPoint

		Moveq	#14,d5
	DPL_Lp:	Add.l	4(a5),d6
		Add.l	8(a5),d7
		Move.l	d6,d2
		Move.l	d7,d3
		Swap	d2
		Swap	d3
		Bsr.w	PlotPixel
		Dbf	d5,DPL_Lp

		Add.l	4(a5),d6
		Add.l	8(a5),d7
		Move.l	d6,d2
		Move.l	d7,d3
		Swap	d2
		Swap	d3
		Move	d2,DPL_X2
		Move	d3,DPL_Y2
		Bsr.w	PlotPoint

		Moveq	#15,d5
	DPL_Lp2:Add.l	4(a5),d6
		Add.l	8(a5),d7
		Move.l	d6,d2
		Move.l	d7,d3
		Swap	d2
		Swap	d3

		Move	d2,d0
		Move	d3,d1
		Add	DP_CX(pc),d0
		Add	DP_CY(pc),d1
		Cmp	X2(pc),d0
		Bge.b	DPL_E
		Cmp	Y2(pc),d1
		Bge.b	DPL_E
		Cmp	X1(pc),d0
		Ble.b	DPL_E
		Cmp	Y1(pc),d1
		Ble.b	DPL_E

		Bsr.w	PlotPixel
		Dbf	d5,DPL_Lp2

	DPL_E:	Rts
	*-- Draw Sine Path
	DP_Sin:	Clr	d2
		Move	8(a5),d4

	DS_Lp:	Move	d4,d0
		Bsr.w	GetSin
		Muls	4(a5),d1
		Swap	d1
		Move	d1,d3

		Bsr.w	PlotPixel
		Add	6(a5),d4
		Add	#1,d2
		Cmp	#160,d2
		Bne.b	DS_Lp

		Move	8(a5),d4
		Move	d4,d5
		And	#16383,d4
		Sub	#16384,d4
		Neg	d4
		
		And	#$c000,d5
		Rol	#2,d5
		Tst	d4
		Beq.b	DSS_0
		Addq	#1,d5
		And	#3,d5
	DSS_0:	And.l	#$ffff,d4
		Divu	6(a5),d4

		Move.l	#16384,d6
		Divu	6(a5),d6
		Move.l	d6,d0
		Clr	d0
		And.l	#$ffff0000,d0
		Divu	6(a5),d0
		Swap	d6
		Move	d0,d6

	DSS_Lp2:Cmp	#0,d5
		Beq.b	DSS_P0
		Cmp	#2,d5
		Beq.b	DSS_P0
		Cmp	#3,d5
		Beq.b	DSS_Top
		Cmp	#1,d5
		Beq.b	DSS_Bot
		
	DSS_P0:	Clr	d3
		Bra.b	DSS_Drw

	DSS_Top:Clr	d3
		Move	4(a5),d0
		Lsr	#1,d0
		Sub	d0,d3
		Bra.b	DSS_Drw

	DSS_Bot:Clr	d3
		Move	4(a5),d0
		Lsr	#1,d0
		Add	d0,d3
		Bra.w	DSS_Drw

	DSS_Drw:Move	d4,d2
		Bsr.w	PlotPoint
		Addq	#1,d5
		And	#3,d5
		Swap	d4
		Add.l	d6,d4
		Swap	d4
		Cmp	#160,d4
		Blt.b	DSS_Lp2

	DS_E:	Rts
	*-- Draw Freehand Path
	DP_Fre:	Move.l	Mem_FreeHand(pc),a4
		Move	FreeHandLen(pc),d6

	DFH_Lp:	;Move.l	GfxBase(pc),a6
		;Jsr	WaitTOF(a6)
		;Jsr	WaitTOF(a6)
		
		Tst	d6
		Beq.b	DFH_End
		Move	(a4)+,d2
		;Mulu	#20000,d2	;Zoom
		;Swap	d2
		Move	(a4)+,d3
		;Mulu	#20000,d3	;Zoom
		;Swap	d3

		;Bsr.w	GetRnd	;Add Rnd
		;Muls	#8,d1
		;Swap	d1
		;Add	d1,d3

		Bsr.w	PlotPixel
		Subq	#1,d6
		Bra.b	DFH_Lp
	DFH_End:Rts

	DP_Sum:	Rts

FreeHandLen:	Dc	0
	DPL_X1:	Dc	0
	DPL_Y1:	Dc	0
	DPL_X2:	Dc	0
	DPL_Y2:	Dc	0
	DP_CX:	Dc	0
	DP_CY:	Dc	0
*---------------
Insert_Freehand:Move	Cur_Part(pc),IF_ChgPart
		Bmi.w	IF_End		;No Part Selected
	*-- Find current Movement, and check if it exists
		Bsr.w	Get_Move_LAdr
		Tst.l	(a2)
		Beq.w	IF_End
		Move.l	a2,IF_ListAdr
		Move.l	(a2),a0
		Bsr.w	Update_MoveBuf
	*-- Free old Movement
		Move.l	IF_ListAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Find Part (A5->Address)
		Move.l	Mem_MoveBuf(pc),a4
		Move	IF_ChgPart(pc),d0
		Add	d0,d0
		Move	08(a4,d0.w),d0
		Lea	00(a4,d0.w),a5
		Move	FreeHandLen(pc),d0
		Sub	12(a5),d0
		Asl	#2,d0
		Move	d0,IF_BytesChg
	*-- Allocate space for new Movement
		Move.l	Mem_MoveBuf(pc),a2	;Get buffer address
		Clr.l	d0
		Move.l	2(a2),d0
		Add	IF_BytesChg(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	IF_ListAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_MemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Move address
		Move.l	Mem_MoveBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	IF_BytesChg(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Move	d7,(a1)+		;+
	*-- Copy FrameOffsets
		Clr	d0
		Moveq.l	#0,d3
	IF_LFO:	Cmp	d7,d0
		Beq.b	IF_FnO
		Move	(a2)+,d2
		Add	d3,d2
		Move	d2,(a1)+
	IF_Nxt:	Cmp	IF_ChgPart(pc),d0	;Is part to change?
		Bne.b	IF_NCh
		Move	IF_BytesChg(pc),d3
	IF_NCh:	Addq	#1,d0
		Bra.b	IF_LFO
	*-- Copy from start to end
	IF_FnO:	Clr	d6
	IF_C2L:	Cmp	d7,d6
		Beq.b	IF_FnP

		Cmp	IF_ChgPart(pc),d6
		Beq.b	IF_Chg

		Move	(a2)+,d1		;Type
		Move	(a2)+,d0		;Size
		Move	d1,(a1)+		;Type
		Move	d0,(a1)+		;Size
		Subq	#4,d0
	IF_C1L:	Subq	#1,d0			;Count number of bytes
		Bmi.b	IF_C1E
		Move.b	(a2)+,(a1)+
		Bra.b	IF_C1L			;Loop

	IF_Chg:	Move	(a2)+,(a1)+	;Copy Type
		Move	(a2)+,d0	;Copy Size
		Add	IF_BytesChg(pc),d0
		Move	d0,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move	(a2)+,d1	;Get old Amount
		Move	FreeHandLen(pc),d0
		Move	d0,(a1)+
		Lsl	#2,d1		;Skip old coordinates
		Add	d1,a2		;+
		Move.l	Mem_FreeHand,a0
	IF_CCo:	Subq	#1,d0
		Bmi.b	IF_C1E
		Move.l	(a0)+,(a1)+
		Bra.b	IF_CCo

	IF_C1E:	Addq	#1,d6			;Count Parts
		Bra.b	IF_C2L
	IF_FnP:
	IF_End:	Rts
IF_ListAdr:	Dc.l	0
IF_BytesChg:	Dc	0
IF_ChgPart:	Dc	0
*---------------
Buffer_Freehand:Move	Cur_Part(pc),BF_BufPart
		Bmi.b	BF_End		;No Part Selected
	*-- Find current Movement, and check if it exists
		Bsr.w	Get_Move_LAdr
		Tst.l	(a2)
		Beq.b	BF_End
		Move.l	a2,BF_ListAdr
		Move.l	(a2),a4
	*-- Find Part (A5->Address)
		Move	BF_BufPart(pc),d0
		Add	d0,d0
		Move	08(a4,d0.w),d0
		Lea	00(a4,d0.w),a5
		Cmp	#1,(a5)		;Freehand?
		Bne.b	BF_End		;No!

		Move	12(a5),FreeHandLen
		Lea	14(a5),a1
		Move	FreeHandLen(pc),d0
		Move.l	Mem_FreeHand,a0
	BF_CCo:	Subq	#1,d0
		Bmi.b	BF_End
		Move.l	(a1)+,(a0)+
		Bra.b	BF_CCo
	BF_End:	Rts
BF_ListAdr:	Dc.l	0
BF_BufPart:	Dc	0
*---------------
MFre_FlipX:	Move	#0,d5
		Bra.b	MFre_Flip
MFre_FlipY:	Move	#2,d5
MFre_Flip:	Move.l	Mem_FreeHand,a0
		Move	FreeHandLen(pc),d0
	MFF_Lp:	Subq	#1,d0
		Bmi.b	MFF_Ed
		Neg	00(a0,d5.w)
		Addq	#4,a0
		Bra.b	MFF_Lp
	MFF_Ed:	Bsr.w	Insert_Freehand
		Bra.w	Draw_Path
*---------------
GetRnd:		Move	Rnd(pc),d1
		Neg	d1
		Add	#$567b,d1
		Eor	#$6dc5,d1
		Ror	#1,d1
		Move	d1,Rnd
		Rts
	Rnd:	Dc	$e6a3
*---------------
Check_Point_Ex:	Move	(a0),d0
		Move	2(a0),d1
		Move	LayX(pc),d2
		Move	LayY(pc),d3
		Sub	DP_CX(pc),d2
		Sub	DP_CY(pc),d3

		Cmp	d0,d2
		Bne.b	CPE_No
		Cmp	d1,d3
		Bne.b	CPE_No
		Moveq.l	#-1,d7
		Rts
	CPE_No:	Clr.l	d7
		Rts
*---------------
Check_Point_Ca:	Move	(a0),d0
		Move	2(a0),d1
		Move	LayX(pc),d2
		Move	LayY(pc),d3
		Sub	DP_CX(pc),d2
		Sub	DP_CY(pc),d3

		Addq	#1,d0
		Addq	#1,d1
		Cmp	d0,d2
		Bgt.b	CPC_No
		Cmp	d1,d3
		Bgt.b	CPC_No
		Subq	#2,d0
		Subq	#2,d1
		Cmp	d0,d2
		Blt.b	CPC_No
		Cmp	d1,d3
		Blt.b	CPC_No

		Moveq.l	#-1,d7
		Rts
	CPC_No:	Clr.l	d7
		Rts
*---------------
GetSin:		;(D0=Degree [0,65535], D1->Sine [-32767,+32767])
		Lea	Sine,a0	;###
		Move	d0,d1
		Lsr	#5,d1
		And	#$3fe,d1
		Move	(a0,d1.w),d1
		Tst	d0
		Bpl.b	GSEnd
		Neg	d1
GSEnd:		Rts
*---------------
Move_MovePart:	Lea	MPrtLay(pc),a5
		Bra.w	Open_Layer
*---------------
MSin_Angle:	Bsr.w	Get_MovePart
		Beq.b	MSA_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Cmp	#135,d0
		Bhi.b	MSA_Ov
		Divu	#45,d0
		Mulu	#45,d0
		Move	d0,10(a1)
	MSA_Ov:	Bsr.b	Upd_MSin_AngD
		Bsr.b	Upd_MSin_AngG
		Bsr.w	Draw_Path
	MSA_Ed:	Rts
*---------------
Upd_MSin_AngD:	Bsr.w	Get_MovePart
		Beq.b	UMSA_Ed
		Move	10(a1),d0
		Lea	MSin_AngleNT+5(pc),a0
		Move	#$8302,d7
		Bsr.w	Conv
	UMSA_Ed:Rts
*---------------
Upd_MSin_AngG:	Lea	MPrtLay(pc),a5
		Lea	GMSin_Angle(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
MSin_Rate:	Bsr.w	Get_MovePart
		Beq.b	MSR_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,06(a1)
		Bsr.b	Upd_MSin_RatD
		Bsr.b	Upd_MSin_RatG
		Bsr.w	Draw_Path
	MSR_Ed:	Rts
*---------------
Upd_MSin_RatD:	Bsr.w	Get_MovePart
		Beq.b	UMSR_Ed
		Move	06(a1),d0
		Lea	MSin_RateNT+5(pc),a0
		Move	#$8104,d7
		Bsr.w	Conv
	UMSR_Ed:Rts
*---------------
Upd_MSin_RatG:	Lea	MPrtLay(pc),a5
		Lea	GMSin_Rate(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
MSin_Width:	Bsr.w	Get_MovePart
		Beq.b	MSW_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,04(a1)
		Bsr.b	Upd_MSin_WidD
		Bsr.b	Upd_MSin_WidG
		Bsr.w	Draw_Path
	MSW_Ed:	Rts
*---------------
Upd_MSin_WidD:	Bsr.w	Get_MovePart
		Beq.b	UMSW_Ed
		Move	04(a1),d0
		Lea	MSin_WidthNT+5(pc),a0
		Move	#$8104,d7
		Bsr.w	Conv
	UMSW_Ed:Rts
*---------------
Upd_MSin_WidG:	Lea	MPrtLay(pc),a5
		Lea	GMSin_Width(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
MSin_Start:	Bsr.w	Get_MovePart
		Beq.b	MSS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,08(a1)
		Bsr.b	Upd_MSin_StaD
		Bsr.b	Upd_MSin_StaG
		Bsr.w	Draw_Path
	MSS_Ed:	Rts
*---------------
Upd_MSin_StaD:	Bsr.w	Get_MovePart
		Beq.b	UMSS_Ed
		Move	08(a1),d0
		Lea	MSin_StartNT+5(pc),a0
		Move	#$8104,d7
		Bsr.w	Conv
	UMSS_Ed:Rts
*---------------
Upd_MSin_StaG:	Lea	MPrtLay(pc),a5
		Lea	GMSin_Start(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
MFre_Delay:	Bsr.w	Get_MovePart
		Beq.b	FD_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,06(a1)
		Bsr.b	Upd_MFre_DelD
		Bsr.b	Upd_MFre_DelG
	FD_End:	Rts
*---------------
Upd_MFre_DelD:	Bsr.w	Get_MovePart
		Beq.b	UFD_Ed
		Cmp	#1,(a1)	;Type=FreeHand?
		Bne.b	UFD_Ed
		Move	06(a1),d0
		Lea	MFre_DelayNT+3(pc),a0
		Move	#$0102,d7
		Bsr.w	Conv
	UFD_Ed:	Rts
*---------------
Upd_MFre_DelG:	Lea	MPrtLay(pc),a5
		Lea	GMFre_Delay(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
MFre_FreeX:	Bsr.w	Get_MovePart
		Beq.b	FFX_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Bchg	#0,05(a1)
		Bsr.b	Upd_MFre_FreeXD
		Bsr.b	Upd_MFre_FreeXG
	FFX_End:Rts
*---------------
Upd_MFre_FreeXD:Bsr.b	Get_MovePart
		Beq.b	UFFX_Ed
		Lea	GMFre_FreeX(pc),a4
		Move	#Im_Blank-Im,d0
		Btst	#0,05(a1)
		Beq.b	UFFX_Of
		Move	#Im_Check5-Im,d0
	UFFX_Of:Move	d0,32(a4)
	UFFX_Ed:Rts
*---------------
Upd_MFre_FreeXG:Lea	GMFre_FreeX(pc),a4
		Lea	MPrtLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
MFre_FreeY:	Bsr.b	Get_MovePart
		Beq.b	FFY_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Bchg	#1,05(a1)
		Bsr.b	Upd_MFre_FreeYD
		Bsr.b	Upd_MFre_FreeYG
	FFY_End:Rts
*---------------
Upd_MFre_FreeYD:Bsr.b	Get_MovePart
		Beq.b	UFFY_Ed
		Lea	GMFre_FreeY(pc),a4
		Move	#Im_Blank-Im,d0
		Btst	#1,05(a1)
		Beq.b	UFFY_Of
		Move	#Im_Check5-Im,d0
	UFFY_Of:Move	d0,32(a4)
	UFFY_Ed:Rts
*---------------
Upd_MFre_FreeYG:Lea	GMFre_FreeY(pc),a4
		Lea	MPrtLay(pc),a5
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Get_MovePart:	Move	MoveList_Len(pc),d0
		Beq.b	GMP_Ed
		Bsr.w	Get_Move_LAdr
		Tst.l	(a2)
		Beq.b	GMP_Ed
		Move.l	(a2),a1
	*-- Find current Part (A1->Address)
		Move	6(a1),d0	;No Parts?
		Beq.b	GMP_Ed		;+
		Move	Cur_Part(pc),d0
		Bmi.b	GMP_Ed		;No Part selected?
		Add	d0,d0
		Move	08(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		Moveq.l	#1,d0
		Rts
	GMP_Ed:	Clr.l	d0
		Rts
*---------------
Move_Load:	Move.l	MoveList(pc),a4
		Move.l	(a4),a4
		Move	Cur_Move(pc),d4
		Move.l	#'MOVE',d0
		Bsr.w	Load_Unit
		Bra.w	Change_Move
*---------------
Check_Move:	Lea	Move_Jump(pc),a0
		Move	MoveList_Len(pc),d0
		Beq.b	CM_NoUn
	*-- Find current Move, and check if it exists
		Move.l	Mem_MoveList(pc),a2
		Move	Cur_Move(pc),d0
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Move?
		Beq.b	CM_NoGr		;No
		Lea	Move_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CM_NoUn:Lea	Move_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CM_NoGr:Lea	Move_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_MPrt:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	MovePart8T
		Dc	'TX',084,009,-01,5
		Dc.l	DashT
		Dc	'TX',093,009,-109,5
GMPrt_MoveName:	Dc.l	0

		Dc	'BX',000,011,087,027

		Dc	'GD'
		Dc.l	$020100a3,1,Move_AddPart
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_FreeHand-Im

		Dc	'GD'
		Dc.l	$020100a4,2,Move_AddPart
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_Sine-Im

		Dc	'GD'
		Dc.l	$020100a5,3,Move_AddPart
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Line-Im

		Dc	'GD'
		Dc.l	$020100a6,4,Move_AddPart
		Dc	'BX',042,013,054,025
		Dc	'IM',044,015,9,Im_Position-Im

		Dc	'GD'
		Dc.l	$020100a7,5,Move_AddPart
		Dc	'BX',055,013,067,025
		Dc	'IM',057,015,9,Im_Joystick-Im

		Dc	'GD'
		Dc.l	$020100a2,0,Move_DelPart
		Dc	'BX',072,013,084,025
		Dc	'IM',074,015,9,Im_ClrClips-Im

		Dc	'BX',088,011,-01,027

GMove_Sum:	Dc	'GD'
		Dc.l	$020102b1,0,Move_Sum
		Dc	'BX',-95,013,-83,025
		Dc	'IM',-93,015,9,Im_Sum-Im

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-77,013,-65,025
		Dc	'IM',-75,015,9,Im_Anim-Im

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-64,013,-52,025
		Dc	'IM',-62,015,9,Im_Gravity-Im

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-51,013,-39,025
		Dc	'IM',-49,015,9,Im_Background-Im

GMove_DataJmp:	Dc	'JS'
		Dc.l	DrawList_MNul

		Dc	'FR',000,028,-01,046

GMove_Part1:	Dc	'XX'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',003,031,015,043
		Dc	'IM',005,033,9,Im_FreeHand-Im

GMove_Part2:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',016,031,028,043
		Dc	'IM',018,033,9,Im_FreeHand-Im

GMove_Part3:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',029,031,041,043
		Dc	'IM',031,033,9,Im_FreeHand-Im

GMove_Part4:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',042,031,054,043
		Dc	'IM',044,033,9,Im_FreeHand-Im

GMove_Part5:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',055,031,067,043
		Dc	'IM',057,033,9,Im_FreeHand-Im

GMove_Part6:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',068,031,080,043
		Dc	'IM',070,033,9,Im_FreeHand-Im

GMove_Part7:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',081,031,093,043
		Dc	'IM',083,033,9,Im_FreeHand-Im

GMove_Part8:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',094,031,106,043
		Dc	'IM',096,033,9,Im_FreeHand-Im

GMove_Part9:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',107,031,119,043
		Dc	'IM',109,033,9,Im_FreeHand-Im

GMove_Part10:	Dc	'GD'
		Dc.l	$020106a8,MPrL_Excl,Move_SelPart
		Dc	'BX',120,031,132,043
		Dc	'IM',122,033,9,Im_FreeHand-Im

		Dc	'XX'

MPrL_Excl:	Dc.l	GMove_Part1
		Dc.l	GMove_Part2
		Dc.l	GMove_Part3
		Dc.l	GMove_Part4
		Dc.l	GMove_Part5
		Dc.l	GMove_Part6
		Dc.l	GMove_Part7
		Dc.l	GMove_Part8
		Dc.l	GMove_Part9
		Dc.l	GMove_Part10
		Dc.l	0
*---------------
DrawList_MNul:	Dc	'BX',000,047,-01,-01
		Dc	'RT'
*---------------
DrawList_MMod:	Dc	'BX',103,047,-01,-01

		Dc	'TX',106,057,-01,8
		Dc.l	Modulate8T

		Dc	'TX',138,066,-01,5
		Dc.l	SpeedT
		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-23,059,-04,067
		Dc	'TX',-20,066,-01,5
		Dc.l	MMod_LinT

		Dc	'TX',106,079,-01,5
		Dc.l	ValueT
		;Dc	'RO'
		;Dc.l	Upd_MFre_DelD
GMMod_Delay:	Dc	'GD'
		Dc.l	$02030a00,5,0	;MFre_Delay
		Dc	'RC',-52,072,-23,080
		Dc	'TX',-49,079,-01,5
		Dc.l	MMod_ValueNT
		Dc	'GD'
		Dc.l	$02010052,MFre_Delay_P,PlusMinus
		Dc	'BX',-21,072,-13,080
		Dc	'IM',-19,076,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MFre_Delay_P,PlusMinus
		Dc	'BX',-12,072,-04,080
		Dc	'IM',-10,074,5,Im_Plus-Im

		Dc	'RT'

Modulate8T:	Dc.b	'Modulate:',0
MMod_NulT:	Dc.b	' 0 ',0
MMod_RndT:	Dc.b	'RND',0
MMod_LinT:	Dc.b	'LIN',0
MMod_SinT:	Dc.b	'SIN',0
ValueT:		Dc.b	'VALUE:',0
MMod_ValueNT:	Dc.b	'99990',0
MMod_RateT:	Dc.b	'RATE:',0
MMod_RateNT:	Dc.b	'  100',0
		Even
*---------------
DrawList_MFre:	Dc	'BX',000,047,102,-01

		Dc	'TX',003,057,-01,8
		Dc.l	Freehand8T

GMFre_Rec:	Dc	'GD'
		Dc.l	$02010300,0,0
		Dc	'BX',003,058,015,070
		Dc	'IM',005,060,9,Im_Record-Im

		Dc	'GD'
		Dc.l	$02010000,0,MFre_Clear
		Dc	'BX',016,058,028,070
		Dc	'IM',018,060,9,Im_ClrClips-Im

GMFre_Mouse:	Dc	'GD'
		Dc.l	$02010700,MFre_Excl_Con,0
		Dc	'BX',032,058,044,070
		Dc	'IM',034,060,9,Im_Mouse-Im

GMFre_Joy:	Dc	'GD'
		Dc.l	$02010600,MFre_Excl_Con,0
		Dc	'BX',045,058,057,070
		Dc	'IM',047,060,9,Im_Joystick-Im

GMFre_Key:	Dc	'GD'
		Dc.l	$02010600,MFre_Excl_Con,0
		Dc	'BX',058,058,070,070
		Dc	'IM',060,060,9,Im_Keyboard-Im

		Dc	'GD'
		Dc.l	$0201001e,0,MFre_FlipX
		Dc	'BX',074,058,086,070
		Dc	'IM',076,060,9,Im_FlipX-Im

		Dc	'GD'
		Dc.l	$0201001f,0,MFre_FlipY
		Dc	'BX',087,058,099,070
		Dc	'IM',089,060,9,Im_FlipY-Im

		Dc	'TX',003,079,-01,5
		Dc.l	DelayT
		Dc	'RO'
		Dc.l	Upd_MFre_DelD
GMFre_Delay:	Dc	'GD'
		Dc.l	$02030a00,3,MFre_Delay
		Dc	'RC',061,072,080,080
		Dc	'TX',064,079,-01,5
		Dc.l	MFre_DelayNT
		Dc	'GD'
		Dc.l	$02010052,MFre_Delay_P,PlusMinus
		Dc	'BX',082,072,090,080
		Dc	'IM',084,076,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MFre_Delay_P,PlusMinus
		Dc	'BX',091,072,099,080
		Dc	'IM',093,074,5,Im_Plus-Im

		Dc	'TX',003,089,-01,5
		Dc.l	SmoothingT
GMFre_Smooth:	Dc	'GD'
		Dc.l	$02030a00,3,0	;MFre_Smooth
		Dc	'RC',061,082,080,090
		Dc	'TX',064,089,-01,5
		Dc.l	MFre_SmoothNT
		Dc	'GD'
		Dc.l	$02010052,MFre_Smooth_P,PlusMinus
		Dc	'BX',082,082,090,090
		Dc	'IM',084,086,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MFre_Smooth_P,PlusMinus
		Dc	'BX',091,082,099,090
		Dc	'IM',093,084,5,Im_Plus-Im

		Dc	'TX',003,099,-01,5
		Dc.l	ZoomT

		Dc	'TX',046,099,-01,5
		Dc.l	XT
		Dc	'GD'
		Dc.l	$02010034,0,0
		Dc	'BX',053,092,061,100
		Dc	'IM',055,096,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010033,0,0
		Dc	'BX',062,092,070,100
		Dc	'IM',064,094,5,Im_Plus-Im

		Dc	'TX',075,099,-01,5
		Dc.l	YT
		Dc	'GD'
		Dc.l	$02010034,0,0
		Dc	'BX',082,092,090,100
		Dc	'IM',084,096,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010033,0,0
		Dc	'BX',091,092,099,100
		Dc	'IM',093,094,5,Im_Plus-Im

		Dc	'TX',003,109,-01,5
		Dc.l	FreeT

		Dc	'TX',036,109,-01,5
		Dc.l	SpdT
		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',053,102,061,110
		Dc	'IM',055,104,5,Im_Check5-Im

		Dc	'TX',065,109,-01,5
		Dc.l	XT
		Dc	'RO'
		Dc.l	Upd_MFre_FreeXD
GMFre_FreeX:	Dc	'GD'
		Dc.l	$02010000,0,MFre_FreeX
		Dc	'BX',072,102,080,110
		Dc	'IM',074,104,5,Im_Check5-Im

		Dc	'TX',084,109,-01,5
		Dc.l	YT
		Dc	'RO'
		Dc.l	Upd_MFre_FreeYD
GMFre_FreeY:	Dc	'GD'
		Dc.l	$02010000,0,MFre_FreeY
		Dc	'BX',091,102,099,110
		Dc	'IM',093,104,5,Im_Check5-Im

		Dc	'JP'
		Dc.l	DrawList_MMod

MFre_Delay_P:	Dc	1,1,255,$8303
MFre_Smooth_P:	Dc	1,0,255,$8303

MFre_Excl_Con:	Dc.l	GMFre_Mouse
		Dc.l	GMFre_Joy
		Dc.l	GMFre_Key
		Dc.l	0

ZoomT:		Dc.b	'ZOOM:',0
FreeT:		Dc.b	'FREE:',0
SmoothingT:	Dc.b	'SMOOTHING:',0
MFre_DelayNT:	Dc.b	'  0',0
MFre_SmoothNT:	Dc.b	'  0',0
		Even
*---------------
DrawList_MSin:	Dc	'BX',000,047,102,-01

		Dc	'TX',003,057,-01,8
		Dc.l	Sine8T

		Dc	'RO'
		Dc.l	Upd_MSin_AngD

		Dc	'TX',003,065,-01,5
		Dc.l	AngleT
GMSin_Angle:	Dc	'GD'
		Dc.l	$02030a00,5,MSin_Angle
		Dc	'RC',031,058,060,066
		Dc	'TX',034,065,-01,5
		Dc.l	MSin_AngleNT
		Dc	'GD'
		Dc.l	$02010052,MSin_Angle_P,PlusMinus
		Dc	'BX',062,058,070,066
		Dc	'IM',064,062,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MSin_Angle_P,PlusMinus
		Dc	'BX',071,058,079,066
		Dc	'IM',073,060,5,Im_Plus-Im
GMSin_Mod1:	Dc	'GD'
		Dc.l	$02010600,MSin_Mod_Excl,0
		Dc	'BX',080,058,099,066
		Dc	'TX',083,065,-01,5
		Dc.l	MMod_NulT

		Dc	'RO'
		Dc.l	Upd_MSin_RatD

		Dc	'TX',003,075,-01,5
		Dc.l	RateT
GMSin_Rate:	Dc	'GD'
		Dc.l	$02030a00,5,MSin_Rate
		Dc	'RC',031,068,060,076
		Dc	'TX',034,075,-01,5
		Dc.l	MSin_RateNT
		Dc	'GD'
		Dc.l	$02010052,MSin_Rate_P,PlusMinus
		Dc	'BX',062,068,070,076
		Dc	'IM',064,072,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MSin_Rate_P,PlusMinus
		Dc	'BX',071,068,079,076
		Dc	'IM',073,070,5,Im_Plus-Im
GMSin_Mod2:	Dc	'GD'
		Dc.l	$02010600,MSin_Mod_Excl,0
		Dc	'BX',080,068,099,076
		Dc	'TX',083,075,-01,5
		Dc.l	MMod_NulT

		Dc	'RO'
		Dc.l	Upd_MSin_WidD

		Dc	'TX',003,085,-01,5
		Dc.l	WidthT
GMSin_Width:	Dc	'GD'
		Dc.l	$02030a00,5,MSin_Width
		Dc	'RC',031,078,060,086
		Dc	'TX',034,085,-01,5
		Dc.l	MSin_WidthNT
		Dc	'GD'
		Dc.l	$02010052,MSin_Width_P,PlusMinus
		Dc	'BX',062,078,070,086
		Dc	'IM',064,082,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MSin_Width_P,PlusMinus
		Dc	'BX',071,078,079,086
		Dc	'IM',073,080,5,Im_Plus-Im
GMSin_Mod3:	Dc	'GD'
		Dc.l	$02010600,MSin_Mod_Excl,0
		Dc	'BX',080,078,099,086
		Dc	'TX',083,085,-01,5
		Dc.l	MMod_NulT

		Dc	'RO'
		Dc.l	Upd_MSin_StaD

		Dc	'TX',003,095,-01,5
		Dc.l	StartT
GMSin_Start:	Dc	'GD'
		Dc.l	$02030a00,5,MSin_Start
		Dc	'RC',031,088,060,096
		Dc	'TX',034,095,-01,5
		Dc.l	MSin_StartNT
		Dc	'GD'
		Dc.l	$02010052,MSin_Start_P,PlusMinus
		Dc	'BX',062,088,070,096
		Dc	'IM',064,092,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MSin_Start_P,PlusMinus
		Dc	'BX',071,088,079,096
		Dc	'IM',073,090,5,Im_Plus-Im
GMSin_Mod4:	Dc	'GD'
		Dc.l	$02010600,MSin_Mod_Excl,0
		Dc	'BX',080,088,099,096
		Dc	'TX',083,095,-01,5
		Dc.l	MMod_NulT

		Dc	'JP'
		Dc.l	DrawList_MMod

MSin_Angle_P:	Dc	45,0,359,$8303
MSin_Rate_P:	Dc	10,1,16384,$8105
MSin_Width_P:	Dc	1,0,32767,$8104
MSin_Start_P:	Dc	10,0,16384,$8105

MSin_Mod_Excl:	Dc.l	GMSin_Mod1
		Dc.l	GMSin_Mod2
		Dc.l	GMSin_Mod3
		Dc.l	GMSin_Mod4
		Dc.l	0

MSin_AngleNT:	Dc.b	'    0',0
MSin_RateNT:	Dc.b	'    0',0
MSin_WidthNT:	Dc.b	'    0',0
MSin_StartNT:	Dc.b	'    0',0
		Even
*---------------
DrawList_MLin:	Dc	'BX',000,047,102,-01

		Dc	'TX',003,057,-01,8
		Dc.l	Line8T

		Dc	'TX',003,065,-01,5
		Dc.l	SpeedT
GMLin_Speed:	Dc	'GD'
		Dc.l	$02030a00,5,0	;MLin_Speed
		Dc	'RC',031,058,060,066
		Dc	'TX',034,065,-01,5
		Dc.l	MLin_SpeedNT
		Dc	'GD'
		Dc.l	$02010052,MLin_Speed_P,PlusMinus
		Dc	'BX',062,058,070,066
		Dc	'IM',064,062,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MLin_Speed_P,PlusMinus
		Dc	'BX',071,058,079,066
		Dc	'IM',073,060,5,Im_Plus-Im
GMLin_Mod1:	Dc	'GD'
		Dc.l	$02010600,MLin_Mod_Excl,0
		Dc	'BX',080,058,099,066
		Dc	'TX',083,065,-01,5
		Dc.l	MMod_NulT

		Dc	'TX',003,075,-01,5
		Dc.l	AngleT
GMLin_Angle:	Dc	'GD'
		Dc.l	$02030a00,5,0	;MLin_Angle
		Dc	'RC',031,068,060,076
		Dc	'TX',034,075,-01,5
		Dc.l	MLin_AngleNT
		Dc	'GD'
		Dc.l	$02010052,MLin_Angle_P,PlusMinus
		Dc	'BX',062,068,070,076
		Dc	'IM',064,072,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,MLin_Angle_P,PlusMinus
		Dc	'BX',071,068,079,076
		Dc	'IM',073,070,5,Im_Plus-Im
GMLin_Mod2:	Dc	'GD'
		Dc.l	$02010600,MLin_Mod_Excl,0
		Dc	'BX',080,068,099,076
		Dc	'TX',083,075,-01,5
		Dc.l	MMod_NulT

		Dc	'JP'
		Dc.l	DrawList_MMod

MLin_Speed_P:	Dc	1,-9999,9999,$8303
MLin_Angle_P:	Dc	10,0,3599,$8303

MLin_Mod_Excl:	Dc.l	GMLin_Mod1
		Dc.l	GMLin_Mod2
		Dc.l	0
		
MLin_SpeedNT:	Dc.b	'    0',0
MLin_AngleNT:	Dc.b	'    0',0
		Even
*---------------
DrawList_MPos:	Dc	'BX',000,047,102,-01

		Dc	'TX',003,057,-01,8
		Dc.l	Position8T

		Dc	'JP'
		Dc.l	DrawList_MMod
*---------------
DrawList_MCon:	Dc	'BX',000,047,102,-01

		Dc	'TX',003,057,-01,8
		Dc.l	Control8T

		Dc	'JP'
		Dc.l	DrawList_MMod
*---------------
DrawList_Move:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Movement8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Move_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Move_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Move_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-34,025

		Dc	'RO'
		Dc.l	Upd_MoveNameD

Move_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Move_Name
		Dc	'RC',049,015,-56,023
		Dc	'TX',051,022,-107,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Move_Info,Unit_BrowseUp
		Dc	'BX',-53,015,-45,023
		Dc	'IM',-51,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Move_Info,Unit_BrowseDn
		Dc	'BX',-44,015,-36,023
		Dc	'IM',-42,018,3,Im_DArr-Im

		Dc	'GD'
		Dc.l	$020100a1,0,Move_MovePart
		Dc	'BX',-29,013,-17,025
		Dc	'IM',-27,015,9,Im_FullClip-Im

		Dc	'GD'
		Dc.l	$0201000e,0,Move_PlayScreen
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_PlayScr-Im

		Dc	'GD'
		Dc.l	$02020000,Move_Prop_X,0
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',003,-07,-20,-03

		Dc	'GD'
		Dc.l	$02020000,Move_Prop_Y,0
		Dc	'BX',-09,028,-01,-10
		Dc	'BX',-07,030,-03,-14

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

Move_GfxUpd:	Dc	'RO'
		Dc.l	Check_Move

		Dc	'JP'
Move_Jump:	Dc.l	Move_No

Move_Yes:	Dc	'GD'
		Dc.l	$01000000,0,Move_Move
GMove_Move:	Dc	'BX',000,028,-10,-10
		Dc	'RO'
		Dc.l	Draw_Path
		Dc	'XX'

Move_No:	Dc	'BX',000,028,-10,-10
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Move_Load
		Dc	'BX',-37,030,-13,038
		Dc	'TX',-34,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Move_None:	Dc	'BX',000,028,-10,-10
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Move_Prop_X:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
Move_Prop_Y:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,65535		;KnobX,Y
		Dc	0,0		;PosX,Y
*=======================================================================*
*			   B A C K G R O U N D				*
*=======================================================================*
Back_New:	Lea	BackList(pc),a4
		Lea	New_Back(pc),a2
		Bsr.w	Unit_New
		Move	d7,Cur_Back
		Bra.w	Change_Back
New_Back:	Dc	0	;Id		00
		Dc.l	100	;BytSize	02
		Dc	0	;TotalPiece	06

		Dc	0	;TotalAnim	08
		Dc.l	0	;OffsetAnim	10
		
		Dc	0	;X1Limit	14
		Dc	0	;X1LimitEnd	16
		Dc.b	0	;X1Flags	18
		Blk.b	3,0	;Unused		19
		Dc	0	;Y1Limit	22
		Dc	0	;Y1LimitEnd	24
		Dc.b	0	;Y1Flags	26
		Blk.b	3,0	;Unused		27
		Dc	0	;X2Limit	30
		Dc	0	;X2LimitEnd	32
		Dc.b	0	;X2Flags	34
		Blk.b	3,0	;Unused		35
		Dc	0	;Y2Limit	38
		Dc	0	;Y2LimitEnd	40
		Dc.b	0	;Y2Flags	42
		Blk.b	3,0	;Unused		43
		
		Dc.l	0	;SpeedX		46
		Dc.l	0	;SpeedY		50
		Dc	0	;MapSizeX	54
		Dc	0	;MapSizeY	56
		Dc	0	;GridSizeX	58
		Dc	0	;GridSizeY	60
		Dc	0	;GridOffsX	62
		Dc	0	;GridOffsY	64
		Dc.b	0	;GridFlags	66
		Blk.b	33,0	;Unused		67
*---------------
Back_Name:	Move	#1,Game_NeedUpd
		Bsr.w	Upd_BackNameD
		Bra.w	Upd_BackNameG
*---------------
Back_Scroll:	Lea	ScrlLay(pc),a5
		Bra.w	Open_Layer
*---------------
;Back_Grid:	Lea	GridLay(pc),a5
;		Bra.w	Open_Layer
*---------------
Back_PiecePick:	;Lea	GBack_Pick(pc),a0	;Button up?
		;Btst	#0,4(a0)
		;Bne.b	BPP_No
		Clr	Cur_BackPiece
		Bsr.w	Draw_Back
	BPP_No:	Rts
*---------------
Back_PieceDel:
	*-- Any Piece Selected?
		Move	Cur_BackPiece(pc),d0
		Beq.b	BPD_End
	*-- Get list address
		Bsr.w	Get_Back_LAdr
		Tst.l	(a2)
		Beq.b	BPD_End
		Move.l	a2,BPD_LAdr
		Bsr.w	Update_BackBuf
	*-- Free old Back
		Move.l	BPD_LAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Back
		Move.l	Mem_BackBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get BytSize
		Subq.l	#8,d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	BPD_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Back address
		Move.l	Mem_BackBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Subq.l	#8,d0			;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Subq	#1,d7			;+
		Move	d7,(a1)+		;+
		Addq	#1,d7
		Moveq.l	#100-8-1,d0	;BackHeader
	BPD_CGL:Move.b	(a2)+,(a1)+
		Dbf	d0,BPD_CGL
	*-- Copy from start to end
		Moveq.l	#0,d6
	BPD_C2L:Addq	#1,d6			;Count Pieces
		Cmp	d7,d6			;Count=>Total?
		Bgt.b	BPD_C2E			;Yes, end
		Move.l	(a2)+,d0		;Piecedata
		Move.l	(a2)+,d1		;+
		Cmp	Cur_BackPiece(pc),d6	;Which piece to delete
		Beq.b	BPD_Skp
		Move.l	d0,(a1)+
		Move.l	d1,(a1)+
	BPD_Skp:Bra.b	BPD_C2L			;Loop
	BPD_C2E:Clr	Cur_BackPiece
		Bsr.w	Draw_Back
	BPD_End:Rts
	BPD_LAdr:Dc.l	0
*---------------
Back_ToTop:	Move	Cur_BackPiece(pc),BD_From
		Beq.b	BTT_End
		Bsr.w	Get_Back_LAdr
		Move.l	(a2),a0
		Move	6(a0),BD_To
		Move	BD_To(pc),Cur_BackPiece
		Addq	#1,BD_To
		Bsr.w	Back_Depth
		Bsr.w	Draw_Back
	BTT_End:Rts
*---------------
Back_TopWard:	Bsr.w	Find_Next_Over
		Move	Cur_BackPiece(pc),BD_From
		Beq.b	BBW_End
		Move	Back_ToPiece(pc),BD_To
		Bmi.b	BBW_End
		Move	BD_To(pc),Cur_BackPiece
		Subq	#1,Cur_BackPiece
		Bsr.w	Back_Depth
		Bsr.w	Draw_Back
	BBW_End:Rts
*---------------
Back_BottomWard:Bsr.w	Find_Prev_Over
		Move	Cur_BackPiece(pc),BD_From
		Beq.b	BTW_End
		Move	Back_ToPiece(pc),BD_To
		Bmi.b	BTW_End
		Move	BD_To(pc),Cur_BackPiece
		Bsr.w	Back_Depth
		Bsr.w	Draw_Back
	BTW_End:Rts
*---------------
Back_ToBottom:	Move	Cur_BackPiece(pc),BD_From
		Beq.b	BTB_End
		Move	#1,BD_To
		Move	BD_To(pc),Cur_BackPiece
		Bsr.w	Back_Depth
		Bsr.w	Draw_Back
	BTB_End:Rts
*---------------
Back_Undo:	Lea	Back_Info(pc),a3
		Bsr.w	Unit_Undo
		Bra.w	Draw_Back
*---------------
Back_Coll:	Clr	Cur_BackPiece
		Bra.w	Draw_Back
*---------------
Back_PlayScreen:Move	#'BK',Play_Mode
		Jsr	Get_Screen_Mem	;###
		Jsr	Erase		;###
		Jsr	Leave_Dos	;###
		Jsr	Chip		;Feed Custom Chips	###
		Jsr	Game_Palette	;###

	BPS_M1:	Jsr	Game_Background	;###
		Btst	#6,$bfe001
		Bne.b	BPS_M1

	BPS_M3:	Moveq.l	#127,d0
	BPS_M2:	Btst	#6,$bfe001
		Beq.b	BPS_M3
		Dbf	d0,BPS_M2

		Jsr	Enter_Dos	;###
		Jsr	Free_Play_Mem	;###
	BPS_End:Rts
*---------------
Check_Back:	Lea	Back_Jump(pc),a0
		Move	BackList_Len(pc),d0
		Beq.b	CB_NoUn
	*-- Find current Background, and check if it exists
		Bsr.w	Get_Back_LAdr
		Tst.l	(a2)		;Any Background?
		Beq.b	CB_NoGr		;No
		Lea	Back_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CB_NoUn:Lea	Back_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CB_NoGr:Lea	Back_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
Back_Depth:	;(Move Piece at position BD_From.W to position BD_To.W)
		Move	BD_From(pc),d0
		Cmp	BD_To(pc),d0
		Beq.w	BD_End
	*-- Get list address (A2)
		Bsr.w	Get_Back_LAdr
		Tst.l	(a2)
		Beq.w	BD_End
		Move.l	a2,BD_LAdr
		Bsr.w	Update_BackBuf
	*-- Free old Back
		Move.l	BD_LAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Back
		Move.l	Mem_BackBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get BytSize
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	BD_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Back address
		Move.l	Mem_BackBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,(a1)+		;BytSize
		Move	(a2)+,d7		;Total
		Move	d7,(a1)+
		Moveq.l	#100-8-1,d0	;BackHeader
	BD_CGL:	Move.b	(a2)+,(a1)+
		Dbf	d0,BD_CGL
	*-- Copy Pieces
		Moveq.l	#0,d6			;Counter for From/To
		
	BD_Lop:	Addq	#1,d6			;Count Pieces
		Cmp	BD_From(pc),d6		;Is this the From-Piece
		Beq.b	BD_Skp			;Yes, skip it
		Cmp	BD_To(pc),d6		;Is this the To-Piece
		Beq.b	BD_Ins			;Yes, insert From-Piece
		
	BD_Nxt:	Cmp	d7,d6			;More Pieces?
		Bgt.b	BD_End			;No, end
		Move.l	(a2)+,(a1)+		;Copy Piecedata
		Move.l	(a2)+,(a1)+		;+
		Bra.b	BD_Lop			;Loop

	BD_Skp:	Addq	#8,a2			;Skip Piece
		Bra.b	BD_Lop			;Loop

	BD_Ins:	Move.l	Mem_BackBuf(pc),a3	;Get buffer address
		Add	#100,a3			;Add BackHeader
		Clr.l	d0			;Find From-Piece
		Move	BD_From(pc),d0		;+
		Subq	#1,d0			;+
		Lsl.l	#3,d0			;+
		Add.l	d0,a3			;+
		Move.l	(a3)+,(a1)+		;Copy From-Piece
		Move.l	(a3)+,(a1)+		;+
		Bra.b	BD_Nxt			;Loop
	BD_End:	Rts
	BD_LAdr:Dc.l	0
	BD_From:Dc	0
	BD_To:	Dc	0
*---------------
Back_Back:
	*-- Are we picking a Piece?
		Lea	GBack_Pick(pc),a0
		Btst	#0,4(a0)
		Bne.w	PickBackPiece
	*-- Are we editing collision?
		Lea	GBack_Coll(pc),a0
		Btst	#0,4(a0)
		Bne.w	PickBackPiece
	*-- Get list address (A2)
		Bsr.w	Get_Back_LAdr
		Tst.l	(a2)
		Beq.w	BB_End
		Move.l	a2,BB_LAdr
		Bsr.w	Update_BackBuf
	*-- Free old Back
		Move.l	BB_LAdr(pc),a4
		Bsr.w	Free_Unit
	*-- Allocate new space for Back
		Move.l	Mem_BackBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get BytSize
		Addq.l	#8,d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	BB_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Back address
		Move.l	Mem_BackBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Addq.l	#8,d0
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Addq	#1,d7			;+
		Move	d7,(a1)+		;+
		Moveq.l	#100-8-1,d0	;BackHeader
	BB_CGL:	Move.b	(a2)+,(a1)+
		Dbf	d0,BB_CGL
	*-- Copy from start to edit point
		Moveq.l	#0,d6
	BB_C2L:	Move	d7,d0
		Subq	#1,d0
		Cmp	d0,d6			;Where to put it!
		Beq.b	BB_C2E
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Addq	#1,d6			;Count Pieces
		Bra.b	BB_C2L			;Loop
	*-- Add Piece
	BB_C2E:	Move	Cur_Piec(pc),(a1)+	;Piece
		Move	BP_X,d2			;X-Offset ###
		Sub	#3,d2			;+
		Add	DB_ScrollX(pc),d2	;+
		Move	d2,(a1)+		;+
		Move	BP_Y,d2			;Y-Offset ###
		Sub	#48,d2			;+
		Add	DB_ScrollY(pc),d2	;+
		Move	d2,(a1)+		;+
	*-- Find current piece
		Move	Cur_Piec(pc),d2
		Move.l	Mem_PiecList(pc),a3
		Ext.l	d2
		Lsl.l	#5,d2			;Multiply by 32		
		Add.l	d2,a3
		Move.l	(a3),a3			;Get PieceData Address
		Move.b	18(a3),d2		;Default Flags.
	*-- Flip Y ?
		Bclr	#5,d2
		Lea	GBack_FlipY(pc),a0
		Btst	#0,4(a0)
		Beq.b	BB_NFlY
		Bset	#5,d2
	BB_NFlY:	
		Move.b	d2,(a1)+		;Flags
		Move.b	19(a3),(a1)+		;Value
	*-- Copy from edit point to end
		Addq	#1,d6
	BB_C4L:	Cmp	d7,d6			;Count=>Total?
		Bge.b	BB_C4E			;Yes, end
		Move.l	(a2)+,(a1)+		;Piecedata
		Move.l	(a2)+,(a1)+		;+
		Addq	#1,d6			;Count Pieces
		Bra.b	BB_C4L			;Loop
	BB_C4E:
	*-- Drop Piece bob
		Lea	Mem_SaveBack(pc),a5
		Bsr.w	Free_Mem
		Clr	BP_SaveFlg
	BB_End:	Rts
	BB_LAdr:Dc.l	0
*---------------
Find_Next_Over:	Move	#1,Back_NxtFlg
		Bra.b	FXO_St
Find_Prev_Over:	Clr	Back_NxtFlg
	FXO_St:
	*-- Get list address (A2)
		Bsr.w	Get_Back_LAdr
		Tst.l	(a2)
		Beq.b	FXO_End
		Move.l	(a2),a2
		Move	6(a2),Back_Total
	*-- Find current piece
		Clr.l	d2
		Move	Cur_BackPiece(pc),d2
		Beq.b	FXO_End
		Subq	#1,d2
		Add	#100,a2		;Add BackHeader
		Lsl.l	#3,d2
		Add.l	d2,a2
		Move	(a2),d2
		Move.l	Mem_PiecList(pc),a3
		Ext.l	d2
		Lsl.l	#5,d2		;Multiply by 32		
		Add.l	d2,a3
		Move.l	(a3),a3		;Get PieceData Adr

		Move	2(a2),Back_X1
		Move	4(a2),Back_Y1
		Move	2(a2),Back_X2
		Move	4(a2),Back_Y2
		Move	6(a3),d0
		Add	d0,Back_X2
		Move	8(a3),d0
		Add	d0,Back_Y2

		Move	Back_NxtFlg(pc),d0
		Beq.b	FXO_Pr
		
		Move	Cur_BackPiece(pc),d7
	FXO_LpN:Addq.l	#8,a2
		Addq	#1,d7
		Cmp	Back_Total(pc),d7
		Bgt.b	FXO_Ok
		Bsr.b	Overlapping
		Beq.b	FXO_NOk
		Bra.b	FXO_LpN

	FXO_End:Move	#-1,Back_ToPiece
		Rts

	FXO_PEd:Moveq.l	#1,d7
	FXO_Ok:	Move	d7,Back_ToPiece
		Rts

	FXO_NOk:Addq	#1,d7
		Move	d7,Back_ToPiece
		Rts

	FXO_Pr:	Move	Cur_BackPiece(pc),d7
	FXO_LpP:Subq.l	#8,a2
		Subq	#1,d7
		Beq.b	FXO_PEd
		Bsr.b	Overlapping
		Beq.b	FXO_Ok
		Bra.b	FXO_LpP
*---------------
Back_ToPiece:	Dc	0
Back_Total:	Dc	0
Back_NxtFlg:	Dc	0
Back_X1:	Dc	0
Back_Y1:	Dc	0
Back_X2:	Dc	0
Back_Y2:	Dc	0
*---------------
Overlapping:	Move	2(a2),d0
		Move	4(a2),d1
	*-- Find current piece
		Clr.l	d2
		Move	(a2),d2
		Move.l	Mem_PiecList(pc),a3
		Ext.l	d2
		Lsl.l	#5,d2		;Multiply by 32		
		Add.l	d2,a3
		Move.l	(a3),a3		;Get PieceData Address
	*-- Calculate Piece X2,Y2
		Move	d0,d2
		Move	d1,d3
		Add	6(a3),d2
		Add	8(a3),d3
	*-- ThisLowerRight < CurUpperLeft ?
		Cmp	Back_X1(pc),d2
		Blt.b	FXO_No
		Cmp	Back_Y1(pc),d3
		Blt.b	FXO_No
	*-- ThisUpperLeft > CurLowerRight ?
		Cmp	Back_X2(pc),d0
		Bgt.b	FXO_No
		Cmp	Back_Y2(pc),d1
		Bgt.b	FXO_No
	*-- No overlapping
		Clr.l	d6
		Rts
	*-- Overlapping!
	FXO_No:	Moveq.l	#-1,d6
		Rts
*---------------
Draw_Back:	Bsr.w	Get_Back_LAdr
		Tst.l	(a2)
		Beq.w	DB_Fin
	*-- Clear gfx area
		Lea	Back_Gfx(pc),a4
		Lea	BackLay(pc),a5
		Bsr.w	Calc_Coord

		Lea	BackLay(pc),a5	;***
		Move.l	GfxBase(pc),a6
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetAPen(a6)

		Move.l	a3,a1
		Move	X1(pc),d0
		Move	Y1(pc),d1
		Move	X2(pc),d2
		Move	Y2(pc),d3
		Jsr	RectFill(a6)

		Bsr.w	Get_Back_LAdr
		Move.l	(a2),a0
	*-- Get number of Pieces, and first Piece address (A1)
		Move.l	a0,a1
		Move	6(a1),DB_Pieces
		Add	#100,a1		;Add BackHeader
		Move.l	a1,DB_Address
		Clr	DB_PieceCnt
	*-- Draw Background
	DB_Nxt:	Addq	#1,DB_PieceCnt
		Subq	#1,DB_Pieces
		Bmi.w	DB_Fin
		Move.l	DB_Address(pc),a1
		Move	(a1)+,DB_Piece
		Move	(a1)+,DB_X
		Move	(a1)+,DB_Y
		Move.b	(a1)+,DB_Flags
		Move.b	(a1)+,DB_Value
		Move.l	a1,DB_Address
	*-- Find current piece, and check if it exists
		Move	DB_Piece(pc),d0
		Move.l	Mem_PiecList(pc),a2
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	DB_None		;No
		Move.l	(a2),a2		;Get PieceData Address
	*-- Get size & pos
		Move	#1,DB_ZoomF
		Move	6(a2),d4	;SizeX
		Mulu	DB_ZoomF(pc),d4

		Move	8(a2),d5	;SizeY
		Mulu	DB_ZoomF(pc),d5

		Move	DB_X(pc),d2
		Mulu	DB_ZoomF(pc),d2
		Add	X1(pc),d2
		Sub	DB_ScrollX(pc),d2

		Move	DB_Y(pc),d3
		Mulu	DB_ZoomF(pc),d3
		Add	Y1(pc),d3
		Sub	DB_ScrollY(pc),d3
	*-- Clip top & left edge of Piece
		Clr	DB_OffX
		Move	X1(pc),d0
		Sub	d2,d0
		Blt.b	DB_NUnX
		Move	d0,DB_OffX
		Add	d0,d2
		Sub	d0,d4
		Ble.w	DB_Out
	DB_NUnX:
		Clr	DB_OffY
		Move	Y1(pc),d0
		Sub	d3,d0
		Blt.b	DB_NUnY
		Move	d0,DB_OffY
		Add	d0,d3
		Sub	d0,d5
		Ble.w	DB_Out
	DB_NUnY:
		Move	DB_OffX(pc),d0
		Divu	DB_ZoomF(pc),d0
		Move	d0,DB_OffX
		Move	DB_OffY(pc),d0
		Divu	DB_ZoomF(pc),d0
		Move	d0,DB_OffY
	*-- Clip bottom & right edge of Piece
		Move	d2,d0
		Add	d4,d0
		Sub	X2(pc),d0
		Ble.b	DB_NOvX
		Sub	d0,d4
		Addq	#1,d4
		Ble.w	DB_Out
	DB_NOvX:
		Move	d3,d0
		Add	d5,d0
		Sub	Y2(pc),d0
		Ble.b	DB_NOvY
		Sub	d0,d5
		Addq	#1,d5
		Ble.w	DB_Out
	DB_NOvY:
	*-- Write data to Piec_BM
		Btst	#5,DB_Flags
		Beq.b	DB_NFl
		Movem.l	d0-d7/a0-a6,-(a7)
		Move	DB_Piece(pc),DB_FlpPc
		Jsr	DB_FlipY	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Move.l	Mem_FlipBuf,a2	;###
	DB_NFl:
		Lea	Piec_BM(pc),a1
		Move	14(a2),(a1)+	;Write BytWidth to BM
		Move	08(a2),(a1)+	;Write SizeY to BM
		Move	10(a2),(a1)+	;Write Depth to BM
		Clr	(a1)+
		Move.l	a2,a0		;Write Bpls to BM
		Add	#28,a0
		Move	10(a2),d0	;Depth
		Subq	#1,d0
	DB_BplL:Move.l	a0,(a1)+
		Add	12(a2),a0	;Add BplSize
		Dbf	d0,DB_BplL

		Lea	GBack_Coll(pc),a0
		Btst	#0,4(a0)
		Bne.b	DB_Coll
	*-- Get Mask address
		Move.l	a2,d7		;Address of BltMask
		Add.l	24(a2),d7	;+ ok
	*-- Blit Piece
		Move	Cur_BackPiece(pc),d0
		Cmp	DB_PieceCnt(pc),d0
		Beq.w	DB_Selc
		Lea	Piec_BM(pc),a0
		Move.l	a3,a1
		Move	DB_OffX(pc),d0	;OffsetX
		Move	DB_OffY(pc),d1	;OffsetY
		Move.l	d7,a2
		Move	#$e2,d6		;Minterm
		Jsr	BltMaskBitMapRastPort(a6)
	DB_None:
	DB_Out:
	DB_End:	Bra.w	DB_Nxt
	DB_Fin:	Rts

	DB_Coll:
	*-- Get Mask address
		Move.l	a2,d7		;Address of ColMask
		Add.l	20(a2),d7	;+ ok
	*-- Decide Color
		Move.b	DB_Flags(pc),d1
		Lsr.b	#6,d1

		Cmp.b	#0,d1
		Bne.b	DB_No0
		Move	BkCol(pc),d0
	DB_No0:
		Cmp.b	#1,d1
		Bne.b	DB_No1
		Move	HiCol(pc),d0
	DB_No1:
		Cmp.b	#2,d1
		Bne.b	DB_No2
		Move	MdCol(pc),d0
	DB_No2:
		Move.l	a3,a1
		Jsr	SetAPen(a6)
		Bra.w	DB_Mask

DB_FlipY:
	*-- Free old buffer
		Lea	Mem_FlipBuf,a5
		Bsr.w	Free_Mem
	*-- Find current Unit, and check if it exists
		Move.l	Mem_PiecList(pc),a2
		Clr.l	d0
		Move	DB_FlpPc(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	DFY_End
		Move.l	(a2),a4
	*-- Allocate new Unit buffer
		Lea	Mem_FlipBuf,a5
		Move.l	2(a4),d0
		Bsr.w	Alloc_Chip_Mem
		Beq.w	Mess_CMemErr
	*-- Copy Unit to buffer
		Move.l	Mem_FlipBuf,a1	;Get Mem_UnitBuf
		Move.l	2(a4),d0
		Move.l	a4,a5
		Subq	#1,d0
	UUBF_CLp:Move.b	(a4)+,(a1)+
		Dbf	d0,UUBF_CLp

		Move.l	a5,a2
		Move.l	Mem_FlipBuf,a4	;###
		Move.l	a2,a3
		Move	10(a2),d7	;Depth
		Addq	#1,d7
		Add	#28,a3		;Header
		Add	#28,a4		;Header
	DFY_DLp:Add	12(a2),a3	;BplSize
		Move	8(a2),d1	;YSize
	DFY_LLp:Sub	14(a2),a3	;ByteWidth
		Move	14(a2),d0
	DFY_WLp:Move	(a3)+,(a4)+
		Subq	#2,d0
		Bgt.b	DFY_WLp
		Sub	14(a2),a3	;ByteWidth
		Subq	#1,d1
		Bne.b	DFY_LLp
		Add	12(a2),a3	;BplSize
		Dbf	d7,DFY_DLp
	DFY_End:Rts
	DB_FlpPc:	Dc	0


	DB_Selc:Move	HiCol(pc),d0
		Move.l	a3,a1
		Jsr	SetAPen(a6)
	*-- Blit Mask
	DB_Mask:Moveq.l	#0,d0
		Move.l	a3,a1
		Jsr	SetDrMd(a6)
		Lea	Piec_BM(pc),a5
		Move.l	d7,a0		;Src
		Move.l	a3,a1		;DstRP
		Move	(a5),d1		;SrcMod
		Move	DB_OffX(pc),d0	;SrcX
		Move	DB_OffY(pc),d7	;OffsetY
		Mulu	d1,d7
		Add	d7,a0
		Jsr	BltTemplate(a6)
		Bra.w	DB_End

DB_ZoomF:	Dc	0
DB_ScrollX:	Dc	0
DB_ScrollY:	Dc	0
DB_OffX:	Dc	0
DB_OffY:	Dc	0
DB_BytWidth:	Dc	0
DB_BytSize:	Dc	0
DB_PlaneSize:	Dc	0

DB_PieceCnt:	Dc	0
DB_Pieces:	Dc	0
DB_Address:	Dc.l	0

DB_Piece:	Dc	0
DB_X:		Dc	0
DB_Y:		Dc	0
DB_Flags:	Dc.b	0
DB_Value:	Dc.b	0
*---------------
Back_OffsetXY:	Lea	Back_Prop_X(pc),a0
		Clr.l	d0
		Move	6(a0),d0
		Move	Back_Size_X(pc),d1
		Subq	#1,d1
		Mulu	d1,d0
		Swap	d0
		Move	d0,DB_ScrollX
		
		Lea	Back_Prop_Y(pc),a0
		Clr.l	d0
		Move	8(a0),d0
		Move	Back_Size_Y(pc),d1
		Subq	#1,d1
		Mulu	d1,d0
		Swap	d0
		Move	d0,DB_ScrollY

		Bra.w	Draw_Back
*---------------
Upd_Back_Props:
	*-- Calculate frame sizes
		Lea	BackLay(pc),a5
		Lea	Back_Gfx(pc),a4
		Bsr.w	Calc_Coord
		Move	X2(pc),d0
		Sub	X1(pc),d0
		Move	d0,BO_SizeX
		Move	Y2(pc),d0
		Sub	Y1(pc),d0
		Move	d0,BO_SizeY

		Move	Back_Size_X(pc),d0
		Cmp	BO_SizeX(pc),d0
		Bgt.b	BO_OkX
		Lea	Back_Prop_X(pc),a0
		Move	#$ffff,2(a0)
		Clr	6(a0)
		Bra.b	BO_NoOverX

	BO_OkX:	Lea	Back_Prop_X(pc),a0
		Clr.l	d0
		Move	BO_SizeX(pc),d0
		Swap	d0
		Divu	Back_Size_X(pc),d0
		And.l	#$0000ffff,d0
		;Divu	DrawRes(pc),d0
		Move	d0,2(a0)

		Move	6(a0),d1
		And.l	#$ffff,d0
		And.l	#$ffff,d1
		Add.l	d0,d1
		Swap	d1
		Tst	d1
		Beq.b	BO_NoOverX
		Swap	d1
		Sub	d1,6(a0)
	BO_NoOverX:	
		Move	Back_Size_Y(pc),d0
		Cmp	BO_SizeY(pc),d0
		Bgt.b	BO_OkY
		Lea	Back_Prop_Y(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Bra.b	BO_NoOverY

	BO_OkY:	Lea	Back_Prop_Y(pc),a0
		Clr.l	d0
		Move	BO_SizeY(pc),d0
		Swap	d0
		Divu	Back_Size_Y(pc),d0
		And.l	#$0000ffff,d0
		;Divu	DrawRes(pc),d0
		Move	d0,4(a0)

		Move	8(a0),d1
		And.l	#$ffff,d0
		And.l	#$ffff,d1
		Add.l	d0,d1
		Swap	d1
		Tst	d1
		Beq.b	BO_NoOverY
		Swap	d1
		Sub	d1,8(a0)
	BO_NoOverY:
		Rts

	BO_Empt:Lea	Back_Prop_X(pc),a0
		Move	#$ffff,2(a0)
		Clr	6(a0)
		Lea	Back_Prop_Y(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Rts

BO_SizeX:	Dc	0
BO_SizeY:	Dc	0
Back_Size_X:	Dc	320*24
Back_Size_Y:	Dc	256
*---------------
PickBackPiece:	Bsr.w	Get_Back_LAdr
		Tst.l	(a2)
		Beq.w	PBP_Fin
		Move.l	(a2),a0
	*-- Get number of Pieces, and first Piece address (A1)
		Move	6(a0),PBP_Pieces
		Move.l	a0,a1
		Add	#100,a1		;Add BackHeader
		Move.l	a1,PBP_Address
	*-- Find coordinates of gfx area
		Lea	Back_Gfx(pc),a4
		Lea	BackLay(pc),a5
		Bsr.w	Calc_Coord
		Clr	PBP_PieceCnt
		Clr	Cur_BackPiece
	*-- Search through Pieces
	PBP_Nxt:Addq	#1,PBP_PieceCnt
		Subq	#1,PBP_Pieces
		Bmi.w	PBP_Fin
		Move.l	PBP_Address(pc),a1
		Move	(a1)+,PBP_Piece
		Move	(a1)+,PBP_X1
		Move	(a1)+,PBP_Y1
		Move.b	(a1)+,PBP_Flags
		Move.b	(a1)+,PBP_Value
		Move.l	a1,PBP_Address

		Move	PBP_Piece(pc),d0
		Moveq.l	#0,d1		;***
	*-- Find current piece, and check if it exists
		Move.l	Mem_PiecList(pc),a2
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	PBP_None	;No
		Move.l	(a2),a2		;Get PieceData Address
		Move	PBP_X1(pc),d0
		Add	6(a2),d0
		Move	d0,PBP_X2
		Move	PBP_Y1(pc),d0
		Add	8(a2),d0
		Move	d0,PBP_Y2
		Move	LayX(pc),d0
		Add	DB_ScrollX(pc),d0
		Sub	X1(pc),d0
		Cmp	PBP_X1(pc),d0
		Blt.b	PBP_None
		Cmp	PBP_X2(pc),d0
		Bgt.b	PBP_None

		Sub	PBP_X1(pc),d0
		Move	d0,PBP_XOff

		Move	LayY(pc),d0
		Add	DB_ScrollY(pc),d0
		Sub	Y1(pc),d0
		Cmp	PBP_Y1(pc),d0
		Blt.b	PBP_None
		Cmp	PBP_Y2(pc),d0
		Bgt.b	PBP_None

		Sub	PBP_Y1(pc),d0
		Move	d0,PBP_YOff

		Move	Cur_BackPiece(pc),d0
		Bne.b	PBP_NAl
		Move	PBP_PieceCnt(pc),Cur_BackPiece
	PBP_NAl:
		Btst	#5,PBP_Flags
		Beq.b	PBP_NFl
		Move	PBP_Piece(pc),DB_FlpPc
		Bsr.w	DB_FlipY
		Move.l	Mem_FlipBuf,a2	;###
	PBP_NFl:
		Move	PBP_XOff(pc),d0
		Move	PBP_YOff(pc),d1
		Moveq.l	#0,d2
		Jsr	CPiec_Pixel_Tst
		Tst	d7
		Ble.b	PBP_None

		Move	PBP_PieceCnt(pc),Cur_BackPiece

	PBP_None:
	PBP_Out:
	PBP_End:Bra.w	PBP_Nxt
	PBP_Fin:
	*-- Are we editing Collision?
		Lea	GBack_Coll(pc),a0
		Btst	#0,4(a0)
		Beq.b	PBP_NCl

		Bsr.w	Get_Back_LAdr
		Or	#2,4(a2)		;Set NeedsUpdate

		Move.l	(a2),a3
		Add	#100,a3		;Add BackHeader
		Clr.l	d0
		Move	Cur_BackPiece(pc),d0
		Beq.b	PBP_NCl
		Subq	#1,d0
		Lsl.l	#3,d0
		Add.l	d0,a3

		Move.b	6(a3),d0
		Lsr.b	#6,d0
		Subq.b	#1,d0
		Bpl.b	PBP_NOv
		Moveq.l	#2,d0
	PBP_NOv:Lsl.b	#6,d0

		Move.b	6(a3),d1
		And.b	#%00111111,d1
		Or.b	d0,d1
		Move.b	d1,6(a3)
		Clr	Cur_BackPiece

	PBP_NCl:Move	#'BA',Last_Pick
		Bsr.w	Draw_Back
	*-- Show piece in piece window if opened
		Bsr.w	Get_Back_LAdr
		Move.l	(a2),a2
	*-- Find current piece
		Clr.l	d2
		Move	Cur_BackPiece(pc),d2
		Beq.b	PBP_NDr
		Subq	#1,d2
		Add	#100,a2		;Add BackHeader
		Lsl.l	#3,d2
		Add.l	d2,a2
		Move	(a2),Cur_Piec

		Move.b	6(a2),d0		;Check FlipY
		Lea	GBack_FlipY(pc),a4
		Bclr	#0,4(a4)
		Btst	#5,d0
		Beq.b	PBP_NOn
		Bset	#0,4(a4)
	PBP_NOn:Moveq.l	#3,d7
		Lea	BackLay,a5
		Jsr	Draw_Some

		Jsr	Change_Piec	;###

	PBP_NDr:Rts

Last_Pick:	Dc	'BA'

PBP_XOff:	Dc	0
PBP_YOff:	Dc	0

Cur_BackPiece:	Dc	0

PBP_PieceCnt:	Dc	0
PBP_Pieces:	Dc	0
PBP_Address:	Dc.l	0

PBP_Flags:	Dc.b	0
PBP_Value:	Dc.b	0
PBP_Piece:	Dc	0
PBP_X1:		Dc	0
PBP_Y1:		Dc	0
PBP_X2:		Dc	0
PBP_Y2:		Dc	0
*---------------
Back_Load:	Move.l	BackList(pc),a4
		Move.l	(a4),a4
		Move	Cur_Back(pc),d4
		Move.l	#'BACK',d0
		Bsr.w	Load_Unit
		Bsr.b	Load_BackPieces
	*-- Show piece in piece window if opened
		Bra.b	Change_Back
*---------------
Load_BackPieces:
	*-- Get list address (A2)
		Bsr.w	Get_Back_LAdr
		Tst.l	(a2)
		Beq.b	LBP_End
	*-- Get Address
		Move.l	(a2),a0		;Get Back address
	*-- Get number of Pieces, and first Piece address (A1)
		Move.l	a0,a1
		Move	6(a1),d4
		Add	#100,a1		;Add BackHeader
	*-- Loop through Pieces
	LBP_Nxt:Subq	#1,d4
		Bmi.b	LBP_End
		Movem.l	a0-a6/d0-d7,-(a7)
		Move.l	Mem_PiecList(pc),a2
		Clr.l	d0
		Move	(a1),d0
		Move	d0,d7
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Bne.b	LBP_Ok
		Move	d7,Cur_Piec
		Jsr	Piec_Load	;###
	LBP_Ok:	Movem.l	(a7)+,a0-a6/d0-d7
		Addq	#8,a1
		Bra.b	LBP_Nxt
	LBP_End:Rts
*---------------
Change_Back:	Bsr.b	Upd_BackNameD
		Bsr.b	Upd_BackNameG
		Lea	Back_GfxUpd(pc),a4
		Lea	BackLay(pc),a5
		Bsr.w	Draw_All
		Lea	Back_Info(pc),a3
		Bra.w	Upd_SelcUnit
*---------------
Update_BackBuf:	Lea	Back_Info(pc),a3
		Jmp	Update_UnitBuf	;###
*---------------
Upd_BackNameD:	;(Update current Back name)
		Lea	Back_NameUpd(pc),a4
			Lea	GScrl_BackName(pc),a5
	;		Lea	GGrid_BackName(pc),a3
		Clr.l	34(a4)
			Clr.l	(a5)
	;		Clr.l	(a3)
		Move	BackList_Len(pc),d7
		Beq.b	UBaN_Ed
		Bsr.b	Get_Back_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	UBaN_Ed
		Addq	#8,a2
		Move.l	a2,34(a4)
			Move.l	a2,(a5)
	;		Move.l	a2,(a3)
	UBaN_Ed:Rts
*---------------
Upd_BackNameG:	Lea	ScrlLay(pc),a5
		Lea	DrawList_Scrl(pc),a4
		Moveq.l	#13,d7
		Bsr.w	Draw_Some
		Lea	BackLay(pc),a5
		Lea	Back_NameUpd(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Get_Back_LAdr:	Move.l	Mem_BackList(pc),a2
		Clr.l	d0
		Move	Cur_Back(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
DrawList_Back:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Background8T
		
		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Back_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Back_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Back_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-21,025

		Dc	'RO'
		Dc.l	Upd_BackNameD

Back_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Back_Name
		Dc	'RC',049,015,-44,023
		Dc	'TX',051,022,-101,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Back_Info,Unit_BrowseUp
		Dc	'BX',-41,015,-33,023
		Dc	'IM',-39,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Back_Info,Unit_BrowseDn
		Dc	'BX',-32,015,-24,023
		Dc	'IM',-30,018,3,Im_DArr-Im

;		Dc	'GD'
;		Dc.l	$02010063,0,Back_Grid
;		Dc	'BX',-33,013,-21,025
;		Dc	'IM',-31,015,9,Im_Grid-Im

		Dc	'GD'
		Dc.l	$02010050,0,Back_Scroll
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_Scroll-Im

		Dc	'BX',000,028,-01,044

;GBack_Piece:	Dc	'GD'
;		Dc.l	$02010687,Back_Excl_PiAn,0	;Back_Piece
;		Dc	'BX',003,030,015,042
;		Dc	'IM',005,032,9,Im_Piece-Im
;
;GBack_Anim:	Dc	'GD'
;		Dc.l	$02010688,Back_Excl_PiAn,0	;Back_Anim
;		Dc	'BX',016,030,028,042
;		Dc	'IM',018,032,9,Im_Anim-Im

GBack_Pick:	Dc	'GD'
		Dc.l	$02010614,Back_Excl,Back_PiecePick
		Dc	'BX',003,030,015,042
		Dc	'IM',005,032,9,Im_Pick-Im

		Dc	'GD'
		Dc.l	$02010015,0,Back_PieceDel
		Dc	'BX',020,030,032,042
		Dc	'IM',022,032,9,Im_ClrClips-Im

		Dc	'GD'
		Dc.l	$02010037,0,Back_ToTop
		Dc	'BX',037,030,049,042
		Dc	'IM',039,032,9,Im_ToTop-Im

		Dc	'GD'
		Dc.l	$02010038,0,Back_TopWard
		Dc	'BX',050,030,062,042
		Dc	'IM',052,032,9,Im_TopWard-Im

		Dc	'GD'
		Dc.l	$02010039,0,Back_BottomWard
		Dc	'BX',067,030,079,042
		Dc	'IM',069,032,9,Im_BottomWard-Im

		Dc	'GD'
		Dc.l	$0201003a,0,Back_ToBottom
		Dc	'BX',080,030,092,042
		Dc	'IM',082,032,9,Im_ToBottom-Im

GBack_FlipY:	Dc	'GD'
		Dc.l	$0201021f,0,0
		Dc	'BX',097,030,109,042
		Dc	'IM',099,032,9,Im_FlipY-Im

		Dc	'GD'
		Dc.l	$0201000b,0,Back_Undo
		Dc	'BX',114,030,126,042
		Dc	'IM',116,032,9,Im_Undo-Im

;GBackZoom:	Dc	'GD'
;		Dc.l	$02010209,0,0	;Pict_Zoom
;		Dc	'BX',161,030,173,042
;		Dc	'IM',163,032,9,Im_Zoom-Im
;
;		Dc	'BX',174,030,207,042
;
;		Dc	'GD'
;		Dc.l	$02030235,0,0
;		Dc	'RC',176,032,185,040
;Back_ZFactUpd:	Dc	'TX',179,039,-01,5
;		Dc.l	Back_ZFactT
;
;		Dc	'GD'
;		Dc.l	$02010034,0,0	;Pict_ZoomMinus
;		Dc	'BX',188,032,196,040
;		Dc	'IM',190,036,1,Im_Minus-Im
;		
;		Dc	'GD'
;		Dc.l	$02010033,0,0	;Pict_ZoomPlus
;		Dc	'BX',197,032,205,040
;		Dc	'IM',199,034,5,Im_Plus-Im

GBack_Coll:	Dc	'GD'
		Dc.l	$02010662,Back_Excl,Back_Coll
		Dc	'BX',131,030,143,042
		Dc	'IM',133,032,9,Im_Collision-Im

		Dc	'GD'
		Dc.l	$0201000e,0,Back_PlayScreen
		Dc	'BX',148,030,160,042
		Dc	'IM',150,032,9,Im_PlayScr-Im

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

		Dc	'RO'
		Dc.l	Upd_Back_Props

		Dc	'GD'
		Dc.l	$02020000,Back_Prop_Y,Back_OffsetXY
		Dc	'BX',-09,045,-01,-10
		Dc	'BX',-07,047,-03,-34

		Dc	'GD'
		Dc.l	$02020000,Back_Prop_X,Back_OffsetXY
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',020,-07,-40,-03

Back_GfxUpd:	Dc	'RO'
		Dc.l	Check_Back

		Dc	'JP'
Back_Jump:	Dc.l	Back_No

Back_Yes:	Dc	'GD'
		Dc.l	$01000000,0,Back_Back
Back_Gfx:	Dc	'DF',003,048,-13,-13
		Dc	'FR',000,045,-10,-10
		Dc	'RO'
		Dc.l	Draw_Back
		Dc	'XX'

Back_No:	Dc	'BX',000,045,-10,-10
		Dc	'TX',003,054,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Back_Load
		Dc	'BX',-37,047,-13,055
		Dc	'TX',-34,054,-01,5
		Dc.l	LoadT
		Dc	'XX'

Back_None:	Dc	'BX',000,045,-10,-10
		Dc	'TX',003,054,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Back_Excl:	Dc.l	GBack_Pick
		Dc.l	GBack_Coll
		Dc.l	0

;Back_Excl_PiAn:	Dc.l	GBack_Piece
;		Dc.l	GBack_Anim
;		Dc.l	0

;Back_ZFactT:	Dc.b	'2',0
;		Even

Back_Prop_X:	Dc.b	%00001010,0
		Dc	8192,0
		Dc	0,0
Back_Prop_Y:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,8192		;KnobX,Y
		Dc	0,0		;PosX,Y
;*---------------
;DrawList_Grid:	Dc	'JS'
;		Dc.l	TitleBar_DL
;		Dc	'TX',016,010,-01,8
;		Dc.l	Grid8T
;		Dc	'TX',052,009,-01,5
;		Dc.l	DashT
;		Dc	'TX',061,009,-93,5
;GGrid_BackName:	Dc.l	0
;
;		Dc	'BX',000,011,-01,-01
;
;		Dc	'TX',003,020,-01,5
;		Dc.l	SizeT
;		Dc	'TX',039,020,-01,5
;		Dc.l	XT
;		Dc	'GD'
;		Dc.l	$02030200,3,0
;		Dc	'RC',046,013,065,021
;		Dc	'TX',049,020,-01,5
;		Dc.l	Grid_XSizeNT
;		Dc	'TX',069,020,-01,5
;		Dc.l	YT
;		Dc	'GD'
;		Dc.l	$02030200,3,0
;		Dc	'RC',076,013,095,021
;		Dc	'TX',079,020,-01,5
;		Dc.l	Grid_YSizeNT
;
;		Dc	'TX',003,030,-01,5
;		Dc.l	OffsetT
;		Dc	'TX',039,030,-01,5
;		Dc.l	XT
;		Dc	'GD'
;		Dc.l	$02030200,3,0
;		Dc	'RC',046,023,065,031
;		Dc	'TX',049,030,-01,5
;		Dc.l	Grid_XOffsNT
;		Dc	'TX',069,030,-01,5
;		Dc.l	YT
;		Dc	'GD'
;		Dc.l	$02030200,3,0
;		Dc	'RC',076,023,095,031
;		Dc	'TX',079,030,-01,5
;		Dc.l	Grid_YOffsNT
;
;		Dc	'GD'
;		Dc.l	$02010000,0,0
;		Dc	'BX',099,018,128,026
;		Dc	'TX',102,025,-01,5
;		Dc.l	PlaceT
;
;		Dc	'TX',132,020,-01,5
;		Dc.l	DrawT
;
;		Dc	'XX'
;
;Grid_XSizeNT:	Dc.b	' 16',0
;Grid_YSizeNT:	Dc.b	' 16',0
;Grid_XOffsNT:	Dc.b	'  0',0
;Grid_YOffsNT:	Dc.b	'  0',0
;
;Grid8T:		Dc.b	'Grid',0
;SizeT:		Dc.b	'SIZE:',0
;;OffsetT:	Dc.b	'OFFSET:',0
;DrawT:		Dc.b	'DRAW:',0
;SnapT:		Dc.b	'SNAP:',0
		Even
*---------------
DrawList_Scrl:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Scroll8T
		Dc	'TX',068,009,-01,5
		Dc.l	DashT
		Dc	'TX',077,009,-93,5
GScrl_BackName:	Dc.l	0

		Dc	'BX',000,011,074,042
		
		Dc	'TX',003,021,-01,8
		Dc.l	MapSize8T

		Dc	'TX',003,029,-01,5
		Dc.l	XT
		Dc	'GD'
		Dc.l	$02030200,5,0
		Dc	'RC',011,022,040,030
		Dc	'TX',014,029,-01,5
		Dc.l	Scrl_XNT
		Dc	'TX',043,029,-01,5
		Dc.l	PixelsT

		Dc	'TX',003,039,-01,5
		Dc.l	YT
		Dc	'GD'
		Dc.l	$02030200,5,0
		Dc	'RC',011,032,040,040
		Dc	'TX',014,039,-01,5
		Dc.l	Scrl_YNT
		Dc	'TX',043,039,-01,5
		Dc.l	PixelsT

		Dc	'BX',075,011,-01,-01

GTull:		Dc	'GD'
		Dc.l	$02030a00,5,Tull
		Dc	'RC',011,062,040,070
		Dc	'TX',014,069,-01,5
		Dc.l	Scrl_SpeedNT

		Dc	'TX',078,021,-01,8
		Dc.l	Controller8T

GScrl_Up:	Dc	'GD'
		Dc.l	$02010600,Scrl_Dir_Excl,0
		Dc	'BX',078,022,090,034
		Dc	'IM',080,024,9,Im_Up-Im

GScrl_Down:	Dc	'GD'
		Dc.l	$02010600,Scrl_Dir_Excl,0
		Dc	'BX',091,022,103,034
		Dc	'IM',093,024,9,Im_Down-Im

GScrl_Left:	Dc	'GD'
		Dc.l	$02010600,Scrl_Dir_Excl,0
		Dc	'BX',104,022,116,034
		Dc	'IM',106,026,5,Im_Backward-Im

GScrl_Right:	Dc	'GD'
		Dc.l	$02010600,Scrl_Dir_Excl,0
		Dc	'BX',117,022,129,034
		Dc	'IM',119,026,5,Im_Forward-Im

		Dc	'XX'
Scrl_XNT:	Dc.b	'    0',0
Scrl_YNT:	Dc.b	'    0',0
Scrl_SpeedNT:	Dc.b	'    0',0

		Even

Scrl_Dir_Excl:	Dc.l	GScrl_Up
		Dc.l	GScrl_Down
		Dc.l	GScrl_Left
		Dc.l	GScrl_Right
		Dc.l	0

Tull:		Move.l	Convert_Value(pc),d0
		Move.l	d0,d7
		Mulu	#256,d7
		Divu	#100,d7
		Mulu	#256,d7
		Move.l	d7,SpeedX
		Lea	Scrl_SpeedNT+5(pc),a0
		Moveq.l	#4,d7
		Bsr.w	Conv
		Lea	ScrlLay(pc),a5
		Lea	GTull(pc),a4
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
Tull_Ed:	Rts
*=======================================================================*
*			       O B J E C T				*
*=======================================================================*
Objc_New:	Lea	ObjcList(pc),a4
		Lea	New_Objc(pc),a2
		Bsr.w	Unit_New
		Move	d7,Cur_Objc
		Bra.w	Change_Objc
New_Objc:	Dc	0	;Id		00
		Dc.l	34	;Size		02
		Dc.b	-1	;Class		06
		Dc.b	0	;Collision	07
		Dc	1	;Power		08
		Dc	1	;HitPower	10
		Dc.l	0	;Score		12
		Dc.l	0	;HitScore	16
		Dc	0	;Total		20
		Dc.b	0	;Flags		22
		Dc.b	$ff	;HitColor	23
		Dc	34	;InvOffs	24
		Dc	0	;InvTotal	26
		Blk.b	4,0	;Unused		28
		Dc	-1	;End		32
*---------------
Objc_PlayScreen:Move	#'OB',Play_Mode
		Jsr	Get_Screen_Mem	;###
		Jsr	Get_Bob_Mem	;###
	*-- Fill in test object
		Jsr	Find_Object_Vacancy	;###
		Move	#$8000,(a5)
		Jsr	Get_Objc_LAdr	;###
		Tst.l	(a2)
		Beq.b	OPS_NOb
		Bset	#7,01(a5)	;Set Object bit
		Move.l	(a2),44(a5)	;Object
		Move	#32767,40(a5)	;Duration
		Clr	02(a5)		;Age

	OPS_NOb:Clr	GM_OutCnt

		Clr	Song_Playing
		Jsr	Get_Song_LAdr	;###
		Tst.l	(a2)
		Beq.b	OPS_NSg
		Move.l	(a2),a2
		Move	6(a2),MasterVol
		Move	20(a2),d0
		Move.l	Mem_ModlList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	OPS_NSg
		Move.l	(a2),a0
		Add	#20,a0
		Lea	Variables,a5	;###
		Lea	$dff000,a6
		Jsr	MT_Init		;###
		Move	#1,Song_Playing
	OPS_NSg:

		Jsr	Erase		;###
		Jsr	Leave_Dos	;###
		Jsr	Chip		;Feed Custom Chips ###
		Jsr	Game_Palette	;###

	OPS_M1:	Jsr	Game_Background	;###
		Btst	#6,$bfe001
		Bne.b	OPS_M1

	OPS_M3:	Moveq.l	#127,d0
	OPS_M2:	Btst	#6,$bfe001
		Beq.b	OPS_M3
		Dbf	d0,OPS_M2

		Jsr	Enter_Dos	;###

		Move	Song_Playing,d0	;###
		Beq.b	OPS_NPl
		Clr	Song_Playing
		Lea	$dff000,a6
		Jsr	MT_End
	OPS_NPl:

		Jsr	Free_Play_Mem	;###
	OPS_End:Rts
*---------------
Objc_Power:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value(pc),d0
		Move	d0,8(a0)
		Bsr.b	Upd_Objc_PwrD
		Bsr.b	Upd_Objc_PwrG
	OP_Ed:	Rts
*---------------
Objc_HitPower:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OHP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value(pc),d0
		Move	d0,10(a0)
		Bsr.b	Upd_Objc_HPwrD
		Bsr.b	Upd_Objc_HPwrG
	OHP_Ed:	Rts
*---------------
Upd_Objc_PwrG:	Lea	ObjcLay(pc),a5
		Lea	GObjc_Power(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Upd_Objc_HPwrG:	Lea	ObjcLay(pc),a5
		Lea	GObjc_HitPower(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Upd_Objc_PwrD:	Move	ObjcList_Len(pc),d0
		Beq.b	UOPwrD_End
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOPwrD_End
		Move.l	(a2),a0
		Move	8(a0),d0
		Lea	Objc_PowerNT+5(pc),a0
		Move	#$104,d7
		Bsr.w	Conv
UOPwrD_End:	Rts
*---------------
Upd_Objc_HPwrD:	Move	ObjcList_Len(pc),d0
		Beq.b	UOHPwrD_End
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOHPwrD_End
		Move.l	(a2),a0
		Move	10(a0),d0
		Lea	Objc_HitPowerNT+5(pc),a0
		Move	#$104,d7
		Bsr.w	Conv
UOHPwrD_End:	Rts
*---------------
Objc_Name:	Move	#1,Game_NeedUpd
		Bsr.w	Upd_ObjcNameD
		Bra.w	Upd_ObjcNameG
*---------------
Upd_Objc_ClassD:Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOCD_Ed
		Move.l	(a2),a2
		Lea	GObjc_Class(pc),a0
		Clr	d0
		Move.b	6(a2),d1
	UOCD_Lp:Bclr	#0,4(a0)
		Cmp.b	d0,d1
		Bne.b	UOCD_No
		Bset	#0,4(a0)
	UOCD_No:Add	#38,a0
		Addq	#1,d0
		Cmp	#7,d0
		Bne.b	UOCD_Lp
	UOCD_Ed:Rts
*---------------
Upd_Objc_ClassG:Lea	ObjcLay(pc),a5
		Lea	GObjc_Class(pc),a4
		Moveq.l	#7*3,d7
		Bra.w	Draw_Some
*---------------
Upd_Objc_CollD:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOCo_Ed
		Move.l	(a2),a2
		Lea	GObjc_Collision(pc),a0
		Clr	d0
		Move.b	7(a2),d1

	UOCo_Lp:Lea	Im_Blank-Im,a3

		Btst	d0,d1
		Beq.b	UOCo_No
		Lea	Im_Check5-Im,a3
	UOCo_No:Move	a3,32(a0)
		Add	#34,a0
		Addq	#1,d0
		Cmp	#7,d0
		Bne.b	UOCo_Lp
	UOCo_Ed:Rts
*---------------
Upd_Objc_CollG:	Lea	ObjcLay(pc),a5
		Lea	GObjc_Collision(pc),a4
		Moveq.l	#7*3,d7
		Bra.w	Draw_Some
*---------------
Upd_OEvn_EventG:Lea	OEvnLay,a5		;###
		Lea	GOEvn_EventJP(pc),a4
		Jmp	Draw_All		;###
*---------------
Change_Objc:	Bsr.b	Upd_ObjcNameD
		Bsr.b	Upd_ObjcNameG

		Bsr.w	Upd_Objc_ClassD
		Bsr.w	Upd_Objc_PwrD
		Bsr.w	Upd_Objc_HPwrD
		Bsr.b	Upd_Objc_CollD
		Bsr.w	Upd_Objc_ScoD
		Bsr.w	Upd_Objc_HScoD

		Lea	ObjcLay,a5	;###
		Lea	Objc_UpdAll(pc),a4
		Jmp	Draw_All	;###

		Lea	Objc_Info(pc),a3
		Bra.w	Upd_SelcUnit
*---------------
Upd_ObjcNameD:	Lea	Objc_NameUpd(pc),a4
			Lea	GInvn_ObjcName(pc),a5
		Clr.l	34(a4)
			Clr.l	(a5)
		Move	ObjcList_Len(pc),d7
		Beq.b	UObN_Ed
		Bsr.b	Get_Objc_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	UObN_Ed
		Addq	#8,a2
		Move.l	a2,34(a4)
			Move.l	a2,(a5)
	UObN_Ed:Rts
*---------------
Upd_ObjcNameG:	Lea	InvnLay(pc),a5
		Lea	DrawList_Invn(pc),a4
		Moveq.l	#13,d7
		Bsr.w	Draw_Some
		Lea	ObjcLay(pc),a5
		Lea	Objc_NameUpd(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Get_Objc_LAdr:	Move.l	Mem_ObjcList(pc),a2
		Clr.l	d0
		Move	Cur_Objc(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Objc_Inventory:	Lea	InvnLay(pc),a5
		Bra.w	Open_Layer
*---------------
Objc_AddEvent:	Bsr.b	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.w	OAE_End
		Move.l	a2,OAE_ListAdr
		Bsr.w	Update_ObjcBuf
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
		Move	20(a2),OAE_Loc		;Total
	*-- Find Event Length
		Lea	Objc_NewEvents(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2
		Move	4(a2),d0
		Addq	#2,d0			;Plus 2 for EventOffset
		Move	d0,OAE_BytesAdd
	*-- Free old Object
		Move.l	OAE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Add	OAE_BytesAdd(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	OAE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	OAE_NEr
		Jmp	Mess_MemErr		;###
	OAE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	OAE_BytesAdd(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Class
		Move.b	(a2)+,(a1)+		;Collision
		Move	(a2)+,(a1)+		;Power
		Move	(a2)+,(a1)+		;HitPower
		Move.l	(a2)+,(a1)+		;Score
		Move.l	(a2)+,(a1)+		;HitScore
		Move	(a2)+,d7		;Total
		Addq	#1,d7			;+
		Move	d7,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Flags
		Move.b	(a2)+,(a1)+		;HitColor
		Move	(a2)+,d0		;InvOffs
		Add	OAE_BytesAdd(pc),d0	;+
		Move	d0,(a1)+		;+
		Move	(a2)+,d5		;InvTotal
		Move	d5,(a1)+		;+
		Move.l	(a2)+,(a1)+		;Unused

		Move.l	a1,a3			;First event address
		Move	d7,d6
		Add	d6,d6
		Add	d6,a3

		Move.l	a2,a4			;First event address
		Move	d7,d6
		Subq	#1,d6
		Add	d6,d6
		Add	d6,a4
	*-- Copy Events
		Clr	d0
		Move	d7,d6
		Add	d6,d6
		Add	#32,d6			;'Header' Size

	OAE_CEL:Cmp	OAE_Loc(pc),d0		;Insert Event here?
		Beq.b	OAE_AE
		Move	(a4)+,d1		;Copy EventSize
		Move	d1,(a3)+		;+
		Bmi.b	OAE_CEE			;If -1 then End
		Move	d6,(a1)+		;Write EventOffset
		Add	d1,d6			;Add EventSize
		Subq	#3,d1
	OAE_CEB:Move.b	(a4)+,(a3)+
		Dbf	d1,OAE_CEB
		Addq	#1,d0
		Bra.b	OAE_CEL
	*-- Copy Inventory list
	OAE_CEE:Subq	#1,d5		;Any more Items?
		Bmi.b	OAE_End		;No.
		Moveq.l	#15,d0
	OAE_CI:	Move.b	(a4)+,(a3)+
		Dbf	d0,OAE_CI
		Bra.b	OAE_CEE		;Loop to next Item

	OAE_End:Bsr.w	Upd_ObjcPropD
		Bsr.w	Upd_ObjcEventsD
		Bsr.w	Upd_OEvnDL
		Bsr.w	Upd_ObjcAllG
		Bra.w	Objc_OEvn
		
	OAE_AE:	Move	d6,(a1)+

		Lea	Objc_NewEvents(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2

		Add	4(a2),d6
		Clr	d2
		Move.l	a3,a0
	OAE_LpN:Move.b	4(a2,d2.w),(a3)+
		Addq	#1,d2
		Cmp	4(a2),d2
		Bne.b	OAE_LpN

		Move	OAE_Loc(pc),Cur_ObjcEvent
		Move.l	(a2),d2
		Beq.b	OAE_NRt
		Movem.l	d0-d7/a0-a6,-(a7)
		Move.l	d2,a2
		Jsr	(a2)		;Jsr to New-routine. A0=Event.
		Movem.l	(a7)+,d0-d7/a0-a6

	OAE_NRt:Addq	#1,d0
		Bra.w	OAE_CEL

OAE_Loc:	Dc	0
OAE_ListAdr:	Dc.l	0
OAE_BytesAdd:	Dc	0

Objc_NewEvents:	Dc.l	Objc_TimEv
		Dc.l	Objc_PosEv
		Dc.l	Objc_ColEv
		Dc.l	Objc_LnkEv

Objc_TimEv:	Dc.l	0		;Rtn
		Dc	30,1,0,0,0,0,0	;Size,Type,Time,...
		Dc	0,-1,0,0,0,0,-1	;UnitType,Unit,8B,Sound	14,16,18,26
		Dc	-1		;Weapon			28

Objc_PosEv:	Dc.l	0		;Rtn
		Dc	30,2,0,0,0,0,0	;Size,Type,...
		Dc	0,-1,0,0,0,0,-1	;UnitType,Unit,8B,Sound	14,16,18,26
		Dc	-1		;Weapon			28

Objc_ColEv:	Dc.l	0		;Rtn
		Dc	30,3,0,0,0,0,0	;Size,Type,...
		Dc	0,-1,0,0,0,0,-1	;UnitType,Unit,8B,Sound	14,16,18,26
		Dc	-1		;Weapon			28

Objc_LnkEv:	Dc.l	0		;Rtn
		Dc	30,4,0,0,0,0,0	;Size,Type,...
		Dc	0,-1,0,0,0,0,-1	;UnitType,Unit,8B,Sound	14,16,18,26
		Dc	-1		;Weapon			28
*---------------
Objc_DelEvent:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.w	ODE_End
		Move.l	a2,ODE_ListAdr
		Bsr.w	Update_ObjcBuf

		Move.l	Mem_ObjcBuf,a2		;Get buffer address	###

		Move	Cur_ObjcEvent(pc),d0
		Move	d0,ODE_Loc
		Bmi.w	ODE_End
	*-- Find Event Length (A3->Address)
		Move	Cur_ObjcEvent(pc),d2
		Move	d2,d3
		Add	d3,d3
		Move	32(a2,d3.w),d3
		Lea	00(a2,d3.w),a3
		Move	(a3),d0
		Addq	#2,d0			;Plus 2 for EventOffset
		Move	d0,ODE_BytesSub
	*-- Free old Object
		Move.l	ODE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Sub	ODE_BytesSub(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	ODE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	ODE_NEr
		Jmp	Mess_MemErr		;###
	ODE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub	ODE_BytesSub(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Class
		Move.b	(a2)+,(a1)+		;Collision
		Move	(a2)+,(a1)+		;Power
		Move	(a2)+,(a1)+		;HitPower
		Move.l	(a2)+,(a1)+		;Score
		Move.l	(a2)+,(a1)+		;HitScore
		Move	(a2)+,d7		;Total
		Subq	#1,d7			;+
		Move	d7,(a1)+		;+
		Move.b	(a2)+,(a1)+		;Flags
		Move.b	(a2)+,(a1)+		;HitColor
		Move	(a2)+,d0		;InvOffs
		Sub	ODE_BytesSub(pc),d0	;+
		Move	d0,(a1)+		;+
		Move	(a2)+,d5		;InvTotal
		Move	d5,(a1)+		;+
		Move.l	(a2)+,(a1)+		;Unused

		Move.l	a1,a3			;First event address (Dst)
		Move	d7,d6
		Add	d6,d6
		Add	d6,a3

		Move.l	a2,a4			;First event address (Src)
		Move	d7,d6
		Addq	#1,d6
		Add	d6,d6
		Add	d6,a4
	*-- Copy Events
		Clr	d0
		Move	d7,d6
		Add	d6,d6
		Add	#32,d6			;'Header' Size
	ODE_CEL:Cmp	ODE_Loc(pc),d0		;Delete this Event?
		Beq.b	ODE_DE
		Move	(a4)+,d1		;Copy EventSize
		Move	d1,(a3)+		;+
		Bmi.b	ODE_CEE			;If -1 then end
		Move	d6,(a1)+		;Write EventOffset
		Add	d1,d6			;Add EventSize
		Subq	#3,d1
	ODE_CEB:Move.b	(a4)+,(a3)+
		Dbf	d1,ODE_CEB
		Addq	#1,d0
		Bra.b	ODE_CEL
	*-- Copy Inventory list
	ODE_CEE:Subq	#1,d5		;Any more Items?
		Bmi.b	ODE_End		;No.
		Moveq.l	#15,d0
	ODE_CI:	Move.b	(a4)+,(a3)+
		Dbf	d0,ODE_CI
		Bra.b	ODE_CEE		;Loop to next Item

	ODE_End:Move	#-1,Cur_ObjcEvent
		Bsr.w	Upd_ObjcPropD
		Bsr.w	Upd_ObjcEventsD
		;Bsr.w	Upd_ObjcEventsG
		Bsr.w	Upd_OEvnDL
		Bsr.w	Upd_ObjcAllG
		Bra.w	Objc_OEvn

	ODE_DE:	Move	(a4),d0		;EventSize
		Add	d0,a4		;Skip it!
		Bra.b	ODE_CEL

ODE_Loc:	Dc	0
ODE_ListAdr:	Dc.l	0
ODE_BytesSub:	Dc	0
*---------------
Objc_Coll:	Move.l	HitGd(pc),a0
		Move	8(a0),d7
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OCo_End
		Move.l	(a2),a2
		Bchg	d7,7(a2)
		Bsr.w	Upd_Objc_CollD
		Bsr.w	Upd_Objc_CollG
	OCo_End:Rts
*---------------
Objc_Class:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OC_End
		Move.l	(a2),a2
		Moveq.l	#-1,d7
		Lea	GObjc_Class(pc),a0
		Clr	d0
	OC_Lp:	Btst	#0,4(a0)
		Beq.b	OC_No
		Move	d0,d7
	OC_No:	Add	#38,a0
		Addq	#1,d0
		Cmp	#7,d0
		Bne.b	OC_Lp
		Move.b	d7,6(a2)
	OC_End:	Rts
*---------------
Objc_Score:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value(pc),d0

		Clr.l	d1

		Move.l	d0,d2		;D2=XXXX----
		Divu	#10000,d2	;+
		And.l	#$ffff,d2

		Move.l	d2,d4		;D3=----XXXX
		Mulu	#10000,d4	;+
		Move.l	d0,d3		;+
		Sub.l	d4,d3		;+

		Moveq.l	#3,d7
	OS_Lp1:	Divu	#10,d3
		Swap	d3
		Or	d3,d1
		Clr	d3
		Swap	d3
		Ror.l	#4,d1
		Dbf	d7,OS_Lp1

		Moveq.l	#3,d7
	OS_Lp2:	Divu	#10,d2
		Swap	d2
		Or	d2,d1
		Clr	d2
		Swap	d2
		Ror.l	#4,d1
		Dbf	d7,OS_Lp2

		Move.l	d1,12(a0)
		Bsr.b	Upd_Objc_ScoD
		Bsr.b	Upd_Objc_ScoG
	OS_Ed:	Rts
*---------------
Upd_Objc_ScoD:	Move	ObjcList_Len(pc),d0
		Beq.b	UOS_E
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOS_E
		Move.l	(a2),a0
		Move.l	12(a0),d0

		Lea	Objc_ScoreNT(pc),a0
		Clr	d6
		Moveq.l	#7,d7
	UOS_Lp:	Rol.l	#4,d0
		Move	d0,d1
		And	#$f,d1
		Bne.b	UOS_Nu
		Tst	d7
		Beq.b	UOS_Nu
		Tst	d6
		Bne.b	UOS_Nu
		Move	#' ',d1
		Bra.b	UOS_Sk
	UOS_Nu:	Add	#48,d1
		Moveq.l	#1,d6
	UOS_Sk:	Move.b	d1,(a0)+
		Dbf	d7,UOS_Lp
	UOS_E:	Rts
*---------------
Upd_Objc_ScoG:	Lea	ObjcLay(pc),a5
		Lea	GObjc_Score(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Objc_HitScore:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OHS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value(pc),d0

		Clr.l	d1

		Move.l	d0,d2		;D2=XXXX----
		Divu	#10000,d2	;+
		And.l	#$ffff,d2

		Move.l	d2,d4		;D3=----XXXX
		Mulu	#10000,d4	;+
		Move.l	d0,d3		;+
		Sub.l	d4,d3		;+

		Moveq.l	#3,d7
	OHS_Lp1:Divu	#10,d3
		Swap	d3
		Or	d3,d1
		Clr	d3
		Swap	d3
		Ror.l	#4,d1
		Dbf	d7,OHS_Lp1

		Moveq.l	#3,d7
	OHS_Lp2:Divu	#10,d2
		Swap	d2
		Or	d2,d1
		Clr	d2
		Swap	d2
		Ror.l	#4,d1
		Dbf	d7,OHS_Lp2

		Move.l	d1,16(a0)
		Bsr.b	Upd_Objc_HScoD
		Bsr.b	Upd_Objc_HScoG
	OHS_Ed:	Rts
*---------------
Upd_Objc_HScoD:	Move	ObjcList_Len(pc),d0
		Beq.b	UOHS_E
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOHS_E
		Move.l	(a2),a0
		Move.l	16(a0),d0

		Lea	Objc_HitScoreNT(pc),a0
		Clr	d6
		Moveq.l	#7,d7
	UOHS_Lp:Rol.l	#4,d0
		Move	d0,d1
		And	#$f,d1
		Bne.b	UOHS_Nu
		Tst	d7
		Beq.b	UOHS_Nu
		Tst	d6
		Bne.b	UOHS_Nu
		Move	#' ',d1
		Bra.b	UOHS_Sk
	UOHS_Nu:Add	#48,d1
		Moveq.l	#1,d6
	UOHS_Sk:Move.b	d1,(a0)+
		Dbf	d7,UOHS_Lp
	UOHS_E:	Rts
*---------------
Upd_Objc_HScoG:	Lea	ObjcLay(pc),a5
		Lea	GObjc_HitScore(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Update_ObjcBuf:	Lea	Objc_Info,a3	;###
		Jmp	Update_UnitBuf	;###
*---------------
Objc_OEvn:	Lea	OEvnLay,a5	;###
		Jmp	Open_Layer
*---------------
Objc_Select1:	Moveq.l	#0,d7
		Bra.b	Objc_Select
Objc_Select2:	Moveq.l	#1,d7
		Bra.b	Objc_Select
Objc_Select3:	Moveq.l	#2,d7
		Bra.b	Objc_Select
Objc_Select4:	Moveq.l	#3,d7

Objc_Select:	Move	#-1,Cur_ObjcEvent
		Move.l	HitGd,a0	;Button off?	###
		Btst	#0,4(a0)	;+
		Beq.b	OS_End		;+

		Move	ObjcList_Len,d0	;No Events?	###
		Beq.b	OS_End

		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OS_End
		Move.l	(a2),a2
	*-- Read prop and calculate Event number
	OS_Ok:	Lea	Objc_Prop_Event(pc),a4
		Clr.l	d4
		Move	8(a4),d4	;%PosY
		Clr.l	d5
		Move	4(a4),d5	;%KnobY
		Lsr	#3,d5		;Divide by 4lines*2half
		Add.l	d5,d4

		Move	20(a2),d1	;Total
		Mulu	d1,d4
		Swap	d4
		Add	d7,d4
		Move	d4,Cur_ObjcEvent

	OS_End:	Bsr.b	Upd_OEvnDL
		Bsr.w	Upd_OUNameD
		Bsr.w	Upd_OUnitTypeD
		Bsr.b	Upd_ObjcAllG
		Bra.b	Objc_OEvn
Cur_ObjcEvent:	Dc	-1
*---------------
Upd_OEvnDL:	Move	Cur_ObjcEvent(pc),d2
		Bpl.b	UODL_Ok
		Lea	GOEvn_EventJP(pc),a0
		Lea	OEvn_NoEvent(pc),a1
		Move.l	a1,2(a0)
		Bra.b	UODL_E
	*-- Find Event (A3->Address)
	UODL_Ok:Move	d2,d3
		Add	d3,d3
		Move	32(a2,d3.w),d3
		Lea	00(a2,d3.w),a3
	*-- Write DrawList
		Lea	OEvn_DrawLists(pc),a4
		Move	2(a3),d3
		Lsl	#2,d3
		Lea	GOEvn_EventJP(pc),a0
		Move.l	0(a4,d3.w),2(a0)
	UODL_E:	Rts

OEvn_DrawLists:	Dc.l	OEvn_NoEvent	;0
		Dc.l	OEvn_TimeDL	;1
		Dc.l	OEvn_PosDL	;2
		Dc.l	OEvn_CollDL	;3
*---------------
Upd_ObjcAllG:	Lea	ObjcLay,a5	;###
		Lea	GObjc_All(pc),a4
		Jmp	Draw_All	;###
*---------------
Upd_ObjcEventsD:Lea	GObjc_Event1(pc),a0	;Clear EventList
		Move	#'XX',-72+24(a0)	;+
				
		Move	ObjcList_Len,d0	;No Levels?	###
		Beq.w	UOE_End
		
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.w	UOE_End
		Move.l	(a2),a2
	*-- Read prop and calculate Event number
		Lea	Objc_Prop_Event(pc),a4
		Clr.l	d4
		Move	8(a4),d4	;%PosY
		Clr.l	d5
		Move	4(a4),d5	;%KnobY
		Lsr	#3,d5		;Divide by 4lines*2half
		Add.l	d5,d4
		Mulu	20(a2),d4
		Swap	d4
		Move	d4,d2
		Move	20(a2),d1

		Lea	GObjc_Event1(pc),a0
		Clr	d0
	UOE_Lop:Move	#'XX',-72+24(a0)
		Tst	d1
		Ble.w	UOE_NEv
		Move	#'GD',-72+24(a0)
	*-- Find Event (A3->Address)
		Move	d2,d3
		Add	d3,d3
		Move	32(a2,d3.w),d3
		Lea	00(a2,d3.w),a3
	*-- Write event text
		Clr.l	-4(a0)
		Move	28(a3),d4
		Bpl.b	UOE_Wpn
		Move	14(a3),d7	;UnitType
		Bmi.b	UOE_NUn
		Move	16(a3),d4	;Unit
		Btst	#0,d7
		Bne.b	UOE_Ani
		Btst	#1,d7
		Bne.b	UOE_Mov
		Btst	#2,d7
		Bne.b	UOE_Obj
	UOE_NUn:Move	26(a3),d4
		Bpl.b	UOE_Snd
		Bra.b	UOE_NOk

	UOE_Snd:Move.l	Mem_SondList,a5		;###
		Bra.b	UOE_Uni
	UOE_Wpn:Move.l	Mem_WeapList,a5		;###
		Bra.b	UOE_Uni
	UOE_Ani:Move.l	Mem_AnimList,a5		;###
		Bra.b	UOE_Uni
	UOE_Mov:Move.l	Mem_MoveList,a5		;###
		Bra.b	UOE_Uni
	UOE_Obj:Move.l	Mem_ObjcList,a5		;###

	UOE_Uni:Ext.l	d4
		Bmi.b	UOE_NOk
		Lsl.l	#5,d4
		Add.l	d4,a5
		Addq	#8,a5
		Move.l	a5,-4(a0)
		Bra.w	UOE_NOk
	*-- Write image
	UOE_NOk:Lea	Objc_ImageList(pc),a4
		Move	2(a3),d3
		Add	d3,d3
		Move	-2(a4,d3.w),32(a0)

		Bclr	#0,4(a0)
		Cmp	Cur_ObjcEvent(pc),d2
		Bne.b	UOE_NCr
		Bset	#0,4(a0)
	UOE_NCr:
		Subq	#1,d1		;Count Amount
		Addq	#1,d2		;Count EventList

	UOE_NEv:Add	#106-24,a0
		Addq	#1,d0		;Count ListLines
		Cmp	#4,d0
		Beq.b	UOE_End
		Bra.w	UOE_Lop

	UOE_End:Rts

Objc_ImageList:	Dc	Im_Time-Im	;1
		Dc	Im_Position-Im	;2
		Dc	Im_Collision-Im	;3
*---------------
Upd_ObjcPropD:	Clr	d7

		Lea	Objc_Prop_Event(pc),a4
		Clr	8(a4)		;%PosY
		Move	#$ffff,4(a4)	;%KnobY

		Move	ObjcList_Len,d0	;No Levels?	;###
		Beq.b	UOP_End

		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOP_End
		Move.l	(a2),a2

		Move	20(a2),d7	;Total
		Cmp	#4,d7
		Ble.b	UOP_End

		Move.l	#$40000,d0
		Divu	d7,d0
		Addq	#1,d0
		Move	d0,4(a4)
	UOP_End:Rts
*---------------
Objc_Browse:	Lea	Objc_Events(pc),a4
		Lea	ObjcLay,a5	;###
		Jmp	Draw_All	;###
*---------------
OEvn_UnitType:	Clr	d7
		Lea	GOEvn_Anim(pc),a0
		Btst	#0,4(a0)
		Beq.b	OUT_NAn
		Moveq.l	#1,d7
	OUT_NAn:
		Lea	GOEvn_Move(pc),a0
		Btst	#0,4(a0)
		Beq.b	OUT_NMv
		Moveq.l	#2,d7
	OUT_NMv:
		Lea	GOEvn_Objc(pc),a0
		Btst	#0,4(a0)
		Beq.b	OUT_NOb
		Moveq.l	#4,d7
	OUT_NOb:
		Bsr.w	Get_Objc_Event
		Beq.b	OUT_End
		Or	#2,4(a2)		;Set NeedsUpdate

		Move	d7,14(a3)	;UnitType
		Bsr.b	OEvn_UseUnit
		Bsr.b	Upd_OUnitTypeD
		Bsr.b	Upd_OUnitTypeG
	OUT_End:Rts
*---------------
Upd_OUnitTypeD:	Bsr.w	Get_Objc_Event
		Beq.b	UOT_End
	*-- Decide on type
		Lea	GOEvn_Anim(pc),a2
		Lea	GOEvn_Move(pc),a3
		Lea	GOEvn_Objc(pc),a4
		Move	14(a3),d7	;UnitType

		;Lea	OEvn_NoneDL(pc),a1

		Bclr	#0,4(a2)
		Btst	#0,d7
		Beq.b	UOT_NAn
		Bset	#0,4(a2)
		;Lea	OEvn_AnimDL(pc),a1
	UOT_NAn:
		Bclr	#0,4(a3)
		Btst	#1,d7
		Beq.b	UOT_NMv
		Bset	#0,4(a3)
		;Lea	OEvn_MoveDL(pc),a1
	UOT_NMv:
		Bclr	#0,4(a4)
		Btst	#2,d7
		Beq.b	UOT_NOb
		Bset	#0,4(a4)
		;Lea	OEvn_ObjcDL(pc),a1
	UOT_NOb:
		;Lea	GOEvn_TypeJump(pc),a0
		;Move.l	a1,2(a0)
	UOT_End:Rts
*---------------
Upd_OUnitTypeG:	Lea	OEvnLay(pc),a5
		Lea	GOEvn_Anim(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some
	Rts
		;Lea	OEvnLay(pc),a5
		;Lea	GOEvn_TypeJump(pc),a4
		;Bra.w	Draw_All
*---------------
OEvn_UseUnit:	Bsr.w	Get_Objc_Event
		Beq.w	OUU_End
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Decide on type
		Move	14(a3),d7	;UnitType
		Btst	#0,d7
		Bne.b	OUU_An
		Btst	#1,d7
		Bne.b	OUU_Mv
		Btst	#2,d7
		Bne.b	OUU_Ob
		Bra.b	OUU_End
	*-- Check that Anim exists
	OUU_An:	Move	AnimList_Len(pc),d0
		Beq.b	OUU_End
		Jsr	Get_Anim_LAdr	;###
		Tst.l	(a2)
		Beq.b	OUU_End
		Move.l	(a2),a2
		Move	Cur_Anim(pc),16(a3)	;Unit
		Move.l	(a2),a2		;Copy Anim Delay
		Clr	d0		;+
		Move.b	7(a2),d0	;+
		Move	d0,18(a3)	;+
		Move.b	8(a2),20(a3)	;Copy Anim Control
		Move.b	9(a2),21(a3)	;Copy Anim Direction
		Bra.b	OUU_Fin
	*-- Check that Movement exists
	OUU_Mv:	Move	MoveList_Len(pc),d0
		Beq.b	OUU_End
		Jsr	Get_Move_LAdr	;###
		Tst.l	(a2)
		Beq.b	OUU_End
		Move	Cur_Move(pc),16(a3)	;Unit
		Bra.b	OUU_Fin
	*-- Check that Object exists
	OUU_Ob:	Move	ObjcList_Len(pc),d0
		Beq.b	OUU_End
		Jsr	Get_Objc_LAdr	;###
		Tst.l	(a2)
		Beq.b	OUU_End
		Move	Cur_Objc(pc),16(a3)	;Unit

	OUU_Fin:Bsr.w	Upd_ObjcEventsD
		Bsr.w	Upd_ObjcAllG
		Bsr.w	Upd_OEvn_EventG
	OUU_End:Rts
*---------------
OEvn_UnitName:	Bsr.w	Get_Objc_Event
		Beq.w	OUN_End

		Move	14(a3),d7	;UnitType
		Btst	#0,d7
		Bne.b	OUN_An
		Btst	#1,d7
		Bne.b	OUN_Mv
		Btst	#2,d7
		Bne.b	OUN_Ob
		Bra.b	OUN_End

	OUN_An:	Move	16(a3),d0
		Bmi.b	OUN_NAn
		Move	d0,Cur_Anim
	OUN_NAn:Lea	AnimLay,a5	;###
		Tst.l	(a5)
		Beq.b	OUN_AnO
		Jsr	Change_Anim	;###
		Lea	AnimLay,a5	;###
	OUN_AnO:Jmp	Open_Layer

	OUN_Mv:	Move	16(a3),d0
		Bmi.b	OUN_NMv
		Move	d0,Cur_Move
	OUN_NMv:Lea	MoveLay,a5	;###
		Tst.l	(a5)
		Beq.b	OUN_MvO
		Jsr	Change_Move	;###
		Lea	MoveLay,a5	;###
	OUN_MvO:Jmp	Open_Layer
		
	OUN_Ob:	Move	16(a3),d0
		Bmi.b	OUN_NOb
		Move	d0,Cur_Objc
	OUN_NOb:Lea	ObjcLay,a5	;###
		Tst.l	(a5)
		Beq.b	OUN_ObO
		Jsr	Change_Objc	;###
		Lea	ObjcLay,a5	;###
	OUN_ObO:Jmp	Open_Layer
	OUN_End:Rts
*---------------
Upd_OUNameD:	Bsr.w	Get_Objc_Event
		Beq.b	UON_End

		Move	14(a3),d7	;UnitType
		Btst	#0,d7
		Bne.b	UON_An
		Btst	#1,d7
		Bne.b	UON_Mv
		Btst	#2,d7
		Bne.b	UON_Ob
	*-- Copy name
	UON_An:	Move.l	Mem_AnimList,a2		;###
		Bra.b	UON_Ok
	UON_Mv:	Move.l	Mem_MoveList,a2		;###
		Bra.b	UON_Ok
	UON_Ob:	Move.l	Mem_ObjcList,a2		;###
	UON_Ok:	Lea	GOEvn_UName(pc),a1
		Clr.l	20(a1)
		Move	16(a3),d0	;Unit
		Bmi.b	UON_End
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a1)
	UON_End:Rts
*---------------
Upd_OUNameG:	Lea	OEvnLay,a5	;###
		Lea	GOEvn_UName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
OEvn_UpdSoNmD:	Lea	GOEvn_SondName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Objc_Event
		Beq.b	OUSo_Ed
		Move	26(a3),d0
		Bmi.b	OUSo_Ed
		Ext.l	d0
		Move.l	Mem_SondList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	OUSo_Ed:Rts
*---------------
OEvn_UpdSoNmG:	Lea	OEvnLay,a5	;###
		Lea	GOEvn_SondName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
OEvn_Sond:	Lea	SondLay,a5	;###
		Jmp	Open_Layer
*---------------
OEvn_UseSond:	Bsr.w	OEvn_UseSond_Com
OEvn_UseSond_Com:
		Bsr.w	Get_Objc_Event
		Beq.b	OUSo_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Sound info
		Move	SondList_Len,d0		;###
		Beq.b	OUSo_E
		Jsr	Get_Sond_LAdr		;###
		Tst.l	(a2)
		Beq.b	OUSo_E
		Move	Cur_Sond,26(a3)		;Write Sound	###
		Bsr.b	OEvn_UpdSoNmD
		Bsr.b	OEvn_UpdSoNmG
	OUSo_E:	Rts
*---------------
OEvn_RemSond:	Bsr.w	Get_Objc_Event
		Beq.b	ORSo_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,26(a3)		;Write 'No Sound'	###
		Bsr.w	OEvn_UpdSoNmD
		Bsr.b	OEvn_UpdSoNmG
	ORSo_E:	Rts
*---------------
OEvn_SondName:	Bsr.w	Get_Objc_Event
		Beq.b	OSoN_Ed
		Move	26(a3),d0
		Bmi.b	OSoN_Ed
		Move	d0,Cur_Sond
		Lea	SondLay,a5	;###
		Tst.l	(a5)
		Beq.b	OSoN_Op
		Jsr	Change_Sond	;###
		Lea	SondLay,a5	;###
	OSoN_Op:Jmp	Open_Layer
	OSoN_Ed:Rts
*---------------
OEvn_UpdWpNmD:	Lea	GOEvn_WeapName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Objc_Event
		Beq.b	OUWp_Ed
		Move	28(a3),d0
		Bmi.b	OUWp_Ed
		Ext.l	d0
		Move.l	Mem_WeapList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	OUWp_Ed:Rts
*---------------
OEvn_UpdWpNmG:	Lea	OEvnLay,a5	;###
		Lea	GOEvn_WeapName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
OEvn_Weap:	Lea	WeapLay,a5	;###
		Jmp	Open_Layer
*---------------
OEvn_UseWeap:	Bsr.w	OEvn_UseWeap_Com
OEvn_UseWeap_Com:
		Bsr.b	Get_Objc_Event
		Beq.b	OUWp_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Weapon info
		Move	WeapList_Len,d0		;###
		Beq.b	OUWp_E
		Jsr	Get_Weap_LAdr		;###
		Tst.l	(a2)
		Beq.b	OUWp_E
		Move	Cur_Weap,28(a3)		;Write Weapon	###
		Bsr.b	OEvn_UpdWpNmD
		Bsr.b	OEvn_UpdWpNmG
	OUWp_E:	Rts
*---------------
OEvn_RemWeap:	Bsr.b	Get_Objc_Event
		Beq.b	ORWp_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,28(a3)		;Write 'No Weapon'	###
		Bsr.w	OEvn_UpdWpNmD
		Bsr.b	OEvn_UpdWpNmG
	ORWp_E:	Rts
*---------------
OEvn_WeapName:	Bsr.b	Get_Objc_Event
		Beq.b	OWpN_Ed
		Move	28(a3),d0
		Bmi.b	OWpN_Ed
		Move	d0,Cur_Weap
		Lea	WeapLay,a5	;###
		Tst.l	(a5)
		Beq.b	OWpN_Op
		Jsr	Change_Weap	;###
		Lea	WeapLay,a5	;###
	OWpN_Op:Jmp	Open_Layer
	OWpN_Ed:Rts
*---------------
Get_Objc_Event:	Move	ObjcList_Len,d0	;###
		Beq.b	GOE_No
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	GOE_No
		Move.l	(a2),a3
		Move	Cur_ObjcEvent(pc),d0
		Bmi.b	GOE_No
		Add	d0,d0
		Move	32(a3,d0.w),d0
		Lea	00(a3,d0.w),a3
		Moveq.l	#1,d0
		Rts
	GOE_No:	Clr.l	d0
		Rts
*---------------
Objc_Load:	Move.l	ObjcList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Objc,d4	;###
		Move.l	#'OBJC',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Objc
		Bra.w	Load_ObjcUnits
*---------------
Load_ObjcUnits:	Move	#1,Cur_ObjcEvent
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.w	LOU_End
		Move.l	(a2),a2
		Move	20(a2),d7	;Get Total
		Lea	32(a2),a3	;Get Offsets adress

	LOU_LpP:Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Upd_OEvnDL
		Bsr.w	Upd_OUNameD
		Bsr.w	Upd_OUnitTypeD
		Bsr.w	Upd_ObjcAllG
		Movem.l	(a7)+,d0-d7/a0-a6

		Move.l	a2,a4		;Get Powerup
		Add	(a3)+,a4	;+

		Move	26(a4),d0	;Get Sound
		Bmi.b	LOU_NSo
		Move	d0,Cur_Sond
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Sond_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
	LOU_NSo:
		Move	28(a4),d0	;Get Sound
		Bmi.b	LOU_NWp
		Move	d0,Cur_Weap
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Weap_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
	LOU_NWp:
	*-- Load Change Unit
		Move	14(a4),d0		;Get Type
		Beq.w	LOU_NTy
		Cmp	#1,d0
		Beq.b	LOU_An
		Cmp	#2,d0
		Beq.b	LOU_Mv
		Cmp	#4,d0
		Beq.b	LOU_Ob
		Bra.b	LOU_NTy

	LOU_An:	Move	16(a4),d0
		Bmi.b	LOU_NTy
		Move	d0,Cur_Anim
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Anim_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LOU_NTy

	LOU_Mv:	Move	16(a4),d0
		Bmi.b	LOU_NTy
		Move	d0,Cur_Move
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Move_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LOU_NTy

	LOU_Ob:	Move.l	Mem_ObjcList(pc),a2
		Clr.l	d0
		Move	16(a4),d0
		Bmi.b	LOU_NTy
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)	;Prevent Iterative Loading
		Beq.b	LOU_NTy

		Move	Cur_ObjcEvent(pc),-(a7)
		Move	Cur_Objc(pc),-(a7)
		Movem.l	d0-d7/a0-a6,-(a7)
		Move	16(a4),Cur_Objc
		Jsr	Objc_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Move	(a7)+,Cur_Objc
		Move	(a7)+,Cur_ObjcEvent
	LOU_NTy:
		Addq	#1,Cur_ObjcEvent
		Subq	#1,d7
		Bne.w	LOU_LpP
	LOU_End:Move	#1,Cur_ObjcEvent
		Bra.w	Change_Objc
*---------------
Check_Objc:	Lea	Objc_Jump(pc),a0
		Move	ObjcList_Len,d0	;###
		Beq.b	COb_NUn
	*-- Find current Object, and check if it exists
		Move.l	Mem_ObjcList,a2	;###
		Move	Cur_Objc,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Object?
		Beq.b	COb_No		;No
		Lea	Objc_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	COb_NUn:Lea	Objc_None(pc),a1
		Move.l	a1,(a0)
		Rts
	COb_No:	Lea	Objc_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_OEvn:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	ObjectEvent8T

GOEvn_EventJP:	Dc	'JP'
		Dc.l	OEvn_NoEvent

OEvn_Type_Excl:	Dc.l	GOEvn_Anim
		Dc.l	GOEvn_Move
		Dc.l	GOEvn_Objc
		Dc.l	0
*---------------
OEvn_NoEvent:	Dc	'BX',000,011,-01,-01
		Dc	'XX'
*---------------
OEvn_TimeDL:	Dc	'BX',000,011,-01,036

		Dc	'TX',003,021,-01,8
		Dc.l	OEvn_TimeT

		Dc	'BX',003,022,-04,034

		Dc	'RO'
		Dc.l	Upd_OTim_TimeD

		Dc	'TX',006,031,-01,5
		Dc.l	OTim_TimeT
GOTim_Time:	Dc	'GD'
		Dc.l	$02030a00,5,OTim_Time
		Dc	'RC',-55,024,-26,032
		Dc	'TX',-52,031,-01,5
		Dc.l	OTim_TimeNT
		Dc	'GD'
		Dc.l	$02010052,OTim_Time_P,PlusMinus
		Dc	'BX',-24,024,-16,032
		Dc	'IM',-22,028,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,OTim_Time_P,PlusMinus
		Dc	'BX',-15,024,-07,032
		Dc	'IM',-13,026,5,Im_Plus-Im

		Dc	'JP'
		Dc.l	OEvn_ThenDL
*---------------
OEvn_PosDL:	Dc	'BX',000,011,-01,036

		Dc	'TX',003,021,-01,8
		Dc.l	OEvn_PositionT

		Dc	'JP'
		Dc.l	OEvn_ThenDL
*---------------
OEvn_CollDL:	Dc	'BX',000,011,-01,036

		Dc	'TX',003,021,-01,8
		Dc.l	OEvn_CollisionT

		Dc	'JP'
		Dc.l	OEvn_ThenDL
*---------------
OEvn_ThenDL:	Dc	'BX',000,037,-01,-01

		Dc	'RO'
		Dc.l	Upd_OUnitTypeD

GOEvn_Anim:	Dc	'GD'
		Dc.l	$02010690,OEvn_Type_Excl,OEvn_UnitType
		Dc	'BX',003,039,015,051
		Dc	'IM',005,041,9,Im_Anim-Im
GOEvn_Move:	Dc	'GD'
		Dc.l	$020106B3,OEvn_Type_Excl,OEvn_UnitType
		Dc	'BX',016,039,028,051
		Dc	'IM',018,041,9,Im_Path-Im
GOEvn_Objc:	Dc	'GD'
		Dc.l	$02010691,OEvn_Type_Excl,OEvn_UnitType
		Dc	'BX',029,039,041,051
		Dc	'IM',031,041,9,Im_Mask-Im
		Dc	'GD'
		Dc.l	$02010092,0,OEvn_UseUnit
		Dc	'BX',042,039,054,051
		Dc	'IM',044,043,5,Im_Store-Im
		Dc	'RO'
		Dc.l	Upd_OUNameD
		Dc	'GD'
		Dc.l	$02010093,0,OEvn_UnitName
GOEvn_UName:	Dc	'BX',055,039,-04,051
		Dc	'TX',058,048,-01,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$0201008C,0,OEvn_Sond
		Dc	'BX',003,053,015,065
		Dc	'IM',005,055,9,Im_Sound-Im
		Dc	'GD'
		Dc.l	$0201008D,0,OEvn_UseSond
		Dc	'BX',016,053,028,065
		Dc	'IM',018,057,5,Im_Store-Im
		Dc	'RO'
		Dc.l	OEvn_UpdSoNmD
		Dc	'GD'
		Dc.l	$0201008E,0,OEvn_SondName
GOEvn_SondName:	Dc	'BX',029,053,-17,065
		Dc	'TX',032,062,-49,5
		Dc.l	0
		Dc	'GD'
		Dc.l	$02010094,0,OEvn_RemSond
		Dc	'BX',-16,053,-04,065
		Dc	'IM',-14,055,9,Im_ClrClips-Im

		Dc	'GD'
		Dc.l	$0201008C,0,OEvn_Weap
		Dc	'BX',003,067,015,079
		Dc	'IM',005,069,9,Im_Weapon-Im
		Dc	'GD'
		Dc.l	$0201008D,0,OEvn_UseWeap
		Dc	'BX',016,067,028,079
		Dc	'IM',018,071,5,Im_Store-Im
		Dc	'RO'
		Dc.l	OEvn_UpdWpNmD
		Dc	'GD'
		Dc.l	$0201008E,0,OEvn_WeapName
GOEvn_WeapName:	Dc	'BX',029,067,-17,079
		Dc	'TX',032,076,-49,5
		Dc.l	0
		Dc	'GD'
		Dc.l	$02010094,0,OEvn_RemWeap
		Dc	'BX',-16,067,-04,079
		Dc	'IM',-14,069,9,Im_ClrClips-Im

		Dc	'XX'
*---------------
OTim_Time_P:	Dc	1,0,32766,$0105

ObjectEvent8T:	Dc.b	'Object Event',0

OEvn_TimeT:	Dc.b	'Time:',0
OEvn_PositionT:	Dc.b	'Position:',0
OEvn_CollisionT:Dc.b	'Collision:',0
OEvn_LinkT:	Dc.b	'Link:',0
OEvn_DeathT:	Dc.b	'Death',0

OTim_TimeNT:	Dc.b	'    0',0
OTim_TimeT:	Dc.b	'TIME (1/50 SEC):',0
		Even
*---------------
OTim_Time:	Move	ObjcList_Len,d0		;###
		Beq.b	OTT_Ed
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	OTT_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
		Move	Cur_ObjcEvent(pc),d2
		Bmi.b	OTT_Ed
	*-- Find Event (A1->Address)
		Move	d2,d3
		Add	d3,d3
		Move	32(a1,d3.w),d3
		Lea	00(a1,d3.w),a1
		Move.l	Convert_Value,d0	;###
		Move	d0,4(a1)
		Bsr.b	Upd_OTim_TimeD
		Bsr.b	Upd_OTim_TimeG
	OTT_Ed:	Rts
*---------------
Upd_OTim_TimeD:	Move	ObjcList_Len,d0		;###
		Beq.b	UOTT_E
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UOTT_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
		Move	Cur_ObjcEvent(pc),d2
		Bmi.b	UOTT_E
	*-- Find Event (A1->Address)
		Move	d2,d3
		Add	d3,d3
		Move	32(a1,d3.w),d3
		Lea	00(a1,d3.w),a1
		Move	4(a1),d0
		Lea	OTim_TimeNT+5(pc),a0
		Move	#$104,d7
		Jsr	Conv			;###
	UOTT_E:	Rts
*---------------
Upd_OTim_TimeG:	Lea	OEvnLay,a5		;###
		Lea	GOTim_Time(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some		;###
*---------------
DrawList_Objc:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Object8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Objc_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Objc_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Objc_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-21,025

		Dc	'RO'
		Dc.l	Upd_ObjcNameD

Objc_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Objc_Name
		Dc	'RC',049,015,-43,023
		Dc	'TX',051,022,-94,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Objc_Info,Unit_BrowseUp
		Dc	'BX',-40,015,-32,023
		Dc	'IM',-38,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Objc_Info,Unit_BrowseDn
		Dc	'BX',-31,015,-23,023
		Dc	'IM',-29,018,3,Im_DArr-Im

		Dc	'GD'
		Dc.l	$02010086,0,Objc_Inventory
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_Weapon-Im
		
Objc_UpdAll:	Dc	'RO'
		Dc.l	Check_Objc
		Dc	'JP'
Objc_Jump:	Dc.l	Objc_No

Objc_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Objc_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Objc_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Objc_Yes:	
GObjc_All:	Dc	'BX',000,028,-01,104

		Dc	'TX',003,039,-01,8
		Dc.l	Class8T
		Dc	'IM',058,030,9,Im_Collision-Im

		Dc	'RO'
		Dc.l	Upd_Objc_ClassD
GObjc_Class:
GObjc_Main:	Dc	'GD'
		Dc.l	$02010665,Objc_Excl_Class,Objc_Class
		Dc	'BX',003,040,057,048
		Dc	'TX',006,047,-01,5
		Dc.l	MainT
GObjc_MainSh:	Dc	'GD'
		Dc.l	$02010665,Objc_Excl_Class,Objc_Class
		Dc	'BX',003,049,057,057
		Dc	'TX',006,056,-01,5
		Dc.l	MainShotT
GObjc_Enemy:	Dc	'GD'
		Dc.l	$02010665,Objc_Excl_Class,Objc_Class
		Dc	'BX',003,058,057,066
		Dc	'TX',006,065,-01,5
		Dc.l	EnemyT
GObjc_EnemySh:	Dc	'GD'
		Dc.l	$02010665,Objc_Excl_Class,Objc_Class
		Dc	'BX',003,067,057,075
		Dc	'TX',006,074,-01,5
		Dc.l	EnemyShotT
GObjc_Explosion:Dc	'GD'
		Dc.l	$02010665,Objc_Excl_Class,Objc_Class
		Dc	'BX',003,076,057,084
		Dc	'TX',006,083,-01,5
		Dc.l	ExplosionT
GObjc_PickUp:	Dc	'GD'
		Dc.l	$02010665,Objc_Excl_Class,Objc_Class
		Dc	'BX',003,085,057,093
		Dc	'TX',006,092,-01,5
		Dc.l	PickUpT
GObjc_Backgnd:	Dc	'GD'
		Dc.l	$02010665,Objc_Excl_Class,Objc_Class
		Dc	'BX',003,094,057,102
		Dc	'TX',006,101,-01,5
		Dc.l	BackgroundT

		Dc	'RO'
		Dc.l	Upd_Objc_CollD

GObjc_Collision:Dc	'GD'
		Dc.l	$0201003b,0,Objc_Coll
		Dc	'BX',058,040,066,048
		Dc	'IM',060,042,5,Im_Blank-Im
		Dc	'GD'
		Dc.l	$0201003b,1,Objc_Coll
		Dc	'BX',058,049,066,057
		Dc	'IM',060,051,5,Im_Blank-Im
		Dc	'GD'
		Dc.l	$0201003b,2,Objc_Coll
		Dc	'BX',058,058,066,066
		Dc	'IM',060,060,5,Im_Blank-Im
		Dc	'GD'
		Dc.l	$0201003b,3,Objc_Coll
		Dc	'BX',058,067,066,075
		Dc	'IM',060,069,5,Im_Blank-Im
		Dc	'GD'
		Dc.l	$0201003b,4,Objc_Coll
		Dc	'BX',058,076,066,084
		Dc	'IM',060,078,5,Im_Blank-Im
		Dc	'GD'
		Dc.l	$0201003b,5,Objc_Coll
		Dc	'BX',058,085,066,093
		Dc	'IM',060,087,5,Im_Blank-Im
		Dc	'GD'
		Dc.l	$0201003b,6,Objc_Coll
		Dc	'BX',058,094,066,102
		Dc	'IM',060,096,5,Im_Blank-Im

		Dc	'RO'
		Dc.l	Upd_Objc_PwrD

		Dc	'TX',070,037,-01,5
		Dc.l	PowerT
GObjc_Power:	Dc	'GD'
		Dc.l	$02030a00,5,Objc_Power
		Dc	'RC',-52,030,-23,038
		Dc	'TX',-49,037,-01,5
		Dc.l	Objc_PowerNT
		Dc	'GD'
		Dc.l	$02010052,Objc_Power_P,PlusMinus
		Dc	'BX',-21,030,-13,038
		Dc	'IM',-19,034,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Objc_Power_P,PlusMinus
		Dc	'BX',-12,030,-04,038
		Dc	'IM',-10,032,5,Im_Plus-Im

		Dc	'RO'
		Dc.l	Upd_Objc_HPwrD

		Dc	'TX',070,047,-01,5
		Dc.l	HitPowerT
GObjc_HitPower:	Dc	'GD'
		Dc.l	$02030a00,5,Objc_HitPower
		Dc	'RC',-52,040,-23,048
		Dc	'TX',-49,047,-01,5
		Dc.l	Objc_HitPowerNT
		Dc	'GD'
		Dc.l	$02010052,Objc_Power_P,PlusMinus
		Dc	'BX',-21,040,-13,048
		Dc	'IM',-19,044,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Objc_Power_P,PlusMinus
		Dc	'BX',-12,040,-04,048
		Dc	'IM',-10,042,5,Im_Plus-Im

		Dc	'TX',070,064,-01,5
		Dc.l	HitShadowT
		Dc	'GD'
		Dc.l	$02010000,0,0	;Objc_Coll
		Dc	'BX',-42,057,-34,065
		Dc	'IM',-40,059,5,Im_Check5-Im
		Dc	'FR',-32,057,-04,065

		Dc	'TX',070,074,-01,5
		Dc.l	ColorT
		Dc	'GD'
		Dc.l	$02030a00,5,0
		Dc	'RC',-42,067,-23,075
		Dc	'TX',-39,074,-01,5
		Dc.l	Objc_ColorNT
		Dc	'GD'
		Dc.l	$02010052,0,0	;Unit_BrowseUp
		Dc	'BX',-21,067,-13,075
		Dc	'IM',-19,071,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,0,0	;Unit_BrowseDn
		Dc	'BX',-12,067,-04,075
		Dc	'IM',-10,069,5,Im_Plus-Im

		Dc	'RO'
		Dc.l	Upd_Objc_ScoD

		Dc	'TX',070,091,-01,5
		Dc.l	ScoreT
GObjc_Score:	Dc	'GD'
		Dc.l	$02030a00,8,Objc_Score
		Dc	'RC',-48,084,-04,092
		Dc	'TX',-45,091,-01,5
		Dc.l	Objc_ScoreNT

		Dc	'RO'
		Dc.l	Upd_Objc_HScoD

		Dc	'TX',070,101,-01,5
		Dc.l	HitScoreT
GObjc_HitScore:	Dc	'GD'
		Dc.l	$02030a00,8,Objc_HitScore
		Dc	'RC',-48,094,-04,102
		Dc	'TX',-45,101,-01,5
		Dc.l	Objc_HitScoreNT

		Dc	'BX',000,105,-01,121

		Dc	'GD'
		Dc.l	$02010000,1,Objc_AddEvent
		Dc	'BX',003,107,015,119
		Dc	'IM',005,109,9,Im_Time-Im

		Dc	'GD'
		Dc.l	$02010000,2,Objc_AddEvent
		Dc	'BX',016,107,028,119
		Dc	'IM',018,109,9,Im_Position-Im

		Dc	'GD'
		Dc.l	$02010000,3,Objc_AddEvent
		Dc	'BX',029,107,041,119
		Dc	'IM',031,109,9,Im_Collision-Im

		Dc	'GD'
		Dc.l	$02010000,4,Objc_AddEvent
		Dc	'BX',042,107,054,119
		Dc	'IM',044,109,9,Im_Once-Im

		Dc	'GD'
		Dc.l	$02010000,5,Objc_AddEvent
		Dc	'BX',055,107,067,119
		Dc	'IM',057,109,9,Im_Death-Im

		Dc	'GD'
		Dc.l	$02010000,6,Objc_AddEvent
		Dc	'BX',068,107,080,119
		Dc	'IM',070,109,9,Im_Death-Im

		Dc	'GD'
		Dc.l	$0201004e,0,Objc_DelEvent
		Dc	'BX',085,107,097,119
		Dc	'IM',087,109,9,Im_ClrClips-Im

		Dc	'GD'
		Dc.l	$0201000e,0,Objc_PlayScreen
		Dc	'BX',102,107,114,119
		Dc	'IM',104,109,9,Im_PlayScr-Im

		Dc	'RO'
		Dc.l	Upd_ObjcPropD

		Dc	'GD'
		Dc.l	$02020000,Objc_Prop_Event,Objc_Browse
		Dc	'BX',-09,-56,-01,-10
		Dc	'BX',-07,-54,-03,-12

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

Objc_Events:	Dc	'RO'
		Dc.l	Upd_ObjcEventsD

		Dc	'BX',000,-56,-10,-01

GObjc_List:	Dc	'XX'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,-52,011,-44
		Dc	'IM',005,-50,5,Im_Check5-Im
		Dc	'TX',017,-45,-46,5
		Dc.l	0
GObjc_Event1:	Dc	'GD'
		Dc.l	$02010651,Objc_Excl_List,Objc_Select1
		Dc	'BX',-25,-54,-13,-42
		Dc	'IM',-23,-52,9,Im_Time-Im

		Dc	'XX'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,-39,011,-31
		Dc	'IM',005,-37,5,Im_Check5-Im
		Dc	'TX',017,-32,-46,5
		Dc.l	0
GObjc_Event2:	Dc	'GD'
		Dc.l	$02010651,Objc_Excl_List,Objc_Select2
		Dc	'BX',-25,-41,-13,-29
		Dc	'IM',-23,-39,9,Im_Time-Im

		Dc	'XX'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,-26,011,-18
		Dc	'IM',005,-24,5,Im_Check5-Im
		Dc	'TX',017,-19,-46,5
		Dc.l	0
GObjc_Event3:	Dc	'GD'
		Dc.l	$02010651,Objc_Excl_List,Objc_Select3
		Dc	'BX',-25,-28,-13,-16
		Dc	'IM',-23,-26,9,Im_Position-Im

		Dc	'XX'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,-13,011,-05
		Dc	'IM',005,-11,5,Im_Check5-Im
		Dc	'TX',017,-06,-46,5
		Dc.l	0
GObjc_Event4:	Dc	'GD'
		Dc.l	$02010651,Objc_Excl_List,Objc_Select4
		Dc	'BX',-25,-15,-13,-03
		Dc	'IM',-23,-13,9,Im_Death-Im

		Dc	'XX'

Objc_Power_P:	Dc	1,0,32766,$0105

Objc_Prop_Event:Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,32767		;KnobX,Y
		Dc	0,0		;PosX,Y

Objc_Excl_Class:Dc.l	GObjc_Main
		Dc.l	GObjc_MainSh
		Dc.l	GObjc_Enemy
		Dc.l	GObjc_EnemySh
		Dc.l	GObjc_Explosion
		Dc.l	GObjc_PickUp
		Dc.l	GObjc_Backgnd
		Dc.l	0

Objc_Excl_List:	Dc.l	GObjc_Event1
		Dc.l	GObjc_Event2
		Dc.l	GObjc_Event3
		Dc.l	GObjc_Event4
		Dc.l	0

MainT:		Dc.b	'MAIN',0
MainShotT:	Dc.b	'MAIN SHOT',0
EnemyT:		Dc.b	'ENEMY',0
EnemyShotT:	Dc.b	'ENEMY SHOT',0
ExplosionT:	Dc.b	'EXPLOSION',0
PickUpT:	Dc.b	'PICK UP',0
;EquipmentT:	Dc.b	'EQUIPMENT',0

HitShadowT:	Dc.b	'HITSHADOW:',0
ColorT:		Dc.b	'COLOR:',0

Objc_ColorNT:	Dc.b	'  0',0
Objc_PowerNT:	Dc.b	'    0',0
Objc_HitPowerNT:Dc.b	'    0',0
Objc_ScoreNT:	Dc.b	'       0',0
Objc_HitScoreNT:Dc.b	'       0',0
		Even
*---------------
Invn_AddItem:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.w	IAI_End
		Move.l	a2,IAI_ListAdr
		Bsr.w	Update_ObjcBuf
		Move	#16,IAI_BytesAdd
	*-- Free old Object
		Move.l	IAI_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Add	IAI_BytesAdd(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	IAI_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	IAI_NEr
		Jmp	Mess_MemErr		;###
	IAI_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	IAI_BytesAdd(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Moveq.l	#17,d0			;Copy uninteresting data
	IAI_CGL:Move.b	(a2)+,(a1)+		;+
		Dbf	d0,IAI_CGL		;+
		Move	(a2)+,d6		;InvOffs
		Move	d6,(a1)+		;+
		Move	(a2)+,d5		;InvTotal
		Addq	#1,d5
		Move	d5,Cur_InvnItem
		Move	d5,(a1)+		;+
		Move.l	(a2)+,(a1)+		;Unused
	*-- Copy rest: EventOffsets,Events,Items
		Move.l	Mem_ObjcBuf,a0		;Get buffer address ###
		Move.l	2(a0),d0
		Sub	#32+1,d0	;Sub Header + Dbf
	IAI_CRL:Move.b	(a2)+,(a1)+
		Dbf	d0,IAI_CRL
	*-- Add new Item
		Move	#1,(a1)+	;Type (1=Weapon)
		Bsr.w	Get_Weap_LAdr
		Move	Cur_Weap(pc),d0
		Tst	(a2)
		Bne.b	IAI_WOk
		Moveq.l	#-1,d0
	IAI_WOk:Move	d0,(a1)+	;Unit
		Clr.l	(a1)+		;OffsetX,OffsetY
		Move	#1,(a1)+	;Powerup
		Move	#-1,(a1)+	;Ammo
		Move	#-1,(a1)+	;Time
		Move	#0,(a1)+

	IAI_End:Bsr.w	Change_InvnItem
		Rts

IAI_ListAdr:	Dc.l	0
IAI_BytesAdd:	Dc	0
*---------------
Invn_DelItem:	Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.w	IDI_End
		Move	26(a2),d0	;Any Items to delete?
		Beq.w	IDI_End		;No!
		Move.l	a2,IDI_ListAdr
		Bsr.w	Update_ObjcBuf
		Move	#16,IDI_BytesSub
	*-- Free old Object
		Move.l	IDI_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Add	IDI_BytesSub(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	IDI_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	IDI_NEr
		Jmp	Mess_MemErr		;###
	IDI_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_ObjcBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	IDI_BytesSub(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Moveq.l	#17,d0			;Copy uninteresting data
	IDI_CGL:Move.b	(a2)+,(a1)+		;+
		Dbf	d0,IDI_CGL		;+
		Move	(a2)+,d6		;InvOffs
		Move	d6,(a1)+		;+
		Move	(a2)+,d5		;InvTotal
		Subq	#1,d5
		Move	d5,(a1)+		;+
		Move.l	(a2)+,(a1)+		;Unused
	*-- Copy rest: EventOffsets,Events,Items
		Move.l	Mem_ObjcBuf,a0		;Get buffer address ###
		Move.l	2(a0),d0
		Sub	#32+1+16,d0	;Sub Header + Dbf + Item
	IDI_CRL:Move.b	(a2)+,(a1)+
		Dbf	d0,IDI_CRL

	IDI_End:Move	#1,Cur_InvnItem
		Bsr.w	Change_InvnItem
		Rts

IDI_ListAdr:	Dc.l	0
IDI_BytesSub:	Dc	0
*---------------
Invn_PrvItem:	Subq	#1,Cur_InvnItem
		Bra.w	Change_InvnItem
Cur_InvnItem:	Dc	1
*---------------
Invn_NxtItem:	Addq	#1,Cur_InvnItem
		Bra.w	Change_InvnItem
*---------------
Upd_InvnNumbD:	Move	ObjcList_Len,d0	;###
		Beq.b	UInN_Ed
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	UInN_Ed
		Move.l	(a2),a0
		Move	26(a0),d0	;InvTotal
		Lea	Invn_ItemsNT+2(pc),a0
		Move	#$101,d7
		Jsr	Conv	;###
	*-- Current Item
		Bsr.w	Get_Objc_LAdr
		Move.l	(a2),a0
		Cmp	#1,Cur_InvnItem
		Bge.b	UInN_NU
		Move	26(a0),d0	;InvTotal
		Move	d0,Cur_InvnItem
	UInN_NU:Move	26(a0),d0	;InvTotal
		Cmp	Cur_InvnItem(pc),d0
		Bge.b	UInN_NO
		Move	#1,Cur_InvnItem
	UInN_NO:Move	Cur_InvnItem(pc),d0
		Lea	Invn_ItemNT+2(pc),a0
		Move	#$101,d7
		Jsr	Conv	;###
	UInN_Ed:Rts
*---------------
Upd_InvnNumbG:	Lea	InvnLay,a5	;###
		Lea	Invn_ItemsUpd(pc),a4
		Moveq.l	#1,d7
		Jsr	Draw_Some	;###

		Lea	Invn_ItemUpd(pc),a4
		Moveq.l	#1,d7
		Jmp	Draw_Some	;###
*---------------
Change_InvnItem:Bsr.w	Upd_InvnNumbD
		Bsr.b	Upd_InvnNumbG
		Bsr.w	Upd_IWNameD
		Bsr.w	Upd_IWNameG
		Bsr.w	Upd_Invn_OffsD
		Bsr.w	Upd_Invn_OffsG
		Bsr.b	Upd_Invn_AmmoD
		Bsr.b	Upd_Invn_AmmoG
		Bsr.b	Upd_Invn_PwrUpD
		Bsr.w	Upd_Invn_PwrUpG
		Rts
*---------------
Invn_Weap:	Lea	WeapLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Invn_Ammo:	Bsr.w	Get_InvnItem
		Beq.b	InA_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,10(a1)		;Ammo
		Bsr.b	Upd_Invn_AmmoD
		Bsr.b	Upd_Invn_AmmoG
	InA_Ed:	Rts
*---------------
Upd_Invn_AmmoD:	Bsr.w	Get_InvnItem
		Beq.b	UInA_E
		Move	10(a1),d0	;Ammo
		Lea	Invn_AmmoNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
	UInA_E:	Rts
*---------------
Upd_Invn_AmmoG:	Lea	InvnLay,a5	;###
		Lea	GInvn_Ammo(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Invn_Powerup:	Bsr.w	Get_InvnItem
		Beq.b	InP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,08(a1)		;Ammo
		Bsr.b	Upd_Invn_PwrUpD
		Bsr.b	Upd_Invn_PwrUpG
	InP_Ed:	Rts
*---------------
Upd_Invn_PwrUpD:Bsr.w	Get_InvnItem
		Beq.b	UInP_E
		Move	08(a1),d0	;Ammo
		Lea	Invn_PwrUpNT+2(pc),a0
		Move	#$8101,d7
		Jsr	Conv	;###
	UInP_E:	Rts
*---------------
Upd_Invn_PwrUpG:Lea	InvnLay,a5	;###
		Lea	GInvn_PwrUp(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Invn_OffsetX:	Move	#04,d5
		Bra.b	InOX_Cm
Invn_OffsetY:	Move	#06,d5
	InOX_Cm:Bsr.b	Get_InvnItem
		Beq.b	InOX_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,0(a1,d5.w)
		Bsr.b	Upd_Invn_OffsD
		Bsr.b	Upd_Invn_OffsG
	InOX_Ed:Rts
*---------------
Upd_Invn_OffsD:	Bsr.b	Get_InvnItem
		Beq.b	UInO_E
	*-- Convert numbers
		Move	04(a1),d0	;XOffset
		Lea	Invn_OffsetXNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
		Move	06(a1),d0	;YOffset
		Lea	Invn_OffsetYNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
	UInO_E:	Rts
*---------------
Upd_Invn_OffsG:	Lea	InvnLay,a5	;###
		Lea	GInvn_OffsetX(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		
		Lea	GInvn_OffsetY(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Get_InvnItem:	
	*-- Find Object
		Bsr.w	Get_Objc_LAdr
		Tst.l	(a2)
		Beq.b	GII_End
		Move.l	(a2),a1
	*-- Find Item (A1->Address)
		Move	Cur_InvnItem(pc),d0
		Subq	#1,d0
		Lsl	#4,d0			;Multiply by 16
		Add	24(a1),d0		;InvOffs
		Lea	00(a1,d0.w),a1
		Moveq.l	#1,d0
		Rts
	GII_End:Moveq.l	#0,d0
		Rts
*---------------
Invn_UseWeap:	Bsr.b	Get_InvnItem
		Beq.b	IUW_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Weapon data
		Jsr	Get_Weap_LAdr	;###
		Tst.l	(a2)
		Beq.b	IUW_Ed
		Move	Cur_Weap,2(a1)		;Write Weapon number ;###
		Bsr.w	Change_InvnItem
	IUW_Ed:	Rts
*---------------
Invn_RemWeap:	Bsr.b	Get_InvnItem
		Beq.b	IRW_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Object data
		Move	#-1,2(a1)		;Write 'Empty'
		Bsr.w	Change_InvnItem
	IRW_Ed:	Rts
*---------------
Invn_WeapName:	Bsr.b	Get_InvnItem
		Beq.b	IWN_Ed
		Move	2(a1),d0	;Get Object number
		Bmi.b	IWN_No
		Move	d0,Cur_Weap
	IWN_No:	Lea	WeapLay,a5	;###
		Tst.l	(a5)
		Beq.b	IWN_Op
		Jsr	Change_Weap	;###
		Lea	WeapLay,a5	;###
	IWN_Op:	Jmp	Open_Layer	;###
	IWN_Ed:	Rts
*---------------
Upd_IWNameD:	Bsr.w	Get_InvnItem
		Beq.b	UIW_End
		Lea	GInvn_IWName(pc),a3
		Clr.l	20(a3)
		Move	2(a1),d0	;Unit
		Bmi.b	UIW_End
		Ext.l	d0
		Move.l	Mem_WeapList,a2		;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	UIW_End:Rts
*---------------
Upd_IWNameG:	Lea	InvnLay,a5	;###
		Lea	GInvn_IWName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
DrawList_Invn:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Inventory8T
		Dc	'TX',093,009,-01,5
		Dc.l	DashT
		Dc	'TX',102,009,-118,5
GInvn_ObjcName:	Dc.l	0

		Dc	'BX',000,011,-01,023

		Dc	'TX',003,022,-01,8
		Dc.l	Item8T
		Dc	'GD'
		Dc.l	$02030a00,2,0
		Dc	'RC',-84,013,-70,021
Invn_ItemUpd:	Dc	'TX',-81,020,-01,5
		Dc.l	Invn_ItemNT
		Dc	'GD'
		Dc.l	$02010000,0,Invn_PrvItem
		Dc	'BX',-68,013,-60,021
		Dc	'IM',-66,017,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010000,0,Invn_NxtItem
		Dc	'BX',-59,013,-51,021
		Dc	'IM',-57,015,5,Im_Plus-Im

		Dc	'TX',-48,020,-01,5
		Dc.l	OfT
		Dc	'GD'
		Dc.l	$02030a00,2,0
		Dc	'RC',-37,013,-23,021
Invn_ItemsUpd:	Dc	'TX',-34,020,-01,5
		Dc.l	Invn_ItemsNT
		Dc	'GD'
		Dc.l	$02010000,0,Invn_DelItem
		Dc	'BX',-21,013,-13,021
		Dc	'IM',-19,017,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010000,0,Invn_AddItem
		Dc	'BX',-12,013,-04,021
		Dc	'IM',-10,015,5,Im_Plus-Im

		Dc	'BX',000,024,-01,-01
	
		Dc	'GD'
		Dc.l	$02010000,0,Invn_Weap
		Dc	'BX',003,026,015,038
		Dc	'IM',005,028,9,Im_Weapon-Im
		Dc	'GD'
		Dc.l	$02010000,0,Invn_UseWeap
		Dc	'BX',016,026,028,038
		Dc	'IM',018,030,5,Im_Store-Im
		Dc	'RO'
		Dc.l	Upd_IWNameD
		Dc	'GD'
		Dc.l	$02010000,0,Invn_WeapName
GInvn_IWName:	Dc	'BX',029,026,-17,038
		Dc	'TX',032,035,-49,5
		Dc.l	0
		Dc	'GD'
		Dc.l	$02010000,0,Invn_RemWeap
		Dc	'BX',-16,026,-04,038
		Dc	'IM',-14,028,9,Im_ClrClips-Im
	
		Dc	'TX',003,047,-01,5
		Dc.l	OffsetT

		Dc	'TX',-120,047,-01,5
		Dc.l	XT
GInvn_OffsetX:	Dc	'GD'
		Dc.l	$02030a00,5,Invn_OffsetX
		Dc	'RC',-112,040,-83,048
		Dc	'TX',-109,047,-01,5
		Dc.l	Invn_OffsetXNT
		Dc	'GD'
		Dc.l	$02010052,Invn_Offset_P,PlusMinus
		Dc	'BX',-81,040,-73,048
		Dc	'IM',-79,044,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Invn_Offset_P,PlusMinus
		Dc	'BX',-72,040,-64,048
		Dc	'IM',-70,042,5,Im_Plus-Im

		Dc	'TX',-60,047,-01,5
		Dc.l	YT
GInvn_OffsetY:	Dc	'GD'
		Dc.l	$02030a00,5,Invn_OffsetY
		Dc	'RC',-52,040,-23,048
		Dc	'TX',-49,047,-01,5
		Dc.l	Invn_OffsetYNT
		Dc	'GD'
		Dc.l	$02010052,Invn_Offset_P,PlusMinus
		Dc	'BX',-21,040,-13,048
		Dc	'IM',-19,044,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Invn_Offset_P,PlusMinus
		Dc	'BX',-12,040,-04,048
		Dc	'IM',-10,042,5,Im_Plus-Im

		Dc	'TX',003,057,-01,5
		Dc.l	PowerupT
GInvn_PwrUp:	Dc	'GD'
		Dc.l	$02030a00,2,Invn_Powerup
		Dc	'RC',-37,050,-23,058
		Dc	'TX',-34,057,-01,5
		Dc.l	Invn_PwrUpNT
		Dc	'GD'
		Dc.l	$02010052,Invn_PwrUp_P,PlusMinus
		Dc	'BX',-21,050,-13,058
		Dc	'IM',-19,054,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Invn_PwrUp_P,PlusMinus
		Dc	'BX',-12,050,-04,058
		Dc	'IM',-10,052,5,Im_Plus-Im

		Dc	'TX',003,067,-01,5
		Dc.l	AmmunitionT
GInvn_Ammo:	Dc	'GD'
		Dc.l	$02030a00,5,Invn_Ammo
		Dc	'RC',-52,060,-23,068
		Dc	'TX',-49,067,-01,5
		Dc.l	Invn_AmmoNT
		Dc	'GD'
		Dc.l	$02010052,Invn_Ammo_P,PlusMinus
		Dc	'BX',-21,060,-13,068
		Dc	'IM',-19,064,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Invn_Ammo_P,PlusMinus
		Dc	'BX',-12,060,-04,068
		Dc	'IM',-10,062,5,Im_Plus-Im

;Time,Rate,MaxOut
		Dc	'XX'

Invn_Offset_P:	Dc	1,-999,999,$8103
Invn_PwrUp_P:	Dc	1,1,9,$8103
Invn_Ammo_P:	Dc	1,-1,32767,$8103

Item8T:		Dc.b	'Item:',0
PowerupT:	Dc.b	'POWERUP:',0
AmmunitionT:	Dc.b	'AMMUNITION:',0
Invn_ItemNT:	Dc.b	' 0',0
Invn_ItemsNT:	Dc.b	' 0',0
Invn_OffsetXNT:	Dc.b	'    0',0
Invn_OffsetYNT:	Dc.b	'    0',0
Invn_PwrUpNT:	Dc.b	' 1',0
Invn_AmmoNT:	Dc.b	'    0',0
Inventory8T:	Dc.b	'Inventory',0
*=======================================================================*
*			       P L A Y E R				*
*=======================================================================*
Play_New:	Lea	PlayList(pc),a4
		Lea	New_Play(pc),a2
		Bsr.w	Unit_New
		Move	d7,Cur_Play
		Bra.b	Change_Play
New_Play:	Dc	0	;Id		00
		Dc.l	6	;Size		02
*---------------
Play_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Change_Play:	Bsr.b	Upd_PlayNameD
		Bsr.b	Upd_PlayNameG
		Lea	PlayLay,a5	;###
		Lea	Play_UpdAll(pc),a4
		Jmp	Draw_All	;###

		Lea	Play_Info(pc),a3
		Bra.w	Upd_SelcUnit
*---------------
Upd_PlayNameD:	Lea	Play_Info(pc),a3
		Lea	Play_NameUpd(pc),a4
		Bra.w	Upd_UnitNameD
*---------------
Upd_PlayNameG:	Lea	PlayLay(pc),a5
		Lea	Play_NameUpd(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Get_Play_LAdr:	Move.l	Mem_PlayList(pc),a2
		Clr.l	d0
		Move	Cur_Play(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Play_Input:	Lea	InptLay,a5	;###
		Jmp	Open_Layer
*---------------
Play_Load:	Move.l	PlayList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Play,d4	;###
		Move.l	#'PLAY',d0
		Jsr	Load_Unit	;###
		Bsr.b	Change_Play
		Bra.w	Load_PlayUnits
*---------------
Load_PlayUnits:	Rts
*---------------
Check_Play:	Lea	Play_Jump(pc),a0
		Move	PlayList_Len,d0	;###
		Beq.b	CPl_NUn
	*-- Find current Player, and check if it exists
		Move.l	Mem_PlayList,a2	;###
		Move	Cur_Play,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Player?
		Beq.b	CPl_No		;No
		Lea	Play_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CPl_NUn:Lea	Play_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CPl_No:	Lea	Play_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_Play:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Player8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Play_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Play_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Play_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im
		
		Dc	'BX',046,013,-21,025

		Dc	'RO'
		Dc.l	Upd_PlayNameD

Play_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Play_Name
		Dc	'RC',049,015,-43,023
		Dc	'TX',051,022,-94,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Play_Info,Unit_BrowseUp
		Dc	'BX',-40,015,-32,023
		Dc	'IM',-38,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Play_Info,Unit_BrowseDn
		Dc	'BX',-31,015,-23,023
		Dc	'IM',-29,018,3,Im_DArr-Im

		Dc	'GD'
		Dc.l	$02010086,0,Play_Input
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_Joystick-Im
		
Play_UpdAll:	Dc	'RO'
		Dc.l	Check_Play
		Dc	'JP'
Play_Jump:	Dc.l	Play_No

Play_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Play_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Play_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Play_Yes:	
GPlay_All:	Dc	'BX',000,028,-01,-01
		Dc	'XX'

Player8T:	Dc.b	'Player',0
		Even
*---------------
DrawList_Inpt:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Input8T

		Dc	'BX',000,011,-01,-01
		Dc	'XX'

Input8T:	Dc.b	'Input',0
		Even
*=======================================================================*
*			       W E A P O N				*
*=======================================================================*
Weap_New:	Lea	WeapList(pc),a4
		Lea	New_Weap(pc),a2
		Bsr.w	Unit_New
		Move	d7,Cur_Weap
		Bra.w	Change_Weap
New_Weap:	Dc	0	;Id		00
		Dc.l	138	;Size		02
		Dc	1	;Total		06
		Dc	10	;Offset		08
	;Powerup:	
		Dc	1	;Amount		00
		Dc	1	;Price		02
		Dc	1	;AmmoDrain	04	
		Dc	1	;FireDelay	06
		Dc	1	;MaxOut		08
		Dc	-1	;Sound		10
		Dc.b	0	;EffectType	12
		Dc.b	1	;EffectVal1	13
		Dc	1	;EffectVal2	14
		Blk.b	48,0	;Unused		16
	;Shot:
		Dc	1	;Type		00
		Dc	-1	;Unit		02
		Dc	1	;Power		04
		Dc	1	;HitPower	06
		Dc.l	$80000	;SpeedX		08
		Dc.l	$00000	;SpeedY		12
		Dc	0	;OffsetX	16
		Dc	0	;OffsetY	18
		Dc	2	;AnimDelay	20
		Dc.b	0	;AnimCon/PieceFlags	22
		Dc.b	0	;AnimDir/PieceValue	23
		Dc.l	0	;Unused		24
		Dc	-1	;Duration	28
		Dc	1	;EndType	30
		Dc	-1	;EndUnit	32
		Dc	2	;EndAnimDelay	34
		Dc.b	0	;EndAnimCon/EndPieceFlags	36
		Dc.b	0	;EndAnimDir/EndPieceValue	37
		Dc.l	0	;Unused		38
		Dc	0	;EndOffsetX	42
		Dc	0	;EndOffsetY	44
		Dc	-1	;EndSound	46
		Blk.b	16,0	;Unused		48
*---------------
Weap_PlayScreen:Bsr.w	Get_Screen_Mem
		Bsr.w	Get_Bob_Mem
	*-- Fill in test object
		Jsr	Find_Object_Vacancy	;###
		Move	#$8000,(a5)
		Jsr	Get_Anim_LAdr	;###
		Tst.l	(a2)
		Beq.b	WPS_NAn
		Move.l	(a2),a0
		Jsr	Prep_Object_Anim	;###
		Move	#32767,40(a5)

	WPS_NAn:Clr	GM_OutCnt

		Clr	Song_Playing
		Jsr	Get_Song_LAdr	;###
		Tst.l	(a2)
		Beq.b	WPS_NSg
		Move.l	(a2),a2
		Move	6(a2),MasterVol
		Move	20(a2),d0
		Move.l	Mem_ModlList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	WPS_NSg
		Move.l	(a2),a0
		Add	#20,a0
		Lea	Variables,a5	;###
		Lea	$dff000,a6
		Jsr	MT_Init		;###
		Move	#1,Song_Playing
	WPS_NSg:
		Jsr	Erase		;###
		Move	#'WP',Play_Mode
		Jsr	Leave_Dos	;###
		Jsr	Chip		;Feed Custom Chips ###
		Jsr	Game_Palette	;###

	WPS_M1:	Jsr	Game_Background	;###
		Btst	#6,$bfe001
		Bne.b	WPS_M1

	WPS_M3:	Moveq.l	#127,d0
	WPS_M2:	Btst	#6,$bfe001
		Beq.b	WPS_M3
		Dbf	d0,WPS_M2

		Jsr	Enter_Dos	;###

		Move	Song_Playing,d0	;###
		Beq.b	WPS_NPl
		Clr	Song_Playing
		Lea	$dff000,a6
		Jsr	MT_End
	WPS_NPl:
		Bsr.w	Free_Play_Mem
	WPS_End:Rts
*---------------
Update_WeapBuf:	Lea	Weap_Info(pc),a3
		Jmp	Update_UnitBuf	;###
*---------------
Weap_MaxOut:	Move	WeapList_Len(pc),d0
		Beq.b	WMO_Ed
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	WMO_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
	*-- Find current Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		
		Move.l	Convert_Value(pc),d0
		Move	d0,8(a1)
		Bsr.b	Upd_Weap_MOutD
		Bsr.b	Upd_Weap_MOutG
	WMO_Ed:	Rts
*---------------
Upd_Weap_MOutD:	Move	WeapList_Len(pc),d0
		Beq.b	UWMO_Ed
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	UWMO_Ed
		Move.l	(a2),a1
	*-- Find current Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1

		Move	8(a1),d0
		Lea	Weap_MaxOutNT+5(pc),a0
		Move	#$104,d7
		Bsr.w	Conv
	UWMO_Ed:Rts
*---------------
Upd_Weap_MOutG:	Lea	WeapLay(pc),a5
		Lea	GWeap_MaxOut(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_AmmoDrain:	Move	WeapList_Len(pc),d0
		Beq.b	WAD_Ed
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	WAD_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
	*-- Find current Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		
		Move.l	Convert_Value(pc),d0
		Move	d0,4(a1)
		Bsr.b	Upd_Weap_ADrnD
		Bsr.b	Upd_Weap_ADrnG
	WAD_Ed:	Rts
*---------------
Upd_Weap_ADrnD:	Move	WeapList_Len(pc),d0
		Beq.b	UWAD_Ed
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	UWAD_Ed
		Move.l	(a2),a1
	*-- Find current Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1

		Move	4(a1),d0
		Lea	Weap_ADrainNT+5(pc),a0
		Move	#$8104,d7
		Bsr.w	Conv
	UWAD_Ed:Rts
*---------------
Upd_Weap_ADrnG:	Lea	WeapLay(pc),a5
		Lea	GWeap_AmmoDrain(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_FireDelay:	Move	WeapList_Len(pc),d0
		Beq.b	WFD_Ed
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	WFD_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
	*-- Find current Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		
		Move.l	Convert_Value(pc),d0
		Move	d0,6(a1)
		Bsr.b	Upd_Weap_FDelD
		Bsr.b	Upd_Weap_FDelG
	WFD_Ed:	Rts
*---------------
Upd_Weap_FDelD:	Move	WeapList_Len(pc),d0
		Beq.b	UWFD_Ed
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	UWFD_Ed
		Move.l	(a2),a1
	*-- Find current Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1

		Move	6(a1),d0
		Lea	Weap_FDelayNT+5(pc),a0
		Move	#$104,d7
		Bsr.w	Conv
	UWFD_Ed:Rts
*---------------
Upd_Weap_FDelG:	Lea	WeapLay(pc),a5
		Lea	GWeap_FDelay(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_OffsetX:	Move	#16,d5
		Bra.b	WOX_Cm
Weap_OffsetY:	Move	#18,d5
	WOX_Cm:	Bsr.w	Get_Shot_Adr
		Beq.b	WOX_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,0(a1,d5.w)
		Bsr.b	Upd_Weap_OffsD
		Bsr.b	Upd_Weap_OffsG
	WOX_Ed:	Rts
*---------------
Upd_Weap_OffsD:	Bsr.w	Get_Shot_Adr
		Beq.b	UWO_Ed
	*-- Convert numbers
		Move	16(a1),d0
		Lea	Weap_OffsetXNT+3(pc),a0
		Move	#$8102,d7
		Bsr.w	Conv
		Move	18(a1),d0
		Lea	Weap_OffsetYNT+3(pc),a0
		Move	#$8102,d7
		Bsr.w	Conv
	UWO_Ed:	Rts
*---------------
Upd_Weap_OffsG:	Lea	WeapLay(pc),a5
		Lea	GWeap_OffsetX(pc),a4
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		
		Lea	GWeap_OffsetY(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_SpeedInt:	Bsr.w	Get_Shot_Adr
		Beq.b	WSI_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,8(a1)
		Bsr.b	Upd_Weap_SpdID
		Bsr.b	Upd_Weap_SpdIG
	WSI_Ed:	Rts
*---------------
Upd_Weap_SpdID:	Bsr.w	Get_Shot_Adr
		Beq.b	UWSI_Ed
		Move	8(a1),d0
		Lea	Weap_SpeedIntNT+3(pc),a0
		Move	#$8102,d7
		Bsr.w	Conv
	UWSI_Ed:Rts
*---------------
Upd_Weap_SpdIG:	Lea	WeapLay(pc),a5
		Lea	GWeap_SpeedInt(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_AngleInt:	Bsr.w	Get_Shot_Adr
		Beq.b	WAI_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,12(a1)
		Bsr.b	Upd_Weap_AngID
		Bsr.b	Upd_Weap_AngIG
	WAI_Ed:	Rts
*---------------
Upd_Weap_AngID:	Bsr.w	Get_Shot_Adr
		Beq.b	UWAI_Ed
		Move	12(a1),d0
		Lea	Weap_AngleIntNT+3(pc),a0
		Move	#$8102,d7
		Bsr.w	Conv
	UWAI_Ed:Rts
*---------------
Upd_Weap_AngIG:	Lea	WeapLay(pc),a5
		Lea	GWeap_AngleInt(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_Duration:	Bsr.w	Get_Shot_Adr
		Beq.b	WD_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,28(a1)
		Bsr.b	Upd_Weap_DurD
		Bsr.b	Upd_Weap_DurG
	WD_Ed:	Rts
*---------------
Upd_Weap_DurD:	Bsr.w	Get_Shot_Adr
		Beq.b	UWD_Ed
		Move	28(a1),d0
		Lea	Weap_DurationNT+5(pc),a0
		Move	#$8104,d7
		Bsr.w	Conv
	UWD_Ed:	Rts
*---------------
Upd_Weap_DurG:	Lea	WeapLay(pc),a5
		Lea	GWeap_Duration(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_Power:	Bsr.w	Get_Shot_Adr
		Beq.b	WP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,4(a1)
		Bsr.b	Upd_Weap_PwrD
		Bsr.b	Upd_Weap_PwrG
	WP_Ed:	Rts
*---------------
Upd_Weap_PwrD:	Bsr.w	Get_Shot_Adr
		Beq.b	UWP_Ed
		Move	4(a1),d0
		Lea	Weap_PowerNT+5(pc),a0
		Move	#$8104,d7
		Bsr.w	Conv
	UWP_Ed:	Rts
*---------------
Upd_Weap_PwrG:	Lea	WeapLay(pc),a5
		Lea	GWeap_Power(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_HitPower:	Bsr.w	Get_Shot_Adr
		Beq.b	WHP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,6(a1)
		Bsr.b	Upd_Weap_HPwrD
		Bsr.b	Upd_Weap_HPwrG
	WHP_Ed:	Rts
*---------------
Upd_Weap_HPwrD:	Bsr.w	Get_Shot_Adr
		Beq.b	UWHP_Ed
		Move	6(a1),d0
		Lea	Weap_HitPowerNT+5(pc),a0
		Move	#$8104,d7
		Bsr.w	Conv
	UWHP_Ed:Rts
*---------------
Upd_Weap_HPwrG:	Lea	WeapLay(pc),a5
		Lea	GWeap_HitPower(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_AnimDel:	Bsr.w	Get_Shot_Adr
		Beq.b	WAD_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value(pc),d0
		Move	d0,20(a1)
		Bsr.b	Upd_Weap_ADelD
		Bsr.b	Upd_Weap_ADelG
	WAD_E:	Rts
*---------------
Upd_Weap_ADelD:	Bsr.w	Get_Shot_Adr
		Beq.b	UWAD_E
		Cmp	#2,(a1)	;Type=Anim?
		Bne.b	UWAD_E
		Move	20(a1),d0
		Lea	Weap_AnimDelNT+2(pc),a0
		Move	#$0101,d7
		Bsr.w	Conv
	UWAD_E:	Rts
*---------------
Upd_Weap_ADelG:	Lea	WeapLay(pc),a5
		Lea	GWeap_AnimDel(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_PrvPowerup:Subq	#1,Cur_Powerup
		Move	#1,Cur_Shot
		Bra.w	Change_Powerup
*---------------
Weap_NxtPowerup:Addq	#1,Cur_Powerup
		Move	#1,Cur_Shot
		Bra.w	Change_Powerup
*---------------
Weap_PrvShot:	Subq	#1,Cur_Shot
		Bra.w	Change_Shot
*---------------
Weap_NxtShot:	Addq	#1,Cur_Shot
		Bra.w	Change_Shot
*---------------
Weap_AddPowerup:Move	#1,WAP_Amount
	WAP_Com:Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.w	WAP_End
		Move.l	a2,WAP_ListAdr
		Bsr.w	Update_WeapBuf
	*-- Find Powerup (A1->Address)
		Move.l	Mem_WeapBuf(pc),a0
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Calculate add lengths
		Move	(a1),d0			;Get number of Shots
		Lsl	#6,d0			;64 bytes per Shot
		Add	#64,d0			;Plus 64 for Powerup data
		Move	d0,WAP_PowerupAdd
		Addq	#2,d0			;Plus 2 for Offset
		Mulu	WAP_Amount(pc),d0	;* Number of copies
		Move	d0,WAP_BytesAdd
		Move	WAP_Amount(pc),d0
		Add	d0,d0			;2 bytes per Offset
		Move	d0,WAP_OffstAdd
	*-- Free old Weapon
		Move.l	WAP_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Weapon
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get Unit Size
		Add	WAP_BytesAdd(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	WAP_ListAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_MemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Weapon address
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	WAP_BytesAdd(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Add	WAP_Amount(pc),d7	;+
		Move	d7,(a1)+		;+
	*-- Copy Offsets
		Move	WAP_OffstAdd(pc),d1
		Clr	d0
	WAP_LFO:Move	(a2)+,d2
		Add	d1,d2
		Move	d2,(a1)+
		Addq	#1,d0
		Cmp	Cur_Powerup(pc),d0
		Bne.b	WAP_NoP

		Move	WAP_Amount(pc),d3
	WAP_LIO:Add	WAP_PowerupAdd(pc),d2
		Move	d2,(a1)+
		Addq	#1,d0
		Subq	#1,d3
		Bne.b	WAP_LIO
		Move	WAP_BytesAdd(pc),d1
	WAP_NoP:Cmp	d7,d0
		Bne.b	WAP_LFO
	*-- Copy from start to edit point
		Moveq.l	#1,d6
	WAP_C2L:Cmp	Cur_Powerup(pc),d6
		Beq.b	WAP_C2E
		Move	(a2),d0			;Get Amount
		Moveq.l	#64/4-1,d1		;Copy Powerup data
	WAP_CpP:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WAP_CpP		;+
	WAP_C1L:Tst	d0			;Any Shots left?
		Beq.b	WAP_C1E			;No
		Moveq.l	#64/4-1,d1		;Copy Shot data
	WAP_CpS:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WAP_CpS		;+
		Subq	#1,d0			;Count number of Shots
		Bra.b	WAP_C1L			;Loop
	WAP_C1E:Addq	#1,d6			;Count Powerups
		Bra.b	WAP_C2L			;Loop
	*-- Add Powerups
	WAP_C2E:Move	WAP_Amount(pc),d3
	WAP_C3L:Addq	#1,d6
		Clr	d0
	WAP_C6L:Move.b	0(a2,d0.w),(a1)+
		Addq	#1,d0
		Cmp	WAP_PowerupAdd(pc),d0
		Bne.b	WAP_C6L
		Dbf	d3,WAP_C3L
		Add	WAP_PowerupAdd(pc),a2
	*-- Copy from edit point to end
	WAP_C4L:Cmp	d7,d6			;Count>Total?
		Bgt.b	WAP_C4E			;Yes, end
		Move	(a2),d0			;Get Amount
		Moveq.l	#64/4-1,d1		;Copy Powerup data
	WAP_CP2:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WAP_CP2		;+
	WAP_C5L:Tst.b	d0			;Any Shots left?
		Beq.b	WAP_C5E			;No
		Moveq.l	#64/4-1,d1		;Copy Shot data
	WAP_CS2:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WAP_CS2		;+
		Subq.b	#1,d0			;Count number of Shots
		Bra.b	WAP_C5L			;Loop
	WAP_C5E:Addq	#1,d6			;Count Powerups
		Bra.b	WAP_C4L			;Loop
	WAP_C4E:
	WAP_NOv:Addq	#1,Cur_Powerup
		Move	#1,Cur_Shot
		Bsr.w	Upd_WeapNumbD
		Bsr.w	Upd_WeapNumbG
		Bsr.w	Change_Powerup
	WAP_End:Rts
WAP_ListAdr:	Dc.l	0
WAP_Amount:	Dc	0
WAP_PowerupAdd:	Dc	0
WAP_BytesAdd:	Dc	0
WAP_OffstAdd:	Dc	0
Cur_Powerup:	Dc	1
Cur_Shot:	Dc	1
*---------------
Weap_DelPowerup:Move	#1,WDP_Amount
	WDP_Com:Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.w	WDP_End
		Move.l	a2,WDP_ListAdr
		Move.l	(a2),a0
		Move	6(a0),d0		;Delete too many?
		Sub	WDP_Amount(pc),d0	;+
		Cmp	#1,d0			;+
		Blt.w	WDP_End			;+ Yes!
		Bsr.w	Update_WeapBuf
		Move.l	WDP_ListAdr(pc),a0
		Move.l	(a0),a0
	*-- Find out how many bytes shorter Weapon will be.
		Clr	d7			;ByteCnt
		Clr	d4			;DeletePowerupCnt
		Move	Cur_Powerup(pc),d3	;PowerupCnt
	*-- Find Powerup (A1->Address)
	WDP_SLp:Move.l	Mem_WeapBuf(pc),a0
		Move	d3,d0
		Add	d0,d0
		Move	08-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1

		Move	(a1),d6			;Get number of Shots
		Lsl	#6,d6			;* 64 bytes per Shot
		Add	#64,d6			;+ 64 for Powerup data
		Addq	#2,d6			;+ 2 for Offset
		Add	d6,d7
		
		Addq	#1,d3
		Move.l	Mem_WeapBuf(pc),a0	;Reached the end?
		Cmp	6(a0),d3		;+ Compare with Total
		Ble.b	WDP_NOv			;+ No.
		Moveq.l	#1,d3			;+ Yes! Loop!
	WDP_NOv:
		Addq	#1,d4
		Cmp	WDP_Amount(pc),d4
		Bne.b	WDP_SLp

		Move	d7,WDP_BytesSub
	*-- Free old Weapon
		Move.l	WDP_ListAdr(pc),a4
		Jsr	Free_Unit	;###
	*-- Allocate new space for Weapon
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0
		Sub	WDP_BytesSub(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	WDP_ListAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Weapon address
		Move.l	a1,WDP_AdrCnt
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub	WDP_BytesSub(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Sub	WDP_Amount(pc),d7	;+
		Move	d7,(a1)+		;+
	*-- Skip X bytes for Offsets
		Move.l	a1,a3	;Save start address for Offsets
		Add	d7,d7	;Total*2
		Add	d7,a1

		Clr	d4
		Moveq.l	#1,d7	;Powerup Counter
		
		Clr	WDP_LoopFlg
		Move.l	Mem_WeapBuf(pc),a0	;Get buffer address
		Move	6(a0),d0		;Total Powerups
		Sub	Cur_Powerup(pc),d0	;Minus Current Powerup
		Addq	#1,d0			;Plus 1 = Powerups Left
		Sub	WDP_Amount(pc),d0	;Do we have to loop?
		Bpl.b	WDP_NLp			;No
		Move	#1,WDP_LoopFlg		;Yes, set flag
		Neg	d0
		Move	d0,d7
		Addq	#1,d7
	WDP_NLp:
	*-- Have we reached current powerup (which should be deleted)
	WDP_CLp:Cmp	Cur_Powerup(pc),d7
		Bne.b	WDP_NCu
		Add	WDP_Amount(pc),d7	;Skip Powerups to delete
	WDP_NCu:
	*-- Find Powerup (A2->Address)
		Move.l	Mem_WeapBuf(pc),a0
		Move	d7,d0
		Add	d0,d0
		Move	08-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a2

		Move.l	a1,d0
		Sub.l	WDP_AdrCnt(pc),d0
		Move	d0,(a3)+
	*-- Copy Powerup
		Move	(a2),d0			;Get Amount
		Moveq.l	#64/4-1,d1		;Copy Powerup data
	WDP_CpP:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WDP_CpP		;+
	WDP_C1L:Tst	d0			;Any Shots left?
		Beq.b	WDP_C1E			;No
		Moveq.l	#64/4-1,d1		;Copy Shot data
	WDP_CpS:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WDP_CpS		;+
		Subq	#1,d0			;Count number of Shots
		Bra.b	WDP_C1L			;Loop
	WDP_C1E:Addq	#1,d7
		Addq	#1,d4
		Move.l	WDP_ListAdr(pc),a0
		Move.l	(a0),a0
		Cmp	6(a0),d4
		Bne.b	WDP_CLp
	*-- Select current Powerup
		Move	Cur_Powerup(pc),d7

		Move.l	WDP_ListAdr(pc),a0
		Move.l	(a0),a0
		Cmp	6(a0),d7	;Total
		Ble.b	WDP_SCP
		Moveq.l	#1,d7
	WDP_SCP:Move	d7,Cur_Powerup
		Move	#1,Cur_Shot
		Bsr.w	Upd_WeapNumbD
		Bsr.w	Upd_WeapNumbG
		Bsr.w	Change_Powerup
	WDP_End:Rts
WDP_AdrCnt:	Dc.l	0
WDP_ListAdr:	Dc.l	0
WDP_Amount:	Dc	0
WDP_BytesSub:	Dc	0
WDP_LoopFlg:	Dc	0
*---------------
Weap_AddShot:
	*-- Get list address (A2)
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.w	WAS_End
		Move.l	a2,WAS_LAdr
		Bsr.w	Update_WeapBuf
	*-- Free old Weapon
		Move.l	WAS_LAdr(pc),a4
		Jsr	Free_Unit	;###
	*-- Allocate new space for Weapon
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get BytSize
		Add.l	#64,d0			;Add 64 bytes for new shot
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	WAS_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Weapon address
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+	;Id
		Move.l	(a2)+,d0	;BytSize
		Add.l	#64,d0		;Add 64 bytes for new shot
		Move.l	d0,(a1)+	;+
		Move	(a2)+,d7	;Total
		Move	d7,(a1)+	;+
	*-- Copy Offsets
		Clr	d1
		Clr	d0
	WAS_LFO:Move	(a2)+,d2
		Add	d1,d2
		Move	d2,(a1)+
		Addq	#1,d0
		Cmp	Cur_Powerup(pc),d0
		Bne.b	WAS_NoF
		Moveq.l	#64,d1
	WAS_NoF:Cmp	d7,d0
		Bne.b	WAS_LFO
	*-- Copy from start to edit point
		Moveq.l	#1,d6
	WAS_C2L:Cmp	Cur_Powerup(pc),d6
		Beq.b	WAS_C2E
		Move	(a2),d0		;Get Amount
		Moveq.l	#64/4-1,d1	;Copy Powerup data
	WAS_CpP:Move.l	(a2)+,(a1)+	;+
		Dbf	d1,WAS_CpP	;+
	WAS_C1L:Tst	d0		;Any Shots left?
		Beq.b	WAS_C1E		;No
		Moveq.l	#64/4-1,d1	;Copy Shot data
	WAS_CpS:Move.l	(a2)+,(a1)+	;+
		Dbf	d1,WAS_CpS	;+
		Subq	#1,d0		;Count number of Shots
		Bra.b	WAS_C1L		;Loop
	WAS_C1E:Addq	#1,d6		;Count Powerups
		Bra.b	WAS_C2L		;Loop
	*-- Add Shot
	WAS_C2E:Move	(a2)+,d0	;Amount
		Addq	#1,d0		;+ Add one Shot
		Move	d0,d5		;Save in D5.
		Move	d0,(a1)+	;+
		Moveq.l	#62/2-1,d1	;Copy rest of Powerup data
	WAS_CRP:Move	(a2)+,(a1)+	;+
		Dbf	d1,WAS_CRP	;+
		Subq.b	#1,d0
	WAS_C3L:Tst.b	d0
		Beq.b	WAS_C3E
		Moveq.l	#64/4-1,d1	;Copy Shot data
	WAS_CRS:Move.l	(a2)+,(a1)+	;+
		Dbf	d1,WAS_CRS	;+
		Subq.b	#1,d0		;Count number of Shots
		Bra.b	WAS_C3L		;Loop
	*-- Insert new Shot
	WAS_C3E:Move.l	Mem_WeapBuf(pc),a3	;Get buffer address
	*-- Find current Powerup and Shot
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a3,d0.w),d0
		Lea	00(a3,d0.w),a3
		Move	Cur_Shot(pc),d0
		Lsl	#6,d0
		Add	d0,a3
		Moveq.l	#64/4-1,d1	;Copy Shot data
	WAS_INS:Move.l	(a3)+,(a1)+	;+
		Dbf	d1,WAS_INS	;+
		Move	d5,Cur_Shot
	*-- Copy from edit point to end
		Addq	#1,d6
	WAS_C4L:Cmp	d7,d6			;Count>Total?
		Bgt.b	WAS_C4E			;Yes, end
		Move	(a2),d0			;Get Amount
		Moveq.l	#64/4-1,d1		;Copy Powerup data
	WAS_CP2:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WAS_CP2		;+
	WAS_C5L:Tst.b	d0			;Any Shots left?
		Beq.b	WAS_C5E			;No
		Moveq.l	#64/4-1,d1		;Copy Shot data
	WAS_CS2:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WAS_CS2		;+
		Subq.b	#1,d0			;Count number of Shots
		Bra.b	WAS_C5L			;Loop
	WAS_C5E:Addq	#1,d6			;Count Powerups
		Bra.b	WAS_C4L			;Loop
	WAS_C4E:Bsr.w	Change_Shot
	WAS_End:Rts
WAS_LAdr:	Dc.l	0
*---------------
Weap_DelShot:
	*-- Get list address (A2)
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.w	WDS_End
		Move.l	a2,WDS_LAdr
		Move.l	(a2),a0
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
		Move	(a1),d0		;More that 1 Shot in Powerup?
		Cmp	#1,d0		;+
		Ble.w	WDS_End		;+ No
		Move	Cur_Shot(pc),d0	;Any Shot selected?
		Beq.w	WDS_End		;No
		Cmp	(a1),d0		;CurrentShot > Amount?
		Bgt.w	WDS_End		;Yes
		Bsr.w	Update_WeapBuf
	*-- Free old Weapon
		Move.l	WDS_LAdr(pc),a4
		Jsr	Free_Unit	;###
	*-- Allocate new space for Weapon
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
		Move.l	2(a2),d0		;Get BytSize
		Sub.l	#64,d0			;Sub 64 bytes for 1 Shot
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	WDS_LAdr(pc),a0
		Move.l	d0,(a0)
		Beq.w	Mess_CMemErr
		Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Weapon address
		Move.l	Mem_WeapBuf(pc),a2	;Get buffer address
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub.l	#64,d0			;Sub 64 bytes for 1 Shot
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Move	d7,(a1)+		;+
	*-- Copy Offsets
		Clr	d1
		Clr	d0
	WDS_LFO:Move	(a2)+,d2
		Sub	d1,d2
		Move	d2,(a1)+
		Addq	#1,d0
		Cmp	Cur_Powerup(pc),d0
		Bne.b	WDS_NoF
		Moveq.l	#64,d1
	WDS_NoF:Cmp	d7,d0
		Bne.b	WDS_LFO
	*-- Copy from start to end
		Moveq.l	#1,d6
	WDS_C2L:Cmp	d7,d6			;Count>Total?
		Bgt.b	WDS_C2E			;Yes, end
		Move	(a2)+,d0		;Get Amount
		Move	d0,d5
		Cmp	Cur_Powerup(pc),d6	;Is this current Powerup?
		Bne.b	WDS_NSb			;No
		Subq	#1,d0			;Minus 1 Shot
	WDS_NSb:Move	d0,(a1)+
		Moveq.l	#62/2-1,d1		;Copy Powerup data
	WDS_CpP:Move	(a2)+,(a1)+		;+
		Dbf	d1,WDS_CpP		;+
		Clr	d2			;Clear Shot Counter
	WDS_C1L:Tst	d5
		Beq.b	WDS_C1E
		Addq	#1,d2			;Count Shots
		Cmp	Cur_Powerup(pc),d6	;Is this current Powerup?
		Bne.b	WDS_Ski			;No
		Cmp	Cur_Shot(pc),d2		;Is this current Shot?
		Beq.b	WDS_SkP			;Yes, skip copy
	WDS_Ski:Moveq.l	#64/4-1,d1		;Copy Shot data
	WDS_CpS:Move.l	(a2)+,(a1)+		;+
		Dbf	d1,WDS_CpS		;+
		Bra.b	WDS_SkA
	WDS_SkP:Add	#64,a2
	WDS_SkA:Subq	#1,d5			;Count number of Shots.
		Bra.b	WDS_C1L			;Loop
	WDS_C1E:Addq	#1,d6			;Count Powerups
		Bra.b	WDS_C2L			;Loop
	WDS_C2E:Subq	#1,Cur_Shot
		Bne.b	WDS_CuO
		Move	#1,Cur_Shot
	WDS_CuO:Bsr.w	Change_Shot
	WDS_End:Rts
WDS_LAdr:	Dc.l	0
*---------------
Weap_UnitType:	Clr	d7
		Lea	GWeap_Piec(pc),a0
		Btst	#0,4(a0)
		Beq.b	WUT_NPi
		Moveq.l	#1,d7
	WUT_NPi:
		Lea	GWeap_Anim(pc),a0
		Btst	#0,4(a0)
		Beq.b	WUT_NAn
		Moveq.l	#2,d7
	WUT_NAn:
		Lea	GWeap_Objc(pc),a0
		Btst	#0,4(a0)
		Beq.b	WUT_NOb
		Moveq.l	#4,d7
	WUT_NOb:
		Bsr.w	Get_Shot_Adr
		Beq.b	WUT_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	d7,(a1)
		Bsr.w	Weap_UseUnit
		Bsr.b	Upd_WUnitTypeD
		Bsr.b	Upd_WUnitTypeG
	WUT_End:Rts
*---------------
Upd_WUnitTypeD:	Bsr.w	Get_Shot_Adr
		Beq.b	UUT_End
	*-- Decide on type
		Lea	GWeap_Piec(pc),a2
		Lea	GWeap_Anim(pc),a3
		Lea	GWeap_Objc(pc),a4
		Move	(a1),d7

		Lea	Weap_NoneDL(pc),a1

		Bclr	#0,4(a2)
		Btst	#0,d7
		Beq.b	UUT_NPi
		Bset	#0,4(a2)
		Lea	Weap_PiecDL(pc),a1
	UUT_NPi:
		Bclr	#0,4(a3)
		Btst	#1,d7
		Beq.b	UUT_NAn
		Bset	#0,4(a3)
		Lea	Weap_AnimDL(pc),a1
	UUT_NAn:
		Bclr	#0,4(a4)
		Btst	#2,d7
		Beq.b	UUT_NOb
		Bset	#0,4(a4)
		Lea	Weap_ObjcDL(pc),a1
	UUT_NOb:
		Lea	GWeap_TypeJump(pc),a0
		Move.l	a1,2(a0)
	UUT_End:Rts
*---------------
Upd_WUnitTypeG:	Lea	WeapLay(pc),a5
		Lea	GWeap_Piec(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some

		Lea	WeapLay(pc),a5
		Lea	GWeap_TypeJump(pc),a4
		Bra.w	Draw_All
*---------------
Weap_UseUnit:	Bsr.w	Get_Shot_Adr
		Beq.w	WUU_End
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Decide on type
		Move	(a1),d7
		Btst	#0,d7
		Bne.b	WUU_Pi
		Btst	#1,d7
		Bne.b	WUU_An
		Btst	#2,d7
		Bne.b	WUU_Ob
		Bra.b	WUU_End
	*-- Check that Piece exists
	WUU_Pi:	Move	PiecList_Len(pc),d0
		Beq.b	WUU_End
		Jsr	Get_Piec_LAdr	;###
		Tst.l	(a2)
		Beq.b	WUU_End
		Move.l	(a2),a2
		Move.b	18(a2),22(a1)
		Move	Cur_Piec(pc),2(a1)
		Bra.b	WUU_Fin
	*-- Check that Anim exists
	WUU_An:	Move	AnimList_Len(pc),d0
		Beq.b	WUU_End
		Jsr	Get_Anim_LAdr	;###
		Tst.l	(a2)
		Beq.b	WUU_End
		Move	Cur_Anim(pc),2(a1)
		Move.l	(a2),a2		;Copy Anim Delay
		Clr	d0		;+
		Move.b	7(a2),d0	;+
		Move	d0,20(a1)	;+
		Move.b	8(a2),22(a1)	;Copy Anim Control
		Move.b	9(a2),23(a1)	;Copy Anim Direction
		Bra.b	WUU_Fin
	*-- Check that Object exists
	WUU_Ob:	Move	ObjcList_Len(pc),d0
		Beq.b	WUU_End
		Jsr	Get_Objc_LAdr	;###
		Tst.l	(a2)
		Beq.b	WUU_End
		Move	Cur_Objc(pc),2(a1)

	WUU_Fin:Bsr.w	Upd_UNameD
		Bsr.w	Upd_UNameG
		Bsr.w	Upd_Weap_TypeG
	WUU_End:Rts
*---------------
Weap_UnitName:	Bsr.w	Get_Shot_Adr
		Beq.w	WUN_End

		Move	(a1),d7
		Btst	#0,d7
		Bne.b	WUN_Pi
		Btst	#1,d7
		Bne.b	WUN_An
		Btst	#2,d7
		Bne.b	WUN_Ob
		Bra.b	WUN_End

	WUN_Pi:	Move	2(a1),d0
		Bmi.b	WUN_NPi
		Move	d0,Cur_Piec
	WUN_NPi:Lea	PiecLay,a5	;###
		Tst.l	(a5)
		Beq.b	WUN_PiO
		Jsr	Change_Piec	;###
		Lea	PiecLay,a5	;###
	WUN_PiO:Jmp	Open_Layer

	WUN_An:	Move	2(a1),d0
		Bmi.b	WUN_NAn
		Move	d0,Cur_Anim
	WUN_NAn:Lea	AnimLay,a5	;###
		Tst.l	(a5)
		Beq.b	WUN_AnO
		Jsr	Change_Anim	;###
		Lea	AnimLay,a5	;###
	WUN_AnO:Jmp	Open_Layer
		
	WUN_Ob:	Move	2(a1),d0
		Bmi.b	WUN_NOb
		Move	d0,Cur_Objc
	WUN_NOb:Lea	ObjcLay,a5	;###
		Tst.l	(a5)
		Beq.b	WUN_ObO
		Jsr	Change_Objc	;###
		Lea	ObjcLay,a5	;###
	WUN_ObO:Jmp	Open_Layer
	WUN_End:Rts
*---------------
Upd_ShotNumbD:	Move	WeapList_Len(pc),d0
		Beq.b	USN_End
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	USN_End
		Move.l	(a2),a1
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		Move	(a1),d0
		Lea	Weap_ShotsNT+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
	*-- Current Shot
		Bsr.w	Get_Weap_LAdr
		Move.l	(a2),a1
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		Move	(a1),d0
		Cmp	#1,Cur_Shot
		Bge.b	USN_TNU
		Move	(a1),d0
		Move	d0,Cur_Shot
	USN_TNU:Move	(a1),d0
		Cmp	Cur_Shot(pc),d0
		Bge.b	USN_TNO
		Move	#1,Cur_Shot
	USN_TNO:Move	Cur_Shot(pc),d0
		Lea	Weap_ShotNT+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
	USN_End:Rts
*---------------
Upd_ShotNumbG:	Lea	WeapLay(pc),a5
		Lea	Weap_ShotsUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some

		Lea	Weap_ShotUpd(pc),a4
		Moveq.l	#1,d7
		Bra.w	Draw_Some
*---------------
Upd_WeapNumbD:	Move	WeapList_Len(pc),d0
		Beq.b	UWN_End
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	UWN_End
		Move.l	(a2),a0
		Move	6(a0),d0
		Lea	Weap_TotalNT+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
	*-- Current Powerup
		Bsr.w	Get_Weap_LAdr
		Move.l	(a2),a0
		Cmp	#1,Cur_Powerup
		Bge.b	UWN_TNU
		Move	6(a0),d0
		Move	d0,Cur_Powerup
	UWN_TNU:Move	6(a0),d0
		Cmp	Cur_Powerup(pc),d0
		Bge.b	UWN_TNO
		Move	#1,Cur_Powerup
	UWN_TNO:Move	Cur_Powerup(pc),d0
		Lea	Weap_PowerupNT+2(pc),a0
		Move	#$101,d7
		Bsr.w	Conv
	UWN_End:Rts
*---------------
Upd_WeapNumbG:	Lea	WeapLay(pc),a5
		Lea	Weap_TotalUpd(pc),a4
		Moveq.l	#1,d7
		Bsr.w	Draw_Some

		Lea	Weap_PowerupUpd(pc),a4
		Moveq.l	#1,d7
		Bra.w	Draw_Some
*---------------
Weap_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Upd_WeapNameD:	Lea	Weap_Info(pc),a3
		Lea	Weap_NameUpd(pc),a4
		Bra.w	Upd_UnitNameD
*---------------
Upd_WeapNameG:	Lea	WeapLay(pc),a5
		Lea	Weap_NameUpd(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Change_Weap:	Move	#1,Cur_Powerup
		Lea	WeapLay(pc),a5
		Lea	GWeap_UpdAll(pc),a4
		Bsr.w	Draw_All

		Lea	Weap_Info(pc),a3
		Bsr.w	Upd_SelcUnit

		Move	WeapList_Len(pc),d0
		Beq.b	CW_End
		Bsr.b	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	CW_End
		Bsr.b	Change_Powerup
	CW_End:	Rts
*---------------
Change_Powerup:	Bsr.w	Upd_WeapNumbD
		Bsr.b	Upd_WeapNumbG
		Bsr.b	Upd_WSNameD
		Bsr.w	Upd_WSNameG
		Bsr.w	Upd_Weap_FDelD
		Bsr.w	Upd_Weap_FDelG
		Bsr.w	Upd_Weap_ADrnD
		Bsr.w	Upd_Weap_ADrnG
		Bsr.w	Upd_Weap_MOutD
		Bsr.w	Upd_Weap_MOutG
		Bra.w	Change_Shot
*---------------
Change_Shot:	Bsr.w	Upd_ShotNumbD
		Bsr.w	Upd_UNameD
		Bsr.w	Upd_WUnitTypeD
		Bsr.w	Upd_Weap_SpdID
		Bsr.w	Upd_Weap_AngID
		Bsr.w	Upd_Weap_OffsD
		Bsr.w	Upd_Weap_DurD
		Bsr.w	Upd_Weap_PwrD
		Bsr.w	Upd_Weap_HPwrD
		Bsr.w	Upd_Weap_EOffsD
		Bsr.w	Upd_WEUnitTypeD
		Bsr.w	Upd_EUNameD
		Bsr.w	Upd_ESNameD

		Lea	WeapLay,a5	;###
		Lea	GWeap_ShotAll(pc),a4
		Jmp	Draw_All	;###
*---------------
Get_Weap_LAdr:	Move.l	Mem_WeapList(pc),a2
		Clr.l	d0
		Move	Cur_Weap(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Upd_WSNameD:
	*-- Update name to drawlist
		Bsr.b	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	UWS_End
		Move.l	(a2),a1
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
	*-- Copy name
		Lea	GWeap_WSName(pc),a3
		Clr.l	20(a3)
		Move	10(a1),d0
		Bmi.b	UWS_End
		Ext.l	d0
		Move.l	Mem_SondList,a2		;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	UWS_End:Rts
*---------------
Upd_WSNameG:	Lea	WeapLay,a5	;###
		Lea	GWeap_WSName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Upd_Weap_TypeG:	Lea	WeapLay(pc),a5
		Lea	GWeap_TypeJump(pc),a4
		Bra.w	Draw_All
*---------------
Upd_UNameD:	Bsr.w	Get_Shot_Adr
		Beq.b	UUN_End

		Move	(a1),d7
		Btst	#0,d7
		Bne.b	UUN_Pi
		Btst	#1,d7
		Bne.b	UUN_An
		Btst	#2,d7
		Bne.b	UUN_Ob
	*-- Copy name
	UUN_Pi:	Move.l	Mem_PiecList,a2		;###
		Bra.b	UUN_Ok
	UUN_An:	Move.l	Mem_AnimList,a2		;###
		Bra.b	UUN_Ok
	UUN_Ob:	Move.l	Mem_ObjcList,a2		;###
	UUN_Ok:	Lea	GWeap_UName(pc),a3
		Clr.l	20(a3)
		Move	2(a1),d0
		Bmi.b	UUN_End
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	UUN_End:Rts
*---------------
Upd_UNameG:	Lea	WeapLay,a5	;###
		Lea	GWeap_UName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Weap_Sound:	Lea	SondLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Weap_UseSound:
	*-- Find Weapon
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	WUS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
	*-- Store new Sound data
		Jsr	Get_Sond_LAdr	;###
		Tst.l	(a2)
		Beq.b	WUS_Ed
		Move	Cur_Sond,10(a1)		;Write Sound	;###
		Bsr.w	Change_Powerup
	WUS_Ed:	Rts
*---------------
Weap_RemoveSound:
	*-- Find Weapon
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	WRS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
	*-- Store new Sound data
		Move	#-1,10(a1)		;Write 'Empty'
		Bsr.w	Change_Powerup
	WRS_Ed:	Rts
*---------------
Weap_SoundName:	Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	WSN_Ed
		Move.l	(a2),a1
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		Move	10(a1),d0		;Get Sound
		Bmi.b	WSN_No
		Move	d0,Cur_Sond
	WSN_No:	Lea	SondLay,a5	;###
		Tst.l	(a5)
		Beq.b	WSN_Op
		Jsr	Change_Sond	;###
		Lea	SondLay,a5	;###
	WSN_Op:	Jmp	Open_Layer	;###
	WSN_Ed:	Rts
*---------------
Weap_Load:	Move.l	WeapList(pc),a4
		Move.l	(a4),a4
		Move	Cur_Weap(pc),d4
		Move.l	#'WEAP',d0
		Bsr.w	Load_Unit
		Bsr.w	Change_Weap
		Bra.w	Load_WeapUnits
*---------------
Load_WeapUnits:	Move	#1,Cur_Powerup
		Move	#1,Cur_Shot
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.w	LWU_End
		Move.l	(a2),a2
		Move	6(a2),d7	;Get Total
		Lea	8(a2),a3	;Get Offsets adress

	LWU_LpP:Move.l	a2,a4		;Get Powerup
		Add	(a3)+,a4	;+

		Move	10(a4),d0	;Get Sound
		Bmi.b	LWU_NSo
		Move	d0,Cur_Sond
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Sond_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6

	LWU_NSo:Move	(a4),d6		;Get Amount
		Move.l	a4,a5		;Get Shot
		Move	#1,Cur_Shot
	LWU_LpS:Add	#64,a5
	*-- Load Start Unit
		Move	(a5),d0		;Get Type
		Beq.b	LWU_NTy
		Cmp	#1,d0
		Beq.b	LWU_Pi
		Cmp	#2,d0
		Beq.b	LWU_An
		Cmp	#4,d0
		Beq.b	LWU_Ob
		Bra.b	LWU_NTy

	LWU_Pi:	Move	2(a5),d0
		Bmi.b	LWU_NTy
		Move	d0,Cur_Piec
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Piec_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LWU_NTy

	LWU_An:	Move	2(a5),d0
		Bmi.b	LWU_NTy
		Move	d0,Cur_Anim
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Anim_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LWU_NTy

	LWU_Ob:	Move	2(a5),d0
		Bmi.b	LWU_NTy
		Move	d0,Cur_Objc
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Objc_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
	LWU_NTy:
	*-- Load End Unit
		Move	30(a5),d0	;Get Type
		Beq.b	LWU_ENT
		Cmp	#1,d0
		Beq.b	LWU_EPi
		Cmp	#2,d0
		Beq.b	LWU_EAn
		Cmp	#4,d0
		Beq.b	LWU_EOb
		Bra.b	LWU_ENT

	LWU_EPi:Move	32(a5),d0
		Bmi.b	LWU_ENT
		Move	d0,Cur_Piec
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Piec_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LWU_ENT

	LWU_EAn:Move	32(a5),d0
		Bmi.b	LWU_ENT
		Move	d0,Cur_Anim
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Anim_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LWU_ENT

	LWU_EOb:Move	32(a5),d0
		Bmi.b	LWU_ENT
		Move	d0,Cur_Objc
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Objc_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
	LWU_ENT:
		Move	46(a5),d0	;Get End Sound
		Bmi.b	LWU_NES
		Move	d0,Cur_Sond
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Sond_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
	LWU_NES:
		Addq	#1,Cur_Shot
		Subq	#1,d6
		Beq.b	LWU_FSh
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Change_Shot
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.w	LWU_LpS

	LWU_FSh:Addq	#1,Cur_Powerup
		Subq	#1,d7
		Beq.b	LWU_End
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Change_Powerup
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.w	LWU_LpP

	LWU_End:Move	#1,Cur_Powerup
		Move	#1,Cur_Shot
		Bra.w	Change_Weap
*---------------
Check_Weap:	Lea	Weap_Jump(pc),a0
		Move	WeapList_Len,d0	;###
		Beq.b	CWp_NUn
	*-- Find current Weapon, and check if it exists
		Move.l	Mem_WeapList,a2	;###
		Move	Cur_Weap,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Weap?
		Beq.b	CWp_No		;No
		Lea	Weap_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CWp_NUn:Lea	Weap_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CWp_No:	Lea	Weap_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
Weap_PiecFlipY:	Bsr.w	Get_Shot_Adr
		Beq.b	WPFY_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Bchg	#5,22(a1)
		Bsr.b	Upd_Weap_FlipYD
		Bsr.b	Upd_Weap_FlipYG
	WPFY_E:	Rts
*---------------
Upd_Weap_FlipYD:Bsr.w	Get_Shot_Adr
		Beq.b	UWFY_E
		Cmp	#1,(a1)	;Type=Piece?
		Bne.b	UWFY_E
		Lea	GWeap_PiecFlipY(pc),a0
		Bclr	#0,4(a0)
		Btst	#5,22(a1)
		Beq.b	UWFY_E
		Bset	#0,4(a0)
	UWFY_E:	Rts
*---------------
Upd_Weap_FlipYG:Lea	WeapLay(pc),a5
		Lea	GWeap_PiecFlipY(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Upd_Weap_AButD:	Bsr.w	Get_Shot_Adr
		Beq.b	UWAB_E

		Lea	GWeap_AnimDir(pc),a0
		Lea	ADI_Lst,a2	;###
		Move.b	23(a1),d0
		Ext.w	d0
		Add	d0,d0
		Move	0(a2,d0.w),d1
		Move	d1,10+8(a0)

		Lea	GWeap_AnimCon(pc),a0
		Lea	ACO_Lst,a2	;###
		Move.b	22(a1),d0
		Ext.w	d0
		Add	d0,d0
		Move	0(a2,d0.w),d1
		Move	d1,10+8(a0)
	UWAB_E:	Rts
*---------------
Weap_AnimCon:	Bsr.w	Get_Shot_Adr
		Beq.b	WAC_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	22(a1),a2
		Lea	GWeap_AnimCon(pc),a0
		Lea	ACO_Lst,a1	;###
		Jsr	Gd_Choice	;###
	WAC_End:Rts
*---------------
Weap_AnimDir:	Bsr.w	Get_Shot_Adr
		Beq.b	WAD_End
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	23(a1),a2
		Lea	GWeap_AnimDir(pc),a0
		Lea	ADI_Lst,a1	;###
		Jsr	Gd_Choice	;###
	WAD_End:Rts
*---------------
Weap_EOffsetX:	Move	#42,d5
		Bra.b	WEOX_Cm
Weap_EOffsetY:	Move	#44,d5
	WEOX_Cm:Bsr.w	Get_Shot_Adr
		Beq.b	WEOX_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,0(a1,d5.w)
		Bsr.b	Upd_Weap_EOffsD
		Bsr.b	Upd_Weap_EOffsG
	WEOX_Ed:Rts
*---------------
Upd_Weap_EOffsD:Bsr.w	Get_Shot_Adr
		Beq.b	UWEO_Ed
	*-- Convert numbers
		Move	42(a1),d0
		Lea	Weap_EOffsetXNT+3(pc),a0
		Move	#$8102,d7
		Bsr.w	Conv
		Move	44(a1),d0
		Lea	Weap_EOffsetYNT+3(pc),a0
		Move	#$8102,d7
		Bsr.w	Conv
	UWEO_Ed:Rts
*---------------
Upd_Weap_EOffsG:Lea	WeapLay(pc),a5
		Lea	GWeap_EOffsetX(pc),a4
		Moveq.l	#3,d7
		Bsr.w	Draw_Some
		
		Lea	GWeap_EOffsetY(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_EUnitType:	Clr	d7
		Lea	GWeap_EPiec(pc),a0
		Btst	#0,4(a0)
		Beq.b	WEUT_NP
		Moveq.l	#1,d7
	WEUT_NP:
		Lea	GWeap_EAnim(pc),a0
		Btst	#0,4(a0)
		Beq.b	WEUT_NA
		Moveq.l	#2,d7
	WEUT_NA:
		Lea	GWeap_EObjc(pc),a0
		Btst	#0,4(a0)
		Beq.b	WEUT_NO
		Moveq.l	#4,d7
	WEUT_NO:
		Bsr.w	Get_Shot_Adr
		Beq.b	WEUT_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	d7,30(a1)
		Bsr.w	Weap_EUseUnit
		Bsr.b	Upd_WEUnitTypeD
		Bsr.b	Upd_WEUnitTypeG
	WEUT_Ed:Rts
*---------------
Upd_WEUnitTypeD:Bsr.w	Get_Shot_Adr
		Beq.b	UEUT_Ed
	*-- Decide on type
		Lea	GWeap_EPiec(pc),a2
		Lea	GWeap_EAnim(pc),a3
		Lea	GWeap_EObjc(pc),a4
		Move	30(a1),d7

		Lea	Weap_ENoneDL(pc),a1

		Bclr	#0,4(a2)
		Btst	#0,d7
		Beq.b	UEUT_NP
		Bset	#0,4(a2)
		Lea	Weap_EPiecDL(pc),a1
	UEUT_NP:
		Bclr	#0,4(a3)
		Btst	#1,d7
		Beq.b	UEUT_NA
		Bset	#0,4(a3)
		Lea	Weap_EAnimDL(pc),a1
	UEUT_NA:
		Bclr	#0,4(a4)
		Btst	#2,d7
		Beq.b	UEUT_NO
		Bset	#0,4(a4)
		Lea	Weap_EObjcDL(pc),a1
	UEUT_NO:
		Lea	GWeap_ETypeJump(pc),a0
		Move.l	a1,2(a0)
	UEUT_Ed:Rts
*---------------
Upd_WEUnitTypeG:Lea	WeapLay(pc),a5
		Lea	GWeap_EPiec(pc),a4
		Moveq.l	#9,d7
		Bsr.w	Draw_Some

		Lea	GWeap_ETypeJump(pc),a4
		Bra.w	Draw_All
*---------------
Weap_ERemUnit:	Bsr.w	Get_Shot_Adr
		Beq.b	WERU_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,32(a1)
		Bsr.w	Upd_EUNameD
		Bsr.w	Upd_EUNameG
		Bsr.w	Upd_Weap_ETypeG
	WERU_Ed:Rts
*---------------
Weap_EUseUnit:	Bsr.w	Get_Shot_Adr
		Beq.w	WEUU_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Decide on type
		Move	30(a1),d7
		Btst	#0,d7
		Bne.b	WEUU_Pi
		Btst	#1,d7
		Bne.b	WEUU_An
		Btst	#2,d7
		Bne.b	WEUU_Ob
		Bra.b	WEUU_Ed
	*-- Check that Piece exists
	WEUU_Pi:Move	PiecList_Len(pc),d0
		Beq.b	WEUU_Ed
		Jsr	Get_Piec_LAdr	;###
		Tst.l	(a2)
		Beq.b	WEUU_Ed
		Move.l	(a2),a2
		Move.b	18(a2),36(a1)
		Move	Cur_Piec(pc),32(a1)
		Bra.b	WEUU_Fn
	*-- Check that Anim exists
	WEUU_An:Move	AnimList_Len(pc),d0
		Beq.b	WEUU_Ed
		Jsr	Get_Anim_LAdr	;###
		Tst.l	(a2)
		Beq.b	WEUU_Ed
		Move	Cur_Anim(pc),32(a1)
		Move.l	(a2),a2		;Copy Anim Delay
		Clr	d0		;+
		Move.b	7(a2),d0	;+
		Move	d0,34(a1)	;+
		Move.b	8(a2),36(a1)	;Copy Anim Control
		Move.b	9(a2),37(a1)	;Copy Anim Direction
		Bra.b	WEUU_Fn
	*-- Check that Object exists
	WEUU_Ob:Move	ObjcList_Len(pc),d0
		Beq.b	WEUU_Ed
		Jsr	Get_Objc_LAdr	;###
		Tst.l	(a2)
		Beq.b	WEUU_Ed
		Move	Cur_Objc(pc),32(a1)

	WEUU_Fn:Bsr.w	Upd_EUNameD
		Bsr.w	Upd_EUNameG
		Bsr.w	Upd_Weap_ETypeG
	WEUU_Ed:Rts
*---------------
Weap_EUnitName:	Bsr.w	Get_Shot_Adr
		Beq.w	WEUN_Ed
		Move	30(a1),d7
		Btst	#0,d7
		Bne.b	WEUN_Pi
		Btst	#1,d7
		Bne.b	WEUN_An
		Btst	#2,d7
		Bne.b	WEUN_Ob
		Bra.b	WEUN_Ed

	WEUN_Pi:Move	32(a1),d0
		Bmi.b	WEUN_NP
		Move	d0,Cur_Piec
	WEUN_NP:Lea	PiecLay,a5	;###
		Tst.l	(a5)
		Beq.b	WEUN_PO
		Jsr	Change_Piec	;###
		Lea	PiecLay,a5	;###
	WEUN_PO:Jmp	Open_Layer

	WEUN_An:Move	32(a1),d0
		Bmi.b	WEUN_NA
		Move	d0,Cur_Anim
	WEUN_NA:Lea	AnimLay,a5	;###
		Tst.l	(a5)
		Beq.b	WEUN_AO
		Jsr	Change_Anim	;###
		Lea	AnimLay,a5	;###
	WEUN_AO:Jmp	Open_Layer
		
	WEUN_Ob:Move	32(a1),d0
		Bmi.b	WEUN_NO
		Move	d0,Cur_Objc
	WEUN_NO:Lea	ObjcLay,a5	;###
		Tst.l	(a5)
		Beq.b	WEUN_OO
		Jsr	Change_Objc	;###
		Lea	ObjcLay,a5	;###
	WEUN_OO:Jmp	Open_Layer
	WEUN_Ed:Rts
*---------------
Upd_EUNameD:	Bsr.w	Get_Shot_Adr
		Beq.b	UEUN_Ed
		Move	30(a1),d7
		Btst	#0,d7
		Bne.b	UEUN_Pi
		Btst	#1,d7
		Bne.b	UEUN_An
		Btst	#2,d7
		Bne.b	UEUN_Ob
	*-- Copy name
	UEUN_Pi:Move.l	Mem_PiecList,a2		;###
		Bra.b	UEUN_Ok
	UEUN_An:Move.l	Mem_AnimList,a2		;###
		Bra.b	UEUN_Ok
	UEUN_Ob:Move.l	Mem_ObjcList,a2		;###
	UEUN_Ok:Lea	GWeap_EUName(pc),a3
		Clr.l	20(a3)
		Move	32(a1),d0
		Bmi.b	UEUN_Ed
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	UEUN_Ed:Rts
*---------------
Upd_EUNameG:	Lea	WeapLay,a5	;###
		Lea	GWeap_EUName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Upd_Weap_ETypeG:Lea	WeapLay(pc),a5
		Lea	GWeap_ETypeJump(pc),a4
		Bra.w	Draw_All
*---------------
Weap_EPFlipY:	Bsr.w	Get_Shot_Adr
		Beq.b	WEPFY_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Bchg	#5,36(a1)
		Bsr.b	Upd_Weap_EFlipYD
		Bsr.b	Upd_Weap_EFlipYG
	WEPFY_E:Rts
*---------------
Upd_Weap_EFlipYD:Bsr.w	Get_Shot_Adr
		Beq.b	UWEFY_E
		Cmp	#1,30(a1)	;Type=Piece?
		Bne.b	UWEFY_E
		Lea	GWeap_EPFlipY(pc),a0
		Bclr	#0,4(a0)
		Btst	#5,36(a1)
		Beq.b	UWEFY_E
		Bset	#0,4(a0)
	UWEFY_E:Rts
*---------------
Upd_Weap_EFlipYG:Lea	WeapLay(pc),a5
		Lea	GWeap_EPFlipY(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Upd_Weap_EAButD:Bsr.w	Get_Shot_Adr
		Beq.b	UWEAB_E

		Lea	GWeap_EAnimDir(pc),a0
		Lea	ADI_Lst,a2	;###
		Move.b	37(a1),d0
		Ext.w	d0
		Add	d0,d0
		Move	0(a2,d0.w),d1
		Move	d1,10+8(a0)

		Lea	GWeap_EAnimCon(pc),a0
		Lea	ACO_Lst,a2	;###
		Move.b	36(a1),d0
		Ext.w	d0
		Add	d0,d0
		Move	0(a2,d0.w),d1
		Move	d1,10+8(a0)
	UWEAB_E:Rts
*---------------
Weap_EAnimCon:	Bsr.b	Get_Shot_Adr
		Beq.b	WEAC_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	36(a1),a2
		Lea	GWeap_EAnimCon(pc),a0
		Lea	ACO_Lst,a1	;###
		Jsr	Gd_Choice	;###
	WEAC_Ed:Rts
*---------------
Weap_EAnimDir:	Bsr.b	Get_Shot_Adr
		Beq.b	WEAD_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	37(a1),a2
		Lea	GWeap_EAnimDir(pc),a0
		Lea	ADI_Lst,a1	;###
		Jsr	Gd_Choice	;###
	WEAD_Ed:Rts
*---------------
Weap_EAnimDel:	Bsr.b	Get_Shot_Adr
		Beq.b	WEAD_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,34(a1)
		Bsr.b	Upd_Weap_EADelD
		Bsr.b	Upd_Weap_EADelG
	WEAD_E:	Rts
*---------------
Get_Shot_Adr:	Move	WeapList_Len(pc),d0
		Beq.b	GSA_End
		Bsr.w	Get_Weap_LAdr
		Tst.l	(a2)
		Beq.b	GSA_End
		Move.l	(a2),a1
	*-- Find current Powerup & Shot (A1->Address)
		Move	Cur_Powerup(pc),d0
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1
		Move	Cur_Shot(pc),d0
		Lsl	#6,d0
		Add	d0,a1
		Moveq.l	#1,d0
		Rts
	GSA_End:Clr.l	d0
		Rts
*---------------
Upd_Weap_EADelD:Bsr.b	Get_Shot_Adr
		Beq.b	UWEAD_E
		Cmp	#2,30(a1)	;Type=Anim?
		Bne.b	UWEAD_E
		Move	34(a1),d0
		Lea	Weap_EAnimDelNT+2(pc),a0
		Move	#$0101,d7
		Bsr.w	Conv
	UWEAD_E:Rts
*---------------
Upd_Weap_EADelG:Lea	WeapLay,a5	;###
		Lea	GWeap_EAnimDel(pc),a4
		Moveq.l	#3,d7
		Bra.w	Draw_Some
*---------------
Weap_ERemSound:	Bsr.b	Get_Shot_Adr
		Beq.b	WERS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,46(a1)
		Bsr.b	Upd_ESNameD
		Bsr.w	Upd_ESNameG
	WERS_Ed:Rts
*---------------
Weap_EUseSound:	Bsr.b	Get_Shot_Adr
		Beq.b	WEUS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Check that Sound exists
		Move	SondList_Len(pc),d0
		Beq.b	WEUS_Ed
		Jsr	Get_Sond_LAdr	;###
		Tst.l	(a2)
		Beq.b	WEUS_Ed
		Move.l	(a2),a2
		Move	Cur_Sond(pc),46(a1)
		Bsr.b	Upd_ESNameD
		Bsr.b	Upd_ESNameG
	WEUS_Ed:Rts
*---------------
Weap_ESoundName:Bsr.w	Get_Shot_Adr
		Beq.b	WESN_Ed
		Move	46(a1),d0
		Bmi.b	WESN_NS
		Move	d0,Cur_Sond
	WESN_NS:Lea	SondLay,a5	;###
		Tst.l	(a5)
		Beq.b	WESN_SO
		Jsr	Change_Sond	;###
		Lea	SondLay,a5	;###
	WESN_SO:Jmp	Open_Layer
	WESN_Ed:Rts
*---------------
Upd_ESNameD:	Bsr.w	Get_Shot_Adr
		Beq.b	UESN_Ed
	*-- Copy name
		Move.l	Mem_SondList,a2		;###
		Lea	GWeap_ESName(pc),a3
		Clr.l	20(a3)
		Move	46(a1),d0
		Bmi.b	UESN_Ed
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	UESN_Ed:Rts
*---------------
Upd_ESNameG:	Lea	WeapLay,a5	;###
		Lea	GWeap_ESName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
DrawList_Weap:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Weapon8T

		Dc	'BX',000,011,-01,027

		Dc	'GD'
		Dc.l	$020100e1,Weap_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Weap_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Weap_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

GWeap_UpdAll:	Dc	'BX',046,013,-04,025
		Dc	'RO'
		Dc.l	Upd_WeapNameD

Weap_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Weap_Name
		Dc	'RC',049,015,-26,023
		Dc	'TX',051,022,-77,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$0201005d,Weap_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Weap_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

		Dc	'RO'
		Dc.l	Check_Weap
		Dc	'JP'
Weap_Jump:	Dc.l	Weap_No

Weap_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Weap_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Weap_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Weap_Yes:	Dc	'BX',000,028,-14,040
		Dc	'RO'
		Dc.l	Upd_WeapNumbD

		Dc	'TX',003,039,-01,8
		Dc.l	PowerUp8T
		Dc	'GD'
		Dc.l	$02030a9d,2,0
		Dc	'RC',-97,030,-83,038
Weap_PowerupUpd:Dc	'TX',-94,037,-01,5
		Dc.l	Weap_PowerupNT
		Dc	'GD'
		Dc.l	$02010095,0,Weap_PrvPowerup
		Dc	'BX',-81,030,-73,038
		Dc	'IM',-79,034,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010096,0,Weap_NxtPowerup
		Dc	'BX',-72,030,-64,038
		Dc	'IM',-70,032,5,Im_Plus-Im

		Dc	'TX',-61,037,-01,5
		Dc.l	OfT
		Dc	'GD'
		Dc.l	$02030a9e,2,0
		Dc	'RC',-50,030,-36,038
Weap_TotalUpd:	Dc	'TX',-47,037,-01,5
		Dc.l	Weap_TotalNT
		Dc	'GD'
		Dc.l	$02010097,0,Weap_DelPowerup
		Dc	'BX',-34,030,-26,038
		Dc	'IM',-32,034,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010098,0,Weap_AddPowerup
		Dc	'BX',-25,030,-17,038
		Dc	'IM',-23,032,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$0201000e,0,Weap_PlayScreen
		Dc	'BX',-13,028,-01,040
		Dc	'IM',-11,030,9,Im_PlayScr-Im

		Dc	'BX',000,041,-01,087

		Dc	'TX',003,050,-01,5
		Dc.l	FireDelayT
GWeap_FDelay:	Dc	'GD'
		Dc.l	$02030a00,5,Weap_FireDelay
		Dc	'RC',-52,043,-23,051
		Dc	'TX',-49,050,-01,5
		Dc.l	Weap_FDelayNT
		Dc	'GD'
		Dc.l	$02010052,Weap_FDel_P,PlusMinus
		Dc	'BX',-21,043,-13,051
		Dc	'IM',-19,047,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_FDel_P,PlusMinus
		Dc	'BX',-12,043,-04,051
		Dc	'IM',-10,045,5,Im_Plus-Im

		Dc	'TX',003,060,-01,5
		Dc.l	MaxOutT
GWeap_MaxOut:	Dc	'GD'
		Dc.l	$02030a00,5,Weap_MaxOut
		Dc	'RC',-52,053,-23,061
		Dc	'TX',-49,060,-01,5
		Dc.l	Weap_MaxOutNT
		Dc	'GD'
		Dc.l	$02010052,Weap_MaxOut_P,PlusMinus
		Dc	'BX',-21,053,-13,061
		Dc	'IM',-19,057,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_MaxOut_P,PlusMinus
		Dc	'BX',-12,053,-04,061
		Dc	'IM',-10,055,5,Im_Plus-Im

		Dc	'TX',003,070,-01,5
		Dc.l	AmmoDrainT
GWeap_AmmoDrain:Dc	'GD'
		Dc.l	$02030a00,5,Weap_AmmoDrain
		Dc	'RC',-52,063,-23,071
		Dc	'TX',-49,070,-01,5
		Dc.l	Weap_ADrainNT
		Dc	'GD'
		Dc.l	$02010052,Weap_ADrain_P,PlusMinus
		Dc	'BX',-21,063,-13,071
		Dc	'IM',-19,067,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_ADrain_P,PlusMinus
		Dc	'BX',-12,063,-04,071
		Dc	'IM',-10,065,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$0201008c,0,Weap_Sound
		Dc	'BX',003,073,015,085
		Dc	'IM',005,075,9,Im_Sound-Im
		Dc	'GD'
		Dc.l	$0201008d,0,Weap_UseSound
		Dc	'BX',016,073,028,085
		Dc	'IM',018,077,5,Im_Store-Im
		Dc	'GD'
		Dc.l	$0201008e,0,Weap_SoundName
GWeap_WSName:	Dc	'BX',029,073,-17,085
		Dc	'TX',032,082,-49,5
		Dc.l	0
		Dc	'GD'
		Dc.l	$02010094,0,Weap_RemoveSound
		Dc	'BX',-16,073,-04,085
		Dc	'IM',-14,075,9,Im_ClrClips-Im

GWeap_ShotAll:	Dc	'BX',000,088,-01,100

		Dc	'TX',003,099,-01,8
		Dc.l	Shot8T
		Dc	'GD'
		Dc.l	$02030a9f,2,0
		Dc	'RC',-84,090,-70,098
Weap_ShotUpd:	Dc	'TX',-81,097,-01,5
		Dc.l	Weap_ShotNT
		Dc	'GD'
		Dc.l	$02010099,0,Weap_PrvShot
		Dc	'BX',-68,090,-60,098
		Dc	'IM',-66,094,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$0201009a,0,Weap_NxtShot
		Dc	'BX',-59,090,-51,098
		Dc	'IM',-57,092,5,Im_Plus-Im

		Dc	'TX',-48,097,-01,5
		Dc.l	OfT
		Dc	'GD'
		Dc.l	$02030aa0,2,0
		Dc	'RC',-37,090,-23,098
Weap_ShotsUpd:	Dc	'TX',-34,097,-01,5
		Dc.l	Weap_ShotsNT
		Dc	'GD'
		Dc.l	$0201009b,0,Weap_DelShot
		Dc	'BX',-21,090,-13,098
		Dc	'IM',-19,094,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$0201009c,0,Weap_AddShot
		Dc	'BX',-12,090,-04,098
		Dc	'IM',-10,092,5,Im_Plus-Im

		Dc	'BX',000,101,-01,-01

		Dc	'TX',003,110,-01,5
		Dc.l	PowerT
GWeap_Power:	Dc	'GD'
		Dc.l	$02030a00,5,Weap_Power
		Dc	'RC',-148,103,-119,111
		Dc	'TX',-145,110,-01,5
		Dc.l	Weap_PowerNT
		Dc	'GD'
		Dc.l	$02010052,Weap_Power_P,PlusMinus
		Dc	'BX',-117,103,-109,111
		Dc	'IM',-115,107,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_Power_P,PlusMinus
		Dc	'BX',-108,103,-100,111
		Dc	'IM',-106,105,5,Im_Plus-Im

		Dc	'TX',-95,110,-01,5
		Dc.l	HitPowerT
GWeap_HitPower:	Dc	'GD'
		Dc.l	$02030a00,5,Weap_HitPower
		Dc	'RC',-52,103,-23,111
		Dc	'TX',-49,110,-01,5
		Dc.l	Weap_HitPowerNT
		Dc	'GD'
		Dc.l	$02010052,Weap_Power_P,PlusMinus
		Dc	'BX',-21,103,-13,111
		Dc	'IM',-19,107,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_Power_P,PlusMinus
		Dc	'BX',-12,103,-04,111
		Dc	'IM',-10,105,5,Im_Plus-Im

GWeap_Piec:	Dc	'GD'
		Dc.l	$0201068f,Weap_Type_Excl,Weap_UnitType
		Dc	'BX',003,113,015,125
		Dc	'IM',005,115,9,Im_Piece-Im
GWeap_Anim:	Dc	'GD'
		Dc.l	$02010690,Weap_Type_Excl,Weap_UnitType
		Dc	'BX',016,113,028,125
		Dc	'IM',018,115,9,Im_Anim-Im
GWeap_Objc:	Dc	'GD'
		Dc.l	$02010691,Weap_Type_Excl,Weap_UnitType
		Dc	'BX',029,113,041,125
		Dc	'IM',031,115,9,Im_Mask-Im

		Dc	'GD'
		Dc.l	$02010092,0,Weap_UseUnit
		Dc	'BX',042,113,054,125
		Dc	'IM',044,117,5,Im_Store-Im
		Dc	'GD'
		Dc.l	$02010093,0,Weap_UnitName
GWeap_UName:	Dc	'BX',055,113,-04,125
		Dc	'TX',058,122,-01,5
		Dc.l	0

GWeap_TypeJump:	Dc	'JS'
		Dc.l	Weap_PiecDL

		Dc	'TX',003,148,-01,5
		Dc.l	OffsetT

		Dc	'TX',-100,148,-01,5
		Dc.l	XT
GWeap_OffsetX:	Dc	'GD'
		Dc.l	$02030a00,3,Weap_OffsetX
		Dc	'RC',-92,141,-73,149
		Dc	'TX',-89,148,-01,5
		Dc.l	Weap_OffsetXNT
		Dc	'GD'
		Dc.l	$02010052,Weap_Offset_P,PlusMinus
		Dc	'BX',-71,141,-63,149
		Dc	'IM',-69,145,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_Offset_P,PlusMinus
		Dc	'BX',-62,141,-54,149
		Dc	'IM',-60,143,5,Im_Plus-Im

		Dc	'TX',-50,148,-01,5
		Dc.l	YT
GWeap_OffsetY:	Dc	'GD'
		Dc.l	$02030a00,3,Weap_OffsetY
		Dc	'RC',-42,141,-23,149
		Dc	'TX',-39,148,-01,5
		Dc.l	Weap_OffsetYNT
		Dc	'GD'
		Dc.l	$02010052,Weap_Offset_P,PlusMinus
		Dc	'BX',-21,141,-13,149
		Dc	'IM',-19,145,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_Offset_P,PlusMinus
		Dc	'BX',-12,141,-04,149
		Dc	'IM',-10,143,5,Im_Plus-Im

		Dc	'TX',003,158,-01,5
		Dc.l	SpeedT
GWeap_SpeedInt:	Dc	'GD'
		Dc.l	$02030a00,3,Weap_SpeedInt
		Dc	'RC',-42,151,-23,159
		Dc	'TX',-39,158,-01,5
		Dc.l	Weap_SpeedIntNT
		Dc	'GD'
		Dc.l	$02010052,Weap_SpeedInt_P,PlusMinus
		Dc	'BX',-21,151,-13,159
		Dc	'IM',-19,155,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_SpeedInt_P,PlusMinus
		Dc	'BX',-12,151,-04,159
		Dc	'IM',-10,153,5,Im_Plus-Im

		Dc	'TX',003,168,-01,5
		Dc.l	AngleT
GWeap_AngleInt:	Dc	'GD'
		Dc.l	$02030a00,3,Weap_AngleInt
		Dc	'RC',-42,161,-23,169
		Dc	'TX',-39,168,-01,5
		Dc.l	Weap_AngleIntNT
		Dc	'GD'
		Dc.l	$02010052,Weap_AngleInt_P,PlusMinus
		Dc	'BX',-21,161,-13,169
		Dc	'IM',-19,165,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_AngleInt_P,PlusMinus
		Dc	'BX',-12,161,-04,169
		Dc	'IM',-10,163,5,Im_Plus-Im

		Dc	'TX',003,178,-01,5
		Dc.l	DurationT
GWeap_Duration:	Dc	'GD'
		Dc.l	$02030a00,5,Weap_Duration
		Dc	'RC',-52,171,-23,179
		Dc	'TX',-49,178,-01,5
		Dc.l	Weap_DurationNT
		Dc	'GD'
		Dc.l	$02010052,Weap_Dur_P,PlusMinus
		Dc	'BX',-21,171,-13,179
		Dc	'IM',-19,175,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_Dur_P,PlusMinus
		Dc	'BX',-12,171,-04,179
		Dc	'IM',-10,173,5,Im_Plus-Im

GWeap_EPiec:	Dc	'GD'
		Dc.l	$0201068f,Weap_EType_Excl,Weap_EUnitType
		Dc	'BX',003,181,015,193
		Dc	'IM',005,183,9,Im_Piece-Im
GWeap_EAnim:	Dc	'GD'
		Dc.l	$02010690,Weap_EType_Excl,Weap_EUnitType
		Dc	'BX',016,181,028,193
		Dc	'IM',018,183,9,Im_Anim-Im
GWeap_EObjc:	Dc	'GD'
		Dc.l	$02010691,Weap_EType_Excl,Weap_EUnitType
		Dc	'BX',029,181,041,193
		Dc	'IM',031,183,9,Im_Mask-Im

		Dc	'GD'
		Dc.l	$02010092,0,Weap_EUseUnit
		Dc	'BX',042,181,054,193
		Dc	'IM',044,185,5,Im_Store-Im
		Dc	'GD'
		Dc.l	$02010093,0,Weap_EUnitName
GWeap_EUName:	Dc	'BX',055,181,-17,193
		Dc	'TX',058,190,-01,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$020100B2,0,Weap_ERemUnit
		Dc	'BX',-16,181,-04,193
		Dc	'IM',-14,183,9,Im_ClrClips-Im

GWeap_ETypeJump:Dc	'JS'
		Dc.l	Weap_EPiecDL

		Dc	'TX',003,216,-01,5
		Dc.l	OffsetT

		Dc	'TX',-100,216,-01,5
		Dc.l	XT
GWeap_EOffsetX:	Dc	'GD'
		Dc.l	$02030a00,3,Weap_EOffsetX
		Dc	'RC',-92,209,-73,217
		Dc	'TX',-89,216,-01,5
		Dc.l	Weap_EOffsetXNT
		Dc	'GD'
		Dc.l	$02010052,Weap_Offset_P,PlusMinus
		Dc	'BX',-71,209,-63,217
		Dc	'IM',-69,213,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_Offset_P,PlusMinus
		Dc	'BX',-62,209,-54,217
		Dc	'IM',-60,211,5,Im_Plus-Im

		Dc	'TX',-50,216,-01,5
		Dc.l	YT
GWeap_EOffsetY:	Dc	'GD'
		Dc.l	$02030a00,3,Weap_EOffsetY
		Dc	'RC',-42,209,-23,217
		Dc	'TX',-39,216,-01,5
		Dc.l	Weap_EOffsetYNT
		Dc	'GD'
		Dc.l	$02010052,Weap_Offset_P,PlusMinus
		Dc	'BX',-21,209,-13,217
		Dc	'IM',-19,213,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_Offset_P,PlusMinus
		Dc	'BX',-12,209,-04,217
		Dc	'IM',-10,211,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$0201008c,0,Weap_Sound
		Dc	'BX',003,219,015,231
		Dc	'IM',005,221,9,Im_Sound-Im
		Dc	'GD'
		Dc.l	$0201008d,0,Weap_EUseSound
		Dc	'BX',016,219,028,231
		Dc	'IM',018,223,5,Im_Store-Im
		Dc	'GD'
		Dc.l	$0201008e,0,Weap_ESoundName
GWeap_ESName:	Dc	'BX',029,219,-17,231
		Dc	'TX',032,228,-49,5
		Dc.l	0
		Dc	'GD'
		Dc.l	$02010094,0,Weap_ERemSound
		Dc	'BX',-16,219,-04,231
		Dc	'IM',-14,221,9,Im_ClrClips-Im

		Dc	'XX'

Weap_NoneDL:	Dc	'BX',003,127,-04,139
		Dc	'RT'

Weap_PiecDL:	Dc	'BX',016,127,-04,139

		Dc	'RO'
		Dc.l	Upd_Weap_FlipYD
		
GWeap_PiecFlipY:Dc	'GD'
		Dc.l	$0201021f,0,Weap_PiecFlipY
		Dc	'BX',003,127,015,139
		Dc	'IM',005,129,9,Im_FlipY-Im

		Dc	'RT'

Weap_AnimDL:	Dc	'RO'
		Dc.l	Upd_Weap_AButD

		Dc	'GD'
		Dc.l	$0201000c,0,Weap_AnimCon
GWeap_AnimCon:	Dc	'BX',003,127,015,139
		Dc	'IM',005,129,9,Im_Loop-Im

		Dc	'GD'
		Dc.l	$02010008,0,Weap_AnimDir
GWeap_AnimDir:	Dc	'BX',016,127,028,139
		Dc	'IM',018,131,5,Im_Forward-Im

		Dc	'BX',029,127,-04,139

		Dc	'RO'
		Dc.l	Upd_Weap_ADelD

		Dc	'TX',032,136,-01,5
		Dc.l	DelayT
GWeap_AnimDel:	Dc	'GD'
		Dc.l	$02030ab0,2,Weap_AnimDel
		Dc	'RC',-40,129,-26,137
		Dc	'TX',-37,136,-01,5
		Dc.l	Weap_AnimDelNT
		Dc	'GD'
		Dc.l	$02010052,Weap_AnimDel_P,PlusMinus
		Dc	'BX',-24,129,-16,137
		Dc	'IM',-22,133,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_AnimDel_P,PlusMinus
		Dc	'BX',-15,129,-07,137
		Dc	'IM',-13,131,5,Im_Plus-Im

		Dc	'RT'

Weap_AnimDelNT:	Dc.b	' 0',0
		Even

Weap_ObjcDL:	Dc	'BX',003,127,-04,139
		Dc	'RT'

Weap_ENoneDL:	Dc	'BX',003,195,-04,207
		Dc	'RT'

Weap_EPiecDL:	Dc	'BX',016,195,-04,207

		Dc	'RO'
		Dc.l	Upd_Weap_EFlipYD
		
GWeap_EPFlipY:	Dc	'GD'
		Dc.l	$0201021f,0,Weap_EPFlipY
		Dc	'BX',003,195,015,207
		Dc	'IM',005,197,9,Im_FlipY-Im

		Dc	'RT'

Weap_EAnimDL:	Dc	'RO'
		Dc.l	Upd_Weap_EAButD

		Dc	'GD'
		Dc.l	$0201000c,0,Weap_EAnimCon
GWeap_EAnimCon:	Dc	'BX',003,195,015,207
		Dc	'IM',005,197,9,Im_Loop-Im

		Dc	'GD'
		Dc.l	$02010008,0,Weap_AnimDir
GWeap_EAnimDir:	Dc	'BX',016,195,028,207
		Dc	'IM',018,199,5,Im_Forward-Im

		Dc	'BX',029,195,-04,207

		Dc	'RO'
		Dc.l	Upd_Weap_EADelD

		Dc	'TX',032,204,-01,5
		Dc.l	DelayT
GWeap_EAnimDel:	Dc	'GD'
		Dc.l	$02030ab0,2,Weap_EAnimDel
		Dc	'RC',-40,197,-26,205
		Dc	'TX',-37,204,-01,5
		Dc.l	Weap_EAnimDelNT
		Dc	'GD'
		Dc.l	$02010052,Weap_AnimDel_P,PlusMinus
		Dc	'BX',-24,197,-16,205
		Dc	'IM',-22,201,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Weap_AnimDel_P,PlusMinus
		Dc	'BX',-15,197,-07,205
		Dc	'IM',-13,199,5,Im_Plus-Im

		Dc	'RT'

Weap_EAnimDelNT:Dc.b	' 0',0
		Even

Weap_EObjcDL:	Dc	'BX',003,195,-04,207
		Dc	'RT'

;		Dc	'TX',003,097,-01,5
;		Dc.l	EffectT
;		Dc	'GD'
;		Dc.l	$02010000,0,0
;		Dc	'BX',-134,090,-90,098
;		Dc	'TX',-131,097,-01,5
;		Dc.l	FlashT
;		Dc	'TX',-86,097,-01,5
;		Dc.l	ValT
;		Dc	'GD'
;		Dc.l	$02030a00,5,0
;		Dc	'RC',-66,090,-47,098
;		Dc	'TX',-63,097,-01,5
;		Dc.l	Weap_EffValNT
;		Dc	'TX',-43,097,-01,5
;		Dc.l	SpdT
;		Dc	'GD'
;		Dc.l	$02030200,5,0
;		Dc	'RC',-23,090,-04,098
;		Dc	'TX',-20,097,-01,5
;		Dc.l	Weap_EffSpdNT

Weap_SpeedInt_P:Dc	1,-999,999,$8103
Weap_AngleInt_P:Dc	1,-999,999,$8103	;0-359
Weap_FDel_P:	Dc	1,1,9999,$0104
Weap_Offset_P:	Dc	1,-999,999,$8103
Weap_ADrain_P:	Dc	1,-999,999,$8103
Weap_MaxOut_P:	Dc	1,0,999,$0103
Weap_Power_P:	Dc	1,-1,32766,$0103
Weap_Dur_P:	Dc	1,-1,32766,$0103
Weap_AnimDel_P:	Dc	1,1,99,$0102

Weap_Type_Excl:	Dc.l	GWeap_Piec
		Dc.l	GWeap_Anim
		Dc.l	GWeap_Objc
		Dc.l	0

Weap_EType_Excl:Dc.l	GWeap_EPiec
		Dc.l	GWeap_EAnim
		Dc.l	GWeap_EObjc
		Dc.l	0

Weap_PowerupNT:	Dc.b	' 0',0
Weap_TotalNT:	Dc.b	' 0',0
Weap_ShotNT:	Dc.b	' 0',0
Weap_ShotsNT:	Dc.b	' 0',0
Weap_FDelayNT:	Dc.b	'    0',0
Weap_MaxOutNT:	Dc.b	'    0',0
Weap_ADrainNT:	Dc.b	'    0',0
Weap_PowerNT:	Dc.b	'    0',0
Weap_HitPowerNT:Dc.b	'    0',0
Weap_DurationNT:Dc.b	'    0',0
Weap_EffSpdNT:	Dc.b	'  0',0
Weap_EffValNT:	Dc.b	'  0',0
Weap_SpeedIntNT:Dc.b	'  0',0
Weap_AngleIntNT:Dc.b	'  0',0
Weap_OffsetXNT:	Dc.b	'  0',0
Weap_OffsetYNT:	Dc.b	'  0',0
Weap_EOffsetXNT:Dc.b	'  0',0
Weap_EOffsetYNT:Dc.b	'  0',0
FlashT:		Dc.b	'FLASH',0
		Even
*=======================================================================*
*				 G A M E				*
*=======================================================================*
Save_Game:	Lea	Sprite_Disk,a1	;###
		Jsr	Change_Sprite	;###

		Lea	RequLay,a5		;Close Layer ###
		Jsr	Close_Layer		;+ ###
	*-- Write File
		Lea	Game_FileName(pc),a0
		Jsr	Open_New_File	;###
		Bne.b	SG_NEr
		Jmp	Mess_FileErr
	SG_NEr:
		Lea	Game_Header(pc),a0	;Address
		Moveq.l	#8,d0			;Size
		Jsr	Write_File	;###

		Lea	Unit_Info,a3	;###

	SG_UnLp:Move	(a3),d0
		Bmi.b	SG_Last
		Bsr.w	Save_UnitList
		
		Add	Item_Size(pc),a3
		Bra.b	SG_UnLp
		
	SG_Last:
	*-- Save Name
		Lea	Game_UnitHead(pc),a0	;Address
		Move.l	#'NAME',(a0)		;Id
		Move.l	#24,4(a0)		;Length
		Moveq.l	#8,d0			;Size
		Jsr	Write_File	;###

		Lea	GameNameT(pc),a0	;Address
		Moveq.l	#24,d0			;Size
		Jsr	Write_File	;###
	*-- Save PathList
		Lea	Game_UnitHead(pc),a0	;Address
		Move.l	#'PATH',(a0)		;Id
		Move	PathList_Len,d0		;Length	###
		Ext.l	d0			;+
		Move.l	d0,4(a0)		;+
		Moveq.l	#8,d0			;Size
		Jsr	Write_File	;###

		Move.l	Mem_PathList,a0	;###
		Move	PathList_Len,d0		;Length	###
		Ext.l	d0
		Lsl.l	#7,d0
		Jsr	Write_File	;###
	*-- Save PrefData
		Lea	Game_UnitHead(pc),a0	;Address
		Move.l	#'PREF',(a0)		;Id
		Move.l	#16,4(a0)		;+
		Moveq.l	#8,d0			;Size
		Jsr	Write_File	;###

		Lea	PrefData,a0	;###
		Moveq.l	#16,d0
		Jsr	Write_File	;###
	*-- Save EndOfFile
		Lea	Game_UnitHead(pc),a0	;Address
		Move.l	#'XXXX',(a0)		;Id
		Clr.l	4(a0)			;Length
		Moveq.l	#8,d0			;Size
		Jsr	Write_File	;###

		Jsr	Close_File	;###
		Clr	Game_NeedUpd
		Rts
*---------------
Save_UnitList:	;(A3=Xxxx_Info)
		Lea	Game_UnitHead(pc),a0	;Address
		Move.l	16(a3),(a0)		;Xxxx
		Move	6(a3),d0		;Length
		Ext.l	d0
		Move.l	d0,4(a0)		;+
		Moveq.l	#8,d0			;Size
		Jsr	Write_File	;###

		Move	6(a3),d4		;Length
		Move.l	2(a3),a5		;Piece List Address
		Move.l	(a5),a5
	SG_Unit:Tst	d4
		Beq.b	SG_UnEd
		Addq.l	#4,a5
		Move.l	a5,a0
		Moveq.l	#28,d0			;Size
		Jsr	Write_File	;###
		Add	#28,a5
		Subq	#1,d4
		Bra.b	SG_Unit
	SG_UnEd:Rts

Game_FileN:	Dc.b	'GAME.AFDF',0

Game_NeedUpd:	Dc	0
Game_Header:	Dc.b	'AFDFGAME'
Game_UnitHead:	Dc.l	0,0
Game_FileName:	Blk.b	74,0
*---------------
Selc_LoadGame:	Lea	PathName,a0	;###
		Lea	Game_FileName(pc),a1
	SLG_Lp:	Move.b	(a0)+,(a1)+
		Bne.b	SLG_Lp

		Subq	#1,a1
		Cmp.b	#':',-1(a1)
		Beq.b	SLG_Ok
		Cmp.b	#'/',-1(a1)
		Beq.b	SLG_Ok
		Move.b	#'/',(a1)+
	SLG_Ok:	Lea	Game_FileN(pc),a0
	SLG_L2:	Move.b	(a0)+,(a1)+
		Bne.b	SLG_L2

		Bra.b	Load_Game
*---------------
Selc_SaveGame:	Lea	GameT,a0	;###
		Move.l	a0,GRequ_Path
		Lea	GameNameT(pc),a0
		Move.l	a0,GRequ_Name
		Lea	Update8T,a0	;###
		Move.l	a0,GRequ_Title
		Lea	UpdateT,a0	;###
		Move.l	a0,GRequ_Confirm
		Lea	Save_Game(pc),a0
		Move.l	a0,GRequ_Routine

		Lea	RequLay,a5	;Open Layer	###
		Tst.l	(a5)
		Beq.b	SSG_NOp
		Lea	DrawList_Requ(pc),a4
		Jsr	Draw_All
	SSG_NOp:Jmp	Open_Layer	;###
*---------------
Selc_UpdtAllGame:
		Move	Game_NeedUpd(pc),d0
		Beq.b	SUAG_No
		Bsr.w	Save_Game
	SUAG_No:Bra.w	Game_UpdateAll
*---------------
Selc_LoadAllGame:
		Bra.w	Game_LoadAll
*---------------
Load_Game:	Lea	Sprite_Disk,a1	;###
		Jsr	Change_Sprite	;###
	*-- Read File
		Lea	Game_FileName(pc),a0
		Jsr	Open_Old_File	;###
		Bne.b	LG_NEr

		Jmp	Mess_FileErr

	LG_NEr:	Lea	Game_LoadBuf(pc),a0	;Address
		Moveq.l	#8,d0			;Size
		Jsr	Read_File		;###
		Move.l	Game_Header(pc),d0
		Cmp.l	Game_LoadBuf(pc),d0
		Bne.b	LG_End

		Jsr	Free_All_Lists		;###

		Clr	Game_NeedUpd

	LG_Next:Lea	Game_LoadBuf(pc),a0	;Address
		Moveq.l	#8,d0			;Size
		Jsr	Read_File		;###

		Lea	Game_LoadBuf(pc),a0	;Address

		Lea	Unit_Info,a3	;###
		Move.l	(a0),d0			;Get Xxxx
		Cmp.l	#'NAME',d0
		Beq.b	LG_Name
		Cmp.l	#'PATH',d0
		Beq.b	LG_Path
		Cmp.l	#'PREF',d0
		Beq.b	LG_Pref
		Cmp.l	#'XXXX',d0		;End of file?
		Beq.b	LG_End
	LG_Loop:Move	(a3),d1
		Bmi.b	LG_End
		Cmp.l	16(a3),d0		;This Unit?
		Bne.b	LG_Not
		Bsr.b	Load_UnitList
		Bra.b	LG_Next
	LG_Not:	Add	Item_Size,a3	;###
		Bra.b	LG_Loop

	LG_End:	Jsr	Close_File	;###

		Jsr	Change_Palt	;###
		Jmp	Update_Prefs	;###

	LG_Name:Move.l	4(a0),d0		;Size
		Lea	GameNameT(pc),a0	;Address
		Jsr	Read_File	;###
		Bra.b	LG_Next

	LG_Path:Move.l	4(a0),d6	;Length
		Move	d6,PathList_Len
		Lsl.l	#7,d6
		Lea	Mem_PathList,a5	;###
		Jsr	Free_Mem	;###
		Move.l	d6,d0
		Jsr	Alloc_Any_Mem	;###
		Move.l	d6,d0
		Move.l	(a5),a0
		Jsr	Read_File	;###
		Bra.w	LG_Next

	LG_Pref:Move.l	4(a0),d0	;Length
		Lea	PrefData,a0	;###
		Jsr	Read_File	;###
		Bra.w	LG_Next
*---------------
Load_UnitList:	Move.l	4(a0),d0	;Get Length
		Move	d0,6(a3)	;Store Length
		Beq.b	LG_UnEd		;Empty List?
		Lsl.l	#5,d0		;Multiply by 32
		Move.l	2(a3),a5	;Get Mem Label
		Jsr	Alloc_Any_Mem	;###
		Bne.b	LUL_NEr

		Jmp	Mess_MemErr

	LUL_NEr:Move	6(a3),d4	;Get Length
		Move.l	2(a3),a5	;Find Piece List Address
		Move.l	(a5),a5		;+

	LG_UnLp:Tst	d4
		Beq.b	LG_UnEd
		Clr.l	(a5)+		;Clear Address
		Move.l	a5,a0
		Moveq.l	#28,d0		;Size
		Jsr	Read_File	;###
		Add	#28,a5
		Subq	#1,d4
		Bra.b	LG_UnLp
	LG_UnEd:Rts

Game_LoadBuf:	Blk.b	8
*---------------
Game_UpdateAll:	Lea	Unit_Info,a3	;###
	GUA_UnL:Move	(a3),d0
		Bmi.b	GUA_End
		Bsr.b	Game_UpdateUnit
		Add	Item_Size,a3	;###
		Bra.b	GUA_UnL
	GUA_End:Rts
*---------------
Game_LoadAll:	Lea	Unit_Info,a3	;###
	GLA_UnL:Move	(a3),d0
		Bmi.b	GLA_End
		Bsr.b	Game_LoadAllUnit
		Add	Item_Size,a3	;###
		Bra.b	GLA_UnL
	GLA_End:Rts
*---------------
Game_UpdateUnit:;(A3=Unit_Info)
		Clr	Unit_Cnt
	GUU_Lp:	Move	6(a3),d1
		Cmp	Unit_Cnt(pc),d1
		Ble.b	GUU_End

		Move.l	2(a3),a4
		Move.l	(a4),a4
		Move	Unit_Cnt(pc),d4

		Move.l	a4,a2
		Clr.l	d1
		Move	d4,d1
		Lsl.l	#5,d1
		Add.l	d1,a2
		Tst.l	(a2)
		Beq.b	GUU_No
		Move	4(a2),d2
		Btst	#1,d2	;Needs Update?
		Beq.b	GUU_No

		Move.l	16(a3),d0
		Jsr	Save_Unit	;###
	GUU_No:	Addq	#1,Unit_Cnt
		Bra.b	GUU_Lp
	GUU_End:Rts
Unit_Cnt:	Dc	0
*---------------
Game_LoadAllUnit:;(A3=Unit_Info)
		Clr	Unit_Cnt
	GLU_Lp:	Move	6(a3),d1
		Cmp	Unit_Cnt(pc),d1
		Ble.b	GLU_End

		Move.l	2(a3),a4
		Move.l	(a4),a4
		Move	Unit_Cnt(pc),d4

		Move.l	a4,a2
		Clr.l	d1
		Move	d4,d1
		Lsl.l	#5,d1
		Add.l	d1,a2
		Tst.l	(a2)
		Bne.b	GLU_No
		Move	4(a2),d2
		Btst	#0,d2	;Is Occupied?
		Beq.b	GLU_No

		Move	d4,(a3)
		Move.l	16(a3),d0
		Jsr	Load_Unit	;###

		Move.l	8(a3),a0
		Move.l	a3,-(a7)
		Jsr	(a0)
		Move.l	(a7)+,a3
		
	GLU_No:	Addq	#1,Unit_Cnt
		Bra.b	GLU_Lp
	GLU_End:Rts
*---------------
Game_Log:	Lea	InvnLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Game_Snapshot:	Lea	SnapLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Game_PathList:	Lea	PathLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Game_Select:	Lea	GSelc_Title,a0	;###
		Lea	GameT,a1	;###
		Move.l	a1,(a0)
		Lea	Selc_GameDL,a0	;###
		Move.l	a0,GSelc_Jump
		Lea	SelcLay,a5	;###
		Tst.l	(a5)
		Beq.b	GS_NOp
		Lea	DrawList_Selc,a4	;###
		Jsr	Draw_All	;###
	GS_NOp:	Jmp	Open_Layer	;###
*---------------
DrawList_Game:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Game8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$02010000,0,Game_Select
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,0
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,0,Selc_SaveGame
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-47,025
		Dc	'GD'
		Dc.l	$0203026e,23,0
Game_NameUpd:	Dc	'RC',049,015,-50,023
		Dc	'TX',052,022,-99,5
		Dc.l	GameNameT
		
		Dc	'GD'
		Dc.l	$0201005f,0,Game_Snapshot
		Dc	'BX',-42,013,-30,025
		Dc	'IM',-40,015,9,Im_Snapshot-Im

		Dc	'GD'
		Dc.l	$02010060,0,Game_Log
		Dc	'BX',-29,013,-17,025
		Dc	'IM',-27,015,9,Im_Log-Im

		Dc	'GD'
		Dc.l	$02010061,0,Game_PathList
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_PathList-Im

		Dc	'BX',000,028,-01,044

		Dc	'GD'
		Dc.l	$0201000d,0,0	;Game_
		Dc	'BX',003,030,015,042
		Dc	'IM',005,033,7,Im_Play-Im

		Dc	'GD'
		Dc.l	$02010066,0,0	;Game_
		Dc	'BX',016,030,028,042
		Dc	'IM',018,032,9,Im_Replay-Im

		Dc	'GD'
		Dc.l	$02010000,0,0	;Game_
		Dc	'BX',029,030,041,042
		Dc	'IM',031,032,9,Im_Reset-Im

		Dc	'BX',046,030,-04,042
		Dc	'TX',049,039,-01,5
		Dc.l	DelayT

		Dc	'GD'
		Dc.l	$02030200,2,0
		Dc	'RC',-41,032,-27,040
		Dc	'TX',-38,039,-01,5
		Dc.l	Game_DelayNT

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-24,032,-16,040
		Dc	'IM',-22,036,1,Im_Minus-Im

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-15,032,-07,040
		Dc	'IM',-13,034,5,Im_Plus-Im

		Dc	'BX',000,045,-01,-01

		Dc	'XX'

GameNameT:	Dc.b	'UNNAMED',0
		Blk.b	24-8,0
;Game_ScreenT:	Dc.b	'SCREEN:',0
;Game_LevelT:	Dc.b	'LEVEL:',0
;Game_PositionT:	Dc.b	'POSITION:',0
;Game_XT:	Dc.b	'X=',0
;Game_YT:	Dc.b	'Y=',0
;Game_CurScrT:	Dc.b	'SCREENNAME',0
Game_CurLevT:	Dc.b	'  0',0
Game_CurXNT:	Dc.b	'    0',0
Game_CurYNT:	Dc.b	'    0',0
;Game_CollisionT:Dc.b	'COLLISION',0
;Game_EnemiesT:	Dc.b	'ENEMIES',0
;Game_SoundT:	Dc.b	'SOUND',0
;Game_InfoT:	Dc.b	'INFO',0
Game_DelayNT:	Dc.b	' 0',0
;ScoreT:		Dc.b	'SCORE:',0
;LivesT:		Dc.b	'LIVES:',0
;PowerT:		Dc.b	'POWER:',0
		Even
*=======================================================================*
*			       S C R E E N				*
*=======================================================================*
Scrn_New:	Lea	ScrnList,a4	;###
		Lea	New_Scrn(pc),a2
		Jsr	Unit_New	;###
		Move	d7,Cur_Scrn
		Bra.b	Change_Scrn
New_Scrn:	Dc	0	;Id		00
		Dc.l	50	;Size		02
		Dc	0	;Total		06
		Blk.b	20,0	;Unused		08
		Dc	0	;Splits		28
		Dc	0	;SplitOffs	30
		Dc	-1	;End
		Blk.b	16,0	;Split		00
*---------------
Change_Scrn:	Move	#-1,Cur_ScrnEvent
		Bsr.w	Upd_ScrnNameD
		Bsr.w	Upd_ScrnNameG
		Lea	Scrn_GfxUpd(pc),a4
		Lea	ScrnLay,a5	;###
		Jsr	Draw_All	;###
		Clr	Scrn_CurPos
		Bsr.w	Upd_ScrnPropD
		Bsr.w	Upd_ScrnEventsD
		Bsr.w	Upd_SEvnDL
		Bsr.w	Buffer_ScrnText
		Bsr.w	Upd_SEvnAllG
		Lea	Scrn_Info,a3	;###
		Jmp	Upd_SelcUnit	;###
*---------------
Scrn_Undo:	Lea	Scrn_Info,a3	;###
		Jsr	Unit_Undo	;###
		Bra.b	Change_Scrn
*---------------
Scrn_Name:	Move	#1,Game_NeedUpd
		Bsr.w	Upd_ScrnNameD
		Bsr.w	Upd_ScrnNameG
		Rts
*---------------
Scrn_AddEvent:	Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.w	SAE_End
		Move.l	a2,SAE_ListAdr
		Bsr.w	Update_ScrnBuf
		Move.l	Mem_ScrnBuf,a2		;Get buffer address ###
		Move	6(a2),SAE_Loc		;Total
	*-- Find Event Length
		Lea	Scrn_NewEvents(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2
		Move	4(a2),d0
		Addq	#2,d0			;Plus 2 for EventOffset
		Move	d0,SAE_BytesAdd
	*-- Free old Object
		Move.l	SAE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_ScrnBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Add	SAE_BytesAdd(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	SAE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	SAE_NEr
		Jmp	Mess_MemErr		;###
	SAE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_ScrnBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	SAE_BytesAdd(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Addq	#1,d7			;+
		Move	d7,(a1)+		;+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+

		Move.l	a1,a3			;First event address
		Move	d7,d6
		Add	d6,d6
		Add	d6,a3

		Move.l	a2,a4			;First event address
		Move	d7,d6
		Subq	#1,d6
		Add	d6,d6
		Add	d6,a4
	*-- Copy Events
		Clr	d0
		Move	d7,d6
		Add	d6,d6
		Add	#32,d6			;'Header' Size

	SAE_CEL:Cmp	SAE_Loc(pc),d0		;Insert Event here?
		Beq.b	SAE_AE
		Move	(a4)+,d1		;Copy EventSize
		Move	d1,(a3)+		;+
		Bmi.b	SAE_CEE			;If -1 then End
		Move	d6,(a1)+		;Write EventOffset
		Add	d1,d6			;Add EventSize
		Subq	#3,d1
	SAE_CEB:Move.b	(a4)+,(a3)+
		Dbf	d1,SAE_CEB
		Addq	#1,d0
		Bra.b	SAE_CEL

	SAE_CEE:
	SAE_End:Clr	Scrn_CurPos
		Bsr.w	Upd_ScrnPropD
		Bsr.w	Upd_ScrnEventsD
		Bsr.w	Upd_SEvnDL
		Bsr.w	Buffer_ScrnText
		Bsr.w	Upd_SEvnAllG
		Bra.w	Draw_Screen
			
	SAE_AE:	Move	d6,(a1)+

		Lea	Scrn_NewEvents(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2

		Add	4(a2),d6
		Clr	d2
		Move.l	a3,a0
	SAE_LpN:Move.b	4(a2,d2.w),(a3)+
		Addq	#1,d2
		Cmp	4(a2),d2
		Bne.b	SAE_LpN

		Move	SAE_Loc(pc),Cur_ScrnEvent
		Move.l	(a2),d2
		Beq.b	SAE_NRt
		Movem.l	d0-d7/a0-a6,-(a7)
		Move.l	d2,a2
		Jsr	(a2)		;Jsr to New-routine. A0=Event.
		Movem.l	(a7)+,d0-d7/a0-a6

	SAE_NRt:Addq	#1,d0
		Bra.b	SAE_CEL

SAE_Loc:	Dc	0
SAE_ListAdr:	Dc.l	0
SAE_BytesAdd:	Dc	0

Scrn_NewEvents:	Dc.l	Scrn_GameEv
		Dc.l	Scrn_TextEv
		Dc.l	Scrn_PiecEv
		Dc.l	Scrn_AnimEv
		Dc.l	Scrn_MoveEv
		Dc.l	Scrn_SondEv
		Dc.l	Scrn_SongEv

Scrn_GameEv:	Dc.l	0		;Rtn
		Dc	22,1,0,0,0,0,0	;Size,Type,Time,...
		Dc	0,0,0		;Unused,X,Y		14,16,18
		Dc	0		;Unused			20

Scrn_TextEv:	Dc.l	SEvn_UseFont	;Rtn
		Dc	24,2,0,0,0,0,0	;Size,Type,Time,...
		Dc	-1,0,0,0	;Font,X,Y,Unused	14,16,18,20
		Dc	0		;String			22

Scrn_PiecEv:	Dc.l	SEvn_UsePiec	;Rtn
		Dc	24,3,0,0,0,0,0	;Size,Type,Time,...
		Dc	-1,0,0		;Piece,X,Y		14,16,18
		Dc.b	0,0		;Flags,Value		20,21
		Dc	0		;Unused			22

Scrn_AnimEv:	Dc.l	SEvn_UseAnim	;Rtn
		Dc	26,4,0,0,0,0,0	;Size,Type,Time,...
		Dc	-1,0,0,0	;Animation,X,Y,AnimDel	14,16,18,20
		Dc.b	0,0		;AnimCon,AnimDir	22,23
		Dc	0		;Unused			24

Scrn_MoveEv:	Dc.l	0		;Rtn
		Dc	22,5,0,0,0,0,0	;Size,Type,Time,...
		Dc	-1,0,0		;Movement,X,Y		14,16,18
		Dc	0		;Unused			20

Scrn_SondEv:	Dc.l	0		;Rtn
		Dc	18,6,0,0,0,0,0	;Size,Type,Time,...
		Dc	-1		;Sound			14
		Dc	0		;Unused			16

Scrn_SongEv:	Dc.l	SEvn_UseSong	;Rtn
		Dc	18,7,0,0,0,0,0	;Size,Type,Time,...
		Dc	-1		;Song			14
		Dc	0		;Unused			16
*---------------
Scrn_DelEvent:	Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.w	SDE_End
		Move.l	a2,SDE_ListAdr
		Bsr.w	Update_ScrnBuf

		Move.l	Mem_ScrnBuf,a2		;Get buffer address	###

		Move	Cur_ScrnEvent(pc),d0
		Move	d0,SDE_Loc
		Bmi.w	SDE_End
	*-- Find Event Length (A3->Address)
		Move	Cur_ScrnEvent(pc),d2
		Move	d2,d3
		Add	d3,d3
		Move	32(a2,d3.w),d3		;<-- Header size here!
		Lea	00(a2,d3.w),a3
		Move	(a3),d0
		Addq	#2,d0			;Plus 2 for EventOffset
		Move	d0,SDE_BytesSub
	*-- Free old Object
		Move.l	SDE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_ScrnBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Sub	SDE_BytesSub(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	SDE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	SDE_NEr
		Jmp	Mess_MemErr		;###
	SDE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_ScrnBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub	SDE_BytesSub(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Subq	#1,d7			;+
		Move	d7,(a1)+		;+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+

		Move.l	a1,a3			;First event address (Dst)
		Move	d7,d6
		Add	d6,d6
		Add	d6,a3

		Move.l	a2,a4			;First event address (Src)
		Move	d7,d6
		Addq	#1,d6
		Add	d6,d6
		Add	d6,a4
	*-- Copy Events
		Clr	d0
		Move	d7,d6
		Add	d6,d6
		Add	#32,d6			;'Header' Size
	SDE_CEL:Cmp	SDE_Loc(pc),d0		;Delete this Event?
		Beq.b	SDE_DE
		Move	(a4)+,d1		;Copy EventSize
		Move	d1,(a3)+		;+
		Bmi.b	SDE_CEE			;If -1 then end
		Move	d6,(a1)+		;Write EventOffset
		Add	d1,d6			;Add EventSize
		Subq	#3,d1
	SDE_CEB:Move.b	(a4)+,(a3)+
		Dbf	d1,SDE_CEB
		Addq	#1,d0
		Bra.b	SDE_CEL
	SDE_CEE:
	SDE_End:Move	#-1,Cur_ScrnEvent
		Bsr.b	Upd_ScrnPropD
		Bsr.b	Upd_ScrnEventsD
		;Bsr.w	Upd_ScrnEventsG
		Bsr.w	Upd_SEvnDL
		Bsr.w	Upd_SEvnAllG
		Bra.w	Draw_Screen

	SDE_DE:	Move	(a4),d0		;EventSize
		Add	d0,a4		;Skip it!
		Bra.b	SDE_CEL

SDE_Loc:	Dc	0
SDE_ListAdr:	Dc.l	0
SDE_BytesSub:	Dc	0
*---------------
Update_ScrnBuf:	Lea	Scrn_Info,a3	;###
		Jmp	Update_UnitBuf	;###
*---------------
Upd_ScrnPropD:	Clr	d7

		Lea	SEvn_Prop_Event(pc),a4
		Clr	8(a4)		;%PosY
		Move	#$ffff,4(a4)	;%KnobY

		Move	ScrnList_Len,d0	;No Levels?	;###
		Beq.b	USP_End

		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.b	USP_End
		Move.l	(a2),a2

		Move	6(a2),d7	;Total
		Cmp	#4,d7
		Ble.b	USP_End

		Move.l	#$40000,d0
		Divu	d7,d0
		Addq	#1,d0
		Move	d0,4(a4)
	USP_End:Rts
*---------------
Upd_ScrnEventsD:Lea	GSEvn_Event1(pc),a0	;Clear EventList
		Move	#'XX',-72+24(a0)	;+
				
		Move	ScrnList_Len,d0		;No Screens?	###
		Beq.w	USE_End
		
		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.w	USE_End
		Move.l	(a2),a2
	*-- Read prop and calculate Event number
		Lea	SEvn_Prop_Event(pc),a4
		Clr.l	d4
		Move	8(a4),d4	;%PosY
		Clr.l	d5
		Move	4(a4),d5	;%KnobY
		Lsr	#3,d5		;Divide by 4lines*2half
		Add.l	d5,d4
		Mulu	6(a2),d4	;Total
		Swap	d4
		Move	d4,d2
		Move	6(a2),d1	;Total

		Lea	GSEvn_Event1(pc),a0
		Clr	d0
	USE_Lop:Move	#'XX',-72+24(a0)
		Tst	d1
		Ble.w	USE_NEv
		Move	#'GD',-72+24(a0)
	*-- Find Event (A3->Address)
		Move	d2,d3
		Add	d3,d3
		Move	32(a2,d3.w),d3	;<-- Header size here!
		Lea	00(a2,d3.w),a3
	*-- Write event text
		Clr.l	-4(a0)

		Move	2(a3),d7	;Get Event type

		Cmp	#2,d7		;Is Text?
		Beq.b	USE_Txt
		Cmp	#3,d7		;Is Piece?
		Beq.b	USE_Pie
		Cmp	#4,d7		;Is Animation?
		Beq.b	USE_Ani
		Cmp	#5,d7		;Is Movement?
		Beq.b	USE_Mov
		Cmp	#6,d7		;Is Sound?
		Beq.b	USE_Snd
		Cmp	#7,d7		;Is Song?
		Beq.b	USE_Sng
		Bra.b	USE_NOk
		
	USE_Txt:Move	14(a3),d4	;Unit
		Move.l	Mem_FontList,a5	;###
		Bra.b	USE_Uni

	USE_Pie:Move	14(a3),d4	;Unit
		Move.l	Mem_PiecList,a5	;###
		Bra.b	USE_Uni

	USE_Ani:Move	14(a3),d4	;Unit
		Move.l	Mem_AnimList,a5	;###
		Bra.b	USE_Uni

	USE_Mov:Move	14(a3),d4	;Unit
		Move.l	Mem_MoveList,a5	;###
		Bra.b	USE_Uni

	USE_Snd:Move	14(a3),d4	;Unit
		Move.l	Mem_SondList,a5	;###
		Bra.b	USE_Uni

	USE_Sng:Move	14(a3),d4	;Unit
		Move.l	Mem_SongList,a5	;###
		Bra.w	USE_Uni

	USE_Uni:Ext.l	d4
		Bmi.b	USE_NOk
		Lsl.l	#5,d4
		Add.l	d4,a5
		Addq	#8,a5
		Move.l	a5,-4(a0)
		Bra.w	USE_NOk
	*-- Write image
	USE_NOk:Lea	Scrn_ImageList(pc),a4
		Move	2(a3),d3
		Add	d3,d3
		Move	-2(a4,d3.w),32(a0)

		Bclr	#0,4(a0)
		Cmp	Cur_ScrnEvent(pc),d2
		Bne.b	USE_NCr
		Bset	#0,4(a0)
	USE_NCr:
		Subq	#1,d1		;Count Amount
		Addq	#1,d2		;Count EventList

	USE_NEv:Add	#106-24,a0
		Addq	#1,d0		;Count ListLines
		Cmp	#4,d0
		Beq.b	USE_End
		Bra.w	USE_Lop

	USE_End:Rts

Scrn_ImageList:	Dc	Im_GameScr-Im	;1
		Dc	Im_Text-Im	;2
		Dc	Im_Piece-Im	;3
		Dc	Im_Anim-Im	;4
		Dc	Im_Path-Im	;5
		Dc	Im_Sound-Im	;6
		Dc	Im_Song-Im	;7
*---------------
Upd_ScrnEventsG:Lea	SEvn_EventsDL(pc),a4
		Lea	SEvnLay,a5	;###
		Jmp	Draw_All	;###
*---------------
Upd_SEvnDL:	Move	Cur_ScrnEvent(pc),d2
		Bpl.b	USDL_Ok
		Lea	GSEvn_EventJP(pc),a0
		Lea	SEvn_NoEventDL(pc),a1
		Move.l	a1,2(a0)
		Bra.b	USDL_E
	*-- Find Event (A3->Address)
	USDL_Ok:Move	d2,d3
		Add	d3,d3
		Move	32(a2,d3.w),d3	;<-- Header size here!
		Lea	00(a2,d3.w),a3
	*-- Write DrawList
		Lea	SEvn_DrawLists(pc),a4
		Move	2(a3),d3
		Lsl	#2,d3
		Lea	GSEvn_EventJP(pc),a0
		Move.l	0(a4,d3.w),2(a0)
	USDL_E:	Rts

SEvn_DrawLists:	Dc.l	SEvn_NoEventDL	;0
		Dc.l	SEvn_AnimDL	;1
		Dc.l	SEvn_TextDL	;2
		Dc.l	SEvn_PiecDL	;3
		Dc.l	SEvn_AnimDL	;4
		Dc.l	SEvn_MoveDL	;5
		Dc.l	SEvn_SondDL	;6
		Dc.l	SEvn_SongDL	;7
*---------------
Upd_SEvnAllG:	Lea	SEvnLay,a5	;###
		Lea	GSEvn_All(pc),a4
		Jmp	Draw_All	;###
*---------------
SEvn_Browse:	Lea	SEvn_Events(pc),a4
		Lea	SEvnLay,a5	;###
		Jmp	Draw_All	;###
*---------------
SEvn_Select1:	Moveq.l	#0,d7
		Bra.b	SEvn_Select
SEvn_Select2:	Moveq.l	#1,d7
		Bra.b	SEvn_Select
SEvn_Select3:	Moveq.l	#2,d7
		Bra.b	SEvn_Select
SEvn_Select4:	Moveq.l	#3,d7

SEvn_Select:	Move	#-1,Cur_ScrnEvent
		Move.l	HitGd,a0	;Button off?	###
		Btst	#0,4(a0)	;+
		Beq.b	SS_End		;+

		Move	ScrnList_Len,d0	;No Events?	###
		Beq.b	SS_End

		Bsr.b	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.b	SS_End
		Move.l	(a2),a2
	*-- Read prop and calculate Event number
	SS_Ok:	Lea	SEvn_Prop_Event(pc),a4
		Clr.l	d4
		Move	8(a4),d4	;%PosY
		Clr.l	d5
		Move	4(a4),d5	;%KnobY
		Lsr	#3,d5		;Divide by 4lines*2half
		Add.l	d5,d4

		Move	6(a2),d1	;Total
		Mulu	d1,d4
		Swap	d4
		Add	d7,d4
		Move	d4,Cur_ScrnEvent

	SS_End:	Clr	Scrn_CurPos
		Bsr.w	Upd_SEvnDL
		Bsr.w	Buffer_ScrnText
		Bsr.w	Draw_Screen
		Bra.w	Upd_SEvnAllG

Cur_ScrnEvent:	Dc	-1
*---------------
Scrn_Modes:	Lea	SModLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Scrn_Events:	Lea	SEvnLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Get_Scrn_LAdr:	Move.l	Mem_ScrnList,a2	;###
		Clr.l	d0
		Move	Cur_Scrn,d0	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Check_Scrn:	Lea	Scrn_Jump(pc),a0
		Move	ScrnList_Len,d0	;###
		Beq.b	CS_NoUn
	*-- Find current Screen, and check if it exists
		Bsr.b	Get_Scrn_LAdr
		Tst.l	(a2)		;Any Screen?
		Beq.b	CS_NoGr		;No
		Lea	Scrn_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CS_NoUn:Lea	Scrn_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CS_NoGr:Lea	Scrn_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
Upd_Scrn_XY:	Lea	ScrnLay,a5	;###
		Lea	Scrn_Gfx(pc),a4
		Jsr	Calc_Coord	;###

		Move	X2,d0		;###
		Sub	X1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#352,d0
		Lea	Scrn_Prop_X(pc),a0
		Move	#352,d2
		Sub	d1,d2
		Mulu	6(a0),d2
		Move.l	#65536,d3
		Sub	d0,d3
		Divu	d3,d2
		Move	d2,ScrnX

		Move	Y2,d0		;###
		Sub	Y1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#256,d0
		Lea	Scrn_Prop_Y(pc),a0
		Move	#256,d2
		Sub	d1,d2
		Mulu	8(a0),d2
		Move.l	#65536,d3
		Sub	d0,d3
		Divu	d3,d2
		Move	d2,ScrnY
		Rts
*---------------
Scrn_Offset:	Bsr.b	Upd_Scrn_XY
		Bra.w	Draw_Screen
*---------------
Upd_Scrn_OffsD:	Lea	ScrnLay,a5	;###
		Lea	Scrn_Gfx(pc),a4
		Jsr	Calc_Coord	;###

		Move	X2,d0		;###
		Sub	X1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#352,d0
		Lea	Scrn_Prop_X(pc),a0
		Move	d0,2(a0)
		Move	#352,d2
		Sub	d1,d2
		Move.l	#65536,d3
		Sub	d0,d3
		Mulu	ScrnX(pc),d3
		Divu	d2,d3
		Move	d3,6(a0)

		Move	Y2,d0		;###
		Sub	Y1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#256,d0
		Lea	Scrn_Prop_Y(pc),a0
		Move	d0,4(a0)
		Move	#256,d2
		Sub	d1,d2
		Move.l	#65536,d3
		Sub	d0,d3
		Mulu	ScrnY(pc),d3
		Divu	d2,d3
		Move	d3,8(a0)

		Lea	Scrn_Prop_X(pc),a0
		Clr.l	d0
		Move	2(a0),d0
		Clr.l	d1
		Move	6(a0),d1
		Add.l	d1,d0
		Cmp.l	#$10000,d0
		Blo.b	UScO_XO
		Move	#$ffff,d0
		Sub	2(a0),d0
		Move	d0,6(a0)
	UScO_XO:
		Lea	Scrn_Prop_Y(pc),a0
		Clr.l	d0
		Move	4(a0),d0
		Clr.l	d1
		Move	8(a0),d1
		Add.l	d1,d0
		Cmp.l	#$10000,d0
		Blo.b	UScO_YO
		Move	#$ffff,d0
		Sub	4(a0),d0
		Move	d0,8(a0)
	UScO_YO:
		Bra.w	Upd_Scrn_XY

	UScO_Ed:Lea	Scrn_Prop_X(pc),a0
		Move	#$ffff,2(a0)
		Clr	6(a0)
		Lea	Scrn_Prop_Y(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Rts

ScrnX:		Dc	0
ScrnY:		Dc	0
*---------------
Draw_Screen:
	*-- Clear gfx area
		Lea	Scrn_Gfx(pc),a4
		Lea	ScrnLay,a5	;###
		Jsr	Calc_Coord	;###

		Lea	ScrnLay,a5	;***	###
		Move.l	GfxBase,a6	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetAPen(a6)

		Move.l	a3,a1
		Move	X1,d0	;###
		Move	Y1,d1	;###
		Move	X2,d2	;###
		Move	Y2,d3	;###
		Jsr	RectFill(a6)

		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.w	DSc_Fin
		Move.l	(a2),a2

		Lea	32(a2),a3	;Get first offset address
		Move	6(a2),d7	;Get Total
		Moveq.l	#-1,d6

	DSc_EvL:Addq	#1,d6
		Subq	#1,d7		;Count Events
		Bmi.b	DSc_Fin		;Finished?

		Move	(a3)+,d0	;Get Offset
		Lea	00(a2,d0.w),a4	;Get Event Address
		Move	2(a4),d0	;Get EventType

		Cmp	Cur_ScrnEvent(pc),d6	;Is this current Event?
		Beq.b	DSc_EvL			;Yes, skip it!

		Cmp	#2,d0		;Is Text?
		Beq.b	DSc_Txt		;+
		Cmp	#3,d0		;Is Piece?
		Beq.b	DSc_Pie		;+
		Cmp	#4,d0		;Is Anim?
		Beq.b	DSc_Ani		;+
		Bra.b	DSc_End		;Something's wrong! Get out, quick!
		
	DSc_Txt:Clr	Scrn_TextOn
		Movem.l	d0-d7/a0-a6,-(a7)
		Move.l	a4,ScP_Event
		Lea	22(a4),a0
		Move.l	a0,ScP_String
		Bsr.w	Scrn_Print
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	DSc_EvL		;Loop

	DSc_Pie:Movem.l	d0-d7/a0-a6,-(a7)
		Move.l	a4,ScPi_Event
		Bsr.w	Scrn_Piece
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	DSc_EvL		;Loop

	DSc_Ani:Movem.l	d0-d7/a0-a6,-(a7)
		Move.l	a4,ScAn_Event
		Bsr.w	Scrn_Anim
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	DSc_EvL		;Loop

	DSc_Fin:Bsr.w	Check_Scrn_Edit
	
	DSc_End:Rts
*---------------
Scrn_Anim:	;(ScAn_Event=Event)
		Lea	Scrn_Gfx(pc),a4
		Lea	ScrnLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	ScAn_Event(pc),a3
		Cmp.w	#4,2(a3)	;Anim?
		Bne.w	ScAn_Ed

		Move	16(a3),ScAn_X
		Move	18(a3),ScAn_Y

		Move.l	Mem_AnimList,a2	;###
		Clr.l	d0
		Move	14(a3),d0
		Bmi.w	ScAn_Ed
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.w	ScAn_Ed
		Move.l	(a2),a5

	*-- Find Frame (A1->Address)
		Moveq.l	#1,d0	;Frame #1
		Add	d0,d0
		Move	10-2(a5,d0.w),d0
		Lea	00(a5,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,ScAn_Pieces
		Move.l	a1,ScAn_Address
	*-- Draw Frame
	ScAn_Nx:Subq.b	#1,ScAn_Pieces
		Bmi.w	ScAn_Ed
		Move.l	ScAn_Address(pc),a1
		Move	(a1)+,d0	;Piece
		Move	(a1)+,d2	;X
		Move	(a1)+,d3	;Y
		Move.b	(a1)+,d4	;Flags
		Move.b	(a1)+,d5	;Value
		Move.l	a1,ScAn_Address

		Add	ScAn_X(pc),d2
		Add	X1,d2		;###
		Sub	ScrnX(pc),d2
		Add	ScAn_Y(pc),d3
		Add	Y1,d3		;###
		Sub	ScrnY(pc),d3
		Lea	ScrnLay,a0	;###
		Bsr.w	Draw_Piece_AnyW

	ScAn_No:Bra.w	ScAn_Nx
	ScAn_Ed:Rts

ScAn_Event:	Dc.l	0
ScAn_Pieces:	Dc.b	0,0
ScAn_Address:	Dc.l	0
ScAn_X:		Dc	0
ScAn_Y:		Dc	0
*---------------
Scrn_Screen:	Move	#-1,Cur_ScrnEvent
		Lea	Scrn_Gfx(pc),a4
		Lea	ScrnLay,a5	;###
		Jsr	Calc_Coord	;###

		Move	LayX,d0		;###
		Sub	X1,d0		;###
		Add	ScrnX(pc),d0
		Move	d0,Scrn_PointX

		Move	LayY,d0		;###
		Sub	Y1,d0		;###
		Add	ScrnY(pc),d0
		Move	d0,Scrn_PointY
		
		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.w	ScS_Fin
		Move.l	(a2),a2

		Lea	32(a2),a3	;Get first offset address
		Move	6(a2),d7	;Get Total
		Moveq.l	#-1,d6

	ScS_EvL:Addq	#1,d6
		Subq	#1,d7		;Count Events
		Bmi.w	ScS_Fin		;Finished?

		Move	(a3)+,d0	;Get Offset
		Lea	00(a2,d0.w),a4	;Get Event Address
		Move	2(a4),d0	;Get EventType

		Cmp	#2,d0		;Is Text?
		Beq.b	ScS_Txt		;+
		Cmp	#3,d0		;Is Piece?
		Beq.w	ScS_Pie		;+
		Cmp	#4,d0		;Is Anim?
		Beq.w	ScS_Ani		;+
		Bra.w	ScS_End		;Something's wrong! Get out, quick!


	ScS_Txt:Move.l	Mem_FontList,a0	;###
		Move	14(a4),d0
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a0
		Tst.l	(a0)
		Beq.b	ScS_EvL
		Move.l	(a0),a5

		Move	16(a4),ScST_X
		Move	18(a4),ScST_Y
		Move.l	a4,ScST_Event

		Lea	22(a4),a4	;Get Text
	ScST_Lp:Clr	d3
		Move.b	(a4)+,d3
		Beq.w	ScST_Ed
		Cmp.b	#32,d3	;Space?
		Beq.w	ScST_Sp
		Cmp.b	#10,d3	;Return?
		Beq.w	ScST_Rt
		Sub.b	6(a5),d3
		Lsl	#2,d3
		Move	16(a5,d3.w),d2	;Piece
		Bmi.w	ScST_Lp

		Move	ScST_X(pc),d0
		Move	18(a5,d3.w),d1	;YOffset
		Add	ScST_Y(pc),d1
		Neg	d0
		Neg	d1

		Move.l	Mem_PiecList,a0	;###
		Ext.l	d2
		Lsl.l	#5,d2
		Add.l	d2,a0
		Move.l	(a0),a0

		Add	Scrn_PointX(pc),d0
		Add	Scrn_PointY(pc),d1
		Moveq.l	#0,d2

		Movem.l	d1-d7/a0-a6,-(a7)
		Move.l	a0,a2
		Jsr	CPiec_Pixel_Tst		;###
		Move	d7,d0
		Movem.l	(a7)+,d1-d7/a0-a6

		Tst	d0
		Ble.b	ScST_XY
		Move	d6,Cur_ScrnEvent	;Set current Event
	ScST_Ed:Bra.w	ScS_EvL		;Loop

	ScST_XY:Move	8(a5),d0	;Font_Width
		Move	14(a5),d4	;Font_PropFlag
		Btst	#0,d4		;Proportional?
		Beq.b	ScST_AW
		Add	6(a0),d0	;Piec_SizeX
	ScST_AW:Add	d0,ScST_X
		Bra.w	ScST_Lp

	ScST_Sp:Move	12(a5),d0	;Font_SpaceWidth
		Bra.b	ScST_AW

	ScST_Rt:Move	10(a5),d0	;Font_Height
		Add	d0,ScST_Y
		Move.l	ScST_Event(pc),a0
		Move	16(a0),ScST_X
		Bra.w	ScST_Lp

ScST_X:		Dc	10
ScST_Y:		Dc	40
ScST_Event:	Dc.l	0


	ScS_Pie:Move.l	Mem_PiecList,a0	;###
		Move	14(a4),d0
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a0
		Tst.l	(a0)
		Beq.w	ScS_EvL
		Move.l	(a0),a0

		Move	Scrn_PointX(pc),d0
		Sub	16(a4),d0
		Move	Scrn_PointY(pc),d1
		Sub	18(a4),d1
		Moveq.l	#0,d2

		Movem.l	d1-d7/a0-a6,-(a7)
		Move.l	a0,a2
		Jsr	CPiec_Pixel_Tst		;###
		Move	d7,d0
		Movem.l	(a7)+,d1-d7/a0-a6

		Tst	d0
		Ble.w	ScS_EvL
		Move	d6,Cur_ScrnEvent	;Set current Event
		Bra.w	ScS_EvL			;Loop


	ScS_Ani:Move.l	Mem_AnimList,a0	;###
		Move	14(a4),d0
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a0
		Tst.l	(a0)
		Beq.w	ScS_EvL
		Move.l	(a0),a5
	*-- Find Frame (A1->Address)
		Moveq.l	#1,d0	;Frame #1
		Add	d0,d0
		Move	10-2(a5,d0.w),d0
		Lea	00(a5,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,ScSA_Pieces
		Move.l	a1,ScSA_Address
	*-- Draw Frame
	ScSA_Nx:Subq.b	#1,ScSA_Pieces
		Bmi.w	ScSA_Ed
		Move.l	ScSA_Address(pc),a1
		Move	(a1)+,d2	;Piece
		Move	(a1)+,d0	;X
		Neg	d0
		Move	(a1)+,d1	;Y
		Neg	d1
		Move.b	(a1)+,d4	;Flags
		Move.b	(a1)+,d5	;Value
		Move.l	a1,ScSA_Address

		Move.l	Mem_PiecList,a0	;###
		Ext.l	d2
		Lsl.l	#5,d2
		Add.l	d2,a0
		Move.l	(a0),a0

		Add	Scrn_PointX(pc),d0
		Sub	16(a4),d0
		Add	Scrn_PointY(pc),d1
		Sub	18(a4),d1
		Moveq.l	#0,d2

		Movem.l	d1-d7/a0-a6,-(a7)
		Move.l	a0,a2
		Jsr	CPiec_Pixel_Tst		;###
		Move	d7,d0
		Movem.l	(a7)+,d1-d7/a0-a6

		Tst	d0
		Ble.b	ScSA_Nx
		Move	d6,Cur_ScrnEvent	;Set current Event
	ScSA_Ed:Bra.w	ScS_EvL			;Loop

ScSA_Pieces:	Dc.b	0,0
ScSA_Address:	Dc.l	0

	ScS_Fin:Clr	Scrn_CurPos
		Bsr.w	Upd_ScrnPropD
		Bsr.w	Upd_ScrnEventsD
		Bsr.w	Upd_SEvnDL
		Bsr.w	Buffer_ScrnText
		Bsr.w	Upd_SEvnAllG
		Bsr.w	Draw_Screen

		Bsr.w	Update_ScrnBuf

		Bsr.w	Get_Scrn_Event
		Beq.w	ScS_End
		Or	#2,4(a2)	;Set NeedsUpdate

	ScS_DrL:Lea	Scrn_Gfx(pc),a4
		Lea	ScrnLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	Screen_Struct,a0	;Get XY	###
		Move	18(a0),RawX
		Move	16(a0),RawY
		Jsr	Which_Layer	;Calculate Layer XY ###

		Jsr	Check_Left_Up	;###
		Bne.b	ScS_End

		Move	LayX,d0		;###
		Sub	X1,d0		;###
		Add	ScrnX(pc),d0
		Move	d0,d2
		Sub	Scrn_PointX(pc),d0
		Move	d2,Scrn_PointX

		Move	LayY,d1		;###
		Sub	Y1,d1		;###
		Add	ScrnY(pc),d1
		Move	d1,d3
		Sub	Scrn_PointY(pc),d1
		Move	d3,Scrn_PointY
		
		Tst	d0
		Bne.b	ScS_Mov
		Tst	d1
		Bne.b	ScS_Mov
		Bra.b	ScS_NMv

	ScS_Mov:Add	d0,16(a3)
		Add	d1,18(a3)
		
		Movem.l	d1-d7/a0-a6,-(a7)
		Bsr.w	Draw_Screen

		Lea	SEvnLay,a5	;###
		Lea	GSEvn_EventJP(pc),a4
		Jsr	Draw_All	;###
		Movem.l	(a7)+,d1-d7/a0-a6

	ScS_NMv:Bra.w	ScS_DrL
	
	ScS_End:Rts
Scrn_PointX:	Dc	0
Scrn_PointY:	Dc	0
*---------------
Check_Scrn_Edit:Clr	Scrn_TextOn
		Bsr.w	Get_Scrn_Event
		Beq.b	CSE_End
		Move	2(a3),d0
		Cmp	#2,d0		;Is Text?
		Beq.b	CSE_Txt
		Cmp	#3,d0		;Is Piece?
		Beq.b	CSE_Pie
		Cmp	#4,d0		;Is Anim?
		Beq.b	CSE_Ani
		Bra.b	CSE_End

	CSE_Txt:Move.l	Mem_FontList,a2	;###
		Clr.l	d0
		Move	14(a3),d0	;Font
		Bmi.b	CSE_End
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	CSE_End
		Move	#1,Scrn_TextOn
		Bra.w	Scrn_UpdText

	CSE_Pie:Bra.w	Scrn_UpdPiec

	CSE_Ani:Bra.w	Scrn_UpdAnim

	CSE_End:Rts
*---------------	
Upd_ScrnNameD:	;(Update current Scrn name)
		Lea	Scrn_NameUpd(pc),a4
			Lea	GSEvn_ScrnName(pc),a5
			Lea	GSMod_ScrnName(pc),a6
		Clr.l	34(a4)
			Clr.l	(a5)
			Clr.l	(a6)
		Move	ScrnList_Len,d7	;###
		Beq.b	UScN_Ed
		Bsr.w	Get_Scrn_LAdr
		Move	4(a2),d0
		Btst	#0,d0
		Beq.b	UScN_Ed
		Addq	#8,a2
		Move.l	a2,34(a4)
			Move.l	a2,(a5)
			Move.l	a2,(a6)
	UScN_Ed:Rts
*---------------
Upd_ScrnNameG:	Lea	SModLay,a5	;###
		Lea	DrawList_SMod(pc),a4
		Moveq.l	#13,d7
		Jsr	Draw_Some	;###
		
		Lea	SEvnLay,a5	;###
		Lea	DrawList_SEvn(pc),a4
		Moveq.l	#13,d7
		Jsr	Draw_Some	;###
		
		Lea	ScrnLay,a5	;###
		Lea	Scrn_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Scrn_Load:	Move.l	ScrnList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Scrn,d4	;###
		Move.l	#'SCRN',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Scrn
		Bsr.b	Load_ScrnUnits
		Bra.w	Change_Scrn
*---------------
Load_ScrnUnits:	Move	#1,Cur_ScrnEvent
		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.w	LSU_End
		Move.l	(a2),a2
		Move	6(a2),d7	;Get Total
		Lea	32(a2),a3	;Get Offsets adress <-Header size here

	LSU_LpP:Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Upd_ScrnPropD
		Bsr.w	Upd_ScrnEventsD
		Bsr.w	Upd_SEvnDL
		Bsr.w	Upd_SEvnAllG
		Movem.l	(a7)+,d0-d7/a0-a6

		Move.l	a2,a4		;Get Event
		Add	(a3)+,a4	;+
	*-- Load Units
		Move	2(a4),d0	;Get Type
		Cmp	#2,d0
		Beq.b	LSU_Txt
		Cmp	#3,d0
		Beq.b	LSU_Pie
		Cmp	#4,d0
		Beq.b	LSU_Ani
		Bra.b	LSU_NTy

	LSU_Txt:Move	14(a4),d0	;Unit
		Bmi.b	LSU_NTy
		Move	d0,Cur_Font
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Font_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LSU_NTy

	LSU_Pie:Move	14(a4),d0	;Unit
		Bmi.b	LSU_NTy
		Move	d0,Cur_Piec
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Piec_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.w	LSU_NTy

	LSU_Ani:Move	14(a4),d0	;Unit
		Bmi.b	LSU_NTy
		Move	d0,Cur_Anim
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Anim_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.w	LSU_NTy

	LSU_NTy:Addq	#1,Cur_ScrnEvent
		Subq	#1,d7
		Bne.w	LSU_LpP
	LSU_End:Move	#1,Cur_ScrnEvent
		Bra.w	Change_Scrn
*---------------
Get_Scrn_Event:	Move	ScrnList_Len,d0	;###
		Beq.b	GSE_No
		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.b	GSE_No
		Move.l	(a2),a3
		Move	Cur_ScrnEvent(pc),d0
		Bmi.b	GSE_No
		Add	d0,d0
		Move	32(a3,d0.w),d0
		Lea	00(a3,d0.w),a3
		Moveq.l	#1,d0
		Rts
	GSE_No:	Clr.l	d0
		Rts
*---------------
Scrn_Piece:	;(ScPi_Event=Event)
		Lea	Scrn_Gfx(pc),a4
		Lea	ScrnLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	ScPi_Event(pc),a3
		Cmp.w	#3,2(a3)	;Piece?
		Bne.b	ScPi_Ed

		Move	14(a3),d0	;Piece
		Bmi.b	ScPi_Ed
		Move	16(a3),d2	;X-Pos
		Add	X1,d2		;###
		Sub	ScrnX(pc),d2
		Move	18(a3),d3	;Y-Pos
		Add	Y1,d3		;###
		Sub	ScrnY(pc),d3
		Lea	ScrnLay,a0	;###
		Move.b	20(a3),d4	;Flags
		Bsr.w	Draw_Piece_AnyW
	ScPi_Ed:Rts
ScPi_Event:	Dc.l	0
*---------------
Scrn_Print:	;(ScP_Event=Event, ScP_String=Text)
		Lea	Scrn_Gfx(pc),a4
		Lea	ScrnLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	ScP_Event(pc),a3
		Cmp.w	#2,2(a3)	;Text?
		Bne.w	ScP_Ed

		Move	16(a3),ScP_X
		Move	18(a3),ScP_Y
		Moveq.l	#0,d7

		Move.l	Mem_FontList,a2	;###
		Clr.l	d0
		Move	14(a3),d0
		Bmi.w	ScP_Ed
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.w	ScP_Ed
		Move.l	(a2),a5

		Move.l	ScP_String(pc),a4	;Get Text
	ScP_Lp:	
	*-- Maybe Draw Cursor
		Move	Scrn_TextOn(pc),d0
		Beq.w	ScP_NCu
		Cmp	Scrn_CurPos(pc),d7
		Bne.w	ScP_NCu
		Move.l	GfxBase,a6	;###
		Lea	ScrnLay,a1	;###
		Move.l	(a1),a1
		Move.l	12(a1),a3
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	HiCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1

		Move	ScP_X(pc),d0
		Add	X1,d0		;###
		Sub	ScrnX(pc),d0
		Move	ScP_Y(pc),d1
		Add	Y1,d1		;###
		Sub	ScrnY(pc),d1

		Move	d0,d2
		Cmp	#14,10(a5)	;If Height>14 then cursorwidth=2.
		Ble.b	ScP_Sml		;+
		Subq	#1,d0		;+
	ScP_Sml:Move	d1,d3
		Add	10(a5),d3

		Move	d1,d4
		Sub	Y1,d4
		Bpl.b	ScP_CY1
		Sub	d4,d1
	ScP_CY1:
		Move	d0,d4
		Sub	X1,d4
		Bpl.b	ScP_CX1
		Sub	d4,d0
	ScP_CX1:
		Move	d3,d4
		Sub	Y2,d4
		Bmi.b	ScP_CY2
		Sub	d4,d3
	ScP_CY2:
		Move	d2,d4
		Sub	X2,d4
		Bmi.b	ScP_CX2
		Sub	d4,d2
	ScP_CX2:
		Cmp	d3,d1
		Bgt.b	ScP_NCu
		Cmp	d2,d0
		Bgt.b	ScP_NCu

		Jsr	RectFill(a6)

	ScP_NCu:Addq	#1,d7
		Clr	d3
		Move.b	(a4)+,d3
		Beq.w	ScP_Ed
		Cmp.b	#32,d3	;Space?
		Beq.w	ScP_Spc
		Cmp.b	#10,d3	;Return?
		Beq.w	ScP_Ret
		Sub.b	6(a5),d3
		Lsl	#2,d3
		Move	16(a5,d3.w),d0	;Piece
		Bmi.w	ScST_Lp

		Move	ScP_X(pc),d2
		Add	X1,d2		;###
		Sub	ScrnX(pc),d2
		Move	18(a5,d3.w),d3	;YOffset
		Add	ScP_Y(pc),d3
		Add	Y1,d3		;###
		Sub	ScrnY(pc),d3
		Lea	ScrnLay,a0	;###
		Clr	d4		;Flags
		Bsr.w	Draw_Piece_AnyW

		Move	8(a5),d0	;Font_Width
		Move	14(a5),d4	;Font_PropFlag
		Btst	#0,d4		;Proportional?
		Beq.b	ScP_AdW
		Add	6(a3),d0	;Piec_SizeX
	ScP_AdW:Add	d0,ScP_X
		Bra.w	ScP_Lp
	ScP_Ed:	Rts

	ScP_Spc:Move	12(a5),d0	;Font_SpaceWidth
		Bra.b	ScP_AdW

	ScP_Ret:Move	10(a5),d0	;Font_Height
		Add	d0,ScP_Y
		Move.l	ScP_Event(pc),a3
		Move	16(a3),ScP_X
		Bra.w	ScP_Lp

ScP_Event:	Dc.l	0
ScP_String:	Dc.l	0
ScP_X:		Dc	10
ScP_Y:		Dc	40
Scrn_TextOn:	Dc	0
*---------------
Draw_Piece_AnyW:;(D0=Piece,D2=X,D3=Y,D4=Flags,A0=Layer,X1/Y1/X2/Y2=ClipRect)
		Move.l	a0,DPA_Layer
		Move	d0,DPA_Piece
	*-- Find Piece, and check if it exists
		Move.l	Mem_PiecList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	DPA_Non		;No
		Move.l	(a2),a2		;Get PieceData Address
		Move.l	a2,a3
	*-- Write stuff to Piec_BM
		Btst	#5,d4
		Beq.b	DPA_NFl
		Movem.l	d0-d7/a0-a6,-(a7)
		Move	DPA_Piece(pc),DB_FlpPc
		Jsr	DB_FlipY	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Move.l	Mem_FlipBuf,a2	;###
	DPA_NFl:
		Lea	Piec_BM,a1	;###
		Move	14(a2),(a1)+	;Write BytWidth to BM
		Move	08(a2),(a1)+	;Write SizeY to BM
		Move	10(a2),(a1)+	;Write Depth to BM
		Clr	(a1)+
		Move.l	a2,a0
		Add	#28,a0
		Move	10(a2),d0
		Subq	#1,d0
	DPA_BpL:Move.l	a0,(a1)+
		Add	12(a2),a0	;Add BplSize
		Dbf	d0,DPA_BpL
	*-- Get size
		Move	6(a2),d4	;SizeX
		Move	8(a2),d5	;SizeY
	*-- Clip top & left edge of Piece
		Clr	DPA_OffX
		Move	X1,d0		;###
		Sub	d2,d0
		Blt.b	DPA_NUX
		Move	d0,DPA_OffX
		Add	d0,d2
		Sub	d0,d4
		Ble.b	DPA_Out
	DPA_NUX:
		Clr	DPA_OffY
		Move	Y1,d0		;###
		Sub	d3,d0
		Blt.b	DPA_NUY
		Move	d0,DPA_OffY
		Add	d0,d3
		Sub	d0,d5
		Ble.b	DPA_Out
	DPA_NUY:
	*-- Clip bottom & right edge of Piece
		Move	d2,d0
		Add	d4,d0
		Sub	X2,d0		;###
		Ble.b	DPA_NOX
		Sub	d0,d4
		Addq	#1,d4
		Ble.b	DPA_Out
	DPA_NOX:
		Move	d3,d0
		Add	d5,d0
		Sub	Y2,d0		;###
		Ble.b	DPA_NOY
		Sub	d0,d5
		Addq	#1,d5
		Ble.b	DPA_Out
	DPA_NOY:
	*-- Get Mask address
		Add.l	24(a2),a2	;Address of BltMask
	*-- Blit Piece
		Lea	Piec_BM,a0	;###
		Move	DPA_OffX(pc),d0	;OffsetX
		Move	DPA_OffY(pc),d1	;OffsetY
		Move	#$e2,d6		;Minterm

		Move.l	GfxBase,a6	;###
		Move.l	DPA_Layer(pc),a1
		Move.l	(a1),a1
		Move.l	12(a1),a1
		Jsr	BltMaskBitMapRastPort(a6)
	DPA_Non:
	DPA_Out:Rts
DPA_Layer:	Dc.l	0
DPA_Piece:	Dc	0
DPA_OffX:	Dc	0
DPA_OffY:	Dc	0
*---------------
Scrn_UpdText:	Bsr.w	Get_Scrn_Event
		Beq.b	SUT_Ed
		Move.l	a3,ScP_Event
		Move.l	Mem_ScrnText,ScP_String	;###
		Bsr.w	Scrn_Print
	SUT_Ed:	Rts
*---------------
Scrn_UpdPiec:	Bsr.w	Get_Scrn_Event
		Beq.b	SUP_Ed
		Move.l	a3,ScPi_Event
		Bsr.w	Scrn_Piece
	SUP_Ed:	Rts
*---------------
Scrn_UpdAnim:	Bsr.w	Get_Scrn_Event
		Beq.b	SUA_Ed
		Move.l	a3,ScAn_Event
		Bsr.w	Scrn_Anim
	SUA_Ed:	Rts
*---------------
Scrn_GetText:	Move	IECode,d0		;Get Code	###
		Tst.b	d0			;Bit 7 - Key release?
		Bmi.w	SGT_End			;Yes, skip

		Move	IEQual,d1	;###
		And	#3,d1			;Left/Right Shift
		Bne.b	SGT_Sh

		Cmp	#$44,d0			;Return?
		Beq.w	SGT_Ret
		Cmp	#$43,d0			;Enter?
		Beq.w	SGT_Ent
		Cmp	#$45,d0			;Escape
		Beq.w	SGT_Esc

		Cmp	#$4f,d0			;LeftArrow?
		Beq.w	SGT_Lft
		Cmp	#$4e,d0			;RightArrow?
		Beq.w	SGT_Rgt
		Cmp	#$41,d0			;BackSpace?
		Beq.w	SGT_Bck
		Cmp	#$46,d0			;Delete?
		Beq.w	SGT_Del
		Bra.b	SGT_NSh

	SGT_Sh:	Cmp	#$41,d0			;Clear?
		Beq.w	SGT_Clr
		Cmp	#$46,d0			;Clear?
		Beq.w	SGT_Clr
		Cmp	#$4f,d0			;ToStart?
		Beq.w	SGT_TSt
		Cmp	#$4e,d0			;ToEnd?
		Beq.w	SGT_TEd
	SGT_NSh:
	*-- Convert to ASCII
		Lea	Event,a0		;Get Event Structure	###
		Lea	Key_Buffer,a1	;Convert Buffer	###
		Moveq.l	#8,d1			;Max 8 Characters
		Sub.l	a2,a2			;A2=0 - Default Keymap
		Move.l	ConBase,a6		;Get Console.Device Base ###
		Jsr	-48(a6)			;RawKeyConvert to ASCII
		Tst	d0			;Any Characters?
		Beq.b	SGT_End			;No
		Lea	Key_Buffer,a0	;Get 1 Character ###
		Move.b	(a0),d5			;+

	*-- Check if character exists in Font. If not, ignore it.
		Bsr.w	Get_Scrn_Event
		Beq.b	SGT_End

		Move.l	Mem_FontList,a2	;###
		Clr.l	d0
		Move	14(a3),d0
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.b	SGT_End
		Move.l	(a2),a5

		Move	d5,d0

		Cmp.b	#32,d5		;Space?
		Beq.b	SGT_Ok		;+
		Cmp.b	#10,d5		;Return?
		Beq.b	SGT_Ok		;+
		Sub.b	6(a5),d5	;Too low character code?
		Bmi.b	SGT_End		;+
		Cmp.b	7(a5),d5	;Too high character code?
		Bge.b	SGT_End		;+
		And	#$00ff,d5	;Find character Piece
		Lsl	#2,d5		;+
		Move	16(a5,d5.w),d5	;+
		Bmi.b	SGT_End		;Any Piece?

	SGT_Ok:	Move.l	Mem_ScrnText,a1	;###
		Move	Scrn_CurPos(pc),d1
	*-- Find length of string
		;Moveq.l	#-1,d3
		;Move.l	Mem_ScrnText,a2	;###
	SGT_Len:;Addq	#1,d3
		;Tst.b	(a2)+
		;Bne.b	SGT_Len
		;Addq	#1,d3
		;Cmp	8(a5),d3		;MaxLength
		;Bgt.b	SGT_Rpl

	SGT_Ins:;Move	8(a5),d3
		;Subq	#1,d3
		;Cmp	Scrn_CurPos(pc),d3
		;Beq.b	SGT_InL
		Addq	#1,Scrn_CurPos
	SGT_InL:Move.b	0(a1,d1.w),d2
		Move.b	d0,0(a1,d1.w)
		Beq.b	SGT_InE
		Addq	#1,a1
		Move	d2,d0
		Bra.b	SGT_InL
	SGT_InE:Addq	#1,d1
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Insert_ScrnText
		Movem.l	(a7)+,d0-d7/a0-a6
		Bsr.w	Draw_Screen
		;Bsr.w	Scrn_UpdText
	SGT_End:Rts

	SGT_Rpl:;Move	8(a5),d3
		;Subq	#1,d3
		;Cmp	Scrn_CurPos(pc),d3
		;Beq.b	SGT_NCr
		;Addq	#1,Scrn_CurPos
	SGT_NCr:;Move.b	d0,0(a1,d1.w)
		;Bra.w	Draw_Screen
		;;Bra.w	Scrn_UpdText

	SGT_Lft:Move	Scrn_CurPos(pc),d0
		Beq.b	SGT_NLf
		Subq	#1,Scrn_CurPos
		Bsr.w	Draw_Screen
		;Bsr.w	Scrn_UpdText
	SGT_NLf:Rts

	SGT_Rgt:Move	Scrn_CurPos(pc),d0
		Move.l	Mem_ScrnText,a1	;###
		Move.b	0(a1,d0.w),d7
		Beq.b	SGT_NRg
		;Move	8(a5),d3
		;Subq	#1,d3
		;Cmp	Scrn_CurPos(pc),d3
		;Beq.b	SGT_NRg
		Addq	#1,Scrn_CurPos
		Bsr.w	Draw_Screen
		;Bsr.w	Scrn_UpdText
	SGT_NRg:Rts

	SGT_Bck:Move	Scrn_CurPos(pc),d0
		Beq.b	SGT_NBk
		Move.l	Mem_ScrnText,a1	;###
	SGT_LBk:Addq	#1,a1
		Move.b	-1(a1,d0.w),-2(a1,d0.w)
		Bne.b	SGT_LBk
		Subq	#1,Scrn_CurPos
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Insert_ScrnText
		Movem.l	(a7)+,d0-d7/a0-a6
		Bsr.w	Draw_Screen
		;Bsr.w	Scrn_UpdText
	SGT_NBk:Rts

	SGT_Del:Move	Scrn_CurPos(pc),d0
		Move.l	Mem_ScrnText,a1	;###
	SGT_LDl:Addq	#1,a1
		Move.b	0(a1,d0.w),-1(a1,d0.w)
		Bne.b	SGT_LDl
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.b	Insert_ScrnText
		Movem.l	(a7)+,d0-d7/a0-a6
		Bsr.w	Draw_Screen
		;Bsr.w	Scrn_UpdText
	SGT_NDl:Rts

	SGT_Clr:Clr	Scrn_CurPos
		Move.l	Mem_ScrnText,a1	;###
		Move	8(a5),d0		;Get MaxLength
	SGT_ClL:Clr.b	(a1)+
		Dbf	d0,SGT_ClL
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.b	Insert_ScrnText
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.w	Draw_Screen
		;Bra.w	Scrn_UpdText

	SGT_TSt:Clr	Scrn_CurPos
		Bra.w	Draw_Screen
		;Bra.w	Scrn_UpdText

	SGT_TEd:
	*-- Find length of string
		Moveq.l	#-1,d3
		Move.l	Mem_ScrnText,a1	;###
	SGT_Ln2:Addq	#1,d3
		Tst.b	(a1)+
		Bne.b	SGT_Ln2
		;Cmp	8(a5),d3
		;Blt.b	SGT_NOv
		;Move	8(a5),d3
		;Subq	#1,d3
	SGT_NOv:Move	d3,Scrn_CurPos
		Bra.w	Draw_Screen
		;Bra.w	Scrn_UpdText

	SGT_Esc:Rts

	SGT_Ret:
	SGT_Ent:Move.l	Mem_ScrnText,a1	;###
		Move	Scrn_CurPos(pc),d1
		Moveq.l	#10,d0
		Bra.w	SGT_Ins
		Rts
Scrn_CurPos:	Dc	0
*---------------
Insert_ScrnText:Move	Cur_ScrnEvent(pc),IST_ChgEvent
		Bmi.w	IST_End		;No Part Selected

	*-- Find Event (A5->Address)
		Bsr.w	Get_Scrn_LAdr
		Move.l	(a2),a4
		Move	IST_ChgEvent(pc),d0
		Add	d0,d0
		Move	32(a4,d0.w),d0		;<- Header Size here!
		Lea	00(a4,d0.w),a5
		Cmp	#2,2(a5)	;Is Text?
		Bne.w	IST_End		;No, End!
	*-- Find current Screen, and check if it exists
		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.w	IST_End
		Move.l	a2,IST_ListAdr
		Move.l	(a2),a0
		Bsr.w	Update_ScrnBuf
	*-- Free old Unit
		Move.l	IST_ListAdr(pc),a4
		Jsr	Free_Unit	;###
	*-- Find Event (A5->Address)
		Move.l	Mem_ScrnBuf,a4	;###
		Move	IST_ChgEvent(pc),d0
		Add	d0,d0
		Move	32(a4,d0.w),d0		;<- Header Size here!
		Lea	00(a4,d0.w),a5
	*-- Find length of string
		Moveq.l	#0,d0
		Move.l	Mem_ScrnText,a3	;###
	IST_Ln:	Addq	#1,d0
		Tst.b	(a3)+
		Bne.b	IST_Ln

		Add	#22,d0
		Btst	#0,d0		;Even
		Beq.b	IST_NEv		;+
		Addq	#1,d0		;+
	IST_NEv:
		Sub	(a5),d0		;EventSize
		Move	d0,IST_BytesChg
	*-- Allocate space for new Screen
		Move.l	Mem_ScrnBuf,a2	;Get buffer address ###
		Clr.l	d0
		Move.l	2(a2),d0
		Add	IST_BytesChg(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	IST_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	IST_NEr
		Jmp	Mess_MemErr	;###
	IST_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Screen address
		Move.l	Mem_ScrnBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	IST_BytesChg(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Move	d7,(a1)+		;+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+

	*-- Copy FrameOffsets
		Clr	d0
		Moveq.l	#0,d3
	IST_LFO:Cmp	d7,d0
		Beq.b	IST_FnO
		Move	(a2)+,d2
		Add	d3,d2
		Move	d2,(a1)+
	IST_Nxt:Cmp	IST_ChgEvent(pc),d0	;Is Event to change?
		Bne.b	IST_NCh
		Move	IST_BytesChg(pc),d3
	IST_NCh:Addq	#1,d0
		Bra.b	IST_LFO
	*-- Copy from start to end
	IST_FnO:Clr	d6
	IST_C2L:Cmp	d7,d6
		Beq.b	IST_FnP

		Cmp	IST_ChgEvent(pc),d6
		Beq.b	IST_Chg

		Move	(a2)+,d0		;Size
		Move	d0,(a1)+		;Size
		Subq	#2,d0
	IST_C1L:Subq	#1,d0			;Count number of bytes
		Bmi.b	IST_C1E
		Move.b	(a2)+,(a1)+
		Bra.b	IST_C1L			;Loop

	IST_Chg:Move	(a2)+,d0	;Copy Size
		Move	d0,d1
		Sub	#22,d1
		Add	IST_BytesChg(pc),d0
		Move	d0,(a1)+
		Move	(a2)+,(a1)+	;Copy Type
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move	(a2)+,(a1)+
		
		Add	d1,a2		;Skip old text

		Move.l	Mem_ScrnText,a0	;###
		Clr.l	d0
	IST_CTx:Addq	#1,d0
		Move.b	(a0)+,(a1)+
		Bne.b	IST_CTx

		Btst	#0,d0		;Even
		Beq.b	IST_NE2
		Clr.b	(a1)+
	IST_NE2:

	IST_C1E:Addq	#1,d6		;Count Events
		Bra.b	IST_C2L
	IST_FnP:Move	(a2)+,(a1)+	;Copy -1
	IST_End:Rts
IST_ListAdr:	Dc.l	0
IST_BytesChg:	Dc	0
IST_ChgEvent:	Dc	0
*---------------
Buffer_ScrnText:Move	Cur_ScrnEvent(pc),BST_BufEvent
		Bmi.b	BST_End		;No Event Selected
	*-- Find current Screen, and check if it exists
		Bsr.w	Get_Scrn_LAdr
		Tst.l	(a2)
		Beq.b	BST_End
		Move.l	a2,BST_ListAdr
		Move.l	(a2),a4
	*-- Find Event (A5->Address)
		Move	BST_BufEvent(pc),d0
		Add	d0,d0
		Move	32(a4,d0.w),d0	;<- Header Size here!
		Lea	00(a4,d0.w),a5
		Cmp	#2,2(a5)	;Text?
		Bne.b	BST_End		;No!

		Lea	22(a5),a1
		Move.l	Mem_ScrnText,a0	;###
	BST_CCo:Move.b	(a1)+,(a0)+
		Bne.b	BST_CCo
	BST_End:Rts
BST_ListAdr:	Dc.l	0
BST_BufEvent:	Dc	0
*---------------
Scrn_PlayScreen:Rts
*---------------
DrawList_Scrn:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Screen8T
		
		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Scrn_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Scrn_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Scrn_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-51,025

		Dc	'RO'
		Dc.l	Upd_ScrnNameD

Scrn_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Scrn_Name
		Dc	'RC',049,015,-73,023
		Dc	'TX',051,022,-124,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Scrn_Info,Unit_BrowseUp
		Dc	'BX',-70,015,-62,023
		Dc	'IM',-68,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Scrn_Info,Unit_BrowseDn
		Dc	'BX',-61,015,-53,023
		Dc	'IM',-59,018,3,Im_DArr-Im

		Dc	'GD'
		Dc.l	$0201000e,0,Scrn_PlayScreen
		Dc	'BX',-46,013,-34,025
		Dc	'IM',-44,015,9,Im_PlayScr-Im

		Dc	'GD'
		Dc.l	$020100c9,0,Scrn_Modes
		Dc	'BX',-29,013,-17,025
		Dc	'IM',-27,015,9,Im_GameScr-Im

		Dc	'GD'
		Dc.l	$020100c8,0,Scrn_Events
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_FullClip-Im

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

		Dc	'RO'
		Dc.l	Upd_Scrn_OffsD

		Dc	'GD'
		Dc.l	$02020000,Scrn_Prop_X,Scrn_Offset
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',020,-07,-40,-03

		Dc	'GD'
		Dc.l	$02020000,Scrn_Prop_Y,Scrn_Offset
		Dc	'BX',-09,028,-01,-10
		Dc	'BX',-07,030,-03,-34

Scrn_GfxUpd:	Dc	'RO'
		Dc.l	Check_Scrn

		Dc	'JP'
Scrn_Jump:	Dc.l	Scrn_None

Scrn_Yes:	Dc	'GD'
		Dc.l	$01000000,0,Scrn_Screen
Scrn_Gfx:	Dc	'DF',003,031,-13,-13
		Dc	'FR',000,028,-10,-10
		Dc	'RO'
		Dc.l	Draw_Screen
		Dc	'XX'

Scrn_No:	Dc	'BX',000,028,-10,-10
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Scrn_Load
		Dc	'BX',-37,030,-13,038
		Dc	'TX',-34,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Scrn_None:	Dc	'BX',000,028,-10,-10
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Scrn_Prop_X:	Dc.b	%00001010,0
		Dc	8192,0
		Dc	0,0
Scrn_Prop_Y:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,8192		;KnobX,Y
		Dc	0,0		;PosX,Y
*---------------
DrawList_SEvn:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	ScreenEvents8T
		Dc	'TX',124,009,-01,5
		Dc.l	DashT
		Dc	'TX',133,009,-148,5
GSEvn_ScrnName:	Dc.l	0

		Dc	'BX',000,011,-01,027

		Dc	'GD'
		Dc.l	$02010000,1,Scrn_AddEvent
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_GameScr-Im

		Dc	'GD'
		Dc.l	$020100c4,2,Scrn_AddEvent
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_Text-Im

		Dc	'GD'
		Dc.l	$02010087,3,Scrn_AddEvent
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Piece-Im

		Dc	'GD'
		Dc.l	$02010088,4,Scrn_AddEvent
		Dc	'BX',042,013,054,025
		Dc	'IM',044,015,9,Im_Anim-Im

		Dc	'GD'
		Dc.l	$020100c5,5,Scrn_AddEvent
		Dc	'BX',055,013,067,025
		Dc	'IM',057,015,9,Im_Path-Im

		Dc	'GD'
		Dc.l	$020100c6,6,Scrn_AddEvent
		Dc	'BX',068,013,080,025
		Dc	'IM',070,015,9,Im_Sound-Im

		Dc	'GD'
		Dc.l	$020100c7,7,Scrn_AddEvent
		Dc	'BX',081,013,093,025
		Dc	'IM',083,015,9,Im_Song-Im

		Dc	'GD'
		Dc.l	$02010000,8,Scrn_AddEvent
		Dc	'BX',094,013,106,025
		Dc	'IM',096,015,9,Im_Palette-Im

		Dc	'GD'
		Dc.l	$02010000,9,Scrn_AddEvent
		Dc	'BX',107,013,119,025
		Dc	'IM',109,015,9,Im_Effect-Im

		Dc	'GD'
		Dc.l	$02010000,10,Scrn_AddEvent
		Dc	'BX',120,013,132,025
		Dc	'IM',122,015,9,Im_Sound-Im

		Dc	'BX',000,028,-01,044

		Dc	'GD'
		Dc.l	$0201004e,0,Scrn_DelEvent
		Dc	'BX',003,030,015,042
		Dc	'IM',005,032,9,Im_ClrClips-Im

		Dc	'GD'
		Dc.l	$0201000b,0,Scrn_Undo
		Dc	'BX',020,030,032,042
		Dc	'IM',022,032,9,Im_Undo-Im

		Dc	'GD'
		Dc.l	$0201000e,0,Scrn_PlayScreen
		Dc	'BX',037,030,049,042
		Dc	'IM',039,032,9,Im_PlayScr-Im

GSEvn_All:	Dc	'BX',000,045,-01,071

		Dc	'TX',003,055,-01,8
		Dc.l	SEvn_CondT

		Dc	'JS'
		Dc.l	SEvn_TimeDL

		Dc	'BX',000,072,-01,141

GSEvn_EventJP:	Dc	'JP'
		Dc.l	SEvn_NoEventDL

SEvn_CondT:	Dc.b	'Condition:',0
PositionT:	Dc.b	'POSITION:',0
		Even
*---------------
SEvn_TimeDL:	Dc	'BX',003,056,-04,068
		Dc	'RO'
		Dc.l	Upd_SEvn_TimeD

		Dc	'TX',006,065,-01,5
		Dc.l	SEvn_TimeT
GSEvn_Time:	Dc	'GD'
		Dc.l	$02030a00,5,SEvn_Time
		Dc	'RC',-55,058,-26,066
		Dc	'TX',-52,065,-01,5
		Dc.l	SEvn_TimeNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Time_P,PlusMinus
		Dc	'BX',-24,058,-16,066
		Dc	'IM',-22,062,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Time_P,PlusMinus
		Dc	'BX',-15,058,-07,066
		Dc	'IM',-13,060,5,Im_Plus-Im

		Dc	'RT'

SEvn_Time_P:	Dc	1,0,32766,$0105
SEvn_TimeNT:	Dc.b	'    0',0
SEvn_TimeT:	Dc.b	'TIME (1/50 SEC):',0
		Even
*---------------
SEvn_Time:	Bsr.w	Get_Scrn_Event
		Beq.b	SET_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,4(a3)
		Bsr.b	Upd_SEvn_TimeD
		Bsr.b	Upd_SEvn_TimeG
	SET_Ed:	Rts
*---------------
Upd_SEvn_TimeD:	Bsr.w	Get_Scrn_Event
		Beq.b	USET_Ed
		Move	4(a3),d0
		Lea	SEvn_TimeNT+5(pc),a0
		Move	#$104,d7
		Jsr	Conv			;###
	USET_Ed:Rts
*---------------
Upd_SEvn_TimeG:	Lea	SEvnLay,a5		;###
		Lea	GSEvn_Time(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some		;###
*---------------
SEvn_NoEventDL:	Dc	'JP'
		Dc.l	SEvn_EventsDL
*---------------
SEvn_PiecDL:	Dc	'TX',003,082,-01,8
		Dc.l	SEvn_Piec8T

		Dc	'RO'
		Dc.l	SEvn_UpdPiNmD
		
		Dc	'GD'
		Dc.l	$020100bb,0,SEvn_Piec
		Dc	'BX',003,083,015,095
		Dc	'IM',005,085,9,Im_Piece-Im

		Dc	'GD'
		Dc.l	$0201008f,0,SEvn_UsePiec
		Dc	'BX',016,083,028,095
		Dc	'IM',018,087,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$020100c0,0,SEvn_PiecName
GSEvn_PiecName:	Dc	'BX',029,083,-17,095
		Dc	'TX',032,092,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$020100bf,0,SEvn_RemPiec
		Dc	'BX',-16,083,-04,095
		Dc	'IM',-14,085,9,Im_ClrClips-Im

		Dc	'BX',016,096,-04,108
		Dc	'RO'
		Dc.l	Upd_SEvn_FlipYD
		
GSEvn_PiecFlipY:Dc	'GD'
		Dc.l	$0201021f,0,SEvn_PiecFlipY
		Dc	'BX',003,096,015,108
		Dc	'IM',005,098,9,Im_FlipY-Im

		Dc	'BX',003,110,-04,122
		Dc	'TX',006,119,-01,5
		Dc.l	PositionT
		Dc	'RO'
		Dc.l	Upd_SEvn_PiecPosD

		Dc	'TX',-110,119,-01,5
		Dc.l	XT
GSEvn_PiecX:	Dc	'GD'
		Dc.l	$02030a00,4,SEvn_PiecPosX
		Dc	'RC',-103,112,-79,120
		Dc	'TX',-100,119,-01,5
		Dc.l	SEvn_PiecXNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-77,112,-69,120
		Dc	'IM',-75,116,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-68,112,-60,120
		Dc	'IM',-66,114,5,Im_Plus-Im

		Dc	'TX',-57,119,-01,5
		Dc.l	YT
GSEvn_PiecY:	Dc	'GD'
		Dc.l	$02030a00,4,SEvn_PiecPosY
		Dc	'RC',-50,112,-26,120
		Dc	'TX',-47,119,-01,5
		Dc.l	SEvn_PiecYNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-24,112,-16,120
		Dc	'IM',-22,116,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-15,112,-07,120
		Dc	'IM',-13,114,5,Im_Plus-Im

		Dc	'JP'
		Dc.l	SEvn_EventsDL

SEvn_Pos_P:	Dc	1,-999,9999,$0104
SEvn_Piec8T:	Dc.b	'Piece:',0
SEvn_PiecXNT:	Dc.b	'   0',0
SEvn_PiecYNT:	Dc.b	'   0',0
		Even
*---------------
SEvn_UpdPiNmD:	Lea	GSEvn_PiecName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Scrn_Event
		Beq.b	SEUPi_E
		Move	14(a3),d0	;Unit
		Bmi.b	SEUPi_E
		Ext.l	d0
		Move.l	Mem_PiecList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	SEUPi_E:Rts
*---------------
SEvn_UpdPiNmG:	Lea	SEvnLay,a5	;###
		Lea	GSEvn_PiecName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_Piec:	Lea	PiecLay,a5	;###
		Jmp	Open_Layer
*---------------
SEvn_UsePiec:	Bsr.b	SEvn_UsePiec_Com
		Bra.w	Upd_ScrnEventsG
SEvn_UsePiec_Com:
		Bsr.w	Get_Scrn_Event
		Beq.b	SUPi_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Unit info
		Move	PiecList_Len,d0		;###
		Beq.b	SUPi_E
		Jsr	Get_Piec_LAdr		;###
		Tst.l	(a2)
		Beq.b	SUPi_E
		Move	Cur_Piec,14(a3)		;Write Unit number	###
		Bsr.b	SEvn_UpdPiNmD
		Bsr.b	SEvn_UpdPiNmG
		Bsr.w	Draw_Screen
	SUPi_E:	Rts
*---------------
SEvn_RemPiec:	Bsr.w	Get_Scrn_Event
		Beq.b	SERPi_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Unit'	###
		Bsr.w	SEvn_UpdPiNmD
		Bsr.b	SEvn_UpdPiNmG
		Bsr.w	Draw_Screen
		Bsr.w	Upd_ScrnEventsG
	SERPi_E:Rts
*---------------
SEvn_PiecName:	Bsr.w	Get_Scrn_Event
		Beq.b	SPiN_Ed
		Move	14(a3),d0	;Unit
		Bmi.b	SPiN_Ed
		Move	d0,Cur_Piec
		Lea	PiecLay,a5	;###
		Tst.l	(a5)
		Beq.b	SPiN_Op
		Jsr	Change_Piec	;###
		Lea	PiecLay,a5	;###
	SPiN_Op:Jmp	Open_Layer
	SPiN_Ed:Rts
*---------------
SEvn_PiecPosX:	Move	#16,d5
		Bra.b	SEPP_Cm
SEvn_PiecPosY:	Move	#18,d5
	SEPP_Cm:Bsr.w	Get_Scrn_Event
		Beq.b	SEPP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,0(a3,d5.w)
		Bsr.b	Upd_SEvn_PiecPosD
		Bsr.b	Upd_SEvn_PiecPosG
		Bsr.w	Draw_Screen
	SEPP_Ed:Rts
*---------------
Upd_SEvn_PiecPosD:
		Bsr.w	Get_Scrn_Event
		Beq.b	USPP_Ed
	*-- Convert numbers
		Move	16(a3),d0
		Lea	SEvn_PiecXNT+4(pc),a0
		Move	#$8103,d7
		Jsr	Conv	;###
		Move	18(a3),d0
		Lea	SEvn_PiecYNT+4(pc),a0
		Move	#$8103,d7
		Jsr	Conv	;###
	USPP_Ed:Rts
*---------------
Upd_SEvn_PiecPosG:
		Lea	SEvnLay,a5	;###
		Lea	GSEvn_PiecX(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		Lea	GSEvn_PiecY(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_PiecFlipY:	Bsr.w	Get_Scrn_Event
		Beq.b	SPFY_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Bchg	#5,20(a3)
		Bsr.b	Upd_SEvn_FlipYD
		Bsr.b	Upd_SEvn_FlipYG
		Bsr.w	Draw_Screen
	SPFY_E:	Rts
*---------------
Upd_SEvn_FlipYD:Bsr.w	Get_Scrn_Event
		Beq.b	USFY_E
		Cmp	#3,2(a3)	;EventType=Piece?
		Bne.b	USFY_E
		Lea	GSEvn_PiecFlipY(pc),a0
		Bclr	#0,4(a0)
		Btst	#5,20(a1)
		Beq.b	USFY_E
		Bset	#0,4(a0)
	USFY_E:	Rts
*---------------
Upd_SEvn_FlipYG:Lea	SEvnLay,a5	;###
		Lea	GSEvn_PiecFlipY(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some
*---------------
SEvn_AnimDL:	Dc	'TX',003,082,-01,8
		Dc.l	SEvn_Anim8T

		Dc	'RO'
		Dc.l	SEvn_UpdAnNmD
		
		Dc	'GD'
		Dc.l	$020100ba,0,SEvn_Anim
		Dc	'BX',003,083,015,095
		Dc	'IM',005,085,9,Im_Anim-Im

		Dc	'GD'
		Dc.l	$02010090,0,SEvn_UseAnim
		Dc	'BX',016,083,028,095
		Dc	'IM',018,087,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$020100c1,0,SEvn_AnimName
GSEvn_AnimName:	Dc	'BX',029,083,-17,095
		Dc	'TX',032,092,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$020100be,0,SEvn_RemAnim
		Dc	'BX',-16,083,-04,095
		Dc	'IM',-14,085,9,Im_ClrClips-Im

		Dc	'RO'
		Dc.l	Upd_SEvn_AButD

		Dc	'GD'
		Dc.l	$0201000c,0,SEvn_AnimCon
GSEvn_AnimCon:	Dc	'BX',003,096,015,108
		Dc	'IM',005,098,9,Im_Loop-Im

		Dc	'GD'
		Dc.l	$02010008,0,SEvn_AnimDir
GSEvn_AnimDir:	Dc	'BX',016,096,028,108
		Dc	'IM',018,100,5,Im_Forward-Im

		Dc	'BX',029,096,-04,108

		Dc	'RO'
		Dc.l	Upd_SEvn_ADelD

		Dc	'TX',032,105,-01,5
		Dc.l	DelayT
GSEvn_AnimDel:	Dc	'GD'
		Dc.l	$02030ab0,2,SEvn_AnimDel
		Dc	'RC',-40,098,-26,106
		Dc	'TX',-37,105,-01,5
		Dc.l	SEvn_AnimDelNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_AnimDel_P,PlusMinus
		Dc	'BX',-24,098,-16,106
		Dc	'IM',-22,102,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_AnimDel_P,PlusMinus
		Dc	'BX',-15,098,-07,106
		Dc	'IM',-13,100,5,Im_Plus-Im

		Dc	'BX',003,110,-04,122
		Dc	'TX',006,119,-01,5
		Dc.l	PositionT
		Dc	'RO'
		Dc.l	Upd_SEvn_AnimPosD

		Dc	'TX',-110,119,-01,5
		Dc.l	XT
GSEvn_AnimX:	Dc	'GD'
		Dc.l	$02030a00,4,SEvn_AnimPosX
		Dc	'RC',-103,112,-79,120
		Dc	'TX',-100,119,-01,5
		Dc.l	SEvn_AnimXNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-77,112,-69,120
		Dc	'IM',-75,116,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-68,112,-60,120
		Dc	'IM',-66,114,5,Im_Plus-Im

		Dc	'TX',-57,119,-01,5
		Dc.l	YT
GSEvn_AnimY:	Dc	'GD'
		Dc.l	$02030a00,4,SEvn_AnimPosY
		Dc	'RC',-50,112,-26,120
		Dc	'TX',-47,119,-01,5
		Dc.l	SEvn_AnimYNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-24,112,-16,120
		Dc	'IM',-22,116,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-15,112,-07,120
		Dc	'IM',-13,114,5,Im_Plus-Im

		Dc	'JP'
		Dc.l	SEvn_EventsDL

SEvn_AnimDel_P:	Dc	1,1,99,$0102

SEvn_Anim8T:	Dc.b	'Animation:',0
SEvn_AnimXNT:	Dc.b	'   0',0
SEvn_AnimYNT:	Dc.b	'   0',0
SEvn_AnimDelNT:	Dc.b	' 0',0
		Even
*---------------
SEvn_UpdAnNmD:	Lea	GSEvn_AnimName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Scrn_Event
		Beq.b	SEUAn_E
		Move	14(a3),d0	;Unit
		Bmi.b	SEUAn_E
		Ext.l	d0
		Move.l	Mem_AnimList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	SEUAn_E:Rts
*---------------
SEvn_UpdAnNmG:	Lea	SEvnLay,a5	;###
		Lea	GSEvn_AnimName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_Anim:	Lea	AnimLay,a5	;###
		Jmp	Open_Layer
*---------------
SEvn_UseAnim:	Bsr.b	SEvn_UseAnim_Com
		Bra.w	Upd_ScrnEventsG
SEvn_UseAnim_Com:
		Bsr.w	Get_Scrn_Event
		Beq.b	SUAn_E
		Or	#2,4(a2)	;Set NeedsUpdate
	*-- Store new Unit info
		Move	AnimList_Len,d0	;###
		Beq.b	SUAn_E
		Jsr	Get_Anim_LAdr	;###
		Tst.l	(a2)
		Beq.b	SUAn_E
		Move	Cur_Anim,14(a3)	;Write Unit number	###
		Move.l	(a2),a2		;Copy Anim Delay
		Clr	d0		;+
		Move.b	7(a2),d0	;+
		Move	d0,20(a3)	;+
		Move.b	8(a2),22(a3)	;Copy Anim Control
		Move.b	9(a2),23(a3)	;Copy Anim Direction
		Bsr.w	SEvn_UpdAnNmD
		Bsr.b	SEvn_UpdAnNmG
		Bsr.w	Draw_Screen
	SUAn_E:	Rts
*---------------
SEvn_RemAnim:	Bsr.w	Get_Scrn_Event
		Beq.b	SERAn_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Unit'	###
		Bsr.w	SEvn_UpdAnNmD
		Bsr.w	SEvn_UpdAnNmG
		Bsr.w	Draw_Screen
		Bsr.w	Upd_ScrnEventsG
	SERAn_E:Rts
*---------------
SEvn_AnimName:	Bsr.w	Get_Scrn_Event
		Beq.b	SAnN_Ed
		Move	14(a3),d0	;Unit
		Bmi.b	SAnN_Ed
		Move	d0,Cur_Anim
		Lea	AnimLay,a5	;###
		Tst.l	(a5)
		Beq.b	SAnN_Op
		Jsr	Change_Anim	;###
		Lea	AnimLay,a5	;###
	SAnN_Op:Jmp	Open_Layer
	SAnN_Ed:Rts
*---------------
SEvn_AnimPosX:	Move	#16,d5
		Bra.b	SEAP_Cm
SEvn_AnimPosY:	Move	#18,d5
	SEAP_Cm:Bsr.w	Get_Scrn_Event
		Beq.b	SEAP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,0(a3,d5.w)
		Bsr.b	Upd_SEvn_AnimPosD
		Bsr.b	Upd_SEvn_AnimPosG
		Bsr.w	Draw_Screen
	SEAP_Ed:Rts
*---------------
Upd_SEvn_AnimPosD:
		Bsr.w	Get_Scrn_Event
		Beq.b	USAP_Ed
	*-- Convert numbers
		Move	16(a3),d0
		Lea	SEvn_AnimXNT+4(pc),a0
		Move	#$8103,d7
		Jsr	Conv	;###
		Move	18(a3),d0
		Lea	SEvn_AnimYNT+4(pc),a0
		Move	#$8103,d7
		Jsr	Conv	;###
	USAP_Ed:Rts
*---------------
Upd_SEvn_AnimPosG:
		Lea	SEvnLay,a5	;###
		Lea	GSEvn_AnimX(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		Lea	GSEvn_AnimY(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_AnimDel:	Bsr.w	Get_Scrn_Event
		Beq.b	SEAD_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,20(a3)
		Bsr.b	Upd_SEvn_ADelD
		Bsr.b	Upd_SEvn_ADelG
	SEAD_E:	Rts
*---------------
Upd_SEvn_ADelD:	Bsr.w	Get_Scrn_Event
		Beq.b	USEAD_E
		Cmp	#4,2(a3)	;Type=Anim?
		Bne.b	USEAD_E
		Move	20(a3),d0
		Lea	SEvn_AnimDelNT+2(pc),a0
		Move	#$0101,d7
		Jsr	Conv		;###
	USEAD_E:Rts
*---------------
Upd_SEvn_ADelG:	Lea	SEvnLay,a5	;###
		Lea	GSEvn_AnimDel(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Upd_SEvn_AButD:	Bsr.w	Get_Scrn_Event
		Beq.b	USEAB_E

		Lea	GSEvn_AnimDir(pc),a0
		Lea	ADI_Lst,a2	;###
		Move.b	23(a3),d0
		Ext.w	d0
		Add	d0,d0
		Move	0(a2,d0.w),d1
		Move	d1,10+8(a0)

		Lea	GSEvn_AnimCon(pc),a0
		Lea	ACO_Lst,a2	;###
		Move.b	22(a3),d0
		Ext.w	d0
		Add	d0,d0
		Move	0(a2,d0.w),d1
		Move	d1,10+8(a0)
	USEAB_E:Rts
*---------------
SEvn_AnimCon:	Bsr.w	Get_Scrn_Event
		Beq.b	SEAC_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	22(a3),a2
		Lea	GSEvn_AnimCon(pc),a0
		Lea	ACO_Lst,a1	;###
		Jsr	Gd_Choice	;###
	SEAC_Ed:Rts
*---------------
SEvn_AnimDir:	Bsr.w	Get_Scrn_Event
		Beq.b	SEAD_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Lea	23(a3),a2
		Lea	GSEvn_AnimDir(pc),a0
		Lea	ADI_Lst,a1	;###
		Jsr	Gd_Choice	;###
	SEAD_Ed:Rts
*---------------
SEvn_MoveDL:	Dc	'TX',003,082,-01,8
		Dc.l	SEvn_Move8T

		;Dc	'RO'
		;Dc.l	SEvn_UpdMvNmD
		
		Dc	'GD'
		Dc.l	$020100b9,0,0	;SEvn_Move
		Dc	'BX',003,083,015,095
		Dc	'IM',005,085,9,Im_Path-Im

		Dc	'GD'
		Dc.l	$020100b3,0,0	;SEvn_UseMove
		Dc	'BX',016,083,028,095
		Dc	'IM',018,087,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$020100c2,0,0	;SEvn_MoveName
		Dc	'BX',029,083,-17,095
		Dc	'TX',032,092,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$020100bd,0,0	;SEvn_RemMove
		Dc	'BX',-16,083,-04,095
		Dc	'IM',-14,085,9,Im_ClrClips-Im


		Dc	'BX',003,096,-04,108


		Dc	'BX',003,110,-04,122
		Dc	'TX',006,119,-01,5
		Dc.l	PositionT
		;Dc	'RO'
		;Dc.l	Upd_SEvn_MovePosD

		Dc	'TX',-110,119,-01,5
		Dc.l	XT
GSEvn_MoveX:	Dc	'GD'
		Dc.l	$02030a00,4,0	;SEvn_MovePosX
		Dc	'RC',-103,112,-79,120
		Dc	'TX',-100,119,-01,5
		Dc.l	SEvn_MoveXNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-77,112,-69,120
		Dc	'IM',-75,116,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-68,112,-60,120
		Dc	'IM',-66,114,5,Im_Plus-Im

		Dc	'TX',-57,119,-01,5
		Dc.l	YT
GSEvn_MoveY:	Dc	'GD'
		Dc.l	$02030a00,4,0	;SEvn_MovePosY
		Dc	'RC',-50,112,-26,120
		Dc	'TX',-47,119,-01,5
		Dc.l	SEvn_MoveYNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-24,112,-16,120
		Dc	'IM',-22,116,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-15,112,-07,120
		Dc	'IM',-13,114,5,Im_Plus-Im

		Dc	'JP'
		Dc.l	SEvn_EventsDL

SEvn_Move8T:	Dc.b	'Movement:',0
SEvn_MoveXNT:	Dc.b	'   0',0
SEvn_MoveYNT:	Dc.b	'   0',0
		Even
*---------------
SEvn_TextDL:	Dc	'TX',003,082,-01,8
		Dc.l	SEvn_Text8T

		Dc	'RO'
		Dc.l	SEvn_UpdFoNmD
		
		Dc	'GD'
		Dc.l	$02010059,0,SEvn_Font
		Dc	'BX',003,083,015,095
		Dc	'IM',005,085,9,Im_Font-Im

		Dc	'GD'
		Dc.l	$020100b8,0,SEvn_UseFont
		Dc	'BX',016,083,028,095
		Dc	'IM',018,087,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$020100c3,0,SEvn_FontName
GSEvn_FontName:	Dc	'BX',029,083,-17,095
		Dc	'TX',032,092,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$020100bc,0,SEvn_RemFont
		Dc	'BX',-16,083,-04,095
		Dc	'IM',-14,085,9,Im_ClrClips-Im

		Dc	'BX',003,097,-04,109
		Dc	'TX',006,106,-01,5
		Dc.l	PositionT
		Dc	'RO'
		Dc.l	Upd_SEvn_TextPosD

		Dc	'TX',-110,106,-01,5
		Dc.l	XT
GSEvn_TextX:	Dc	'GD'
		Dc.l	$02030a00,4,SEvn_TextPosX
		Dc	'RC',-103,099,-79,107
		Dc	'TX',-100,106,-01,5
		Dc.l	SEvn_TextXNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-77,099,-69,107
		Dc	'IM',-75,103,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-68,099,-60,107
		Dc	'IM',-66,101,5,Im_Plus-Im

		Dc	'TX',-57,106,-01,5
		Dc.l	YT
GSEvn_TextY:	Dc	'GD'
		Dc.l	$02030a00,4,SEvn_TextPosY
		Dc	'RC',-50,099,-26,107
		Dc	'TX',-47,106,-01,5
		Dc.l	SEvn_TextYNT
		Dc	'GD'
		Dc.l	$02010052,SEvn_Pos_P,PlusMinus
		Dc	'BX',-24,099,-16,107
		Dc	'IM',-22,103,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,SEvn_Pos_P,PlusMinus
		Dc	'BX',-15,099,-07,107
		Dc	'IM',-13,101,5,Im_Plus-Im

		Dc	'JP'
		Dc.l	SEvn_EventsDL

SEvn_Text8T:	Dc.b	'Text:',0
SEvn_TextXNT:	Dc.b	'   0',0
SEvn_TextYNT:	Dc.b	'   0',0
		Even
*---------------
SEvn_UpdFoNmD:	Lea	GSEvn_FontName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Scrn_Event
		Beq.b	SEUF_Ed
		Move	14(a3),d0	;Unit
		Bmi.b	SEUF_Ed
		Ext.l	d0
		Move.l	Mem_FontList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	SEUF_Ed:Rts
*---------------
SEvn_UpdFoNmG:	Lea	SEvnLay,a5	;###
		Lea	GSEvn_FontName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_Font:	Lea	FontLay,a5	;###
		Jmp	Open_Layer
*---------------
SEvn_UseFont:	Bsr.b	SEvn_UseFont_Com
		Bra.w	Upd_ScrnEventsG
SEvn_UseFont_Com:
		Bsr.w	Get_Scrn_Event
		Beq.b	SUFo_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Unit info
		Move	FontList_Len,d0		;###
		Beq.b	SUFo_E
		Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	SUFo_E
		Move	Cur_Font,14(a3)		;Write Unit number	###
		Bsr.b	SEvn_UpdFoNmD
		Bsr.b	SEvn_UpdFoNmG
		Bsr.w	Draw_Screen
	SUFo_E:	Rts
*---------------
SEvn_RemFont:	Bsr.w	Get_Scrn_Event
		Beq.b	SERFo_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Unit'	###
		Bsr.w	SEvn_UpdFoNmD
		Bsr.b	SEvn_UpdFoNmG
		Bsr.w	Draw_Screen
		Bsr.w	Upd_ScrnEventsG
	SERFo_E:Rts
*---------------
SEvn_FontName:	Bsr.w	Get_Scrn_Event
		Beq.b	SFoN_Ed
		Move	14(a3),d0	;Unit
		Bmi.b	SFoN_Ed
		Move	d0,Cur_Font
		Lea	FontLay,a5	;###
		Tst.l	(a5)
		Beq.b	SFoN_Op
		Bsr.w	Change_Font
		Lea	FontLay,a5	;###
	SFoN_Op:Jmp	Open_Layer
	SFoN_Ed:Rts
*---------------
SEvn_TextPosX:	Move	#16,d5
		Bra.b	SETP_Cm
SEvn_TextPosY:	Move	#18,d5
	SETP_Cm:Bsr.w	Get_Scrn_Event
		Beq.b	SETP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,0(a3,d5.w)
		Bsr.b	Upd_SEvn_TextPosD
		Bsr.b	Upd_SEvn_TextPosG
		Bsr.w	Draw_Screen
	SETP_Ed:Rts
*---------------
Upd_SEvn_TextPosD:
		Bsr.w	Get_Scrn_Event
		Beq.b	USTP_Ed
	*-- Convert numbers
		Move	16(a3),d0
		Lea	SEvn_TextXNT+4(pc),a0
		Move	#$8103,d7
		Jsr	Conv	;###
		Move	18(a3),d0
		Lea	SEvn_TextYNT+4(pc),a0
		Move	#$8103,d7
		Jsr	Conv	;###
	USTP_Ed:Rts
*---------------
Upd_SEvn_TextPosG:
		Lea	SEvnLay,a5	;###
		Lea	GSEvn_TextX(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		Lea	GSEvn_TextY(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_SondDL:	Dc	'TX',003,082,-01,8
		Dc.l	SEvn_Sound8T
		Dc	'RO'
		Dc.l	SEvn_UpdSdNmD
		
		Dc	'GD'
		Dc.l	$0201008c,0,SEvn_Sond
		Dc	'BX',003,083,015,095
		Dc	'IM',005,085,9,Im_Sound-Im

		Dc	'GD'
		Dc.l	$0201008d,0,SEvn_UseSond
		Dc	'BX',016,083,028,095
		Dc	'IM',018,087,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$0201008e,0,SEvn_SondName
GSEvn_SondName:	Dc	'BX',029,083,-17,095
		Dc	'TX',032,092,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$02010094,0,SEvn_RemSond
		Dc	'BX',-16,083,-04,095
		Dc	'IM',-14,085,9,Im_ClrClips-Im

		Dc	'JP'
		Dc.l	SEvn_EventsDL

SEvn_Sound8T:	Dc.b	'Sound:',0
		Even
*---------------
SEvn_UpdSdNmD:	Lea	GSEvn_SondName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Scrn_Event
		Beq.b	SEUSd_E
		Move	14(a3),d0	;Unit
		Bmi.b	SEUSd_E
		Ext.l	d0
		Move.l	Mem_SondList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	SEUSd_E:Rts
*---------------
SEvn_UpdSdNmG:	Lea	SEvnLay,a5	;###
		Lea	GSEvn_SondName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_Sond:	Lea	SondLay,a5	;###
		Jmp	Open_Layer
*---------------
SEvn_UseSond:	Bsr.b	SEvn_UseSond_Com
		Bra.w	Upd_ScrnEventsG
SEvn_UseSond_Com:
		Bsr.w	Get_Scrn_Event
		Beq.b	SUSd_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Unit info
		Move	SondList_Len,d0		;###
		Beq.b	SUSd_E
		Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	SUSd_E
		Move	Cur_Sond,14(a3)		;Write Unit number	###
		Bsr.b	SEvn_UpdSdNmD
		Bsr.b	SEvn_UpdSdNmG
		Bsr.w	Draw_Screen
	SUSd_E:	Rts
*---------------
SEvn_RemSond:	Bsr.w	Get_Scrn_Event
		Beq.b	SERSd_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Unit'	###
		Bsr.w	SEvn_UpdSdNmD
		Bsr.b	SEvn_UpdSdNmG
		Bsr.w	Draw_Screen
		Bsr.w	Upd_ScrnEventsG
	SERSd_E:Rts
*---------------
SEvn_SondName:	Bsr.w	Get_Scrn_Event
		Beq.b	SSdN_Ed
		Move	14(a3),d0	;Unit
		Bmi.b	SSdN_Ed
		Move	d0,Cur_Sond
		Lea	SondLay,a5	;###
		Tst.l	(a5)
		Beq.b	SSdN_Op
		Bsr.w	Change_Sond
		Lea	SondLay,a5	;###
	SSdN_Op:Jmp	Open_Layer
	SSdN_Ed:Rts
*---------------
SEvn_SongDL:	Dc	'TX',003,082,-01,8
		Dc.l	SEvn_Song8T

		Dc	'RO'
		Dc.l	SEvn_UpdSgNmD
		
		Dc	'GD'
		Dc.l	$020100b4,0,SEvn_Song
		Dc	'BX',003,083,015,095
		Dc	'IM',005,085,9,Im_Song-Im

		Dc	'GD'
		Dc.l	$020100b5,0,SEvn_UseSong
		Dc	'BX',016,083,028,095
		Dc	'IM',018,087,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$020100b6,0,SEvn_SongName
GSEvn_SongName:	Dc	'BX',029,083,-17,095
		Dc	'TX',032,092,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$020100b7,0,SEvn_RemSong
		Dc	'BX',-16,083,-04,095
		Dc	'IM',-14,085,9,Im_ClrClips-Im

		Dc	'JP'
		Dc.l	SEvn_EventsDL

SEvn_Song8T:	Dc.b	'Song:',0
		Even
*---------------
SEvn_UpdSgNmD:	Lea	GSEvn_SongName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Scrn_Event
		Beq.b	SEUSg_E
		Move	14(a3),d0	;Unit
		Bmi.b	SEUSg_E
		Ext.l	d0
		Move.l	Mem_SongList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	SEUSg_E:Rts
*---------------
SEvn_UpdSgNmG:	Lea	SEvnLay,a5	;###
		Lea	GSEvn_SongName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
SEvn_Song:	Lea	SongLay,a5	;###
		Jmp	Open_Layer
*---------------
SEvn_UseSong:	Bsr.b	SEvn_UseSong_Com
		Bra.w	Upd_ScrnEventsG
SEvn_UseSong_Com:
		Bsr.w	Get_Scrn_Event
		Beq.b	SUSg_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Unit info
		Move	SongList_Len,d0		;###
		Beq.b	SUSg_E
		Bsr.w	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	SUSg_E
		Move	Cur_Song,14(a3)		;Write Unit number	###
		Bsr.b	SEvn_UpdSgNmD
		Bsr.b	SEvn_UpdSgNmG
		Bsr.w	Draw_Screen
	SUSg_E:	Rts
*---------------
SEvn_RemSong:	Bsr.w	Get_Scrn_Event
		Beq.b	SERSg_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Unit'	###
		Bsr.w	SEvn_UpdSgNmD
		Bsr.b	SEvn_UpdSgNmG
		Bsr.w	Draw_Screen
		Bsr.w	Upd_ScrnEventsG
	SERSg_E:Rts
*---------------
SEvn_SongName:	Bsr.w	Get_Scrn_Event
		Beq.b	SSgN_Ed
		Move	14(a3),d0	;Unit
		Bmi.b	SSgN_Ed
		Move	d0,Cur_Song
		Lea	SongLay,a5	;###
		Tst.l	(a5)
		Beq.b	SSgN_Op
		Bsr.w	Change_Song
		Lea	SongLay,a5	;###
	SSgN_Op:Jmp	Open_Layer
	SSgN_Ed:Rts
*---------------
SEvn_EventsDL:	Dc	'GD'
		Dc.l	$02020000,SEvn_Prop_Event,SEvn_Browse
		Dc	'BX',-09,142,-01,-10
		Dc	'BX',-07,145,-03,-12

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

SEvn_Events:	Dc	'BX',000,142,-10,-01

		Dc	'RO'
		Dc.l	Upd_ScrnEventsD

		Dc	'XX'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,146,011,154
		Dc	'IM',005,148,5,Im_Check5-Im
		Dc	'TX',014,153,-46,5
		Dc.l	0
GSEvn_Event1:	Dc	'GD'
		Dc.l	$02010651,SEvn_Excl_Event,SEvn_Select1
		Dc	'BX',-25,144,-13,156
		Dc	'IM',-23,146,9,Im_Background-Im

		Dc	'GD'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,159,011,167
		Dc	'IM',005,161,5,Im_Check5-Im
		Dc	'TX',014,166,-46,5
		Dc.l	0
GSEvn_Event2:	Dc	'GD'
		Dc.l	$02010651,SEvn_Excl_Event,SEvn_Select2
		Dc	'BX',-25,157,-13,169
		Dc	'IM',-23,159,9,Im_Scroll-Im

		Dc	'GD'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,172,011,180
		Dc	'IM',005,174,5,Im_Check5-Im
		Dc	'TX',014,179,-46,5
		Dc.l	0
GSEvn_Event3:	Dc	'GD'
		Dc.l	$02010651,SEvn_Excl_Event,SEvn_Select3
		Dc	'BX',-25,170,-13,182
		Dc	'IM',-23,172,9,Im_Release-Im

		Dc	'GD'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,185,011,193
		Dc	'IM',005,187,5,Im_Check5-Im
		Dc	'TX',014,192,-46,5
		Dc.l	0
GSEvn_Event4:	Dc	'GD'
		Dc.l	$02010651,SEvn_Excl_Event,SEvn_Select4
		Dc	'BX',-25,183,-13,195
		Dc	'IM',-23,185,9,Im_Sound-Im

		Dc	'XX'

SEvn_Prop_Event:Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,32767		;KnobX,Y
		Dc	0,0		;PosX,Y
SEvn_Excl_Event:Dc.l	GSEvn_Event1
		Dc.l	GSEvn_Event2
		Dc.l	GSEvn_Event3
		Dc.l	GSEvn_Event4
		Dc.l	0
*---------------
DrawList_SMod:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	ScreenModes8T
		Dc	'TX',116,009,-01,5
		Dc.l	DashT
		Dc	'TX',125,009,-140,5
GSMod_ScrnName:	Dc.l	0

		Dc	'BX',000,011,-01,-01
		Dc	'XX'
ScreenModes8T:	Dc.b	'Screen Modes',0
		Even
*=======================================================================*
*			      P A L E T T E				*
*=======================================================================*
Game_Palette:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.w	GP_End
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.w	GP_End
		Move.l	(a2),a2
		Lea	$dff180,a5

		Move	8(a2),d7	;Total
		Subq	#1,d7

		Move.l	a2,a3		;A3 points to offsets
		Add	#10,a3		;+

		Btst	#0,Prf_GfxFlags
		Beq.w	GP_NAa
		Move	AGA,d5		;###
		Beq.b	GP_NAa
	*-- AGA
		Clr	d5
	GP_ALp:	Move	(a3)+,d0	;A1 points to Color
		Lea	0(a2,d0.w),a1	;+

		Move	d5,d6
		Lsl	#8,d6
		And	#$e000,d6
		
		Move.l	a5,d0
		Bclr	#6,d0
		Move.l	d0,a5
	*-- Hi bits
		Bclr	#9,d6
		Move	d6,$dff106

		Move.b	6(a1),d1	;Grn
		And	#$00f0,d1

		Clr	d0
		Move.b	7(a1),d0	;Blu
		Lsr	#4,d0
		Or	d0,d1
		
		Move.b	5(a1),d0	;Red
		Lsl	#4,d0
		And	#$0f00,d0
		Or	d0,d1
		Move	d1,(a5)
	*-- Lo bits
		Bset	#9,d6
		Move	d6,$dff106

		Move.b	6(a1),d1	;Grn
		And	#$000f,d1
		Lsl	#4,d1

		Move.b	7(a1),d0	;Blu
		And	#$000f,d0
		Or	d0,d1
		
		Move.b	5(a1),d0	;Red
		And	#$000f,d0
		Lsl	#8,d0
		Or	d0,d1
		Move	d1,(a5)+

		Addq	#1,d5
		Dbf	d7,GP_ALp

		Clr	$dff106

		Bra.b	GP_End

	*--Non-AGA
	GP_NAa:
	GP_Lp:	Move	(a3)+,d0	;A1 points to Color
		Lea	0(a2,d0.w),a1	;+

		Move.b	6(a1),d1	;Grn
		And	#$00f0,d1

		Clr	d0
		Move.b	7(a1),d0	;Blu
		Lsr	#4,d0
		Or	d0,d1
		
		Move.b	5(a1),d0	;Red
		Lsl	#4,d0
		And	#$0f00,d0
		Or	d0,d1
		Move	d1,(a5)+
		
		Dbf	d7,GP_Lp
	GP_End:	Rts
*---------------
Upd_Palt_Screen:Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	UPS_E
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	UPS_E
		Move.l	(a2),a2
		Move.l	Mem_Palette,a5	;###
		Move.l	a2,a3		;A3 points to offsets
		Add	#10,a3		;+
		Move	8(a2),d7	;Number of colors
		Subq	#1,d7		;+ (-1 for Dbf)
	UPS_Lp:	Move	(a3)+,d0	;A1 points to Color
		Lea	0(a2,d0.w),a1	;+
		Move.l	4(a1),(a5)+
		Dbf	d7,UPS_Lp
		Jsr	ReDraw_All	;###
	UPS_E:	Rts
*---------------
Palt_New:
	*-- Get list space.
		Lea	PaltList,a4	;###
		Jsr	Find_Unit_Space	;This routine saves regs. ###
		Move.l	a0,PlN_LstA
		Bne.b	PN_NEr1
		Jmp	Mess_MemErr	;###
	PN_NEr1:	
	*-- Allocate memory.
		Move	#1,d0
		Move	Screen_Depth,d1	;###
		Lsl	d1,d0
		Move	d0,PlN_Total
		Mulu	#10,d0
		Add.l	#10,d0
		Move.l	d0,PlN_Size
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Tst.l	d0
		Bne.b	PN_NEr2
		Jmp	Mess_MemErr	;###
	PN_NEr2:Move	d7,Cur_Palt
	*-- Write to list.
		Move.l	PlN_LstA(pc),a5
		Move.l	d0,(a5)
		Move	#%111,4(a5)		;Set Flags = New
		Move.l	a5,a0
		Jsr	Unnamed		;###
	*-- Store new Unit.
		Move.l	PlN_LstA(pc),a0
		Move.l	(a0),a1			;Get Palette Address
		Clr	(a1)+			;Write Id
		Move.l	PlN_Size(pc),(a1)+	;Write BytSize
		Clr	(a1)+			;Flags
		Move	PlN_Total(pc),(a1)+	;Total
	*-- Write offsets.
		Move	PlN_Total(pc),d0
		Move	d0,d1
		Add	d1,d1		;Multiply by 2
		Add	#10,d1
	PlN_OfL:Move	d1,(a1)+
		Addq	#8,d1
		Subq	#1,d0
		Bne.b	PlN_OfL
	*-- Write colors.
		Move.l	Mem_Palette,a0	;###
		Move	PlN_Total(pc),d7
	PlN_CoL:Clr	(a1)+
		Move	#8,(a1)+
		Move.l	(a0)+,(a1)+
		Subq	#1,d7
		Bne.b	PlN_CoL
		Bra.w	Change_Palt
PlN_LstA:	Dc.l	0
PlN_Size:	Dc.l	0
PlN_Total:	Dc	0
*---------------
Get_Palt_LAdr:	Move.l	Mem_PaltList,a2	;###
		Clr.l	d0
		Move	Cur_Palt,d0	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Palt_Undo:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PU_E
		Bsr.b	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PU_E

		Lea	Palt_Info,a3	;###
		Jsr	Unit_Undo	;###

		Bsr.w	Upd_Palette
		Bsr.w	Upd_PaltSelect
		Bsr.w	Upd_Palt_ColD
		Bsr.w	Upd_Palt_ColG
		Bsr.w	Upd_Palt_TotD
		Bsr.w	Upd_Palt_TotG
		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_RGB_PropG
		Bsr.w	Palt_Set_Color
		Bsr.b	Update_PaltBuf
	PU_E:	Rts
*---------------
Update_PaltBuf:	Lea	Palt_Info,a3	;###
		Jmp	Update_UnitBuf	;###
*---------------
Palt_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Upd_PaltNameD:	Lea	Palt_Info,a3	;###
		Lea	Palt_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_PaltNameG:	Lea	PaltLay,a5	;###
		Lea	Palt_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Change_Palt:	Bsr.b	Upd_PaltNameD
		Bsr.b	Upd_PaltNameG
		Lea	Palt_Info,a3	;###
		Jsr	Upd_SelcUnit	;###
		Bsr.w	Upd_PaletteBoxD
		Clr	Palt_CurColor
		Bsr.w	Upd_Palt_ColD
		Bsr.w	Upd_Palt_TotD
		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_Palt_Screen

		Lea	PaltLay,a5
		Lea	GPalt_UpdAll(pc),a4
		Jsr	Draw_All	;###
		
		Bra.b	Update_PaltBuf
*---------------
Palt_PrvColor:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PPC_End
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PPC_End
		Move.l	(a2),a2

		Subq	#1,Palt_CurColor
		Bpl.b	PPC_Ok
		Clr	Palt_CurColor
	PPC_Ok:	Bsr.w	Upd_PaltSelect
		Bsr.w	Upd_Palt_ColD
		Bsr.w	Upd_Palt_ColG
		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_RGB_PropG
		Bsr.w	Update_PaltBuf
	PPC_End:Rts
*---------------
Palt_NxtColor:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PNC_End
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PNC_End
		Move.l	(a2),a2

		Addq	#1,Palt_CurColor
		Move	8(a2),d0
		Cmp	Palt_CurColor(pc),d0
		Bne.b	PNC_Ok
		Move	d0,Palt_CurColor
		Subq	#1,Palt_CurColor
	PNC_Ok:	Bsr.w	Upd_PaltSelect
		Bsr.w	Upd_Palt_ColD
		Bsr.w	Upd_Palt_ColG
		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_RGB_PropG
		Bsr.w	Update_PaltBuf
	PNC_End:Rts
*---------------
Palt_Color:	Move	PaltList_Len,d0	;###
		Beq.b	PC_E
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PC_E
		Move.l	(a2),a1
		Move.l	Convert_Value,d0	;###
		Subq	#1,d0
		Cmp	8(a1),d0
		Bhs.b	PC_Bad		;Is it too high or negative?
		Move	d0,Palt_CurColor
	PC_Bad:	Bsr.b	Upd_Palt_ColD
		Bsr.b	Upd_Palt_ColG
		Bsr.b	Upd_PaltSelect
		Bsr.w	Update_PaltBuf
	PC_E:	Rts
*---------------
Upd_Palt_TotD:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	UPT_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	UPT_Ed
		Move.l	(a2),a2

		Move	8(a2),d0
		Lea	Palt_TotalNT+3(pc),a0
		Move	#$8102,d7
		Jsr	Conv		;###
	UPT_Ed:	Rts
*---------------
Upd_Palt_TotG:	Lea	PaltLay,a5	;###
		Lea	GPalt_Total(pc),a4
		Moveq.l	#1,d7
		Jmp	Draw_Some	;###
*---------------
Upd_Palt_ColD:	Move	Palt_CurColor(pc),d0
		Addq	#1,d0
		Lea	Palt_ColorNT+3(pc),a0
		Move	#$8102,d7
		Jmp	Conv	;###
*---------------
Upd_Palt_ColG:	Lea	PaltLay,a5	;###
		Lea	GPalt_Color(pc),a4
		Moveq.l	#1,d7
		Jmp	Draw_Some	;###
*---------------
Palt_PickColor:	Lea	Sprite_Cross,a1	;###
		Jsr	Change_Sprite	;###
		Jsr	Check_Left_Dn	;###
		Beq.b	Palt_PickColor
		Bra.b	Palt_SelectColor
*---------------
Upd_PaltSelect:	Lea	PaltLay,a5	;###
		Move.l	(a5),d0
		Beq.b	UPS_End

		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	GfxBase,a6	;###
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	Palt_CurColor(pc),d0
		Jsr	SetAPen(a6)

		Lea	GPalt_Select(pc),a4
		Lea	PaltLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	a3,a1

		Move	X1,d0	;###
		Move	Y1,d1	;###
		Move	X2,d2	;###
		Move	Y2,d3	;###
		Addq	#3,d0
		Addq	#3,d1
		Subq	#3,d2
		Subq	#3,d3
		Jsr	RectFill(a6)
	UPS_End:Rts
*---------------
Palt_SelectColor:
		Move.l	GfxBase,a6	;###
		Move.l	Screen_Struct,a0	;###
		Move.l	a0,a1
		Add	#84,a1
		Move	18(a0),d0	;Get ScreenX
		Move	16(a0),d1	;Get ScreenY
		Jsr	ReadPixel(a6)
		Move	d0,Palt_CurColor
		Bsr.w	Upd_PaltSelect
		Bsr.w	Upd_Palt_ColD
		Bsr.w	Upd_Palt_ColG
		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_RGB_PropG
		Jsr	Check_Left_Up	;###
		Beq.b	Palt_SelectColor
		Bra.w	Update_PaltBuf
Palt_CurColor:	Dc	0
*---------------
Upd_PaletteBoxD:Lea	GPalt_Palt(pc),a4
		Move	#'BX',(a4)
		
		Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	UPB_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	UPB_Ed
		Move.l	(a2),a2

		Move	#'FR',(a4)
	UPB_Ed:	Rts
*---------------
Upd_PaletteBoxG:Lea	PaltLay,a5	;###
		Lea	GPalt_Palt(pc),a4
		Moveq.l	#1,d7
		Jmp	Draw_Some	;###
*---------------
Upd_Palette:	Lea	GPalt_Palt(pc),a4
		Lea	PaltLay,a5	;###

		Move.l	(a5),d0
		Beq.w	UPa_End

		Jsr	Calc_Coord	;###

		Move	PaltList_Len,d0	;No Palettes?	###
		Beq.w	UPa_End
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.w	UPa_End
		Move.l	(a2),a2

		Move	8(a2),d0	;Get Total

		Move	#1,d6
		Move	#1,d7
		Cmp	#2,d0
		Blt.b	UPa_Rdy
		Add	d6,d6
		Cmp	#4,d0
		Blt.b	UPa_Rdy
		Add	d6,d6
		Cmp	#8,d0
		Blt.b	UPa_Rdy
		Add	d7,d7
		Cmp	#16,d0
		Blt.b	UPa_Rdy
		Add	d6,d6
		Cmp	#32,d0
		Blt.b	UPa_Rdy
		Add	d7,d7
		Cmp	#64,d0
		Blt.b	UPa_Rdy
		Add	d6,d6
		Cmp	#128,d0
		Blt.b	UPa_Rdy
		Add	d7,d7
		Cmp	#256,d0
		Blt.b	UPa_Rdy
		Add	d6,d6

	UPa_Rdy:Clr.l	d3
		Clr.l	d4
		Move	X2,d3	;###
		Sub	X1,d3	;###
		Subq	#5,d3
		Move	Y2,d4	;###
		Sub	Y1,d4	;###
		Subq	#5,d4

		Lsl.l	#7,d3
		Lsl.l	#7,d4
		Divu	d6,d3
		Divu	d7,d4
		And.l	#$0000ffff,d3
		And.l	#$0000ffff,d4
		Lsl.l	#8,d3
		Lsl.l	#8,d4
		Add.l	d3,d3	;Multiply by 2
		Add.l	d4,d4	;Multiply by 2
		Move.l	d3,UPa_XSz
		Move.l	d4,UPa_YSz

		Lea	PaltLay,a5	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	GfxBase,a6	;###
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)

		Clr	UPa_XCn

		Clr.l	UPa_X
		Move	X1,d0	;###
		Addq	#3,d0
		Move	d0,UPa_X

		Clr.l	UPa_Y
		Move	Y1,d0	;###
		Addq	#3,d0
		Move	d0,UPa_Y
		
		Clr	d5		;Color

	UPa_Lp:	Move.l	a3,a1
		Move	d5,d0
		Jsr	SetAPen(a6)

		Move.l	a3,a1
		Move	UPa_X(pc),d0
		Move	UPa_Y(pc),d1
		Move	d0,d2
		Move	d1,d3
		Add	UPa_XSz(pc),d2
		Add	UPa_YSz(pc),d3

		Move	X2,d7	;###
		Subq	#3,d7
		Cmp	d7,d2
		Ble.b	UPa_OkX
		Subq	#1,d2
	UPa_OkX:
		Move	Y2,d7	;###
		Subq	#3,d7
		Cmp	d7,d3
		Ble.b	UPa_OkY
		Subq	#1,d3
	UPa_OkY:
		Jsr	RectFill(a6)

		Move.l	UPa_XSz(pc),d0
		Add.l	d0,UPa_X
		
		Addq	#1,UPa_XCn
		Cmp	UPa_XCn(pc),d6
		Bne.b	UPa_NLn
		
		Move.l	UPa_YSz(pc),d0
		Add.l	d0,UPa_Y

		Clr	UPa_XCn

		Clr.l	UPa_X
		Move	X1,d0	;###
		Addq	#3,d0
		Move	d0,UPa_X

	UPa_NLn:Addq	#1,d5
		
		Move	8(a2),d0	;Get Total
		Cmp	d0,d5
		Bne.w	UPa_Lp
	UPa_End:Rts
	UPa_XCn:Dc	0
	UPa_X:	Dc.l	0
	UPa_Y:	Dc.l	0
	UPa_XSz:Dc.l	0
	UPa_YSz:Dc.l	0
*---------------
Upd_Palt_RGB_ND:Move	PaltList_Len,d0	;No Palettes?	;###
		Beq.b	UPRN_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	UPRN_Ed
		Move.l	(a2),a2
	*-- Find Color
		Move	Palt_CurColor(pc),d0
		Add	d0,d0
		Move	10(a2,d0.w),d0
		Lea	0(a2,d0.w),a1

		Moveq.l	#$10,d5
		Btst	#0,Prf_GfxFlags
		Beq.b	UPRN_NAa
		Moveq.l	#1,d5
	UPRN_NAa:

		Clr.l	d0
		Move.b	5(a1),d0
		Divu	d5,d0
		Lea	Palt_RedNT+3(pc),a0
		Move	#$8102,d7
		Jsr	Conv	;###

		Clr.l	d0
		Move.b	6(a1),d0
		Divu	d5,d0
		Lea	Palt_GrnNT+3(pc),a0
		Move	#$8102,d7
		Jsr	Conv	;###

		Clr.l	d0
		Move.b	7(a1),d0
		Divu	d5,d0
		Lea	Palt_BluNT+3(pc),a0
		Move	#$8102,d7
		Jsr	Conv	;###
	UPRN_Ed:Rts
*---------------
Upd_Palt_RGB_NG:Lea	PaltLay,a5	;###
		Lea	GPalt_Red(pc),a4
		Moveq.l	#1,d7
		Jsr	Draw_Some	;###
		Lea	GPalt_Grn(pc),a4
		Moveq.l	#1,d7
		Jsr	Draw_Some	;###
		Lea	GPalt_Blu(pc),a4
		Moveq.l	#1,d7
		Jmp	Draw_Some	;###
*---------------
Upd_RGB_PropD:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	URP_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	URP_Ed
		Move.l	(a2),a2
	*-- Find Color
		Move	Palt_CurColor(pc),d0
		Add	d0,d0
		Move	10(a2,d0.w),d0
		Lea	0(a2,d0.w),a1

		Move	#255,d7

		Lea	Palt_Prop_Red(pc),a0
		Clr	d2
		Move.b	5(a1),d2
		Move.l	#$ffff,d0
		Clr.l	d1
		Move	2(a0),d1
		Sub.l	d1,d0
		Mulu	d2,d0
		Divu	d7,d0
		Move	d0,6(a0)

		Lea	Palt_Prop_Grn(pc),a0
		Clr	d2
		Move.b	6(a1),d2
		Move.l	#$ffff,d0
		Clr.l	d1
		Move	2(a0),d1
		Sub.l	d1,d0
		Mulu	d2,d0
		Divu	d7,d0
		Move	d0,6(a0)

		Lea	Palt_Prop_Blu(pc),a0
		Clr	d2
		Move.b	7(a1),d2
		Move.l	#$ffff,d0
		Clr.l	d1
		Move	2(a0),d1
		Sub.l	d1,d0
		Mulu	d2,d0
		Divu	d7,d0
		Move	d0,6(a0)
	URP_Ed:	Rts
*---------------
Upd_RGB_PropG:	Lea	PaltLay,a5	;###
		Lea	GPalt_Red_Prop(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		Lea	GPalt_Grn_Prop(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		Lea	GPalt_Blu_Prop(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Palt_RGB_Prop:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.w	PRP_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PRP_Ed
		Move.l	(a2),a2
	*-- Find Color
		Move	Palt_CurColor(pc),d0
		Add	d0,d0
		Move	10(a2,d0.w),d0
		Lea	0(a2,d0.w),a1

		Move	#256,d7

		Lea	Palt_Prop_Red(pc),a0
		Move.l	#$10000,d0
		Clr.l	d1
		Move	2(a0),d1
		Sub.l	d1,d0
		Move	d7,d1
		Mulu	6(a0),d1
		Divu	d0,d1
		Move.b	d1,5(a1)

		Lea	Palt_Prop_Grn(pc),a0
		Move.l	#$10000,d0
		Clr.l	d1
		Move	2(a0),d1
		Sub.l	d1,d0
		Move	d7,d1
		Mulu	6(a0),d1
		Divu	d0,d1
		Move.b	d1,6(a1)

		Lea	Palt_Prop_Blu(pc),a0
		Move.l	#$10000,d0
		Clr.l	d1
		Move	2(a0),d1
		Sub.l	d1,d0
		Move	d7,d1
		Mulu	6(a0),d1
		Divu	d0,d1
		Move.b	d1,7(a1)

		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Palt_Set_Color
	PRP_Ed:	Rts
*---------------
Palt_Red_N:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PRN_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PRN_Ed
		Move.l	(a2),a2
	*-- Find Color
		Move	Palt_CurColor(pc),d0
		Add	d0,d0
		Move	10(a2,d0.w),d0
		Lea	0(a2,d0.w),a1

		Moveq.l	#$10,d7
		Btst	#0,Prf_GfxFlags
		Beq.b	PRN_NAa
		Move	#1,d7
	PRN_NAa:
		Move.l	Convert_Value,d0	;###
		Mulu	d7,d0
		Bmi.b	PRN_Ov
		Cmp	#255,d0
		Bgt.b	PRN_Ov
		Move.b	d0,5(a1)

	PRN_Ov:	Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_RGB_PropG
		Bsr.w	Palt_Set_Color
	PRN_Ed:	Rts
*---------------
Palt_Grn_N:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PGN_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PGN_Ed
		Move.l	(a2),a2
	*-- Find Color
		Move	Palt_CurColor(pc),d0
		Add	d0,d0
		Move	10(a2,d0.w),d0
		Lea	0(a2,d0.w),a1

		Moveq.l	#$10,d7
		Btst	#0,Prf_GfxFlags
		Beq.b	PGN_NAa
		Move	#1,d7
	PGN_NAa:
		Move.l	Convert_Value,d0	;###
		Mulu	d7,d0
		Bmi.b	PGN_Ov
		Cmp	#255,d0
		Bgt.b	PGN_Ov
		Move.b	d0,6(a1)

	PGN_Ov:	Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_RGB_PropG
		Bsr.b	Palt_Set_Color
	PGN_Ed:	Rts
*---------------
Palt_Blu_N:	Move	PaltList_Len,d0		;No Palettes?	###
		Beq.b	PBN_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PBN_Ed
		Move.l	(a2),a2
	*-- Find Color
		Move	Palt_CurColor(pc),d0
		Add	d0,d0
		Move	10(a2,d0.w),d0
		Lea	0(a2,d0.w),a1

		Moveq.l	#$10,d7
		Btst	#0,Prf_GfxFlags
		Beq.b	PBN_NAa
		Move	#1,d7
	PBN_NAa:
		Move.l	Convert_Value,d0	;###
		Mulu	d7,d0
		Bmi.b	PBN_Ov
		Cmp	#255,d0
		Bgt.b	PBN_Ov
		Move.b	d0,7(a1)

	PBN_Ov:	Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bsr.w	Upd_RGB_PropG
		Bsr.b	Palt_Set_Color
	PBN_Ed:	Rts
*---------------
Palt_Set_Color:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PSC_Ed
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PSC_Ed
		Move.l	(a2),a2
	*-- Find Color
		Move	Palt_CurColor(pc),d0
		Add	d0,d0
		Move	10(a2,d0.w),d0
		Lea	0(a2,d0.w),a1

		Clr.l	d0
		Move	Palt_CurColor(pc),d0
		Clr.l	d1
		Clr.l	d2
		Clr.l	d3
		Move.b	5(a1),d1
		Move.b	6(a1),d2
		Move.b	7(a1),d3
		Move.l	GfxBase,a6	;###
		Move.l	Screen_Struct,a0	;###
		Add.l	#44,a0

		Btst	#0,Prf_GfxFlags
		Beq.b	PSC_NAa
		Move	AGA,d5	;###
		Beq.b	PSC_NAa

		Ror.l	#8,d1
		Ror.l	#8,d2
		Ror.l	#8,d3
		Jmp	SetRGB8(a6)

	PSC_NAa:Lsr	#4,d1
		Lsr	#4,d2
		Lsr	#4,d3
		Jsr	SetRGB4(a6)
	PSC_Ed:	Rts
*---------------
Palt_Total:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PT_E
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PT_E
		Move.l	(a2),a2
	*-- Find nearest power of 2.
		Move.l	Convert_Value,d0	;###
		Clr	d1
		
		Moveq.l	#6,d2
		Btst	#0,Prf_GfxFlags
		Beq.b	PT_NAa
		Moveq.l	#8,d2
	PT_NAa:
	PT_L:	Btst	d2,d0
		Beq.b	PT_Nul
		Bset	d2,d1
		Bra.b	PT_Fin
	PT_Nul:	Dbf	d2,PT_L
		Bra.b	PT_E
	PT_Fin:	Move	d1,Palt_NewSize

		Bsr.w	Palt_AddDel

	PT_E:	Bsr.w	Upd_Palt_TotD
		Bsr.w	Upd_Palt_TotG
		Bra.w	Upd_Palette
*---------------
Palt_AddColors:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PAC_E
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PAC_E
		Move.l	(a2),a2

		Moveq.l	#64,d6
		Btst	#0,Prf_GfxFlags
		Beq.b	PAC_NAa
		Move	#256,d6
	PAC_NAa:

		Move	8(a2),d7
		Cmp	d6,d7
		Beq.b	PAC_E
		Add	d7,d7		;Multiply by 2
		Move	d7,Palt_NewSize

		Bsr.b	Palt_AddDel

		Bsr.w	Upd_Palt_TotD
		Bsr.w	Upd_Palt_TotG
		Bsr.w	Upd_Palette
	PAC_E:	Rts
*---------------
Palt_DelColors:	Move	PaltList_Len,d0	;No Palettes?	###
		Beq.b	PDC_E
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	PDC_E
		Move.l	(a2),a2

		Move	8(a2),d7
		Cmp	#1,d7
		Beq.b	PDC_E
		Lsr	#1,d7
		Move	d7,Palt_NewSize

		Bsr.b	Palt_AddDel
		
		Bsr.w	Upd_Palt_TotD
		Bsr.w	Upd_Palt_TotG
		Bsr.w	Upd_Palette
	PDC_E:	Rts
*---------------
Palt_AddDel:	Move	Palt_NewSize(pc),d0
		Cmp	8(a2),d0
		Bgt.b	Palt_AddTotal
		Blt.w	Palt_DelTotal
		Rts
Palt_NewSize:	Dc	0
*---------------
Palt_AddTotal:	Bsr.w	Update_PaltBuf
		Bsr.w	Get_Palt_LAdr
		Move.l	a2,PAT_LAdr
	*-- Calculate new size
		Move.l	(a2),a2
		Move.l	2(a2),d1		;Get Old Size
		Move	d1,PAT_OldBytSize
		Move	Palt_NewSize(pc),d0	;How many more colors?
		Sub	8(a2),d0		;+
		Move	d0,d2
		Add	d2,d2			;Multiply by 2
		Move	d2,PAT_OffsAdd
		Mulu	#10,d0			;*10=Bytes
		Add	d0,d1			;Calculate New Size
		Move	d1,PAT_BytSize
		Move	8(a2),d0
		Move	d0,PAT_OldTotal
	*-- Free old Palette
		Move.l	PAT_LAdr(pc),a4
		Jsr	Free_Unit	;###
	*-- Allocate new space for Palette
		Move.l	Mem_PaltBuf,a2		;Get buffer address	###
		Clr.l	d0
		Move	PAT_BytSize(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	PAT_LAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	PAT_NEr
		Jmp	Mess_CMemErr		;###
	PAT_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Palette address
		Move.l	Mem_PaltBuf,a2		;Get buffer address	;###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Clr.l	d0			;+
		Move	PAT_BytSize(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,(a1)+		;Flags
		Move	(a2)+,d7		;Total
		Move	Palt_NewSize(pc),(a1)+	;+
	*-- Copy old Offsets
		Move	PAT_OldTotal(pc),d7
	PAT_LOO:Move	(a2)+,d2
		Add	PAT_OffsAdd(pc),d2
		Move	d2,(a1)+
		Subq	#1,d7
		Bne.b	PAT_LOO
	*-- Insert new offsets
		Move	Palt_NewSize(pc),d7
		Sub	PAT_OldTotal(pc),d7
		Move	PAT_OldBytSize(pc),d0
		Add	PAT_OffsAdd,d0
	PAT_LNO:Move	d0,(a1)+
		Addq	#8,d0
		Subq	#1,d7
		Bne.b	PAT_LNO
	*-- Copy old colors
		Move	PAT_OldTotal(pc),d7
	PAT_OC:	Move	(a2)+,(a1)+	;Copy Type
		Move	(a2)+,d0	;Copy Size
		Move	d0,(a1)+	;+
		Subq	#4,d0
	PAT_OCD:Move.b	(a2)+,(a1)+
		Subq	#1,d0
		Bne.b	PAT_OCD
		Subq	#1,d7
		Bne.b	PAT_OC
	*-- Write new colors.
		Move.l	Mem_Palette,a0	;###
		Move	PAT_OldTotal(pc),d0	;Find start color
		Lsl	#2,d0			;+
		Add	d0,a0			;+
		Move	Palt_NewSize(pc),d7
		Sub	PAT_OldTotal(pc),d7
	PAT_NC:	Clr	(a1)+
		Move	#8,(a1)+
		Move.l	(a0)+,(a1)+
		Subq	#1,d7
		Bne.b	PAT_NC

		Clr	Palt_CurColor
		Bsr.w	Upd_PaletteBoxD
		Bsr.w	Upd_PaletteBoxG
		Bsr.w	Upd_Palette
		Bsr.w	Upd_PaltSelect
		Bsr.w	Upd_Palt_ColD
		Bsr.w	Upd_Palt_ColG
		Bsr.w	Upd_Palt_TotD
		Bsr.w	Upd_Palt_TotG
		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bra.w	Upd_RGB_PropG

PAT_LAdr:	Dc.l	0
PAT_BytSize:	Dc	0
PAT_OldTotal:	Dc	0
PAT_OffsAdd:	Dc	0
PAT_OldBytSize:	Dc	0
*---------------
Palt_DelTotal:	Bsr.w	Update_PaltBuf
		Bsr.w	Get_Palt_LAdr
		Move.l	a2,PDT_LAdr
	*-- Calculate new size
		Move.l	(a2),a2
		Move	Palt_NewSize(pc),d0	;Find offset for (LastColor+1)
		Add	d0,d0			;+
		Move	10(a2,d0.w),d3		;+
		Move	8(a2),d0		;How many less colors?
		Sub	Palt_NewSize(pc),d0	;+
		Add	d0,d0			;Calculate OffsetSub
		Move	d0,PDT_OffsSub		;+
		Sub	d0,d3			;Calculate New Size
		Move	d3,PDT_BytSize		;+
		Move	8(a2),d0
		Move	d0,PDT_OldTotal
	*-- Free old Palette
		Move.l	PDT_LAdr(pc),a4
		Jsr	Free_Unit	;###
	*-- Allocate new space for Palette
		Move.l	Mem_PaltBuf,a2		;Get buffer address	###
		Clr.l	d0
		Move	PDT_BytSize(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	PDT_LAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	PDT_NEr
		Jmp	Mess_CMemErr		;###
	PDT_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Palette address
		Move.l	Mem_PaltBuf,a2		;Get buffer address	;###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Clr.l	d0			;+
		Move	PDT_BytSize(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,(a1)+		;Flags
		Move	(a2)+,d7		;Total
		Move	Palt_NewSize(pc),(a1)+	;+
	*-- Copy offsets
		Move	Palt_NewSize(pc),d7
	PDT_LO:	Move	(a2)+,d2
		Sub	PDT_OffsSub(pc),d2
		Move	d2,(a1)+
		Subq	#1,d7
		Bne.b	PDT_LO
	*-- Skip rest of offsets
		Move	PDT_OldTotal(pc),d7
		Sub	Palt_NewSize(pc),d7
		Add	d7,d7	;Multiply by 2
		Add	d7,a2
	*-- Copy colors
		Move	Palt_NewSize(pc),d7
	PDT_OC:	Move	(a2)+,(a1)+	;Copy Type
		Move	(a2)+,d0	;Copy Size
		Move	d0,(a1)+	;+
		Subq	#4,d0
	PDT_OCD:Move.b	(a2)+,(a1)+
		Subq	#1,d0
		Bne.b	PDT_OCD
		Subq	#1,d7
		Bne.b	PDT_OC

		Clr	Palt_CurColor
		Bsr.w	Upd_PaletteBoxD
		Bsr.w	Upd_PaletteBoxG
		Bsr.w	Upd_Palette
		Bsr.w	Upd_PaltSelect
		Bsr.w	Upd_Palt_ColD
		Bsr.w	Upd_Palt_ColG
		Bsr.w	Upd_Palt_TotD
		Bsr.w	Upd_Palt_TotG
		Bsr.w	Upd_Palt_RGB_ND
		Bsr.w	Upd_Palt_RGB_NG
		Bsr.w	Upd_RGB_PropD
		Bra.w	Upd_RGB_PropG

PDT_LAdr:	Dc.l	0
PDT_BytSize:	Dc	0
PDT_OldTotal:	Dc	0
PDT_OffsSub:	Dc	0
*---------------
Check_Palt:	Lea	Palt_Jump(pc),a0
		Move	PaltList_Len,d0	;###
		Beq.b	CPa_NUn
	*-- Find current Palette, and check if it exists
		Move.l	Mem_PaltList,a2	;###
		Move	Cur_Palt,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Palette?
		Beq.b	CPa_No		;No
		Lea	Palt_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CPa_NUn:Lea	Palt_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CPa_No:	Lea	Palt_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
Palt_Load:	Move.l	PaltList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Palt,d4	;###
		Move.l	#'PALT',d0
		Jsr	Load_Unit	;###
		Bra.w	Change_Palt
*---------------
DrawList_Palt:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Palette8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Palt_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Palt_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Palt_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

GPalt_UpdAll:	Dc	'BX',046,013,-04,025

		Dc	'RO'
		Dc.l	Upd_PaltNameD

Palt_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Palt_Name
		Dc	'RC',049,015,-26,023
		Dc	'TX',051,022,-77,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Palt_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Palt_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

		Dc	'RO'
		Dc.l	Check_Palt

		Dc	'JP'
Palt_Jump:	Dc.l	Palt_No

Palt_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Palt_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Palt_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Palt_Yes:	Dc	'BX',000,028,-14,040

		Dc	'TX',003,039,-01,8
		Dc.l	Color8T

		Dc	'RO'
		Dc.l	Upd_Palt_ColD

		Dc	'GD'
		Dc.l	$02030aaf,3,Palt_Color
		Dc	'RC',-107,030,-88,038
GPalt_Color:	Dc	'TX',-104,037,-01,5
		Dc.l	Palt_ColorNT
		Dc	'GD'
		Dc.l	$020100ae,0,Palt_PrvColor
		Dc	'BX',-86,030,-78,038
		Dc	'IM',-84,034,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$020100ad,0,Palt_NxtColor
		Dc	'BX',-77,030,-69,038
		Dc	'IM',-75,032,5,Im_Plus-Im

		Dc	'RO'
		Dc.l	Upd_Palt_TotD

		Dc	'TX',-66,037,-01,5
		Dc.l	OfT
		Dc	'GD'
		Dc.l	$02030aac,3,Palt_Total
		Dc	'RC',-55,030,-36,038
GPalt_Total:	Dc	'TX',-52,037,-01,5
		Dc.l	Palt_TotalNT
		Dc	'GD'
		Dc.l	$020100ab,0,Palt_DelColors
		Dc	'BX',-34,030,-26,038
		Dc	'IM',-32,034,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$020100aa,0,Palt_AddColors
		Dc	'BX',-25,030,-17,038
		Dc	'IM',-23,032,5,Im_Plus-Im
		
		Dc	'GD'
		Dc.l	$0201000b,0,Palt_Undo
		Dc	'BX',-13,028,-01,040
		Dc	'IM',-11,030,9,Im_Undo-Im

		Dc	'BX',000,041,-01,073

		Dc	'RO'
		Dc.l	Upd_Palt_RGB_ND

		Dc	'RO'
		Dc.l	Upd_RGB_PropD

		Dc	'TX',003,052,-01,8
		Dc.l	RT
GPalt_Red_Prop:	Dc	'GD'
		Dc.l	$0202005a,Palt_Prop_Red,Palt_RGB_Prop
		Dc	'BX',011,043,-44,051
		Dc	'BX',013,045,-46,049
		Dc	'GD'
		Dc.l	$02030a5a,3,Palt_Red_N
		Dc	'RC',-42,043,-23,051
GPalt_Red:	Dc	'TX',-39,050,-01,5
		Dc.l	Palt_RedNT
		Dc	'GD'
		Dc.l	$02010052,Palt_RGB_P,PlusMinus
		Dc	'BX',-21,043,-13,051
		Dc	'IM',-19,047,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Palt_RGB_P,PlusMinus
		Dc	'BX',-12,043,-04,051
		Dc	'IM',-10,045,5,Im_Plus-Im

		Dc	'TX',003,062,-01,8
		Dc.l	GT
GPalt_Grn_Prop:	Dc	'GD'
		Dc.l	$0202005b,Palt_Prop_Grn,Palt_RGB_Prop
		Dc	'BX',011,053,-44,061
		Dc	'BX',013,055,-46,059
		Dc	'GD'
		Dc.l	$02030a5b,3,Palt_Grn_N
		Dc	'RC',-42,053,-23,061
GPalt_Grn:	Dc	'TX',-39,060,-01,5
		Dc.l	Palt_GrnNT
		Dc	'GD'
		Dc.l	$02010052,Palt_RGB_P,PlusMinus
		Dc	'BX',-21,053,-13,061
		Dc	'IM',-19,057,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Palt_RGB_P,PlusMinus
		Dc	'BX',-12,053,-04,061
		Dc	'IM',-10,055,5,Im_Plus-Im

		Dc	'TX',003,072,-01,8
		Dc.l	BT
GPalt_Blu_Prop:	Dc	'GD'
		Dc.l	$0202005c,Palt_Prop_Blu,Palt_RGB_Prop
		Dc	'BX',011,063,-44,071
		Dc	'BX',013,065,-46,069
		Dc	'GD'
		Dc.l	$02030a5c,3,Palt_Blu_N
		Dc	'RC',-42,063,-23,071
GPalt_Blu:	Dc	'TX',-39,070,-01,5
		Dc.l	Palt_BluNT
		Dc	'GD'
		Dc.l	$02010052,Palt_RGB_P,PlusMinus
		Dc	'BX',-21,063,-13,071
		Dc	'IM',-19,067,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Palt_RGB_P,PlusMinus
		Dc	'BX',-12,063,-04,071
		Dc	'IM',-10,065,5,Im_Plus-Im

		Dc	'RO'
		Dc.l	Upd_PaletteBoxD

		Dc	'GD'
		Dc.l	$010000a9,0,Palt_SelectColor
GPalt_Palt:	Dc	'FR',000,074,-01,-23
		Dc	'RO'
		Dc.l	Upd_Palette	

		Dc	'BX',000,-22,-25,-01

		Dc	'TX',003,-13,-01,5
		Dc.l	ColorT
		Dc	'GD'
		Dc.l	$02030200,0,0
		Dc	'RC',-66,-20,-47,-12
		Dc	'TX',-63,-13,-01,5
		Dc.l	Palt_ColorNT
		Dc	'GD'
		Dc.l	$02010000,0,PlusMinus
		Dc	'BX',-45,-20,-37,-12
		Dc	'IM',-43,-16,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010000,0,PlusMinus
		Dc	'BX',-36,-20,-28,-12
		Dc	'IM',-34,-18,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',003,-10,037,-02
		Dc	'TX',006,-03,-01,5
		Dc.l	RasterT

		Dc	'GD'
		Dc.l	$0100004f,0,Palt_PickColor
GPalt_Select:	Dc	'FR',-24,-22,-10,-01
		Dc	'RO'
		Dc.l	Upd_PaltSelect	

		Dc	'GD'
		Dc.l	$02020000,Palt_Prop_Brws,0
		Dc	'BX',-09,-22,-01,-10
		Dc	'BX',-07,-20,-03,-20

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

		Dc	'XX'

Palt_Prop_Red:	Dc.b	%00001010,0	;FreeX,Y PropX,Y
		Dc	4096,0		;KnobX,Y
		Dc	0,0		;PosX,Y
Palt_Prop_Grn:	Dc.b	%00001010,0
		Dc	4096,0
		Dc	0,0
Palt_Prop_Blu:	Dc.b	%00001010,0
		Dc	4096,0
		Dc	0,0
Palt_Prop_Brws:	Dc.b	%00000101,0
		Dc	0,32767
		Dc	0,0

Palt_RGB_P:	Dc	1,0,255,$0103
Palt_Color_P:	Dc	1,0,15,$0103

Palt_RedNT:	Dc.b	'  0',0
Palt_GrnNT:	Dc.b	'  0',0
Palt_BluNT:	Dc.b	'  0',0

Color8T:	Dc.b	'Color:',0
Palt_ColorNT:	Dc.b	'  0',0
Palt_TotalNT:	Dc.b	'  0',0

;HSV redraw rate reverse revert 12/24
		Even
*=======================================================================*
*			         F O N T				*
*=======================================================================*
Font_New:
	*-- Get list space.
		Lea	FontList,a4	;###
		Jsr	Find_Unit_Space		;This routine saves regs. ###
		Move.l	a0,FN_LstA
		Bne.b	FN_NEr1
		Jmp	Mess_MemErr	;###
	*-- Allocate memory.
	FN_NEr1:Move.l	#102*4+16,d0		;ByteSize
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Tst.l	d0
		Bne.b	FN_NEr2
		Jmp	Mess_MemErr	;###
	FN_NEr2:Move	d7,Cur_Font
	*-- Write to list.
		Move.l	FN_LstA(pc),a5
		Move.l	d0,(a5)
		Move	#%111,4(a5)		;Set Flags = New
		Move.l	a5,a0
		Jsr	Unnamed		;###
	*-- Store new Unit.
		Move.l	(a5),a1			;Get Font Address
		Clr	(a1)+			;Write Id
		Move.l	#102*4+16,(a1)+		;Write BytSize
		Move.b	#32,(a1)+		;Write FirstChar
		Move.b	#102,(a1)+		;Write Total
		Clr.l	(a1)+			;Write Width,Height
		Clr	(a1)+			;Write SpaceWidth
		Clr	(a1)+			;Write PropFlag
		Moveq.l	#101,d7			;Write 102 chars
	FN_Lp:	Move.l	#$ffff0000,(a1)+	;+
		Dbf	d7,FN_Lp		;+
		Bra.b	Change_Font
	FN_LstA:Dc.l	0
*---------------
Font_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Get_Font_LAdr:	Move.l	Mem_FontList,a2	;###
		Clr.l	d0
		Move	Cur_Font,d0	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Upd_FontNameD:	Lea	Font_Info,a3	;###
		Lea	Font_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_FontNameG:	Lea	FontLay,a5	;###
		Lea	Font_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Change_Font:	Bsr.w	Upd_FontNumbD
		;Bsr.w	Upd_FontNumbG
		Bsr.b	Upd_FontNameD
		Bsr.b	Upd_FontNameG
		;Bsr.w	Upd_FontPropFix

		Lea	FontLay,a5	;###
		Lea	Font_UpdAll(pc),a4
		Jsr	Draw_All	;###

		;Lea	FontLay,a5	;###
		;Lea	GFont_PropFix(pc),a4
		;Moveq.l	#3,d7
		;Jsr	Draw_Some	;###

		;Bsr.w	Font_Browse
		Lea	Font_Info,a3	;###
		Jmp	Upd_SelcUnit	;###
*---------------
Font_Height:	Bsr.b	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	FH_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value,d0	;###
		Move	d0,10(a0)
		Lea	Font_HeightNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv		;###
		Lea	FontLay,a5	;###
		Lea	GFont_Height(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
	FH_Ed:	Rts
*---------------
Font_Width:	Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	FW_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value,d0	;###
		Move	d0,08(a0)
		Lea	Font_WidthNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv		;###
		Lea	FontLay,a5	;###
		Lea	GFont_Width(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
	FW_Ed:	Rts
*---------------
Font_Space:	Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	FS_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a0
		Move.l	Convert_Value,d0	;###
		Move	d0,12(a0)
		Lea	Font_SpaceNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv		;###
		Lea	FontLay,a5	;###
		Lea	GFont_Space(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
	FS_Ed:	Rts
*---------------
Upd_FontNumbG:	Lea	FontLay,a5	;###
		Lea	GFont_Height(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###

		Lea	GFont_Width(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###

		Lea	GFont_Space(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Upd_FontNumbD:	Move	FontList_Len,d0	;###
		Beq.b	UFD_End
		Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	UFD_End

		Bsr.w	Get_Font_LAdr
		Move.l	(a2),a0
		Move	10(a0),d0
		Lea	Font_HeightNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv	;###

		Bsr.w	Get_Font_LAdr
		Move.l	(a2),a0
		Move	08(a0),d0
		Lea	Font_WidthNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv	;###

		Bsr.w	Get_Font_LAdr
		Move.l	(a2),a0
		Move	12(a0),d0
		Lea	Font_SpaceNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv	;###

	UFD_End:Rts
*---------------
Upd_Font_YOffsD:Bsr.w	Get_Font_LAdr
		Move.l	(a2),a2
		Move	Font_SelChar(pc),d0
		Bmi.b	UFYO_Ed
		Sub.b	6(a2),d0
		Lsl	#2,d0
		Move	18(a2,d0.w),d0	;YOffset
		Lea	Font_YOffsNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv		;###
	UFYO_Ed:Rts
*---------------
Upd_Font_YOffsG:Lea	FontLay,a5	;###
		Lea	GFont_YOffs(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Font_Browse:	Bsr.w	Upd_FontChars
		Lea	FontLay,a5	;###
		Lea	GFont_CharList(pc),a4
		Moveq.l	#35,d7
		Jmp	Draw_Some	;###
*---------------
Font_Select:	Move	#-1,Font_SelChar
		Move.l	HitGd,a0	;###
		Btst	#0,4(a0)		;Button up?
		Beq.b	FSC_Ed
	*-- Which Gadget line?
		Move.l	a0,d2
		Lea	GFont_Char1(pc),a2
		Sub.l	a2,d2
		Divu	#52,d2
	*-- Decode browser
		Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	FSC_Ed
		Move.l	(a2),a2
		Lea	Font_Prop(pc),a0	;Find Prop
		Move	8(a0),d0		;Read %PosY
		Clr	d1			;Get Total
		Move.b	7(a2),d1		;+
		Mulu	d1,d0			;Convert Prop
		Swap	d0			;+
		Add.b	6(a2),d0		;Add FirstChar

		Add	d2,d0
		Move	d0,Font_SelChar

		Move	Font_SelChar(pc),d0
		Bmi.b	FUP_Ed
		Sub.b	6(a2),d0
		Lsl	#2,d0
		Move	16(a2,d0.w),d7
		Bmi.b	FSC_Ed
		Move	d7,Cur_Piec
		Jsr	Change_Piec	;###

		Bsr.w	Upd_Font_YOffsD
		Bsr.w	Upd_Font_YOffsG

	FSC_Ed:	Rts
Font_SelChar:	Dc	0
*---------------
Font_DelPiece:	Moveq.l	#-1,d7
		Bra.b	FUP_Com
*---------------
Font_UsePiece:	Move	Cur_Piec,d7	;###
	FUP_Com:Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	FUP_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a2
		Move	Font_SelChar(pc),d0
		Bmi.b	FUP_Ed
		Sub.b	6(a2),d0
		Lsl	#2,d0
		Move	d7,16(a2,d0.w)
		Bsr.w	Font_Browse
	FUP_Ed:	Move	#-1,Font_SelChar
		Rts
*---------------
Font_YOffs:	Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	FYO_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a2
		Move	Font_SelChar(pc),d0
		Bmi.b	FYO_Ed
		Sub.b	6(a2),d0
		Lsl	#2,d0
		Move.l	Convert_Value,d7	;###
		Move	d7,18(a2,d0.w)	;YOffset
		Move	d7,d0
		Lea	Font_YOffsNT+3(pc),a0
		Move	#$102,d7
		Jsr	Conv		;###
		Lea	FontLay,a5	;###
		Lea	GFont_YOffs(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
	FYO_Ed:	Rts
*---------------
Upd_FontChars:	Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	UFC_Ed
		Move.l	(a2),a2
		Lea	Font_Prop(pc),a0	;Find Prop
		Move	8(a0),d0		;Read %PosY
		Clr	d1			;Get Total
		Move.b	7(a2),d1		;+
		Mulu	d1,d0			;Convert Prop
		Swap	d0			;+
		Move	d0,d1			;+ Copy CharNo
		Add.b	6(a2),d0		;Add FirstChar
		Lsl	#2,d1			;Find first char
		Lea	Font_Char1T(pc),a0
		Lea	GFont_Char1(pc),a1
		Lea	16(a2,d1.w),a3		;Start of Font_Pieces
		Moveq.l	#7,d7			;8 gadget lines
	UFC_Lp:	Move.b	d0,(a0)+		;Write character
		Clr.b	(a0)+			;+
		Clr.l	48(a1)			;Write null string
		Move.l	Mem_PiecList,a2		;Write Piece Name	###
		Clr.l	d6			;+
		Move	(a3),d6			;+ Get Font_Piece
		Bmi.b	UFC_NoP			;+ No Piece!
		Lsl.l	#5,d6			;+
		Add.l	d6,a2			;+
		Addq.l	#8,a2			;+
		Move.l	a2,48(a1)		;+ Write it to 'TX'
	UFC_NoP:Bclr	#0,4(a1)		;Deselect Gadget line
		Addq.l	#4,a3			;Next Font_Piece
		Add	#52,a1			;Next Gadget Line
		Addq	#1,d0			;Count ASCII
		Dbf	d7,UFC_Lp		;Loop
	UFC_Ed:	Rts
*---------------
Upd_FontPropFix:Lea	GFont_PropFix(pc),a0
		Lea	Im_Blank-Im,a3
		Bsr.w	Get_Font_LAdr
		Move.l	(a2),d1
		Beq.b	UFPF_Ed
		Move.l	d1,a2
		Tst	14(a2)
		Beq.b	UFPF_No
		Lea	Im_Check5-Im,a3
	UFPF_No:Move	a3,32(a0)
	UFPF_Ed:Rts
*---------------
Font_PropFix:	Jsr	CheckMark5	;###
		Moveq.l	#$0001,d3
		Tst	d7
		Bne.b	FPF_No
		Clr	d3
	FPF_No:	Bsr.w	Get_Font_LAdr
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),d1
		Beq.b	FPF_Ed
		Move.l	d1,a2
		Move	d3,14(a2)
	FPF_Ed:	Rts
*---------------
Font_Load:	Move.l	FontList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Font,d4	;###
		Move.l	#'FONT',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Font
		Bra.w	Load_FontUnits
*---------------
Load_FontUnits:	Bsr.w	Get_Font_LAdr
		Tst.l	(a2)
		Beq.b	LFU_End
		Move.l	(a2),a2
		Clr	d7
		Move.b	7(a2),d7	;Total
		Lea	16(a2),a1
	LFU_Nxt:Move	(a1),d0
		Bmi.b	LFU_Skp
		Move	d0,Cur_Piec
		Movem.l	a0-a6/d0-d7,-(a7)
		Jsr	Piec_Load
		Movem.l	(a7)+,a0-a6/d0-d7
	LFU_Skp:Addq	#4,a1
		Subq	#1,d7
		Bne.b	LFU_Nxt
	LFU_End:Rts
*---------------
Check_Font:	Lea	Font_Jump(pc),a0
		Move	FontList_Len,d0	;###
		Beq.b	CFo_NUn
	*-- Find current Object, and check if it exists
		Move.l	Mem_FontList,a2	;###
		Move	Cur_Font,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Object?
		Beq.b	CFo_No		;No
		Lea	Font_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CFo_NUn:Lea	Font_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CFo_No:	Lea	Font_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_Font:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Font8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Font_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Font_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Font_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-04,025

		Dc	'RO'
		Dc.l	Upd_FontNameD

Font_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Font_Name
		Dc	'RC',049,015,-26,023
		Dc	'TX',051,022,-77,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Font_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Font_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

Font_UpdAll:	Dc	'RO'
		Dc.l	Check_Font
		Dc	'JP'
Font_Jump:	Dc.l	Font_No

Font_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Font_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Font_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Font_Yes:	Dc	'BX',000,028,-01,058

		Dc	'GD'
		Dc.l	$02010054,0,Font_UsePiece
		Dc	'BX',003,030,015,042
		Dc	'IM',005,034,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$02010055,0,Font_DelPiece
		Dc	'BX',020,030,032,042
		Dc	'IM',022,032,9,Im_ClrClips-Im

		Dc	'RO'
		Dc.l	Upd_FontPropFix
		Dc	'BX',037,030,076,042
		Dc	'TX',040,039,-01,5
		Dc.l	PropT
GFont_PropFix:	Dc	'GD'
		Dc.l	$02010056,0,Font_PropFix
		Dc	'BX',065,032,073,040
		Dc	'IM',067,034,5,Im_Check5-Im

		Dc	'RO'
		Dc.l	Upd_FontNumbD

		Dc	'BX',081,030,-04,042
		Dc	'TX',084,039,-01,5
		Dc.l	HeightT
GFont_Height:	Dc	'GD'
		Dc.l	$02030a00,3,Font_Height
		Dc	'RC',117,032,-26,040
		Dc	'TX',120,039,-77,5
		Dc.l	Font_HeightNT

		Dc	'GD'
		Dc.l	$02010052,Font_Common_P,PlusMinus
		Dc	'BX',-23,032,-15,040
		Dc	'IM',-21,036,1,Im_Minus-Im

		Dc	'GD'
		Dc.l	$02010053,Font_Common_P,PlusMinus
		Dc	'BX',-14,032,-06,040
		Dc	'IM',-12,034,5,Im_Plus-Im

		Dc	'BX',003,044,076,056
		Dc	'TX',006,053,-01,5
		Dc.l	SpaceT
GFont_Space:	Dc	'GD'
		Dc.l	$02030a6b,3,Font_Space
		Dc	'RC',034,046,053,054
		Dc	'TX',037,053,-77,5
		Dc.l	Font_SpaceNT

		Dc	'GD'
		Dc.l	$02010052,Font_Common_P,PlusMinus
		Dc	'BX',056,046,064,054
		Dc	'IM',058,050,1,Im_Minus-Im

		Dc	'GD'
		Dc.l	$02010053,Font_Common_P,PlusMinus
		Dc	'BX',065,046,073,054
		Dc	'IM',067,048,5,Im_Plus-Im

		Dc	'BX',081,044,-04,056
		Dc	'TX',084,053,-01,5
		Dc.l	WidthT

GFont_Width:	Dc	'GD'
		Dc.l	$02030a00,3,Font_Width
		Dc	'RC',117,046,-26,054
		Dc	'TX',120,053,-77,5
		Dc.l	Font_WidthNT

		Dc	'GD'
		Dc.l	$02010052,Font_Common_P,PlusMinus
		Dc	'BX',-23,046,-15,054
		Dc	'IM',-21,050,1,Im_Minus-Im

		Dc	'GD'
		Dc.l	$02010053,Font_Common_P,PlusMinus
		Dc	'BX',-14,046,-06,054
		Dc	'IM',-12,048,5,Im_Plus-Im

		Dc	'BX',000,059,-01,075

		Dc	'BX',003,061,-04,073
		Dc	'TX',006,070,-01,5
		Dc.l	YOffsetT

		Dc	'RO'
		Dc.l	Upd_Font_YOffsD

GFont_YOffs:	Dc	'GD'
		Dc.l	$02030a00,3,Font_YOffs
		Dc	'RC',117,063,-26,071
		Dc	'TX',120,070,-77,5
		Dc.l	Font_YOffsNT

		Dc	'GD'
		Dc.l	$02010052,Font_YOffs_P,PlusMinus
		Dc	'BX',-23,063,-15,071
		Dc	'IM',-21,067,1,Im_Minus-Im

		Dc	'GD'
		Dc.l	$02010053,Font_YOffs_P,PlusMinus
		Dc	'BX',-14,063,-06,071
		Dc	'IM',-12,065,5,Im_Plus-Im

GFont_CharList:	Dc	'BX',000,076,011,-01

		Dc	'BX',012,076,-10,-01

		Dc	'RO'
		Dc.l	Upd_FontChars

GFont_Char1:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,077,-10,085
		Dc	'TX',003,086,-01,8
		Dc.l	Font_Char1T
		Dc	'TX',015,084,-25,5
		Dc.l	0

GFont_Char2:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,086,-10,094
		Dc	'TX',003,095,-01,8
		Dc.l	Font_Char2T
		Dc	'TX',015,093,-25,5
		Dc.l	0

GFont_Char3:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,095,-10,103
		Dc	'TX',003,104,-01,8
		Dc.l	Font_Char3T
		Dc	'TX',015,102,-25,5
		Dc.l	0

GFont_Char4:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,104,-10,112
		Dc	'TX',003,113,-01,8
		Dc.l	Font_Char4T
		Dc	'TX',015,111,-25,5
		Dc.l	0

GFont_Char5:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,113,-10,121
		Dc	'TX',003,122,-01,8
		Dc.l	Font_Char5T
		Dc	'TX',015,120,-25,5
		Dc.l	0

GFont_Char6:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,122,-10,130
		Dc	'TX',003,131,-01,8
		Dc.l	Font_Char6T
		Dc	'TX',015,129,-25,5
		Dc.l	0

GFont_Char7:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,131,-10,139
		Dc	'TX',003,140,-01,8
		Dc.l	Font_Char7T
		Dc	'TX',015,138,-25,5
		Dc.l	0

GFont_Char8:	Dc	'GD'
		Dc.l	$03010657,Font_Excl_List,Font_Select
		Dc	'DF',000,140,-10,148
		Dc	'TX',003,149,-01,8
		Dc.l	Font_Char8T
		Dc	'TX',015,147,-25,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$02020000,Font_Prop,Font_Browse
		Dc	'BX',-09,076,-01,-01
		Dc	'BX',-07,078,-03,-03

		Dc	'XX'

Font_Common_P:	Dc	1,0,255,$8103
Font_YOffs_P:	Dc	1,-99,127,$8103

Font_Prop:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,4369		;KnobX,Y
		Dc	0,0		;PosX,Y

Font_Excl_List:	Dc.l	GFont_Char1
		Dc.l	GFont_Char2
		Dc.l	GFont_Char3
		Dc.l	GFont_Char4
		Dc.l	GFont_Char5
		Dc.l	GFont_Char6
		Dc.l	GFont_Char7
		Dc.l	GFont_Char8
		Dc.l	0

Font_Char1T:	Dc.b	32,0
Font_Char2T:	Dc.b	33,0
Font_Char3T:	Dc.b	34,0
Font_Char4T:	Dc.b	35,0
Font_Char5T:	Dc.b	36,0
Font_Char6T:	Dc.b	37,0
Font_Char7T:	Dc.b	38,0
Font_Char8T:	Dc.b	39,0
Font_HeightNT:	Dc.b	'  0',0
Font_WidthNT:	Dc.b	'  0',0
Font_SpaceNT:	Dc.b	'  0',0
Font_YOffsNT:	Dc.b	'  0',0
YOffsetT:	Dc.b	'Y-OFFSET:',0
		Even
*=======================================================================*
*				L E V E L				*
*=======================================================================*
Levl_New:	Lea	LevlList,a4	;###
		Lea	New_Levl(pc),a2
		Jsr	Unit_New	;###
		Move	d7,Cur_Levl
		Bra.b	Change_Levl
New_Levl:	Dc	0	;Id		00
		Dc.l	14	;Size		02
		Dc	0	;FirstPos	06
		Dc	0	;FirstCond	08
		Dc	0	;Total		10
		Dc	-1	;End		12
*---------------
Change_Levl:	Bsr.b	Upd_LevlNameD
		Bsr.b	Upd_LevlNameG
		Bsr.w	Upd_EventPropD
		Bsr.w	Upd_LevlAllG
		Lea	Levl_Info,a3	;###
		Jmp	Upd_SelcUnit	;###
*---------------
Upd_LevlNameD:	Lea	Levl_Info,a3	;###
		Lea	Levl_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_LevlNameG:	Lea	LevlLay,a5	;###
		Lea	Levl_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Get_Screen_Mem:	Lea	Mem_Screen,a5	;###
		Jsr	Free_Mem	;###
	*-- (Wid+Scr+SBf)/8*Hgt*(Dpt*2+2)+(Wid+Scr+SBf)/8*YSc+XSc/8
		Move	#352,d1		;Width
		Add	#16,d1		;Scroll
		Add	#32,d1		;ScrollBuffer
		Lsr	#3,d1		;Bits/Byte

		Move	d1,d3		;Calculate BplSize
		Mulu	#256,d3		;+
		Move	d3,DstS		;+

		Move	Depth(pc),d7	;Bitplanes
		Add	d7,d7		;DoubleBuffer
		Addq	#2,d7		;Collision+Mask Bitplane
		Mulu	#256,d7		;Height
		Mulu	d1,d7		;*

		Mulu	#256,d1		;YScroll
		Clr.l	d2		;0
		Move	#32768,d2	;XScroll
		Lsr	#3,d2		;Bits/Byte
		Add.l	d2,d1
		Add.l	d1,d7	

		Lea	Mem_Screen,a5	;###
		Move.l	d7,d0
		Jsr	Alloc_Chip_Mem	;###
		Move.l	Mem_Screen,a0	;###
		Move.l	a0,Dst1A

		Move	DstS(pc),d0
		Mulu	Depth(pc),d0
		Add.l	d0,a0
		Move.l	a0,Dst2A

		Add.l	d0,a0
		Move.l	a0,MaskBpl

		Add	DstS(pc),a0
		Move.l	a0,CollBpl
	*-- Get memory for copperlists
		Lea	Mem_Copper1,a5	;###
		Move.l	#1024,d0
		Jsr	Alloc_Chip_Mem	;###
	*-- Move Copperlist
		Move.l	Mem_Copper1,a0	;###
		Lea	Cop1,a1		;###
	LPS_CLp:Move.l	(a1)+,d0
		Move.l	d0,(a0)+
		Cmp.l	#$fffffffe,d0
		Bne.b	LPS_CLp
	*-- Scroll preparations
		Lea	Mem_ScrollTab,a5	;###
		Move.l	#1024,d0
		Jsr	Alloc_Any_Mem	;###

		Clr	ScrDraw_X2
		Clr.l	ScrX
		Clr.l	ScrY
	*-- Object preparations
		Lea	Mem_Objects,a5	;###
		Jsr	Free_Mem	;###

		Lea	Mem_Objects,a5	;###
		Move.l	#16384,d0	;Max 64 objects.
		Jmp	Alloc_Any_Mem	;###
*---------------
Get_Bob_Mem:	Lea	Mem_SaveList1,a5	;###
		Move.l	#4096,d0
		Jsr	Alloc_Any_Mem	;###
		Move.l	Mem_SaveList1,SaveL1A	;###
		Move.l	Mem_SaveList1,SaveL1Cnt	;###
		
		Lea	Mem_SaveList2,a5	;###
		Move.l	#4096,d0
		Jsr	Alloc_Any_Mem	;###
		Move.l	Mem_SaveList2,SaveL2A	;###
		Move.l	Mem_SaveList2,SaveL2Cnt	;###
		
		Lea	Mem_SaveBack1,a5	;###
		Move.l	#40960,d0
		Jsr	Alloc_Chip_Mem	;###
		Move.l	Mem_SaveBack1,SaveB1A	;###

		Lea	Mem_SaveBack2,a5	;###
		Move.l	#40960,d0
		Jsr	Alloc_Chip_Mem	;###
		Move.l	Mem_SaveBack2,SaveB2A	;###

		Lea	Mem_MaskBuffer,a5	;###
		Move.l	#10240,d0
		Jmp	Alloc_Chip_Mem	;###
*---------------
Free_Play_Mem:	Lea	Mem_ScrollTab,a5	;*** Scroll	;###
		Jsr	Free_Mem		;###
		Lea	Mem_SaveList1,a5	;###
		Jsr	Free_Mem		;###
		Lea	Mem_SaveList2,a5	;###
		Jsr	Free_Mem		;###
		Lea	Mem_SaveBack1,a5	;###
		Jsr	Free_Mem		;###
		Lea	Mem_SaveBack2,a5	;###
		Jsr	Free_Mem		;###
		Lea	Mem_MaskBuffer,a5	;###
		Jsr	Free_Mem		;###
		Lea	Mem_Copper1,a5		;###
		Jmp	Free_Mem		;###
*---------------
Levl_PlayScreen:Move	#'LV',Play_Mode
		Bsr.w	Get_Screen_Mem
		Bsr.w	Get_Bob_Mem
	*-- Fill in test object
		Jsr	Find_Object_Vacancy	;###
		Move	#$8000,(a5)
		Jsr	Get_Anim_LAdr		;###
		Tst.l	(a2)
		Beq.w	WPS_NAn
		Move.l	(a2),a0
		Jsr	Prep_Object_Anim	;###
		Move	#32767,40(a5)

	LPS_NAn:Clr	GM_OutCnt
		Bsr.w	Init_Level

		Jsr	Erase		;###
		Jsr	Leave_Dos	;###
		Jsr	Chip		;Feed Custom Chips ###
		Jsr	Game_Palette	;###

	LPS_M1:	Jsr	Game_Background	;###
		Btst	#6,$bfe001
		Bne.b	LPS_M1
	LPS_M3:	Moveq.l	#127,d0
	LPS_M2:	Btst	#6,$bfe001
		Beq.b	LPS_M3
		Dbf	d0,LPS_M2

		Jsr	Enter_Dos	;###

		Move	Song_Playing(pc),d0
		Beq.b	LPS_NPl
		Clr	Song_Playing
		Lea	$dff000,a6
		Jsr	MT_End

	LPS_NPl:Bsr.w	Free_Play_Mem
	LPS_End:Rts
*---------------
Levl_SelectList:Move	#-1,Cur_LevlEvent
		Bsr.w	Upd_EventPropD
		Bra.w	Upd_LevlAllG
*---------------
Upd_LevlEventsD:Clr	ULE_Cnt
		Clr	ULE_Amt
		Lea	GLevl_Event1(pc),a0	;Clear EventList
		Move	#'XX',-72+24(a0)	;+
				
		Move	LevlList_Len,d0	;No Levels?	###
		Beq.w	ULE_End
		
		Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.w	ULE_End
		Move.l	(a2),a2

		Lea	GLevl_Condition(pc),a0
		Btst	#0,4(a0)
		Bne.b	ULE_Con
		Lea	GLevl_Timer(pc),a0
		Btst	#0,4(a0)
		Bne.b	ULE_Tim
		Lea	GLevl_Position(pc),a0
		Btst	#0,4(a0)
		Bne.b	ULE_Pos
		Bra.w	ULE_End
		
	ULE_Con:Move	8(a2),ULE_Cnt	;FirstCond
		Move	10(a2),d0	;Total
		Sub	8(a2),d0	;FirstCond
		Move	d0,ULE_Amt
		Bra.b	ULE_Ok

	ULE_Tim:Clr	ULE_Cnt
		Move	6(a2),ULE_Amt
		Bra.b	ULE_Ok

	ULE_Pos:Move	6(a2),ULE_Cnt	;FirstPos
		Move	8(a2),d0	;FirstCond
		Sub	6(a2),d0	;FirstPos
		Move	d0,ULE_Amt

	ULE_Ok:	
	*-- Read prop and calculate Event number
		Lea	Levl_Prop_Event(pc),a4
		Clr.l	d4
		Move	8(a4),d4	;%PosY
		Clr.l	d5
		Move	4(a4),d5	;%KnobY
		Lsr	#3,d5		;Divide by 4lines*2half
		Add.l	d5,d4
		Move	ULE_Cnt(pc),d2
		Move	ULE_Amt(pc),d1
		Mulu	d1,d4
		Swap	d4
		Add	d4,d2

		Lea	GLevl_Event1(pc),a0
		Clr	d0
	ULE_Lop:Move	#'XX',-72+24(a0)
		Tst	d1
		Ble.w	ULE_NEv
		Move	#'GD',-72+24(a0)
	*-- Find Event (A3->Address)
		Move	d2,d3
		Add	d3,d3
		Move	12(a2,d3.w),d3
		Lea	00(a2,d3.w),a3
	*-- Write event text
		Clr.l	-4(a0)
		Move	2(a3),d7
		Cmp	#1,d7
		Beq.b	ULE_Bck
		Cmp	#4,d7
		Beq.b	ULE_Snd
		Cmp	#5,d7
		Beq.b	ULE_Sng
		Cmp	#9,d7
		Beq.b	ULE_Pal
		Bra.b	ULE_NOk

	ULE_Bck:Move.l	Mem_BackList,a5		;###
		Bra.b	ULE_Uni

	ULE_Snd:Move.l	Mem_SondList,a5		;###
		Bra.b	ULE_Uni

	ULE_Sng:Move.l	Mem_SongList,a5		;###
		Bra.b	ULE_Uni

	ULE_Pal:Move.l	Mem_PaltList,a5		;###
		Bra.w	ULE_Uni

	ULE_Uni:Clr.l	d4
		Move	14(a3),d4	;Unit
		Bmi.b	ULE_NOk
		Lsl.l	#5,d4
		Add.l	d4,a5
		Addq	#8,a5
		Move.l	a5,-4(a0)
		Bra.w	ULE_NOk
	*-- Write image
	ULE_NOk:Lea	Levl_ImageList(pc),a4
		Move	2(a3),d3
		Add	d3,d3
		Move	-2(a4,d3.w),32(a0)

		Bclr	#0,4(a0)
		Cmp	Cur_LevlEvent(pc),d2
		Bne.b	ULE_NCr
		Bset	#0,4(a0)
	ULE_NCr:
		Subq	#1,d1		;Count Amount
		Addq	#1,d2		;Count EventList

	ULE_NEv:Add	#106-24,a0
		Addq	#1,d0		;Count ListLines
		Cmp	#4,d0
		Beq.b	ULE_End
		Bra.w	ULE_Lop

	ULE_End:Rts
	ULE_Cnt:Dc	0
	ULE_Amt:Dc	0

Levl_ImageList:	Dc	Im_Background-Im	;1
		Dc	Im_Scroll-Im		;2
		Dc	Im_Release-Im		;3
		Dc	Im_Sound-Im		;4
		Dc	Im_Song-Im		;5
		Dc	Im_Mask-Im		;6
		Dc	Im_Player-Im		;7
		Dc	Im_Score-Im		;8
		Dc	Im_Palette-Im		;9
		Dc	Im_Once-Im		;10
*---------------
Upd_EventPropD:	Clr	d7

		Lea	Levl_Prop_Event(pc),a4
		Clr	8(a4)		;%PosY
		Move	#$ffff,4(a4)	;%KnobY

		Move	LevlList_Len,d0	;No Levels?	;###
		Beq.b	UEP_End

		Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.b	UEP_End
		Move.l	(a2),a2

		Lea	GLevl_CondJP(pc),a1
		Lea	GLevl_Condition(pc),a0
		Btst	#0,4(a0)
		Bne.b	UEP_Con
		Lea	GLevl_Timer(pc),a0
		Btst	#0,4(a0)
		Bne.b	UEP_Tim
		Lea	GLevl_Position(pc),a0
		Btst	#0,4(a0)
		Bne.b	UEP_Pos
		Bra.b	UEP_End

	UEP_Con:Lea	Levl_ConDL(pc),a3
		Move.l	a3,2(a1)
		Move	10(a2),d7	;Total
		Sub	8(a2),d7	;FirstCond
		Bra.b	UEP_Ok

	UEP_Tim:Lea	Levl_TimDL(pc),a3
		Move.l	a3,2(a1)
		Move	6(a2),d7
		Bra.b	UEP_Ok

	UEP_Pos:Lea	Levl_PosDL(pc),a3
		Move.l	a3,2(a1)
		Move	8(a2),d7	;FirstCond
		Sub	6(a2),d7	;FirstPos

	UEP_Ok:	Cmp	#4,d7
		Ble.b	UEP_End

		Move.l	#$40000,d0
		Divu	d7,d0
		Addq	#1,d0
		Move	d0,4(a4)
	UEP_End:Rts
*---------------
Upd_LevlEventsG:Lea	Levl_EventsDL(pc),a4
		Lea	LevlLay,a5	;###
		Jmp	Draw_All	;###
*---------------
Get_Levl_LAdr:	Move.l	Mem_LevlList,a2	;###
		Clr.l	d0
		Move	Cur_Levl,d0	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Levl_SortTime:	Bsr.b	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.b	LST_End
		Move.l	(a2),a2
	*-- Find Event (A3->Address)
		Move	Cur_LevlEvent(pc),d3
		Add	d3,d3
		Move	12(a2,d3.w),d3
		Lea	00(a2,d3.w),a3

		Move	4(a3),d7			;Get Time

		Move	6(a2),d6			;FirstPos
		Move	Cur_LevlEvent(pc),LME_From	;From=Cur_LevlEvent
		Clr	d0		;Clear Event counter.
	LST_Lp:	Move	d0,d3		;Find Event
		Add	d3,d3		;+
		Move	12(a2,d3.w),d3	;+
		Lea	00(a2,d3.w),a3	;+
		Cmp	4(a3),d7	;Is this Time-value greater?
		Blt.b	LST_Ok		;+ Yes!
		Addq	#1,d0		;Next Event
		Cmp	d0,d6		;Reached Last Time Event?
		Bne.b	LST_Lp		;+ No, loop!

	LST_Ok:	Move	d0,LME_To		;To=ThisEvent
		Bsr.b	Levl_MoveEvent		;Move It!
		Move	LME_To(pc),Cur_LevlEvent;Cur_Ev=To
		Move	LME_From(pc),d0		;From>=To
		Cmp	LME_To(pc),d0		;+
		Bge.b	LST_End			;+ Yes! End!
		Subq	#1,Cur_LevlEvent	;+ No! Cur_Ev=Cur_Ev-1
	LST_End:Rts
*---------------
Levl_MoveEvent:	Move	LME_From(pc),d0		;From=To?
		Cmp	LME_To(pc),d0		;+
		Beq.w	LME_End			;+
		Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.w	LME_End
		Move.l	a2,LME_ListAdr
		Bsr.w	Update_LevlBuf
	*-- Free old Level
		Move.l	LME_ListAdr(pc),a4
		Jsr	Free_Unit	;###
	*-- Allocate new space for Level
		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	LME_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	LME_NEr
		Jmp	Mess_MemErr	;###
	LME_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Level address
		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,(a1)+		;BytSize
		Move	(a2)+,(a1)+		;FirstPos
		Move	(a2)+,(a1)+		;FirstIf
		Move	(a2)+,d7		;Total
		Move	d7,(a1)+		;+

		Move.l	a1,a3			;First event address
		Move	d7,d6			;+ (Total*2)
		Add	d6,d6			;+ +
		Add	d6,a3			;+

		Move.l	a2,a4			;First event address
		Move	d7,d6
		Add	d6,d6
		Add	d6,a4
	*-- Copy Events
		Clr	d0			;Clear Event counter
		Move	d7,d6			;Calculate first offset
		Add	d6,d6			;+ *2
		Add	#12,d6			;+ Add 'Header' size

	LME_CEL:Cmp	LME_From(pc),d0		;Skip this Event?
		Beq.b	LME_Skp			;+
		Cmp	LME_To(pc),d0		;Insert Event here?
		Beq.b	LME_Ins			;+

	LME_Con:Move	(a4)+,d5		;Copy EventSize
		Move	d5,(a3)+		;+
		Bmi.b	LME_End			;If -1 then end
		Move	d6,(a1)+		;Write EventOffset
		Add	d5,d6			;Add EventSize
		Subq	#3,d5
	LME_CEB:Move.b	(a4)+,(a3)+
		Dbf	d5,LME_CEB
		Addq	#1,d0			;Count one Event
		Bra.b	LME_CEL			;Next...

	LME_End:Bsr.w	Upd_EventPropD
		;Bsr.w	Upd_LevlEventsD
		;Bsr.w	Upd_LevlEventsG
		Bsr.w	Upd_LevlDL
		Bra.w	Upd_LevlAllG

	LME_Skp:Move	(a4),d5			;Get Event size
		Add	d5,a4			;Skip Event
		Addq	#1,d0			;Count one Event
		Bra.b	LME_CEL			;Next...

	LME_Ins:
	*-- Find Event (A5->Address)
		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
		Move	LME_From(pc),d3		;Find Event to insert
		Add	d3,d3			;+
		Move	12(a2,d3.w),d3		;+
		Lea	00(a2,d3.w),a5		;+

		Move	(a5)+,d5		;Copy EventSize
		Move	d5,(a3)+		;+
		Move	d6,(a1)+		;Write EventOffset
		Add	d5,d6			;Add EventSize
		Subq	#3,d5
	LME_IEB:Move.b	(a5)+,(a3)+
		Dbf	d5,LME_IEB
		Bra.b	LME_Con			;Continue...

LME_ListAdr:	Dc.l	0
LME_From:	Dc	0
LME_To:		Dc	0
*---------------
Levl_AddEvent:	Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.w	LAE_End
		Move.l	a2,LAE_ListAdr
		Bsr.w	Update_LevlBuf

		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
		Lea	GLevl_Condition(pc),a0
		Btst	#0,4(a0)
		Bne.b	LAE_Con
		Lea	GLevl_Timer(pc),a0
		Btst	#0,4(a0)
		Bne.b	LAE_Tim
		Lea	GLevl_Position(pc),a0
		Btst	#0,4(a0)
		Bne.b	LAE_Pos
		Bra.w	LAE_End

	LAE_Tim:Move	#0,LAE_Loc
		Addq	#1,6(a2)	;FirstPos
		Addq	#1,8(a2)	;FirstCond
		Bra.b	LAE_Ok

	LAE_Pos:Move	6(a2),LAE_Loc	;FirstPos
		Addq	#1,8(a2)	;FirstCond
		Bra.b	LAE_Ok

	LAE_Con:Move	8(a2),LAE_Loc

	LAE_Ok:
	*-- Find Event Length
		Lea	Levl_NewEvents(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2
		Move	4(a2),d0
		Addq	#2,d0			;Plus 2 for EventOffset
		Move	d0,LAE_BytesAdd
	*-- Free old Level
		Move.l	LAE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Level
		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Add	LAE_BytesAdd(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	LAE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	LAE_NEr
		Jmp	Mess_MemErr		;###
	LAE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Level address
		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	LAE_BytesAdd(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,(a1)+		;FirstPos
		Move	(a2)+,(a1)+		;FirstIf
		Move	(a2)+,d7		;Total
		Addq	#1,d7			;+
		Move	d7,(a1)+		;+

		Move.l	a1,a3			;First event address
		Move	d7,d6
		Add	d6,d6
		Add	d6,a3

		Move.l	a2,a4			;First event address
		Move	d7,d6
		Subq	#1,d6
		Add	d6,d6
		Add	d6,a4
	*-- Copy Events
		Clr	d0
		Move	d7,d6
		Add	d6,d6
		Add	#12,d6			;'Header' Size

	LAE_CEL:Cmp	LAE_Loc(pc),d0		;Insert Event here?
		Beq.b	LAE_AE
		Move	(a4)+,d5		;Copy EventSize
		Move	d5,(a3)+		;+
		Bmi.b	LAE_End			;If -1 then End
		Move	d6,(a1)+		;Write EventOffset
		Add	d5,d6			;Add EventSize
		Subq	#3,d5
	LAE_CEB:Move.b	(a4)+,(a3)+
		Dbf	d5,LAE_CEB
		Addq	#1,d0
		Bra.b	LAE_CEL
		
	LAE_End:Bsr.w	Upd_EventPropD
		Bsr.w	Upd_LevlEventsD
		Bsr.w	Upd_LevlDL
		Bra.w	Upd_LevlAllG

	LAE_AE:	Move	d6,(a1)+

		Lea	Levl_NewEvents(pc),a2
		Move.l	HitGd,a0		;###
		Move	8(a0),d2		;EventType
		Lsl	#2,d2
		Move.l	-4(a2,d2.w),a2

		Add	4(a2),d6
		Clr	d2
		Move.l	a3,a0
	LAE_LpN:Move.b	4(a2,d2.w),(a3)+
		Addq	#1,d2
		Cmp	4(a2),d2
		Bne.b	LAE_LpN

		Move	LAE_Loc(pc),Cur_LevlEvent
		Move.l	(a2),d2
		Beq.b	LAE_NRt
		Move.l	d2,a2
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	(a2)		;Jsr to New-routine. A0=Event.
		Movem.l	(a7)+,d0-d7/a0-a6

	LAE_NRt:Addq	#1,d0
		Bra.b	LAE_CEL

LAE_Loc:	Dc	0
LAE_ListAdr:	Dc.l	0
LAE_BytesAdd:	Dc	0

Levl_NewEvents:	Dc.l	Levl_BackEv
		Dc.l	Levl_ScrlEv
		Dc.l	Levl_RelsEv
		Dc.l	Levl_SondEv
		Dc.l	Levl_SongEv
		Dc.l	Levl_ObjcEv
		Dc.l	Levl_PlayEv
		Dc.l	Levl_ScorEv
		Dc.l	Levl_PaltEv
		Dc.l	Levl_EndLEv

Levl_BackEv:	Dc.l	Levl_NewBack	;Rtn
		Dc	16,1,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	-1		;Background	14
Levl_ScrlEv:	Dc.l	0		;Rtn
		Dc	16,2,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	0		;---		14
Levl_RelsEv:	Dc.l	0		;Rtn
		Dc	22,3,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	0		;UnitType	14
		Dc	-1		;Unit		16
		Dc	0		;XPosition	18
		Dc	0		;YPosition	20
Levl_SondEv:	Dc.l	0		;Rtn
		Dc	16,4,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	-1		;Sound		14
Levl_SongEv:	Dc.l	Levl_NewSong	;Rtn
		Dc	16,5,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	-1		;Song		14
Levl_ObjcEv:	Dc.l	0		;Rtn
		Dc	16,6,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	0		;---		14
Levl_PlayEv:	Dc.l	0		;Rtn
		Dc	16,7,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	0		;---		14
Levl_ScorEv:	Dc.l	0		;Rtn
		Dc	16,8,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	0		;---		14
Levl_PaltEv:	Dc.l	0		;Rtn
		Dc	16,9,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	-1		;Palette	14
Levl_EndLEv:	Dc.l	0		;Rtn
		Dc	16,10,0,0,0,0,0	;Size,Type,Val1,Val2,CondData
		Dc	-1		;NextLevel	14

Levl_NewSong:	Bra.w	LSong_UseSong_Com
Levl_NewBack:	Bra.w	LBack_UseBack_Com
*---------------
Levl_DelEvent:	Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.w	LDE_End
		Move.l	a2,LDE_ListAdr
		Bsr.w	Update_LevlBuf

		Move.l	Mem_LevlBuf,a2	;Get buffer address	###

		Move	Cur_LevlEvent(pc),d0
		Move	d0,LDE_Loc
		Bmi.w	LDE_End
		Cmp	6(a2),d0
		Blt.b	LDE_Tim
		Cmp	8(a2),d0
		Blt.b	LDE_Pos
		
	LDE_Con:Bra.b	LDE_Ok

	LDE_Tim:Subq	#1,6(a2)	;FirstPos
		Subq	#1,8(a2)	;FirstCond
		Bra.b	LDE_Ok

	LDE_Pos:Subq	#1,8(a2)	;FirstCond
	*-- Find Event Length (A3->Address)
	LDE_Ok:	Move	Cur_LevlEvent(pc),d2
		Move	d2,d3
		Add	d3,d3
		Move	12(a2,d3.w),d3
		Lea	00(a2,d3.w),a3
		Move	(a3),d0
		Addq	#2,d0			;Plus 2 for EventOffset
		Move	d0,LDE_BytesSub
	*-- Free old Level
		Move.l	LDE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Level
		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Sub	LDE_BytesSub(pc),d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	LDE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	LDE_NEr
		Jmp	Mess_MemErr		;###
	LDE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Level address
		Move.l	Mem_LevlBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub	LDE_BytesSub(pc),d0	;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,(a1)+		;FirstPos
		Move	(a2)+,(a1)+		;FirstIf
		Move	(a2)+,d7		;Total
		Subq	#1,d7			;+
		Move	d7,(a1)+		;+

		Move.l	a1,a3			;First event address (Dst)
		Move	d7,d6
		Add	d6,d6
		Add	d6,a3

		Move.l	a2,a4			;First event address (Src)
		Move	d7,d6
		Addq	#1,d6
		Add	d6,d6
		Add	d6,a4
	*-- Copy Events
		Clr	d0
		Move	d7,d6
		Add	d6,d6
		Add	#12,d6			;'Header' Size
	LDE_CEL:Cmp	LDE_Loc(pc),d0		;Delete this Event?
		Beq.b	LDE_DE
		Move	(a4)+,d5		;Copy EventSize
		Move	d5,(a3)+		;+
		Bmi.b	LDE_End			;If -1 then end
		Move	d6,(a1)+		;Write EventOffset
		Add	d5,d6			;Add EventSize
		Subq	#3,d5
	LDE_CEB:Move.b	(a4)+,(a3)+
		Dbf	d5,LDE_CEB
		Addq	#1,d0
		Bra.b	LDE_CEL
		
	LDE_End:Move	#-1,Cur_LevlEvent
		Bsr.w	Upd_EventPropD
		Bsr.w	Upd_LevlEventsD
		;Bsr.w	Upd_LevlEventsG
		Bsr.w	Upd_LevlDL
		Bra.w	Upd_LevlAllG

	LDE_DE:	Move	(a4),d0		;EventSize
		Add	d0,a4		;Skip it!
		Bra.b	LDE_CEL

LDE_Loc:	Dc	0
LDE_ListAdr:	Dc.l	0
LDE_BytesSub:	Dc	0
*---------------
Levl_Browse:	Bra.w	Upd_LevlEventsG
*---------------
Update_LevlBuf:	Lea	Levl_Info,a3	;###
		Jmp	Update_UnitBuf	;###
*---------------
Levl_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Levl_Select1:	Moveq.l	#0,d7
		Bra.b	Levl_Select
Levl_Select2:	Moveq.l	#1,d7
		Bra.b	Levl_Select
Levl_Select3:	Moveq.l	#2,d7
		Bra.b	Levl_Select
Levl_Select4:	Moveq.l	#3,d7

Levl_Select:	Move	#-1,Cur_LevlEvent
		Move.l	HitGd,a0	;Button off?	###
		Btst	#0,4(a0)	;+
		Beq.w	LS_End		;+
		
		Clr	LS_Cnt
		Clr	LS_Amt
				
		Move	LevlList_Len,d0	;No Events?	###
		Beq.w	LS_End
		
		Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.w	LS_End
		Move.l	(a2),a2

		Lea	GLevl_Condition(pc),a0
		Btst	#0,4(a0)
		Bne.b	LS_Con
		Lea	GLevl_Timer(pc),a0
		Btst	#0,4(a0)
		Bne.b	LS_Tim
		Lea	GLevl_Position(pc),a0
		Btst	#0,4(a0)
		Bne.b	LS_Pos
		Bra.b	LS_End
		
	LS_Con:	Move	8(a2),LS_Cnt	;FirstCond
		Move	10(a2),d0	;Total
		Sub	8(a2),d0	;FirstCond
		Move	d0,LS_Amt
		Bra.b	LS_Ok

	LS_Tim:	Clr	LS_Cnt
		Move	6(a2),LS_Amt
		Bra.b	LS_Ok

	LS_Pos:	Move	6(a2),LS_Cnt	;FirstPos
		Move	8(a2),d0	;FirstCond
		Sub	6(a2),d0	;FirstPos
		Move	d0,LS_Amt
	*-- Read prop and calculate Event number
	LS_Ok:	Lea	Levl_Prop_Event(pc),a4
		Clr.l	d4
		Move	8(a4),d4	;%PosY
		Clr.l	d5
		Move	4(a4),d5	;%KnobY
		Lsr	#3,d5		;Divide by 4lines*2half
		Add.l	d5,d4
		Move	LS_Cnt(pc),d2
		Move	LS_Amt(pc),d1
		Mulu	d1,d4
		Swap	d4
		Add	d4,d2

		Add	d7,d2
		Move	d2,Cur_LevlEvent

	LS_End:	Bsr.b	Upd_LevlDL
		Bra.b	Upd_LevlAllG
		
	LS_Cnt:	Dc	0
	LS_Amt:	Dc	0
Cur_LevlEvent:	Dc	-1
*---------------
Upd_LevlDL:	Move	Cur_LevlEvent(pc),d2
		Bpl.b	ULDL_Ok
		Lea	GLevl_EventJP(pc),a0
		Lea	Levl_NoEvent(pc),a1
		Move.l	a1,2(a0)
		Bra.b	ULDL_E
	*-- Find Event (A3->Address)
	ULDL_Ok:Move	d2,d3
		Add	d3,d3
		Move	12(a2,d3.w),d3
		Lea	00(a2,d3.w),a3
	*-- Write DrawList
		Lea	Levl_DrawLists(pc),a4
		Move	2(a3),d3
		Lsl	#2,d3
		Lea	GLevl_EventJP(pc),a0
		Move.l	0(a4,d3.w),2(a0)
	ULDL_E:	Rts

Levl_DrawLists:	Dc.l	Levl_NoEvent	;0
		Dc.l	Levl_BackDL	;1
		Dc.l	Levl_ScrlDL	;2
		Dc.l	Levl_RelsDL	;3
		Dc.l	Levl_SondDL	;4
		Dc.l	Levl_SongDL	;5
		Dc.l	Levl_ObjcDL	;6
		Dc.l	Levl_PlayDL	;7
		Dc.l	Levl_ScorDL	;8
		Dc.l	Levl_PaltDL	;9
		Dc.l	Levl_EndLDL	;10
*---------------
Upd_LevlAllG:	Lea	Levl_UpdAll(pc),a4
		Lea	LevlLay,a5	;###
		Jmp	Draw_All	;###
*---------------
Levl_Load:	Move.l	LevlList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Levl,d4	;###
		Move.l	#'LEVL',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Levl
		Bra.w	Load_LevlUnits
*---------------
Load_LevlUnits:	Move	#1,Cur_LevlEvent
		Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.w	LLU_End
		Move.l	(a2),a2
		Move	10(a2),d7	;Get Total
		Lea	12(a2),a3	;Get Offsets adress

	LLU_LpP:Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Upd_EventPropD
		Bsr.w	Upd_LevlEventsD
		Bsr.w	Upd_LevlDL
		Bsr.b	Upd_LevlAllG
		Movem.l	(a7)+,d0-d7/a0-a6

		Move.l	a2,a4		;Get Event
		Add	(a3)+,a4	;+
	*-- Load Units
		Move	2(a4),d0	;Get Type
		Cmp	#1,d0
		Beq.b	LLU_Bck
		Cmp	#3,d0
		Beq.b	LLU_Rel
		Cmp	#4,d0
		Beq.b	LLU_Snd
		Cmp	#5,d0
		Beq.b	LLU_Sng
		Bra.w	LLU_NTy

	LLU_Bck:Move	14(a4),d0
		Bmi.w	LLU_NTy
		Move	d0,Cur_Back
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Back_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LLU_NTy

	LLU_Rel:Move	14(a4),d0
		Cmp	#1,d0
		Beq.b	LLU_ROb
		Cmp	#2,d0
		Beq.b	LLU_RWa
		Beq.b	LLU_NTy
		
	LLU_ROb:Move	16(a4),d0
		Bmi.b	LLU_NTy
		Move	d0,Cur_Objc
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Objc_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LLU_NTy

	LLU_RWa:Bra.b	LLU_NTy

	LLU_Snd:Move	14(a4),d0
		Bmi.b	LLU_NTy
		Move	d0,Cur_Sond
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Sond_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.b	LLU_NTy

	LLU_Sng:Move	14(a4),d0
		Bmi.b	LLU_NTy
		Move	d0,Cur_Song
		Movem.l	d0-d7/a0-a6,-(a7)
		Jsr	Song_Load	;###
		Movem.l	(a7)+,d0-d7/a0-a6
		Bra.w	LLU_NTy

	LLU_NTy:
		Addq	#1,Cur_LevlEvent
		Subq	#1,d7
		Bne.w	LLU_LpP
	LLU_End:Move	#1,Cur_LevlEvent
		Bra.w	Change_Levl
*---------------
Check_Levl:	Lea	Levl_Jump(pc),a0
		Move	LevlList_Len,d0	;###
		Beq.b	CLv_NUn
	*-- Find current Object, and check if it exists
		Move.l	Mem_LevlList,a2	;###
		Move	Cur_Levl,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Object?
		Beq.b	CLv_No		;No
		Lea	Levl_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CLv_NUn:Lea	Levl_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CLv_No:	Lea	Levl_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_Levl:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Level8T
		
		Dc	'RO'
		Dc.l	Upd_EventPropD

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Levl_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Levl_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Levl_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-04,025

		Dc	'RO'
		Dc.l	Upd_LevlNameD

Levl_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Levl_Name
		Dc	'RC',049,015,-26,023
		Dc	'TX',051,022,-77,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Levl_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Levl_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

Levl_UpdAll:	Dc	'RO'
		Dc.l	Check_Levl
		Dc	'JP'
Levl_Jump:	Dc.l	Levl_No

Levl_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Levl_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Levl_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Levl_Yes:	Dc	'BX',000,028,-01,044

GLevl_Condition:Dc	'GD'
		Dc.l	$0201064b,Levl_Excl_Lists,Levl_SelectList
		Dc	'BX',003,030,015,042
		Dc	'IM',005,032,9,Im_Condition-Im

GLevl_Timer:	Dc	'GD'
		Dc.l	$0201064c,Levl_Excl_Lists,Levl_SelectList
		Dc	'BX',016,030,028,042
		Dc	'IM',018,032,9,Im_Time-Im

GLevl_Position:	Dc	'GD'
		Dc.l	$0201064d,Levl_Excl_Lists,Levl_SelectList
		Dc	'BX',029,030,041,042
		Dc	'IM',031,032,9,Im_Position-Im

		Dc	'GD'
		Dc.l	$0201000E,0,Levl_PlayScreen
		Dc	'BX',046,030,058,042
		Dc	'IM',048,032,9,Im_PlayScr-Im

		Dc	'BX',000,045,-01,061

		Dc	'GD'
		Dc.l	$02010071,01,Levl_AddEvent
		Dc	'BX',003,047,015,059
		Dc	'IM',005,049,9,Im_Background-Im

		Dc	'GD'
		Dc.l	$02010072,02,Levl_AddEvent
		Dc	'BX',016,047,028,059
		Dc	'IM',018,049,9,Im_Scroll-Im

		Dc	'GD'
		Dc.l	$02010073,03,Levl_AddEvent
		Dc	'BX',029,047,041,059
		Dc	'IM',031,049,9,Im_Release-Im

		Dc	'GD'
		Dc.l	$02010074,04,Levl_AddEvent
		Dc	'BX',042,047,054,059
		Dc	'IM',044,049,9,Im_Sound-Im

		Dc	'GD'
		Dc.l	$02010075,05,Levl_AddEvent
		Dc	'BX',055,047,067,059
		Dc	'IM',057,049,9,Im_Song-Im

		Dc	'GD'
		Dc.l	$02010076,06,Levl_AddEvent
		Dc	'BX',068,047,080,059
		Dc	'IM',070,049,9,Im_Mask-Im

		Dc	'GD'
		Dc.l	$02010077,07,Levl_AddEvent
		Dc	'BX',081,047,093,059
		Dc	'IM',083,049,9,Im_Player-Im

		Dc	'GD'
		Dc.l	$02010078,08,Levl_AddEvent
		Dc	'BX',094,047,106,059
		Dc	'IM',096,049,9,Im_Score-Im

		Dc	'GD'
		Dc.l	$02010079,09,Levl_AddEvent
		Dc	'BX',107,047,119,059
		Dc	'IM',109,049,9,Im_Palette-Im

		Dc	'GD'
		Dc.l	$0201007a,10,Levl_AddEvent
		Dc	'BX',120,047,132,059
		Dc	'IM',122,049,9,Im_Once-Im

		Dc	'GD'
		Dc.l	$0201004e,0,Levl_DelEvent
		Dc	'BX',137,047,149,059
		Dc	'IM',139,049,9,Im_ClrClips-Im

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

GLevl_CondJP:	Dc	'JP'
		Dc.l	Levl_TimDL
*---------------
GLevl_EventData:Dc	'BX',000,102,-01,171
		
GLevl_EventJP:	Dc	'JP'
		Dc.l	Levl_BackDL

Levl_Excl_Lists:Dc.l	GLevl_Condition
		Dc.l	GLevl_Timer
		Dc.l	GLevl_Position
		Dc.l	0
*---------------
Levl_TimDL:	Dc	'BX',000,062,-01,101
		Dc	'TX',003,072,-01,8
		Dc.l	Time8T

		Dc	'BX',003,073,-04,085

		Dc	'RO'
		Dc.l	Upd_LTim_TimeD

		Dc	'TX',006,082,-01,5
		Dc.l	LTim_TimeT
GLTim_Time:	Dc	'GD'
		Dc.l	$02030a00,5,LTim_Time
		Dc	'RC',-55,075,-26,083
		Dc	'TX',-52,082,-01,5
		Dc.l	LTim_TimeNT
		Dc	'GD'
		Dc.l	$02010052,LTim_Time_P,PlusMinus
		Dc	'BX',-24,075,-16,083
		Dc	'IM',-22,079,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,LTim_Time_P,PlusMinus
		Dc	'BX',-15,075,-07,083
		Dc	'IM',-13,077,5,Im_Plus-Im

		Dc	'JP'
		Dc.l	GLevl_EventData

LTim_Time_P:	Dc	1,0,32766,$0105
LTim_TimeNT:	Dc.b	'    0',0
LTim_TimeT:	Dc.b	'TIME (1/50 SEC):',0
		Even
*---------------
LTim_Time:	Bsr.w	Get_Levl_Event
		Beq.b	TT_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,4(a3)
		Bsr.b	Upd_LTim_TimeD
		Bsr.b	Upd_LTim_TimeG
		Bsr.w	Levl_SortTime
	TT_Ed:	Rts
*---------------
Upd_LTim_TimeD:	Bsr.w	Get_Levl_Event
		Beq.b	UTT_Ed
		Move	4(a3),d0
		Lea	LTim_TimeNT+5(pc),a0
		Move	#$104,d7
		Jsr	Conv			;###
	UTT_Ed:	Rts
*---------------
Upd_LTim_TimeG:	Lea	LevlLay,a5		;###
		Lea	GLTim_Time(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some		;###
*---------------
Levl_PosDL:	Dc	'BX',000,062,-01,101
		Dc	'TX',003,072,-01,8
		Dc.l	Position8T

		Dc	'BX',003,073,-04,085

		Dc	'TX',006,082,-01,5
		Dc.l	StartT

		Dc	'TX',-117,082,-01,5
		Dc.l	XT
		Dc	'GD'
		Dc.l	$02030a00,5,0
		Dc	'RC',-110,075,-81,083
		Dc	'TX',-107,082,-01,5
		Dc.l	Levl_BackXNT

		Dc	'TX',-77,082,-01,5
		Dc.l	YT
		Dc	'GD'
		Dc.l	$02030a00,5,0
		Dc	'RC',-70,075,-41,083
		Dc	'TX',-67,082,-01,5
		Dc.l	Levl_BackYNT

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-36,075,-07,083
		Dc	'TX',-33,082,-01,5
		Dc.l	PlaceT

		Dc	'JP'
		Dc.l	GLevl_EventData
*---------------
Levl_ConDL:	Dc	'BX',000,062,-01,101
		Dc	'TX',003,072,-01,8
		Dc.l	Condition8T

		Dc	'JP'
		Dc.l	GLevl_EventData
*---------------
Levl_EventsDL:	Dc	'BX',000,172,-10,-01

		Dc	'GD'
		Dc.l	$02020000,Levl_Prop_Event,Levl_Browse
		Dc	'BX',-09,172,-01,-10
		Dc	'BX',-07,175,-03,-12

		Dc	'RO'
		Dc.l	Upd_LevlEventsD

		Dc	'GD'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,176,011,184
		Dc	'IM',005,178,5,Im_Check5-Im

		Dc	'TX',017,183,-46,5
		Dc.l	0

GLevl_Event1:	Dc	'GD'
		Dc.l	$02010651,Levl_Excl_Event,Levl_Select1
		Dc	'BX',-25,174,-13,186
		Dc	'IM',-23,176,9,Im_Background-Im

		Dc	'GD'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,189,011,197
		Dc	'IM',005,191,5,Im_Check5-Im

		Dc	'TX',017,196,-46,5
		Dc.l	0

GLevl_Event2:	Dc	'GD'
		Dc.l	$02010651,Levl_Excl_Event,Levl_Select2
		Dc	'BX',-25,187,-13,199
		Dc	'IM',-23,189,9,Im_Scroll-Im

		Dc	'GD'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,202,011,210
		Dc	'IM',005,204,5,Im_Check5-Im

		Dc	'TX',017,209,-46,5
		Dc.l	0

GLevl_Event3:	Dc	'GD'
		Dc.l	$02010651,Levl_Excl_Event,Levl_Select3
		Dc	'BX',-25,200,-13,212
		Dc	'IM',-23,202,9,Im_Release-Im

		Dc	'GD'
		Dc.l	$0201006c,0,0
		Dc	'BX',003,215,011,223
		Dc	'IM',005,217,5,Im_Check5-Im

		Dc	'TX',017,222,-46,5
		Dc.l	0

GLevl_Event4:	Dc	'GD'
		Dc.l	$02010651,Levl_Excl_Event,Levl_Select4
		Dc	'BX',-25,213,-13,225
		Dc	'IM',-23,215,9,Im_Sound-Im

		Dc	'XX'

Levl_Prop_Event:Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,32767		;KnobX,Y
		Dc	0,0		;PosX,Y
Levl_Excl_Event:Dc.l	GLevl_Event1
		Dc.l	GLevl_Event2
		Dc.l	GLevl_Event3
		Dc.l	GLevl_Event4
		Dc.l	0
*---------------
Levl_BackDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_BackT

		Dc	'GD'
		Dc.l	$02010000,0,LBack_Back
		Dc	'BX',003,113,015,125
		Dc	'IM',005,115,9,Im_Background-Im

		Dc	'GD'
		Dc.l	$02010000,0,LBack_UseBack
		Dc	'BX',016,113,028,125
		Dc	'IM',018,117,5,Im_Store-Im

		Dc	'RO'
		Dc.l	LBack_UpdBkNmD

		Dc	'GD'
		Dc.l	$02010000,0,LBack_BackName
GLBack_BackName:Dc	'BX',029,113,-17,125
		Dc	'TX',032,122,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$02010000,0,LBack_RemBack
		Dc	'BX',-16,113,-04,125
		Dc	'IM',-14,115,9,Im_ClrClips-Im

		Dc	'BX',003,127,-04,139

		Dc	'TX',006,136,-01,5
		Dc.l	StartT

		Dc	'TX',-117,136,-01,5
		Dc.l	XT
		Dc	'GD'
		Dc.l	$02030a00,5,0
		Dc	'RC',-110,129,-81,137
		Dc	'TX',-107,136,-01,5
		Dc.l	Levl_BackXNT

		Dc	'TX',-77,136,-01,5
		Dc.l	YT
		Dc	'GD'
		Dc.l	$02030a00,5,0
		Dc	'RC',-70,129,-41,137
		Dc	'TX',-67,136,-01,5
		Dc.l	Levl_BackYNT

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-36,129,-07,137
		Dc	'TX',-33,136,-01,5
		Dc.l	PlaceT

		Dc	'BX',003,141,-04,153

		Dc	'TX',006,150,-01,5
		Dc.l	WipeOutT
		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-95,143,-51,151
		Dc	'TX',-92,150,-01,5
		Dc.l	FadeT
		Dc	'GD'
		Dc.l	$02030200,5,0
		Dc	'RC',-48,143,-29,151
		Dc	'TX',-45,150,-01,5
		Dc.l	Levl_WipeOutANT
		Dc	'GD'
		Dc.l	$02030200,5,0
		Dc	'RC',-26,143,-07,151
		Dc	'TX',-23,150,-01,5
		Dc.l	Levl_WipeOutBNT

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_BackXNT:	Dc.b	'    0',0
Levl_BackYNT:	Dc.b	'    0',0
Levl_BackT:	Dc.b	'Change Background:',0
WipeInT:	Dc.b	'WIPE IN:',0
WipeOutT:	Dc.b	'WIPE OUT:',0
FadeT:		Dc.b	'TRIANGLE',0
Levl_WipeOutANT:Dc.b	'  0',0
Levl_WipeOutBNT:Dc.b	'  0',0
		Even
*---------------
LBack_UpdBkNmD:	Lea	GLBack_BackName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Levl_Event
		Beq.b	LUBk_Ed
		Move	14(a3),d0
		Bmi.b	LUBk_Ed
		Ext.l	d0
		Move.l	Mem_BackList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	LUBk_Ed:Rts
*---------------
LBack_UpdBkNmG:	Lea	LevlLay,a5	;###
		Lea	GLBack_BackName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
LBack_Back:	Lea	BackLay,a5	;###
		Jmp	Open_Layer
*---------------
LBack_UseBack:	Bsr.b	LBack_UseBack_Com
		Bra.w	Upd_LevlEventsG
LBack_UseBack_Com:
		Bsr.w	Get_Levl_Event
		Beq.b	LUBk_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Back info
		Move	BackList_Len,d0		;###
		Beq.b	LUBk_E
		Jsr	Get_Back_LAdr		;###
		Tst.l	(a2)
		Beq.b	LUBk_E
		Move	Cur_Back,14(a3)		;Write Back	###
		Bsr.b	LBack_UpdBkNmD
		Bsr.b	LBack_UpdBkNmG
	LUBk_E:	Rts
*---------------
LBack_RemBack:	Bsr.w	Get_Levl_Event
		Beq.b	LRBk_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Background'	###
		Bsr.w	LBack_UpdBkNmD
		Bsr.b	LBack_UpdBkNmG
		Bsr.w	Upd_LevlEventsG
	LRBk_E:	Rts
*---------------
LBack_BackName:	Bsr.w	Get_Levl_Event
		Beq.b	LBkN_Ed
		Move	14(a3),d0
		Bmi.b	LBkN_Ed
		Move	d0,Cur_Back
		Lea	BackLay,a5	;###
		Tst.l	(a5)
		Beq.b	LBkN_Op
		Jsr	Change_Back	;###
		Lea	BackLay,a5	;###
	LBkN_Op:Jmp	Open_Layer
	LBkN_Ed:Rts
*---------------
Levl_ScrlDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_ScrlT

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_ScrlT:	Dc.b	'Change Scroll:',0
		Even
*---------------
Levl_RelsDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_RelsT

		Dc	'RO'
		Dc.l	Upd_LRUnitTypeD

GLRels_Object:	Dc	'GD'
		Dc.l	$02010691,LRels_Excl_Type,LRels_UnitType
		Dc	'BX',003,113,015,125
		Dc	'IM',005,115,9,Im_Mask-Im

GLRels_Wave:	Dc	'GD'
		Dc.l	$02010600,LRels_Excl_Type,LRels_UnitType
		Dc	'BX',016,113,028,125
		Dc	'IM',018,115,9,Im_Formation-Im

		Dc	'GD'
		Dc.l	$02010092,0,LRels_UseUnit
		Dc	'BX',029,113,041,125
		Dc	'IM',031,117,5,Im_Store-Im

		Dc	'RO'
		Dc.l	Upd_LRUNameD

		Dc	'GD'
		Dc.l	$02010093,0,LRels_UnitName
GLRels_UName:	Dc	'BX',042,113,-04,125
		Dc	'TX',045,122,-49,5
		Dc.l	0

		Dc	'TX',003,134,-01,5
		Dc.l	PositionT

		Dc	'RO'
		Dc.l	Upd_LRels_PosD

		Dc	'TX',-114,134,-01,5
		Dc.l	XT
GLRels_PosX:	Dc	'GD'
		Dc.l	$02030a00,5,LRels_PosX
		Dc	'RC',-107,127,-78,135
		Dc	'TX',-104,134,-01,5
		Dc.l	LRels_PosXNT

		Dc	'TX',-74,134,-01,5
		Dc.l	YT
GLRels_PosY:	Dc	'GD'
		Dc.l	$02030a00,5,LRels_PosY
		Dc	'RC',-67,127,-38,135
		Dc	'TX',-64,134,-01,5
		Dc.l	LRels_PosYNT

		Dc	'GD'
		Dc.l	$02010000,0,0
		Dc	'BX',-33,127,-04,135
		Dc	'TX',-30,134,-01,5
		Dc.l	PlaceT

		Dc	'JP'
		Dc.l	Levl_EventsDL



		Dc	'TX',003,120,-01,5
		Dc.l	TimeT
GLRels_Time:	Dc	'GD'
		Dc.l	$02030a00,5,0	;LRels_Time
		Dc	'RC',-52,113,-23,121
		Dc	'TX',-49,120,-01,5
		Dc.l	LRels_TimeNT
		Dc	'GD'
		Dc.l	$02010052,LRels_Time_P,PlusMinus
		Dc	'BX',-21,113,-13,121
		Dc	'IM',-19,117,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,LRels_Time_P,PlusMinus
		Dc	'BX',-12,113,-04,121
		Dc	'IM',-10,115,5,Im_Plus-Im



LRels_Excl_Type:Dc.l	GLRels_Object
		Dc.l	GLRels_Wave
		Dc.l	0

LRels_Time_P:	Dc	1,0,32766,$0105
LRels_TimeNT:	Dc.b	'    0',0
Levl_RelsT:	Dc.b	'Release Objects:',0
LRels_PosXNT:	Dc.b	'    0',0
LRels_PosYNT:	Dc.b	'    0',0
TimeT:		Dc.b	'TIME:',0
		Even
*---------------
LRels_UnitType:	Clr	d7
		Lea	GLRels_Object(pc),a0
		Btst	#0,4(a0)
		Beq.b	LRUT_Ob
		Moveq.l	#1,d7
	LRUT_Ob:
		Lea	GLRels_Wave(pc),a0
		Btst	#0,4(a0)
		Beq.b	LRUT_Wa
		Moveq.l	#2,d7
	LRUT_Wa:
		Bsr.w	Get_Levl_Event
		Beq.b	LRUT_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	d7,14(a3)	;UnitType
		Bsr.b	LRels_UseUnit
		Bsr.b	Upd_LRUnitTypeD
		Bsr.b	Upd_LRUnitTypeG
	LRUT_Ed:Rts
*---------------
Upd_LRUnitTypeD:Bsr.w	Get_Levl_Event
		Beq.b	ULRT_Ed
	*-- Decide on type
		Lea	GLRels_Object(pc),a2
		Lea	GLRels_Wave(pc),a4
		Move	14(a3),d7	;Get UnitType

		;Lea	LRels_NoneDL(pc),a1

		Bclr	#0,4(a2)
		Btst	#0,d7
		Beq.b	ULRT_Ob
		Bset	#0,4(a2)
		;Lea	LRels_ObjcDL(pc),a1
	ULRT_Ob:
		Bclr	#0,4(a4)
		Btst	#1,d7
		Beq.b	ULRT_Wa
		Bset	#0,4(a4)
		;Lea	LRels_WaveDL(pc),a1
	ULRT_Wa:
		;Lea	GLRels_TypeJump(pc),a0
		;Move.l	a1,2(a0)
	ULRT_Ed:Rts
*---------------
Upd_LRUnitTypeG:Lea	LevlLay,a5	;###
		Lea	GLRels_Object(pc),a4
		Moveq.l	#6,d7
		Jmp	Draw_Some	;###

		;Lea	WeapLay(pc),a5
		;Lea	GLRels_TypeJump(pc),a4
		;Bra.w	Draw_All
*---------------
LRels_UseUnit:	Bsr.w	Get_Levl_Event
		Beq.b	LRUU_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Decide on type
		Move	14(a3),d7	;UnitType
		Btst	#0,d7
		Bne.b	LRUU_Ob
		Btst	#1,d7
		Bne.b	LRUU_Wa
		Bra.b	LRUU_Ed
	*-- Check that Object exists
	LRUU_Ob:Move	ObjcList_Len,d0	;###
		Beq.b	LRUU_Ed
		Jsr	Get_Objc_LAdr	;###
		Tst.l	(a2)
		Beq.b	LRUU_Ed
		;Move.l	(a2),a2
		Move	Cur_Objc,16(a3)	;###
		Bra.b	LRUU_Fi
	*-- Check that Wave exists
	LRUU_Wa:Move	WaveList_Len,d0	;###
		Beq.b	LRUU_Ed
		Jsr	Get_Wave_LAdr	;###
		Tst.l	(a2)
		Beq.b	LRUU_Ed
		Move	Cur_Wave,16(a3)	;###
		Bra.w	LRUU_Fi

	LRUU_Fi:Bsr.b	Upd_LRUNameD
		Bsr.w	Upd_LRUNameG
	LRUU_Ed:Rts
*---------------
LRels_UnitName:	Bsr.w	Get_Levl_Event
		Beq.b	LRUN_Ed

		Move	14(a3),d7
		Btst	#0,d7
		Bne.b	LRUN_Ob
		Btst	#1,d7
		Bne.b	LRUN_Wa
		Bra.b	LRUN_Ed

	LRUN_Ob:Move	16(a3),d0
		Bmi.b	LRUN_NO
		Move	d0,Cur_Objc
	LRUN_NO:Lea	ObjcLay,a5	;###
		Tst.l	(a5)
		Beq.b	LRUN_OO
		Jsr	Change_Objc	;###
		Lea	ObjcLay,a5	;###
	LRUN_OO:Jmp	Open_Layer

	LRUN_Wa:Move	16(a3),d0
		Bmi.b	LRUN_NW
		Move	d0,Cur_Wave
	LRUN_NW:Lea	WaveLay,a5	;###
		Tst.l	(a5)
		Beq.b	LRUN_WO
		Jsr	Change_Wave	;###
		Lea	WaveLay,a5	;###
	LRUN_WO:Jmp	Open_Layer
		
	LRUN_Ed:Rts
*---------------
Upd_LRUNameD:	Bsr.w	Get_Levl_Event
		Beq.b	ULRN_Ed

		Move	14(a3),d7	;UnitType
		Btst	#0,d7
		Bne.b	ULRN_Ob
		Btst	#1,d7
		Bne.b	ULRN_Wa
	*-- Copy name
	ULRN_Ob:Move.l	Mem_ObjcList,a2		;###
		Bra.b	ULRN_Ok
	ULRN_Wa:Move.l	Mem_WaveList,a2		;###
		;Bra.b	ULRN_Ok
	ULRN_Ok:Lea	GLRels_UName(pc),a4
		Clr.l	20(a4)
		Move	16(a3),d0
		Bmi.b	ULRN_Ed
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a4)
	ULRN_Ed:Rts
*---------------
Upd_LRUNameG:	Lea	LevlLay,a5	;###
		Lea	GLRels_UName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
LRels_PosX:	Move	#18,d5
		Bra.b	LRPX_Cm
LRels_PosY:	Move	#20,d5
	LRPX_Cm:Bsr.w	Get_Levl_Event
		Beq.b	LRPX_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,0(a3,d5.w)
		Bsr.b	Upd_LRels_PosD
		Bsr.b	Upd_LRels_PosG
	LRPX_Ed:Rts
*---------------
Upd_LRels_PosD:	Bsr.w	Get_Levl_Event
		Beq.b	ULRP_Ed
	*-- Convert numbers
		Move	18(a3),d0
		Lea	LRels_PosXNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
		Move	20(a3),d0
		Lea	LRels_PosYNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
	ULRP_Ed:Rts
*---------------
Upd_LRels_PosG:	Lea	LevlLay,a5	;###
		Lea	GLRels_PosX(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		Lea	GLRels_PosY(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Levl_SondDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_SondT

		Dc	'GD'
		Dc.l	$0201008C,0,LSond_Sond
		Dc	'BX',003,113,015,125
		Dc	'IM',005,115,9,Im_Sound-Im

		Dc	'GD'
		Dc.l	$0201008D,0,LSond_UseSond
		Dc	'BX',016,113,028,125
		Dc	'IM',018,117,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$0201008E,0,LSond_SondName
GLSond_SondName:Dc	'BX',029,113,-17,125
		Dc	'TX',032,122,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$02010094,0,LSond_RemSond
		Dc	'BX',-16,113,-04,125
		Dc	'IM',-14,115,9,Im_ClrClips-Im

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_SondT:	Dc.b	'Play Sound:',0
		Even
*---------------
LSond_UpdSoNmD:	Lea	GLSond_SondName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Levl_Event
		Beq.b	LUSo_Ed
		Move	14(a3),d0
		Bmi.b	LUSo_Ed
		Ext.l	d0
		Move.l	Mem_SondList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	LUSo_Ed:Rts
*---------------
LSond_UpdSoNmG:	Lea	LevlLay,a5	;###
		Lea	GLSond_SondName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
LSond_Sond:	Lea	SondLay,a5	;###
		Jmp	Open_Layer
*---------------
LSond_UseSond:	Bsr.b	LSond_UseSond_Com
		Bra.w	Upd_LevlEventsG
LSond_UseSond_Com:
		Bsr.w	Get_Levl_Event
		Beq.b	LUSo_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Sound info
		Move	SondList_Len,d0		;###
		Beq.b	LUSo_E
		Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	LUSo_E
		Move	Cur_Sond,14(a3)		;Write Sound	###
		Bsr.b	LSond_UpdSoNmD
		Bsr.b	LSond_UpdSoNmG
	LUSo_E:	Rts
*---------------
LSond_RemSond:	Bsr.w	Get_Levl_Event
		Beq.b	LRSo_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Sound'	###
		Bsr.w	LSond_UpdSoNmD
		Bsr.b	LSond_UpdSoNmG
		Bsr.w	Upd_LevlEventsG
	LRSo_E:	Rts
*---------------
LSond_SondName:	Bsr.w	Get_Levl_Event
		Beq.b	LSoN_Ed
		Move	14(a3),d0
		Bmi.b	LSoN_Ed
		Move	d0,Cur_Sond
		Lea	SondLay,a5	;###
		Tst.l	(a5)
		Beq.b	LSoN_Op
		Bsr.w	Change_Sond
		Lea	SondLay,a5	;###
	LSoN_Op:Jmp	Open_Layer
	LSoN_Ed:Rts
*---------------
Levl_SongDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_SongT

		Dc	'GD'
		Dc.l	$020100B4,0,LSong_Song
		Dc	'BX',003,113,015,125
		Dc	'IM',005,115,9,Im_Song-Im

		Dc	'GD'
		Dc.l	$020100B5,0,LSong_UseSong
		Dc	'BX',016,113,028,125
		Dc	'IM',018,117,5,Im_Store-Im

		Dc	'RO'
		Dc.l	LSong_UpdSgNmD

		Dc	'GD'
		Dc.l	$020100B6,0,LSong_SongName
GLSong_SongName:Dc	'BX',029,113,-17,125
		Dc	'TX',032,122,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$020100B7,0,LSong_RemSong
		Dc	'BX',-16,113,-04,125
		Dc	'IM',-14,115,9,Im_ClrClips-Im

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_SongT:	Dc.b	'Change Song:',0
		Even
*---------------
LSong_UpdSgNmD:	Lea	GLSong_SongName(pc),a5
		Clr.l	20(a5)
		Bsr.w	Get_Levl_Event
		Beq.b	LUSg_Ed
		Move	14(a3),d0
		Bmi.b	LUSg_Ed
		Ext.l	d0
		Move.l	Mem_SongList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	LUSg_Ed:Rts
*---------------
LSong_UpdSgNmG:	Lea	LevlLay,a5	;###
		Lea	GLSong_SongName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
LSong_Song:	Lea	SongLay,a5	;###
		Jmp	Open_Layer
*---------------
LSong_UseSong:	Bsr.b	LSong_UseSong_Com
		Bra.w	Upd_LevlEventsG
LSong_UseSong_Com:
		Bsr.w	Get_Levl_Event
		Beq.b	LUSg_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Song info
		Move	SongList_Len,d0		;###
		Beq.b	LUSg_E
		Bsr.w	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	LUSg_E
		Move	Cur_Song,14(a3)		;Write Song	###
		Bsr.b	LSong_UpdSgNmD
		Bsr.b	LSong_UpdSgNmG
		Bsr.w	Upd_LevlEventsG
	LUSg_E:	Rts
*---------------
LSong_RemSong:	Bsr.w	Get_Levl_Event
		Beq.b	LRSg_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Song'	###
		Bsr.w	LSong_UpdSgNmD
		Bsr.b	LSong_UpdSgNmG
		Bsr.w	Upd_LevlEventsG
	LRSg_E:	Rts
*---------------
LSong_SongName:	Bsr.w	Get_Levl_Event
		Beq.b	LSgN_Ed
		Move	14(a3),d0
		Bmi.b	LSgN_Ed
		Move	d0,Cur_Song
		Lea	SongLay,a5	;###
		Tst.l	(a5)
		Beq.b	LSgN_Op
		Bsr.w	Change_Song
		Lea	SongLay,a5	;###
	LSgN_Op:Jmp	Open_Layer
	LSgN_Ed:Rts
*---------------
Levl_ObjcDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_ObjcT

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_ObjcT:	Dc.b	'Change Object:',0
		Even
*---------------
Levl_PlayDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_PlayT

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_PlayT:	Dc.b	'Change Player:',0
		Even
*---------------
Levl_ScorDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_ScorT

		Dc	'TX',003,120,-01,5
		Dc.l	LivesT
		Dc	'GD'
		Dc.l	$02010200,0,0	;LScor_Delta
		Dc	'BX',-52,113,-44,121
		Dc	'IM',-51,115,5,Im_Delta-Im
GLScor_Lives:	Dc	'GD'
		Dc.l	$02030a00,3,0	;LScor_Lives
		Dc	'RC',-42,113,-23,121
		Dc	'TX',-39,120,-01,5
		Dc.l	LScor_LivesNT
		Dc	'GD'
		Dc.l	$02010052,LScor_Lives_P,PlusMinus
		Dc	'BX',-21,113,-13,121
		Dc	'IM',-19,117,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,LScor_Lives_P,PlusMinus
		Dc	'BX',-12,113,-04,121
		Dc	'IM',-10,115,5,Im_Plus-Im

		Dc	'JP'
		Dc.l	Levl_EventsDL

LScor_Lives_P:	Dc	1,-99,99,$8105
Levl_ScorT:	Dc.b	'Change Score Data:',0
LivesT:		Dc.b	'LIVES:',0
LScor_LivesNT:	Dc.b	' +1',0
		Even
*---------------
Levl_PaltDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_PaltT

		Dc	'GD'
		Dc.l	$02010000,0,LPalt_Palt
		Dc	'BX',003,113,015,125
		Dc	'IM',005,115,9,Im_Palette-Im

		Dc	'GD'
		Dc.l	$02010000,0,LPalt_UsePalt
		Dc	'BX',016,113,028,125
		Dc	'IM',018,117,5,Im_Store-Im

		Dc	'GD'
		Dc.l	$02010000,0,LPalt_PaltName
GLPalt_PaltName:Dc	'BX',029,113,-17,125
		Dc	'TX',032,122,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$02010000,0,LPalt_RemPalt
		Dc	'BX',-16,113,-04,125
		Dc	'IM',-14,115,9,Im_ClrClips-Im

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_PaltT:	Dc.b	'Change Palette:',0
		Even
*---------------
Get_Levl_Event:	Move	LevlList_Len,d0	;###
		Beq.b	GLE_No
		Bsr.w	Get_Levl_LAdr
		Tst.l	(a2)
		Beq.b	GLE_No
		Move.l	(a2),a3
		Move	Cur_LevlEvent(pc),d0
		Bmi.b	GLE_No
		Add	d0,d0
		Move	12(a3,d0.w),d0
		Lea	00(a3,d0.w),a3
		Moveq.l	#1,d0
		Rts
	GLE_No:	Clr.l	d0
		Rts
*---------------
LPalt_UpdPaNmD:	Lea	GLPalt_PaltName(pc),a5
		Clr.l	20(a5)
		Bsr.b	Get_Levl_Event
		Beq.b	LUPa_Ed
		Move	14(a3),d0
		Bmi.b	LUPa_Ed
		Ext.l	d0
		Move.l	Mem_PaltList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a5)
	LUPa_Ed:Rts
*---------------
LPalt_UpdPaNmG:	Lea	LevlLay,a5	;###
		Lea	GLPalt_PaltName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
LPalt_Palt:	Lea	PaltLay,a5	;###
		Jmp	Open_Layer
*---------------
LPalt_UsePalt:	Bsr.b	LPalt_UsePalt_Com
		Bra.w	Upd_LevlEventsG
LPalt_UsePalt_Com:
		Bsr.b	Get_Levl_Event
		Beq.b	LUPa_E
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Palette info
		Move	PaltList_Len,d0		;###
		Beq.b	LUPa_E
		Bsr.w	Get_Palt_LAdr
		Tst.l	(a2)
		Beq.b	LUPa_E
		Move	Cur_Palt,14(a3)		;Write Palette	###
		Bsr.b	LPalt_UpdPaNmD
		Bsr.b	LPalt_UpdPaNmG
	LUPa_E:	Rts
*---------------
LPalt_RemPalt:	Bsr.w	Get_Levl_Event
		Beq.b	LRPa_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move	#-1,14(a3)		;Write 'No Palette'	###
		Bsr.w	LPalt_UpdPaNmD
		Bsr.b	LPalt_UpdPaNmG
		Bsr.w	Upd_LevlEventsG
	LRPa_E:	Rts
*---------------
LPalt_PaltName:	Bsr.w	Get_Levl_Event
		Beq.b	LPaN_Ed
		Move	14(a3),d0
		Bmi.b	LPaN_Ed
		Move	d0,Cur_Palt
		Lea	PaltLay,a5	;###
		Tst.l	(a5)
		Beq.b	LPaN_Op
		Bsr.w	Change_Palt
		Lea	PaltLay,a5	;###
	LPaN_Op:Jmp	Open_Layer
	LPaN_Ed:Rts
*---------------
Levl_EndLDL:	Dc	'TX',003,112,-01,8
		Dc.l	Levl_EndLT

		Dc	'GD'
		Dc.l	$02010000,0,0	;LEndL_Levl
		Dc	'BX',003,113,015,125
		Dc	'IM',005,115,9,Im_Level-Im

		Dc	'GD'
		Dc.l	$02010000,0,0	;LEndL_UseLevl
		Dc	'BX',016,113,028,125
		Dc	'IM',018,117,5,Im_Store-Im

		;Dc	'RO'
		;Dc.l	LEndL_UpdLvNmD

		Dc	'GD'
		Dc.l	$02010000,0,0	;LEndL_LevlName
GLEndL_LevlName:Dc	'BX',029,113,-17,125
		Dc	'TX',032,122,-49,5
		Dc.l	0

		Dc	'GD'
		Dc.l	$02010000,0,0	;LEndL_RemLevl
		Dc	'BX',-16,113,-04,125
		Dc	'IM',-14,115,9,Im_ClrClips-Im

		Dc	'JP'
		Dc.l	Levl_EventsDL

Levl_EndLT:	Dc.b	'End Of Level:',0
		Even
*---------------
Levl_NoEvent:	Dc	'JP'
		Dc.l	Levl_EventsDL
*---------------
Levl_ScrnT:	Dc.b	'Change Screen:',0
Levl_EffcT:	Dc.b	'Effect:',0
		Even
*=======================================================================*
*				 W A V E				*
*=======================================================================*
Wave_New:	Lea	WaveList,a4	;###
		Lea	New_Wave(pc),a2
		Jsr	Unit_New	;###
		Move	d7,Cur_Wave
		Move	#1,Cur_WaveEvent
		Bsr.w	Wave_UseObjc
		Bra.b	Change_Wave
New_Wave:	Dc	0	;Id		00
		Dc.l	24	;Size		02
		Dc	1	;Total		06
	;Event:
		Dc	-1	;Object		00
		Dc	0	;OffsetX	02
		Dc	0	;OffsetY	04
		Blk.b	10,0	;06
*---------------
Change_Wave:	Bsr.b	Upd_WaveNameD
		Bsr.b	Upd_WaveNameG

		Move	#1,Cur_WaveEvent
		Bsr.b	Upd_WaveAllG
		Bsr.w	Change_WaveEvent

		Lea	Wave_Info,a3	;###
		Jmp	Upd_SelcUnit	;###
*---------------
Upd_WaveAllG:	Lea	Wave_UpdAll(pc),a4
		Lea	WaveLay,a5	;###
		Jmp	Draw_All	;###
*---------------
Wave_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Upd_WaveNameD:	Lea	Wave_Info,a3	;###
		Lea	Wave_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_WaveNameG:	Lea	WaveLay,a5	;###
		Lea	Wave_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Get_Wave_LAdr:	Move.l	Mem_WaveList,a2	;###
		Clr.l	d0
		Move	Cur_Wave,d0	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Wave_PrvObject:	Subq	#1,Cur_WaveEvent
		Bra.w	Change_WaveEvent
*---------------
Wave_NxtObject:	Addq	#1,Cur_WaveEvent
		Bra.w	Change_WaveEvent
*---------------
Upd_WaveNumbD:	Move	WaveList_Len,d0	;###
		Beq.b	UWaN_Ed
		Bsr.b	Get_Wave_LAdr
		Tst.l	(a2)
		Beq.b	UWaN_Ed
		Move.l	(a2),a0
		Move	6(a0),d0
		Lea	Wave_ObjectsNT+2(pc),a0
		Move	#$101,d7
		Jsr	Conv	;###
	*-- Current Object
		Bsr.b	Get_Wave_LAdr
		Move.l	(a2),a0
		Cmp	#1,Cur_WaveEvent
		Bge.b	UWaN_NU
		Move	6(a0),d0
		Move	d0,Cur_WaveEvent
	UWaN_NU:Move	6(a0),d0
		Cmp	Cur_WaveEvent(pc),d0
		Bge.b	UWaN_NO
		Move	#1,Cur_WaveEvent
	UWaN_NO:Move	Cur_WaveEvent(pc),d0
		Lea	Wave_ObjectNT+2(pc),a0
		Move	#$101,d7
		Jsr	Conv	;###
	UWaN_Ed:Rts
*---------------
Upd_WaveNumbG:	Lea	WaveLay,a5	;###
		Lea	Wave_ObjectsUpd(pc),a4
		Moveq.l	#1,d7
		Jsr	Draw_Some	;###

		Lea	Wave_ObjectUpd(pc),a4
		Moveq.l	#1,d7
		Jmp	Draw_Some	;###
*---------------
Update_WaveBuf:	Lea	Wave_Info,a3	;###
		Jmp	Update_UnitBuf	;###
*---------------
Wave_AddEvent:	Bsr.w	Get_Wave_LAdr
		Tst.l	(a2)
		Beq.b	WAE_End
		Move.l	a2,WAE_ListAdr
		Bsr.b	Update_WaveBuf
		Move.l	Mem_WaveBuf,a2		;Get buffer address ###
		Move	6(a2),d0		;Total
		Move	d0,WAE_Loc
	*-- Free old Object
		Move.l	WAE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_WaveBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Add	#16,d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	WAE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	WAE_NEr
		Jmp	Mess_MemErr		;###
	WAE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_WaveBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Add	#16,d0			;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Addq	#1,d7			;+
		Move	d7,(a1)+		;+
	*-- Copy Events
		Clr	d0
	WAE_CEL:Cmp	d0,d7
		Beq.b	WAE_End
		Cmp	WAE_Loc(pc),d0		;Insert Event here?
		Beq.b	WAE_AE
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Addq	#1,d0
		Bra.b	WAE_CEL
	WAE_End:Bsr.w	Wave_UseObjc
		Bra.w	Change_WaveEvent
	*-- Add Event
	WAE_AE:	Move	#-1,(a1)+	;Object
		Clr.l	(a1)+		;OffsetX,OffsetY
		Clr	(a1)+
		Clr.l	(a1)+
		Clr.l	(a1)+
		Move	WAE_Loc(pc),d1
		Addq	#1,d1
		Move	d1,Cur_WaveEvent
		Addq	#1,d0
		Bra.b	WAE_CEL
WAE_Loc:	Dc	0
WAE_ListAdr:	Dc.l	0
Cur_WaveEvent:	Dc	1
*---------------
Wave_DelEvent:	Bsr.w	Get_Wave_LAdr
		Tst.l	(a2)
		Beq.w	WDE_End
		Move.l	a2,WDE_ListAdr
		Bsr.w	Update_WaveBuf
		Move.l	Mem_WaveBuf,a2		;Get buffer address	###
		Cmp	#1,6(a2)
		Ble.b	WDE_End
		Move	Cur_WaveEvent(pc),d0
		Subq	#1,d0
		Move	d0,WDE_Loc
		Bmi.b	WDE_End
	*-- Free old Object
		Move.l	WDE_ListAdr(pc),a4
		Jsr	Free_Unit		;###
	*-- Allocate new space for Object
		Move.l	Mem_WaveBuf,a2		;Get buffer address ###
		Move.l	2(a2),d0		;BytSize
		Sub	#16,d0
		Moveq.l	#0,d1			;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Move.l	WDE_ListAdr(pc),a0
		Move.l	d0,(a0)
		Bne.b	WDE_NEr
		Jmp	Mess_MemErr		;###
	WDE_NEr:Or	#2,4(a0)		;Set NeedsUpdate
	*-- Get Addresses
		Move.l	(a0),a1			;Get Object address
		Move.l	Mem_WaveBuf,a2		;Get buffer address ###
	*-- Copy general data
		Move	(a2)+,(a1)+		;Id
		Move.l	(a2)+,d0		;BytSize
		Sub	#16,d0			;+
		Move.l	d0,(a1)+		;+
		Move	(a2)+,d7		;Total
		Subq	#1,d7			;+
		Move	d7,(a1)+		;+
	*-- Copy Events
		Clr	d0
		Addq	#1,d7
	WDE_CEL:Cmp	d0,d7
		Beq.b	WDE_End
		Cmp	WDE_Loc(pc),d0		;Delete this Event?
		Beq.b	WDE_DE
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Move.l	(a2)+,(a1)+
		Addq	#1,d0
		Bra.b	WDE_CEL
	WDE_End:Move	#1,Cur_WaveEvent
		Bra.b	Change_WaveEvent
	*-- Delete Event
	WDE_DE:	Add	#16,a2		;Skip Event!
		Addq	#1,d0
		Bra.b	WDE_CEL
WDE_Loc:	Dc	0
WDE_ListAdr:	Dc.l	0
*---------------
Change_WaveEvent:
		Bsr.w	Upd_WaveNumbD
		Bsr.w	Upd_WaveNumbG
		Bsr.w	Upd_WONameD
		Bsr.w	Upd_WONameG
		Bsr.w	Upd_Wave_OffsD
		Bsr.w	Upd_Wave_OffsG
		Bsr.b	Upd_Wave_TimeD
		Bsr.b	Upd_Wave_TimeG
		Rts
*---------------
Wave_Objc:	Lea	ObjcLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Wave_Time:	Bsr.w	Get_WaveEvent
		Beq.b	WaT_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,6(a1)
		Bsr.b	Upd_Wave_TimeD
		Bsr.b	Upd_Wave_TimeG
	WaT_Ed:	Rts
*---------------
Upd_Wave_TimeD:	Bsr.w	Get_WaveEvent
		Beq.b	UWaT_E
		Move	06(a1),d0	;Time
		Lea	Wave_TimeNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
	UWaT_E:	Rts
*---------------
Upd_Wave_TimeG:	Lea	WaveLay,a5	;###
		Lea	GWave_Time(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Wave_OffsetX:	Move	#02,d5
		Bra.b	WaOX_Cm
Wave_OffsetY:	Move	#04,d5
	WaOX_Cm:Bsr.b	Get_WaveEvent
		Beq.b	WaOX_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	Convert_Value,d0	;###
		Move	d0,0(a1,d5.w)
		Bsr.b	Upd_Wave_OffsD
		Bsr.b	Upd_Wave_OffsG
	WaOX_Ed:Rts
*---------------
Upd_Wave_OffsD:	Bsr.b	Get_WaveEvent
		Beq.b	UWaO_E
	*-- Convert numbers
		Move	02(a1),d0	;XOffset
		Lea	Wave_OffsetXNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
		Move	04(a1),d0	;YOffset
		Lea	Wave_OffsetYNT+5(pc),a0
		Move	#$8104,d7
		Jsr	Conv	;###
	UWaO_E:	Rts
*---------------
Upd_Wave_OffsG:	Lea	WaveLay,a5	;###
		Lea	GWave_OffsetX(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
		
		Lea	GWave_OffsetY(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Get_WaveEvent:	
	*-- Find Wave
		Bsr.w	Get_Wave_LAdr
		Tst.l	(a2)
		Beq.b	GWE_End
		Move.l	(a2),a1
	*-- Find Event (A1->Address)
		Move	Cur_WaveEvent(pc),d0
		Subq	#1,d0
		Lsl	#4,d0			;Multiply by 16
		Lea	08(a1,d0.w),a1
		Moveq.l	#1,d0
		Rts
	GWE_End:Moveq.l	#0,d0
		Rts
*---------------
Wave_UseObjc:	Bsr.b	Get_WaveEvent
		Beq.b	WUO_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Object data
		Jsr	Get_Objc_LAdr	;###
		Tst.l	(a2)
		Beq.b	WUO_Ed
		Move	Cur_Objc,(a1)		;Write Object number ;###
		Bsr.w	Change_WaveEvent
	WUO_Ed:	Rts
*---------------
Wave_RemoveObjc:Bsr.b	Get_WaveEvent
		Beq.b	WRO_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
	*-- Store new Object data
		Move	#-1,(a1)		;Write 'Empty'
		Bsr.w	Change_WaveEvent
	WRO_Ed:	Rts
*---------------
Wave_ObjcName:	Bsr.b	Get_WaveEvent
		Beq.b	WON_Ed
		Move	(a1),d0		;Get Object number
		Bmi.b	WON_No
		Move	d0,Cur_Objc
	WON_No:	Lea	ObjcLay,a5	;###
		Tst.l	(a5)
		Beq.b	WON_Op
		Jsr	Change_Objc	;###
		Lea	ObjcLay,a5	;###
	WON_Op:	Jmp	Open_Layer	;###
	WON_Ed:	Rts
*---------------
Upd_WONameD:	Bsr.b	Get_WaveEvent
		Beq.b	UWO_End
	*-- Copy name
		Lea	GWave_WOName(pc),a3
		Clr.l	20(a3)
		Move	(a1),d0
		Bmi.b	UWO_End
		Ext.l	d0
		Move.l	Mem_ObjcList,a2		;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	UWO_End:Rts
*---------------
Upd_WONameG:	Lea	WaveLay,a5	;###
		Lea	GWave_WOName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Wave_Load:	Move.l	WaveList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Wave,d4	;###
		Move.l	#'WAVE',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Wave
		Bra.w	Load_WaveUnits
*---------------
Load_WaveUnits:	;Move	#1,Cur_WaveEvent
		Bsr.w	Get_Wave_LAdr
		Tst.l	(a2)
		Beq.b	LWaU_Ed
		Move.l	(a2),a2
		;Move	10(a2),d7	;Get Total

	LWaU_Ed:;Move	#1,Cur_WaveEvent
		Bra.w	Change_Wave
*---------------
Check_Wave:	Lea	Wave_Jump(pc),a0
		Move	WaveList_Len,d0	;###
		Beq.b	CWa_NUn
	*-- Find current Object, and check if it exists
		Move.l	Mem_WaveList,a2	;###
		Move	Cur_Wave,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Object?
		Beq.b	CWa_No		;No
		Lea	Wave_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CWa_NUn:Lea	Wave_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CWa_No:	Lea	Wave_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_Wave:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Wave8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Wave_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Wave_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Wave_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-04,025

		Dc	'RO'
		Dc.l	Upd_WaveNameD

Wave_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Wave_Name
		Dc	'RC',049,015,-26,023
		Dc	'TX',051,022,-77,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Wave_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Wave_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

Wave_UpdAll:	Dc	'RO'
		Dc.l	Check_Wave
		Dc	'JP'
Wave_Jump:	Dc.l	Wave_No

Wave_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Wave_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Wave_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Wave_Yes:	Dc	'BX',000,028,-01,057

		Dc	'BX',000,058,-01,070

		Dc	'RO'
		Dc.l	Upd_WaveNumbD

		Dc	'TX',003,069,-01,8
		Dc.l	Wave_Object8T
		Dc	'GD'
		Dc.l	$02030a00,2,0
		Dc	'RC',-84,060,-70,068
Wave_ObjectUpd:	Dc	'TX',-81,067,-01,5
		Dc.l	Wave_ObjectNT
		Dc	'GD'
		Dc.l	$02010000,0,Wave_PrvObject
		Dc	'BX',-68,060,-60,068
		Dc	'IM',-66,064,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010000,0,Wave_NxtObject
		Dc	'BX',-59,060,-51,068
		Dc	'IM',-57,062,5,Im_Plus-Im

		Dc	'TX',-48,067,-01,5
		Dc.l	OfT
		Dc	'GD'
		Dc.l	$02030a00,2,0
		Dc	'RC',-37,060,-23,068
Wave_ObjectsUpd:Dc	'TX',-34,067,-01,5
		Dc.l	Wave_ObjectsNT
		Dc	'GD'
		Dc.l	$02010000,0,Wave_DelEvent
		Dc	'BX',-21,060,-13,068
		Dc	'IM',-19,064,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010000,0,Wave_AddEvent
		Dc	'BX',-12,060,-04,068
		Dc	'IM',-10,062,5,Im_Plus-Im

		Dc	'BX',000,071,-01,-01

		Dc	'TX',003,080,-01,5
		Dc.l	TimeT
		Dc	'RO'
		Dc.l	Upd_Wave_TimeD

GWave_Time:	Dc	'GD'
		Dc.l	$02030a00,5,Wave_Time
		Dc	'RC',-52,073,-23,081
		Dc	'TX',-49,080,-01,5
		Dc.l	Wave_TimeNT
		Dc	'GD'
		Dc.l	$02010052,Wave_Time_P,PlusMinus
		Dc	'BX',-21,073,-13,081
		Dc	'IM',-19,077,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Wave_Time_P,PlusMinus
		Dc	'BX',-12,073,-04,081
		Dc	'IM',-10,075,5,Im_Plus-Im

		Dc	'GD'
		Dc.l	$02010000,0,Wave_Objc
		Dc	'BX',003,083,015,095
		Dc	'IM',005,085,9,Im_Mask-Im
		Dc	'GD'
		Dc.l	$02010000,0,Wave_UseObjc
		Dc	'BX',016,083,028,095
		Dc	'IM',018,087,5,Im_Store-Im
		Dc	'RO'
		Dc.l	Upd_WONameD
		Dc	'GD'
		Dc.l	$02010000,0,Wave_ObjcName
GWave_WOName:	Dc	'BX',029,083,-17,095
		Dc	'TX',032,092,-49,5
		Dc.l	0
		Dc	'GD'
		Dc.l	$02010000,0,Wave_RemoveObjc
		Dc	'BX',-16,083,-04,095
		Dc	'IM',-14,085,9,Im_ClrClips-Im

		Dc	'TX',003,104,-01,5
		Dc.l	OffsetT
		Dc	'RO'
		Dc.l	Upd_Wave_OffsD
		
		Dc	'TX',-120,104,-01,5
		Dc.l	XT
GWave_OffsetX:	Dc	'GD'
		Dc.l	$02030a00,5,Wave_OffsetX
		Dc	'RC',-112,097,-83,105
		Dc	'TX',-109,104,-01,5
		Dc.l	Wave_OffsetXNT
		Dc	'GD'
		Dc.l	$02010052,Wave_Offset_P,PlusMinus
		Dc	'BX',-81,097,-73,105
		Dc	'IM',-79,101,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Wave_Offset_P,PlusMinus
		Dc	'BX',-72,097,-64,105
		Dc	'IM',-70,099,5,Im_Plus-Im

		Dc	'TX',-60,104,-01,5
		Dc.l	YT
GWave_OffsetY:	Dc	'GD'
		Dc.l	$02030a00,5,Wave_OffsetY
		Dc	'RC',-52,097,-23,105
		Dc	'TX',-49,104,-01,5
		Dc.l	Wave_OffsetYNT
		Dc	'GD'
		Dc.l	$02010052,Wave_Offset_P,PlusMinus
		Dc	'BX',-21,097,-13,105
		Dc	'IM',-19,101,1,Im_Minus-Im
		Dc	'GD'
		Dc.l	$02010053,Wave_Offset_P,PlusMinus
		Dc	'BX',-12,097,-04,105
		Dc	'IM',-10,099,5,Im_Plus-Im

		Dc	'XX'

Wave_Time_P:	Dc	1,0,32767,$8103
Wave_Offset_P:	Dc	1,-9999,9999,$8103

Wave_Object8T:	Dc.b	'Object:',0
Wave_ObjectNT:	Dc.b	' 0',0
Wave_ObjectsNT:	Dc.b	' 0',0
Wave_TimeNT:	Dc.b	'    0',0
Wave_OffsetXNT:	Dc.b	'    0',0
Wave_OffsetYNT:	Dc.b	'    0',0
*=======================================================================*
*				S O U N	D				*
*=======================================================================*
Sond_New:	Bsr.w	Get_Smpl_LAdr
		Tst.l	(a2)
		Beq.w	SN_Ed
	*-- Get list space
		Lea	SondList,a4	;###
		Jsr	Find_Unit_Space	;### This routine saves regs
		Move.l	a0,SN_LstA
		Bne.b	SN_NEr1
		Jmp	Mess_MemErr	;###
	*-- Allocate memory
	SN_NEr1:Moveq.l	#30,d0		;ByteSize
		Moveq.l	#0,d1		;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Tst.l	d0
		Bne.b	SN_NEr2
		Jmp	Mess_MemErr	;###
	SN_NEr2:Move	d7,Cur_Sond
	*-- Write to list
		Move.l	SN_LstA(pc),a5
		Move.l	d0,(a5)
		Move	#%111,04(a5)	;Set Flags = New
		Move.l	a5,a0
		Jsr	Unnamed		;###
	*-- Store new Unit
		Bsr.w	Get_Smpl_LAdr
		Tst.l	(a2)
		Beq.b	SN_Ed
		Move.l	(a2),a2
		Lea	6(a2),a3
		Move.l	(a5),a1		;Get Sound Address
		Clr	(a1)+		;Write Id
		Move.l	#30,(a1)+	;Write BytSize
		Move	(a3)+,(a1)+	;Copy Flags
		Move	(a3)+,(a1)+	;Copy Frequency
		Move	(a3)+,(a1)+	;Copy Volume
		Move.l	(a3)+,(a1)+	;Copy LoopStart
		Move.l	(a3)+,(a1)+	;Copy LoopEnd
		Clr.l	(a1)+		;Write StartPoint
		Move.l	2(a2),d0	;Write EndPoint
		Sub.l	#20,d0		;+
		Move.l	d0,(a1)+	;+
		Move	Cur_Smpl,(a1)+	;Write Sample	###
		Bra.b	Change_Sond
	SN_Ed:	Rts
	SN_LstA:Dc.l	0
*---------------
Change_Sond:	Bsr.w	Upd_SondNameD
		Bsr.w	Upd_SondNameG
		Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	CS_End
		Bsr.w	Upd_SondButtD
		Bsr.w	Conv_Freq
		Bsr.b	Upd_SSNameD

		Bsr.w	Upd_SondVolD

		Move.l	#0,DS_Offset
		Bsr.w	Get_Sond_LAdr
		Move.l	(a2),a2
		Move	28(a2),d0
		Ext.l	d0
		Move.l	Mem_SmplList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move.l	(a2),a2
		Move.l	2(a2),d0
		Sub.l	#20,d0
		Move.l	d0,DS_Length

		Move	#-1,SMR_X1

		Lea	SondLay,a5	;###
		Lea	Sond_UpdAll(pc),a4
		Jsr	Draw_All	;###

		Lea	Sond_Info,a3	;###
		Jsr	Upd_SelcUnit	;###
	CS_End:	Rts
*---------------
Upd_SSNameD:
	*-- Update name to drawlist
		Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	USS_End
		Move.l	(a2),a2
		Lea	GSond_SmplName(pc),a3
		Clr.l	20(a3)
		Move	28(a2),d0
		Bmi.b	USS_End
		Ext.l	d0
		Move.l	Mem_SmplList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	USS_End:Rts
*---------------
Upd_SSNameG:	Lea	SondLay,a5	;###
		Lea	GSond_SmplName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Upd_SondNameD:	Lea	Sond_Info,a3	;###
		Lea	Sond_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_SondNameG:	Lea	SondLay,a5	;###
		Lea	Sond_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Upd_SmplNameD:	Lea	Smpl_Info,a3	;###
		Lea	Smpl_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_SmplNameG:	Lea	SmplLay,a5	;###
		Lea	Smpl_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Sond_UseSample:
	*-- Find Sound
		Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	SUS_Ed
		Or	#2,4(a2)	;Set NeedsUpdate
		Move.l	(a2),a1
	*-- Store new Sound data
		Bsr.w	Get_Smpl_LAdr
		Tst.l	(a2)
		Beq.b	SUS_Ed
		Move.l	(a2),a2
		Lea	6(a2),a3
		Clr	(a1)+		;Write Id
		Move.l	#30,(a1)+	;Write BytSize
		Move	(a3)+,(a1)+	;Copy Flags
		Move	(a3)+,(a1)+	;Copy Frequency
		Move	(a3)+,(a1)+	;Copy Volume
		Move.l	(a3)+,(a1)+	;Copy LoopStart
		Move.l	(a3)+,(a1)+	;Copy LoopEnd
		Clr.l	(a1)+		;Write StartPoint
		Move.l	2(a2),d0	;Write EndPoint
		Sub.l	#20,d0		;+
		Move.l	d0,(a1)+	;+
		Move	Cur_Smpl,(a1)+	;Write Sample	###
		Bra.w	Change_Sond
	SUS_Ed:	Rts
*---------------
Sond_SampleName:Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	SS_Ed
		Move.l	(a2),a2
		Move	28(a2),Cur_Smpl
		Lea	SmplLay,a5	;###
		Tst.l	(a5)
		Beq.b	SS_Op
		Bsr.w	Change_Smpl
		Lea	SmplLay,a5	;###
	SS_Op:	Jmp	Open_Layer
	SS_Ed:	Rts
*---------------
Sond_Sample:	Lea	SmplLay,a5	;###
		Jmp	Open_Layer
*---------------
Sond_Loop:	Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	SL_End
		Or	#2,4(a2)	;Set NeedsUpdate
		Move.l	(a2),a0
		Clr.b	SL_Lop
		Tst	6(a0)
		Bpl.b	SL_NLp
		Move.b	#1,SL_Lop
	SL_NLp:	Lea	SL_Lop(pc),a2
		Lea	Sond_LoopUpd(pc),a0
		Lea	SL_Lst(pc),a1
		Jsr	Gd_Choice	;###

		Bsr.w	Get_Sond_LAdr
		Move.l	(a2),a0
		Move	6(a0),d1
		Bclr	#15,d1
		Move.b	SL_Lop(pc),d0
		Beq.b	SL_NLp2
		Bset	#15,d1
	SL_NLp2:Move	d1,6(a0)
	SL_End:	Rts
	SL_Lst:	Dc	Im_Once-Im	;0
		Dc	Im_Loop-Im	;1
		Dc	0
	SL_Lop:	Dc	0
*---------------
Sond_VolumeN:	Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	SdVN_E
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a2
		Move.l	Convert_Value,d1	;###
		Bpl.b	SdVN_NU
		Moveq.l	#0,d1
	SdVN_NU:Cmp	#100,d1
		Ble.b	SdVN_NO
		Moveq.l	#100,d1
	SdVN_NO:Mulu	#65535,d1
		Divu	#100,d1
		Move	d1,10(a2)
		Bsr.b	Upd_SondVolD
		Bsr.b	Upd_SondVolG
	SdVN_E:	Rts
*---------------
Upd_SondVolD:	Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Move.l	(a2),a2
		Beq.b	USdV_E

		Move	10(a2),d0	;Volume
		Mulu	#101,d0
		Swap	d0

		Lea	Sond_VolN_T+3(pc),a0
		Move	#$0102,d7
		Jsr	Conv	;###

		Lea	GSond_Vol(pc),a0
		Move.l	6(a0),a0	;Pointer
	*-- Calc move space
		Clr	d0
		Sub	2(a0),d0	;%KnobX
	*-- Conv from word to move space
		Move	10(a2),d1	;Volume
		Mulu	d1,d0
		Swap	d0
		Move	d0,6(a0)	;%PosX
	*-- Convert from word to 0-64
		Mulu	#64,d1
		Swap	d1
		Move	d1,$dff0a8
		Move	d1,$dff0b8
		Move	d1,$dff0c8
		Move	d1,$dff0d8
	USdV_E:	Rts
*---------------
Upd_SondVolG:	Lea	SondLay,a5	;###
		Lea	GSond_Vol(pc),a4
		Moveq.l	#6,d7
		Jmp	Draw_Some	;###
*---------------
Sond_Volume:	Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	SdV_End
		Or	#2,4(a2)	;Set NeedsUpdate
		Move.l	(a2),a2
		Move.l	HitGd,a0	;###
		Move.l	6(a0),a0	;Pointer
	*-- Calculate prop move space
		Clr	d0
		Sub	2(a0),d0	;%KnobX
	*-- Convert from move space to word
		Move	6(a0),d1	;%PosX
		Swap	d1
		Divu	d0,d1
		Move	d1,10(a2)	;Volume

		Bsr.w	Upd_SondVolD
		Lea	SondLay,a5	;###
		Lea	GSond_VolN(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
	SdV_End:Rts
*---------------
Smpl_Backward:	Bsr.w	Get_Smpl_LAdr
		Tst.l	(a2)
		Beq.b	SB_End
		Or	#2,4(a2)	;Set NeedsUpdate
		Move.l	(a2),a4
		Lea	Sprite_Busy,a1	;###
		Jsr	Change_Sprite	;###
		Move.l	2(a4),d3	;Get length of sample
		Sub.l	#20,d3		;+
		Add.l	#20,a4		;Get start address of sample
		Move.l	a4,a5		;Get end address of sample
		Add.l	d3,a5		;+
		Lsr.l	#1,d3		;Divide length by 2
		Subq.l	#1,d3		;Sub 1 for Dbf
	SB_Lp:	Move.b	(a4),d0
		Move.b	-(a5),(a4)+
		Move.b	d0,(a5)
		Dbf	d3,SB_Lp
		Bsr.b	Draw_Sample
	SB_End:	Rts
*---------------
Clear_Sond:	Lea	SondLay,a5	;###
		Lea	GSond_Gfx(pc),a4
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Jsr	Calc_Coord	;###
		Move.l	GfxBase,a6	;###
	*-- Clear graphics area		
		Move.l	a3,a1
		Move	LoCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X1,d0		;###
		Move	Y1,d1		;###
		Move	X2,d2		;###
		Move	Y2,d3		;###
		Jmp	RectFill(a6)
*---------------
Draw_Sound:	Lea	SondLay,a5	;###
		Lea	GSond_Gfx(pc),a4
		Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	DS_NSn
		Move.l	(a2),a2
		Move	28(a2),d0
		Ext.l	d0
		Move.l	Mem_SmplList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
	DS_NSn:	Move.l	a2,DS_Adr
		Bra.b	DS_Com

Draw_Sample:	Lea	SmplLay,a5	;###
		Lea	GSmpl_Gfx(pc),a4
		Bsr.w	Get_Smpl_LAdr
		Move.l	a2,DS_Adr

	DS_Com:	Tst.l	(a5)	;Layer Open?
		Beq.w	DS_End	;No!
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Jsr	Calc_Coord	;###
		Move.l	GfxBase,a6	;###
	*-- Draw zero line
		Move.l	a3,a1
		Move	BkCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X2,d0		;###
		Move	Y2,d1		;###
		Sub	Y1,d1		;###
		Move	d1,DS_Height
		Subq	#1,DS_Height
		Asr	#1,d1
		Add	Y1,d1		;###
		Move	d1,d7
		Jsr	Move(a6)
		Move.l	a3,a1
		Move	X1,d0		;###
		Move	d7,d1
		Jsr	Move(a6)

		Move.l	a3,a1
		Move	MdCol,d0	;###
		Jsr	SetAPen(a6)

		Move.l	DS_Adr(pc),a2
		Tst.l	(a2)
		Beq.b	DS_End
		Move.l	(a2),a4

		Move	X1,d6		;###
		
		Move.l	DS_Length(pc),d3
		;Move.l	2(a4),d3
		;Sub.l	#20,d3

		Add	#20,a4
		Add.l	DS_Offset(pc),a4

		Move	X2,d0		;###
		Sub	X1,d0		;###
		Addq	#1,d0
		
		Divu	d0,d3
		Move.l	d3,d5
		Swap	d5

		And.l	#$ffff0000,d3
		Divu	d0,d3
		Move	d3,d5
		Lsr.l	#8,d5
		
		Clr.l	d2		;Sample Counter
	DS_Loop:Add.l	d5,d2
		Move.l	d2,d4
		Lsr.l	#8,d4
		Move.b	0(a4,d4.l),d1
		Ext.w	d1
		Move	d6,d0
		Muls	DS_Height(pc),d1
		Asr	#8,d1
		Add	d7,d1
		Move.l	a3,a1
		Jsr	Draw(a6)
		Addq	#1,d6
		Cmp	X2,d6		;###
		Ble.b	DS_Loop
	DS_End:	Rts
DS_Count:	Dc.l	0
DS_Height:	Dc	0
DS_Adr:		Dc.l	0

DS_Offset:	Dc.l	0
DS_Length:	Dc.l	0
*---------------
Change_Smpl:	Bsr.w	Upd_SmplNameD
		Bsr.w	Upd_SmplNameG
		Bsr.b	Upd_SmplAllG
		Bsr.w	Draw_Sample
		Lea	Smpl_Info,a3	;###
		Jmp	Upd_SelcUnit	;###
*---------------
Upd_SmplAllG:	Lea	SmplLay,a5	;###
		Lea	Smpl_UpdAll(pc),a4
		Jmp	Draw_All	;###
*---------------
Get_Smpl_LAdr:	Move.l	Mem_SmplList,a2	;###
		Clr.l	d0
		Move	Cur_Smpl,d0	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Get_Sond_LAdr:	Move.l	Mem_SondList,a2	;###
		Clr.l	d0
		Move	Cur_Sond,d0	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Smpl_Play:	Bsr.b	Get_Smpl_LAdr
		Tst.l	(a2)
		Beq.b	SmP_Ed
		Move.l	(a2),a5
		Lea	$dff000,a6
		Move	#$0001,$96(a6)	;DMA
		Move.l	a5,a0		;Address
		Add	#20,a0		;+
		Move.l	a0,$a0(a6)	;+
		Move.l	2(a5),d0	;Length
		Sub.l	#20,d0		;+
		Lsr.l	#1,d0		;+
		Move	d0,$a4(a6)	;+
		Move.l	#3576320,d0	;Rate
		Divu	8(a5),d0	;+
		Move	d0,$a6(a6)	;+
		Move	10(a5),d0	;Volume
		Mulu	#65,d0		;+
		Swap	d0		;+
		Move	d0,$a8(a6)	;+
		Move	#$8001,$96(a6)	;DMA

		Move	6(a5),d0
		Bmi.b	SmP_Ed

		Move.l	Mem_Null,$a0(a6)	;###
		Move	#1,$a4(a6)
	SmP_Ed:	Rts
*---------------
Sond_Play:	Bsr.b	Get_Sond_LAdr	;Find Sound
		Tst.l	(a2)		;+
		Beq.w	SoP_Ed		;+
		Move.l	(a2),a5		;+
		Move.l	Mem_SmplList,a2	;Find Sample	###
		Clr.l	d0		;+
		Move	28(a5),d0	;+
		Lsl.l	#5,d0		;+
		Add.l	d0,a2		;+
		Tst.l	(a2)		;+
		Beq.w	SoP_Ed		;+
		Move	Channel(pc),d1	;Select channel
		And	#$3,d1		;+
		Addq	#1,Channel	;+
		Lea	$dff000,a6	;Get chips base address
		Move	#1,d6		;Disable Audio DMA
		Lsl	d1,d6		;+
		Move	d6,$96(a6)	;+
		Lea	$dff0a0,a3	;Find base address for channel
		Move	d1,d2		;+
		Lsl	#4,d2		;+
		Add	d2,a3		;+
		Move	#1,$6(a3)	;Wait for channel to finish
		Move	#300,d5		;+
	SoP_Pau:Dbf	d5,SoP_Pau	;+
		Move.l	(a2),a4		;Pointer=Address+20+StartPos
		Move.l	a4,a0		;+
		Add	#20,a0		;+
		Add.l	20(a5),a0	;+
		Move.l	a0,(a3)		;+
		Move.l	2(a4),d0	;Length=(ByteSize-20)/2
		Sub.l	#20,d0		;+
		Lsr.l	#1,d0		;+
		Move	d0,d7		;+ Timer=Len/2
		Mulu	#100,d7		;+ Timer=Timer*100
		Move	d0,$4(a3)	;+
		Move.l	#3546895,d0	;Period=3546895/Rate
		Divu	8(a5),d0	;+
		Divu	d0,d7		;+ Timer=Timer/Rate
		Move	d0,$6(a3)	;+
		Move	10(a5),d0	;Volume=Volume*65/65536
		Mulu	#65,d0		;+
		Swap	d0		;+
		Move	d0,$8(a3)	;+
		Or	#$8000,d6	;Enable Audio DMA
		Move	d6,$96(a6)	;+
		Lsl	#7,d6		;Clear Audio Interrupt
		Move	d6,$9c(a6)	;+
		Lea	Ch_List(pc),a1	;Find Channel in list
		Move	d1,d0		;+
		Lsl	#2,d0		;+
		Add	d0,a1		;+
		Clr.l	(a1)		;Clear everything
		Move	d7,(a1)		;Set Timer
		Bset	#0,2(a1)	;Set Occupied Flag
		Move	6(a5),d0	;Loop?
		Bmi.b	SoP_Ed		;+
		Bset	#5,2(a1)	;Set Looping
		Move	d1,d0		;Wait for Audio Interrupt
		Addq	#7,d0		;+
	SoP_Wt:	Move	$1e(a6),d3	;+
		Btst	d0,d3		;+
		Beq.b	SoP_Wt		;+
		Move.l	Mem_Null,(a3)	;Write null-sound	###
		Move	#1,$4(a3)	;+
	SoP_Ed:	Rts			;End

	Channel:Dc	0

	Ch_List:Dc.l	0	;Timer.W, Flags.B, Unused.B
		Dc.l	0
		Dc.l	0
		Dc.l	0
*---------------
* A0 = Source.L
* A1 = Destination.L
* D0 = Length.L
* Turn a sample upside down.
InvertS:Move.b	(A0)+,D1
	Not.b	D1
	Move.b	D1,(A1)+
	Subq.l	#1,D0
	Bne.s	InvertS
	Rts

* A0 = Source.L
* D0 = Length.L
* D1 ->Highest Point.B
FindH:	Clr.b	D1
FindH3:	Move.b	(A0)+,D2
	Bpl.s	FindH1
	Neg.b	D2
FindH1:	Cmp.b	D2,D1
	Bgt.s	FindH2
	Move.b	D2,D1
FindH2:	Subq.l	#1,D0
	Bne.s	FindH3
	Rts

* A0 = Source.L
* A1 = Destination.L
* D0 = Length.L
* D1 = Offset.B
* D2 ->Flag.W (Overstyr)
Offset:	Clr.l	D2
Offs2:	Move.b	(A0)+,D3
	Add.b	D1,D3
	Bvc.s	Offs1
	Moveq.l	#1,D2
Offs1:	Move.b	D3,(A1)+
	Subq.l	#1,D0
	Bne.s	Offs2
	Rts

* A0 = Source1.L
* A1 = Source2.L
* A2 = Destination.L
* D0 = Length1.L
* D1 = Length2.L
* Mix 50-50.
Mix:	Clr.l	D4
	Cmp.l	D0,D1
	Blt.s	Mix1
	Exg	A0,A1
	Exg	D0,D1
Mix1:	Move.b	(A0)+,D2
	Move.b	#0,D3
	Cmp.l	D4,D1
	Bge.s	Mix2
	Move.b	(A1)+,D3
Mix2:	Asr.b	#1,D2
	Asr.b	#1,D3
	Add.b	D2,D3
	Move.b	D3,(A2)+
	Addq.l	#1,D4
	Cmp.l	D4,d1

* Compressing a sound by halving its size.
* Frequency halved. New data calculated by averaging two and two bytes.
CompA:	Lea	$40000,a0	;Address of Source Sample
	Move	#28336,d0	;Length of Source Sample
	Lea	$50000,a1	;Address of Destination
LoopA:	Move.b	(a0)+,d1
	Ext.w	d1
	Move.b	(a0)+,d2
	Ext.w	d2
	Add	d1,d2
	Ext.l	d2
	Divs	#2,d2
	Move.b	d2,(a1)+
	Dbf	d0,LoopA
	Rts

* Improving quality of a sound by doubling its size.
* Frequency doubled. New data calculated by finding the average
* value between two and two bytes.
CompB:	Move.l	#28336/2,d0	;Length of Sound
	Lea	$60000,a2	;Destination Address
	Lea	$50000,a1	;Source Address
LoopB:	Move.b	(a1)+,d1	;Get Data and Increment
	Move.b	d1,(a2)+	;Save It
	Ext.w	d1		;Extend to word width
	Move.b	(a1),d2		;Get Next Data
	Ext.w	d2		;Extend to word width
	Add	d1,d2		;Add the two data words
	Ext.l	d2		;Extend the result to longword
	Divs	#2,d2		;Divide by two
	Move.b	d2,(a2)+	;Save the result
	Dbf	d0,LoopB
	Rts

* Mix Sounds.
	Lea	$40000,a0
	Lea	$50000,a1
	Lea	$60000,a2
	Clr.l	d7
	Clr.l	d0
	Clr.l	d1
MixLoop:Move.b	(a0,d7),d0
	Move.b	(a1,d7),d1
	Move.l	#128,d2
	Move.l	#128,d3
	Bsr.b	VMix
	Move.b	d4,(a2,d7)
	Addq	#1,d7
	Cmp	#10000,d7
	Bne.s	MixLoop
	Rts

* D0 - Data 1
* D1 - Data 2
* D2 - Volume 1	;0-128
* D3 - Volume 2	;0-128
* D4 - Output
VMix:	Muls	d2,d0
	Muls	d3,d1
	Add.l	d0,d1
	Move	d1,d4
	Lsr	#8,d4
	Rts
*---------------
Stop_Sound:	Move	#$000f,$dff096
		Rts
*---------------
Upd_SondButtD:	Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.b	USBG_E
		Move.l	(a2),a3

		Lea	Sond_LoopUpd(pc),a0
		Lea	SL_Lst(pc),a1
	*-- Rotate & Isolate Loop Bit
		Move	6(a3),d0
		Rol	#2,d0
		And	#2,d0
		Move	0(a1,d0.w),d1
		Move	d1,10+8(a0)
	USBG_E:	Rts
*---------------
Upd_SondButtG:	Lea	SondLay,a5	;###
		Lea	Sond_LoopUpd(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Conv_Sond_Prop:	Lea	GSond_Octv(pc),a0
		Move.l	6(a0),a0
		Clr	d0
		Sub	2(a0),d0
		Mulu	d4,d0
		Divu	#5,d0
		Move	d0,6(a0)

		Movem.l	d0-d7,-(a7)
		Move	d4,d0
		Lea	Sond_OctvN_T+3(pc),a0
		Moveq.l	#2,d7
		Jsr	Conv		;###
		Movem.l	(a7)+,d0-d7
		Rts
*---------------
Conv_Freq:	;(D0=Frequency, D1->Rate, D2->Octave, D3->Note, D4->Fine)
		Bsr.w	Get_Sond_LAdr
		Tst.l	(a2)
		Beq.w	CF_NoU
		Move.l	(a2),a2
		Move	8(a2),d0
		Move.l	#3546895,d1
		Divu	d0,d1
		Lea	Freq_Tab(pc),a0
		Clr	d6
		Moveq.l	#-1,d5
	CF_Lp:	Move	(a0)+,d7
		Bmi.b	CF_Fin
		Clr	CF_Neg
		Sub	d1,d7
		Bpl.b	CF_Pl
		Neg	d7
		Move	#1,CF_Neg
	CF_Pl:	Cmp	d7,d5
		Blo.b	CF_NRc
		Move	d7,d5
		Move	d6,d3
	CF_NRc:	Addq	#1,d6
		Bra.b	CF_Lp
	CF_Fin:	Move	d3,d4
		Divu	#12,d4
		Move.l	d4,d3
		Swap	d3
		Lea	Freq_Tab(pc),a0
		Move	d4,d7
		Add	d7,d7
		Move	00(a0,d7.w),d6
		Tst	CF_Neg
		Beq.b	CF_Ps
		Sub	-2(a0,d7.w),d6
		Bra.b	CF_Ng
	CF_Ps:	Sub	+2(a0,d7.w),d6
	CF_Ng:	Muls	#50,d5
		Divs	d6,d5
		Move	d5,d2

		Movem.l	d0-d7,-(a7)
		Lea	Sond_FreqN_T+5(pc),a0
		Moveq.l	#4,d7
		Jsr	Conv	;###
		Movem.l	(a7)+,d0-d7

		Movem.l	d0-d7,-(a7)
		Move	d2,d0
		Lea	Sond_FineN_T+3(pc),a0
		Move.b	#' ',-3(a0)
		Moveq.l	#1,d7
		Jsr	Conv	;###
		Movem.l	(a7)+,d0-d7

		Movem.l	d0-d7,-(a7)
		Move	d3,d0
		Lea	Sond_NoteN_T(pc),a0
		Lea	Note_Tab(pc),a1
		Add	d0,d0
		Lea	00(a1,d0.w),a1
		Move.b	#' ',(a0)+
		Move.b	(a1)+,(a0)+
		Move.b	(a1)+,(a0)+
		Movem.l	(a7)+,d0-d7

		Movem.l	d0-d7,-(a7)
		Move	d4,d0
		Lea	Sond_OctvN_T+3(pc),a0
		Move.b	#' ',-2(a0)
		Move.b	#' ',-3(a0)
		Moveq.l	#0,d7
		Jsr	Conv	;###
		Movem.l	(a7)+,d0-d7

		Lea	GSond_Fine(pc),a0
		Move.l	6(a0),a0
		Clr	d0
		Sub	2(a0),d0
		Mulu	d2,d0
		Divu	#100,d0
		Move	d0,6(a0)

		Lea	GSond_Note(pc),a0
		Move.l	6(a0),a0
		Clr	d0
		Sub	2(a0),d0
		Mulu	d3,d0
		Divu	#12,d0
		Move	d0,6(a0)

		Lea	GSond_Octv(pc),a0
		Move.l	6(a0),a0
		Clr	d0
		Sub	2(a0),d0
		Mulu	d4,d0
		Divu	#5,d0
		Move	d0,6(a0)

	CF_NoU:	Rts
	CF_Neg:	Dc	0
*---------------
	Dc 4270
Freq_Tab:
	Dc 4031,3804,3591,3389,3199,3020,2850,2690,2539,2397,2262,2135	;880
	Dc 2015,1902,1795,1694,1599,1510,1425,1345,1269,1198,1131,1068	;1760
	Dc 1008,0951,0898,0847,0800,0755,0712,0672,0635,0599,0566,0534	;3520
	Dc 0504,0476,0449,0424,0400,0377,0356,0336,0317,0300,0283,0267	;7040
	Dc 0252,0238,0224,0212,0200,0189,0178,0168,0159,0150,0141,0133	;14080
	Dc 0126,-1
Note_Tab:
	Dc ' A','A#',' B',' C','C#',' D','D#',' E',' F','F#',' G','G#'
*---------------
Sond_FinePr:	Rts
*---------------
Sond_NotePr:	Rts
*---------------
Sond_OctvPr:	Rts
*---------------
Sond_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Smpl_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Sond_StartPt:	Move	#10,SMP_LOf
		Move	#3,SMP_LX1

		Lea	GSond_EndPt+14(pc),a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###
		Move	X1,SMP_LX2	;###

		Lea	GSond_StartPt(pc),a0
		Move.l	a0,SMP_But
		Bra.w	Sond_MovePt
*---------------
Sond_EndPt:	Clr	SMP_LOf

		Lea	GSond_StartPt+20(pc),a4
		Move	(a4),d0
		Addq	#1,d0
		Move	d0,SMP_LX1

		Lea	SondLay,a0
		Move	12(a0),d0
		Sub	8(a0),d0
		Subq	#2,d0
		Move	d0,SMP_LX2

		Lea	GSond_EndPt(pc),a0
		Move.l	a0,SMP_But
		Bra.b	Sond_MovePt
*---------------
Sond_LoopStart:	Move	#10,SMP_LOf
		Move	#3,SMP_LX1

		Lea	GSond_LoopEnd+14(pc),a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###
		Move	X1,SMP_LX2	;###

		Lea	GSond_LoopStart(pc),a0
		Move.l	a0,SMP_But
		Bra.b	Sond_MovePt
*---------------
Sond_LoopEnd:	Clr	SMP_LOf

		Lea	GSond_LoopStart+20(pc),a4
		Move	(a4),d0
		Addq	#1,d0
		Move	d0,SMP_LX1

		Lea	SondLay,a0
		Move	12(a0),d0
		Sub	8(a0),d0
		Subq	#2,d0
		Move	d0,SMP_LX2

		Lea	GSond_LoopEnd(pc),a0
		Move.l	a0,SMP_But
		Bra.w	Sond_MovePt
*---------------
Sond_MovePt:	Move.l	SMP_But(pc),a0
		Move	LayX,d0		;###
		Sub	16(a0),d0
		Move	d0,SMP_OfX
		
	SMP_Lp:	Move.l	Screen_Struct,a0	;Get X	;###
		Move	18(a0),RawX
		Move	16(a0),RawY
		Jsr	Which_Layer	;###

		Move.l	LayL,a0		;###
		Cmp.l	#'SOND',4(a0)
		Bne.w	SMP_NMv

		Move	SMP_LsX(pc),d0
		Cmp	LayX,d0		;###
		Beq.w	SMP_NMv
		Move	LayX,SMP_LsX	;###

		Move.l	SMP_But(pc),a4
		Add	#14,a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	GfxBase,a6	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)
		Move.l	a3,a1
		Move	LoCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	X1,d0	;###
		Move	Y1,d1	;###
		Move	X2,d2	;###
		Move	Y2,d3	;###
		Jsr	RectFill(a6)

		Lea	GSond_Gfx(pc),a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	a3,a1
		Move	LoCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move.l	SMP_But(pc),a4
		Move	16(a4),d0
		Add	SMP_LOf(pc),d0
		Move	Y1,d1	;###
		Jsr	Move(a6)
		Move.l	a3,a1
		Move	16(a4),d0
		Add	SMP_LOf(pc),d0
		Move	Y2,d1	;###
		Jsr	Draw(a6)

		Move.l	SMP_But(pc),a0
		Move	LayX,d0	;###
		Sub	SMP_OfX(pc),d0
		Cmp	SMP_LX1(pc),d0
		Bge.b	SMP_NUn
		Move	SMP_LX1(pc),d0

	SMP_NUn:Move	d0,d1
		Add	#11,d1
		Cmp	SMP_LX2(pc),d1
		Ble.b	SMP_NOv

		Move	SMP_LX2(pc),d0
		Sub	#11,d0

	SMP_NOv:Move	d0,16(a0)
		Addq	#2,d0
		Move	d0,26(a0)
		Addq	#8,d0
		Move	d0,20(a0)

		Move.l	SMP_But(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###

		Lea	GSond_Gfx(pc),a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	a3,a1
		Move	HiCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move.l	SMP_But(pc),a4
		Move	16(a4),d0
		Add	SMP_LOf(pc),d0
		Move	Y1,d1	;###
		Jsr	Move(a6)
		Move.l	a3,a1
		Move	16(a4),d0
		Add	SMP_LOf(pc),d0
		Move	Y2,d1	;###
		Jsr	Draw(a6)

		Bsr.w	Draw_Sound

	SMP_NMv:Jsr	Check_Left_Up	;###
		Beq.w	SMP_Lp
		Rts
	SMP_LX1:Dc	0
	SMP_LX2:Dc	0
	SMP_OfX:Dc	0
	SMP_LsX:Dc	0
	SMP_But:Dc.l	0
	SMP_LOf:Dc	0
*---------------
Sond_Smpl:	Move	#14,SMR_LX1

		Lea	SondLay,a0
		Move	12(a0),d0
		Sub	8(a0),d0
		Sub	#14,d0
		Move	d0,SMR_LX2

		Bra.w	Sond_MarkRng
*---------------
Sond_MarkRng:	Move	LayX,SMR_X1	;###
		Move	LayX,SMR_X2	;###

	SMR_Lp:	Move.l	Screen_Struct,a0	;Get X	###
		Move	18(a0),RawX
		Move	16(a0),RawY
		Jsr	Which_Layer	;###

		Move.l	LayL,a0		;###
		Cmp.l	#'SOND',4(a0)
		Bne.w	SMR_NMv

		Move	SMR_LsX(pc),d0
		Cmp	LayX,d0		;###
		Beq.w	SMR_NMv
		Move	LayX,SMR_LsX	;###

		Move.l	GfxBase,a6	;###
		Lea	SondLay,a5	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3
		Move.l	a3,a1
		Moveq.l	#0,d0
		Jsr	SetDrMd(a6)

		Lea	GSond_Gfx(pc),a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	a3,a1
		Move	LoCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	SMR_X1(pc),d0
		Move	Y1,d1		;###
		Move	SMR_X2(pc),d2
		Move	Y2,d3		;###
		Cmp	d0,d2
		Bge.b	SMR_Ok1
		Exg	d0,d2
	SMR_Ok1:Jsr	RectFill(a6)

		Move	LayX,d0	;###
		Cmp	SMR_LX1(pc),d0
		Bge.b	SMR_NUn
		Move	SMR_LX1(pc),d0
	SMR_NUn:Cmp	SMR_LX2(pc),d0
		Ble.b	SMR_NOv
		Move	SMR_LX2(pc),d0
	SMR_NOv:Move	d0,SMR_X2

		Lea	GSond_Gfx(pc),a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###

		Move.l	a3,a1
		Move	HiCol,d0	;###
		Jsr	SetAPen(a6)
		Move.l	a3,a1
		Move	SMR_X1(pc),d0
		Move	Y1,d1	;###
		Move	SMR_X2(pc),d2
		Move	Y2,d3	;###
		Cmp	d0,d2
		Bge.b	SMR_Ok2
		Exg	d0,d2
	SMR_Ok2:Jsr	RectFill(a6)

		Bsr.w	Draw_Sound

	SMR_NMv:Jsr	Check_Left_Up
		Beq.w	SMR_Lp
		Rts
	SMR_LX1:Dc	0
	SMR_LX2:Dc	0
	SMR_LsX:Dc	0
	SMR_X1:	Dc	-1
	SMR_X2:	Dc	-1
*---------------
Sond_ShowAll:	Lea	Sond_Prop(pc),a0
		Clr	6(a0)
		Move	#$ffff,2(a0)
		Clr.l	DS_Offset
		Bsr.w	Get_Sond_LAdr
		Move.l	(a2),a2
		Move	28(a2),d0
		Ext.l	d0
		Move.l	Mem_SmplList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move.l	(a2),a2
		Move.l	2(a2),d0
		Sub.l	#20,d0
		Move.l	d0,DS_Length
		Move	#-1,SMR_X1
		Bsr.w	Clear_Sond
		Bra.w	Draw_Sound
*---------------
Sond_ShowRange:	Lea	GSond_Gfx(pc),a4
		Lea	SondLay,a5	;###
		Jsr	Calc_Coord	;###
		Move	X2,d0		;D0=Total length in pixels ###
		Sub	X1,d0		;+ ###
		Move	SMR_X1(pc),d1
		Bmi.w	SSR_End
		Sub	X1,d1	;###
		Move	SMR_X2(pc),d2
		Sub	X1,d2	;###
		Cmp	d1,d2	;Exchange if X2<X1
		Bge.b	SSR_Ok	;+
		Exg	d1,d2	;+
	SSR_Ok:	Move	d2,d3	;D3=Length in pixels
		Sub	d1,d3	;+

		Move.l	DS_Length(pc),d4
		Move.l	d4,d5

		Mulu	d1,d4
		Swap	d5
		Mulu	d1,d5
		Swap	d5
		Add.l	d5,d4
		
		Move.l	d4,d5
		And.l	#$ff,d4
		Divu	d0,d4
		Lsr.l	#8,d5
		Divu	d0,d5
		Move.l	d5,d6
		Swap	d6
		And.l	#$ffff,d6
		Lsl.l	#8,d6
		Divu	d0,d6
		And.l	#$ffff,d5
		Lsl.l	#8,d5
		And.l	#$ffff,d4
		Add.l	d4,d5
		And.l	#$ffff,d6
		Add.l	d6,d5
		Add.l	d5,DS_Offset

		Move.l	DS_Length(pc),d4
		Move.l	d4,d5

		Mulu	d3,d4
		Swap	d5
		Mulu	d3,d5
		Swap	d5
		Add.l	d5,d4
		
		Move.l	d4,d5
		And.l	#$ff,d4
		Divu	d0,d4
		Lsr.l	#8,d5
		Divu	d0,d5
		Move.l	d5,d6
		Swap	d6
		And.l	#$ffff,d6
		Lsl.l	#8,d6
		Divu	d0,d6
		And.l	#$ffff,d5
		Lsl.l	#8,d5
		And.l	#$ffff,d4
		Add.l	d4,d5
		And.l	#$ffff,d6
		Add.l	d6,d5

		Move.l	d5,DS_Length

		Move	#-1,SMR_X1
		Bsr.w	Clear_Sond
		Bsr.w	Draw_Sound
		Bsr.b	Upd_Sond_Slider
	SSR_End:Rts
*---------------
Upd_Sond_Slider:Bsr.w	Get_Sond_LAdr
		Move.l	(a2),a2
		Move	28(a2),d0
		Ext.l	d0
		Move.l	Mem_SmplList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move.l	(a2),a2
		Move.l	2(a2),d0
		Sub.l	#20,d0

		Move.l	DS_Length(pc),d4
		Lsr.l	#4,d4
		Swap	d4
		Move.l	d0,d1
		Lsr.l	#4,d1
		Divu	d1,d4
		Lea	Sond_Prop(pc),a0
		Move	d4,2(a0)

		Move.l	DS_Offset(pc),d4
		Lsr.l	#4,d4
		Swap	d4
		Move.l	d0,d1
		Lsr.l	#4,d1
		Divu	d1,d4
		Lea	Sond_Prop(pc),a0
		Move	d4,6(a0)

		Bsr.w	Clear_Sond
		Bsr.w	Draw_Sound

		Lea	SondLay,a5	;###
		Lea	GSond_Slider(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Sond_Slider:	Bsr.w	Get_Sond_LAdr
		Move.l	(a2),a2
		Move	28(a2),d0
		Ext.l	d0
		Move.l	Mem_SmplList,a2	;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move.l	(a2),a2
		Move.l	2(a2),d0
		Sub.l	#20,d0
		Move.l	d0,d4
		
		Lsr.l	#4,d4
		Move.l	d4,d5

		Lea	Sond_Prop(pc),a0
		Move	6(a0),d1

		Mulu	d1,d4
		Swap	d5
		Mulu	d1,d5
		Swap	d5
		Add.l	d5,d4

		Lsr.l	#4,d4
		Lsr.l	#8,d4
		;Swap	d4
		Move.l	d4,DS_Offset

		Move	#-1,SMR_X1

		Bsr.w	Clear_Sond
		Bra.w	Draw_Sound
*---------------
Smpl_Cut:	Rts
*---------------
Smpl_Copy:	Rts
*---------------
Smpl_Paste:	Rts
*---------------
Sond_Load:	Move.l	SondList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Sond,d4	;###
		Move.l	#'SOND',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Sond

		Bsr.w	Get_Sond_LAdr	;Find Sample
		Move.l	(a2),a5		;+
		Move	28(a5),Cur_Smpl	;+
		
		Move.l	SmplList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Smpl,d4	;###
		Move.l	#'SMPL',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Smpl
		Bra.w	Change_Sond
*---------------
Check_Sond:	Lea	Sond_Jump(pc),a0
		Move	SondList_Len,d0	;###
		Beq.b	CSd_NUn
	*-- Find current Sound, and check if it exists
		Move.l	Mem_SondList,a2	;###
		Move	Cur_Sond,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Sound?
		Beq.b	CSd_No		;No
		Lea	Sond_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CSd_NUn:Lea	Sond_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CSd_No:	Lea	Sond_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
Smpl_Load:	Move.l	SmplList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Smpl,d4	;###
		Move.l	#'SMPL',d0
		Jsr	Load_Unit	;###
		Bra.w	Change_Smpl
*---------------
Check_Smpl:	Lea	Smpl_Jump(pc),a0
		Move	SmplList_Len,d0	;###
		Beq.b	CSm_NUn
	*-- Find current Sample, and check if it exists
		Move.l	Mem_SmplList,a2	;###
		Move	Cur_Smpl,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Sample?
		Beq.b	CSm_No		;No
		Lea	Smpl_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CSm_NUn:Lea	Smpl_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CSm_No:	Lea	Smpl_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_Sond:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Sound8T

		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Sond_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Sond_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Sond_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-21,025

		Dc	'RO'
		Dc.l	Upd_SondNameD
		
Sond_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Sond_Name
		Dc	'RC',049,015,-43,023
		Dc	'TX',051,022,-94,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Sond_Info,Unit_BrowseUp
		Dc	'BX',-40,015,-32,023
		Dc	'IM',-38,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Sond_Info,Unit_BrowseDn
		Dc	'BX',-31,015,-23,023
		Dc	'IM',-29,018,3,Im_DArr-Im

		Dc	'GD'
		Dc.l	$0201002a,0,Sond_Sample
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_Sample-Im

Sond_UpdAll:	Dc	'RO'
		Dc.l	Check_Sond
		Dc	'JP'
Sond_Jump:	Dc.l	Sond_No

Sond_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Sond_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Sond_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Sond_Yes:	Dc	'BX',000,028,-01,044

		Dc	'GD'
		Dc.l	$02010042,0,Sond_Play
		Dc	'BX',003,030,015,042
		Dc	'IM',005,033,7,Im_Play-Im

		Dc	'GD'
		Dc.l	$02010028,0,Stop_Sound
		Dc	'BX',016,030,028,042
		Dc	'IM',018,033,7,Im_Stop-Im

		Dc	'BX',033,030,-04,042

		Dc	'IM',036,032,9,Im_Volume-Im

		Dc	'RO'
		Dc.l	Upd_SondVolD

GSond_Vol:	Dc	'GD'
		Dc.l	$0202003c,Sond_Vol_Prop,Sond_Volume
		Dc	'BX',047,032,-29,040
		Dc	'BX',048,034,-30,038

GSond_VolN:	Dc	'GD'
		Dc.l	$02030a3c,3,Sond_VolumeN
		Dc	'RC',-26,032,-07,040
		Dc	'TX',-23,039,-01,5
		Dc.l	Sond_VolN_T

		Dc	'BX',000,045,-01,087

		Dc	'TX',003,054,-37,5
		Dc.l	FrequencyT

		Dc	'GD'
		Dc.l	$02030240,3,0
		Dc	'RC',-55,047,-26,055
		Dc	'TX',-52,054,-01,5
		Dc.l	Sond_FreqN_T

		Dc	'TX',-23,056,-01,8
		Dc.l	Hz8T

		Dc	'IM',003,057,9,Im_Fine-Im

GSond_Fine:	Dc	'GD'
		Dc.l	$0202003d,Sond_Fine_Prop,Sond_FinePr
		Dc	'BX',014,057,-26,065
		Dc	'BX',024,059,-28,063

		Dc	'GD'
		Dc.l	$0203023d,3,0
		Dc	'RC',-23,057,-04,065
		Dc	'TX',-20,064,-01,5
		Dc.l	Sond_FineN_T

		Dc	'IM',003,067,9,Im_Sound-Im

GSond_Note:	Dc	'GD'
		Dc.l	$0202003e,Sond_Note_Prop,Sond_NotePr
		Dc	'BX',014,067,-26,075
		Dc	'BX',024,069,-28,073

		Dc	'GD'
		Dc.l	$0203023e,3,0
		Dc	'RC',-23,067,-04,075
		Dc	'TX',-20,074,-01,5
		Dc.l	Sond_NoteN_T

		Dc	'IM',003,077,9,Im_Octave-Im

GSond_Octv:	Dc	'GD'
		Dc.l	$0202003f,Sond_Octv_Prop,Sond_OctvPr
		Dc	'BX',014,077,-26,085
		Dc	'BX',024,079,-28,083

		Dc	'GD'
		Dc.l	$0203023f,3,0
		Dc	'RC',-23,077,-04,085
		Dc	'TX',-20,084,-01,5
		Dc.l	Sond_OctvN_T

		Dc	'BX',000,088,-01,104

		Dc	'GD'
		Dc.l	$0201002a,0,Sond_Sample
		Dc	'BX',003,090,015,102
		Dc	'IM',005,092,9,Im_Sample-Im

		Dc	'GD'
		Dc.l	$02010029,0,Sond_UseSample
		Dc	'BX',016,090,028,102
		Dc	'IM',018,094,5,Im_Store-Im

		Dc	'RO'
		Dc.l	Upd_SSNameD
		Dc	'GD'
		Dc.l	$02010041,0,Sond_SampleName
GSond_SmplName:	Dc	'BX',029,090,-51,102
		Dc	'TX',032,099,-84,5
		Dc.l	0

		Dc	'RO'
		Dc.l	Upd_SondButtD

		Dc	'GD'
		Dc.l	$02010027,0,Sond_Loop
Sond_LoopUpd:	Dc	'BX',-46,090,-34,102
		Dc	'IM',-44,092,9,Im_Once-Im

		Dc	'GD'
		Dc.l	$02010020,0,Sond_ShowRange
		Dc	'BX',-29,090,-17,102
		Dc	'IM',-27,092,9,Im_Zoom-Im

		Dc	'GD'
		Dc.l	$02010021,0,Sond_ShowAll
		Dc	'BX',-16,090,-04,102
		Dc	'IM',-14,092,9,Im_All-Im

		Dc	'FR',000,105,-01,132

GSond_StartPt:	Dc	'GD'
		Dc.l	$02000025,0,Sond_StartPt
		Dc	'BX',003,108,013,118
		Dc	'IM',005,110,7,Im_StartPoint-Im

GSond_EndPt:	Dc	'GD'
		Dc.l	$02000026,0,Sond_EndPt
		Dc	'BX',014,108,024,118
		Dc	'IM',016,110,7,Im_EndPoint-Im

GSond_LoopStart:Dc	'GD'
		Dc.l	$02000023,0,Sond_LoopStart
		Dc	'BX',003,119,013,129
		Dc	'IM',005,121,7,Im_LoopStart-Im

GSond_LoopEnd:	Dc	'GD'
		Dc.l	$02000024,0,Sond_LoopEnd
		Dc	'BX',014,119,024,129
		Dc	'IM',016,121,7,Im_LoopEnd-Im

		Dc	'GD'
		Dc.l	$00000000,0,Sond_Smpl
		Dc	'FR',000,133,-01,-10

GSond_Gfx:	Dc	'DF',014,136,-15,-13

		Dc	'RO'
		Dc.l	Draw_Sound

GSond_Slider:	Dc	'GD'
		Dc.l	$02020000,Sond_Prop,Sond_Slider
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',002,-07,-12,-03

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

		Dc	'XX'

Sond_Prop:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
Sond_Vol_Prop:	Dc.b	%00001010,0
		Dc	65535/10,0
		Dc	0,0
Sond_Fine_Prop:	Dc.b	%00001010,0
		Dc	65535/10,0
		Dc	0,0
Sond_Note_Prop:	Dc.b	%00001010,0
		Dc	65535/12,0
		Dc	0,0
Sond_Octv_Prop:	Dc.b	%00001010,0
		Dc	65535/5,0
		Dc	0,0

Sond_VolN_T:	Dc.b	'  0',0
Sond_FineN_T:	Dc.b	'-50',0
Sond_NoteN_T:	Dc.b	' D#',0
Sond_OctvN_T:	Dc.b	'  3',0
Sond_FreqN_T:	Dc.b	'14396',0
		Even
*---------------
DrawList_Smpl:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Sample8T
		
		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Smpl_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010011,Smpl_Info,Xxxx_Update
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_Save-Im

		Dc	'BX',033,013,-04,025

		Dc	'RO'
		Dc.l	Upd_SmplNameD

Smpl_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Smpl_Name
		Dc	'RC',036,015,-26,023
		Dc	'TX',038,022,-64,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Smpl_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Smpl_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

Smpl_UpdAll:	Dc	'RO'
		Dc.l	Check_Smpl
		Dc	'JP'
Smpl_Jump:	Dc.l	Smpl_No

Smpl_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Smpl_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Smpl_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Smpl_Yes:	Dc	'BX',000,028,-01,044
		
		Dc	'GD'
		Dc.l	$02010043,0,Smpl_Play
		Dc	'BX',003,030,015,042
		Dc	'IM',005,033,7,Im_Play-Im

		Dc	'GD'
		Dc.l	$02010028,0,Stop_Sound
		Dc	'BX',016,030,028,042
		Dc	'IM',018,033,7,Im_Stop-Im

		Dc	'GD'
		Dc.l	$02010044,0,Smpl_Cut
		Dc	'BX',033,030,045,042
		Dc	'IM',035,032,9,Im_Cut-Im

		Dc	'GD'
		Dc.l	$02010045,0,Smpl_Copy
		Dc	'BX',046,030,058,042
		Dc	'IM',048,032,9,Im_Clipboard-Im

		Dc	'GD'
		Dc.l	$02010046,0,Smpl_Paste
		Dc	'BX',059,030,071,042
		Dc	'IM',061,032,9,Im_Paste-Im

		Dc	'GD'
		Dc.l	$02010022,0,Smpl_Backward
		Dc	'BX',076,030,088,042
		Dc	'IM',078,032,9,Im_FlipX-Im

		Dc	'GD'
		Dc.l	$02010020,0,0	;Smpl_ShowRange
		Dc	'BX',093,030,105,042
		Dc	'IM',095,032,9,Im_Zoom-Im

		Dc	'GD'
		Dc.l	$02010021,0,0	;Smpl_ShowAll
		Dc	'BX',106,030,118,042
		Dc	'IM',108,032,9,Im_All-Im

		Dc	'GD'
		Dc.l	$00000000,0,0	;Smpl_Smpl
		Dc	'FR',000,045,-01,-10

GSmpl_Gfx:	Dc	'DF',003,048,-04,-13

		Dc	'RO'
		Dc.l	Draw_Sample

GSmpl_Slider:	Dc	'GD'
		Dc.l	$02020000,Smpl_Prop,0	;Smpl_Slider
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',020,-07,-40,-03

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

		Dc	'XX'

Smpl_Prop:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
*=======================================================================*
*				 S O N G				*
*=======================================================================*
Song_New:	Bsr.w	Get_Modl_LAdr
		Tst.l	(a2)
		Beq.b	SgN_Ed
	*-- Get list space
		Lea	SongList,a4	;###
		Jsr	Find_Unit_Space	;### ;This routine saves regs
		Move.l	a0,SgN_LstA
		Bne.b	SN_NE2
		Jmp	Mess_MemErr	;###
	SN_NE2:
	*-- Allocate memory
		Moveq.l	#22,d0		;ByteSize
		Moveq.l	#0,d1		;AnyMem
		Move.l	4.w,a6
		Jsr	AllocMem(a6)
		Tst.l	d0
		Bne.b	SN_NErr
		Jmp	Mess_MemErr	;###
	SN_NErr:Move	d7,Cur_Song
	*-- Write to list
		Move.l	SgN_LstA(pc),a5
		Move.l	d0,(a5)
		Move	#%111,04(a5)		;Set Flags = New
		Move.l	a5,a0
		Jsr	Unnamed		;###
	*-- Store new Unit
		Bsr.w	Get_Modl_LAdr
		Tst.l	(a2)
		Beq.b	SgN_Ed
		Move.l	(a2),a2
		Lea	6(a2),a3
		Move.l	(a5),a1			;Get Sound Address
		Clr	(a1)+			;Write Id
		Move.l	#22,(a1)+		;Write BytSize
		Move	(a3)+,(a1)+		;Copy Volume
		Move.l	(a3)+,(a1)+		;Copy
		Move.l	(a3)+,(a1)+		;Copy
		Move.l	(a3)+,(a1)+		;Copy
		Move	Cur_Modl,(a1)+	;Write Module	;###
		Bra.b	Change_Song
	SgN_Ed:	Rts
	SgN_LstA:Dc.l	0
*---------------
Change_Song:	Bsr.w	Upd_SongNameD
		Bsr.w	Upd_SongNameG

		Bsr.w	Upd_SMNameD
		Bsr.w	Upd_SongVolD

		Lea	SongLay,a5	;###
		Lea	Song_WinUpd(pc),a4
		Jsr	Draw_All	;###

		Lea	Song_Info,a3	;###
		Jmp	Upd_SelcUnit	;###
*---------------
Change_Modl:	Bsr.w	Upd_ModlNameD
		Bsr.w	Upd_ModlNameG
		Bsr.w	Upd_ModuleSizeD
		Bsr.b	Upd_ModlAllG
		Lea	Modl_Info,a3	;###
		Jmp	Upd_SelcUnit	;###
*---------------
Upd_ModlAllG:	Lea	ModlLay,a5	;###
		Lea	Modl_UpdAll(pc),a4
		Jmp	Draw_All	;###
*---------------
Get_Modl_LAdr:	Move.l	Mem_ModlList,a2		;###
		Clr.l	d0
		Move	Cur_Modl,d0		;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Get_Song_LAdr:	Move.l	Mem_SongList,a2		;###
		Clr.l	d0
		Move	Cur_Song,d0		;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Rts
*---------------
Song_Module:	Lea	ModlLay,a5	;###
		Jmp	Open_Layer	;###
*---------------
Song_UseModule:
	*-- Find Song
		Bsr.b	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	SUM_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a1
	*-- Store new Song data
		Bsr.b	Get_Modl_LAdr
		Tst.l	(a2)
		Beq.b	SUM_Ed
		Move.l	(a2),a2
		Lea	6(a2),a3
		Clr	(a1)+			;Write Id
		Move.l	#22,(a1)+		;Write BytSize
		Move	(a3)+,(a1)+		;Copy Volume
		Move.l	(a3)+,(a1)+		;Copy
		Move.l	(a3)+,(a1)+		;Copy
		Move.l	(a3)+,(a1)+		;Copy
		Move	Cur_Modl,(a1)+	;Write Module	;###
		Bra.w	Change_Song
	SUM_Ed:	Rts
*---------------
Song_ModuleName:Bsr.b	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	SM_Ed
		Move.l	(a2),a2
		Move	20(a2),Cur_Modl
		Lea	ModlLay,a5	;###
		Tst.l	(a5)
		Beq.b	SM_Op
		Bsr.w	Change_Modl
		Lea	ModlLay,a5	;###
	SM_Op:	Jmp	Open_Layer	;###
	SM_Ed:	Rts
*---------------
Upd_ModlNameD:	Lea	Modl_Info,a3	;###
		Lea	Modl_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_ModlNameG:	Lea	ModlLay,a5	;###
		Lea	Modl_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Upd_SongNameD:	Lea	Song_Info,a3	;###
		Lea	Song_NameUpd(pc),a4
		Jmp	Upd_UnitNameD	;###
*---------------
Upd_SongNameG:	Lea	SongLay,a5	;###
		Lea	Song_NameUpd(pc),a4
		Moveq.l	#3,d7
		Jmp	Draw_Some	;###
*---------------
Upd_SMNameD:
	*-- Update name to drawlist
		Bsr.w	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	USM_End
		Move.l	(a2),a2
		Lea	GSong_SMName(pc),a3
		Clr.l	20(a3)
		Move	20(a2),d0
		Bmi.b	USM_End
		Ext.l	d0
		Move.l	Mem_ModlList,a2		;###
		Lsl.l	#5,d0
		Add.l	d0,a2
		Addq	#8,a2
		Move.l	a2,20(a3)
	USM_End:Rts
*---------------
Upd_SMNameG:	Lea	SongLay,a5	;###
		Lea	GSong_SMName(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Modl_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Song_Name:	Move	#1,Game_NeedUpd
		Rts
*---------------
Song_VolumeN:	Bsr.w	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	SVN_Ed
		Or	#2,4(a2)		;Set NeedsUpdate
		Move.l	(a2),a2
		Move.l	Convert_Value,d1	;###
		Bpl.b	SVN_NUn
		Moveq.l	#0,d1
	SVN_NUn:Cmp	#100,d1
		Ble.b	SVN_NOv
		Moveq.l	#100,d1
	SVN_NOv:Mulu	#65535,d1
		Divu	#100,d1
		Move	d1,6(a2)
		Move	d1,MasterVol
		Bsr.b	Upd_SongVolD
		Bsr.b	Upd_SongVolG
	SVN_Ed:	Rts
*---------------
Upd_SongVolD:	Bsr.w	Get_Song_LAdr
		Tst.l	(a2)
		Move.l	(a2),a2
		Beq.b	USV_End

		Move	6(a2),d0
		Mulu	#101,d0
		Swap	d0
		
		Lea	Song_VolN_T+3(pc),a0
		Move	#$0102,d7
		Jsr	Conv	;###

		Lea	GSong_Vol(pc),a0
		Move.l	6(a0),a0	;Pointer
	*-- Calc move space
		Clr	d0
		Sub	2(a0),d0	;%KnobX
	*-- Conv from word to move space
		Move	6(a2),d1	;Volume
		Mulu	d1,d0
		Swap	d0
		Move	d0,6(a0)	;%PosX

		Move	d1,MasterVol
		Bsr.b	Set_Song_Vol
	USV_End:Rts
*---------------
Upd_SongVolG:	Lea	SongLay,a5	;###
		Lea	GSong_Vol(pc),a4
		Moveq.l	#6,d7
		Jmp	Draw_Some	;###
*---------------
Song_Volume:	Bsr.w	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	SgV_End
		Or	#2,4(a2)	;Set NeedsUpdate
		Move.l	(a2),a2
		Move.l	HitGd,a0	;###
		Move.l	6(a0),a0	;Pointer
	*-- Calculate prop move space
		Clr	d0
		Sub	2(a0),d0	;%KnobX
	*-- Convert from move space to word
		Move	6(a0),d1	;%PosX
		Swap	d1
		Divu	d0,d1
		Move	d1,6(a2)	;Volume

		Bsr.w	Upd_SongVolD
		Lea	SongLay,a5	;###
		Lea	GSong_VolN(pc),a4
		Moveq.l	#3,d7
		Jsr	Draw_Some	;###
	SgV_End:Rts
*---------------
Set_Song_Vol:	Lea	Variables(pc),a5
		Lea	$dff000,a6
		Move	#$a0,d5
		Move.l	a5,a4
		Sub	#318,a4
		Bsr.b	SgV_Vol
		Move	#$b0,d5
		Add	#44,a4
		Bsr.b	SgV_Vol
		Move	#$c0,d5
		Add	#44,a4
		Bsr.b	SgV_Vol
		Move	#$d0,d5
		Add	#44,a4
	
	SgV_Vol:Clr	d0
		Move.b	N_Volume(a4),d0
		Bsr.w	MT_MasterVol
		Move	d0,8(a6,d5.w)
		Rts
*---------------
Upd_ModuleSizeD:Bsr.w	Get_Modl_LAdr
		Tst.l	(a2)
		Beq.b	UMS_End
		Move.l	(a2),a2

		Move.l	2(a2),d5
		Sub.l	#20,d5

		Move.l	d5,d0
		Divu	#1000,d0
		Move.l	d0,d1
		Mulu	#1000,d1
		Sub.l	d1,d5

		Lea	Modl_SizeNT+4(pc),a0
		Move	#$0103,d7
		Jsr	Conv		;###
		Move	d5,d0
		Lea	Modl_SizeNT+7(pc),a0
		Moveq.l	#2,d7
		Jsr	Conv		;###
	UMS_End:Rts
*---------------
Upd_ModuleSizeG:Lea	ModlLay,a5	;###
		Lea	GModl_Size(pc),a4
		Moveq.l	#2,d7
		Jmp	Draw_Some	;###
*---------------
Check_Song:	Lea	Song_Jump(pc),a0
		Move	SongList_Len,d0	;###
		Beq.b	CSg_NUn
	*-- Find current Song, and check if it exists
		Move.l	Mem_SongList,a2	;###
		Move	Cur_Song,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Song?
		Beq.b	CSg_No		;No
		Lea	Song_Yes(pc),a1
		Move.l	a1,(a0)
		Rts

	CSg_NUn:Lea	Song_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CSg_No:	Lea	Song_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
Song_Load:	Move.l	SongList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Song,d4	;###
		Move.l	#'SONG',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Song

		Bsr.w	Get_Song_LAdr	;Find Module
		Move.l	(a2),a5		;+
		Move	20(a5),Cur_Modl	;+
		
		Move.l	ModlList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Modl,d4	;###
		Move.l	#'MODL',d0
		Jsr	Load_Unit	;###
		Bsr.w	Change_Modl
		Bra.w	Change_Song
*---------------
Modl_Load:	Move.l	ModlList,a4	;###
		Move.l	(a4),a4
		Move	Cur_Modl,d4	;###
		Move.l	#'MODL',d0
		Jsr	Load_Unit	;###
		Bra.w	Change_Modl
*---------------
Check_Modl:	Lea	Modl_Jump(pc),a0
		Move	ModlList_Len,d0	;###
		Beq.b	CMd_NUn
	*-- Find current Module, and check if it exists
		Move.l	Mem_ModlList,a2	;###
		Move	Cur_Modl,d0	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Module?
		Beq.b	CMd_No		;No
		Lea	Modl_Yes(pc),a1
		Move.l	a1,(a0)
		Rts
	CMd_NUn:Lea	Modl_None(pc),a1
		Move.l	a1,(a0)
		Rts
	CMd_No:	Lea	Modl_No(pc),a1
		Move.l	a1,(a0)
		Rts
*---------------
DrawList_Song:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Song8T
		
		Dc	'BX',000,011,-01,027
		
		Dc	'GD'
		Dc.l	$020100e1,Song_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010010,0,Song_New
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_New-Im

		Dc	'GD'
		Dc.l	$02010011,Song_Info,Xxxx_Update
		Dc	'BX',029,013,041,025
		Dc	'IM',031,015,9,Im_Save-Im

		Dc	'BX',046,013,-21,025

		Dc	'RO'
		Dc.l	Upd_SongNameD

Song_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Song_Name
		Dc	'RC',049,015,-43,023
		Dc	'TX',051,022,-94,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Song_Info,Unit_BrowseUp
		Dc	'BX',-40,015,-32,023
		Dc	'IM',-38,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Song_Info,Unit_BrowseDn
		Dc	'BX',-31,015,-23,023
		Dc	'IM',-29,018,3,Im_DArr-Im

		Dc	'GD'
		Dc.l	$02010068,0,Song_Module
		Dc	'BX',-16,013,-04,025
		Dc	'IM',-14,015,9,Im_Module-Im

Song_WinUpd:	Dc	'RO'
		Dc.l	Check_Song

		Dc	'JP'
Song_Jump:	Dc.l	Song_No

Song_Yes:	Dc	'BX',000,028,-01,044

		Dc	'GD'
		Dc.l	$0201000d,0,Song_Play
		Dc	'BX',003,030,015,042
		Dc	'IM',005,033,7,Im_Play-Im

		Dc	'GD'
		Dc.l	$02010067,0,Song_Pause
		Dc	'BX',016,030,028,042
		Dc	'IM',018,033,7,Im_Pause-Im

		Dc	'GD'
		Dc.l	$02010028,0,Modl_Stop
		Dc	'BX',029,030,041,042
		Dc	'IM',031,033,7,Im_Stop-Im

		Dc	'BX',046,030,-04,042

		Dc	'IM',049,032,9,Im_Volume-Im

		Dc	'RO'
		Dc.l	Upd_SongVolD
		
GSong_Vol:	Dc	'GD'
		Dc.l	$0202003c,Song_Vol_Prop,Song_Volume
		Dc	'BX',060,032,-29,040
		Dc	'BX',061,034,-30,038

GSong_VolN:	Dc	'GD'
		Dc.l	$02030a3c,3,Song_VolumeN
		Dc	'RC',-26,032,-07,040
		Dc	'TX',-23,039,-01,5
		Dc.l	Song_VolN_T

		Dc	'BX',000,045,-01,061

		Dc	'GD'
		Dc.l	$02010068,0,Song_Module
		Dc	'BX',003,047,015,059
		Dc	'IM',005,049,9,Im_Module-Im

		Dc	'GD'
		Dc.l	$02010069,0,Song_UseModule
		Dc	'BX',016,047,028,059
		Dc	'IM',018,051,5,Im_Store-Im

		Dc	'RO'
		Dc.l	Upd_SMNameD
		Dc	'GD'
		Dc.l	$0201006a,0,Song_ModuleName
GSong_SMName:	Dc	'BX',029,047,-04,059	;-04=-21
		Dc	'TX',032,056,-54,5
		Dc.l	0

		;Dc	'RO'
		;Dc.l	Upd_SongButtD

;		Dc	'GD'
;		Dc.l	$02010027,0,0	;Song_Loop
;Song_LoopUpd:	Dc	'BX',-16,047,-04,059
;		Dc	'IM',-14,049,9,Im_Once-Im

		Dc	'XX'

Song_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Song_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Song_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Song_Vol_Prop:	Dc.b	%00001010,0
		Dc	65535/10,0
		Dc	0,0

Song_VolN_T:	Dc.b	'  0',0
		Even
*---------------
DrawList_Modl:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Module8T

		Dc	'BX',000,011,-01,027

		Dc	'GD'
		Dc.l	$020100e1,Modl_Info,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

		Dc	'GD'
		Dc.l	$02010011,Modl_Info,Xxxx_Update
		Dc	'BX',016,013,028,025
		Dc	'IM',018,015,9,Im_Save-Im

		Dc	'BX',033,013,-04,025

		Dc	'RO'
		Dc.l	Upd_ModlNameD

Modl_NameUpd:	Dc	'GD'
		Dc.l	$0203021a,23,Modl_Name
		Dc	'RC',036,015,-26,023
		Dc	'TX',038,022,-64,5
		Dc.l	0
		
		Dc	'GD'
		Dc.l	$0201005d,Modl_Info,Unit_BrowseUp
		Dc	'BX',-23,015,-15,023
		Dc	'IM',-21,018,3,Im_UArr-Im

		Dc	'GD'
		Dc.l	$0201005e,Modl_Info,Unit_BrowseDn
		Dc	'BX',-14,015,-06,023
		Dc	'IM',-12,018,3,Im_DArr-Im

Modl_UpdAll:	Dc	'RO'
		Dc.l	Check_Modl
		Dc	'JP'
Modl_Jump:	Dc.l	Modl_No

Modl_No:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NotLoadedT
		Dc	'GD'
		Dc.l	$02010000,0,Modl_Load
		Dc	'BX',-28,030,-04,038
		Dc	'TX',-25,037,-01,5
		Dc.l	LoadT
		Dc	'XX'

Modl_None:	Dc	'BX',000,028,-01,-01
		Dc	'TX',003,037,-01,5
		Dc.l	NoUnitsT
		Dc	'XX'

Modl_Yes:	Dc	'BX',000,028,-01,044

		Dc	'GD'
		Dc.l	$0201000d,0,Modl_Play
		Dc	'BX',003,030,015,042
		Dc	'IM',005,033,7,Im_Play-Im

		Dc	'GD'
		Dc.l	$02010028,0,Modl_Stop
		Dc	'BX',016,030,028,042
		Dc	'IM',018,033,7,Im_Stop-Im

		Dc	'RO'
		Dc.l	Upd_ModuleSizeD
GModl_Size:	Dc	'BX',033,030,-04,042
		Dc	'TX',036,039,-01,5
		Dc.l	Modl_SizeT

		Dc	'XX'

Modl_SizeT:	Dc.b	'SIZE: '
Modl_SizeNT:	Dc.b	'      0 BYTES',0
*=======================================================================*
*		     L I B R A R Y   O F F S E T S			*
*=======================================================================*
*-----------------------*
* intuition.library	*
*-----------------------*
OpenIntuition		=-30
Intuition		=-36
AddGadget		=-42
ClearDMRequest		=-48
ClearMenuStrip		=-54
ClearPointer		=-60
CloseScreen		=-66
CloseWindow		=-72
CloseWorkBench		=-78
CurrentTime		=-84
DisplayAlert		=-90
DisplayBeep		=-96
DoubleClick		=-102
DrawBorder		=-108
DrawImage		=-114
EndRequest		=-120
GetDefPrefs		=-126
GetPrefs		=-132
InitRequester		=-138
ItemAddress		=-144
ModifyIDCMP		=-150
ModifyProp		=-156
MoveScreen		=-162
MoveWindow		=-168
OffGadget		=-174
OffMenu			=-180
OnGadget		=-186
OnMenu			=-192
OpenScreen		=-198
OpenWindow		=-204
OpenWorkBench		=-210
PrintIText		=-216
RefreshGadgets		=-222
RemoveGadget		=-228
ReportMouse		=-234
Request			=-240
ScreenToBack		=-246
ScreenToFront		=-252
SetDMRequest		=-258
SetMenuStrip		=-264
SetPointer		=-270
SetWindowTitles		=-276
ShowTitle		=-282
SizeWindow		=-288
ViewAddress		=-294
ViewPortAddress		=-300
WindowToBack		=-306
WindowToFront		=-312
WindowLimits		=-318
SetPrefs		=-324
IntuiTextLength		=-330
WBenchToBack		=-336
WBenchToFront		=-342
AutoRequest		=-348
BeginRefresh		=-354
BuildSysRequest		=-360
EndRefresh		=-366
FreeSysRequest		=-372
MakeScreen		=-378
RemakeDisplay		=-384
RethinkDisplay		=-390
AllocRemember		=-396
AlohaWorkbench		=-402
FreeRemember		=-408
LockIBase		=-414
UnlockIBase		=-420
GetScreenData		=-426
RefreshGList		=-432
AddGList		=-438
RemoveGList		=-444
ActivateWindow		=-450
RefreshWindowFrame	=-456
ActivateGadget		=-462
NewModifyProp		=-468
*-----------------------*
* graphics.library	*
*-----------------------*
BltBitMap		=-30
BltTemplate		=-36
ClearEOL		=-42
ClearScreen		=-48
TextLength		=-54
Text			=-60
SetFont			=-66
OpenFont		=-72
CloseFont		=-78
AskSoftStyle		=-84
SetSoftStyle		=-90
AddBob			=-96
AddVSprite		=-102
DoCollision		=-108
DrawGList		=-114
InitGels		=-120
InitMasks		=-126
RemIBob			=-132
RemVSprite		=-138
SetCollision		=-144
SortGList		=-150
AddAnimOb		=-156
Animate			=-162
GetGBuffers		=-168
InitGMasks		=-174
DrawEllipse		=-180
AreaEllipse		=-186
LoadRGB4		=-192
InitRastPort		=-198
InitVPort		=-204
MrgCop			=-210
MakeVPort		=-216
LoadView		=-222
WaitBlit		=-228
SetRast			=-234
Move			=-240
Draw			=-246
AreaMove		=-252
AreaDraw		=-258
AreaEnd			=-264
WaitTOF			=-270
QBlit			=-276
InitArea		=-282
SetRGB4			=-288
QBSBlit			=-294
BltClear		=-300
RectFill		=-306
BltPattern		=-312
ReadPixel		=-318
WritePixel		=-324
Flood			=-330
PolyDraw		=-336
SetAPen			=-342
SetBPen			=-348
SetDrMd			=-354
InitView		=-360
CBump			=-366
CMove			=-372
CWait			=-378
VBeamPos		=-384
InitBitMap		=-390
ScrollRaster		=-396
WaitBOVP		=-402
GetSprite		=-408
FreeSprite		=-414
ChangeSprite		=-420
MoveSprite		=-426
LockLayerROM		=-432
UnLockLayerROM		=-438
SyncSBitMap		=-444
CopySBitMap		=-450
OwnBlitter		=-456
DisownBlitter		=-462
InitTmpRas		=-468
AskFont			=-474
AddFont			=-480
RemFont			=-486
AllocRaster		=-492
FreeRaster		=-498
AndRectRegion		=-504
OrRectRegion		=-510
NewRegion		=-516
ClearRectRegion		=-522
ClearRegion		=-528
DisposeRegion		=-534
FreeVPortCopLists	=-540
FreeCopList		=-546
ClipBlit		=-552
XorRectRegion		=-558
FreeCprList		=-564
GetColorMap		=-570
FreeColorMap		=-576
GetRGB4			=-582
ScrollVPort		=-588
UCopperListInit		=-594
FreeGBuffers		=-600
BltBitMapRastPort	=-606
OrRegionRegion		=-612
XorRegionRegion		=-618
AndRegionRegion		=-624
SetRGB4CM		=-630
BltMaskBitMapRastPort	=-636
GraphicsReserved1	=-642
GraphicsReserved2	=-648
AttempLockLayerROM	=-654
SetRGB8			=-852
SetChipRev		=-888
*-----------------------*
* exec.library		*
*-----------------------*
Supervisor		=-30
ExitIntr		=-36
Schedule		=-42
Reschedule		=-48
Switch			=-54
Dispatch		=-60
Exception		=-66
InitCode		=-72
InitStruct		=-78
MakeLibrary		=-84
MakeFunctions		=-90
FindResident		=-96
InitResident		=-102
Alert			=-108
Debug			=-114
Disable			=-120
Enable			=-126
Forbid			=-132
Permit			=-138
SetSR			=-144
SuperState		=-150
UserState		=-156
SetIntVector		=-162
AddIntServer		=-168
RemIntServer		=-174
Cause			=-180
Allocate		=-186
Deallocate		=-192
AllocMem		=-198
AllocAbs		=-204
FreeMem			=-210
AvailMem		=-216
AllocEntry		=-222
FreeEntry		=-228
Insert			=-234
AddHead			=-240
AddTail			=-246
Remove			=-252
RemHead			=-258
RemTail			=-264
Enqueue			=-270
FindName		=-276
AddTask			=-282
RemTask			=-288
FindTask		=-294
SetTaskPri		=-300
SetSignal		=-306
SetExcept		=-312
Wait			=-318
Signal			=-324
AllocSignal		=-330
FreeSignal		=-336
AllocTrap		=-342
FreeTrap		=-348
AddPort			=-354
RemPort			=-360
PutMsg			=-366
GetMsg			=-372
ReplyMsg		=-378
WaitPort		=-384
FindPort		=-390
AddLibrary		=-396
RemLibrary		=-402
OldOpenLibrary		=-408
CloseLibrary		=-414
SetFunction		=-420
SumLibrary		=-426
AddDevice		=-432
RemDevice		=-438
OpenDevice		=-444
CloseDevice		=-450
DoIO			=-456
SendIO			=-462
CheckIO			=-468
WaitIO			=-474
AbortIO			=-480
AddResource		=-486
RemResource		=-492
OpenResource		=-498
RawIOInit		=-504
RawMayGetChar		=-510
RawPutChar		=-516
RawDoFmt		=-522
GetCC			=-528
TypeOfMem		=-534
Procure			=-540
Vacate			=-546
OpenLibrary		=-552
InitSemaphore		=-558
ObtainSemaphore		=-564
ReleaseSemaphore	=-570
AttemptSemaphore	=-576
ObtainSemaphoreList	=-582
ReleaseSemaphoreList	=-588
FindSemaphore		=-594
AddSemaphore		=-600
RemSemaphore		=-606
SumKickData		=-612
AddMemList		=-618
CopyMem			=-624
CopyMemQuick		=-630
*-----------------------*
* layers.library	*
*-----------------------*
InitLayers		=-30
CreateUpfrontLayer	=-36
CreateBehindLayer	=-42
UpfrontLayer		=-48
BehindLayer		=-54
MoveLayer		=-60
SizeLayer		=-66
ScrollLayer		=-72
BeginUpdate		=-78
EndUpdate		=-84
DeleteLayer		=-90
LockLayer		=-96
UnlockLayer		=-102
LockLayers		=-108
UnlockLayers		=-114
LockLayerInfo		=-120
SwapBitsRastPortClipRect=-126
WhichLayer		=-132
UnlockLayerInfo		=-138
NewLayerInfo		=-144
DisposeLayerInfo	=-150
FattenLayerInfo		=-156
ThinLayerInfo		=-162
MoveLayerInFrontOf	=-168
InstallClipRegion	=-174
*-----------------------*
* dos.library		*
*-----------------------*
Open			=-30
Close			=-36
Read			=-42
Write			=-48
Input			=-54
Output			=-60
Seek			=-66
DeleteFile		=-72
Rename			=-78
Lock			=-84
UnLock			=-90
DupLock			=-96
Examine			=-102
ExNext			=-108
Info			=-114
CreateDir		=-120
CurrentDir		=-126
IoErr			=-132
CreateProc		=-138
Exit			=-144
LoadSeg			=-150
UnLoadSeg		=-156
GetPacket		=-162
QueuePacket		=-168
DeviceProc		=-174
SetComment		=-180
SetProtection		=-186
DateStamp		=-192
Delay			=-198
WaitForChar		=-204
ParentDir		=-210
IsInteractive		=-216
Execute			=-222
*---------------
	*-- All game code is PC-Relative!
Game_Play:	Bsr.b	Leave_Dos
		Bsr.w	Erase		;Erase Game Screen
MouseTst:	Btst	#6,$bfe001
		Bne.b	MouseTst
RelMouse:	Btst	#6,$bfe001
		Beq.b	RelMouse
Game_End:	Bsr.w	Enter_Dos
		Clr.l	d0		;Set ReturnCode = 0.
		Rts
*---------------
INTENA:		Dc	0
DMACON:		Dc	0
ADKCON:		Dc	0

DosCop1:	Dc.l	0
DosCop2:	Dc.l	0
Int64:		Dc.l	0
Int6C:		Dc.l	0

GfxBas:		Dc.l	0
GfxNam:		Dc.b	"graphics.library",0
		Even
*---------------
Leave_Dos:
* The following stuff has been taken care of: Multitasking, Interrupts,
* Copper, Blitter, DMACON, INTENA, ADKCON, VectorVERTB.
		Move.l	4.w,a6			;Get ExecBase
		Jsr	Disable(a6)		;Disable
		Lea	GfxNam(pc),a1		;Open graphics.library
		Moveq.l	#0,d0			;+
		Jsr	OpenLibrary(a6)		;+
		Lea	GfxBas(pc),a0		;Save GfxBase Pointer
		Move.l	d0,(a0)			;+
		Move.l	d0,a1			;GfxBase to a1
		Lea	DosCop1(pc),a0		;Save Dos Copper1
		Move.l	$26(a1),(a0)		;+
		Lea	DosCop2(pc),a0		;Save Dos Copper2
		Move.l	$32(a1),(a0)		;+
		Move.l	GfxBas(pc),a6		;OwnBlitter
		Jsr	OwnBlitter(a6)		;+
		Lea	$dff000,a6		;Custom chip start to a6
		Lea	DMACON(pc),a0		;Save Dos DMACON
		Move	$02(a6),(a0)		;+
		Lea	INTENA(pc),a0		;Save Dos INTENA
		Move	$1c(a6),(a0)		;+
		Lea	ADKCON(pc),a0		;Save Dos ADKCON
		Move	$10(a6),(a0)		;+
		Move	#$7fff,$9a(a6)		;Disable all Interrupts
		Bsr.w	Wait_Vert_Blank		;Wait for Vertical Blank
		Move	#$7fff,$96(a6)		;Disable all DMA
		Move.l	Mem_Copper1,a0		;Set New Copper1 ###
		Move.l	a0,$80(a6)		;+
		Clr	$88(a6)			;Strobe Copper
		Move	#$83c0,$96(a6)		;Ena DMA,BPL,COP,BLT
		Lea	Int64(pc),a0		;Save Dos Int1 Vector
		Move.l	$64.w,(a0)		;+
		Lea	Int1(pc),a0		;Set New Int1 Vector
		Move.l	a0,$64			;+
		Lea	Int6C(pc),a0		;Save Dos Int3 Vector
		Move.l	$6c.w,(a0)		;+
		Lea	Int3(pc),a0		;Set New Int3 Vector
		Move.l	a0,$6c			;+
		Move	#$7fff,$9c(a6)		;Clear Int Requests
		Move	#$c024,$9a(a6)		;Enable INTEN,VERTB,SOFT
		Rts
*---------------
Enter_Dos:	Lea	$dff000,a6		;Custom chip start to a6
		Move	#$7fff,$9a(a6)		;Disable all Interrupts
		Bsr.b	Wait_Vert_Blank		;Wait for Vertical Blank
		Move	#$7fff,$96(a6)		;Disable all DMA
		Move.l	DosCop1(pc),$80(a6)	;Set Dos Copper1
		Move.l	DosCop2(pc),$84(a6)	;Set Dos Copper2
		Clr	$88(a6)			;Strobe Copper
		Move.l	Int64(pc),$64		;Set Dos Int1 Vector
		Move.l	Int6C(pc),$6C		;Set Dos Int3 Vector
		Move	ADKCON(pc),d0		;Set Dos ADKCON
		Bset	#15,d0			;+
		Move	d0,$9e(a6)		;+
		Move	DMACON(pc),d0		;Set Dos DMACON
		Bset	#15,d0			;+
		Move	d0,$96(a6)		;+
		Move	#$7fff,$9c(a6)		;Clear Int Requests
		Move	INTENA(pc),d0		;Set Dos INTENA
		Bset	#15,d0			;+
		Move	d0,$9a(a6)		;+
		Move.l	GfxBas(pc),a6		;DisownBlitter
		Jsr	DisownBlitter(a6)	;+
		Move.l	4.w,a6			;Get ExecBase
		Jsr	Enable(a6)		;Enable
		Move.l	GfxBas(pc),a1		;Close graphics.library
		Jmp	CloseLibrary(a6)	;+
*---------------
Wait_Vert_Blank:Btst	#0,$05(a6)
		Beq.b	Wait_Vert_Blank
	VBL_Lp:	Btst	#0,$05(a6)
		Bne.b	VBL_Lp
		Rts
*---------------
Erase:			Rts
		Move.l	Dst1A(pc),a0
		Move.l	Dst2A(pc),a1
		Move	#50960/4-1,d7
Erase1:		Clr.l	(a0)+
		Clr.l	(a1)+
		Dbf	d7,Erase1
		Rts
*---------------
Int3:		Movem.l	d0-d7/a0-a6,-(a7)	;Save Registers
		Lea	VblC(pc),a0		;Count Vbls
		Addq	#1,(a0)			;+

		Move	Song_Playing(pc),d0
		Beq.b	I3_NSg
		Lea	Variables(pc),a5
		Lea	$dff000,a6
		Bsr.w	MT_Music
	I3_NSg:
		Move	#$0020,$dff09c		;Clear Request
		Movem.l	(a7)+,d0-d7/a0-a6	;Load Registers
			;Move	#$600,$dff180
		Rte				;End
VblC:		Dc	0
Song_Playing:	Dc	0
*---------------
Int1:		Clr	VblC

		Movem.l	d0-d7/a0-a6,-(a7)	;Save Registers
		Lea	$dff000,a6

		;Move	#$0550,$180(a6)		;DEBUG

		Btst	#2,$16(a6)		;Right Mouse Button
		Beq.w	I1_End

		Bsr.w	Double			;Double Buffering

		Bsr.w	SetBPL			;Set Bitplane Pointers
		Bsr.w	Mouse

		Cmp	#'AN',Play_Mode
		Beq.b	I1_Anim
		Cmp	#'BK',Play_Mode
		Beq.b	I1_Back
		Cmp	#'WP',Play_Mode
		Beq.b	I1_Weap
		Cmp	#'LV',Play_Mode
		Beq.b	I1_Levl
		Cmp	#'MO',Play_Mode
		Beq.b	I1_Move
		Cmp	#'OB',Play_Mode
		Beq.b	I1_Objc

	I1_Anim:Bsr.w	Game_Objects
		Bra.b	I1_Vbl

	I1_Back:Move.l	SpeedX(pc),d0		;DEBUG
		Lea	ScrX(pc),a0		;+
		Add.l	d0,(a0)			;+
		Move.l	SpeedY(pc),d0		;DEBUG
		Lea	ScrY(pc),a0		;+
		Add.l	d0,(a0)			;+
		Bra.w	I1_End

	I1_Weap:Bsr.w	Fire_Main_Wpn
		Bsr.w	Game_Objects
		Bsr.w	Game_Collision
		Bra.b	I1_Vbl

	I1_Levl:Bsr.w	Game_DoLevel
		Bsr.w	Fire_Main_Wpn
		Bsr.w	Game_Objects
		Bsr.w	Game_Collision
		Bra.b	I1_Vbl

	I1_Move:Bsr.w	Game_Objects
		Bsr.w	Game_Collision
		Bra.b	I1_Vbl

	I1_Objc:Bsr.w	Game_Objects
		Bsr.w	Game_Collision
		Bra.w	I1_Vbl

	I1_Vbl:	Clr	Count_VBL
	
	I1_VblL:Move.l	SpeedX(pc),d0		;DEBUG
		Lea	ScrX(pc),a0		;+
		Add.l	d0,(a0)			;+
		Move.l	SpeedY(pc),d0		;DEBUG
		Lea	ScrY(pc),a0		;+
		Add.l	d0,(a0)			;+
		Bsr.w	Joystick
		Bsr.w	Game_Move
		Addq	#1,Game_Time
		Subq	#1,Time_VBL
		Bpl.b	I1_VPl
		Clr	Time_VBL
	I1_VPl:
		Move	VblC(pc),d0		;UsedVBL>CurrentVBL?
		Cmp	Current_VBL(pc),d0	;+
		Ble.b	I1_VOk			;+
		Move	VblC(pc),Current_VBL	;Yes, CurrentVBL=UsedVBL
		Move	#24,Time_VBL		;...and set TimeVBL=12

	I1_VOk:	Addq	#1,Count_VBL		;Count VBL calculated
		Move	Count_VBL(pc),d0	;CountVBL<CurrentVBL
		Cmp	Current_VBL(pc),d0	;+
		Ble.b	I1_VblL			;Yes, Loop!

		Move	VblC(pc),d0		;UsedVBL<CurrentVBL?
		Cmp	Current_VBL(pc),d0	;+
		Bge.b	I1_VNo			;+
		Move	Time_VBL(pc),d0		;Ready for VBL change?
		Bne.b	I1_VNo			;+ No!
		Move	VblC(pc),Current_VBL	;Yes, CurrentVBL=UsedVBL
	I1_VNo:	

		Move	Current_VBL(pc),d0
	I1_Wait:Cmp	VblC(pc),d0
		Bgt.b	I1_Wait

	I1_End:	;Move	#$0000,$180(a6)		;DEBUG
		Move	#$0004,$9C(a6)		;Clear	Request
		Movem.l	(a7)+,d0-d7/a0-a6	;Load Registers
		Rte				;End
Play_Mode:	Dc	0
Current_VBL:	Dc	0
Count_VBL:	Dc	0
Time_VBL:	Dc	0

Game_Time:	Dc	0
Game_Level:	Dc.l	0
Game_TimeEvent:	Dc	0
*---------------
Fire_Main_Wpn:	Move	FW_Cnt(pc),d0
		Ble.b	FW_Nul
		Subq	#1,FW_Cnt
		Bgt.b	FMW_End
	FW_Nul:	Btst	#7,$bfe001
		Beq.b	FW_Yes
		Clr	FW_One
		Bra.b	FMW_End

	FW_Yes:	Move	FW_One(pc),d0
		Bne.w	FW_End
		Move	#1,FW_One

		Move	MousX(pc),d0
		Lsr	#1,d0
		Move	d0,FW_X
		Move	MousY(pc),d0
		Lsr	#1,d0
		Move	d0,FW_Y
		Move	Cur_Weap,FW_Wpn
		Bsr.w	Fire_Weapon
	FMW_End:Rts
*---------------
Init_Level:	Move	Cur_Levl,d0	;###	***
		Move.l	Mem_LevlList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2

		Move.l	(a2),a2
		Move.l	a2,Game_Level
		Clr	Game_TimeEvent
		Clr	Game_Time
		Rts
*---------------
Game_DoLevel:	Move.l	Game_Level(pc),a2
		Move	Game_TimeEvent(pc),d3
		Cmp	6(a2),d3		;FirstPos=Game_TimeEvent?
		Bge.w	GDL_Ed			;No more TimerEvents.
	*-- Find Event (A3->Address)
		Add	d3,d3
		Move	12(a2,d3.w),d3
		Lea	00(a2,d3.w),a3

		Move	4(a3),d0
		Cmp	Game_Time(pc),d0
		Bne.w	GDL_Ed

		Cmp	#1,2(a3)
		Beq.b	GDL_Bck
		Cmp	#2,2(a3)
		Beq.b	GDL_Scl
		Cmp	#3,2(a3)
		Beq.b	GDL_Rls
		Cmp	#4,2(a3)
		Beq.w	GDL_Snd
		Cmp	#5,2(a3)
		Beq.w	GDL_Sng
		Cmp	#6,2(a3)
		Beq.w	GDL_Obj
		Cmp	#7,2(a3)
		Beq.w	GDL_Plr
		Cmp	#8,2(a3)
		Beq.w	GDL_Sco
		Cmp	#9,2(a3)
		Beq.w	GDL_Pal
		Cmp	#10,2(a3)
		Beq.w	GDL_End
		Bra.w	GDL_Fin
	*-- Change Background
	GDL_Bck:
		Bra.w	GDL_Fin
	*-- Change Scroll
	GDL_Scl:
		Bra.w	GDL_Fin
	*-- Release Objects
	GDL_Rls:Jsr	Find_Object_Vacancy	;###
		Move.l	a5,d0
		Beq.w	GDL_Fin
		Move	#$8000,(a5)

		Move	14(a3),d0
		Btst	#0,d0
		Bne.b	GDL_Ob
		Btst	#1,d0
		Bne.b	GDL_Wa
		Bra.w	GDL_Fin


	GDL_Ob:	Move.l	Mem_ObjcList,a2	;###
		Clr.l	d0
		Move	16(a3),d0
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.b	GDL_NOb
		Bset	#7,01(a5)	;Set Object bit
		Move.l	(a2),44(a5)	;Object
		Move	#32767,40(a5)	;Duration
		Clr	02(a5)		;Age
		Move	18(a3),08(a5)
		Clr	10(a5)
		Move	20(a3),12(a5)
		Clr	14(a5)

		Move	08(a3),48(a5)
		Move	12(a3),52(a5)


	GDL_NOb:Bra.w	GDL_Fin

	GDL_Wa:	Bra.w	GDL_Fin
	*-- Play Sound
	GDL_Snd:Move	14(a3),d0
		Bmi.w	GDL_Fin
		Move	d0,Cur_Sond
		Bsr.w	Sond_Play
		Bra.b	GDL_Fin
	*-- Change Song
	GDL_Sng:Clr	Song_Playing
		Move	14(a3),d0
		Move.l	Mem_SongList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	GDL_NSg
		Move.l	(a2),a2
		Move	6(a2),MasterVol
		Move	20(a2),d0
		Move.l	Mem_ModlList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	GDL_NSg
		Move.l	(a2),a0
		Add	#20,a0

		Move	Song_Playing(pc),d0
		Beq.b	GDL_NPl
		Clr	Song_Playing
		Lea	$dff000,a6
		Jsr	MT_End
	GDL_NPl:
		Lea	Variables,a5	;###
		Lea	$dff000,a6
		Jsr	MT_Init		;###
		Move	#1,Song_Playing
	GDL_NSg:Bra.b	GDL_Fin
	*-- Change Object
	GDL_Obj:
		Bra.b	GDL_Fin
	*-- Change Player
	GDL_Plr:
		Bra.b	GDL_Fin
	*-- Change Scoredata
	GDL_Sco:
		Bra.b	GDL_Fin
	*-- Change Palette
	GDL_Pal:
		Bra.w	GDL_Fin
	*-- End of Level
	GDL_End:

	GDL_Fin:Addq	#1,Game_TimeEvent
		Bra.w	Game_DoLevel
	GDL_Ed:	Rts
*---------------
Game_Background:Lea	$dff000,a6
		Move	ScrX(pc),d0
		Add	#16,d0
		Cmp	ScrDraw_X2(pc),d0
		Ble.w	IB_End

		Move	#$0004,$9a(a6)		;Disable VBL Interrupt
		Move.l	Dst1A(pc),IB_Dst1A
		Move.l	Dst2A(pc),IB_Dst2A
		Move	#$8004,$9a(a6)		;Enable VBL Interrupt

		Jsr	Get_Back_LAdr		;###
		Tst.l	(a2)
		Beq.w	IB_End
		Move.l	(a2),a2
		Move.l	a2,a0
		Move	6(a2),d7		;Piece Counter
		Add	#100,a0			;Add BackHeader

		Move.l	Mem_ScrollTab,a1	;###
		Moveq.l	#64,d6			;ScrollTab Counter ***

		Tst	d7			;More Pieces?
		Beq.b	IB_TbE			;No!
		Move	ScrDraw_X2(pc),d2
		Moveq.l	#16,d3
		Addq	#2,a0			;For å slippe 2(a0) \/
	IB_TbLp:Move	(a0),d0			;Get PieceX
		Sub	d2,d0			;PieceX < ScrDraw_X2 ?
		Blt.b	IB_GoLp			;+ Already drawn!
		Sub	d3,d0			;PieceX > ScrDraw_X2+16 ?
		Blt.b	IB_Out			;+ Not yet!
	*-- Loop through Back_Pieces
	IB_GoLp:Addq	#8,a0		;Next Back_Piece
		Subq	#1,d7		;Count Pieces
		Bne.b	IB_TbLp		;Loop
		Bra.b	IB_TbE

	IB_Out:	Subq	#2,a0
		Move	(a0),d0
		Move.l	Mem_PiecList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0	
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.b	IB_NOut		;No
		Move.l	(a2),a2		;Get PieceData Address
	*-- Insert Piece in ScrollTab
	IB_VaLp:Tst	d6		;No Vacancy? ***
		Beq.b	IB_NOut		;***

		Tst	(a1)		;Vacancy here?
		Bgt.b	IB_NVa		;No!

		Move	6(a2),(a1)+	;Write Piece_XSize
		Clr	(a1)+		;Clear OffsetX
		Move	d7,(a1)+	;Write Layer
		Addq	#2,a1		;Skip Unused
		Move.l	(a0),(a1)+	;Write PieceNumber,PieceX
		Move.l	4(a0),(a1)+	;Write PieceY,PieceFlags,Value

		Subq	#1,d6		;Count ScrollTab lines ***
		Bra.b	IB_NOut

	IB_NVa:	Add	#16,a1		;Next ScrollTab line
		Subq	#1,d6		;Count ScrollTab lines ***
		Bra.b	IB_VaLp		;Loop

	IB_NOut:Addq	#2,a0
		Bra.b	IB_GoLp
	IB_TbE:
	*-- Blit Background Pieces
	*-- A4=ClearAddress
		Move.l	IB_Dst1A(pc),d0
		Move.l	IB_Dst2A(pc),d5
		Cmp.l	d0,d5
		Bhi.b	IB_Ok
		Exg	d0,d5		
	IB_Ok:	Move.l	d0,a4
		Move	ScrDraw_X2(pc),d0
		Add	#336+16,d0
		Lsr	#3,d0
		Add	d0,a4
	*-- D5=ClearModulo
		Move	BytWidth(pc),d5		;Get Width of Game Screen
		Subq	#2,d5
	*-- Feed Blitter
		Move	Depth(pc),d0
		Add	d0,d0
		Addq	#1,d0			;For Overlayer mask bpl
	IB_ClLp:Move	#$0004,$9a(a6)		;Disable VBL Interrupt
		Bsr.w	BltFinB
		Clr	$74(a6)			;DATA
		Clr	$42(a6)			;CON1
		Move	#$01f0,$40(a6)		;CON0
		Move	d5,$66(a6)		;MODD
		Move.l	a4,$54(a6)		;PTD
		Move	#256*64+1,$58(a6)	;SIZE
		Add	DstS(pc),a4
		Move	#$8004,$9a(a6)		;Enable VBL Interrupt
		Dbf	d0,IB_ClLp		;Dbf for coll bpl
	*-- Depth System
		Move	#$ffff,IB_DCnt

	IB_NxDp:Clr	IB_DRec
		Move	#-1,IB_DLin

		Move.l	Mem_ScrollTab,a1
		Moveq.l	#63,d1
	IB_DpLp:Tst	(a1)
		Ble.b	IB_NRc

		Move	4(a1),d0
		Cmp	IB_DRec(pc),d0	;New record?
		Blo.b	IB_NRc		;No
		Cmp	IB_DCnt(pc),d0	;Too high?
		Bhs.b	IB_NRc		;Yes
		Move	d0,IB_DRec	;Save Record
		Moveq.l	#63,d2		;Save Line Number
		Sub	d1,d2		;+
		Move	d2,IB_DLin	;+
		
	IB_NRc:	Add	#16,a1
		Dbf	d1,IB_DpLp

		Move	IB_DRec(pc),IB_DCnt
	*-- Draw Piece
		Move	IB_DLin(pc),d0
		Bmi.w	IB_Fin
		Move.l	Mem_ScrollTab,a1
		Lsl	#4,d0
		Add	d0,a1
	*-- Find piece, and check if it exists
		Move	8(a1),d0		;Get Piece Number
		Move.l	Mem_PiecList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0	
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.w	IB_NPc		;No
		Move.l	(a2),a2		;Get PieceData Address

		Move	2(a1),d7	;Offset
		Lsr	#3,d7

		Btst	#5,14(a1)		;FlipY?
		Beq.b	IB_NFlA
		Add	12(a2),d7
		Sub	14(a2),d7
	IB_NFlA:
	*-- A4=PTB
		Move.l	a2,a4
		Add	#28,a4
		Add	d7,a4
	*-- A3=PTA
		Move.l	a2,a3
		Add.l	24(a2),a3	;ok
		Add	d7,a3
	*-- A5=PTD/PTC
		Move.l	IB_Dst2A(pc),a5
		Move	ScrDraw_X2(pc),d0
		Add	#336+16,d0
		Lsr	#3,d0
		Add	d0,a5

		Moveq.l	#0,d7
		Move	12(a1),d0	;Get PieceY
		Bpl.b	IB_NMi		;Negative?
		Neg	d0		;Yes! Find how much
		Move	d0,d7		;Save value for size calc
		Mulu	14(a2),d0	;Multiply by Piec_ByteWidth

		Btst	#5,14(a1)	;FlipY?
		Beq.b	IB_NFlS
		Neg	d0
	IB_NFlS:
		Add	d0,a3		;Add to source pointers
		Add	d0,a4		;+
		Bra.b	IB_Mi		;PieceY is then 0, so skip calc
	IB_NMi:	Mulu	BytWidth(pc),d0
		Add	d0,a5
	IB_Mi:
		Move	#4096,IB_BltX
	*-- D4=SIZE
		Move	8(a2),d4
		Move	d4,d0		;Clip Y2
		Add	12(a1),d0	;+
		Sub	IB_Height(pc),d0
		Ble.b	IB_NY2
		Sub	d0,d4
		Ble.w	IB_Quit
	IB_NY2:
		Sub	d7,d4		;Subtract clipped gfx
		Ble.w	IB_Quit
		Lsl	#6,d4
		Or	#2,d4
	*-- Split up into 16 wide
		Move	10(a1),d6
		And	#$f,d6

		Tst	2(a1)
		Beq.b	IB_1st
		Tst	d6
		Beq.b	IB_1st
		Subq	#2,a5

		Move	#16,IB_BltX
		Move	d6,d0
		Add	d0,d0
		Lea	MaskTab(pc),a0
		Move	(a0,d0.w),IB_FWM
		Move	IB_FWM(pc),IB_LWM
		Not	IB_LWM

		Cmp	#16,(a1)	;Size<16
		Bge.b	IB_MOk

		Moveq.l	#16,d0		;16-Size+Shift
		Sub	(a1),d0		;+
		Add	d6,d0		;+
		Cmp	#16,d0		;>16
		Bge.b	IB_0		;Yes
	
		Add	d0,d0
		Lea	MaskTab(pc),a0
		Move	(a0,d0.w),d0
		Eor	d0,IB_LWM
		Bra.b	IB_MOk

	IB_0:	Clr	IB_LWM
		Sub	#16,d0
		Add	d0,d0
		Lea	MaskTab(pc),a0
		Move	(a0,d0.w),d0
		Eor	d0,IB_FWM
		Bra.b	IB_MOk

	IB_1st:	Move	d6,d0

		Moveq.l	#16,d5
		Sub	d6,d5
		Move	d5,IB_BltX

		Cmp	#16,(a1)	;Size<16
		Bge.b	IB_N16
		Moveq.l	#16,d0
		Sub	(a1),d0

	IB_N16:	Add	d0,d0
		Lea	MaskTab(pc),a0
		Move	(a0,d0.w),IB_FWM
		Not	IB_FWM
		Clr	IB_LWM
	IB_MOk:
	*-- D6=CON1
		Move	10(a1),d6
		And	#$f,d6
		Ror	#4,d6
	*-- D7=CON0
		Move	d6,d7
		Or	#$fca,d7
	*-- D2=MODD/MODC
		Move	BytWidth(pc),d2		;Get Width of Game Screen
		Subq	#4,d2
	*-- D3=MODA/MODB
		Move	14(a2),d3		;Get ByteWidth
		Btst	#5,14(a1)		;FlipY?
		Beq.b	IB_NFlM
		Neg	d3
	IB_NFlM:Subq	#4,d3

		Move.l	a5,d0
		Sub.l	IB_Dst2A(pc),d0
		Move.l	d0,IB_AdrOff
	*-- Feed Blitter
		Move	10(a2),d0		;Depth

	IB_BlLp:Move	#$0004,$9a(a6)		;Disable VBL Interrupt
		Bsr.w	BltFinB
		Move	d3,$64(a6)		;MODA
		Move	d3,$62(a6)		;MODB
		Move	d2,$60(a6)		;MODC
		Move	d2,$66(a6)		;MODD
		Move	IB_FWM(pc),$44(a6)	;FWM
		Move	IB_LWM(pc),$46(a6)	;LWM
		Move	d7,$40(a6)		;CON0
		Move	d6,$42(a6)		;CON1
		Move.l	a3,$50(a6)		;PTA
		Move.l	a4,$4c(a6)		;PTB
		Move.l	a5,$48(a6)		;PTC
		Move.l	a5,$54(a6)		;PTD
		Move	d4,$58(a6)		;SIZE
		Move	#$8004,$9a(a6)		;Enable VBL Interrupt

		Sub.l	IB_Dst2A(pc),a5
		Add.l	IB_Dst1A(pc),a5

		Move	#$0004,$9a(a6)		;Disable VBL Interrupt
		Bsr.w	BltFinB
		Move	d3,$64(a6)		;MODA
		Move	d3,$62(a6)		;MODB
		Move	d2,$60(a6)		;MODC
		Move	d2,$66(a6)		;MODD
		Move	IB_FWM(pc),$44(a6)	;FWM
		Move	IB_LWM(pc),$46(a6)	;LWM
		Move	d7,$40(a6)		;CON0
		Move	d6,$42(a6)		;CON1
		Move.l	a3,$50(a6)		;PTA
		Move.l	a4,$4c(a6)		;PTB
		Move.l	a5,$48(a6)		;PTC
		Move.l	a5,$54(a6)		;PTD
		Move	d4,$58(a6)		;SIZE
		Move	#$8004,$9a(a6)		;Enable VBL Interrupt

		Sub.l	IB_Dst1A(pc),a5
		Add.l	IB_Dst2A(pc),a5

		Add	DstS(pc),a5
		Add	12(a2),a4
		Subq	#1,d0
		Bne.w	IB_BlLp


		Btst	#6,14(a1)		;Front on?
		Beq.b	IB_NoFr			;No.

		Move.l	MaskBpl(pc),a5
		Add.l	IB_AdrOff(pc),a5

		Move	#$0004,$9a(a6)		;Disable VBL Interrupt
		Bsr.w	BltFinB
		Move	d3,$64(a6)		;MODA
		Move	d3,$62(a6)		;MODB
		Move	d2,$60(a6)		;MODC
		Move	d2,$66(a6)		;MODD
		Move	IB_FWM(pc),$44(a6)	;FWM
		Move	IB_LWM(pc),$46(a6)	;LWM
		Move	d7,$40(a6)		;CON0
		Move	d6,$42(a6)		;CON1
		Move.l	a3,$50(a6)		;PTA
		Move.l	a4,$4c(a6)		;PTB
		Move.l	a5,$48(a6)		;PTC
		Move.l	a5,$54(a6)		;PTD
		Move	d4,$58(a6)		;SIZE
		Move	#$8004,$9a(a6)		;Enable VBL Interrupt

	IB_NoFr:

		Btst	#7,14(a1)		;Collision on?
		Beq.b	IB_NoCl			;No.

		Move.l	CollBpl(pc),a5
		Add.l	IB_AdrOff(pc),a5

		Add	12(a2),a4

		Move	#$0004,$9a(a6)		;Disable VBL Interrupt
		Bsr.w	BltFinB
		Move	d3,$64(a6)		;MODA
		Move	d3,$62(a6)		;MODB
		Move	d2,$60(a6)		;MODC
		Move	d2,$66(a6)		;MODD
		Move	IB_FWM(pc),$44(a6)	;FWM
		Move	IB_LWM(pc),$46(a6)	;LWM
		Move	d7,$40(a6)		;CON0
		Move	d6,$42(a6)		;CON1
		Move.l	a3,$50(a6)		;PTA
		Move.l	a4,$4c(a6)		;PTB
		Move.l	a5,$48(a6)		;PTC
		Move.l	a5,$54(a6)		;PTD
		Move	d4,$58(a6)		;SIZE
		Move	#$8004,$9a(a6)		;Enable VBL Interrupt

	IB_NoCl:

	IB_Quit:Move	IB_BltX(pc),d0
		
		Add	d0,2(a1)
		Sub	d0,(a1)
	IB_NPc:	Bra.w	IB_NxDp

	IB_Fin:	Add	#16,ScrDraw_X2	;Move ScrDraw_X2 forward
	IB_End:	Rts

IB_AdrOff:	Dc.l	0
IB_FWM:		Dc	0
IB_LWM:		Dc	0
IB_BltX:	Dc	0
IB_DCnt:	Dc	0
IB_DRec:	Dc	0
IB_DLin:	Dc	0
IB_Height:	Dc	256
IB_Dst1A:	Dc.l	0
IB_Dst2A:	Dc.l	0

ScrDraw_X2:	Dc	0

MaskTab:	Dc	%0000000000000000
		Dc	%0000000000000001
		Dc	%0000000000000011
		Dc	%0000000000000111
		Dc	%0000000000001111
		Dc	%0000000000011111
		Dc	%0000000000111111
		Dc	%0000000001111111
		Dc	%0000000011111111
		Dc	%0000000111111111
		Dc	%0000001111111111
		Dc	%0000011111111111
		Dc	%0000111111111111
		Dc	%0001111111111111
		Dc	%0011111111111111
		Dc	%0111111111111111
		Dc	%1111111111111111
*---------------
Game_Collision:	;	Rts
		Move	#$080,$dff180	;***
		Move.l	Mem_Objects,a5
		Clr	GC_Cnt

	GC_Nxt:	Move	(a5),d7
		Bpl.w	GC_NObA
		Btst	#0,d7
		Bne.w	GC_APi
		Btst	#1,d7
		Bne.b	GC_AAn
		Bra.w	GC_NObA
	*-- Check collision from Animation to other unit.
	GC_AAn:	Move.l	16(a5),a0		;Get GraphicsPtr
	*-- Find Frame (A1->Address)
		Move	36(a5),d0		;Get AnimFrame
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,GC_APieces
		Move.l	a1,GC_AAddress
	*-- Draw Frame
	GC_ANxt:Subq.b	#1,GC_APieces
		Bmi.w	GC_Done
		Move.l	GC_AAddress(pc),a1
		Move	(a1)+,d0
		Move	(a1)+,d2
		Move	(a1)+,d3
		Move	(a1)+,GC_AFlags
		Move.l	a1,GC_AAddress
		Btst	#7,GC_AFlags
		Beq.b	GC_ANxt
	*-- Find piece, and check if it exists
		Move.l	Mem_PiecList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.b	GC_No		;No
		Move.l	(a2),a2		;Get PieceData Address
		Add	08(a5),d2	;Add X
		Add	12(a5),d3	;Add Y
		Move	d2,GC_AX1	;to X1
		Move	d3,GC_AY1	;to Y1
		Add	6(a2),d2	;Add SizeX
		Add	8(a2),d3	;Add SizeY
		Move	d2,GC_AX2	;to X2
		Move	d3,GC_AY2	;to Y2

		Move	GC_Cnt(pc),GC_Cnt2
		Move.l	a5,a4
		Bsr.w	GC_Tst
	GC_No:	Bra.b	GC_ANxt
	*-- Collision detection from Piece to other unit.
	GC_APi:	Move	GC_Cnt(pc),GC_Cnt2
		Move.l	a5,a4
		Move	08(a5),d0	;XPos
		Move	d0,GC_AX1	;to X1
		Move	12(a5),d1	;YPos
		Move	d1,GC_AY1	;to Y1
		Move.l	16(a5),a2	;Gfx pointer
		Add	6(a2),d0	;Add SizeX
		Add	8(a2),d1	;Add SizeY
		Move	d0,GC_AX2	;to X2
		Move	d1,GC_AY2	;to Y2
		Bsr.w	GC_Tst
		Bra.w	GC_Done

	GC_Done:
	*-- Next Object...
	GC_NObA:Add	#256,a5
		Addq	#1,GC_Cnt
		Cmp	#64,GC_Cnt
		Bne.w	GC_Nxt
		Move	#$000,$dff180	;***
		Rts
	GC_Cnt:	Dc	0
	GC_Cnt2:Dc	0

	GC_AX1:	Dc	0
	GC_AY1:	Dc	0
	GC_AX2:	Dc	0
	GC_AY2:	Dc	0

	GC_BX1:	Dc	0
	GC_BY1:	Dc	0
	GC_BX2:	Dc	0
	GC_BY2:	Dc	0

	GC_Tab:	Blk.b	64*2,0

GC_AFlags:	Dc.b	0
GC_AValue:	Dc.b	0
GC_AAddress:	Dc.l	0
GC_APieces:	Dc.b	0,0

GC_BFlags:	Dc.b	0
GC_BValue:	Dc.b	0
GC_BAddress:	Dc.l	0
GC_BPieces:	Dc.b	0,0
	*-- Check collision forward in table.
	*-- (A4=Table Pointer, GC_Cnt2=Table Position, A2=Piece Pointer,
	*--  GC_AX1,GC_AY1,GC_AX2,GC_AY2=Piece Rectangle)
	GC_Tst:	Cmp	#64,GC_Cnt2
		Beq.w	GC_Fin
		Addq	#1,GC_Cnt2
		Add	#256,a4

		Move	(a4),d7
		Bpl.w	GC_NObB
		Btst	#0,d7
		Bne.w	GC_BPi
		Btst	#1,d7
		Bne.b	GC_BAn
		Bra.w	GC_NObB

	*-- Check collision from other unit to Anim.
	GC_BAn:	Move.l	16(a4),a0		;Get GraphicsPtr
	*-- Find Frame (A1->Address)
		Move	36(a4),d0		;Get AnimFrame
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,GC_BPieces
		Move.l	a1,GC_BAddress
	*-- Draw Frame
	GC_BNxt:Subq.b	#1,GC_BPieces
		Bmi.b	GC_BDon
		Move.l	GC_BAddress(pc),a1
		Move	(a1)+,d0
		Move	(a1)+,d2
		Move	(a1)+,d3
		Move	(a1)+,GC_BFlags
		Move.l	a1,GC_BAddress
		Btst	#7,GC_BFlags
		Beq.b	GC_BNxt
	*-- Find piece, and check if it exists
		Move.l	Mem_PiecList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.b	GC_BNo		;No
		Move.l	(a2),a2		;Get PieceData Address
		Add	08(a4),d2	;Add X
		Add	12(a4),d3	;Add Y
		Move	d2,GC_BX1	;to X1
		Move	d3,GC_BY1	;to Y1
		Add	6(a2),d2	;Add SizeX
		Add	8(a2),d3	;Add SizeY
		Move	d2,GC_BX2	;to X2
		Move	d3,GC_BY2	;to Y2

		Bsr.b	GC_Col

	GC_BNo:	Bra.b	GC_BNxt

	GC_BDon:Bra.b	GC_NObB


	*-- Check collision from other unit to Piece.
	GC_BPi:	Move	08(a4),d0
		Move	d0,GC_BX1
		Move	12(a4),d1
		Move	d1,GC_BY1
		Move.l	16(a4),a0
		Add	6(a0),d0
		Add	8(a0),d1
		Move	d0,GC_BX2
		Move	d1,GC_BY2
		Bsr.b	GC_Col
		Bra.w	GC_NObB

	GC_NObB:Bra.w	GC_Tst
	GC_Fin:	Rts

	*-- Check Collision between two Pieces
	GC_Col:	Move	GC_AX2(pc),d0
		Sub	GC_BX1(pc),d0
		Ble.b	GC_NCol
		Move	GC_AY2(pc),d0
		Sub	GC_BY1(pc),d0
		Ble.b	GC_NCol
		Move	GC_BX2(pc),d0
		Sub	GC_AX1(pc),d0
		Ble.b	GC_NCol
		Move	GC_BY2(pc),d0
		Sub	GC_AY1(pc),d0
		Ble.b	GC_NCol
		Move	#$fff,$dff180

		Btst	#7,01(a5)	;Object?
		Bne.b	GC_Obj
	GC_NCol:Rts

	GC_Obj:	Move.l	44(a5),a2	;Object Adr
		Moveq.l	#0,d6
		
	GC_EvLp:Cmp	20(a2),d6	;Total
		Beq.b	GC_EvFn

		Move	d6,d0
		Add	d0,d0
		Move	32(a2,d0.w),d0
		Lea	00(a2,d0.w),a3

		Cmp	#3,2(a3)	;EventType=Hit?
		Bne.b	GC_Unkn
	*-- Do Hit Event
		Bsr.w	GO_DoEv

	GC_Unkn:Addq	#1,d6
		Bra.b	GC_EvLp
	GC_EvFn:Rts
*---------------
Game_Objects:	Bsr.w	Game_Remove

		Move	#64,GO_Cnt
		Move.l	Mem_Objects,a5	;###
	*-- ***
	GO_Nxt:	Move	(a5),d7
		Bpl.b	GO_NOb		;Occupied?

		Btst	#7,d7
		Beq.b	GO_Gfx

	GO_Objc:Move.l	44(a5),a2	;Object Adr
		Moveq.l	#0,d6
		
	GO_EvLp:Cmp	20(a2),d6	;Total
		Beq.b	GO_EvFn

		Move	d6,d0
		Add	d0,d0
		Move	32(a2,d0.w),d0
		Lea	00(a2,d0.w),a3

		Cmp	#1,2(a3)	;EventType=Time?
		Beq.b	GO_Time
		Bra.b	GO_Unkn

	GO_Time:Move	2(a5),d0	;Age
		Cmp	4(a3),d0	;Time
		Bne.b	GO_NTim
		Bsr.b	GO_DoEv


	GO_NTim:

	GO_Unkn:Addq	#1,d6
		Bra.b	GO_EvLp
	GO_EvFn:
	
	GO_Gfx:	Btst	#0,d7
		Bne.b	GO_Piec
		Btst	#1,d7
		Bne.b	GO_Anim
		Bra.b	GO_Fin
	*-- Bob Piece
	GO_Piec:Move.l	16(a5),a2
		Moveq.l	#0,d2
		Moveq.l	#0,d3
		Move.b	42(a5),DFS_Flags

		Add	08(a5),d2	;X
		Add	ScrX(pc),d2
		Add	12(a5),d3	;Y
		Add	ScrY(pc),d3

		Bsr.w	Game_BlitPiece
	GO_No:	Bra.b	GO_Fin

	GO_Anim:Bsr.w	Game_Animate

	GO_Fin:	
	GO_NOb:	Add	#256,a5
		Subq	#1,GO_Cnt
		Bne.b	GO_Nxt
		Rts
	GO_Cnt:	Dc	0

	*-- Do Event!
	GO_DoEv:Movem.l	d0-d7/a0-a6,-(a7)

		Move	14(a3),d0
		Btst	#1,d0
		Bne.b	GO_ChMv
		Btst	#0,d0
		Bne.b	GO_ChAn
		Bra.b	GO_ChEd
	*-- Get Movement Address
	GO_ChMv:Move.l	Mem_MoveList,a2	;###
		Clr.l	d0
		Move	16(a3),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	GO_ChEd
		Move.l	(a2),a0
		Jsr	Prep_Object_Move
		Bra.b	GO_ChEd

	GO_ChAn:Move.l	Mem_AnimList,a2	;###
		Clr.l	d0
		Move	16(a3),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Tst.l	(a2)
		Beq.b	GO_ChEd
		Move.l	(a2),a0
		Jsr	Prep_Object_Anim
		;Bra.w	GO_ChEd

	GO_ChEd:
	*-- Play Sound if any
		Move	26(a3),d0
		Bmi.b	GO_NSnd
		Move	d0,Cur_Sond
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Sond_Play
		Movem.l	(a7)+,d0-d7/a0-a6
	GO_NSnd:
	*-- Fire Weapon if any
		Move	28(a3),d0
		Bmi.b	GO_NWpn
		Move	d0,FW_Wpn
		Move	08(a5),FW_X
		Move	12(a5),FW_Y
		Movem.l	d0-d7/a0-a6,-(a7)
		Bsr.w	Fire_Weapon
		Movem.l	(a7)+,d0-d7/a0-a6
	GO_NWpn:

		Movem.l	(a7)+,d0-d7/a0-a6
		Rts
*---------------
Game_Move2:	;(A5=ObjectListPtr)
		Move.l	20(a5),a1	;MovementPtr
		Lea	64-16(a5),a4
		Clr	d7
		Move.l	48(a5),08(a5)
		Move.l	52(a5),12(a5)
	*-- Do Movement Parts
	GM_LpP:	Add	#16,a4		;Next ObjectList MovementPart
		Move	d7,d0
		Cmp	6(a1),d7	;Any more Parts?
		Beq.w	GM_FinP		;+ No
		Add	d0,d0
		Move	08(a1,d0.w),d0
		Lea	00(a1,d0.w),a3
		Move	(a3),d2
		Cmp	#1,d2
		Beq.b	GM_Fre
		Cmp	#2,d2
		Beq.w	GM_Sin
		Cmp	#3,d2
		Beq.w	GM_Lin

	GM_NxtP:Addq	#1,d7		;Count Parts
		Bra.b	GM_LpP
	*-- Freehand Part (FreeFlags.B.05, RecDelay.W.06, Amount.W.12)
	GM_Fre:	Subq	#1,GM_VblCnt		;Count Delay
		Ble.b	GM_New			;Count finished. Get new coords
		Bra.b	GM_NCo
	GM_New:	Move	06(a3),GM_VblCnt	;Restart counter
		Move	(a4),d0			;Get coord counter
		Cmp	12(a3),d0		;End of coordinates?
		Bge.b	GM_NCo			;Yes!
		Lsl	#2,d0			;Multiply by 4

		Btst	#0,05(a3)		;FreeX?
		Beq.b	GM_NoX			;No!
		Moveq.l	#0,d1
		Move	14(a3,d0.w),d1		;Get X-Coord
		Swap	d1
		Sub.l	GM_XInt(pc),d1		;Find distance
		Asr.l	#8,d1
		Divs	06(a3),d1		;Divide by VBLs
		Move	d1,GM_DeltaX
		
	GM_NoX:	Btst	#1,05(a3)		;FreeY?
		Beq.b	GM_NoY			;No!
		Moveq.l	#0,d1
		Move	16(a3,d0.w),d1		;Get X-Coord
		Swap	d1
		Sub.l	GM_YInt(pc),d1		;Find distance
		Asr.l	#8,d1
		Divs	06(a3),d1		;Divide by VBLs
		Move	d1,GM_DeltaY

	GM_NoY:	Add	#1,(a4)			;Count coordinates
	GM_NCo:	Move	GM_DeltaX(pc),d0
		Ext.l	d0
		Asl.l	#8,d0
		Add.l	d0,GM_XInt		;Add to X-coord
		Move	GM_DeltaY(pc),d0
		Ext.l	d0
		Asl.l	#8,d0
		Add.l	d0,GM_YInt		;Add to Y-coord
		
		Move.l	GM_XInt(pc),d0		;Add X
		Add.l	d0,08(a5)		;+
		Move.l	GM_YInt(pc),d0		;Add Y
		Add.l	d0,12(a5)		;+
		Bra.w	GM_NxtP

GM_VblCnt:	Dc	0
GM_DeltaX:	Dc	0
GM_DeltaY:	Dc	0
GM_DDXInt:	Dc	0
GM_DDXFrc:	Dc	0
GM_DDYInt:	Dc	0
GM_DDYFrc:	Dc	0
GM_XInt:	Dc	0
GM_XFrc:	Dc	0
GM_YInt:	Dc	0
GM_YFrc:	Dc	0

	*-- Sine Part (Height.W.04, Speed.W.06, Start.W.08, Angle.W.10)
	GM_Sin:	Move	(a4),d0
		Jsr	GetSin	;###
		Muls	4(a3),d1
		Move	10(a3),d0
		Beq.b	GM_000
		Cmp	#90,d0
		Beq.b	GM_090
		Cmp	#135,d0
		Beq.b	GM_135
		;Cmp	#45,d0
		;Beq.w	GM_045

	GM_045:	Add.l	d1,08(a5)
	GM_090:	Add.l	d1,12(a5)
		Bra.b	GM_SinF

	GM_135:	Add.l	d1,12(a5)
		Neg.l	d1
	GM_000:	Add.l	d1,08(a5)

	GM_SinF:Move	6(a3),d0
		Add	d0,(a4)
		Bra.w	GM_NxtP

	*-- Line Part (XSpeed.L.04, YSpeed.L.06)
	GM_Lin:	Move.l	(a4),d0
		Add.l	d0,8(a5)
		Move.l	4(a4),d0
		Add.l	d0,12(a5)

		Move.l	4(a3),d0
		Add.l	d0,(a4)
		Move.l	8(a3),d0
		Add.l	d0,4(a4)
		Bra.w	GM_NxtP
		
	GM_FinP:Rts
*---------------
Game_Move:	Move	#64,GM_Cnt
		Move.l	Mem_Objects,a5	;###

	GM_Nxt:	Move	(a5),d7
		Bpl.b	GM_NOb		;Occupied?

		Btst	#1,d7		;Is Animation?
		Beq.b	GM_NAn		;Yes!
		Bsr.b	GM_Anim
	GM_NAn:
		Move	(a5),d7
		Btst	#5,d7		;Is Movement?
		Bne.b	GM_Move		;Yes!
		Btst	#6,d7		;Is Weapon?
		Bne.b	GM_Weap		;Yes!
		Bra.b	GM_Fin		;Is nothing...

	GM_Move:Bsr.w	Game_Move2
		Bra.b	GM_Fin

	GM_Weap:Move.l	64(a5),d0
		Add.l	d0,08(a5)
		Move.l	68(a5),d0
		Add.l	d0,12(a5)
		Bra.w	GM_Fin

	GM_Fin:	Move	02(a5),d0
		Bmi.b	GM_Inf
		Addq	#1,02(a5)	;Add Age
	GM_Inf:	Move	40(a5),d0
		Cmp	02(a5),d0	;Age>Duration?
		Bhi.b	GM_NOld
		Clr	(a5)
		Subq	#1,GM_OutCnt
	GM_NOld:
	GM_NOb:	Add	#256,a5
		Subq	#1,GM_Cnt
		Bne.b	GM_Nxt
		Rts

	GM_Anim:Subq	#1,38(a5)		;AnimTimer
		Bpl.w	DFS_Ok
	*-- Choose next Anim frame
		Cmp.b	#3,32(a5)		;AnimCon=Random?
		Bne.b	CN_NCn3
		Cmp	#1,28(a5)		;AnimTotal=1?
		Beq.w	CN_End
	CN_Try:	Jsr	GetRnd			;###
		Move	Rnd,d0			;###
		Mulu	28(a5),d0		;Rnd*AnimTotal
		Swap	d0
		Addq	#1,d0
		Cmp	36(a5),d0		;RndFrame=AnimFrame?
		Beq.b	CN_Try
		Move	d0,36(a5)		;AnimFrame=RndFrame
		Bra.w	CN_End

	CN_NCn3:Move	36(a5),d0		;Get AnimFrame?
		Cmp	28(a5),d0		;AnimTotal=AnimFrame?
		Bne.b	CN_NLst
		Move.b	32(a5),d0		;AnimCon=Loop?
		Bne.b	CN_NCL0
		Move.b	33(a5),d0		;AnimDir=Forward?
		Bne.b	CN_NCL0
		Move	#1,36(a5)		;AnimFrame=1
		Bra.b	CN_End

	CN_NCL0:Cmp.b	#1,32(a5)		;AnimCon=PingPong?
		Bne.b	CN_NCL1
		Move	34(a5),d0		;Get AnimDelta
		Bmi.b	CN_Nxt
		Neg	34(a5)			;Neg AnimDelta
		Bra.b	CN_Nxt

	CN_NCL1:Cmp.b	#2,32(a5)		;AnimCon=Once?
		Bne.b	CN_NCL2
		Move.b	33(a5),d0		;AnimDir=Forward?
		Beq.b	CN_Quit			;+

	CN_NCL2:Bra.b	CN_N1st

	CN_NLst:Cmp	#1,36(a5)		;AnimFrame=1?
		Bne.b	CN_N1st

		Move.b	32(a5),d0		;AnimCon=Loop?
		Bne.b	CN_NCF0
		Cmp.b	#1,33(a5)		;AnimDir=Backward?
		Bne.b	CN_NCF0
		Move	28(a5),36(a5)		;AnimFrame=AnimTotal
		Bra.b	CN_End

	CN_NCF0:Cmp.b	#1,32(a5)		;AnimCon=PingPong?
		Bne.b	CN_NCF1
		Move	34(a5),d0		;Get AnimDelta
		Bpl.b	CN_Nxt
		Neg	34(a5)			;Neg AnimDelta
		Bra.b	CN_Nxt

	CN_NCF1:Cmp.b	#2,32(a5)		;AnimCon=Once?
		Bne.b	CN_NCF2
		Move.b	33(a5),d0		;AnimDir=Backward?
		Bne.b	CN_Quit
	CN_NCF2:
	CN_N1st:
	CN_Nxt:	Move	34(a5),d0		;Get AnimDelta
		Add	d0,36(a5)		;Frame=Frame+Delta

	CN_End:	Bra.b	GA_Ok			;To be continued...

	CN_Quit:Btst	#3,(a5)			;Remove if end Anim?
		Beq.b	GA_Ok
		Clr	(a5)
		Subq	#1,GM_OutCnt
		Bra.b	DFS_Ok
	*-- Get WaitValue
	GA_Ok:	Move	30(a5),d7	;Get AnimDelay
		Move.l	16(a5),a0	;Find Frame (A1->Address) ###
		Move	36(a5),d0	;Get AnimFrame
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
		Clr	d0
		Move.b	(a1),d0
		Mulu	d0,d7
		Subq	#1,d7
		Move	d7,38(a5)	;AnimTimer
	DFS_Ok:	Rts

	GM_Cnt:	Dc	0
GM_OutCnt:	Dc	0
*---------------
;Game_Remove:	Move.l	SaveL2Cnt(pc),a0
;		Move.l	SaveL2A(pc),a3
;		Move	#$8400,$96(a6)		;BlitterNasty On
;	RB_BF1:	Btst	#14,$02(a6)
;		Bne.b	RB_BF1
;		Move	#$09f0,$40(a6)		;CON0
;		Clr	$42(a6)			;CON1
;		Clr	$64(a6)			;AMOD
;		Move.l	#$ffffffff,$44(a6)	;AFWM + ALWM
;	RB_Nxt:	Cmp.l	a0,a3
;		Beq.b	RB_End
;		Move.l	-(a0),a1
;		Move.l	-(a0),a2
;		Move	-(a0),d1
;		Move	-(a0),d2
;		Move	-(a0),d3
;		Move	Depth(pc),d7
;		Subq	#1,d7
;	RB_BLp:	Btst	#14,$02(a6)
;		Bne.b	RB_BLp
		Move	d1,$66(a6)		;DMOD
		Move.l	a2,$50(a6)		;APT
		Move.l	a1,$54(a6)		;DPT
		Move	d3,$58(a6)		;SIZE
		Add	DstS(pc),a1		;Next destination bpl
		Add	d2,a2			;Next source bpl
		Dbf	d7,RB_BLp
		Bra.b	RB_Nxt
;	RB_End:	Move	#$0400,$96(a6)		;BlitterNasty Off
		Lea	SaveL2Cnt(pc),a0
		Move.l	SaveL2A(pc),(a0)
		Lea	SaveB2Cnt(pc),a0
		Move.l	SaveB2A(pc),(a0)
		Rts
*---------------
Game_Remove:	Move.l	SaveL2Cnt(pc),a0
		Move.l	SaveL2A(pc),a3

	RB_Nxt:	Cmp.l	a0,a3
		Beq.b	RB_End
		Move.l	-(a0),a1
		Move.l	-(a0),a2
		Move	-(a0),d1
		Move	-(a0),d2
		Move	-(a0),d3
		Move	Depth(pc),d7
		Subq	#1,d7

		Move.w	d3,d0
		And.w	#%111111,d0
		Lsr.w	#6,d3

	RB_BLp:	
		Move.l	a1,a5
		Move.l	a2,a4
		Move.w	d3,d5
		
	GR_Lin:	Move.w	d0,d4
	GR_Wrd:	Move.w	(a4)+,(a5)+
		Subq.w	#1,d4
		Bne.b	GR_Wrd
		Add.w	d1,a5
		Subq.w	#1,d5
		Bne.b	GR_Lin
		
		Add	DstS(pc),a1		;Next destination bpl
		Add	d2,a2			;Next source bpl
		Dbf	d7,RB_BLp
		Bra.b	RB_Nxt
	RB_End:	Lea	SaveL2Cnt(pc),a0
		Move.l	SaveL2A(pc),(a0)
		Lea	SaveB2Cnt(pc),a0
		Move.l	SaveB2A(pc),(a0)
		Rts
*---------------
Fire_Weapon:	Move.l	Mem_WeapList,a2	;###
		Clr.l	d0
		Move	FW_Wpn(pc),d0
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.w	FW_End
		Move.l	(a2),a1
	*-- Find Powerup (A1->Address)
		Move	Cur_Powerup,d0	;###
		Add	d0,d0
		Move	08-2(a1,d0.w),d0
		Lea	00(a1,d0.w),a1

		Move	6(a1),FW_Cnt
		Move	(a1),d6		;Amount

		Move	GM_OutCnt(pc),d0
		Add	d6,d0
		Cmp	8(a1),d0
		Bgt.w	FW_End
	*-- Play sound
		Move	10(a1),d0
		Bmi.b	FWS_End
		Move	d0,Cur_Sond
		Movem.l	a1/d6,-(a7)
		Bsr.w	Sond_Play
		Movem.l	(a7)+,a1/d6
	FWS_End:

		Move.l	a1,a3

	FW_Next:Add	#64,a1

		Move.l	a1,-(a7)
		Jsr	Find_Object_Vacancy	;###
		Move.l	(a7)+,a1
		Move.l	a5,d0
		Beq.w	FW_Fin
		Move	#$9040,(a5)	;Occupied,RemoveOffScreen,Weapon
		Clr	02(a5)

		Move.l	a1,24(a5)	;WeaponShot

		Addq	#1,GM_OutCnt

		Move	28(a1),40(a5)	;Duration

		Move	(a1),d7
		Btst	#0,d7
		Bne.b	FW_Piec
		Btst	#1,d7
		Bne.b	FW_Anim
		Btst	#2,d7
		Bne.w	FW_Objc
		Bra.w	FW_Fin

	FW_Piec:Bset	#0,1(a5)	;Set Piece bit.
		Move	2(a1),Cur_Piec
		Jsr	Get_Piec_LAdr
		Move.l	(a2),a0
		Move.l	a0,16(a5)
		Move.l	08(a1),64(a5)
		Move.l	12(a1),68(a5)
		Move.b	22(a1),42(a5)	;Piece Flags

		Move	FW_X(pc),d0
		Add	16(a1),d0
		Move	d0,08(a5)
		Clr	10(a5)
		
		Move	FW_Y(pc),d0
		Add	18(a1),d0
		Move	d0,12(a5)
		Clr	14(a5)

		Bra.w	FW_Fin

	FW_Anim:Bset	#1,1(a5)	;Set Animation bit.
		Move.l	Mem_AnimList,a2	;###
		Clr.l	d0
		Move	2(a1),d0
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move.l	(a2),a0
	*-- Prepare Object Anim (A5=ObjectListAdr, A0=AnimAdr)
		Move.l	a0,16(a5)	;GraphicsPtr
		Bset	#1,1(a5)	;Set Animation bit.
		Clr	d0
		Move.b	6(a0),d0
		Move	d0,28(a5)	;AnimTotal
		Move	20(a1),30(a5)	;Copy Weap_ADel
		Move.b	22(a1),32(a5)	;Copy Weap_ACon
		Move.b	23(a1),33(a5)	;Copy Weap_ADir
		Move	#1,36(a5)	;AnimFrame
		Move	#1,34(a5)	;AnimDelta
		Move.b	33(a5),d0	;Check AnimDir
		Beq.b	FW_DOk
		Move	28(a5),36(a5)	;AnimFrame=AnimTotal
		Move	#-1,34(a5)	;AnimDelta
	FW_DOk:	Clr	38(a5)		;AnimTimer=0
		Cmp.b	#3,32(a5)
		Bne.b	FW_NRn
		Jsr	GetRnd	;###
		Move	Rnd,d0	;###
		Mulu	28(a5),d0	;Rnd*AnimTotal
		Swap	d0
		Addq	#1,d0
		Move	d0,36(a5)
	*-- Get WaitValue
	FW_NRn:	Move	30(a5),d7	;AnimDelay
		Move	36(a5),d0	;AnimFrame
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a2
		Clr	d0
		Move.b	(a2),d0
		Mulu	d0,d7
		Subq	#1,d7
		Move	d7,38(a5)

		Move.l	08(a1),64(a5)
		Move.l	12(a1),68(a5)

		Move	MousX(pc),d0
		Lsr	#1,d0
		Add	16(a1),d0
		Move	d0,08(a5)
		Clr	10(a5)
		
		Move	MousY(pc),d0
		Lsr	#1,d0
		Add	18(a1),d0
		Move	d0,12(a5)
		Clr	14(a5)

		Bra.b	FW_Fin

	FW_Objc:Move.l	Mem_ObjcList,a2	;###
		Clr.l	d0
		Move	2(a1),d0
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.b	FW_Fin

		Bset	#7,01(a5)	;Set Object bit
		Move.l	(a2),44(a5)	;Object

		;Move.l	08(a1),64(a5)
		;Move.l	12(a1),68(a5)

		Move	MousX(pc),d0
		Lsr	#1,d0
		Add	16(a1),d0
		Move	d0,08(a5)
		Clr	10(a5)
		
		Move	MousY(pc),d0
		Lsr	#1,d0
		Add	18(a1),d0
		Move	d0,12(a5)
		Clr	14(a5)
		
		Move	08(a3),48(a5)
		Move	12(a3),52(a5)


	FW_Fin:	Subq	#1,d6
		Bne.w	FW_Next

	FW_End:	Rts
	FW_One:	Dc	0
	FW_Cnt:	Dc	1

	FW_X:	Dc	0
	FW_Y:	Dc	0
	FW_Wpn:	Dc	0
*---------------
Game_Animate:	Move.l	16(a5),a0		;Get GraphicsPtr
	*-- Find Frame (A1->Address)
		Move	36(a5),d0		;Get AnimFrame
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a1
	*-- Get number of Pieces, and first Piece address (A1)
		Move.b	(a1)+,d0
		Move.b	(a1)+,DF_Pieces
		Move.l	a1,DF_Address
	*-- Draw Frame
	DFS_Nxt:Subq.b	#1,DF_Pieces
		Bmi.b	DFS_Fin
		Move.l	DF_Address,a1	;###
		Move	(a1)+,d0
		Move	(a1)+,d2
		Move	(a1)+,d3
		Move	(a1)+,DFS_Flags
		Move.l	a1,DF_Address
	*-- Find piece, and check if it exists
		Move.l	Mem_PiecList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0		;Multiply by 32		
		Add.l	d0,a2
		Tst.l	(a2)		;Any Piece?
		Beq.b	DFS_No		;No
		Move.l	(a2),a2		;Get PieceData Address

		Add	08(a5),d2	;X
		Add	ScrX(pc),d2	;+
		Add	12(a5),d3	;Y
		Add	ScrY(pc),d3	;+
		Bsr.w	Game_BlitPiece

	DFS_No:	Bra.b	DFS_Nxt
	DFS_Fin:Rts
DFS_Flags:	Dc.b	0
DFS_Value:	Dc.b	0
*---------------
Game_EndShot:	Movem.l	d0-d7/a0-a6,-(a7)
		Btst	#2,(a5)		;Already EndUnit?
		Bne.w	GES_End		;Yes, End
		Move.l	24(a5),a1
		Btst	#6,1(a5)	;Is this a Weapon?
		Beq.w	GES_End		;No, End
	*-- Play sound
		Move	46(a1),d0
		Bmi.b	GES_NSn
		Move	d0,Cur_Sond
		Movem.l	a1/a5/d6,-(a7)
		Bsr.w	Sond_Play
		Movem.l	(a7)+,a1/a5/d6
	GES_NSn:

		Move	#$9440,(a5) ;Occupied,RemoveOffScreen,EndUnit,Weapon
		Clr	02(a5)		;Age=0

		Move	30(a1),d7	;Get EndType
		Btst	#0,d7
		Bne.b	GES_Pi
		Btst	#1,d7
		Bne.b	GES_An
		Btst	#2,d7
		Bne.w	GES_Ob
		Bra.w	GES_Non

	GES_Pi:	Bset	#0,1(a5)	;Set Piece bit.
		Move	32(a1),d0
		Bmi.w	GES_Non
		Move	d0,Cur_Piec	;Graphics Pointer
		Jsr	Get_Piec_LAdr	;+
		Move.l	(a2),a0		;+
		Move.l	a0,16(a5)	;+
		Clr.l	64(a5)		;XSpeed=0
		Clr.l	68(a5)		;YSpeed=0
		Move.b	36(a1),42(a5)	;End Piece Flags
		Move	42(a1),d0	;Add EndOffset to Position
		Add	d0,08(a5)	;+
		Move	44(a1),d0	;Add EndOffset to Position
		Add	d0,12(a5)	;+		
		Move	#2,40(a5)	;Duration=1
		Bra.w	GES_End

	GES_An:	Bset	#1,1(a5)	;Set Animation bit.
		Move.l	Mem_AnimList,a2	;###
		Clr.l	d0
		Move	32(a1),d0
		Bmi.w	GES_Non
		Lsl.l	#5,d0
		Add.l	d0,a2
		Move.l	(a2),a0
	*-- Prepare Object Anim (A5=ObjectListAdr, A0=AnimAdr)
		Move.l	a0,16(a5)	;GraphicsPtr
		Bset	#1,1(a5)	;Set Animation bit.
		Bset	#3,(a5)		;Set 'Remove if end Anim' bit.
		Clr	d0
		Move.b	6(a0),d0
		Move	d0,28(a5)	;AnimTotal
		Move	34(a1),30(a5)	;Copy Weap_EndADel
		Move.b	36(a1),32(a5)	;Copy Weap_EndACon
		Move.b	37(a1),33(a5)	;Copy Weap_EndADir
		Move	#1,36(a5)	;AnimFrame
		Move	#1,34(a5)	;AnimDelta
		Move.b	33(a5),d0	;Check AnimDir
		Beq.b	GES_DOk
		Move	28(a5),36(a5)	;AnimFrame=AnimTotal
		Move	#-1,34(a5)	;AnimDelta
	GES_DOk:Clr	38(a5)		;AnimTimer=0
		Cmp.b	#3,32(a5)
		Bne.b	GES_NRn
		Jsr	GetRnd	;###
		Move	Rnd,d0	;###
		Mulu	28(a5),d0	;Rnd*AnimTotal
		Swap	d0
		Addq	#1,d0
		Move	d0,36(a5)
	*-- Get WaitValue
	GES_NRn:Move	30(a5),d7	;AnimDelay
		Move	36(a5),d0	;AnimFrame
		Add	d0,d0
		Move	10-2(a0,d0.w),d0
		Lea	00(a0,d0.w),a2
		Clr	d0
		Move.b	(a2),d0
		Mulu	d0,d7
		Subq	#1,d7
		Move	d7,38(a5)

		Move	42(a1),d0	;Add EndOffset to Position
		Add	d0,08(a5)	;+
		Move	44(a1),d0	;Add EndOffset to Position
		Add	d0,12(a5)	;+
		Clr.l	64(a5)		;XSpeed=0
		Clr.l	68(a5)		;YSpeed=0
		Move	#-1,40(a5)	;Duration=Infinite
		Bra.b	GES_End

	GES_Ob:	Move.l	Mem_ObjcList,a2	;###
		Clr.l	d0
		Move	32(a1),d0
		Bmi.b	GES_Non
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.b	GES_Non

		Bset	#7,01(a5)	;Set Object bit
		Move.l	(a2),44(a5)	;Object
		Move	42(a1),d0	;Add EndOffset to Position
		Add	d0,08(a5)	;+
		Move	44(a1),d0	;Add EndOffset to Position
		Add	d0,12(a5)	;+
		Clr.l	64(a5)		;XSpeed=0
		Clr.l	68(a5)		;YSpeed=0
		Move	#-1,40(a5)	;Duration=Infinite
		Bra.b	GES_End

	GES_Non:Clr	(a5)
		Subq	#1,GM_OutCnt

	GES_End:Movem.l	(a7)+,d0-d7/a0-a6
		Rts
*---------------
Game_BlitPiece:	;(A2=PieceAdr, D2=X, D3=Y, DFS_Flags=Piec_Flags)
		Cmp	#64,GO_Cnt
		Bne.b	GBP_N1

		Move	MousX(pc),d0
		Lsr	#1,d0
		Add	d0,d2
		Move	MousY(pc),d0
		Lsr	#1,d0
		Add	d0,d3

	GBP_N1:	Move	#-2,Game_SrcMod		;If no clip, SourceMod=-2
		Clr	Game_AdrAdd		;If no clip, AdressAdd=0
		Clr	Game_YAdd		;If no clip, YAdd=0
		Move	16(a2),Game_Width
		And	#$3f,Game_Width
		Move	8(a2),d5		;D5=YSize
	*-- Dest Modulo	(D1)
		Move	BytWidth(pc),d1		;D1=ScrWidth-2-PieceWidth
		Subq	#2,d1			;+
		Sub	14(a2),d1		;+
	*-- Make mask
		Move.l	Mem_MaskBuffer,a1	;###
		Move.l	a2,a4
		Add.l	24(a2),a4
	*-- Mask Bpl Address (A3)
		Move.l	MaskBpl(pc),a3
		Move	d2,d0
		Asr	#3,d0
		Add	d0,a3
		Move	d3,d0
		Muls	BytWidth(pc),d0
		Add.l	d0,a3
	*-- Shift
		Moveq.l	#16,d4
		Move	d2,d6
		And	#$f,d6
		Beq.b	GBP_NSh
		Sub	d6,d4
		Subq.l	#2,a4
		Bra.b	GBP_Sh
	GBP_NSh:Addq.l	#2,a1
	GBP_Sh:	And	#$f,d4
		Ror	#4,d4
	GBP_BF1:Btst	#14,$02(a6)		;Wait for blitter
		Bne.b	GBP_BF1			;+
		Move	#$0d30,$40(a6)		;CON0
		Move	d4,$42(a6)		;CON1
		Move.l	a3,$4c(a6)		;BPT
		Move.l	a4,$50(a6)		;APT
		Move.l	a1,$54(a6)		;DPT
		Move	d1,$62(a6)		;BMOD
		Move.l	#$fffe0000,$64(a6)	;AMOD + DMOD
		Move.l	#$ffffffff,$44(a6)	;AFWM + ALWM
		Move	16(a2),$58(a6)		;SIZE
	*-- Choose Y-Clip routines.
		Btst	#5,DFS_Flags		;Flip Y?
		Beq.b	GBP_NF1			;No
	*-- Check Y1 limit.
		Move	ScrY(pc),d0		;Is ScrY-Y>0?
		Sub	d3,d0			;+
		Ble.b	GBP_FY1			;+
		Clr	d3			;Y=0
		Sub	d0,d5			;Reduce height
		Ble.w	GBP_Out			;Height<=0?
	*-- Check Y2 limit.
	GBP_FY1:Move	d3,d0			;Y+YSize-LimY2-ScrY>0?
		Add	8(a2),d0		;+
		Sub	Game_LimY2(pc),d0	;+
		Sub	ScrY(pc),d0		;+
		Ble.b	GBP_FY2			;+
		Move	d0,Game_YAdd		;Save value
		Sub	d0,d5			;Reduce height
		Ble.w	GBP_Out			;Height<=0?
	GBP_FY2:Bra.b	GBP_Y2			;Skip other Y-Clip rtn
	*-- Check Y1 limit.
	GBP_NF1:Move	ScrY(pc),d0		;Is ScrY-Y>0?
		Sub	d3,d0			;+
		Ble.b	GBP_Y1			;+
		Move	d0,Game_YAdd		;Save value
		Clr	d3			;Y=0
		Sub	d0,d5			;Reduce height
		Ble.w	GBP_Out			;Height<=0?
	*-- Check Y2 limit.
	GBP_Y1:	Move	d3,d0			;Y+YSize-LimY2-ScrY>0?
		Add	8(a2),d0		;+
		Sub	Game_LimY2(pc),d0	;+
		Sub	ScrY(pc),d0		;+
		Ble.b	GBP_Y2			;+
		Sub	d0,d5			;Reduce height
		Ble.w	GBP_Out			;Height<=0?
	*-- Check X2 limit.
	GBP_Y2:	Move	d2,d0			;X+XSize-LimX2-ScrX>0?
		Add	6(a2),d0		;+
		Sub	Game_LimX2(pc),d0	;+
		Sub	ScrX(pc),d0		;+
		Ble.b	GBP_X2			;+
		Lsr	#4,d0			;Pixels/16
		Sub	d0,Game_Width		;Reduce Width
		Ble.w	GBP_Out			;Width<=0?
		Add	d0,d0			;Words*2
		Add	d0,d1			;Add to DstMod
		Add	d0,Game_SrcMod		;Add to SrcMod
	*-- Destination Address (A3)
	GBP_X2:	Move.l	Dst2A(pc),a3
		Move	d2,d0
		Lsr	#3,d0
		Add	d0,a3
		Move	d3,d0
		Mulu	BytWidth(pc),d0
		Add.l	d0,a3
	*-- Flip Y.
		Btst	#5,DFS_Flags		;Flip Y?
		Beq.b	GBP_NF2			;No
		Sub	BytWidth(pc),d1		;Modulo=Backward
		Sub	BytWidth(pc),d1		;+
		Move	d5,d0			;(Height-1)*ScreenWidth
		Subq	#1,d0			;+
		Mulu	BytWidth(pc),d0		;+
		Add	d0,a3			;+
	*-- Check X1 limit.
	GBP_NF2:Move	ScrX(pc),d0		;ScrX-X>0?
		Sub	d2,d0			;+
		Ble.b	GBP_X1			;+
		Lsr	#4,d0			;Pixels/16
		Sub	d0,Game_Width		;Reduce Width
		Ble.w	GBP_Out			;Width<=0?
		Add	d0,d0			;Words*2
		Add	d0,d1			;Add to DstMod
		Add	d0,Game_SrcMod		;Add to SrcMod
		Add	d0,a3			;Add to DstAdr
		Move	d0,Game_AdrAdd		;Save in AdrAdd
	*-- BLTSIZE (D5)
	GBP_X1:	Lsl	#6,d5			;Create BLTSIZE code
		Or	Game_Width(pc),d5	;+
	*-- BLTCON0/BLTCON1 (D2/D3)
		And	#$f,d2
		Ror	#4,d2
		Move	d2,d3
		Or	#$fca,d2
	*-- Background collision check
		Btst	#7,DFS_Flags		;Collision on?
		Beq.b	GBP_NCl			;No
	*-- Back Collision Help Bitplane (D6)
		Move.l	a3,d6
		Sub.l	Dst2A(pc),d6
		Add.l	CollBpl(pc),d6
	*-- Piece Collision Mask (D7)
		Move.l	a2,d7
		Add.l	20(a2),d7		;ColMask

		Move	Game_YAdd(pc),d4
		Mulu	14(a2),d4
		Add	Game_AdrAdd(pc),d4
		Add.l	d4,d7
		Add.l	d4,d6
	*-- BLTCON0 (D4)
		Move	d3,d4
		Or	#$aa0,d4		;Use=AC, Minterm=A&C.
	*-- Blitter collision check.
	GBP_BF2:Btst	#14,$02(a6)
		Bne.b	GBP_BF2
		Move	d4,$40(a6)		;CON0
		Clr	$42(a6)			;CON1
		Move.l	d7,$50(a6)		;APT
		Move.l	d6,$48(a6)		;CPT
		Move	Game_SrcMod(pc),$64(a6)	;AMOD
		Move	d1,$60(a6)		;CMOD
		Clr	$46(a6)			;ALWM (AFWM=^)
		Move	d5,$58(a6)		;SIZE
	*-- Get Mask address
	GBP_NCl:Move.l	Mem_MaskBuffer,d6	;###
		Addq.l	#2,d6
	*-- Get Graphics address
		Lea	28(a2),a0

		Move.l	SaveB2Cnt(pc),d4

		Move	Game_Width(pc),d7
		Add	d7,d7
		Mulu	Game_YAdd(pc),d7
		Add	Game_AdrAdd(pc),d7
		Add.l	d7,d4

		Move	14(a2),d7
		Addq	#2,d7
		Mulu	Game_YAdd(pc),d7
		Add	Game_AdrAdd(pc),d7
		Add.l	d7,d6

		Move	Game_YAdd(pc),d7
		Mulu	14(a2),d7
		Add	Game_AdrAdd(pc),d7
		Add	d7,a0

		Lea	SaveL2Cnt(pc),a4
		Move.l	(a4),a1
		Move	8(a2),d0		;YSize
		Add	d0,d0			;*2
		Add	12(a2),d0		;+BplSize
		Ext.l	d0			;+
		Move	d5,(a1)+		;BltSize
		Move	d0,(a1)+		;BplSize
		Move	d1,(a1)+		;Modulo
		Move.l	d4,(a1)+		;SaveAdr
		Move.l	a3,(a1)+		;DstAdr
		Move.l	a1,(a4)
	*-- Read results of collision check
		Move	#$8400,$96(a6)		;BlitterNasty On
		Btst	#7,DFS_Flags		;Collision on?
		Beq.b	GBP_NC2			;No
	GBP_BF3:Btst	#14,$02(a6)		;Wait for blitter
		Bne.b	GBP_BF3			;+
		Move	$2(a6),d7		;Read DMACONR
		Btst	#13,d7			;Collision?
		Bne.b	GBP_NC2			;No!
		;Move	#$fff,$180(a6)		;Yes!

		Bsr.w	Game_EndShot
	GBP_NC2:
		Move.l	a3,a4			;Copy DstAdr
	*-- Save Background
		Move	Depth(pc),d7
		Subq	#1,d7
	GBP_BF4:Btst	#14,$02(a6)		;Wait for blitter
		Bne.b	GBP_BF4			;+
		Move.l	#$09f00000,$40(a6)	;CON0 + CON1
		Move	d1,$64(a6)		;AMOD
		Clr	$66(a6)			;DMOD
		Move.l	#$ffffffff,$44(a6)	;AFWM + ALWM
	GBP_SBL:Btst	#14,$02(a6)		;Wait for blitter
		Bne.b	GBP_SBL			;+
		Move.l	d4,$54(a6)		;DPT
		Move.l	a3,$50(a6)		;APT
		Move	d5,$58(a6)		;SIZE
		Add.l	d0,d4			;Add SaveBplSize
		Add	DstS(pc),a3		;Add ScreenBplSize
		Dbf	d7,GBP_SBL		;Loop
		Lea	SaveB2Cnt(pc),a3	;Store saveback pointer
		Move.l	d4,(a3)			;+
	*-- Draw Bob
		Move	10(a2),d7		;Piec_Depth
		Subq	#1,d7
	GBP_BF5:Btst	#14,$02(a6)		;Wait for blitter
		Bne.b	GBP_BF5			;+
		Move	d2,$40(a6)		;CON0
		Move	d3,$42(a6)		;CON1
		Clr	$46(a6)			;ALWM (AFWM=^)
		Move	d1,$60(a6)		;CMOD
		Move	Game_SrcMod(pc),d0
		Move	d0,$62(a6)		;BMOD
		Addq	#2,d0
		Move	d0,$64(a6)		;AMOD
		Move	d1,$66(a6)		;DMOD
	GBP_DBL:Btst	#14,$02(a6)		;Wait for blitter
		Bne.b	GBP_DBL			;+
		Move.l	a4,$48(a6)		;CPT
		Move.l	a0,$4c(a6)		;BPT
		Move.l	d6,$50(a6)		;APT
		Move.l	a4,$54(a6)		;DPT
		Move	d5,$58(a6)		;SIZE
		Add	12(a2),a0		;Add BplSize
		Add	DstS(pc),a4		;Add ScreenBplSize
		Dbf	d7,GBP_DBL		;Loop
		Move	#$0400,$96(a6)		;BlitterNasty Off
	GBP_End:Rts				;End

	GBP_Out:Move.b	(a5),d0
		Btst	#4,d0
		Beq.b	GBP_End
		Clr	(a5)
		Subq	#1,GM_OutCnt
		Rts

Game_LimX2:	Dc	319+16
Game_LimY2:	Dc	255
Game_SrcMod:	Dc	0
Game_AdrAdd:	Dc	0
Game_Width:	Dc	0
Game_YAdd:	Dc	0
*---------------
Mouse:		Move.b	$0a(a6),d0
		Move.b	MousLY(pc),d1
		Move.b	d0,MousLY
		Sub.b	d1,d0
		Ext.w	d0
		Move	d0,MousDY
		Add	d0,MousY
		Bpl.b	Mouse1
		Clr	MousY
	Mouse1:	Move	MousMY(pc),d7
		Cmp	MousY(pc),d7
		Bge.b	Mouse2
		Move	d7,MousY
	Mouse2:	Move.b	$0b(a6),d0
		Move.b	MousLX(pc),d1
		Move.b	d0,MousLX
		Sub.b	d1,d0
		Ext.w	d0
		Move	d0,MousDX
		Add	d0,MousX
		Bpl.b	Mouse3
		Clr	MousX
	Mouse3:	Move	MousMX(pc),d7
		Cmp	MousX(pc),d7
		Bge.b	Mouse4
		Move	d7,MousX
	Mouse4:	Rts
MousX:		Dc	0,0
MousY:		Dc	0,0
MousDX:		Dc	0
MousDY:		Dc	0
MousLX:		Dc.b	0,0
MousLY:		Dc.b	0,0
MousMX:		Dc	639
MousMY:		Dc	511
*---------------
Double:		Lea	VblC(pc),a0	;Clear Vbl-Counter
		Clr	(a0)		;+
		Lea	Dst1A(pc),a1	;Exchange Dst1A & Dst2A
		Lea	Dst2A(pc),a2	;+
		Move.l	(a1),d0		;+
		Move.l	(a2),(a1)	;+
		Move.l	d0,(a2)		;+
		Lea	SaveL1A(pc),a1	;Exchange SaveL1A & SaveL2A
		Lea	SaveL2A(pc),a2	;+
		Move.l	(a1),d0		;+
		Move.l	(a2),(a1)	;+
		Move.l	d0,(a2)		;+
		Lea	SaveL1Cnt(pc),a1;Exchange SaveL1Cnt & SaveL2Cnt
		Lea	SaveL2Cnt(pc),a2;+
		Move.l	(a1),d0		;+
		Move.l	(a2),(a1)	;+
		Move.l	d0,(a2)		;+
		Lea	SaveB1A(pc),a1	;Exchange SaveB1A & SaveB2A
		Lea	SaveB2A(pc),a2	;+
		Move.l	(a1),d0		;+
		Move.l	(a2),(a1)	;+
		Move.l	d0,(a2)		;+
		Rts			;End
*---------------
SetBPL:		Move.l	Dst2A(pc),a0
		Move	ScrX(pc),d0
		Move	ScrY(pc),d1
		Mulu	BytWidth(pc),d1
		Add	d1,a0
		Move	d0,d2
		Lsr	#3,d0
		Add	d0,a0
		Not	d2
		And	#$f,d2
		Move	d2,d3
		Lsl	#4,d3
		Add	d3,d2
		Move	DstS(pc),d0
		Move.l	Mem_Copper1,a5	;Get Scr label	###
		Addq.l	#Scr-Cop1,a5
		Move	d2,2(a5)
		Move	Depth(pc),d1
	BplLop:	Move.l	a0,d5
		Move	d5,10(a5)
		Swap	d5
		Move	d5,6(a5)
		Addq	#8,a5
		Add	d0,a0
		Subq	#1,d1
		Bne.b	BplLop
		Rts
BytWidth:	Dc	50
Depth:		Dc	4
ScrX:		Dc	$0000,$0000	;(D) Position of Scroll
ScrY:		Dc	$0000,$0000	;(D) Position of Scroll
SpeedX:		Dc.l	+$00010000	;(D) Scroll Speed
SpeedY:		Dc.l	+$00000000	;(D) Scroll Speed
Dst1A:		Dc.l	$1e0000		;Current Dest. Screen Address
Dst2A:		Dc.l	$1f0000		;Other   Dest. Screen Address
DstS:		Dc	12800		;Destination Bitplane Size
MaskBpl:	Dc.l	0
CollBpl:	Dc.l	0
SaveL1A:	Dc.l	0
SaveL2A:	Dc.l	0
SaveL1Cnt:	Dc.l	0
SaveL2Cnt:	Dc.l	0
SaveB1A:	Dc.l	0
SaveB2A:	Dc.l	0
SaveB2Cnt:	Dc.l	0
*---------------
Chip:		Lea	$dff000,a6
	*-- BPU3 (8Bpls)
		Move.l	Mem_Copper1,a5	;Get Scr label	###
		Add	#Cop1_BplCon0-Cop1,a5

		Move	Depth(pc),d0
		Ror	#4,d0
		Btst	#15,d0
		Beq.b	C_N8Bpl
		Bset	#4,d0
		Bclr	#15,d0
	C_N8Bpl:
		Bset	#9,d0
		Move	d0,(a5)
	*-- KillEHB	
		Move	#$000,$104(a6)
		Btst	#0,Prf_GfxFlags
		Beq.b	C_NAa
		Move	#$200,$104(a6)
	C_NAa:
	*-- Write Misc Registers
		Lea	ChipT(pc),a1
Chip2:		Move	(a1)+,d0
		Bmi.b	Chip1
		Move	(a1)+,0(a6,d0.w)
		Bra.b	Chip2
Chip1:		Rts
ChipT:		DC	$008E,$2c71,$0090,$2cd1	;DIWSTRT,DIWSTOP
		DC	$0092,$0020,$0094,$00d8	;DDFSTRT,DDFSTOP
		DC	$0108,$0002	;BPL1MOD
		DC	$010A,$0002	;BPL2MOD
		DC	$0100,$0200	;BPLCON0
		DC	$01FC,$0000	;FMODE (A1200)
		DC	-1
*---------------
Cop1:		DC	$0001,$FFFE
		DC	$009C,$8004 ;Request SOFT Interrupt
Scr:		DC	$0102,$0000 ;BPLCON1
		DC	$00E0,$0000,$00E2,$0000 ;BPL1PT
		DC	$00E4,$0000,$00E6,$0000 ;BPL2PT
		DC	$00E8,$0000,$00EA,$0000 ;BPL3PT
		DC	$00EC,$0000,$00EE,$0000 ;BPL4PT
		DC	$00F0,$0000,$00F2,$0000 ;BPL5PT
		DC	$00F4,$0000,$00F6,$0000 ;BPL6PT
		DC	$00F8,$0000,$00FA,$0000 ;BPL7PT
		DC	$00FC,$0000,$00FE,$0000 ;BPL8PT

		DC	$0100
Cop1_BplCon0:	Dc	$4200	;BPLCON0
		Dc	$180,0
		DC	$FFFF,$FFFE
*---------------
BltFinA:	Move	#$8400,$96(a6)
BltFin1:	Btst	#14,$02(a6)
		Bne.b	BltFin1
		Move	#$0400,$96(a6)
		Rts
BltFinB:	Btst	#14,$02(a6)
		Bne.b	BltFinB
		Rts
*---------------
Joystick:	Bsr.w	Read_Joystick
		Move.l	JoySX(pc),d1
		Move.l	JoySY(pc),d2
	*-- Thrust and brakes...
		Btst	#0,d7
		Beq.b	J_NUp
		Sub.l	JoyPosY(pc),d2
		Bra.b	J_NMiY
	J_NUp:	Btst	#2,d7
		Beq.b	J_NDn
		Add.l	JoyPosY(pc),d2
		Bra.b	J_NMiY
	J_NDn:	
		Tst.l	d2
		Bmi.b	J_NPlY
		Sub.l	JoyNegY(pc),d2
		Bpl.b	J_NPlY
		Clr.l	d2
	J_NPlY:
		Tst.l	d2
		Bpl.b	J_NMiY
		Add.l	JoyNegY(pc),d2
		Bmi.b	J_NMiY
		Clr.l	d2
	J_NMiY:
		Btst	#1,d7
		Beq.b	J_NRg
		Add.l	JoyPosX(pc),d1
		Bra.b	J_NMiX
	J_NRg:	Btst	#3,d7
		Beq.b	J_NLf
		Sub.l	JoyPosX(pc),d1
		Bra.b	J_NMiX
	J_NLf:	
		Tst.l	d1
		Bmi.b	J_NPlX
		Sub.l	JoyNegX(pc),d1
		Bpl.b	J_NPlX
		Clr.l	d1
	J_NPlX:
		Tst.l	d1
		Bpl.b	J_NMiX
		Add.l	JoyNegX(pc),d1
		Bmi.b	J_NMiX
		Clr.l	d1
	J_NMiX:
	*-- Max Speed.
		Move.l	JoyMaxX(pc),d0
		Cmp.l	d0,d1
		Ble.b	J_SX2
		Move.l	d0,d1
	J_SX2:
		Neg.l	d0
		Cmp.l	d0,d1
		Bge.b	J_SX1
		Move.l	d0,d1
	J_SX1:
		Move.l	JoyMaxX(pc),d0
		Cmp.l	d0,d2
		Ble.b	J_SY2
		Move.l	d0,d2
	J_SY2:
		Neg.l	d0
		Cmp.l	d0,d2
		Bge.b	J_SY1
		Move.l	d0,d2
	J_SY1:
	*-- Move it!
		Add.l	d1,MousX
		Add.l	d2,MousY
	*-- Coordinates limits.
		Move	MousX(pc),d0
		Bpl.b	J_OkX1
		Clr	MousX
		Clr.l	d1
	J_OkX1:
		Move	MousY(pc),d0
		Bpl.b	J_OkY1
		Clr	MousY
		Clr.l	d2
	J_OkY1:
		Move	MousMX(pc),d0
		Cmp	MousX(pc),d0
		Bge.b	J_OkX2
		Move	d0,MousX
		Clr.l	d1
	J_OkX2:
		Move	MousMY(pc),d0
		Cmp	MousY(pc),d0
		Bge.b	J_OkY2
		Move	d0,MousY
		Clr.l	d2
	J_OkY2:
		Move.l	d1,JoySX
		Move.l	d2,JoySY
		Rts
	JoySX:	Dc.l	0
	JoySY:	Dc.l	0
	JoyPosX:Dc.l	$8000
	JoyPosY:Dc.l	$8000
	JoyNegX:Dc.l	$8000
	JoyNegY:Dc.l	$8000
	JoyMaxX:Dc.l	$40000
	JoyMaxY:Dc.l	$40000
*---------------
Read_Joystick:	;(D7 -> Bit 0=U 1=R 2=D 3=L)
		Clr	d7
		Move	$0c(a6),d0
		Move	d0,d2
		Lsr	#1,d2
		Eor	d0,d2
		Btst	#8,d2
		Beq.b	RJ_1
		Bset	#0,d7
	RJ_1:	Btst	#0,d2
		Beq.s	RJ_2
		Bset	#2,d7
	RJ_2:	Btst	#1,d0
		Beq.s	RJ_3
		Bset	#1,d7
	RJ_3:	Btst	#9,d0
		Beq.s	RJ_4
		Bset	#3,d7
	RJ_4:	Rts
*---------------
Get:		Move	#1,KFlg
		Clr.l	d3
		Btst	#3,$bfed01	;Anything received yet?
		Beq.b	Get9
		Move.b	$bfec01,d3	;Read keydata.
		Bset	#6,$bfee01	;Handshake.
		Clr.b	$bfec01
		Move	#100,d7
Pau1:		Dbf	d7,Pau1
		Bclr	#6,$bfee01
		Btst	#0,d3		;Key Released?
		Beq.b	Get9		;Yes, Exit.
		Not.b	d3		;Calculate Position In Keytab.
		Lsr	#1,d3
		Lea	KeyTab(pc),a2
		Add	d3,a2
		Clr.l	d0		;Get Character.
		Move.b	(a2),d0
		Move.b	d0,GetKey2
		Clr	KFlg
	Get9:	Rts
	GetKey2:Dc	0
	KFlg:	Dc	0
*---------------
KeyTab:		DC.B $f5,$31,$32,$33,$34,$35,$36,$37 ;$00-$07
*---------------
;Point:		;Lea	Pointer(pc),a6
;		Move	MousX(pc),d2
;		Add	PointX(pc),d2
;		Move.b	3(a6),d5
;		And.b	#%11111000,d5
;		Btst	#0,d2
;		Beq.s	Point1
;		Bset	#0,d5
;	Point1:	Lsr	#1,d2
;		Move.b	d2,1(a6)
;		Move	MousY(pc),d2
;		Add	PointY(pc),d2
;		Move.b	d2,(a6)
;		Btst	#8,d2
;		Beq.s	Point2
;		Bset	#2,d5
;	Point2:	Add	PointL(pc),d2
;		Move.b	d2,2(a6)
;		Btst	#8,d2
;		Beq.s	Point3
;		Bset	#1,d5
;	Point3:	Move.b	d5,3(a6)
;		Rts
;	PointX:	Dc	122
;	PointY:	Dc	47
;	PointL:	Dc	11
*---------------
;Motors_Off:	Lea	$bfd100,a0
;		Move.b	#$ff,(a0)
;		Bclr	#3,(a0)
;		Move.b	#$ff,(a0)
;		Bclr	#4,(a0)
;		Move.b	#$ff,(a0)
;		Bclr	#5,(a0)
;		Move.b	#$ff,(a0)
;		Bclr	#6,(a0)
;		Rts
*---------------
Add_Score:	;(A0=Number to add to, A1=Number to add)
		Addq.l	#4,a0		;Start with the least
		Addq.l	#4,a1		;significant digits
		Clr	d1		;Clear X flag
		Abcd	d1,d1		;+
		Move.b	-(a1),d2	;Get number to add
		Move.b	-(a0),d1	;Get number to add to
		Abcd.b	d2,d1		;Add them
		Move.b	d1,(a0)		;Store the result
		Move.b	-(a1),d2	;And so on...
		Move.b	-(a0),d1	;.
		Abcd.b	d2,d1		;.
		Move.b	d1,(a0)		;.
		Move.b	-(a1),d2
		Move.b	-(a0),d1
		Abcd.b	d2,d1
		Move.b	d1,(a0)
		Move.b	-(a1),d2
		Move.b	-(a0),d1
		Abcd.b	d2,d1
		Move.b	d1,(a0)
		Rts	
*---------------
Sub_Score:	;(A0=Number to sub from, A1=Number to sub)
		Addq.l	#4,a0		;Start with the least
		Addq.l	#4,a1		;significant digits
		Clr	d1		;Clear X flag
		Abcd	d1,d1		;+
		Move.b	-(a1),d2	;Get number to sub
		Move.b	-(a0),d1	;Get number to sub from
		Sbcd.b	d2,d1		;Sub them
		Move.b	d1,(a0)		;Store the result
		Move.b	-(a1),d2	;And so on...
		Move.b	-(a0),d1	;.
		Sbcd.b	d2,d1		;.
		Move.b	d1,(a0)		;.
		Move.b	-(a1),d2
		Move.b	-(a0),d1
		Sbcd.b	d2,d1
		Move.b	d1,(a0)
		Move.b	-(a1),d2
		Move.b	-(a0),d1
		Sbcd.b	d2,d1
		Move.b	d1,(a0)
		Rts	
*---------------
Snap_PrevBuf:	Bra.w	Draw_Snapshot
*---------------
Draw_Snapshot:	Move.l	Mem_Screen,d0		;Any Snapshot?	###
		Beq.w	DSn_End			;No

		Lea	Snap_BM(pc),a0
		Move	BytWidth(pc),(a0)+
		Move	#256,(a0)+
		Move	Depth(pc),(a0)+
		Clr	(a0)+
		Move.l	Dst2A(pc),a1
		Lea	GSnap_PrevBuf(pc),a2
		Btst	#0,4(a2)
		Beq.b	DSn_Pr
		Move.l	Dst1A(pc),a1
	DSn_Pr:	Move.l	a1,d0
		Beq.b	DSn_End
		
		Move	ScrY(pc),d0
		Mulu	BytWidth(pc),d0
		Add	d0,a1
		Move	ScrX(pc),d0
		Lsr	#3,d0
		And	#$fffe,d0
		Add	d0,a1

		Move	Depth(pc),d7
	DSn_Lp:	Move.l	a1,(a0)+
		Add	DstS(pc),a1
		Subq	#1,d7
		Bne.b	DSn_Lp
		
Update_SnapShot:Lea	Snap_BM(pc),a0		;BitMap empty?
		Tst.l	8(a0)			;+
		Beq.b	DSn_End			;Yes

		Lea	Snap_Gfx(pc),a4
		Lea	SnapLay,a5	;###
		Jsr	Calc_Coord	;###
		Move.l	(a5),a3
		Move.l	12(a3),a3

		Move.l	a3,a1
		;Lea	GSnapZoom(pc),a0
		;Btst	#0,4(a0)
		;Bne.b	DSn_Zm

		Lea	Snap_BM(pc),a0
		Move.l	a0,BG_SrcBM
		Move	SnapX(pc),BG_SrcX
		Move	SnapY(pc),BG_SrcY
		Jsr	Blit_Gfx	;###
	DSn_End:Rts

Snap_BM:	Dc	40
		Dc	256
		Dc.b	0
		Dc.b	5
		Dc	0
		Blk.l	8,0
*---------------
Check_Snapshot:	Lea	Snap_NoGfx(pc),a0
		Move.l	Mem_Screen,d0	;###
		Beq.b	CS_NSn
		Lea	Snap_Gfx(pc),a0
	CS_NSn:	Move.l	a0,Snap_Jump
		Rts
*---------------
Upd_Snap_XY:	Lea	SnapLay,a5	;###
		Lea	Snap_Gfx(pc),a4
		Jsr	Calc_Coord	;###

		Move	X2,d0		;###
		Sub	X1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#352,d0
		Lea	Snap_Prop_X(pc),a0
		Move	#352,d2
		Sub	d1,d2
		Mulu	6(a0),d2
		Move.l	#65536,d3
		Sub	d0,d3
		Divu	d3,d2
		Move	d2,SnapX

		Move	Y2,d0		;###
		Sub	Y1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#256,d0
		Lea	Snap_Prop_Y(pc),a0
		Move	#256,d2
		Sub	d1,d2
		Mulu	8(a0),d2
		Move.l	#65536,d3
		Sub	d0,d3
		Divu	d3,d2
		Move	d2,SnapY
		Rts
*---------------
Snap_Offset:	Bsr.b	Upd_Snap_XY
		Bra.w	Draw_Snapshot		
*---------------
Upd_Snap_OffsD:	Move.l	Mem_Screen,d0		;Any Snapshot?	###
		Beq.w	USO_End			;No

		Lea	SnapLay,a5	;###
		Lea	Snap_Gfx(pc),a4
		Jsr	Calc_Coord	;###

		Move	X2,d0		;###
		Sub	X1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#352,d0
		Lea	Snap_Prop_X(pc),a0
		Move	d0,2(a0)
		Move	#352,d2
		Sub	d1,d2
		Move.l	#65536,d3
		Sub	d0,d3
		Mulu	SnapX(pc),d3
		Divu	d2,d3
		Move	d3,6(a0)

		Move	Y2,d0		;###
		Sub	Y1,d0		;###
		Move	d0,d1
		Swap	d0
		Clr	d0
		Divu	#256,d0
		Lea	Snap_Prop_Y(pc),a0
		Move	d0,4(a0)
		Move	#256,d2
		Sub	d1,d2
		Move.l	#65536,d3
		Sub	d0,d3
		Mulu	SnapY(pc),d3
		Divu	d2,d3
		Move	d3,8(a0)

		Lea	Snap_Prop_X(pc),a0
		Clr.l	d0
		Move	2(a0),d0
		Clr.l	d1
		Move	6(a0),d1
		Add.l	d1,d0
		Cmp.l	#$10000,d0
		Blo.b	USO_XOk
		Move	#$ffff,d0
		Sub	2(a0),d0
		Move	d0,6(a0)
	USO_XOk:
		Lea	Snap_Prop_Y(pc),a0
		Clr.l	d0
		Move	4(a0),d0
		Clr.l	d1
		Move	8(a0),d1
		Add.l	d1,d0
		Cmp.l	#$10000,d0
		Blo.b	USO_YOk
		Move	#$ffff,d0
		Sub	4(a0),d0
		Move	d0,8(a0)
	USO_YOk:
		Bra.w	Upd_Snap_XY

	USO_End:Lea	Snap_Prop_X(pc),a0
		Move	#$ffff,2(a0)
		Clr	6(a0)
		Lea	Snap_Prop_Y(pc),a0
		Move	#$ffff,4(a0)
		Clr	8(a0)
		Rts

SnapX:		Dc	0
SnapY:		Dc	0
*---------------
DrawList_Snap:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Snapshot8T

		Dc	'BX',000,011,-01,027
		
GSnapSelect:	Dc	'GD'
		Dc.l	$020100e1,0,0
		Dc	'BX',003,013,015,025
		Dc	'IM',005,015,9,Im_Select-Im

GSnap_PrevBuf:	Dc	'GD'
		Dc.l	$0201028B,0,Snap_PrevBuf
		Dc	'BX',020,013,032,025
		Dc	'IM',022,015,9,Im_PrevBuffer-Im

;GSnapZoom:	Dc	'GD'
;		Dc.l	$02010209,0,0	;Snap_Zoom
;		Dc	'BX',037,013,049,025
;		Dc	'IM',039,015,9,Im_Zoom-Im
;		Dc	'BX',050,013,083,025
;		Dc	'GD'
;		Dc.l	$02030235,0,0
;		Dc	'RC',052,015,061,023
;Snap_ZFactUpd:	Dc	'TX',055,022,-01,5
;		Dc.l	Snap_ZFactT
;		Dc	'GD'
;		Dc.l	$02010034,0,0	;Snap_ZoomMinus
;		Dc	'BX',064,015,072,023
;		Dc	'IM',066,019,1,Im_Minus-Im
;		Dc	'GD'
;		Dc.l	$02010033,0,0	;Snap_ZoomPlus
;		Dc	'BX',073,015,081,023
;		Dc	'IM',075,017,5,Im_Plus-Im

		Dc	'RO'
		Dc.l	Upd_Snap_OffsD

		Dc	'GD'
		Dc.l	$02020000,Snap_Prop_X,Snap_Offset
		Dc	'BX',000,-09,-10,-01
		Dc	'BX',020,-07,-40,-03

		Dc	'GD'
		Dc.l	$02020000,Snap_Prop_Y,Snap_Offset
		Dc	'BX',-09,028,-01,-10
		Dc	'BX',-07,030,-03,-34

		Dc	'GD'
		Dc.l	$020000f4,0,0
		Dc	'BX',-09,-09,-01,-01
		Dc	'IM',-07,-07,5,Im_Size-Im

		Dc	'RO'
		Dc.l	Check_Snapshot

		Dc	'JP'
Snap_Jump:	Dc.l	Snap_NoGfx

Snap_Gfx:	Dc	'DF',003,031,-13,-13
		Dc	'FR',000,028,-10,-10
		Dc	'RO'
		Dc.l	Draw_Snapshot
		Dc	'XX'

Snap_NoGfx:	Dc	'BX',000,028,-10,-10
		Dc	'TX',003,037,-01,5
		Dc.l	NoSnapT
		Dc	'XX'

Snap_Prop_X:	Dc.b	%00001010,0
		Dc	65535,0
		Dc	0,0
Snap_Prop_Y:	Dc.b	%00000101,0	;FreeX,Y PropX,Y
		Dc	0,65535		;KnobX,Y
		Dc	0,0		;PosX,Y
;Snap_ZFactT:	Dc.b	'2',0

NoSnapT:	Dc.b	'NO SNAPSHOTS!',0
		Even
*---------------
;DrawList_Logg:	Dc	'JS'
;		Dc.l	TitleBar_DL
;		Dc	'TX',016,010,-01,8
;		Dc.l	Log8T
;
;		Dc	'BX',000,011,069,023
;		Dc	'TX',003,020,-01,5
;		Dc.l	LogT
;
;		Dc	'RC',022,013,046,021
;		Dc	'TX',025,020,-01,5
;		Dc.l	VblT
;
;		Dc	'GD'
;		Dc.l	$02010000,0,0	;Piec_BrowseUp
;		Dc	'BX',049,013,057,021
;		Dc	'IM',051,016,003,Im_UArr-Im
;
;		Dc	'GD'
;		Dc.l	$02010000,0,0	;Piec_BrowseDown
;		Dc	'BX',058,013,066,021
;		Dc	'IM',060,016,003,Im_DArr-Im
;
;		Dc	'BX',070,011,-01,023
;		Dc	'TX',073,020,-01,5
;		Dc.l	PeakT
;		Dc	'TX',098,020,-01,5
;		Dc.l	PeakV
;
;		Dc	'FR',000,024,-01,061
;
;		Dc	'GD'
;		Dc.l	$02010000,0,0
;		Dc	'BX',000,062,008,070
;		Dc	'IM',002,064,005,Im_ToStart-Im
;
;		Dc	'GD'
;		Dc.l	$02020000,Graph_Prop,0
;		Dc	'BX',009,062,-10,070
;		Dc	'BX',016,064,-20,068
;
;		Dc	'GD'
;		Dc.l	$02010000,0,0
;		Dc	'BX',-09,062,-01,070
;		Dc	'IM',-07,064,005,Im_ToEnd-Im
;
;		Dc	'XX'
;
;Graph_Prop:	Dc.b	%00001010,0
;		Dc	65535,0
;		Dc	0,0
;
;ResetT:		Dc.b	'RESET',0
;ResetAllT:	Dc.b	'RESET ALL',0
;PeakT:		Dc.b	'PEAK=',0
;VblT:		Dc.b	'VBLS',0
;BobT:		Dc.b	'BOBS',0
;LogT:		Dc.b	'LOG:',0
;PeakV:		Dc.b	'  0',0
;		Even
*---------------
N_Note = 0	; W
N_Cmd = 2	; W
N_Cmdlo = 3	; B
N_Start = 4	; L
N_Length = 8	; W
N_LoopStart = 10 ; L
N_Replen = 14 ; W
N_Period = 16 ; W
N_FineTune = 18 ; B
N_Volume = 19 ; B
N_DMABit = 20 ; W
N_TonePortDirec = 22 ; B
N_TonePortSpeed = 23 ; B
N_WantedPeriod = 24 ; W
N_VibratoCmd = 26 ; B
N_VibratoPos = 27 ; B
N_TremoloCmd = 28 ; B
N_TremoloPos = 29 ; B
N_WaveControl = 30 ; B
N_GlissFunk = 31 ; B
N_SampleOffset = 32 ; B
N_PattPos = 33 ; B
N_LoopCount = 34 ; B
N_FunkOffset = 35 ; B
N_WaveStart = 36 ; L
N_RealLength = 40 ; W
MT_SongDataPtr = -18
MT_Speed = -14
MT_Counter = -13
MT_SongPos = -12
MT_PBreakPos = -11
MT_PosJumpFlag = -10
MT_PBreakFlag = -9
MT_LowMask = -8
MT_PattDelTime = -7
MT_PattDelTime2 = -6
MT_PatternPos = -4
MT_DMACONTemp = -2
*---------------
Song_Pause:	Move	Int_On(pc),d0	;Playing?
		Beq.b	SgP_End		;No!
		Move	SP_Pause(pc),d0	;Paused?
		Beq.b	SgP_No		;No!
		Bsr.w	Set_Song_Vol	;Volume On!
		Clr	SP_Pause	;Unpause!
		Rts
	SgP_No:	Move	#1,SP_Pause	;Pause!
		Lea	$dff000,a6	;Volume Off!
		Clr	$a8(a6)
		Clr	$b8(a6)
		Clr	$c8(a6)
		Clr	$d8(a6)
	SgP_End:Rts
SP_Pause:	Dc	0
*---------------
Song_Play:	Move	Int_On(pc),d0
		Beq.b	SP_Ok
		Bsr.w	Modl_Stop
	SP_Ok:	Bsr.w	Get_Song_LAdr
		Tst.l	(a2)
		Beq.b	MP_End
		Move.l	(a2),a2
		Move	6(a2),MasterVol
		Move	20(a2),d0
		Bra.b	Common_Play

Modl_Play:	Move	Int_On(pc),d0
		Beq.b	MP_Ok
		Bsr.b	Modl_Stop
	MP_Ok:	Move	#65535,MasterVol
		Move	Cur_Modl,d0	;###

Common_Play:	Clr	SP_Pause	;Unpause!
		Move.l	Mem_ModlList,a2	;###
		Ext.l	d0
		Lsl.l	#5,d0
		Add.l	d0,a2

		Tst.l	(a2)
		Beq.b	MP_End
		Move.l	(a2),a0
		Add	#20,a0
		Lea	Variables(pc),a5
		Lea	$dff000,a6
		Bsr.b	MT_Init
		Move.l	4.w,a6
		Moveq.l	#5,d0	;VBL Interrupt
		Lea	Interrupt(pc),a1
		Clr.l	(a1)
		Clr.l	4(a1)
		Jsr	AddIntServer(a6)
		Move	#1,Int_On
	MP_End:	Rts
*---------------
Modl_Int:	Movem.l	d0-d7/a0-a6,-(a7)
		Move	SP_Pause(pc),d0
		Bne.b	MI_End
		Lea	Variables(pc),a5
		Lea	$dff000,a6
		Bsr.w	MT_Music
	MI_End:	Movem.l	(a7)+,d0-d7/a0-a6
		Moveq.l	#0,d0	;Continue server chain
		Rts
*---------------
Modl_Stop:	Move	Int_On(pc),d0
		Beq.b	MS_End
		Clr	Int_On
		Move.l	4.w,a6
		Moveq.l	#5,d0	;VBL Interrupt
		Lea	Interrupt(pc),a1
		Jsr	RemIntServer(a6)
	MS_End:	Lea	$dff000,a6
		Bra.b	MT_End
*---------------
Int_On:		Dc	0
Interrupt:	Dc.l	0		;LN_Succ
		Dc.l	0		;LN_Pred
		Dc.b	2		;LN_Type (2=Interrupt)
		Dc.b	0		;LN_Pri  (0=Nominal)
		Dc.l	Int_Name	;LN_Name
		Dc.l	Variables	;IS_Data
		Dc.l	Modl_Int	;IS_Code
Int_Name:	Dc.b	'AF',0
		Even
*---------------
* ProTracker2.2a replay routine.
MT_Init:
	Move.l	a0,MT_SongDataPtr(a5)
	Lea	952(a0),a1
	Moveq	#127,D0
	Moveq	#0,D1
MTLoop:
	Move.l	d1,d2
	Subq	#1,d0
MTLoop2:
	Move.b	(a1)+,d1
	Cmp.b	d2,d1
	Bgt.s	MTLoop
	Dbf	d0,MTLoop2
	Addq.b	#1,d2
		
	Move.l	a5,a1
	Suba	#142,a1
	Asl.l	#8,d2
	Asl.l	#2,d2
	Addi.l	#1084,d2
	Add.l	a0,d2
	Move.l	d2,a2
	Moveq	#30,d0
MTLoop3:
	Clr.l	(a2)
	Move.l	a2,(a1)+
	Moveq	#0,d1
	Move	42(a0),d1
	Add.l	d1,d1
	Add.l	d1,a2
	Adda	#30,a0
	Dbf	d0,MTLoop3

	Ori.b	#2,$bfe001
	Move.b	#6,MT_Speed(a5)
	Clr.b	MT_Counter(a5)
	Clr.b	MT_SongPos(a5)
	Clr	MT_PatternPos(a5)
MT_End:
	Clr	$0A8(a6)
	Clr	$0B8(a6)
	Clr	$0C8(a6)
	Clr	$0D8(a6)
	Move	#$f,$096(a6)
	Rts

MT_Music:
	Movem.l	d0-d4/a0-a6,-(a7)
	Addq.b	#1,MT_Counter(a5)
	Move.b	MT_Counter(a5),d0
	Cmp.b	MT_Speed(a5),d0
	Blo.s	MT_NoNewNote
	Clr.b	MT_Counter(a5)
	Tst.b	MT_PattDelTime2(a5)
	Beq.s	MT_GetNewNote
	Bsr.s	MT_NoNewAllChannels
	Bra.w	MT_Dskip

MT_NoNewNote:
	Bsr.s	MT_NoNewAllChannels
	Bra.w	MT_NoNewPosYet
MT_NoNewAllChannels:
	Move	#$a0,d5
	Move.l	a5,a4
	Suba	#318,a4
	Bsr.w	MT_CheckEfx
	Move	#$b0,d5
	Adda	#44,a4
	Bsr.w	MT_CheckEfx
	Move	#$c0,d5
	Adda	#44,a4
	Bsr.w	MT_CheckEfx
	Move	#$d0,d5
	Adda	#44,a4
	Bra.w	MT_CheckEfx
MT_GetNewNote:
	Move.l	MT_SongDataPtr(a5),a0
	Lea	12(a0),a3
	Lea	952(a0),a2	;pattpo
	Lea	1084(a0),a0	;patterndata
	Moveq	#0,d0
	Moveq	#0,d1
	Move.b	MT_SongPos(a5),d0
	Move.b	(a2,d0.w),d1
	Asl.l	#8,d1
	Asl.l	#2,d1
	Add	MT_PatternPos(a5),d1
	Clr	MT_DMACONTemp(a5)

	Move	#$a0,d5
	Move.l	a5,a4
	Suba	#318,a4
	Bsr.s	MT_PlayVoice
	Move	#$b0,d5
	Adda	#44,a4
	Bsr.s	MT_PlayVoice
	Move	#$c0,d5
	Adda	#44,a4
	Bsr.s	MT_PlayVoice
	Move	#$d0,d5
	Adda	#44,a4
	Bsr.s	MT_PlayVoice
	Bra.w	MT_SetDMA

MT_PlayVoice:
	Tst.l	(a4)
	Bne.s	MT_PlvSkip
	Bsr.w	MT_PerNop
MT_PlvSkip:
	Move.l	(a0,d1.l),(a4)
	Addq.l	#4,d1
	Moveq	#0,d2
	Move.b	N_Cmd(a4),d2
	Andi.b	#$f0,d2
	Lsr.b	#4,d2
	Move.b	(a4),d0
	Andi.b	#$f0,d0
	Or.b	d0,d2
	Beq.w	MT_SetRegs
	Moveq	#0,d3
	Move.l	a5,a1
	Suba	#142,a1
	Move	d2,d4
	Subq.l	#1,d2
	Asl.l	#2,d2
	Mulu	#30,d4
	Move.l	(a1,d2.l),N_Start(a4)
	Move	(a3,d4.l),N_Length(a4)
	Move	(a3,d4.l),N_RealLength(a4)
	Move.b	2(a3,d4.l),N_FineTune(a4)
	Move.b	3(a3,d4.l),N_Volume(a4)
	Move	4(a3,d4.l),d3 ; Get repeat
	Beq.s	MT_NoLoop
	Move.l	N_Start(a4),d2 ; Get start
	Add	d3,d3
	Add.l	d3,d2		; Add repeat
	Move.l	d2,N_LoopStart(a4)
	Move.l	d2,N_WaveStart(a4)
	Move	4(a3,d4.l),d0	; Get repeat
	Add	6(a3,d4.l),d0	; Add replen
	Move	d0,N_Length(a4)
	Move	6(a3,d4.l),N_Replen(a4)	; Save replen
	Moveq	#0,d0
	Move.b	N_Volume(a4),d0
	Bsr.b	MT_MasterVol
	Move	d0,8(a6,d5.w)	; Set volume
	Bra.s	MT_SetRegs

MT_MasterVol:
	Addq	#1,d0
	Mulu	MasterVol(pc),d0
	Swap	d0
	Rts
MasterVol:	Dc	65535

MT_NoLoop:
	Move.l	N_Start(a4),d2
	Add.l	d3,d2
	Move.l	d2,N_LoopStart(a4)
	Move.l	d2,N_WaveStart(a4)
	Move	6(a3,d4.l),N_Replen(a4)	; Save replen
	Moveq	#0,d0
	Move.b	N_Volume(a4),d0
	Bsr.b	MT_MasterVol
	Move	d0,8(a6,d5.w)	; Set volume
MT_SetRegs:
	Move	(a4),d0
	Andi	#$0fff,d0
	Beq.w	MT_CheckMoreEfx	; If no note
	Move	2(a4),d0
	Andi	#$0ff0,d0
	Cmpi	#$0e50,d0
	Beq.s	MT_DoSetFineTune
	Move.b	2(a4),d0
	Andi.b	#$0f,d0
	Cmpi.b	#3,d0	; TonePortamento
	Beq.s	MT_ChkTonePorta
	Cmpi.b	#5,d0
	Beq.s	MT_ChkTonePorta
	Cmpi.b	#9,d0	; Sample Offset
	Bne.s	MT_SetPeriod
	Bsr.w	MT_CheckMoreEfx
	Bra.s	MT_SetPeriod

MT_DoSetFineTune:
	Bsr.w	MT_SetFineTune
	Bra.s	MT_SetPeriod

MT_ChkTonePorta:
	Bsr.w	MT_SetTonePorta
	Bra.w	MT_CheckMoreEfx

MT_SetPeriod:
	Movem.l	d0-d1/a0-a1,-(a7)
	Move	(a4),d1
	Andi	#$0fff,d1
	Lea	MT_PeriodTable(pc),a1
	Moveq	#0,d0
	Moveq	#36,d7
MT_FtuLoop:
	Cmp	(a1,d0.w),d1
	Bhs.s	MT_FtuFound
	Addq.l	#2,d0
	Dbf	d7,MT_FtuLoop
MT_FtuFound:
	Moveq	#0,d1
	Move.b	N_FineTune(a4),d1
	Mulu	#72,d1
	Add.l	d1,a1
	Move	(a1,d0.w),N_Period(a4)
	Movem.l	(a7)+,d0-d1/a0-a1

	Move	2(a4),d0
	Andi	#$0ff0,d0
	Cmpi	#$0ed0,d0 ; Notedelay
	Beq.w	MT_CheckMoreEfx

	Move	N_DMABit(a4),$096(a6)
	Btst	#2,N_WaveControl(a4)
	Bne.s	MT_Vibnoc
	Clr.b	N_VibratoPos(a4)
MT_Vibnoc:
	Btst	#6,N_WaveControl(a4)
	Bne.s	MT_Trenoc
	Clr.b	N_TremoloPos(a4)
MT_Trenoc:
	Move.l	N_Start(a4),(a6,d5.w)	; Set start
	Move	N_Length(a4),4(a6,d5.w)	; Set length
	Move	N_Period(a4),d0
	Move	d0,6(a6,d5.w)		; Set period
	Move	N_DMABit(a4),d0
	Or	d0,MT_DMACONTemp(a5)
	Bra.w	MT_CheckMoreEfx
 
MT_SetDMA:
	Bsr.w	MT_DMAWaitLoop
	Move	MT_DMACONTemp(a5),d0
	Ori	#$8000,d0
	Move	d0,$096(a6)
	Bsr.w	MT_DMAWaitLoop
	Move.l	a5,a4
	Suba	#186,a4
	Move.l	N_LoopStart(a4),$d0(a6)
	Move	N_Replen(a4),$d4(a6)
	Suba	#44,a4
	Move.l	N_LoopStart(a4),$c0(a6)
	Move	N_Replen(a4),$c4(a6)
	Suba	#44,a4
	Move.l	N_LoopStart(a4),$b0(a6)
	Move	N_Replen(a4),$b4(a6)
	Suba	#44,a4
	Move.l	N_LoopStart(a4),$a0(a6)
	Move	N_Replen(a4),$a4(a6)

MT_Dskip:
	Addi	#16,MT_PatternPos(a5)
	Move.b	MT_PattDelTime(a5),d0
	Beq.s	MT_Dskc
	Move.b	d0,MT_PattDelTime2(a5)
	Clr.b	MT_PattDelTime(a5)
MT_Dskc:
	Tst.b	MT_PattDelTime2(a5)
	Beq.s	MT_Dska
	Subq.b	#1,MT_PattDelTime2(a5)
	Beq.s	MT_Dska
	Sub	#16,MT_PatternPos(a5)
MT_Dska:
	Tst.b	MT_PBreakFlag(a5)
	Beq.s	MT_Nnpysk
	Clr.b	MT_PBreakFlag(a5)
	Moveq	#0,d0
	Move.b	MT_PBreakPos(a5),d0
	Clr.b	MT_PBreakPos(a5)
	Lsl	#4,d0
	Move	d0,MT_PatternPos(a5)
MT_Nnpysk:
	Cmpi	#1024,MT_PatternPos(a5)
	Blo.s	MT_NoNewPosYet
MT_NextPosition:
	Moveq	#0,d0
	Move.b	MT_PBreakPos(a5),d0
	Lsl	#4,d0
	Move	d0,MT_PatternPos(a5)
	Clr.b	MT_PBreakPos(a5)
	Clr.b	MT_PosJumpFlag(a5)
	Addq.b	#1,MT_SongPos(a5)
	Andi.b	#$7F,MT_SongPos(a5)
	Move.b	MT_SongPos(a5),d1
	Move.l	MT_SongDataPtr(a5),a0
	Cmp.b	950(a0),d1
	Blo.s	MT_NoNewPosYet
	Clr.b	MT_SongPos(a5)
MT_NoNewPosYet:	
	Tst.b	MT_PosJumpFlag(a5)
	Bne.s	MT_NextPosition
	Movem.l	(a7)+,d0-d4/a0-a6
	Rts

MT_CheckEfx:
	Bsr.w	MT_UpdateFunk
	Move	N_Cmd(a4),d0
	Andi	#$0fff,d0
	Beq.s	MT_PerNop
	Move.b	N_Cmd(a4),d0
	Andi.b	#$0f,d0
	Beq.s	MT_Arpeggio
	Cmpi.b	#1,d0
	Beq.w	MT_PortaUp
	Cmpi.b	#2,d0
	Beq.w	MT_PortaDown
	Cmpi.b	#3,d0
	Beq.w	MT_TonePortamento
	Cmpi.b	#4,d0
	Beq.w	MT_Vibrato
	Cmpi.b	#5,d0
	Beq.w	MT_TonePlusVolSlide
	Cmpi.b	#6,d0
	Beq.w	MT_VibratoPlusVolSlide
	Cmpi.b	#$E,d0
	Beq.w	MT_E_Commands
SetBack:
	Move	N_Period(a4),6(a6,d5.w)
	Cmpi.b	#7,d0
	Beq.w	MT_Tremolo
	Cmpi.b	#$a,d0
	Beq.w	MT_VolumeSlide
MT_Return2:
	Rts

MT_PerNop:
	Move	N_Period(a4),6(a6,d5.w)
	Rts

MT_Arpeggio:
	Moveq	#0,d0
	Move.b	MT_Counter(a5),d0
	Divs	#3,d0
	Swap	d0
	Tst	D0
	Beq.s	MT_Arpeggio2
	Cmpi	#2,d0
	Beq.s	MT_Arpeggio1
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Lsr.b	#4,d0
	Bra.s	MT_Arpeggio3

MT_Arpeggio1:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#15,d0
	Bra.s	MT_Arpeggio3

MT_Arpeggio2:
	Move	N_Period(a4),d2
	Bra.s	MT_Arpeggio4

MT_Arpeggio3:
	Add	d0,d0
	Moveq	#0,d1
	Move.b	N_FineTune(a4),d1
	Mulu	#72,d1
	Lea	MT_PeriodTable(pc),a0
	Add	d1,a0
	Moveq	#0,d1
	Move	N_Period(a4),d1
	Moveq	#36,d7
MT_ArpLoop:
	Move	(a0,d0.w),d2
	Cmp	(a0),d1
	Bhs.s	MT_Arpeggio4
	Addq	#2,a0
	Dbf	d7,MT_ArpLoop
	Rts

MT_Arpeggio4:
	Move	d2,6(a6,d5.w)
	Rts

MT_FinePortaUp:
	Tst.b	MT_Counter(a5)
	Bne.s	MT_Return2
	Move.b	#$0f,MT_LowMask(a5)
MT_PortaUp:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	And.b	MT_LowMask(a5),d0
	St	MT_LowMask(a5)
	Sub	d0,N_Period(a4)
	Move	N_Period(a4),d0
	Andi	#$0fff,d0
	Cmpi	#113,d0
	Bpl.s	MT_PortaUskip
	Andi	#$f000,N_Period(a4)
	Ori	#113,N_Period(a4)
MT_PortaUskip:
	Move	N_Period(a4),d0
	Andi	#$0fff,d0
	Move	d0,6(a6,d5.w)
	Rts
 
MT_FinePortaDown:
	Tst.b	MT_Counter(a5)
	Bne.w	MT_Return2
	Move.b	#$0f,MT_LowMask(a5)
MT_PortaDown:
	Clr	d0
	Move.b	N_Cmdlo(a4),d0
	And.b	MT_LowMask(a5),d0
	St	MT_LowMask(a5)
	Add	d0,N_Period(a4)
	Move	N_Period(a4),d0
	Andi	#$0fff,d0
	Cmpi	#856,d0
	Bmi.s	MT_PortaDskip
	Andi	#$f000,N_Period(a4)
	Ori	#856,N_Period(a4)
MT_PortaDskip:
	Move	N_Period(a4),d0
	Andi	#$0fff,d0
	Move	d0,6(a6,d5.w)
	Rts

MT_SetTonePorta:
	Move.l	a0,-(a7)
	Move	(a4),d2
	Andi	#$0fff,d2
	Moveq	#0,d0
	Move.b	N_FineTune(a4),d0
	Mulu	#74,d0
	Lea	MT_PeriodTable(pc),a0
	Add	d0,a0
	Moveq	#0,d0
MT_StpLoop:
	Cmp	(a0,d0.w),d2
	Bhs.s	MT_StpFound
	Addq	#2,d0
	Cmpi	#74,d0
	Blo.s	MT_StpLoop
	Moveq	#70,d0
MT_StpFound:
	Move.b	N_FineTune(a4),d2
	Andi.b	#8,d2
	Beq.s	MT_StpGoss
	Tst	d0
	Beq.s	MT_StpGoss
	Subq	#2,d0
MT_StpGoss:
	Move	(a0,d0.w),d2
	Move.l	(a7)+,a0
	Move	d2,N_WantedPeriod(a4)
	Move	N_Period(a4),d0
	Clr.b	N_TonePortDirec(a4)
	Cmp	d0,d2
	Beq.s	MT_ClearTonePorta
	Bge.w	MT_Return2
	Move.b	#1,N_TonePortDirec(a4)
	Rts

MT_ClearTonePorta:
	Clr	N_WantedPeriod(a4)
	Rts

MT_TonePortamento:
	Move.b	N_Cmdlo(a4),d0
	Beq.s	MT_TonePortNoChange
	Move.b	d0,N_TonePortSpeed(a4)
	Clr.b	N_Cmdlo(a4)
MT_TonePortNoChange:
	Tst	N_WantedPeriod(a4)
	Beq.w	MT_Return2
	Moveq	#0,d0
	Move.b	N_TonePortSpeed(a4),d0
	Tst.b	N_TonePortDirec(a4)
	Bne.s	MT_TonePortaUp
MT_TonePortaDown:
	Add	d0,N_Period(a4)
	Move	N_WantedPeriod(a4),d0
	Cmp	N_Period(a4),d0
	Bgt.s	MT_TonePortaSetPer
	Move	N_WantedPeriod(a4),N_Period(a4)
	Clr	N_WantedPeriod(a4)
	Bra.s	MT_TonePortaSetPer

MT_TonePortaUp:
	Sub	d0,N_Period(a4)
	Move	N_WantedPeriod(a4),d0
	Cmp	N_Period(a4),d0
	Blt.s	MT_TonePortaSetPer
	Move	N_WantedPeriod(a4),N_Period(a4)
	Clr	N_WantedPeriod(a4)

MT_TonePortaSetPer:
	Move	N_Period(a4),d2
	Move.b	N_GlissFunk(a4),d0
	Andi.b	#$0f,d0
	Beq.s	MT_GlissSkip
	Moveq	#0,d0
	Move.b	N_FineTune(a4),d0
	Mulu	#72,d0
	Lea	MT_PeriodTable(pc),a0
	Add	d0,a0
	Moveq	#0,d0
MT_GlissLoop:
	Cmp	(a0,d0.w),d2
	Bhs.s	MT_GlissFound
	Addq	#2,d0
	Cmpi	#72,d0
	Blo.s	MT_GlissLoop
	Moveq	#70,d0
MT_GlissFound:
	Move	(a0,d0.w),d2
MT_GlissSkip:
	Move	d2,6(a6,d5.w) ; Set period
	Rts

MT_Vibrato:
	Move.b	N_Cmdlo(a4),d0
	Beq.s	MT_Vibrato2
	Move.b	N_VibratoCmd(a4),d2
	Andi.b	#$0f,d0
	Beq.s	MT_VibSkip
	Andi.b	#$f0,d2
	Or.b	d0,d2
MT_VibSkip:
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$f0,d0
	Beq.s	MT_VibSkip2
	Andi.b	#$0f,d2
	Or.b	d0,d2
MT_VibSkip2:
	Move.b	d2,N_VibratoCmd(a4)
MT_Vibrato2:
	Move.b	N_VibratoPos(a4),d0
	Lea	MT_VibratoTable(pc),a0
	Lsr	#2,d0
	Andi	#$001f,d0
	Moveq	#0,d2
	Move.b	N_WaveControl(a4),d2
	Andi.b	#$03,d2
	Beq.s	MT_Vib_Sine
	Lsl.b	#3,d0
	Cmpi.b	#1,d2
	Beq.s	MT_Vib_RampDown
	St	d2
	Bra.s	MT_Vib_Set
MT_Vib_RampDown:
	Tst.b	N_VibratoPos(a4)
	Bpl.s	MT_Vib_RampDown2
	St	d2
	Sub.b	d0,d2
	Bra.s	MT_Vib_Set
MT_Vib_RampDown2:
	Move.b	d0,d2
	Bra.s	MT_Vib_Set
MT_Vib_Sine:
	Move.b	(a0,d0.w),d2
MT_Vib_Set:
	Move.b	N_VibratoCmd(a4),d0
	Andi	#15,d0
	Mulu	d0,d2
	Lsr	#7,d2
	Move	N_Period(a4),d0
	Tst.b	N_VibratoPos(a4)
	Bmi.s	MT_VibratoNeg
	Add	d2,d0
	Bra.s	MT_Vibrato3
MT_VibratoNeg:
	Sub	d2,d0
MT_Vibrato3:
	Move	d0,6(a6,d5.w)
	Move.b	N_VibratoCmd(a4),d0
	Lsr	#2,d0
	Andi	#$3C,d0
	Add.b	d0,N_VibratoPos(a4)
	Rts

MT_TonePlusVolSlide:
	Bsr.w	MT_TonePortNoChange
	Bra.w	MT_VolumeSlide

MT_VibratoPlusVolSlide:
	Bsr.s	MT_Vibrato2
	Bra.w	MT_VolumeSlide

MT_Tremolo:
	Move.b	N_Cmdlo(a4),d0
	Beq.s	MT_Tremolo2
	Move.b	N_TremoloCmd(a4),d2
	Andi.b	#$0f,d0
	Beq.s	MT_TreSkip
	Andi.b	#$f0,d2
	Or.b	d0,d2
MT_TreSkip:
	Move.b	N_Cmdlo(a4),d0
	And.b	#$f0,d0
	Beq.s	MT_TreSkip2
	Andi.b	#$0f,d2
	Or.b	d0,d2
MT_TreSkip2:
	Move.b	d2,N_TremoloCmd(a4)
MT_Tremolo2:
	Move.b	N_TremoloPos(a4),d0
	Lea	MT_VibratoTable(pc),a0
	Lsr	#2,d0
	Andi	#$1f,d0
	Moveq	#0,d2
	Move.b	N_WaveControl(a4),d2
	Lsr.b	#4,d2
	Andi.b	#3,d2
	Beq.s	MT_Tre_Sine
	Lsl.b	#3,d0
	Cmpi.b	#1,d2
	Beq.s	MT_Tre_RampDown
	St	d2
	Bra.s	MT_Tre_Set
MT_Tre_RampDown:
	Tst.b	N_VibratoPos(a4)
	Bpl.s	MT_Tre_RampDown2
	St	d2
	Sub.b	d0,d2
	Bra.s	MT_Tre_Set
MT_Tre_RampDown2:
	Move.b	d0,d2
	Bra.s	MT_Tre_Set
MT_Tre_Sine:
	Move.b	(a0,d0.w),d2
MT_Tre_Set:
	Move.b	N_TremoloCmd(a4),d0
	Andi	#15,d0
	Mulu	d0,d2
	Lsr	#6,d2
	Moveq	#0,d0
	Move.b	N_Volume(a4),d0
	Tst.b	N_TremoloPos(a4)
	Bmi.s	MT_TremoloNeg
	Add	d2,d0
	Bra.s	MT_Tremolo3
MT_TremoloNeg:
	Sub	d2,d0
MT_Tremolo3:
	Bpl.s	MT_TremoloSkip
	Clr	d0
MT_TremoloSkip:
	Cmpi	#$40,d0
	Bls.s	MT_TremoloOk
	Move	#$40,d0
MT_TremoloOk:
	Bsr.w	MT_MasterVol
	Move	d0,8(a6,d5.w)
	Move.b	N_TremoloCmd(a4),d0
	Lsr	#2,d0
	Andi	#$3c,d0
	Add.b	d0,N_TremoloPos(a4)
	Rts

MT_SampleOffset:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Beq.s	MT_SoNoNew
	Move.b	d0,N_SampleOffset(a4)
MT_SoNoNew:
	Move.b	N_SampleOffset(a4),d0
	Lsl	#7,d0
	Cmp	N_Length(a4),d0
	Bge.s	MT_SofSkip
	Sub	d0,N_Length(a4)
	Add	d0,d0
	Add.l	d0,N_Start(a4)
	Rts
MT_SofSkip:
	Move	#1,N_Length(a4)
	Rts

MT_VolumeSlide:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Lsr.b	#4,d0
	Tst.b	d0
	Beq.s	MT_VolSlideDown
MT_VolSlideUp:
	Add.b	d0,N_Volume(a4)
	Cmpi.b	#$40,N_Volume(a4)
	Bmi.s	MT_VsuSkip
	Move.b	#$40,N_Volume(a4)
MT_VsuSkip:
	Move.b	N_Volume(a4),d0
	Bsr.w	MT_MasterVol
	Move	d0,8(a6,d5.w)
	Rts

MT_VolSlideDown:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
MT_VolSlideDown2:
	Sub.b	d0,N_Volume(a4)
	Bpl.s	MT_VsdSkip
	Clr.b	N_Volume(a4)
MT_VsdSkip:
	Move.b	N_Volume(a4),d0
	Bsr.w	MT_MasterVol
	Move	d0,8(a6,d5.w)
	Rts

MT_PositionJump:
	Move.b	N_Cmdlo(a4),MT_SongPos(a5)
	Subq.b	#1,MT_SongPos(a5)
MT_PJ2:
	Clr.b	MT_PBreakPos(a5)
	St 	MT_PosJumpFlag(a5)
	Rts

MT_VolumeChange:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Cmpi.b	#$40,d0
	Bls.s	MT_VolumeOk
	Moveq	#$40,d0
MT_VolumeOk:
	Move.b	d0,N_Volume(a4)
	Bsr.w	MT_MasterVol
	Move	d0,8(a6,d5.w)
	Rts

MT_PatternBreak:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Move.l	d0,d2
	Lsr.b	#4,d0
	Mulu	#10,d0
	Andi.b	#$0f,d2
	Add.b	d2,d0
	Cmpi.b	#63,d0
	Bhi.s	MT_PJ2
	Move.b	d0,MT_PBreakPos(a5)
	St	MT_PosJumpFlag(a5)
	Rts

MT_SetSpeed:
	Move.b	3(a4),d0
	Beq.w	MT_Return2
	Clr.b	MT_Counter(a5)
	Move.b	d0,MT_Speed(a5)
	Rts

MT_CheckMoreEfx:
	Bsr.w	MT_UpdateFunk
	Move.b	2(a4),d0
	Andi.b	#$0f,d0
	Cmpi.b	#$9,d0
	Beq.w	MT_SampleOffset
	Cmpi.b	#$b,d0
	Beq.b	MT_PositionJump
	Cmpi.b	#$d,d0
	Beq.s	MT_PatternBreak
	Cmpi.b	#$e,d0
	Beq.s	MT_E_Commands
	Cmpi.b	#$f,d0
	Beq.s	MT_SetSpeed
	Cmpi.b	#$c,d0
	Beq.w	MT_VolumeChange
	Bra.w	MT_PerNop

MT_E_Commands:
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$f0,d0
	Lsr.b	#4,d0
	Beq.s	MT_FilterOnOff
	Cmpi.b	#1,d0
	Beq.w	MT_FinePortaUp
	Cmpi.b	#2,d0
	Beq.w	MT_FinePortaDown
	Cmpi.b	#3,d0
	Beq.s	MT_SetGlissControl
	Cmpi.b	#4,d0
	Beq.w	MT_SetVibratoControl
	Cmpi.b	#5,d0
	Beq.w	MT_SetFineTune
	Cmpi.b	#6,d0
	Beq.w	MT_JumpLoop
	Cmpi.b	#7,d0
	Beq.w	MT_SetTremoloControl
	Cmpi.b	#9,d0
	Beq.w	MT_RetrigNote
	Cmpi.b	#$a,d0
	Beq.w	MT_VolumeFineUp
	Cmpi.b	#$b,d0
	Beq.w	MT_VolumeFineDown
	Cmpi.b	#$c,d0
	Beq.w	MT_NoteCut
	Cmpi.b	#$d,d0
	Beq.w	MT_NoteDelay
	Cmpi.b	#$e,d0
	Beq.w	MT_PatternDelay
	Cmpi.b	#$f,d0
	Beq.w	MT_FunkIt
	Rts

MT_FilterOnOff:
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#1,d0
	Add.b	d0,d0
	Andi.b	#$fd,$bfe001
	Or.b	d0,$bfe001
	Rts

MT_SetGlissControl:
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Andi.b	#$f0,N_GlissFunk(a4)
	Or.b	d0,N_GlissFunk(a4)
	Rts

MT_SetVibratoControl:
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Andi.b	#$f0,N_WaveControl(a4)
	Or.b	d0,N_WaveControl(a4)
	Rts

MT_SetFineTune:
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Move.b	d0,N_FineTune(a4)
	Rts

MT_JumpLoop:
	Tst.b	MT_Counter(a5)
	Bne.w	MT_Return2
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Beq.s	MT_SetLoop
	Tst.b	N_LoopCount(a4)
	Beq.s	MT_JumpCnt
	Subq.b	#1,N_LoopCount(a4)
	Beq.w	MT_Return2
MT_JmpLoop:
	Move.b	N_PattPos(a4),MT_PBreakPos(a5)
	St	MT_PBreakFlag(a5)
	Rts

MT_JumpCnt:
	Move.b	d0,N_LoopCount(a4)
	Bra.s	MT_JmpLoop

MT_SetLoop:
	Move	MT_PatternPos(a5),d0
	Lsr	#4,d0
	Move.b	d0,N_PattPos(a4)
	Rts

MT_SetTremoloControl:
	Move.b	N_Cmdlo(a4),d0
*	Andi.b	#$0f,d0
	Lsl.b	#4,d0
	Andi.b	#$0f,N_WaveControl(a4)
	Or.b	d0,N_WaveControl(a4)
	Rts

MT_RetrigNote:
	Move.l	d1,-(a7)
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Beq.s	MT_RtnEnd
	Moveq	#0,d1
	Move.b	MT_Counter(a5),d1
	Bne.s	MT_RtnSkp
	Move	(a4),d1
	Andi	#$0fff,d1
	Bne.s	MT_RtnEnd
	Moveq	#0,d1
	Move.b	MT_Counter(a5),d1
MT_RtnSkp:
	Divu	d0,d1
	Swap	d1
	Tst	d1
	Bne.s	MT_RtnEnd
MT_DoRetrig:
	Move	N_DMABit(a4),$096(a6)	; Channel DMA off
	Move.l	N_Start(a4),(a6,d5.w)	; Set sampledata pointer
	Move	N_Length(a4),4(a6,d5.w)	; Set length
	Bsr.w	MT_DMAWaitLoop
	Move	N_DMABit(a4),d0
	Ori	#$8000,d0
	Move	d0,$096(a6)
	Bsr.w	MT_DMAWaitLoop
	Move.l	N_LoopStart(a4),(a6,d5.w)
	Move.l	N_Replen(a4),4(a6,d5.w)
MT_RtnEnd:
	Move.l	(a7)+,d1
	Rts

MT_VolumeFineUp:
	Tst.b	MT_Counter(a5)
	Bne.w	MT_Return2
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$d,d0
	Bra.w	MT_VolSlideUp

MT_VolumeFineDown:
	Tst.b	MT_Counter(a5)
	Bne.w	MT_Return2
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Bra.w	MT_VolSlideDown2

MT_NoteCut:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Cmp.b	MT_Counter(a5),d0
	Bne.w	MT_Return2
	Clr.b	N_Volume(a4)
	Clr	8(a6,d5.w)
	Rts

MT_NoteDelay:
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Cmp.b	MT_Counter(a5),d0
	Bne.w	MT_Return2
	Move	(a4),d0
	Beq.w	MT_Return2
	Move.l	d1,-(a7)
	Bra.w	MT_DoRetrig

MT_PatternDelay:
	Tst.b	MT_Counter(a5)
	Bne.w	MT_Return2
	Moveq	#0,d0
	Move.b	N_Cmdlo(a4),d0
	Andi.b	#$0f,d0
	Tst.b	MT_PattDelTime2(a5)
	Bne.w	MT_Return2
	Addq.b	#1,d0
	Move.b	d0,MT_PattDelTime(a5)
	Rts

MT_FunkIt:
	Tst.b	MT_Counter(a5)
	Bne.w	MT_Return2
	Move.b	N_Cmdlo(a4),d0
*	Andi.b	#$0f,d0
	Lsl.b	#4,d0
	Andi.b	#$0f,N_GlissFunk(a4)
	Or.b	d0,N_GlissFunk(a4)
	Tst.b	d0
	Beq.w	MT_Return2
MT_UpdateFunk:
	Movem.l	a0/d1,-(a7)
	Moveq	#0,d0
	Move.b	N_GlissFunk(a4),d0
	Lsr.b	#4,d0
	Beq.s	MT_FunkEnd
	Lea	MT_FunkTable(pc),a0
	Move.b	(a0,d0.w),d0
	Add.b	d0,N_FunkOffset(a4)
	Btst	#7,N_FunkOffset(a4)
	Beq.s	MT_FunkEnd
	Clr.b	N_FunkOffset(a4)

	Move.l	N_LoopStart(a4),d0
	Moveq	#0,d1
	Move	N_Replen(a4),d1
	Add.l	d1,d0
	Add.l	d1,d0
	Move.l	N_WaveStart(a4),a0
	Addq	#1,a0
	Cmp.l	d0,a0
	Blo.s	MT_FunkOk
	Move.l	N_LoopStart(a4),a0
MT_FunkOk:
	Move.l	a0,N_WaveStart(a4)
	Moveq	#-1,d0
	Sub.b	(a0),d0
	Move.b	d0,(a0)
MT_FunkEnd:
	Movem.l	(a7)+,a0/d1
	Rts

MT_DMAWaitLoop:
	Move	d1,-(sp)
	Moveq	#5,d0		;Wait 5+1 lines
.Loop:	Move.b	6(a6),d1	;Read current raster position
.Wait:	Cmp.b	6(a6),d1
	Beq.s	.Wait		;Wait until it changes
	Dbf	d0,.Loop	;Do it again
	Move	(sp)+,d1
	Rts

MT_FunkTable:	Dc.b 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

MT_VibratoTable:
	Dc.b 0, 24, 49, 74, 97,120,141,161
	Dc.b 180,197,212,224,235,244,250,253
	Dc.b 255,253,250,244,235,224,212,197
	Dc.b 180,161,141,120, 97, 74, 49, 24

MT_PeriodTable:
; Tuning 0, Normal
	Dc	856,808,762,720,678,640,604,570,538,508,480,453
	Dc	428,404,381,360,339,320,302,285,269,254,240,226
	Dc	214,202,190,180,170,160,151,143,135,127,120,113
; Tuning 1
	Dc	850,802,757,715,674,637,601,567,535,505,477,450
	Dc	425,401,379,357,337,318,300,284,268,253,239,225
	Dc	213,201,189,179,169,159,150,142,134,126,119,113
; Tuning 2
	Dc	844,796,752,709,670,632,597,563,532,502,474,447
	Dc	422,398,376,355,335,316,298,282,266,251,237,224
	Dc	211,199,188,177,167,158,149,141,133,125,118,112
; Tuning 3
	Dc	838,791,746,704,665,628,592,559,528,498,470,444
	Dc	419,395,373,352,332,314,296,280,264,249,235,222
	Dc	209,198,187,176,166,157,148,140,132,125,118,111
; Tuning 4
	Dc	832,785,741,699,660,623,588,555,524,495,467,441
	Dc	416,392,370,350,330,312,294,278,262,247,233,220
	Dc	208,196,185,175,165,156,147,139,131,124,117,110
; Tuning 5
	Dc	826,779,736,694,655,619,584,551,520,491,463,437
	Dc	413,390,368,347,328,309,292,276,260,245,232,219
	Dc	206,195,184,174,164,155,146,138,130,123,116,109
; Tuning 6
	Dc	820,774,730,689,651,614,580,547,516,487,460,434
	Dc	410,387,365,345,325,307,290,274,258,244,230,217
	Dc	205,193,183,172,163,154,145,137,129,122,115,109
; Tuning 7
	Dc	814,768,725,684,646,610,575,543,513,484,457,431
	Dc	407,384,363,342,323,305,288,272,256,242,228,216
	Dc	204,192,181,171,161,152,144,136,128,121,114,108
; Tuning -8
	Dc	907,856,808,762,720,678,640,604,570,538,508,480
	Dc	453,428,404,381,360,339,320,302,285,269,254,240
	Dc	226,214,202,190,180,170,160,151,143,135,127,120
; Tuning -7
	Dc	900,850,802,757,715,675,636,601,567,535,505,477
	Dc	450,425,401,379,357,337,318,300,284,268,253,238
	Dc	225,212,200,189,179,169,159,150,142,134,126,119
; Tuning -6
	Dc	894,844,796,752,709,670,632,597,563,532,502,474
	Dc	447,422,398,376,355,335,316,298,282,266,251,237
	Dc	223,211,199,188,177,167,158,149,141,133,125,118
; Tuning -5
	Dc	887,838,791,746,704,665,628,592,559,528,498,470
	Dc	444,419,395,373,352,332,314,296,280,264,249,235
	Dc	222,209,198,187,176,166,157,148,140,132,125,118
; Tuning -4
	Dc	881,832,785,741,699,660,623,588,555,524,494,467
	Dc	441,416,392,370,350,330,312,294,278,262,247,233
	Dc	220,208,196,185,175,165,156,147,139,131,123,117
; Tuning -3
	Dc	875,826,779,736,694,655,619,584,551,520,491,463
	Dc	437,413,390,368,347,328,309,292,276,260,245,232
	Dc	219,206,195,184,174,164,155,146,138,130,123,116
; Tuning -2
	Dc	868,820,774,730,689,651,614,580,547,516,487,460
	Dc	434,410,387,365,345,325,307,290,274,258,244,230
	Dc	217,205,193,183,172,163,154,145,137,129,122,115
; Tuning -1
	Dc	862,814,768,725,684,646,610,575,543,513,484,457
	Dc	431,407,384,363,342,323,305,288,272,256,242,228
	Dc	216,203,192,181,171,161,152,144,136,128,121,114

MT_Chan1Temp:
	Dc.l	0,0,0,0,0,$00010000,0,0,0,0,0
MT_Chan2Temp:
	Dc.l	0,0,0,0,0,$00020000,0,0,0,0,0
MT_Chan3Temp:
	Dc.l	0,0,0,0,0,$00040000,0,0,0,0,0
MT_Chan4Temp:
	Dc.l	0,0,0,0,0,$00080000,0,0,0,0,0
MT_SampleStarts:
	Dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	Dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
*MT_SongDataPtr:	Dc.l 0
*MT_Speed:		Dc.b 6
*MT_Counter:		Dc.b 0
*MT_SongPos:		Dc.b 0
*MT_PBreakPos:		Dc.b 0
*MT_PosJumpFlag:	Dc.b 0
*MT_PBreakFlag:		Dc.b 0
*MT_LowMask:		Dc.b 0
*MT_PattDelTime:	Dc.b 0
*MT_PattDelTime2:	Dc.b 0,0
*MT_PatternPos:		Dc 0
*MT_DMACONtemp:		Dc 0
Variables:
*=======================================================================*
*			       F O N T S				*
*=======================================================================*
Prepare_Fonts:	Move.l	GfxBase,a6	;###
		Lea	Font5Start(pc),a1
		Move.l	a1,Font5
		Jsr	AddFont(a6)
		Lea	Font8Start(pc),a1
		Move.l	a1,Font8
		Jmp	AddFont(a6)
*---------------
Free_Fonts:	Move.l	GfxBase,a6	;###
		Move.l	Font5(pc),d0
		Beq.b	FF_N5
		Lea	Font5Start(pc),a1
		Jsr	RemFont(a6)
	FF_N5:	Move.l	Font8(pc),d0
		Beq.b	FF_N8
		Lea	Font8Start(pc),a1
		Jsr	RemFont(a6)
	FF_N8:	Rts
Font5:		Dc.l	0
Font8:		Dc.l	0
*---------------
Font5Start:	Dc.l	0,0			;Succ,Pred
		Dc.b	$c			;Type
		Dc.b	0			;Pri
		Dc.l	Font5Name		;Name
		Dc.l	0			;Replyport
		Dc	Font5End-Font5Start	;LengtH
		Dc	5			;YSize
		Dc.b	0			;Style
		Dc.b	$42			;Flags
		Dc	5			;XSize
		Dc	5			;BaseLine
		Dc	1			;BoldSmear
		Dc	0			;Accessors
		Dc.b	$20			;LoChar
		Dc.b	$5c			;HiChar
		Dc.l	Font5Data		;CharData
		Dc	$26			;Modulo
		Dc.l	Font5Loc		;CharLoc
		Dc.l	0			;CharSpace
		Dc.l	0			;CharKern
Font5Data:	DC	$0228,$A653,$8422,$2800,$0004,$F33D,$E97B,$DEF7,$8002
		DC	$021E,$67B9,$EC7B,$DE97,$0528,$4A5E,$F7B9,$294A,$5264
		DC	$1800,$0229,$FF12,$8841,$1080,$0004,$9104,$2942,$0294
		DC	$A084,$7112,$94A9,$2A42,$1092,$0548,$7B52,$9491,$294A
		DC	$5244,$0800,$0200,$A621,$4041,$39C0,$7008,$913C,$EF7B
		DC	$C2F7,$8008,$0086,$B7BD,$0973,$96F2,$0588,$4ADE,$9791
		DC	$2949,$9E42,$0800,$0001,$FF42,$8041,$1082,$0010,$9120
		DC	$210A,$4290,$A084,$7100,$B4A5,$2942,$1292,$2548,$4A50
		DC	$A511,$2A7A,$4241,$0800,$0200,$A653,$C022,$2804,$0110
		DC	$F3BD,$E17B,$C2F7,$8102,$0204,$44BD,$EF7A,$1E97,$3D2F
		DC	$4A50,$D491,$EC4A,$5E61,$1800
Font5Loc:	DC	$0000,$0005,$0005,$0005,$000A,$0005,$000F,$0005,$0014
		DC	$0005,$0019,$0005,$001E,$0005,$0023,$0005,$0028,$0005
		DC	$002D,$0005,$0032,$0005,$0037,$0005,$003C,$0005,$0041
		DC	$0005,$0046,$0005,$004B,$0005,$0050,$0005,$0055,$0005
		DC	$005A,$0005,$005F,$0005,$0064,$0005,$0069,$0005,$006E
		DC	$0005,$0073,$0005,$0078,$0005,$007D,$0005,$0082,$0005
		DC	$0087,$0005,$008C,$0005,$0091,$0005,$0096,$0005,$009B
		DC	$0005,$00A0,$0005,$00A5,$0005,$00AA,$0005,$00AF,$0005
		DC	$00B4,$0005,$00B9,$0005,$00BE,$0005,$00C3,$0005,$00C8
		DC	$0005,$00CD,$0005,$00D2,$0005,$00D7,$0005,$00DC,$0005
		DC	$00E1,$0005,$00E6,$0005,$0050,$0005,$00EB,$0005,$00F0
		DC	$0005,$00F5,$0005,$0069,$0005,$00FA,$0005,$00FF,$0005
		DC	$0104,$0005,$0109,$0005,$010E,$0005,$0113,$0005,$005A
		DC	$0005,$0118,$0005,$011D,$0005,$0122,$0005
Font5Name:	Dc.b	'AF',0,0
Font5End:
*---------------
Font8Start:	Dc.l	0,0			;Succ,Pred
		Dc.b	$0c			;Type
		Dc.b	0			;Pri
		Dc.l	Font8Name		;Name
		Dc.l	0			;Replyport
		Dc	Font8End-Font8Start	;Length
		Dc	7			;YSize
		Dc.b	0			;Style
		Dc.b	$42			;Flags
		Dc	8			;XSize
		Dc	8			;BaseLine
		Dc	1			;BoldSmear
		Dc	0			;Accessors
		Dc.b	$20			;LoChar
		Dc.b	$86			;HiChar
		Dc.l	Font8Data		;CharData
		Dc	$60			;Modulo
		Dc.l	Font8Loc		;CharLoc
		Dc.l	0			;CharSpace
		Dc.l	0			;CharKern
Font8Data:	DC	$0060,$6C6C,$30CC,$7030,$1860,$0000,$0000,$000C,$FC70
		DC	$FCFC,$CCFC,$FCFC,$FCFC,$0000,$0000,$00FC,$78FC,$F8FC
		DC	$F0FC,$FCFC,$CCFC,$0CCC,$C0C6,$CCFC,$FCFC,$FCCC,$CCC6
		DC	$CCCC,$FCF0,$C0F0,$1000,$6000,$0000,$0000,$0000,$0000
		DC	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0018
		DC	$3060,$0000,$0004,$0060,$6C6C,$7CCC,$D830,$3030,$6C30
		DC	$0000,$000C,$CC30,$CCCC,$CCCC,$CCCC,$CCCC,$6060,$1800
		DC	$60CC,$CCCC,$D8CC,$D8C0,$C0C0,$CC30,$0CCC,$C0EE,$CCCC
		DC	$CCCC,$30CC,$CCC6,$CCCC,$0CC0,$C030,$3800,$6000,$0000
		DC	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
		DC	$0000,$0000,$0030,$3030,$00EE,$2004,$0060,$D8FE,$B018
		DC	$D860,$6018,$3830,$0000,$0018,$CC30,$0C0C,$CCC0,$C00C
		DC	$CCCC,$6060,$3078,$300C,$CCCC,$D8C0,$CCC0,$C0C0,$CC30
		DC	$0CD8,$C0FE,$ECCC,$CCCC,$30CC,$CCC6,$78CC,$18C0,$6030
		DC	$6C00,$30FC,$F8FC,$F0FC,$FCFC,$CCFC,$0CCC,$C0C6,$CCFC
		DC	$FCFC,$FCFC,$FCCC,$CCC6,$CCCC,$FC30,$3030,$388A,$6024
		DC	$0060,$006C,$7830,$7000,$6018,$FEFC,$0078,$0030,$CC30
		DC	$FC7C,$FCFC,$FC0C,$FCFC,$0000,$6000,$183C,$D4FC,$FCC0
		DC	$CCF0,$F0DC,$FC30,$0CF0,$C0D6,$FCFC,$CCFC,$30CC,$CCD6
		DC	$30FC,$30C0,$3030,$4400,$00CC,$D8CC,$D8C0,$C0C0,$CC30
		DC	$0CD8,$C0EE,$ECCC,$CCCC,$CCC0,$30CC,$CCD6,$78CC,$1860
		DC	$3018,$38EE,$FE64,$0060,$00FE,$3460,$DE00,$6018,$3830
		DC	$3000,$0060,$CC30,$C00C,$0C0C,$CC0C,$CC0C,$6060,$3078
		DC	$3030,$D4CC,$CCC0,$CCC0,$C0CC,$CC30,$0CD8,$C0C6,$DCC0
		DC	$CCD8,$30CC,$D8FE,$7830,$60C0,$1830,$0000,$00FC,$FCC0
		DC	$CCF0,$F0DC,$FC30,$0CF0,$C0FE,$FCCC,$FCCC,$FCFC,$30CC
		DC	$D8FE,$30FC,$3030,$3030,$3828,$60FC,$0000,$006C,$F8CC
		DC	$CC00,$3030,$6C30,$3000,$60C0,$CC30,$CCCC,$0CCC,$CC0C
		DC	$CCCC,$6060,$1800,$6000,$CCCC,$CCCC,$CCC0,$C0CC,$CC30
		DC	$CCCC,$C0C6,$CCC0,$D8CC,$30CC,$F0EE,$CC30,$C0C0,$0C30
		DC	$0000,$00CC,$CCCC,$CCC0,$C0CC,$CC30,$CCD8,$C0D6,$DCCC
		DC	$C0D8,$D80C,$30CC,$F0EE,$7830,$6030,$3030,$00E8,$2060
		DC	$0060,$006C,$30CC,$7E00,$1860,$0000,$6000,$60C0,$FC78
		DC	$FCFC,$0CFC,$FC0C,$FCFC,$00C0,$0000,$0030,$60CC,$FCFC
		DC	$FCFC,$C0FC,$CCFC,$FCCC,$FCC6,$CCC0,$ECCC,$30FC,$E0C6
		DC	$CC30,$FCF0,$0CF0,$00FE,$00CC,$FCFC,$FCFC,$C0FC,$CCFC
		DC	$FCCC,$FCC6,$CCFC,$C0EC,$CCFC,$30FC,$E0C6,$CC30,$FC18
		DC	$3060,$0000,$0020
Font8Loc:	DC	$0000,$0008,$0008,$0008,$0010,$0008,$0018,$0008,$0020
		DC	$0008,$0028,$0008,$0030,$0008,$0038,$0008,$0040,$0008
		DC	$0048,$0008,$0050,$0008,$0058,$0008,$0060,$0008,$0068
		DC	$0008,$0070,$0008,$0078,$0008,$0080,$0008,$0088,$0008
		DC	$0090,$0008,$0098,$0008,$00A0,$0008,$00A8,$0008,$00B0
		DC	$0008,$00B8,$0008,$00C0,$0008,$00C8,$0008,$00D0,$0008
		DC	$00D8,$0008,$00E0,$0008,$00E8,$0008,$00F0,$0008,$00F8
		DC	$0008,$0100,$0008,$0108,$0008,$0110,$0008,$0118,$0008
		DC	$0120,$0008,$0128,$0008,$0130,$0008,$0138,$0008,$0140
		DC	$0008,$0148,$0008,$0150,$0008,$0158,$0008,$0160,$0008
		DC	$0168,$0008,$0170,$0008,$0080,$0008,$0178,$0008,$0180
		DC	$0008,$0188,$0008,$00A8,$0008,$0190,$0008,$0198,$0008
		DC	$01A0,$0008,$01A8,$0008,$01B0,$0008,$01B8,$0008,$01C0
		DC	$0008,$01C8,$0008,$01D0,$0008,$01D8,$0008,$01E0,$0008
		DC	$01E8,$0008,$01F0,$0008,$01F8,$0008,$0200,$0008,$0208
		DC	$0008,$0210,$0008,$0218,$0008,$0220,$0008,$0228,$0008
		DC	$0230,$0008,$0238,$0008,$0240,$0008,$0248,$0008,$0250
		DC	$0008,$0258,$0008,$0260,$0008,$0268,$0008,$0270,$0008
		DC	$0278,$0008,$0280,$0008,$0288,$0008,$0290,$0008,$0298
		DC	$0008,$02A0,$0008,$02A8,$0008,$02B0,$0008,$02B8,$0008
		DC	$02C0,$0008,$02C8,$0008,$02D0,$0008,$02D8,$0008,$02E0
		DC	$0008,$02E0,$0008,$02E0,$0008,$02E0,$0008,$02E0,$0008
		DC	$02E0,$0008,$02E8,$0008,$02F0,$0008,$02F8,$0008,$02E0
		DC	$0008
Font8Name:	Dc.b	'AF',0,0
Font8End:
*=======================================================================*
*			        H E L P					*
*=======================================================================*
Help_Tab:	Dc	0,Help_01-Help,Help_02-Help,Help_03-Help
		Dc	Help_04-Help,Help_05-Help,Help_06-Help,Help_07-Help
		Dc	Help_08-Help,Help_09-Help,Help_0A-Help,Help_0B-Help
		Dc	Help_0C-Help,Help_0D-Help,Help_0E-Help,Help_0F-Help
		Dc	Help_10-Help,Help_11-Help,Help_12-Help,Help_13-Help
		Dc	Help_14-Help,Help_15-Help,Help_16-Help,Help_17-Help
		Dc	Help_18-Help,Help_19-Help,Help_1A-Help,Help_1B-Help
		Dc	Help_1C-Help,Help_1D-Help,Help_1E-Help,Help_1F-Help
		Dc	Help_20-Help,Help_21-Help,Help_22-Help,Help_23-Help
		Dc	Help_24-Help,Help_25-Help,Help_26-Help,Help_27-Help
		Dc	Help_28-Help,Help_29-Help,Help_2A-Help,Help_2B-Help
		Dc	Help_2C-Help,Help_2D-Help,Help_2E-Help,Help_2F-Help
		Dc	Help_30-Help,Help_31-Help,Help_32-Help,Help_33-Help
		Dc	Help_34-Help,Help_35-Help,Help_36-Help,Help_37-Help
		Dc	Help_38-Help,Help_39-Help,Help_3A-Help,Help_3B-Help
		Dc	Help_3C-Help,Help_3D-Help,Help_3E-Help,Help_3F-Help
		Dc	Help_40-Help,Help_41-Help,Help_42-Help,Help_43-Help
		Dc	Help_44-Help,Help_45-Help,Help_46-Help,Help_47-Help
		Dc	Help_48-Help,Help_49-Help,Help_4A-Help,Help_4B-Help
		Dc	Help_4C-Help,Help_4D-Help,Help_4E-Help,Help_4F-Help
		Dc	Help_50-Help,Help_51-Help,Help_52-Help,Help_53-Help
		Dc	Help_54-Help,Help_55-Help,Help_56-Help,Help_57-Help
		Dc	Help_58-Help,Help_59-Help,Help_5A-Help,Help_5B-Help
		Dc	Help_5C-Help,Help_5D-Help,Help_5E-Help,Help_5F-Help
		Dc	Help_60-Help,Help_61-Help,Help_62-Help,Help_63-Help
		Dc	Help_64-Help,Help_65-Help,Help_66-Help,Help_67-Help
		Dc	Help_68-Help,Help_69-Help,Help_6A-Help,Help_6B-Help
		Dc	Help_6C-Help,Help_6D-Help,Help_6E-Help,Help_6F-Help
		Dc	Help_70-Help,Help_71-Help,Help_72-Help,Help_73-Help
		Dc	Help_74-Help,Help_75-Help,Help_76-Help,Help_77-Help
		Dc	Help_78-Help,Help_79-Help,Help_7A-Help,Help_7B-Help
		Dc	Help_7C-Help,Help_7D-Help,Help_7E-Help,Help_7F-Help
		Dc	Help_80-Help,Help_81-Help,Help_82-Help,Help_83-Help
		Dc	Help_84-Help,Help_85-Help,Help_86-Help,Help_87-Help
		Dc	Help_88-Help,Help_89-Help,Help_8A-Help,Help_8B-Help
		Dc	Help_8C-Help,Help_8D-Help,Help_8E-Help,Help_8F-Help
		Dc	Help_90-Help,Help_91-Help,Help_92-Help,Help_93-Help
		Dc	Help_94-Help,Help_95-Help,Help_96-Help,Help_97-Help
		Dc	Help_98-Help,Help_99-Help,Help_9A-Help,Help_9B-Help
		Dc	Help_9C-Help,Help_9D-Help,Help_9E-Help,Help_9F-Help
		Dc	Help_A0-Help,Help_A1-Help,Help_A2-Help,Help_A3-Help
		Dc	Help_A4-Help,Help_A5-Help,Help_A6-Help,Help_A7-Help
		Dc	Help_A8-Help,Help_A9-Help,Help_AA-Help,Help_AB-Help
		Dc	Help_AC-Help,Help_AD-Help,Help_AE-Help,Help_AF-Help
		Dc	Help_B0-Help,Help_B1-Help,Help_B2-Help,Help_B3-Help
		Dc	Help_B4-Help,Help_B5-Help,Help_B6-Help,Help_B7-Help
		Dc	Help_B8-Help,Help_B9-Help,Help_BA-Help,Help_BB-Help
		Dc	Help_BC-Help,Help_BD-Help,Help_BE-Help,Help_BF-Help
		Dc	Help_C0-Help,Help_C1-Help,Help_C2-Help,Help_C3-Help
		Dc	Help_C4-Help,Help_C5-Help,Help_C6-Help,Help_C7-Help
		Dc	Help_C8-Help,Help_C9-Help,Help_CA-Help,Help_CB-Help
		Dc	Help_CC-Help,Help_CD-Help,Help_CE-Help,Help_CF-Help
		Dc	Help_D0-Help,Help_D1-Help,Help_D2-Help,Help_D3-Help
		Dc	Help_D4-Help,Help_D5-Help,Help_D6-Help,Help_D7-Help
		Dc	Help_D8-Help,Help_D9-Help,Help_DA-Help,Help_DB-Help
		Dc	Help_DC-Help,Help_DD-Help,Help_DE-Help,Help_DF-Help
		Dc	Help_E0-Help,Help_E1-Help,Help_E2-Help,Help_E3-Help
		Dc	Help_E4-Help,Help_E5-Help,Help_E6-Help,Help_E7-Help
		Dc	Help_E8-Help,Help_E9-Help,Help_EA-Help,Help_EB-Help
		Dc	Help_EC-Help,Help_ED-Help,Help_EE-Help,Help_EF-Help
		Dc	Help_F0-Help,Help_F1-Help,Help_F2-Help,Help_F3-Help
		Dc	Help_F4-Help
Help:
;00=No Help
Help_01:	Dc.b	'ADD FRAME',0
Help_02:	Dc.b	'DELETE FRAME',0
Help_03:	Dc.b	'NEXT FRAME',0
Help_04:	Dc.b	'PREVIOUS FRAME',0
Help_05:	Dc.b	'QUIT PROGRAM',0
Help_06:	Dc.b	'TO FIRST FRAME',0
Help_07:	Dc.b	'TO LAST FRAME',0
Help_08:	Dc.b	'PLAY DIRECTION',0
Help_09:	Dc.b	'ZOOM ON/OFF',0
Help_0A:	Dc.b	'FREEHAND',0
Help_0B:	Dc.b	'UNDO LAST EDIT',0
Help_0C:	Dc.b	'PLAY MODE',0
Help_0D:	Dc.b	'PLAY',0
Help_0E:	Dc.b	'PLAY ON SCREEN',0
Help_0F:	Dc.b	'FRAME SLIDER',0
Help_10:	Dc.b	'CREATE NEW UNIT',0
Help_11:	Dc.b	'UPDATE TO DISK',0
Help_12:	Dc.b	'CURRENT FRAME',0
Help_13:	Dc.b	'TOTAL FRAMES',0
Help_14:	Dc.b	'PICK PIECE',0
Help_15:	Dc.b	'DELETE PIECE',0
Help_16:	Dc.b	'DRAW WINDOW',0
Help_17:	Dc.b	'CALC SHADOW',0
Help_18:	Dc.b	'COPY SHADOW',0
Help_19:	Dc.b	'TRIM EDGES',0
Help_1A:	Dc.b	'NAME OF UNIT',0
Help_1B:	Dc.b	'GRAPHICS',0
Help_1C:	Dc.b	'DRAW-MASK',0
Help_1D:	Dc.b	'COLLISION-MASK',0
Help_1E:	Dc.b	'FLIP X',0
Help_1F:	Dc.b	'FLIP Y',0
Help_20:	Dc.b	'SHOW RANGE',0
Help_21:	Dc.b	'SHOW ALL',0
Help_22:	Dc.b	'BACKWARD',0
Help_23:	Dc.b	'LOOP START',0
Help_24:	Dc.b	'LOOP END',0
Help_25:	Dc.b	'STARTING POINT',0
Help_26:	Dc.b	'ENDING POINT',0
Help_27:	Dc.b	'ONCE/LOOP',0
Help_28:	Dc.b	'STOP PLAYING',0
Help_29:	Dc.b	'USE SAMPLE',0
Help_2A:	Dc.b	'SAMPLE WINDOW',0
Help_2B:	Dc.b	'REMOVE PICTURE',0
Help_2C:	Dc.b	'CUT ALL PIECES',0
Help_2D:	Dc.b	'AUTO CUT',0
Help_2E:	Dc.b	'MANUAL CUT',0
Help_2F:	Dc.b	'FREEHAND CUT',0
Help_30:	Dc.b	'CLEAR CUT AREAS',0
Help_31:	Dc.b	'STORE AS PIECES',0
Help_32:	Dc.b	'STORE AND CLEAR',0
Help_33:	Dc.b	'ZOOM IN',0
Help_34:	Dc.b	'ZOOM OUT',0
Help_35:	Dc.b	'ZOOM FACTOR',0
Help_36:	Dc.b	'INFORMATION',0
Help_37:	Dc.b	'TO TOP',0
Help_38:	Dc.b	'TOWARDS TOP',0
Help_39:	Dc.b	'TOWARDS BOTTOM',0
Help_3A:	Dc.b	'TO BOTTOM',0
Help_3B:	Dc.b	'COLLISION',0
Help_3C:	Dc.b	'VOLUME',0
Help_3D:	Dc.b	'FINE TUNING',0
Help_3E:	Dc.b	'NOTE',0
Help_3F:	Dc.b	'OCTAVE',0
Help_40:	Dc.b	'FREQUENCY',0
Help_41:	Dc.b	'SAMPLE USED',0
Help_42:	Dc.b	'PLAY SOUND',0
Help_43:	Dc.b	'PLAY SAMPLE',0
Help_44:	Dc.b	'CUT RANGE',0
Help_45:	Dc.b	'COPY RANGE',0
Help_46:	Dc.b	'PASTE',0
Help_47:	Dc.b	'SCREEN DRAG BAR',0
Help_48:	Dc.b	'WORKBENCH',0
Help_49:	Dc.b	'DEPTH SCREEN',0
Help_4A:	Dc.b	'PREFERENCES',0
Help_4B:	Dc.b	'CONDITIONS LIST',0
Help_4C:	Dc.b	'TIMER LIST',0
Help_4D:	Dc.b	'POSITION LIST',0
Help_4E:	Dc.b	'DELETE EVENT',0
Help_4F:	Dc.b	'PICK COLOR',0
Help_50:	Dc.b	'SCROLL WINDOW',0
Help_51:	Dc.b	'SELECT EVENT',0
Help_52:	Dc.b	'DECREASE VALUE',0
Help_53:	Dc.b	'INCREASE VALUE',0
Help_54:	Dc.b	'USE PIECE',0
Help_55:	Dc.b	'DELETE PIECE',0
Help_56:	Dc.b	'PROPORTIONAL',0
Help_57:	Dc.b	'PICK CHARACTER',0
Help_58:	Dc.b	'PALETTE WINDOW',0
Help_59:	Dc.b	'FONT WINDOW',0
Help_5A:	Dc.b	'RED VALUE',0
Help_5B:	Dc.b	'GREEN VALUE',0
Help_5C:	Dc.b	'BLUE VALUE',0
Help_5D:	Dc.b	'BROWSE UP',0
Help_5E:	Dc.b	'BROWSE DOWN',0
Help_5F:	Dc.b	'SNAPSHOT WINDOW',0
Help_60:	Dc.b	'LOG WINDOW',0
Help_61:	Dc.b	'PATHLIST WINDOW',0
Help_62:	Dc.b	'EDIT COLLISION',0
Help_63:	Dc.b	'GRID WINDOW',0
Help_64:	Dc.b	'PLACE CENTER',0
Help_65:	Dc.b	'CLASSIFY OBJECT',0
Help_66:	Dc.b	'REPLAY GAME',0
Help_67:	Dc.b	'PAUSE',0
Help_68:	Dc.b	'MODULE WINDOW',0
Help_69:	Dc.b	'USE MODULE',0
Help_6A:	Dc.b	'MODULE USED',0
Help_6B:	Dc.b	'SPACE WIDTH',0
Help_6C:	Dc.b	'ENABLE/DISABLE',0
Help_6D:	Dc.b	'REPEAT FRAME',0
Help_6E:	Dc.b	'PROJECT NAME',0
Help_6F:	Dc.b	'HARDWARE FILTER',0
Help_70:	Dc.b	'UNIT/FILE NAME',0
Help_71:	Dc.b	'CHANGE BACKGRND',0
Help_72:	Dc.b	'CHANGE SCROLL',0
Help_73:	Dc.b	'RELEASE OBJECTS',0
Help_74:	Dc.b	'PLAY SOUND',0
Help_75:	Dc.b	'CHANGE SONG',0
Help_76:	Dc.b	'CHANGE OBJECT',0
Help_77:	Dc.b	'CHANGE PLAYER',0
Help_78:	Dc.b	'CHANGE SCORE',0
Help_79:	Dc.b	'CHANGE PALETTE',0
Help_7A:	Dc.b	'END OF LEVEL',0
Help_7B:	Dc.b	'FILLED BOX',0
Help_7C:	Dc.b	'SELECT NAME',0
Help_7D:	Dc.b	'LIST UNITS',0
Help_7E:	Dc.b	'LIST DISKS',0
Help_7F:	Dc.b	'PARENT DIR',0
Help_80:	Dc.b	'ADD SAVEPATH',0
Help_81:	Dc.b	'DELETE SAVEPATH',0
Help_82:	Dc.b	'SELECT SAVEPATH',0
Help_83:	Dc.b	'SELECT BRUSH',0
Help_84:	Dc.b	'STRAIGHT LINE',0
Help_85:	Dc.b	'FLOOD FILL',0
Help_86:	Dc.b	'INVENTORY',0
Help_87:	Dc.b	'ADD PIECE',0
Help_88:	Dc.b	'ADD ANIMATION',0
Help_89:	Dc.b	'DELETE ITEM',0
Help_8A:	Dc.b	'CHANGE SAVEPATH',0
Help_8B:	Dc.b	'PREVIOUS FRAME',0
Help_8C:	Dc.b	'SOUND WINDOW',0
Help_8D:	Dc.b	'USE SOUND',0
Help_8E:	Dc.b	'SOUND USED',0
Help_8F:	Dc.b	'USE PIECE',0
Help_90:	Dc.b	'USE ANIMATION',0
Help_91:	Dc.b	'USE OBJECT',0
Help_92:	Dc.b	'USE UNIT',0
Help_93:	Dc.b	'UNIT USED',0
Help_94:	Dc.b	'REMOVE SOUND',0
Help_95:	Dc.b	'PREV POWERUP',0
Help_96:	Dc.b	'NEXT POWERUP',0
Help_97:	Dc.b	'DELETE POWERUP',0
Help_98:	Dc.b	'ADD POWERUP',0
Help_99:	Dc.b	'PREVIOUS SHOT',0
Help_9A:	Dc.b	'NEXT SHOT',0
Help_9B:	Dc.b	'DELETE SHOT',0
Help_9C:	Dc.b	'ADD SHOT',0
Help_9D:	Dc.b	'CURRENT POWERUP',0
Help_9E:	Dc.b	'TOTAL POWERUPS',0
Help_9F:	Dc.b	'CURRENT SHOT',0
Help_A0:	Dc.b	'TOTAL SHOTS',0
Help_A1:	Dc.b	'MOVEPART WINDOW',0
Help_A2:	Dc.b	'DELETE PART',0
Help_A3:	Dc.b	'ADD FREEHAND',0
Help_A4:	Dc.b	'ADD SINE',0
Help_A5:	Dc.b	'ADD LINE',0
Help_A6:	Dc.b	'ADD POSITION',0
Help_A7:	Dc.b	'ADD CONTROLLER',0
Help_A8:	Dc.b	'SELECT MOVEPART',0
Help_A9:	Dc.b	'SELECT COLOR',0
Help_AA:	Dc.b	'ADD COLORS',0
Help_AB:	Dc.b	'DELETE COLORS',0
Help_AC:	Dc.b	'TOTAL COLORS',0
Help_AD:	Dc.b	'NEXT COLOR',0
Help_AE:	Dc.b	'PREVIOUS COLOR',0
Help_AF:	Dc.b	'CURRENT COLOR',0
Help_B0:	Dc.b	'ANIMATION DELAY',0
Help_B1:	Dc.b	'SHOW SUM PATH',0
Help_B2:	Dc.b	'REMOVE UNIT',0
Help_B3:	Dc.b	'USE MOVEMENT',0
Help_B4:	Dc.b	'SONG WINDOW',0
Help_B5:	Dc.b	'USE SONG',0
Help_B6:	Dc.b	'SONG USED',0
Help_B7:	Dc.b	'REMOVE SONG',0
Help_B8:	Dc.b	'USE FONT',0
Help_B9:	Dc.b	'MOVEMENT WINDOW',0
Help_BA:	Dc.b	'ANIM WINDOW',0
Help_BB:	Dc.b	'PIECE WINDOW',0
Help_BC:	Dc.b	'REMOVE FONT',0
Help_BD:	Dc.b	'REMOVE MOVEMENT',0
Help_BE:	Dc.b	'REMOVE ANIM',0
Help_BF:	Dc.b	'REMOVE PIECE',0
Help_C0:	Dc.b	'PIECE USED',0
Help_C1:	Dc.b	'ANIMATION USED',0
Help_C2:	Dc.b	'MOVEMENT USED',0
Help_C3:	Dc.b	'FONT USED',0
Help_C4:	Dc.b	'ADD TEXT',0
Help_C5:	Dc.b	'ADD MOVEMENT',0
Help_C6:	Dc.b	'ADD SOUND',0
Help_C7:	Dc.b	'ADD SONG',0
Help_C8:	Dc.b	'SCREEN EVENTS',0
Help_C9:	Dc.b	'SCREEN MODES',0
Help_CA:	Dc.b	'',0
Help_CB:	Dc.b	'',0
Help_CC:	Dc.b	'',0
Help_CD:	Dc.b	'',0
Help_CE:	Dc.b	'',0
Help_CF:	Dc.b	'',0
Help_D0:	Dc.b	'',0
Help_D1:	Dc.b	'',0
Help_D2:	Dc.b	'',0
Help_D3:	Dc.b	'',0
Help_D4:	Dc.b	'',0
Help_D5:	Dc.b	'',0
Help_D6:	Dc.b	'',0
Help_D7:	Dc.b	'',0
Help_D8:	Dc.b	'',0
Help_D9:	Dc.b	'',0
Help_DA:	Dc.b	'',0
Help_DB:	Dc.b	'',0
Help_DC:	Dc.b	'',0
Help_DD:	Dc.b	'',0
Help_DE:	Dc.b	'',0
Help_DF:	Dc.b	'',0
Help_E0:	Dc.b	'',0
Help_E1:	Dc.b	'SELECTOR WINDOW',0
Help_E2:	Dc.b	'',0
Help_E3:	Dc.b	'',0
Help_E4:	Dc.b	'',0
Help_E5:	Dc.b	'',0
Help_E6:	Dc.b	'',0
Help_E7:	Dc.b	'',0
Help_E8:	Dc.b	'',0
Help_E9:	Dc.b	'',0
Help_EA:	Dc.b	'',0
Help_EB:	Dc.b	'',0
Help_EC:	Dc.b	'',0
Help_ED:	Dc.b	'',0
Help_EE:	Dc.b	'',0
Help_EF:	Dc.b	'',0
Help_F0:	Dc.b	'',0
Help_F1:	Dc.b	'CLOSE WINDOW',0
Help_F2:	Dc.b	'DRAG WINDOW',0
Help_F3:	Dc.b	'DEPTH WINDOW',0
Help_F4:	Dc.b	'SIZE WINDOW',0
;F5=
;F6=Sample Pos
;F7=Sound Pos
;F8=Picture XY
;F9=Piece XY
;FA=Anim XY
;FB=Move XY
;FC=Back XY
;FD=Screen XY
;FE=Snap XY
;FF=
*=======================================================================*
*			        T E X T					*
*=======================================================================*
Picture8T:	Dc.b	'Picture',0
Piece8T:	Dc.b	'Piece',0
Animation8T:	Dc.b	'Animation',0
Background8T:	Dc.b	'Background',0
Scroll8T:	Dc.b	'Scroll',0
Selector8T:	Dc.b	'Selector',0
Quit8T:		Dc.b	'Quit',0
Windows8T:	Dc.b	'Windows',0
Sample8T:	Dc.b	'Sample',0
Palette8T:	Dc.b	'Palette',0
Sound8T:	Dc.b	'Sound',0
Movement8T:	Dc.b	'Movement',0
Font8T:		Dc.b	'Font',0
Draw8T:		Dc.b	'Draw Piece',0
Game8T:		Dc.b	'Game',0
Weapon8T:	Dc.b	'Weapon',0
Update8T:	Dc.b	'Update',0
Delete8T:	Dc.b	'Delete',0
Remove8T:	Dc.b	'Remove',0
Screen8T:	Dc.b	'Screen',0
Level8T:	Dc.b	'Level',0
Wave8T:		Dc.b	'Wave',0
Module8T:	Dc.b	'Module',0
Song8T:		Dc.b	'Song',0
Object8T:	Dc.b	'Object',0
Log8T:		Dc.b	'Log',0
Line8T:		Dc.b	'Line:',0
Control8T:	Dc.b	'Control:',0
Information8T:	Dc.b	'Information',0
Preferences8T:	Dc.b	'Preferences',0
Position8T:	Dc.b	'Position:',0
Arcade8T:	Dc.b	'Arcade',0
Factory8T:	Dc.b	'Factory',0
Version8T:	Dc.b	'I',0
PathList8T:	Dc.b	'Path List',0
Class8T:	Dc.b	'Class:',0
Hz8T:		Dc.b	'Hz',0
Snapshot8T:	Dc.b	'Snapshot',0
ScreenEvents8T:	Dc.b	'Screen Events',0
Condition8T:	Dc.b	'Condition:',0
Time8T:		Dc.b	'Time:',0
Freehand8T:	Dc.b	'Freehand:',0
Sine8T:		Dc.b	'Sine:',0
Controller8T:	Dc.b	'Controller:',0
MapSize8T:	Dc.b	'Map Size:',0
PowerUp8T:	Dc.b	'Powerup:',0
Shot8T:		Dc.b	'Shot:',0
MovePart8T:	Dc.b	'Movepart',0

PictureT:	Dc.b	'PICTURE',0
PieceT:		Dc.b	'PIECE',0
BackgroundT:	Dc.b	'BACKGROUND',0
AnimationT:	Dc.b	'ANIMATION',0
MovementT:	Dc.b	'MOVEMENT',0
ObjectT:	Dc.b	'OBJECT',0
LevelT:		Dc.b	'LEVEL',0
WaveT:		Dc.b	'WAVE',0
ScreenT:	Dc.b	'SCREEN',0
SoundT:		Dc.b	'SOUND',0
SongT:		Dc.b	'SONG',0
GameT:		Dc.b	'GAME',0
PaletteT:	Dc.b	'PALETTE',0
FontT:		Dc.b	'FONT',0
WeaponT:	Dc.b	'WEAPON',0
SampleT:	Dc.b	'SAMPLE',0
ModuleT:	Dc.b	'MODULE',0
PlayerT:	Dc.b	'PLAYER',0

AngleT:		Dc.b	'ANGLE:',0
StartT:		Dc.b	'START:',0
DurationT:	Dc.b	'DURATION:',0
OffsetT:	Dc.b	'OFFSET:',0
MaxOutT:	Dc.b	'MAX OUT:',0
FireDelayT:	Dc.b	'FIRING DELAY:',0
SpeedT:		Dc.b	'SPEED:',0
EffectT:	Dc.b	'EFFECT:',0
ValT:		Dc.b	'VAL:',0
SpdT:		Dc.b	'SPD:',0
PriceT:		Dc.b	'PRICE:',0
AmmoDrainT:	Dc.b	'AMMO DRAINAGE:',0
PowerT:		Dc.b	'POWER:',0
HitPowerT:	Dc.b	'HITPOWER:',0
ScoreT:		Dc.b	'SCORE:',0
HitScoreT:	Dc.b	'HITSCORE:',0
FrequencyT:	Dc.b	'FREQUENCY:',0
CancelT:	Dc.b	'CANCEL',0
PlaceT:		Dc.b	'PLACE',0
XT:		Dc.b	'X:',0
YT:		Dc.b	'Y:',0
PixelsT:	Dc.b	'PIXELS',0
DashT:		Dc.b	'-',0
CollT:		Dc.b	'COLL',0
NotLoadedT:	Dc.b	'NOT LOADED!',0
NoUnitsT:	Dc.b	'NO UNITS!',0
DelayT:		Dc.b	'DELAY:',0
RepeatT:	Dc.b	'REPEAT:',0
FrameT:		Dc.b	'FRAME:',0
OfT:		Dc.b	'OF',0
SureT:		Dc.b	'ARE YOU SURE?',0
YesT:		Dc.b	'YES',0
NoT:		Dc.b	'NO',0
DeleteT:	Dc.b	'DELETE',0
RemoveT:	Dc.b	'REMOVE',0
DisksT:		Dc.b	'DISKS',0
UnitsT:		Dc.b	'UNITS',0
ParentT:	Dc.b	'PARENT',0
LoadT:		Dc.b	'LOAD',0
SaveT:		Dc.b	'SAVE',0
CopyT:		Dc.b	'COPY',0
SaveAsT:	Dc.b	'SAVE AS',0
LoadAllT:	Dc.b	'LOADALL',0
UpdtAllT:	Dc.b	'UPDTALL',0
UpdateT:	Dc.b	'UPDATE',0
AddT:		Dc.b	'ADD',0
PathT:		Dc.b	'PATH:',0
NameT:		Dc.b	'NAME:',0
HeightT:	Dc.b	'HEIGHT:',0
WidthT:		Dc.b	'WIDTH:',0
SpaceT:		Dc.b	'SPACE:',0
PropT:		Dc.b	'PROP:',0
OkT:		Dc.b	'OK',0
ChangeT:	Dc.b	'CHANGE',0
MakeDirT:	Dc.b	'MAKEDIR',0
RT:		Dc.b	'R',0
GT:		Dc.b	'G',0
BT:		Dc.b	'B',0
ExchangeT:	Dc.b	'EXCHANGE',0
SpreadT:	Dc.b	'SPREAD',0
PickT:		Dc.b	'PICK',0
FixedT:		Dc.b	'FIXED',0
CycleT:		Dc.b	'CYCLE',0
RasterT:	Dc.b	'RASTER',0
RateT:		Dc.b	'RATE:',0
QuitT:		Dc.b	'QUIT',0
ClearT:		Dc.b	'CLEAR',0
		Even
*---------------
Sine:	;(0-180 Degrees, 512 Words, Ampl=32767, Round Corr.)
	Dc $0000,$00C9,$0192,$025B,$0324,$03ED,$04B6,$057F,$0648,$0711
	Dc $07D9,$08A2,$096A,$0A33,$0AFB,$0BC4,$0C8C,$0D54,$0E1C,$0EE3
	Dc $0FAB,$1072,$113A,$1201,$12C8,$138F,$1455,$151C,$15E2,$16A8
	Dc $176E,$1833,$18F9,$19BE,$1A82,$1B47,$1C0B,$1CCF,$1D93,$1E57
	Dc $1F1A,$1FDD,$209F,$2161,$2223,$22E5,$23A6,$2467,$2528,$25E8
	Dc $26A8,$2767,$2826,$28E5,$29A3,$2A61,$2B1F,$2BDC,$2C99,$2D55
	Dc $2E11,$2ECC,$2F87,$3041,$30FB,$31B5,$326E,$3326,$33DF,$3496
	Dc $354D,$3604,$36BA,$376F,$3824,$38D9,$398C,$3A40,$3AF2,$3BA5
	Dc $3C56,$3D07,$3DB8,$3E68,$3F17,$3FC5,$4073,$4121,$41CE,$427A
	Dc $4325,$43D0,$447A,$4524,$45CD,$4675,$471C,$47C3,$4869,$490F
	Dc $49B4,$4A58,$4AFB,$4B9D,$4C3F,$4CE0,$4D81,$4E20,$4EBF,$4F5D
	Dc $4FFB,$5097,$5133,$51CE,$5268,$5302,$539B,$5432,$54C9,$5560
	Dc $55F5,$568A,$571D,$57B0,$5842,$58D3,$5964,$59F3,$5A82,$5B10
	Dc $5B9C,$5C28,$5CB3,$5D3E,$5DC7,$5E4F,$5ED7,$5F5D,$5FE3,$6068
	Dc $60EB,$616E,$61F0,$6271,$62F1,$6370,$63EE,$646C,$64E8,$6563
	Dc $65DD,$6656,$66CF,$6746,$67BC,$6832,$68A6,$6919,$698B,$69FD
	Dc $6A6D,$6ADC,$6B4A,$6BB7,$6C23,$6C8E,$6CF8,$6D61,$6DC9,$6E30
	Dc $6E96,$6EFB,$6F5E,$6FC1,$7022,$7083,$70E2,$7140,$719D,$71F9
	Dc $7254,$72AE,$7307,$735F,$73B5,$740A,$745F,$74B2,$7504,$7555
	Dc $75A5,$75F3,$7641,$768D,$76D8,$7722,$776B,$77B3,$77FA,$783F
	Dc $7884,$78C7,$7909,$794A,$7989,$79C8,$7A05,$7A41,$7A7C,$7AB6
	Dc $7AEE,$7B26,$7B5C,$7B91,$7BC5,$7BF8,$7C29,$7C59,$7C88,$7CB6
	Dc $7CE3,$7D0E,$7D39,$7D62,$7D89,$7DB0,$7DD5,$7DFA,$7E1D,$7E3E
	Dc $7E5F,$7E7E,$7E9C,$7EB9,$7ED5,$7EEF,$7F09,$7F21,$7F37,$7F4D
	Dc $7F61,$7F74,$7F86,$7F97,$7FA6,$7FB4,$7FC1,$7FCD,$7FD8,$7FE1
	Dc $7FE9,$7FF0,$7FF5,$7FF9,$7FFD,$7FFE,$7FFF,$7FFE,$7FFD,$7FF9
	Dc $7FF5,$7FF0,$7FE9,$7FE1,$7FD8,$7FCD,$7FC1,$7FB4,$7FA6,$7F97
	Dc $7F86,$7F74,$7F61,$7F4D,$7F37,$7F21,$7F09,$7EEF,$7ED5,$7EB9
	Dc $7E9C,$7E7E,$7E5F,$7E3E,$7E1D,$7DFA,$7DD5,$7DB0,$7D89,$7D62
	Dc $7D39,$7D0E,$7CE3,$7CB6,$7C88,$7C59,$7C29,$7BF8,$7BC5,$7B91
	Dc $7B5C,$7B26,$7AEE,$7AB6,$7A7C,$7A41,$7A05,$79C8,$7989,$794A
	Dc $7909,$78C7,$7884,$783F,$77FA,$77B3,$776B,$7722,$76D8,$768D
	Dc $7641,$75F3,$75A5,$7555,$7504,$74B2,$745F,$740A,$73B5,$735E
	Dc $7307,$72AE,$7254,$71F9,$719D,$7140,$70E2,$7083,$7022,$6FC1
	Dc $6F5E,$6EFA,$6E96,$6E30,$6DC9,$6D61,$6CF8,$6C8E,$6C23,$6BB7
	Dc $6B4A,$6ADC,$6A6D,$69FC,$698B,$6919,$68A6,$6831,$67BC,$6746
	Dc $66CF,$6656,$65DD,$6563,$64E8,$646B,$63EE,$6370,$62F1,$6271
	Dc $61F0,$616E,$60EB,$6068,$5FE3,$5F5D,$5ED7,$5E4F,$5DC7,$5D3D
	Dc $5CB3,$5C28,$5B9C,$5B0F,$5A82,$59F3,$5964,$58D3,$5842,$57B0
	Dc $571D,$5689,$55F5,$555F,$54C9,$5432,$539A,$5302,$5268,$51CE
	Dc $5133,$5097,$4FFB,$4F5D,$4EBF,$4E20,$4D81,$4CE0,$4C3F,$4B9D
	Dc $4AFB,$4A57,$49B3,$490F,$4869,$47C3,$471C,$4675,$45CD,$4524
	Dc $447A,$43D0,$4325,$427A,$41CD,$4121,$4073,$3FC5,$3F17,$3E67
	Dc $3DB8,$3D07,$3C56,$3BA4,$3AF2,$3A40,$398C,$38D8,$3824,$376F
	Dc $36BA,$3604,$354D,$3496,$33DE,$3326,$326E,$31B5,$30FB,$3041
	Dc $2F87,$2ECC,$2E10,$2D55,$2C98,$2BDC,$2B1F,$2A61,$29A3,$28E5
	Dc $2826,$2767,$26A8,$25E8,$2528,$2467,$23A6,$22E5,$2223,$2161
	Dc $209F,$1FDC,$1F1A,$1E56,$1D93,$1CCF,$1C0B,$1B47,$1A82,$19BD
	Dc $18F8,$1833,$176D,$16A8,$15E2,$151B,$1455,$138E,$12C8,$1201
	Dc $113A,$1072,$0FAB,$0EE3,$0E1B,$0D54,$0C8C,$0BC3,$0AFB,$0A33
	Dc $096A,$08A2,$07D9,$0710,$0648,$057F,$04B6,$03ED,$0324,$025B
	Dc $0192,$00C9
*=======================================================================*
*			       I M A G E S				*
*=======================================================================*
Im:
Im_Close:
	Dc %111111100
	Dc %100000100
	Dc %100000100
	Dc %100100100
	Dc %100000100
	Dc %100000100
	Dc %111111100
Im_Depth:
	Dc %111111000
	Dc %100001000
	Dc %100111111
	Dc %100111111
	Dc %111111111
	Dc %000111111
	Dc %000111111
Im_Info:
	Dc %000111000
	Dc %000111000
	Dc %000000000
	Dc %001111000
	Dc %000111000
	Dc %000111000
	Dc %001111100
Im_Size:
	Dc %000010000
	Dc %000110000
	Dc %001010000
	Dc %010010000
	Dc %111110000
Im_DArr:
	Dc %111110000
	Dc %011100000
	Dc %001000000
Im_UArr:
	Dc %001000000
	Dc %011100000
	Dc %111110000
Im_RArr:
	Dc %100000000
	Dc %110000000
	Dc %111000000
	Dc %110000000
	Dc %100000000
Im_LArr:
	Dc %001000000
	Dc %011000000
	Dc %111000000
	Dc %011000000
	Dc %001000000
Im_Plus:
	Dc %001000000
	Dc %001000000
	Dc %111110000
	Dc %001000000
	Dc %001000000
Im_Minus:
	Dc %111110000
Im_Fill:
	Dc %000010000
	Dc %000101000
	Dc %001000100
	Dc %010000010
	Dc %001000100
	Dc %000101000
	Dc %000110000
	Dc %000100000
	Dc %011110000
Im_Zoom:
	Dc %000011100
	Dc %000100010
	Dc %001011001
	Dc %001010001
	Dc %001000001
	Dc %001100010
	Dc %011111100
	Dc %111000000
	Dc %110000000
Im_Line:
	Dc %000000000
	Dc %000000010
	Dc %000000100
	Dc %000001000
	Dc %000010000
	Dc %000100000
	Dc %001000000
	Dc %010000000
	Dc %000000000
Im_FillBox:
	Dc %011111110
	Dc %011111110
	Dc %011111110
	Dc %011111110
	Dc %011111110
	Dc %011111110
	Dc %011111110
Im_FreeHand:
	Dc %001100000
	Dc %010010000
	Dc %100010001
	Dc %000100010
	Dc %001000010
	Dc %010000100
	Dc %010000100
	Dc %010001000
	Dc %001110000
Im_FullClip:
	Dc %111110000
	Dc %100010000
	Dc %101111100
	Dc %101000100
	Dc %111011111
	Dc %001010001
	Dc %001110001
	Dc %000010001
	Dc %000011111
Im_AutoClip:
	Dc %001111100
	Dc %001000100
	Dc %001000100
	Dc %001000100
	Dc %001111100
;Im_PolyClip:
;	Dc %000010000
;	Dc %000101000
;	Dc %001000100
;	Dc %010000010
;	Dc %100000001
;	Dc %010000010
;	Dc %001000100
;	Dc %000101000
;	Dc %000010000
Im_ManuClip:
	Dc %011101110
	Dc %010000010
	Dc %010000010
	Dc %000000000
	Dc %010000010
	Dc %010000010
	Dc %011101110
Im_ClrClips:
	Dc %100000001
	Dc %010000010
	Dc %001111100
	Dc %001101100
	Dc %001010100
	Dc %001101100
	Dc %001111100
	Dc %010000010
	Dc %100000001
Im_Store:
	Dc %111110100
	Dc %100010110
	Dc %100010111
	Dc %100010110
	Dc %111110100
Im_StoreClr:
	Dc %111110100
	Dc %111110110
	Dc %111110111
	Dc %111110110
	Dc %111110100
Im_Undo:
	Dc %100101001
	Dc %100101101
	Dc %100101011
	Dc %011001001
	Dc %000000000
	Dc %111000110
	Dc %100101001
	Dc %100101001
	Dc %111000110
Im_Up:
	Dc %000010000
	Dc %000111000
	Dc %001111100
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000010000
Im_Down:
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %001111100
	Dc %000111000
	Dc %000010000
Im_Forward:
	Dc %000000100
	Dc %000000110
	Dc %111111111
	Dc %000000110
	Dc %000000100
Im_Backward:
	Dc %001000000
	Dc %011000000
	Dc %111111111
	Dc %011000000
	Dc %001000000
Im_Loop:
	Dc %000100000
	Dc %000110000
	Dc %011111110
	Dc %100110001
	Dc %100100001
	Dc %100000001
	Dc %011111110
	Dc %000000000
	Dc %000000000
Im_Stop:
	Dc %001111100
	Dc %001111100
	Dc %001111100
	Dc %001111100
	Dc %001111100
	Dc %001111100
	Dc %001111100
Im_Pause:
	Dc %001101100
	Dc %001101100
	Dc %001101100
	Dc %001101100
	Dc %001101100
	Dc %001101100
	Dc %001101100
Im_ToEnd:
	Dc %010010000
	Dc %011010000
	Dc %011110000
	Dc %011010000
	Dc %010010000
Im_ToStart:
	Dc %100100000
	Dc %101100000
	Dc %111100000
	Dc %101100000
	Dc %100100000
Im_NextFrame:
	Dc %001010000
	Dc %001011000
	Dc %001011100
	Dc %001011110
	Dc %001011100
	Dc %001011000
	Dc %001010000
Im_PrevFrame:
	Dc %000010100
	Dc %000110100
	Dc %001110100
	Dc %011110100
	Dc %001110100
	Dc %000110100
	Dc %000010100
Im_Play:
	Dc %000100000
	Dc %000110000
	Dc %000111000
	Dc %000111100
	Dc %000111000
	Dc %000110000
	Dc %000100000
;Im_DigDown:
;	Dc %111110000
;	Dc %011100000
;	Dc %001000000
;	Dc %000000000
;	Dc %111110000
;Im_DigUp:
;	Dc %001000000
;	Dc %011100000
;	Dc %111110000
;	Dc %000000000
;	Dc %111110000
Im_Once:
	Dc %000000000
	Dc %000000000
	Dc %000001001
	Dc %000001101
	Dc %111111111
	Dc %000001101
	Dc %000001001
	Dc %000000000
	Dc %000000000
Im_WorkBench:
	Dc %000000000
	Dc %100101110
	Dc %100101001
	Dc %100101110
	Dc %111101001
	Dc %100101110
	Dc %000000000
;Im_Sleep:
;	Dc %000000000
;	Dc %011111110
;	Dc %000011100
;	Dc %000111000
;	Dc %001110000
;	Dc %011111110
;	Dc %000000000
;Im_Help:
;	Dc %011111110
;	Dc %011101110
;	Dc %000001110
;	Dc %000111110
;	Dc %000111000
;	Dc %000000000
;	Dc %000111000
Im_Blank:
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
Im_Check5:
	Dc %000110000
	Dc %101100000
	Dc %111000000
	Dc %010000000
	Dc %010000000
;Im_Check7:
;	Dc %000000100
;	Dc %000011000
;	Dc %100110000
;	Dc %011100000
;	Dc %011100000
;	Dc %001000000
;	Dc %001000000
Im_Select:
	Dc %011111110
	Dc %010000010
	Dc %010111010
	Dc %010000010
	Dc %010111010
	Dc %010000010
	Dc %010111010
	Dc %010000010
	Dc %011111110
Im_Disk:
	Dc %111111111
	Dc %100000001
	Dc %100000001
	Dc %100000001
	Dc %111111111
	Dc %110000011
	Dc %110100011
	Dc %110100011
	Dc %011111111
;Im_Memory:
;	Dc %001111100
;	Dc %111101111
;	Dc %001101100
;	Dc %111111111
;	Dc %001101100
;	Dc %111101111
;	Dc %001111100
;	Dc %111101111
;	Dc %001111100
Im_AddFrame:
	Dc %000000000
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %011111110
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000000000
Im_DelFrame:
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %011111110
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %000000000
Im_Remove:
	Dc %000000000
	Dc %010000010
	Dc %001000100
	Dc %000101000
	Dc %000010000
	Dc %000101000
	Dc %001000100
	Dc %010000010
	Dc %000000000
Im_Draw:
	Dc %000000100
	Dc %000001110
	Dc %000011100
	Dc %000111000
	Dc %001110000
	Dc %011100000
	Dc %011011001
	Dc %100100110
	Dc %011000000
;Im_Box:
;	Dc %011111110
;	Dc %010000010
;	Dc %010000010
;	Dc %010000010
;	Dc %010000010
;	Dc %010000010
;	Dc %011111110
Im_New:
	Dc %011110000
	Dc %010011000
	Dc %010010100
	Dc %010011110
	Dc %010000010
	Dc %010000010
	Dc %010000010
	Dc %010000010
	Dc %011111110
Im_Pick:
	Dc %000000000
	Dc %011111000
	Dc %011110000
	Dc %011110000
	Dc %011111000
	Dc %010011100
	Dc %000001110
	Dc %000000100
	Dc %000000000
Im_Rnd:
	Dc %000000000
	Dc %000000000
	Dc %000100100
	Dc %010100110
	Dc %010101111
	Dc %101010110
	Dc %001000100
	Dc %000000000
	Dc %000000000
Im_Bounce:
Im_FlipX:
	Dc %000000000
	Dc %000000000
	Dc %001000100
	Dc %011000110
	Dc %111111111
	Dc %011000110
	Dc %001000100
	Dc %000000000
	Dc %000000000
Im_FlipY:
	Dc %000010000
	Dc %000111000
	Dc %001111100
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %001111100
	Dc %000111000
	Dc %000010000
;Im_FlipZ:
;	Dc %001000000
;	Dc %011100000
;	Dc %111110000
;	Dc %001000000
;	Dc %001000100
;	Dc %001000110
;	Dc %001111111
;	Dc %000000110
;	Dc %000000100
Im_Mouse:
	Dc %000011100
	Dc %000100010
	Dc %011111010
	Dc %010101001
	Dc %010101000
	Dc %011111000
	Dc %011111000
	Dc %011111000
	Dc %001110000
Im_Joystick:
	Dc %000100000
	Dc %001110000
	Dc %001110000
	Dc %000100000
	Dc %000100001
	Dc %000100010
	Dc %011111010
	Dc %111111100
	Dc %011111000
Im_Death:
	Dc %000000000
	Dc %000010000
	Dc %000010000
	Dc %001111100
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000000000
Im_Time:
	Dc %000000000
	Dc %000111000
	Dc %001000100
	Dc %010100010
	Dc %010011010
	Dc %010000010
	Dc %001000100
	Dc %000111000
	Dc %000000000
Im_Gravity:
	Dc %000000000
	Dc %001111100
	Dc %011000110
	Dc %011000000
	Dc %011011110
	Dc %011000110
	Dc %011000110
	Dc %001111110
	Dc %000000000
Im_Sine:
	Dc %000000000
	Dc %000000000
	Dc %011100000
	Dc %100010000
	Dc %100010001
	Dc %000010001
	Dc %000001110
	Dc %000000000
	Dc %000000000
;Im_Compass:
;	Dc %000010000
;	Dc %000111000
;	Dc %000010000
;	Dc %010010010
;	Dc %111111111
;	Dc %010010010
;	Dc %000010000
;	Dc %000111000
;	Dc %000010000
Im_Sum:
	Dc %000000000
	Dc %011111110
	Dc %001100010
	Dc %000110000
	Dc %000011000
	Dc %000110000
	Dc %001100010
	Dc %011111110
	Dc %000000000
Im_Reset:
	Dc %000000000
	Dc %000111000
	Dc %001000100
	Dc %001000100
	Dc %001000100
	Dc %001000100
	Dc %001000100
	Dc %000111000
	Dc %000000000
Im_Song:
	Dc %000000011
	Dc %000001101
	Dc %000110001
	Dc %000100001
	Dc %000100111
	Dc %000101111
	Dc %011100110
	Dc %111100000
	Dc %011000000
Im_Sound:
	Dc %000000000
	Dc %000011100
	Dc %000011110
	Dc %000010010
	Dc %000010000
	Dc %001110000
	Dc %011110000
	Dc %001100000
	Dc %000000000
Im_Font:
	Dc %000010000
	Dc %000010000
	Dc %000111000
	Dc %000111000
	Dc %001001100
	Dc %001111100
	Dc %010000110
	Dc %111001111
	Dc %000000000
Im_Keyboard:
	Dc %000001000
	Dc %001110000
	Dc %010000000
	Dc %111111111
	Dc %101010101
	Dc %110101011
	Dc %110000011
	Dc %111111111
	Dc %000000000
Im_Position:
	Dc %000000000
	Dc %000000100
	Dc %000000000
	Dc %000000100
	Dc %000000000
	Dc %000000100
	Dc %010101110
	Dc %000000100
	Dc %000000000
Im_Background:
	Dc %000000000
	Dc %000000000
	Dc %000000100
	Dc %000000100
	Dc %001001110
	Dc %011101110
	Dc %111011111
	Dc %110111111
	Dc %000000000
Im_Origo:
	Dc %000010000
	Dc %000010000
	Dc %000010000
	Dc %000000000
	Dc %111010111
	Dc %000000000
	Dc %000010000
	Dc %000010000
	Dc %000010000
Im_Path:
	Dc %000000000
	Dc %001000100
	Dc %111010001
	Dc %000000000
	Dc %000000001
	Dc %000000100
	Dc %000010000
	Dc %000000000
	Dc %000100000
Im_Scroll:
	Dc %000100000
	Dc %001100000
	Dc %011111110
	Dc %001100000
	Dc %000100100
	Dc %000000100
	Dc %001001110
	Dc %011101110
	Dc %111011111
;Im_First:
;	Dc %000000000
;	Dc %010000000
;	Dc %110000000
;	Dc %010000000
;	Dc %010110111
;	Dc %010100010
;	Dc %010010010
;	Dc %010110010
;	Dc %000000000
Im_Collision:
	Dc %000010000
	Dc %010010010
	Dc %001000100
	Dc %000000000
	Dc %110000011
	Dc %000000000
	Dc %001000100
	Dc %010010010
	Dc %000010000
Im_Palette:
	Dc %000000000
	Dc %001111110
	Dc %011010111
	Dc %101111111
	Dc %111110011
	Dc %101110010
	Dc %011011110
	Dc %001111100
	Dc %000000000
Im_Prefs:
	Dc %011111000
	Dc %001101100
	Dc %001101100
	Dc %001111000
	Dc %001100000
	Dc %001100000
	Dc %011110000
Im_Anim:
	Dc %111111111
	Dc %010101010
	Dc %111111111
	Dc %001000100
	Dc %001000100
	Dc %001000100
	Dc %111111111
	Dc %010101010
	Dc %111111111
Im_Level:
	Dc %000000000
	Dc %000111111
	Dc %001000010
	Dc %010000111
	Dc %111111010
	Dc %010000111
	Dc %111111010
	Dc %010000100
	Dc %111111000
Im_Record:
	Dc %000000000
	Dc %000000000
	Dc %000111000
	Dc %001111100
	Dc %001111100
	Dc %001111100
	Dc %000111000
	Dc %000000000
	Dc %000000000
Im_PlayScr:
	Dc %000000000
	Dc %111111111
	Dc %100100001
	Dc %100110001
	Dc %100111001
	Dc %100110001
	Dc %100100001
	Dc %111111111
	Dc %000000000
;Im_Behind:
;	Dc %000000000
;	Dc %011111000
;	Dc %011111000
;	Dc %011111110
;	Dc %011100010
;	Dc %011100010
;	Dc %000100010
;	Dc %000111110
;	Dc %000000000
Im_Mask:
	Dc %000000000
	Dc %000000000
	Dc %000000001
	Dc %000000011
	Dc %000111111
	Dc %011111111
	Dc %111111111
	Dc %000000000
	Dc %000000000
Im_Graphics:
	Dc %000000000
	Dc %000000000
	Dc %000000001
	Dc %000000011
	Dc %000111101
	Dc %011000001
	Dc %111111111
	Dc %000000000
	Dc %000000000
Im_Save:
	Dc %000111000
	Dc %000010000
	Dc %000000000
	Dc %011111110
	Dc %010000010
	Dc %010000010
	Dc %011111110
	Dc %011010110
	Dc %001111110
Im_Equal:
	Dc %000000000
	Dc %000000000
	Dc %000000000
	Dc %011111110
	Dc %000000000
	Dc %011111110
	Dc %000000000
	Dc %000000000
	Dc %000000000
Im_Calculate:
	Dc %000000000
	Dc %000000000
	Dc %110000110
	Dc %001010001
	Dc %010111010
	Dc %100010100
	Dc %111000111
	Dc %000000000
	Dc %000000000
Im_Trim:
	Dc %000000000
	Dc %000000000
	Dc %000000001
	Dc %000000010
	Dc %000101011
	Dc %010111110
	Dc %101010101
	Dc %000000000
	Dc %000000000
Im_Replay:
	Dc %000000000
	Dc %011111100
	Dc %011000110
	Dc %011000110
	Dc %011111100
	Dc %011011000
	Dc %011001100
	Dc %011000110
	Dc %000000000
;Im_Copy:
;	Dc %000000000
;	Dc %001111100
;	Dc %011000110
;	Dc %000000110
;	Dc %000011100
;	Dc %001110000
;	Dc %011000000
;	Dc %011111110
;	Dc %000000000
;Im_ObjNone:
;	Dc %000000000
;	Dc %000000000
;	Dc %000000000
;	Dc %000111000
;	Dc %000101000
;	Dc %000111000
;	Dc %000000000
;	Dc %000000000
;	Dc %000000000
;Im_ObjFree:
;	Dc %000000000
;	Dc %000111000
;	Dc %001000100
;	Dc %010111010
;	Dc %010101010
;	Dc %010111010
;	Dc %001000100
;	Dc %000111000
;	Dc %000000000
;Im_ObjFixed:
;	Dc %000000000
;	Dc %011111110
;	Dc %010000010
;	Dc %010111010
;	Dc %010101010
;	Dc %010111010
;	Dc %010000010
;	Dc %011111110
;	Dc %000000000
;Im_IQ:
;	Dc %000000000
;	Dc %000000000
;	Dc %111001110
;	Dc %010010001
;	Dc %010010101
;	Dc %010010010
;	Dc %111001101
;	Dc %000000000
;	Dc %000000000
Im_Formation:
	Dc %000000000
	Dc %000000100
	Dc %000001100
	Dc %000100100
	Dc %001100000
	Dc %000100100
	Dc %000001100
	Dc %000000100
	Dc %000000000
;Im_NotePad:
;	Dc %111111111
;	Dc %100000001
;	Dc %101011101
;	Dc %100000001
;	Dc %101100101
;	Dc %100001101
;	Dc %111111111
;	Dc %000110000
;	Dc %001100000
Im_Volume:
	Dc %000000000
	Dc %000000000
	Dc %000000001
	Dc %000000111
	Dc %000011111
	Dc %001111111
	Dc %111111111
	Dc %000000000
	Dc %000000000
Im_ToTop:
	Dc %000010000
	Dc %000111000
	Dc %001111100
	Dc %000000000
	Dc %001111100
	Dc %000000000
	Dc %001111100
	Dc %000000000
	Dc %001111100
Im_ToBottom:
	Dc %001111100
	Dc %000000000
	Dc %001111100
	Dc %000000000
	Dc %001111100
	Dc %000000000
	Dc %001111100
	Dc %000111000
	Dc %000010000
Im_TopWard:
	Dc %001111100
	Dc %000000000
	Dc %001111100
	Dc %000000000
	Dc %000010000
	Dc %000111000
	Dc %001111100
	Dc %000000000
	Dc %001111100
Im_BottomWard:
	Dc %001111100
	Dc %000000000
	Dc %001111100
	Dc %000111000
	Dc %000010000
	Dc %000000000
	Dc %001111100
	Dc %000000000
	Dc %001111100
Im_Sample:
	Dc %010000000
	Dc %010010000
	Dc %010010100
	Dc %110110100
	Dc %111111111
	Dc %101011010
	Dc %101001000
	Dc %100000000
	Dc %100000000
Im_Fine:
	Dc %000000000
	Dc %000000000
	Dc %100000001
	Dc %110010011
	Dc %111010111
	Dc %110010011
	Dc %100000001
	Dc %000000000
	Dc %000000000
Im_Module:
	Dc %111111111
	Dc %100000001
	Dc %100001101
	Dc %100110101
	Dc %100101101
	Dc %101101101
	Dc %101100001
	Dc %100000001
	Dc %111111111
Im_Weapon:
	Dc %000000000
	Dc %010000001
	Dc %111111110
	Dc %111111111
	Dc %001001111
	Dc %000111111
	Dc %000000111
	Dc %000000010
	Dc %000000000
Im_Log:
	Dc %000100000
	Dc %001100000
	Dc %011111110
	Dc %111100010
	Dc %011101010
	Dc %111100010
	Dc %011101010
	Dc %111000010
	Dc %011111110
Im_GameScr:
	Dc %000000000
	Dc %111111111
	Dc %100001001
	Dc %101100101
	Dc %100001101
	Dc %101000011
	Dc %111110111
	Dc %111111111
	Dc %000000000
Im_Snapshot:
	Dc %000000000
	Dc %010111010
	Dc %111111111
	Dc %111000111
	Dc %110110011
	Dc %110100011
	Dc %111000111
	Dc %111111111
	Dc %000000000
;Im_Clear:
;	Dc %000000000
;	Dc %000000000
;	Dc %011010000
;	Dc %100010101
;	Dc %100010110
;	Dc %100010100
;	Dc %011010100
;	Dc %000000000
;	Dc %000000000
Im_LoopStart:
	Dc %011000000
	Dc %100000000
	Dc %100010000
	Dc %100011000
	Dc %011111100
	Dc %000011000
	Dc %000010000
Im_LoopEnd:
	Dc %001000000
	Dc %011000000
	Dc %111111000
	Dc %011000100
	Dc %001000100
	Dc %000000100
	Dc %000011000
Im_StartPoint:
	Dc %000000000
	Dc %100100000
	Dc %101100000
	Dc %111111100
	Dc %101100000
	Dc %100100000
	Dc %000000000
Im_EndPoint:
	Dc %000000000
	Dc %000100100
	Dc %000110100
	Dc %111111100
	Dc %000110100
	Dc %000100100
	Dc %000000000
Im_Octave:
	Dc %000000000
	Dc %000111100
	Dc %001100010
	Dc %001110010
	Dc %000111100
	Dc %001001110
	Dc %001000110
	Dc %000111100
	Dc %000000000
Im_Grid:
	Dc %010010010
	Dc %111111111
	Dc %010010010
	Dc %010010010
	Dc %111111111
	Dc %010010010
	Dc %010010010
	Dc %111111111
	Dc %010010010
Im_Player:
	Dc %000010000
	Dc %000111000
	Dc %000111000
	Dc %000010000
	Dc %000111000
	Dc %001010100
	Dc %000010000
	Dc %000101000
	Dc %001000100
Im_All:
	Dc %000000000
	Dc %111010010
	Dc %101010010
	Dc %101010010
	Dc %111010010
	Dc %101010010
	Dc %101010010
	Dc %101011011
	Dc %000000000
Im_Release:
	Dc %000000000
	Dc %000000001
	Dc %001000011
	Dc %011011111
	Dc %111000000
	Dc %011000001
	Dc %001000011
	Dc %000011111
	Dc %000000000
Im_Score:
	Dc %000000000
	Dc %011000110
	Dc %100101001
	Dc %100001000
	Dc %011001000
	Dc %000101000
	Dc %100101001
	Dc %011000110
	Dc %000000000
Im_Effect:
	Dc %000000000
	Dc %111101001
	Dc %100001001
	Dc %100001001
	Dc %111000110
	Dc %100001001
	Dc %100001001
	Dc %100001001
	Dc %000000000
Im_Text:
	Dc %000000000
	Dc %111110000
	Dc %001000000
	Dc %001010001
	Dc %001001010
	Dc %001000100
	Dc %001001010
	Dc %001010001
	Dc %000000000
Im_Piece:
	Dc %000111000
	Dc %001111100
	Dc %000111000
	Dc %111111111
	Dc %101111101
	Dc %000111000
	Dc %000111000
	Dc %101111101
	Dc %111111111
Im_Condition:
	Dc %000000000
	Dc %011101111
	Dc %001001000
	Dc %001001000
	Dc %001001110
	Dc %001001000
	Dc %001001000
	Dc %011101000
	Dc %000000000
Im_PathList:
	Dc %111000110
	Dc %100101001
	Dc %111001111
	Dc %100001001
	Dc %000000000
	Dc %111001001
	Dc %010001111
	Dc %010001001
	Dc %010001001
Im_PrevBuffer:
	Dc %000000000
	Dc %000000010
	Dc %011000110
	Dc %000001110
	Dc %111100110
	Dc %000000110
	Dc %011000110
	Dc %000001111
	Dc %000000000
Im_Cut:
	Dc %000000000
	Dc %100000110
	Dc %011001001
	Dc %001111110
	Dc %000101000
	Dc %001111110
	Dc %011001001
	Dc %100000110
	Dc %000000000
Im_Clipboard:
	Dc %000111000
	Dc %111111111
	Dc %110111011
	Dc %110000011
	Dc %110100011
	Dc %110111011
	Dc %110000011
	Dc %111111111
	Dc %111111111
Im_Paste:
	Dc %000000100
	Dc %000001110
	Dc %000010111
	Dc %000100010
	Dc %001010100
	Dc %010101000
	Dc %011010000
	Dc %101100000
	Dc %110000000
Im_Pixel:
	Dc %100000000
Im_Square1:
	Dc %110000000
	Dc %110000000
Im_Square2:
	Dc %111000000
	Dc %111000000
	Dc %111000000
Im_Dot1:
	Dc %010000000
	Dc %111000000
	Dc %010000000
Im_Dot2:
	Dc %011000000
	Dc %111100000
	Dc %111100000
	Dc %011000000
Im_Dot3:
	Dc %011100000
	Dc %111110000
	Dc %111110000
	Dc %111110000
	Dc %011100000
;Im_Exchange:
;	Dc %001111100
;	Dc %010000010
;	Dc %010000010
;	Dc %111000111
;	Dc %010000010
;	Dc %000000000
;	Dc %111101111
;	Dc %100101111
;	Dc %111101111
;Im_Spread:
;	Dc %111111111
;	Dc %111011001
;	Dc %110100101
;	Dc %111110001
;	Dc %111001001
;	Dc %111110001
;	Dc %110100101
;	Dc %111011001
;	Dc %111111111
Im_Delta:
	Dc %000100000
	Dc %001010000
	Dc %010001000
	Dc %111111100
	Dc %000000000
*=======================================================================*
* Routines & Data which can be anywhere!				*
*=======================================================================*
Info_Info1:	Lea	Info_Info1DL(pc),a0
		Move.l	a0,II_Adr
		Bra.b	Info_InfoComm
*---------------
Info_Info2:	Lea	Info_Info2DL(pc),a0
		Move.l	a0,II_Adr
		Bra.b	Info_InfoComm
*---------------
Info_Info3:	Lea	Info_Info3DL(pc),a0
		Move.l	a0,II_Adr
		Bra.w	Info_InfoComm
*---------------
Info_InfoComm:	Lea	InfoLay,a5	;###
		Move.l	HitGd,a4	;###
		Btst	#0,4(a4)
		Bne.b	II1_Ok
		Bset	#0,4(a4)
		Moveq.l	#3,d7
		Jsr	Draw_Some
	II1_Ok:	Lea	GInfo_Jump(pc),a4
		Move.l	II_Adr(pc),2(a4)
		Jmp	Draw_All	;###
	II_Adr:	Dc.l	0
*---------------
DrawList_Info:	Dc	'JS'
		Dc.l	TitleBar_DL
		Dc	'TX',016,010,-01,8
		Dc.l	Information8T

		Dc	'BX',000,-13,-01,-01
GInfo_Info1:	Dc	'GD'
		Dc.l	$02010700,Info_Excl,Info_Info1
		Dc	'BX',003,-11,055,-03
		Dc	'TX',012,-04,-01,5
		Dc.l	Info1T
GInfo_Info2:	Dc	'GD'
		Dc.l	$02010600,Info_Excl,Info_Info2
		Dc	'BX',060,-11,-61,-03
		Dc	'TX',069,-04,-01,5
		Dc.l	Info2T
GInfo_Info3:	Dc	'GD'
		Dc.l	$02010600,Info_Excl,Info_Info3
		Dc	'BX',-56,-11,-04,-03
		Dc	'TX',-51,-04,-01,5
		Dc.l	Info3T

GInfo_Jump:	Dc	'JP'
		Dc.l	Info_Info1DL
*---------------
Info_Info1DL:	Dc	'BX',000,011,-01,-14
		Dc	'TX',026,025,-01,8
		Dc.l	InfoT1A
		Dc	'TX',063,035,-01,5
		Dc.l	InfoT1B
		Dc	'TX',003,045,-01,8
		Dc.l	InfoT1C
		Dc	'TX',061,055,-01,5
		Dc.l	InfoT1D
		Dc	'TX',021,065,-01,8
		Dc.l	InfoT1E
		Dc	'TX',044,075,-01,5
		Dc.l	InfoT1F
		Dc	'TX',028,085,-01,8
		Dc.l	InfoT1G
		Dc	'XX'

InfoT1A:	Dc.b	'Arcade Factory I',0
InfoT1B:	Dc.b	'CODING BY',0
InfoT1C:	Dc.b	'Richard Glenn Nielsen',0
InfoT1D:	Dc.b	'SUPPORT BY',0
InfoT1E:	Dc.b	'Freddy Olav Tveit',0
InfoT1F:	Dc.b	'COPYRIGHT 1994 BY',0
InfoT1G:	Dc.b	'Digital Fiction',0
*---------------
Info_Info2DL:	Dc	'BX',000,011,-01,-14
		Dc	'TX',026,025,-01,8
		Dc.l	InfoT2A
		Dc	'TX',063,035,-01,5
		Dc.l	InfoT2B
		Dc	'TX',005,045,-01,8
		Dc.l	InfoT2C
		Dc	'TX',061,055,-01,5
		Dc.l	InfoT2D
		Dc	'TX',021,065,-01,8
		Dc.l	InfoT2E
		Dc	'TX',044,075,-01,5
		Dc.l	InfoT2F
		Dc	'TX',028,085,-01,8
		Dc.l	InfoT2G
		Dc	'XX'

InfoT2A:	Dc.b	'More Information:',0
InfoT2B:	Dc.b	'VERSION',0
InfoT2C:	Dc.b	'Version 1 Update 0',0
InfoT2D:	Dc.b	'SERIAL NUMBER',0
InfoT2E:	Dc.b	'Serial #2E7A104B',0
InfoT2F:	Dc.b	'RELEASE DATE',0
InfoT2G:	Dc.b	'25-Oct-1994',0
		Even
*---------------
Info_Info3DL:	Dc	'BX',000,011,-01,-14
		Dc	'TX',026,025,-01,8
		Dc.l	InfoT3A
		Dc	'TX',063,035,-01,5
		Dc.l	InfoT3B
		Dc	'TX',005,045,-01,8
		Dc.l	InfoT3C
		Dc	'TX',061,055,-01,5
		Dc.l	InfoT3D
		Dc	'TX',021,065,-01,8
		Dc.l	InfoT3E
		Dc	'TX',044,075,-01,5
		Dc.l	InfoT3F
		Dc	'TX',028,085,-01,8
		Dc.l	InfoT3G
		Dc	'XX'

InfoT3A:	Dc.b	'Nothing more to say:',0
InfoT3B:	Dc.b	'WERDGDG',0
InfoT3C:	Dc.b	'Snirruksnurk!',0
InfoT3D:	Dc.b	'SABLATANN',0
InfoT3E:	Dc.b	'Milternistisk tranfentark.',0
InfoT3F:	Dc.b	'BROSS',0
InfoT3G:	Dc.b	'Truppknittfnelltokk',0
		Even
;Address,copyright notice,thanks,tech support:reg.users only:phone/adr
*---------------
Info1T:		Dc.b	'CREDITS',0
Info2T:		Dc.b	'VERSION',0
Info3T:		Dc.b	'COPYRIGHT',0
		Even
Info_Excl:	Dc.l	GInfo_Info1
		Dc.l	GInfo_Info2
		Dc.l	GInfo_Info3
		Dc.l	0
*---------------
TitleBar_DL:	Dc	'GD'
		Dc.l	$020100f1,0,0
		Dc	'BX',000,000,012,010
		Dc	'IM',003,002,7,Im_Close-Im
		Dc	'GD'
		Dc.l	$020000f2,0,0
		Dc	'BX',013,000,-14,010
		Dc	'GD'
		Dc.l	$020100f3,0,0
		Dc	'BX',-13,000,-01,010
		Dc	'IM',-11,002,7,Im_Depth-Im
		Dc	'RT'
*-----------------------------------------------------------------------*
		End
*=======================================================================*
*			    W O R K L I S T				*
*=======================================================================*
Picture:	  Place Zoom
Piece:		  New Piece (Remove/Finish)
		- Prop X,Y
Draw:		- Remove Box,Line,Brush. Insert Undo.
Background:	  8-Way Scroll
		  Fix Slow Bug
Animation:	- Prop X,Y
		  Pick Piece Bug (1200)
Song:		  Tempo
Module:		  Choose to load Module/Sample
Sample:		  Play-Bug
		  Cut,Copy,Paste,Zoom,ShowAll,Prop (Remove/Finish)
		  Fix Graph Bugs
Sound:		  Fix Graph Bugs
		  Rate
		  Loop Start,End and Start,End Point
		  Finish Game Sound Routine
Palette:	  Raster/Cycle/Fixed
Game:		  Window
		- Play
		  Split up Editor/Game
		  TrackDisk routines
		  Save New Game w/PathName
		- Collision Detection
		  New
Screen:		  Start Level (GameScreen)
		- Play
		  Select Palette
		  Depth
		  Place Game Screen
		  Add Move
Scroll:		  Window
		- Mapsize
		- Speed
		  Add,Delete Space
Inventory:	- Check PowerUp Limits
Weapon:		  Speed & Angle or Fine Adjust
		  Aiming
		- End Cause: Duration/HitBackground/HitObject
		  Graphical Edit
Selector:	  Improve Sort Routine
		  Make GameDisk
Snapshot:	  Save IFF
Movement:	- Line: Speed & Angle
		- Sine: Graphical Edit
		- Freehand: Smoothing, Move point
		  Anim/Piece
		  Controller
		  Position
		  Modulation
		  Sum
Font:		  Test Font
Object:		  HitMask Check, Color
		- Sine Bug
		  Hit Event
		  Position Event
		  Link Event
		  Death Event
Wave:		- Graphical Edit
Player:		- Window
		- Input
		- Variables
Input:		- Keyboard
		- Joystick
		- Mouse
		- Simultaneously
		- Sequence
Level:		  Change Scroll: Limits,Directions,Speed,LimEnd,Inertia,Accel
		  Change Background
		  Change ScoreData: Lives,Score
		  Release Objects: ScrollRel.
		  Position
		  If
		- Condition info in EventList
		  End Of Level
		  Change Palette
General:	  Quit: Clear-Bug
		- Delete,Remove updates windows
		- Key functions
		- Help
		  Quit: Unsaved:Save/Don't/Cancel
		- Get_Xxxx_LAdr point to 0 if #>Len.
		  Select Path on unsaved Units.
		  StrGd scroll
		  Multitasking
		  Titlebar drag bug.
*=======================================================================*
