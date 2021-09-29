
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	93013103          	ld	sp,-1744(sp) # 80008930 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	eec78793          	addi	a5,a5,-276 # 80005f50 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	6b6080e7          	jalr	1718(ra) # 800027d4 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	9be080e7          	jalr	-1602(ra) # 80001b70 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	204080e7          	jalr	516(ra) # 800023c6 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	580080e7          	jalr	1408(ra) # 8000277e <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	54c080e7          	jalr	1356(ra) # 8000282a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	120080e7          	jalr	288(ra) # 80002552 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	6e478793          	addi	a5,a5,1764 # 80021b48 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	cd4080e7          	jalr	-812(ra) # 80002552 <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	abc080e7          	jalr	-1348(ra) # 800023c6 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	ff8080e7          	jalr	-8(ra) # 80001b54 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	fc6080e7          	jalr	-58(ra) # 80001b54 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	fba080e7          	jalr	-70(ra) # 80001b54 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	fa2080e7          	jalr	-94(ra) # 80001b54 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	f62080e7          	jalr	-158(ra) # 80001b54 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	f36080e7          	jalr	-202(ra) # 80001b54 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
    if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	cd0080e7          	jalr	-816(ra) # 80001b44 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
    if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	cb4080e7          	jalr	-844(ra) # 80001b44 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	b00080e7          	jalr	-1280(ra) # 800029b2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	0d6080e7          	jalr	214(ra) # 80005f90 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	1e6080e7          	jalr	486(ra) # 800020a8 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	b56080e7          	jalr	-1194(ra) # 80001a78 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	a60080e7          	jalr	-1440(ra) # 8000298a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	a80080e7          	jalr	-1408(ra) # 800029b2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	040080e7          	jalr	64(ra) # 80005f7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	04e080e7          	jalr	78(ra) # 80005f90 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	224080e7          	jalr	548(ra) # 8000316e <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	8b4080e7          	jalr	-1868(ra) # 80003806 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	85e080e7          	jalr	-1954(ra) # 800047b8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	150080e7          	jalr	336(ra) # 800060b2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	eec080e7          	jalr	-276(ra) # 80001e56 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	7d6080e7          	jalr	2006(ra) # 800019e2 <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b2:	00b67d63          	bgeu	a2,a1,800013cc <uvmdealloc+0x26>
    800013b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b8:	6785                	lui	a5,0x1
    800013ba:	17fd                	addi	a5,a5,-1
    800013bc:	00f60733          	add	a4,a2,a5
    800013c0:	767d                	lui	a2,0xfffff
    800013c2:	8f71                	and	a4,a4,a2
    800013c4:	97ae                	add	a5,a5,a1
    800013c6:	8ff1                	and	a5,a5,a2
    800013c8:	00f76863          	bltu	a4,a5,800013d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d8:	8f99                	sub	a5,a5,a4
    800013da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013dc:	4685                	li	a3,1
    800013de:	0007861b          	sext.w	a2,a5
    800013e2:	85ba                	mv	a1,a4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	e5e080e7          	jalr	-418(ra) # 80001242 <uvmunmap>
    800013ec:	b7c5                	j	800013cc <uvmdealloc+0x26>

00000000800013ee <uvmalloc>:
  if(newsz < oldsz)
    800013ee:	0ab66163          	bltu	a2,a1,80001490 <uvmalloc+0xa2>
{
    800013f2:	7139                	addi	sp,sp,-64
    800013f4:	fc06                	sd	ra,56(sp)
    800013f6:	f822                	sd	s0,48(sp)
    800013f8:	f426                	sd	s1,40(sp)
    800013fa:	f04a                	sd	s2,32(sp)
    800013fc:	ec4e                	sd	s3,24(sp)
    800013fe:	e852                	sd	s4,16(sp)
    80001400:	e456                	sd	s5,8(sp)
    80001402:	0080                	addi	s0,sp,64
    80001404:	8aaa                	mv	s5,a0
    80001406:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001408:	6985                	lui	s3,0x1
    8000140a:	19fd                	addi	s3,s3,-1
    8000140c:	95ce                	add	a1,a1,s3
    8000140e:	79fd                	lui	s3,0xfffff
    80001410:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001414:	08c9f063          	bgeu	s3,a2,80001494 <uvmalloc+0xa6>
    80001418:	894e                	mv	s2,s3
    mem = kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	6b8080e7          	jalr	1720(ra) # 80000ad2 <kalloc>
    80001422:	84aa                	mv	s1,a0
    if(mem == 0){
    80001424:	c51d                	beqz	a0,80001452 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	894080e7          	jalr	-1900(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001432:	4779                	li	a4,30
    80001434:	86a6                	mv	a3,s1
    80001436:	6605                	lui	a2,0x1
    80001438:	85ca                	mv	a1,s2
    8000143a:	8556                	mv	a0,s5
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	c52080e7          	jalr	-942(ra) # 8000108e <mappages>
    80001444:	e905                	bnez	a0,80001474 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	6785                	lui	a5,0x1
    80001448:	993e                	add	s2,s2,a5
    8000144a:	fd4968e3          	bltu	s2,s4,8000141a <uvmalloc+0x2c>
  return newsz;
    8000144e:	8552                	mv	a0,s4
    80001450:	a809                	j	80001462 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001452:	864e                	mv	a2,s3
    80001454:	85ca                	mv	a1,s2
    80001456:	8556                	mv	a0,s5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f4e080e7          	jalr	-178(ra) # 800013a6 <uvmdealloc>
      return 0;
    80001460:	4501                	li	a0,0
}
    80001462:	70e2                	ld	ra,56(sp)
    80001464:	7442                	ld	s0,48(sp)
    80001466:	74a2                	ld	s1,40(sp)
    80001468:	7902                	ld	s2,32(sp)
    8000146a:	69e2                	ld	s3,24(sp)
    8000146c:	6a42                	ld	s4,16(sp)
    8000146e:	6aa2                	ld	s5,8(sp)
    80001470:	6121                	addi	sp,sp,64
    80001472:	8082                	ret
      kfree(mem);
    80001474:	8526                	mv	a0,s1
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	560080e7          	jalr	1376(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000147e:	864e                	mv	a2,s3
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f22080e7          	jalr	-222(ra) # 800013a6 <uvmdealloc>
      return 0;
    8000148c:	4501                	li	a0,0
    8000148e:	bfd1                	j	80001462 <uvmalloc+0x74>
    return oldsz;
    80001490:	852e                	mv	a0,a1
}
    80001492:	8082                	ret
  return newsz;
    80001494:	8532                	mv	a0,a2
    80001496:	b7f1                	j	80001462 <uvmalloc+0x74>

0000000080001498 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
    800014a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014aa:	84aa                	mv	s1,a0
    800014ac:	6905                	lui	s2,0x1
    800014ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b0:	4985                	li	s3,1
    800014b2:	a821                	j	800014ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b6:	0532                	slli	a0,a0,0xc
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	fe0080e7          	jalr	-32(ra) # 80001498 <freewalk>
      pagetable[i] = 0;
    800014c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014c4:	04a1                	addi	s1,s1,8
    800014c6:	03248163          	beq	s1,s2,800014e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014cc:	00f57793          	andi	a5,a0,15
    800014d0:	ff3782e3          	beq	a5,s3,800014b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014d4:	8905                	andi	a0,a0,1
    800014d6:	d57d                	beqz	a0,800014c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c8850513          	addi	a0,a0,-888 # 80008160 <digits+0x120>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014e8:	8552                	mv	a0,s4
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4ec080e7          	jalr	1260(ra) # 800009d6 <kfree>
}
    800014f2:	70a2                	ld	ra,40(sp)
    800014f4:	7402                	ld	s0,32(sp)
    800014f6:	64e2                	ld	s1,24(sp)
    800014f8:	6942                	ld	s2,16(sp)
    800014fa:	69a2                	ld	s3,8(sp)
    800014fc:	6a02                	ld	s4,0(sp)
    800014fe:	6145                	addi	sp,sp,48
    80001500:	8082                	ret

0000000080001502 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
    8000150c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000150e:	e999                	bnez	a1,80001524 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001510:	8526                	mv	a0,s1
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f86080e7          	jalr	-122(ra) # 80001498 <freewalk>
}
    8000151a:	60e2                	ld	ra,24(sp)
    8000151c:	6442                	ld	s0,16(sp)
    8000151e:	64a2                	ld	s1,8(sp)
    80001520:	6105                	addi	sp,sp,32
    80001522:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001524:	6605                	lui	a2,0x1
    80001526:	167d                	addi	a2,a2,-1
    80001528:	962e                	add	a2,a2,a1
    8000152a:	4685                	li	a3,1
    8000152c:	8231                	srli	a2,a2,0xc
    8000152e:	4581                	li	a1,0
    80001530:	00000097          	auipc	ra,0x0
    80001534:	d12080e7          	jalr	-750(ra) # 80001242 <uvmunmap>
    80001538:	bfe1                	j	80001510 <uvmfree+0xe>

000000008000153a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000153a:	c679                	beqz	a2,80001608 <uvmcopy+0xce>
{
    8000153c:	715d                	addi	sp,sp,-80
    8000153e:	e486                	sd	ra,72(sp)
    80001540:	e0a2                	sd	s0,64(sp)
    80001542:	fc26                	sd	s1,56(sp)
    80001544:	f84a                	sd	s2,48(sp)
    80001546:	f44e                	sd	s3,40(sp)
    80001548:	f052                	sd	s4,32(sp)
    8000154a:	ec56                	sd	s5,24(sp)
    8000154c:	e85a                	sd	s6,16(sp)
    8000154e:	e45e                	sd	s7,8(sp)
    80001550:	0880                	addi	s0,sp,80
    80001552:	8b2a                	mv	s6,a0
    80001554:	8aae                	mv	s5,a1
    80001556:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001558:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000155a:	4601                	li	a2,0
    8000155c:	85ce                	mv	a1,s3
    8000155e:	855a                	mv	a0,s6
    80001560:	00000097          	auipc	ra,0x0
    80001564:	a46080e7          	jalr	-1466(ra) # 80000fa6 <walk>
    80001568:	c531                	beqz	a0,800015b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000156a:	6118                	ld	a4,0(a0)
    8000156c:	00177793          	andi	a5,a4,1
    80001570:	cbb1                	beqz	a5,800015c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001572:	00a75593          	srli	a1,a4,0xa
    80001576:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000157a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	554080e7          	jalr	1364(ra) # 80000ad2 <kalloc>
    80001586:	892a                	mv	s2,a0
    80001588:	c939                	beqz	a0,800015de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	85de                	mv	a1,s7
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	78c080e7          	jalr	1932(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001596:	8726                	mv	a4,s1
    80001598:	86ca                	mv	a3,s2
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	aee080e7          	jalr	-1298(ra) # 8000108e <mappages>
    800015a8:	e515                	bnez	a0,800015d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	99be                	add	s3,s3,a5
    800015ae:	fb49e6e3          	bltu	s3,s4,8000155a <uvmcopy+0x20>
    800015b2:	a081                	j	800015f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bbc50513          	addi	a0,a0,-1092 # 80008170 <digits+0x130>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bcc50513          	addi	a0,a0,-1076 # 80008190 <digits+0x150>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      kfree(mem);
    800015d4:	854a                	mv	a0,s2
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	400080e7          	jalr	1024(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015de:	4685                	li	a3,1
    800015e0:	00c9d613          	srli	a2,s3,0xc
    800015e4:	4581                	li	a1,0
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	c5a080e7          	jalr	-934(ra) # 80001242 <uvmunmap>
  return -1;
    800015f0:	557d                	li	a0,-1
}
    800015f2:	60a6                	ld	ra,72(sp)
    800015f4:	6406                	ld	s0,64(sp)
    800015f6:	74e2                	ld	s1,56(sp)
    800015f8:	7942                	ld	s2,48(sp)
    800015fa:	79a2                	ld	s3,40(sp)
    800015fc:	7a02                	ld	s4,32(sp)
    800015fe:	6ae2                	ld	s5,24(sp)
    80001600:	6b42                	ld	s6,16(sp)
    80001602:	6ba2                	ld	s7,8(sp)
    80001604:	6161                	addi	sp,sp,80
    80001606:	8082                	ret
  return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	8082                	ret

000000008000160c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160c:	1141                	addi	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001614:	4601                	li	a2,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	990080e7          	jalr	-1648(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000161e:	c901                	beqz	a0,8000162e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001620:	611c                	ld	a5,0(a0)
    80001622:	9bbd                	andi	a5,a5,-17
    80001624:	e11c                	sd	a5,0(a0)
}
    80001626:	60a2                	ld	ra,8(sp)
    80001628:	6402                	ld	s0,0(sp)
    8000162a:	0141                	addi	sp,sp,16
    8000162c:	8082                	ret
    panic("uvmclear");
    8000162e:	00007517          	auipc	a0,0x7
    80001632:	b8250513          	addi	a0,a0,-1150 # 800081b0 <digits+0x170>
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>

000000008000163e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163e:	c6bd                	beqz	a3,800016ac <copyout+0x6e>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	e062                	sd	s8,0(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8c2e                	mv	s8,a1
    8000165c:	8a32                	mv	s4,a2
    8000165e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001660:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001662:	6a85                	lui	s5,0x1
    80001664:	a015                	j	80001688 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001666:	9562                	add	a0,a0,s8
    80001668:	0004861b          	sext.w	a2,s1
    8000166c:	85d2                	mv	a1,s4
    8000166e:	41250533          	sub	a0,a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>

    len -= n;
    8000167a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001680:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001684:	02098263          	beqz	s3,800016a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001688:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168c:	85ca                	mv	a1,s2
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	9bc080e7          	jalr	-1604(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001698:	cd01                	beqz	a0,800016b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000169a:	418904b3          	sub	s1,s2,s8
    8000169e:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a0:	fc99f3e3          	bgeu	s3,s1,80001666 <copyout+0x28>
    800016a4:	84ce                	mv	s1,s3
    800016a6:	b7c1                	j	80001666 <copyout+0x28>
  }
  return 0;
    800016a8:	4501                	li	a0,0
    800016aa:	a021                	j	800016b2 <copyout+0x74>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
}
    800016b2:	60a6                	ld	ra,72(sp)
    800016b4:	6406                	ld	s0,64(sp)
    800016b6:	74e2                	ld	s1,56(sp)
    800016b8:	7942                	ld	s2,48(sp)
    800016ba:	79a2                	ld	s3,40(sp)
    800016bc:	7a02                	ld	s4,32(sp)
    800016be:	6ae2                	ld	s5,24(sp)
    800016c0:	6b42                	ld	s6,16(sp)
    800016c2:	6ba2                	ld	s7,8(sp)
    800016c4:	6c02                	ld	s8,0(sp)
    800016c6:	6161                	addi	sp,sp,80
    800016c8:	8082                	ret

00000000800016ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	caa5                	beqz	a3,8000173a <copyin+0x70>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	8c32                	mv	s8,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a01d                	j	80001716 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f2:	018505b3          	add	a1,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	412585b3          	sub	a1,a1,s2
    800016fe:	8552                	mv	a0,s4
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	61a080e7          	jalr	1562(ra) # 80000d1a <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000170c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	92e080e7          	jalr	-1746(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f2e3          	bgeu	s3,s1,800016f2 <copyin+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	bf7d                	j	800016f2 <copyin+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyin+0x76>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001758:	c6c5                	beqz	a3,80001800 <copyinstr+0xa8>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8a2a                	mv	s4,a0
    80001772:	8b2e                	mv	s6,a1
    80001774:	8bb2                	mv	s7,a2
    80001776:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6985                	lui	s3,0x1
    8000177c:	a035                	j	800017a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001782:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001784:	0017b793          	seqz	a5,a5
    80001788:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a6:	c8a9                	beqz	s1,800017f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	8552                	mv	a0,s4
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	89c080e7          	jalr	-1892(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017b8:	c131                	beqz	a0,800017fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ba:	41790833          	sub	a6,s2,s7
    800017be:	984e                	add	a6,a6,s3
    if(n > max)
    800017c0:	0104f363          	bgeu	s1,a6,800017c6 <copyinstr+0x6e>
    800017c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c6:	955e                	add	a0,a0,s7
    800017c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017cc:	fc080be3          	beqz	a6,800017a2 <copyinstr+0x4a>
    800017d0:	985a                	add	a6,a6,s6
    800017d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d4:	41650633          	sub	a2,a0,s6
    800017d8:	14fd                	addi	s1,s1,-1
    800017da:	9b26                	add	s6,s6,s1
    800017dc:	00f60733          	add	a4,a2,a5
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017e4:	df49                	beqz	a4,8000177e <copyinstr+0x26>
        *dst = *p;
    800017e6:	00e78023          	sb	a4,0(a5)
      --max;
    800017ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f0:	ff0796e3          	bne	a5,a6,800017dc <copyinstr+0x84>
      dst++;
    800017f4:	8b42                	mv	s6,a6
    800017f6:	b775                	j	800017a2 <copyinstr+0x4a>
    800017f8:	4781                	li	a5,0
    800017fa:	b769                	j	80001784 <copyinstr+0x2c>
      return -1;
    800017fc:	557d                	li	a0,-1
    800017fe:	b779                	j	8000178c <copyinstr+0x34>
  int got_null = 0;
    80001800:	4781                	li	a5,0
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
}
    8000180a:	8082                	ret

000000008000180c <enqueue>:
/*
 *@Author: Leyuan & Lee 
  Implement enqueue for the mlq to add process into the mlq
*/
void enqueue(struct proc *p)
{
    8000180c:	1101                	addi	sp,sp,-32
    8000180e:	ec06                	sd	ra,24(sp)
    80001810:	e822                	sd	s0,16(sp)
    80001812:	e426                	sd	s1,8(sp)
    80001814:	1000                	addi	s0,sp,32
    80001816:	84aa                	mv	s1,a0
  //checking the level not over level 3
  if (p->level > 3)
    80001818:	17053703          	ld	a4,368(a0)
    8000181c:	478d                	li	a5,3
    8000181e:	06e7e163          	bltu	a5,a4,80001880 <enqueue+0x74>
  {
    printf("enqueue level error");
  }
  //create offset since we start from level 1-3 but in the qtable is 0-2
  uint64 offset = p->level - 1;
  struct qentry *mlq = qtable + NPROC + offset;
    80001822:	1704b683          	ld	a3,368(s1)
    80001826:	03f68693          	addi	a3,a3,63 # 103f <_entry-0x7fffefc1>
    8000182a:	00010717          	auipc	a4,0x10
    8000182e:	a7670713          	addi	a4,a4,-1418 # 800112a0 <qtable>
    80001832:	00469793          	slli	a5,a3,0x4
    80001836:	97ba                	add	a5,a5,a4
  uint64 pindex = p - proc;
    80001838:	00010517          	auipc	a0,0x10
    8000183c:	2c850513          	addi	a0,a0,712 # 80011b00 <proc>
    80001840:	8c89                	sub	s1,s1,a0
    80001842:	848d                	srai	s1,s1,0x3
    80001844:	00006617          	auipc	a2,0x6
    80001848:	7bc63603          	ld	a2,1980(a2) # 80008000 <etext>
    8000184c:	02c484b3          	mul	s1,s1,a2
  struct qentry *pinqtable = qtable + pindex;
    80001850:	00449613          	slli	a2,s1,0x4
    80001854:	9732                	add	a4,a4,a2

  // if there is no process in the queue level
  if (mlq->next == EMPTY)
    80001856:	678c                	ld	a1,8(a5)
    80001858:	567d                	li	a2,-1
    8000185a:	02c58c63          	beq	a1,a2,80001892 <enqueue+0x86>
    mlq->prev = pindex;
  }
  // if there is process in the queue level
  else
  {
    uint64 lastProcess = mlq->prev;
    8000185e:	638c                	ld	a1,0(a5)
    struct qentry *lastQEntry = qtable + lastProcess;
    lastQEntry->next = pindex;
    80001860:	00459513          	slli	a0,a1,0x4
    80001864:	00010617          	auipc	a2,0x10
    80001868:	a3c60613          	addi	a2,a2,-1476 # 800112a0 <qtable>
    8000186c:	962a                	add	a2,a2,a0
    8000186e:	e604                	sd	s1,8(a2)
    pinqtable->prev = lastProcess;
    80001870:	e30c                	sd	a1,0(a4)
    pinqtable->next = NPROC + offset;
    80001872:	e714                	sd	a3,8(a4)
    mlq->prev = pindex;
    80001874:	e384                	sd	s1,0(a5)
  }
}
    80001876:	60e2                	ld	ra,24(sp)
    80001878:	6442                	ld	s0,16(sp)
    8000187a:	64a2                	ld	s1,8(sp)
    8000187c:	6105                	addi	sp,sp,32
    8000187e:	8082                	ret
    printf("enqueue level error");
    80001880:	00007517          	auipc	a0,0x7
    80001884:	94050513          	addi	a0,a0,-1728 # 800081c0 <digits+0x180>
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	cec080e7          	jalr	-788(ra) # 80000574 <printf>
    80001890:	bf49                	j	80001822 <enqueue+0x16>
    pinqtable->next = NPROC + offset;
    80001892:	e714                	sd	a3,8(a4)
    pinqtable->prev = NPROC + offset;
    80001894:	e314                	sd	a3,0(a4)
    mlq->next = pindex;
    80001896:	e784                	sd	s1,8(a5)
    mlq->prev = pindex;
    80001898:	e384                	sd	s1,0(a5)
    8000189a:	bff1                	j	80001876 <enqueue+0x6a>

000000008000189c <dequeue>:
 * @Authors: Leyuan & Lee
 * Implement dequeue for taking out the process from the mlq
 * return process pointer that is dequeueing
**/ 
struct proc *dequeue()
{
    8000189c:	7179                	addi	sp,sp,-48
    8000189e:	f406                	sd	ra,40(sp)
    800018a0:	f022                	sd	s0,32(sp)
    800018a2:	ec26                	sd	s1,24(sp)
    800018a4:	e84a                	sd	s2,16(sp)
    800018a6:	e44e                	sd	s3,8(sp)
    800018a8:	e052                	sd	s4,0(sp)
    800018aa:	1800                	addi	s0,sp,48
  struct qentry *q;

  // go through every level of queue to look for process to dequeue
  for (q = qtable + NPROC; q < &qtable[QTABLE_SIZE]; q++)
    800018ac:	00010497          	auipc	s1,0x10
    800018b0:	df448493          	addi	s1,s1,-524 # 800116a0 <qtable+0x400>
  {
    if (q->next != EMPTY)
    800018b4:	577d                	li	a4,-1
  for (q = qtable + NPROC; q < &qtable[QTABLE_SIZE]; q++)
    800018b6:	00010697          	auipc	a3,0x10
    800018ba:	e1a68693          	addi	a3,a3,-486 # 800116d0 <pid_lock>
    if (q->next != EMPTY)
    800018be:	649c                	ld	a5,8(s1)
    800018c0:	00e79f63          	bne	a5,a4,800018de <dequeue+0x42>
  for (q = qtable + NPROC; q < &qtable[QTABLE_SIZE]; q++)
    800018c4:	04c1                	addi	s1,s1,16
    800018c6:	fed49ce3          	bne	s1,a3,800018be <dequeue+0x22>
      {
        return p;
      }
    }
  }
  return 0;
    800018ca:	4901                	li	s2,0
}
    800018cc:	854a                	mv	a0,s2
    800018ce:	70a2                	ld	ra,40(sp)
    800018d0:	7402                	ld	s0,32(sp)
    800018d2:	64e2                	ld	s1,24(sp)
    800018d4:	6942                	ld	s2,16(sp)
    800018d6:	69a2                	ld	s3,8(sp)
    800018d8:	6a02                	ld	s4,0(sp)
    800018da:	6145                	addi	sp,sp,48
    800018dc:	8082                	ret
      uint64 qindex = q - qtable;
    800018de:	00010997          	auipc	s3,0x10
    800018e2:	9c298993          	addi	s3,s3,-1598 # 800112a0 <qtable>
    800018e6:	413489b3          	sub	s3,s1,s3
    800018ea:	4049d993          	srai	s3,s3,0x4
      p = proc + q->next;
    800018ee:	17800913          	li	s2,376
    800018f2:	032787b3          	mul	a5,a5,s2
    800018f6:	00010917          	auipc	s2,0x10
    800018fa:	20a90913          	addi	s2,s2,522 # 80011b00 <proc>
    800018fe:	993e                	add	s2,s2,a5
      if (qindex == 63 && p->level == 1)
    80001900:	03f00793          	li	a5,63
    80001904:	02f98963          	beq	s3,a5,80001936 <dequeue+0x9a>
      else if (qindex == 64 && p->level == 2)
    80001908:	04000793          	li	a5,64
    8000190c:	08f98c63          	beq	s3,a5,800019a4 <dequeue+0x108>
      else if (qindex == 65 && p->level == 3)
    80001910:	04100793          	li	a5,65
    80001914:	02f99663          	bne	s3,a5,80001940 <dequeue+0xa4>
    80001918:	17093703          	ld	a4,368(s2)
    8000191c:	478d                	li	a5,3
    8000191e:	02f71163          	bne	a4,a5,80001940 <dequeue+0xa4>
        printf("Process with level: %d is on queue: 2", p->level - 1);
    80001922:	4589                	li	a1,2
    80001924:	00007517          	auipc	a0,0x7
    80001928:	90450513          	addi	a0,a0,-1788 # 80008228 <digits+0x1e8>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	c48080e7          	jalr	-952(ra) # 80000574 <printf>
    80001934:	a031                	j	80001940 <dequeue+0xa4>
      if (qindex == 63 && p->level == 1)
    80001936:	17093703          	ld	a4,368(s2)
    8000193a:	4785                	li	a5,1
    8000193c:	04f70a63          	beq	a4,a5,80001990 <dequeue+0xf4>
      qfirst = qtable + q->next;
    80001940:	00010797          	auipc	a5,0x10
    80001944:	96078793          	addi	a5,a5,-1696 # 800112a0 <qtable>
    80001948:	0084ba03          	ld	s4,8(s1)
    8000194c:	0a12                	slli	s4,s4,0x4
    8000194e:	9a3e                	add	s4,s4,a5
      qsecond = qtable + qfirst->next;
    80001950:	008a3703          	ld	a4,8(s4) # fffffffffffff008 <end+0xffffffff7ffd9008>
      q->next = qfirst->next;
    80001954:	e498                	sd	a4,8(s1)
      qsecond->prev = qindex;
    80001956:	0712                	slli	a4,a4,0x4
    80001958:	97ba                	add	a5,a5,a4
    8000195a:	0137b023          	sd	s3,0(a5)
      if  (qfirst->prev != qindex)
    8000195e:	000a3783          	ld	a5,0(s4)
    80001962:	07379063          	bne	a5,s3,800019c2 <dequeue+0x126>
      if (q->next == qindex && q->prev == qindex)
    80001966:	649c                	ld	a5,8(s1)
    80001968:	07378663          	beq	a5,s3,800019d4 <dequeue+0x138>
      qfirst->next = EMPTY;
    8000196c:	57fd                	li	a5,-1
    8000196e:	00fa3423          	sd	a5,8(s4)
      qfirst->prev = EMPTY;
    80001972:	00fa3023          	sd	a5,0(s4)
      if (p->pid == 0)
    80001976:	03092783          	lw	a5,48(s2)
    8000197a:	fba9                	bnez	a5,800018cc <dequeue+0x30>
        printf("Pid = 0\n");
    8000197c:	00007517          	auipc	a0,0x7
    80001980:	91450513          	addi	a0,a0,-1772 # 80008290 <digits+0x250>
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	bf0080e7          	jalr	-1040(ra) # 80000574 <printf>
        return 0;
    8000198c:	4901                	li	s2,0
    8000198e:	bf3d                	j	800018cc <dequeue+0x30>
        printf("Process with level: %d is on queue: 0", p->level - 1);
    80001990:	4581                	li	a1,0
    80001992:	00007517          	auipc	a0,0x7
    80001996:	84650513          	addi	a0,a0,-1978 # 800081d8 <digits+0x198>
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	bda080e7          	jalr	-1062(ra) # 80000574 <printf>
    800019a2:	bf79                	j	80001940 <dequeue+0xa4>
      else if (qindex == 64 && p->level == 2)
    800019a4:	17093703          	ld	a4,368(s2)
    800019a8:	4789                	li	a5,2
    800019aa:	f8f71be3          	bne	a4,a5,80001940 <dequeue+0xa4>
        printf("Process with level: %d is on queue: 1", p->level - 1);
    800019ae:	4585                	li	a1,1
    800019b0:	00007517          	auipc	a0,0x7
    800019b4:	85050513          	addi	a0,a0,-1968 # 80008200 <digits+0x1c0>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	bbc080e7          	jalr	-1092(ra) # 80000574 <printf>
    800019c0:	b741                	j	80001940 <dequeue+0xa4>
        printf("In Qtable, the previous of dequeuing process is not head.\n");
    800019c2:	00007517          	auipc	a0,0x7
    800019c6:	88e50513          	addi	a0,a0,-1906 # 80008250 <digits+0x210>
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	baa080e7          	jalr	-1110(ra) # 80000574 <printf>
    800019d2:	bf51                	j	80001966 <dequeue+0xca>
      if (q->next == qindex && q->prev == qindex)
    800019d4:	609c                	ld	a5,0(s1)
    800019d6:	f9379be3          	bne	a5,s3,8000196c <dequeue+0xd0>
        q->next = EMPTY;
    800019da:	57fd                	li	a5,-1
    800019dc:	e49c                	sd	a5,8(s1)
        q->prev = EMPTY;
    800019de:	e09c                	sd	a5,0(s1)
    800019e0:	b771                	j	8000196c <dequeue+0xd0>

00000000800019e2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800019e2:	7139                	addi	sp,sp,-64
    800019e4:	fc06                	sd	ra,56(sp)
    800019e6:	f822                	sd	s0,48(sp)
    800019e8:	f426                	sd	s1,40(sp)
    800019ea:	f04a                	sd	s2,32(sp)
    800019ec:	ec4e                	sd	s3,24(sp)
    800019ee:	e852                	sd	s4,16(sp)
    800019f0:	e456                	sd	s5,8(sp)
    800019f2:	e05a                	sd	s6,0(sp)
    800019f4:	0080                	addi	s0,sp,64
    800019f6:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800019f8:	00010497          	auipc	s1,0x10
    800019fc:	10848493          	addi	s1,s1,264 # 80011b00 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a00:	8b26                	mv	s6,s1
    80001a02:	00006a97          	auipc	s5,0x6
    80001a06:	5fea8a93          	addi	s5,s5,1534 # 80008000 <etext>
    80001a0a:	04000937          	lui	s2,0x4000
    80001a0e:	197d                	addi	s2,s2,-1
    80001a10:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a12:	00016a17          	auipc	s4,0x16
    80001a16:	eeea0a13          	addi	s4,s4,-274 # 80017900 <tickslock>
    char *pa = kalloc();
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	0b8080e7          	jalr	184(ra) # 80000ad2 <kalloc>
    80001a22:	862a                	mv	a2,a0
    if (pa == 0)
    80001a24:	c131                	beqz	a0,80001a68 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a26:	416485b3          	sub	a1,s1,s6
    80001a2a:	858d                	srai	a1,a1,0x3
    80001a2c:	000ab783          	ld	a5,0(s5)
    80001a30:	02f585b3          	mul	a1,a1,a5
    80001a34:	2585                	addiw	a1,a1,1
    80001a36:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a3a:	4719                	li	a4,6
    80001a3c:	6685                	lui	a3,0x1
    80001a3e:	40b905b3          	sub	a1,s2,a1
    80001a42:	854e                	mv	a0,s3
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	6d8080e7          	jalr	1752(ra) # 8000111c <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a4c:	17848493          	addi	s1,s1,376
    80001a50:	fd4495e3          	bne	s1,s4,80001a1a <proc_mapstacks+0x38>
  }
}
    80001a54:	70e2                	ld	ra,56(sp)
    80001a56:	7442                	ld	s0,48(sp)
    80001a58:	74a2                	ld	s1,40(sp)
    80001a5a:	7902                	ld	s2,32(sp)
    80001a5c:	69e2                	ld	s3,24(sp)
    80001a5e:	6a42                	ld	s4,16(sp)
    80001a60:	6aa2                	ld	s5,8(sp)
    80001a62:	6b02                	ld	s6,0(sp)
    80001a64:	6121                	addi	sp,sp,64
    80001a66:	8082                	ret
      panic("kalloc");
    80001a68:	00007517          	auipc	a0,0x7
    80001a6c:	83850513          	addi	a0,a0,-1992 # 800082a0 <digits+0x260>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	aba080e7          	jalr	-1350(ra) # 8000052a <panic>

0000000080001a78 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    80001a78:	7139                	addi	sp,sp,-64
    80001a7a:	fc06                	sd	ra,56(sp)
    80001a7c:	f822                	sd	s0,48(sp)
    80001a7e:	f426                	sd	s1,40(sp)
    80001a80:	f04a                	sd	s2,32(sp)
    80001a82:	ec4e                	sd	s3,24(sp)
    80001a84:	e852                	sd	s4,16(sp)
    80001a86:	e456                	sd	s5,8(sp)
    80001a88:	e05a                	sd	s6,0(sp)
    80001a8a:	0080                	addi	s0,sp,64

  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a8c:	00007597          	auipc	a1,0x7
    80001a90:	81c58593          	addi	a1,a1,-2020 # 800082a8 <digits+0x268>
    80001a94:	00010517          	auipc	a0,0x10
    80001a98:	c3c50513          	addi	a0,a0,-964 # 800116d0 <pid_lock>
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	096080e7          	jalr	150(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001aa4:	00007597          	auipc	a1,0x7
    80001aa8:	80c58593          	addi	a1,a1,-2036 # 800082b0 <digits+0x270>
    80001aac:	00010517          	auipc	a0,0x10
    80001ab0:	c3c50513          	addi	a0,a0,-964 # 800116e8 <wait_lock>
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	07e080e7          	jalr	126(ra) # 80000b32 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001abc:	00010497          	auipc	s1,0x10
    80001ac0:	04448493          	addi	s1,s1,68 # 80011b00 <proc>
  {
    initlock(&p->lock, "proc");
    80001ac4:	00006b17          	auipc	s6,0x6
    80001ac8:	7fcb0b13          	addi	s6,s6,2044 # 800082c0 <digits+0x280>
    p->kstack = KSTACK((int)(p - proc));
    80001acc:	8aa6                	mv	s5,s1
    80001ace:	00006a17          	auipc	s4,0x6
    80001ad2:	532a0a13          	addi	s4,s4,1330 # 80008000 <etext>
    80001ad6:	04000937          	lui	s2,0x4000
    80001ada:	197d                	addi	s2,s2,-1
    80001adc:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ade:	00016997          	auipc	s3,0x16
    80001ae2:	e2298993          	addi	s3,s3,-478 # 80017900 <tickslock>
    initlock(&p->lock, "proc");
    80001ae6:	85da                	mv	a1,s6
    80001ae8:	8526                	mv	a0,s1
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	048080e7          	jalr	72(ra) # 80000b32 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001af2:	415487b3          	sub	a5,s1,s5
    80001af6:	878d                	srai	a5,a5,0x3
    80001af8:	000a3703          	ld	a4,0(s4)
    80001afc:	02e787b3          	mul	a5,a5,a4
    80001b00:	2785                	addiw	a5,a5,1
    80001b02:	00d7979b          	slliw	a5,a5,0xd
    80001b06:	40f907b3          	sub	a5,s2,a5
    80001b0a:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b0c:	17848493          	addi	s1,s1,376
    80001b10:	fd349be3          	bne	s1,s3,80001ae6 <procinit+0x6e>
  }

  //Leyuan & Lee
  //Initialize qtable
  struct qentry *q;
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001b14:	0000f797          	auipc	a5,0xf
    80001b18:	78c78793          	addi	a5,a5,1932 # 800112a0 <qtable>
  {
    // let all the process in qtable prev and next = EMPTY (-1)
    q->prev = EMPTY;
    80001b1c:	577d                	li	a4,-1
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001b1e:	00010697          	auipc	a3,0x10
    80001b22:	bb268693          	addi	a3,a3,-1102 # 800116d0 <pid_lock>
    q->prev = EMPTY;
    80001b26:	e398                	sd	a4,0(a5)
    q->next = EMPTY;
    80001b28:	e798                	sd	a4,8(a5)
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001b2a:	07c1                	addi	a5,a5,16
    80001b2c:	fed79de3          	bne	a5,a3,80001b26 <procinit+0xae>
  }
}
    80001b30:	70e2                	ld	ra,56(sp)
    80001b32:	7442                	ld	s0,48(sp)
    80001b34:	74a2                	ld	s1,40(sp)
    80001b36:	7902                	ld	s2,32(sp)
    80001b38:	69e2                	ld	s3,24(sp)
    80001b3a:	6a42                	ld	s4,16(sp)
    80001b3c:	6aa2                	ld	s5,8(sp)
    80001b3e:	6b02                	ld	s6,0(sp)
    80001b40:	6121                	addi	sp,sp,64
    80001b42:	8082                	ret

0000000080001b44 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b44:	1141                	addi	sp,sp,-16
    80001b46:	e422                	sd	s0,8(sp)
    80001b48:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b4a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b4c:	2501                	sext.w	a0,a0
    80001b4e:	6422                	ld	s0,8(sp)
    80001b50:	0141                	addi	sp,sp,16
    80001b52:	8082                	ret

0000000080001b54 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b54:	1141                	addi	sp,sp,-16
    80001b56:	e422                	sd	s0,8(sp)
    80001b58:	0800                	addi	s0,sp,16
    80001b5a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b5c:	2781                	sext.w	a5,a5
    80001b5e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b60:	00010517          	auipc	a0,0x10
    80001b64:	ba050513          	addi	a0,a0,-1120 # 80011700 <cpus>
    80001b68:	953e                	add	a0,a0,a5
    80001b6a:	6422                	ld	s0,8(sp)
    80001b6c:	0141                	addi	sp,sp,16
    80001b6e:	8082                	ret

0000000080001b70 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b70:	1101                	addi	sp,sp,-32
    80001b72:	ec06                	sd	ra,24(sp)
    80001b74:	e822                	sd	s0,16(sp)
    80001b76:	e426                	sd	s1,8(sp)
    80001b78:	1000                	addi	s0,sp,32
  push_off();
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	ffc080e7          	jalr	-4(ra) # 80000b76 <push_off>
    80001b82:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b84:	2781                	sext.w	a5,a5
    80001b86:	079e                	slli	a5,a5,0x7
    80001b88:	0000f717          	auipc	a4,0xf
    80001b8c:	71870713          	addi	a4,a4,1816 # 800112a0 <qtable>
    80001b90:	97ba                	add	a5,a5,a4
    80001b92:	4607b483          	ld	s1,1120(a5)
  pop_off();
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	080080e7          	jalr	128(ra) # 80000c16 <pop_off>
  return p;
}
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	60e2                	ld	ra,24(sp)
    80001ba2:	6442                	ld	s0,16(sp)
    80001ba4:	64a2                	ld	s1,8(sp)
    80001ba6:	6105                	addi	sp,sp,32
    80001ba8:	8082                	ret

0000000080001baa <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001baa:	1141                	addi	sp,sp,-16
    80001bac:	e406                	sd	ra,8(sp)
    80001bae:	e022                	sd	s0,0(sp)
    80001bb0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bb2:	00000097          	auipc	ra,0x0
    80001bb6:	fbe080e7          	jalr	-66(ra) # 80001b70 <myproc>
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	0bc080e7          	jalr	188(ra) # 80000c76 <release>

  if (first)
    80001bc2:	00007797          	auipc	a5,0x7
    80001bc6:	d1e7a783          	lw	a5,-738(a5) # 800088e0 <first.1>
    80001bca:	eb89                	bnez	a5,80001bdc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bcc:	00001097          	auipc	ra,0x1
    80001bd0:	dfe080e7          	jalr	-514(ra) # 800029ca <usertrapret>
}
    80001bd4:	60a2                	ld	ra,8(sp)
    80001bd6:	6402                	ld	s0,0(sp)
    80001bd8:	0141                	addi	sp,sp,16
    80001bda:	8082                	ret
    first = 0;
    80001bdc:	00007797          	auipc	a5,0x7
    80001be0:	d007a223          	sw	zero,-764(a5) # 800088e0 <first.1>
    fsinit(ROOTDEV);
    80001be4:	4505                	li	a0,1
    80001be6:	00002097          	auipc	ra,0x2
    80001bea:	ba0080e7          	jalr	-1120(ra) # 80003786 <fsinit>
    80001bee:	bff9                	j	80001bcc <forkret+0x22>

0000000080001bf0 <allocpid>:
{
    80001bf0:	1101                	addi	sp,sp,-32
    80001bf2:	ec06                	sd	ra,24(sp)
    80001bf4:	e822                	sd	s0,16(sp)
    80001bf6:	e426                	sd	s1,8(sp)
    80001bf8:	e04a                	sd	s2,0(sp)
    80001bfa:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bfc:	00010917          	auipc	s2,0x10
    80001c00:	ad490913          	addi	s2,s2,-1324 # 800116d0 <pid_lock>
    80001c04:	854a                	mv	a0,s2
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	fbc080e7          	jalr	-68(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001c0e:	00007797          	auipc	a5,0x7
    80001c12:	cd678793          	addi	a5,a5,-810 # 800088e4 <nextpid>
    80001c16:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c18:	0014871b          	addiw	a4,s1,1
    80001c1c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c1e:	854a                	mv	a0,s2
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	056080e7          	jalr	86(ra) # 80000c76 <release>
}
    80001c28:	8526                	mv	a0,s1
    80001c2a:	60e2                	ld	ra,24(sp)
    80001c2c:	6442                	ld	s0,16(sp)
    80001c2e:	64a2                	ld	s1,8(sp)
    80001c30:	6902                	ld	s2,0(sp)
    80001c32:	6105                	addi	sp,sp,32
    80001c34:	8082                	ret

0000000080001c36 <proc_pagetable>:
{
    80001c36:	1101                	addi	sp,sp,-32
    80001c38:	ec06                	sd	ra,24(sp)
    80001c3a:	e822                	sd	s0,16(sp)
    80001c3c:	e426                	sd	s1,8(sp)
    80001c3e:	e04a                	sd	s2,0(sp)
    80001c40:	1000                	addi	s0,sp,32
    80001c42:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	6c2080e7          	jalr	1730(ra) # 80001306 <uvmcreate>
    80001c4c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c4e:	c121                	beqz	a0,80001c8e <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c50:	4729                	li	a4,10
    80001c52:	00005697          	auipc	a3,0x5
    80001c56:	3ae68693          	addi	a3,a3,942 # 80007000 <_trampoline>
    80001c5a:	6605                	lui	a2,0x1
    80001c5c:	040005b7          	lui	a1,0x4000
    80001c60:	15fd                	addi	a1,a1,-1
    80001c62:	05b2                	slli	a1,a1,0xc
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	42a080e7          	jalr	1066(ra) # 8000108e <mappages>
    80001c6c:	02054863          	bltz	a0,80001c9c <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c70:	4719                	li	a4,6
    80001c72:	05893683          	ld	a3,88(s2)
    80001c76:	6605                	lui	a2,0x1
    80001c78:	020005b7          	lui	a1,0x2000
    80001c7c:	15fd                	addi	a1,a1,-1
    80001c7e:	05b6                	slli	a1,a1,0xd
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	40c080e7          	jalr	1036(ra) # 8000108e <mappages>
    80001c8a:	02054163          	bltz	a0,80001cac <proc_pagetable+0x76>
}
    80001c8e:	8526                	mv	a0,s1
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6902                	ld	s2,0(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret
    uvmfree(pagetable, 0);
    80001c9c:	4581                	li	a1,0
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	862080e7          	jalr	-1950(ra) # 80001502 <uvmfree>
    return 0;
    80001ca8:	4481                	li	s1,0
    80001caa:	b7d5                	j	80001c8e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cac:	4681                	li	a3,0
    80001cae:	4605                	li	a2,1
    80001cb0:	040005b7          	lui	a1,0x4000
    80001cb4:	15fd                	addi	a1,a1,-1
    80001cb6:	05b2                	slli	a1,a1,0xc
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	588080e7          	jalr	1416(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cc2:	4581                	li	a1,0
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	83c080e7          	jalr	-1988(ra) # 80001502 <uvmfree>
    return 0;
    80001cce:	4481                	li	s1,0
    80001cd0:	bf7d                	j	80001c8e <proc_pagetable+0x58>

0000000080001cd2 <proc_freepagetable>:
{
    80001cd2:	1101                	addi	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	e04a                	sd	s2,0(sp)
    80001cdc:	1000                	addi	s0,sp,32
    80001cde:	84aa                	mv	s1,a0
    80001ce0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce2:	4681                	li	a3,0
    80001ce4:	4605                	li	a2,1
    80001ce6:	040005b7          	lui	a1,0x4000
    80001cea:	15fd                	addi	a1,a1,-1
    80001cec:	05b2                	slli	a1,a1,0xc
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	554080e7          	jalr	1364(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cf6:	4681                	li	a3,0
    80001cf8:	4605                	li	a2,1
    80001cfa:	020005b7          	lui	a1,0x2000
    80001cfe:	15fd                	addi	a1,a1,-1
    80001d00:	05b6                	slli	a1,a1,0xd
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	53e080e7          	jalr	1342(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d0c:	85ca                	mv	a1,s2
    80001d0e:	8526                	mv	a0,s1
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	7f2080e7          	jalr	2034(ra) # 80001502 <uvmfree>
}
    80001d18:	60e2                	ld	ra,24(sp)
    80001d1a:	6442                	ld	s0,16(sp)
    80001d1c:	64a2                	ld	s1,8(sp)
    80001d1e:	6902                	ld	s2,0(sp)
    80001d20:	6105                	addi	sp,sp,32
    80001d22:	8082                	ret

0000000080001d24 <freeproc>:
{
    80001d24:	1101                	addi	sp,sp,-32
    80001d26:	ec06                	sd	ra,24(sp)
    80001d28:	e822                	sd	s0,16(sp)
    80001d2a:	e426                	sd	s1,8(sp)
    80001d2c:	1000                	addi	s0,sp,32
    80001d2e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d30:	6d28                	ld	a0,88(a0)
    80001d32:	c509                	beqz	a0,80001d3c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	ca2080e7          	jalr	-862(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001d3c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d40:	68a8                	ld	a0,80(s1)
    80001d42:	c511                	beqz	a0,80001d4e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d44:	64ac                	ld	a1,72(s1)
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	f8c080e7          	jalr	-116(ra) # 80001cd2 <proc_freepagetable>
  p->pagetable = 0;
    80001d4e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d52:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d56:	0204a823          	sw	zero,48(s1)
  p->ticks = 0;  //initialize the tick of process
    80001d5a:	1604a423          	sw	zero,360(s1)
  p->parent = 0;
    80001d5e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d62:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d66:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d6a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d6e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d72:	0004ac23          	sw	zero,24(s1)
}
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6105                	addi	sp,sp,32
    80001d7e:	8082                	ret

0000000080001d80 <allocproc>:
{
    80001d80:	1101                	addi	sp,sp,-32
    80001d82:	ec06                	sd	ra,24(sp)
    80001d84:	e822                	sd	s0,16(sp)
    80001d86:	e426                	sd	s1,8(sp)
    80001d88:	e04a                	sd	s2,0(sp)
    80001d8a:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d8c:	00010497          	auipc	s1,0x10
    80001d90:	d7448493          	addi	s1,s1,-652 # 80011b00 <proc>
    80001d94:	00016917          	auipc	s2,0x16
    80001d98:	b6c90913          	addi	s2,s2,-1172 # 80017900 <tickslock>
    acquire(&p->lock);
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	e24080e7          	jalr	-476(ra) # 80000bc2 <acquire>
    if (p->state == UNUSED)
    80001da6:	4c9c                	lw	a5,24(s1)
    80001da8:	cf81                	beqz	a5,80001dc0 <allocproc+0x40>
      release(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	eca080e7          	jalr	-310(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001db4:	17848493          	addi	s1,s1,376
    80001db8:	ff2492e3          	bne	s1,s2,80001d9c <allocproc+0x1c>
  return 0;
    80001dbc:	4481                	li	s1,0
    80001dbe:	a8a9                	j	80001e18 <allocproc+0x98>
  p->pid = allocpid();
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	e30080e7          	jalr	-464(ra) # 80001bf0 <allocpid>
    80001dc8:	d888                	sw	a0,48(s1)
  p->ticks = 0; //Leyuan & Lee
    80001dca:	1604a423          	sw	zero,360(s1)
  p->level = 1;
    80001dce:	4785                	li	a5,1
    80001dd0:	16f4b823          	sd	a5,368(s1)
  p->state = USED;
    80001dd4:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	cfc080e7          	jalr	-772(ra) # 80000ad2 <kalloc>
    80001dde:	892a                	mv	s2,a0
    80001de0:	eca8                	sd	a0,88(s1)
    80001de2:	c131                	beqz	a0,80001e26 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001de4:	8526                	mv	a0,s1
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	e50080e7          	jalr	-432(ra) # 80001c36 <proc_pagetable>
    80001dee:	892a                	mv	s2,a0
    80001df0:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001df2:	c531                	beqz	a0,80001e3e <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001df4:	07000613          	li	a2,112
    80001df8:	4581                	li	a1,0
    80001dfa:	06048513          	addi	a0,s1,96
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	ec0080e7          	jalr	-320(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001e06:	00000797          	auipc	a5,0x0
    80001e0a:	da478793          	addi	a5,a5,-604 # 80001baa <forkret>
    80001e0e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e10:	60bc                	ld	a5,64(s1)
    80001e12:	6705                	lui	a4,0x1
    80001e14:	97ba                	add	a5,a5,a4
    80001e16:	f4bc                	sd	a5,104(s1)
}
    80001e18:	8526                	mv	a0,s1
    80001e1a:	60e2                	ld	ra,24(sp)
    80001e1c:	6442                	ld	s0,16(sp)
    80001e1e:	64a2                	ld	s1,8(sp)
    80001e20:	6902                	ld	s2,0(sp)
    80001e22:	6105                	addi	sp,sp,32
    80001e24:	8082                	ret
    freeproc(p);
    80001e26:	8526                	mv	a0,s1
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	efc080e7          	jalr	-260(ra) # 80001d24 <freeproc>
    release(&p->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e44080e7          	jalr	-444(ra) # 80000c76 <release>
    return 0;
    80001e3a:	84ca                	mv	s1,s2
    80001e3c:	bff1                	j	80001e18 <allocproc+0x98>
    freeproc(p);
    80001e3e:	8526                	mv	a0,s1
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	ee4080e7          	jalr	-284(ra) # 80001d24 <freeproc>
    release(&p->lock);
    80001e48:	8526                	mv	a0,s1
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e2c080e7          	jalr	-468(ra) # 80000c76 <release>
    return 0;
    80001e52:	84ca                	mv	s1,s2
    80001e54:	b7d1                	j	80001e18 <allocproc+0x98>

0000000080001e56 <userinit>:
{
    80001e56:	1101                	addi	sp,sp,-32
    80001e58:	ec06                	sd	ra,24(sp)
    80001e5a:	e822                	sd	s0,16(sp)
    80001e5c:	e426                	sd	s1,8(sp)
    80001e5e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	f20080e7          	jalr	-224(ra) # 80001d80 <allocproc>
    80001e68:	84aa                	mv	s1,a0
  initproc = p;
    80001e6a:	00007797          	auipc	a5,0x7
    80001e6e:	1aa7bf23          	sd	a0,446(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e72:	03400613          	li	a2,52
    80001e76:	00007597          	auipc	a1,0x7
    80001e7a:	a7a58593          	addi	a1,a1,-1414 # 800088f0 <initcode>
    80001e7e:	6928                	ld	a0,80(a0)
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	4b4080e7          	jalr	1204(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001e88:	6785                	lui	a5,0x1
    80001e8a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e8c:	6cb8                	ld	a4,88(s1)
    80001e8e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e92:	6cb8                	ld	a4,88(s1)
    80001e94:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e96:	4641                	li	a2,16
    80001e98:	00006597          	auipc	a1,0x6
    80001e9c:	43058593          	addi	a1,a1,1072 # 800082c8 <digits+0x288>
    80001ea0:	15848513          	addi	a0,s1,344
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	f6c080e7          	jalr	-148(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001eac:	00006517          	auipc	a0,0x6
    80001eb0:	42c50513          	addi	a0,a0,1068 # 800082d8 <digits+0x298>
    80001eb4:	00002097          	auipc	ra,0x2
    80001eb8:	300080e7          	jalr	768(ra) # 800041b4 <namei>
    80001ebc:	14a4b823          	sd	a0,336(s1)
  global_ticks = 0; // initialize the global ticks
    80001ec0:	00007797          	auipc	a5,0x7
    80001ec4:	1607a823          	sw	zero,368(a5) # 80009030 <global_ticks>
  p->state = RUNNABLE;
    80001ec8:	478d                	li	a5,3
    80001eca:	cc9c                	sw	a5,24(s1)
  enqueue(p); // add the process into mlq
    80001ecc:	8526                	mv	a0,s1
    80001ece:	00000097          	auipc	ra,0x0
    80001ed2:	93e080e7          	jalr	-1730(ra) # 8000180c <enqueue>
  release(&p->lock);
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	d9e080e7          	jalr	-610(ra) # 80000c76 <release>
}
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6105                	addi	sp,sp,32
    80001ee8:	8082                	ret

0000000080001eea <growproc>:
{
    80001eea:	1101                	addi	sp,sp,-32
    80001eec:	ec06                	sd	ra,24(sp)
    80001eee:	e822                	sd	s0,16(sp)
    80001ef0:	e426                	sd	s1,8(sp)
    80001ef2:	e04a                	sd	s2,0(sp)
    80001ef4:	1000                	addi	s0,sp,32
    80001ef6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ef8:	00000097          	auipc	ra,0x0
    80001efc:	c78080e7          	jalr	-904(ra) # 80001b70 <myproc>
    80001f00:	892a                	mv	s2,a0
  sz = p->sz;
    80001f02:	652c                	ld	a1,72(a0)
    80001f04:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001f08:	00904f63          	bgtz	s1,80001f26 <growproc+0x3c>
  else if (n < 0)
    80001f0c:	0204cc63          	bltz	s1,80001f44 <growproc+0x5a>
  p->sz = sz;
    80001f10:	1602                	slli	a2,a2,0x20
    80001f12:	9201                	srli	a2,a2,0x20
    80001f14:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f18:	4501                	li	a0,0
}
    80001f1a:	60e2                	ld	ra,24(sp)
    80001f1c:	6442                	ld	s0,16(sp)
    80001f1e:	64a2                	ld	s1,8(sp)
    80001f20:	6902                	ld	s2,0(sp)
    80001f22:	6105                	addi	sp,sp,32
    80001f24:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001f26:	9e25                	addw	a2,a2,s1
    80001f28:	1602                	slli	a2,a2,0x20
    80001f2a:	9201                	srli	a2,a2,0x20
    80001f2c:	1582                	slli	a1,a1,0x20
    80001f2e:	9181                	srli	a1,a1,0x20
    80001f30:	6928                	ld	a0,80(a0)
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	4bc080e7          	jalr	1212(ra) # 800013ee <uvmalloc>
    80001f3a:	0005061b          	sext.w	a2,a0
    80001f3e:	fa69                	bnez	a2,80001f10 <growproc+0x26>
      return -1;
    80001f40:	557d                	li	a0,-1
    80001f42:	bfe1                	j	80001f1a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f44:	9e25                	addw	a2,a2,s1
    80001f46:	1602                	slli	a2,a2,0x20
    80001f48:	9201                	srli	a2,a2,0x20
    80001f4a:	1582                	slli	a1,a1,0x20
    80001f4c:	9181                	srli	a1,a1,0x20
    80001f4e:	6928                	ld	a0,80(a0)
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	456080e7          	jalr	1110(ra) # 800013a6 <uvmdealloc>
    80001f58:	0005061b          	sext.w	a2,a0
    80001f5c:	bf55                	j	80001f10 <growproc+0x26>

0000000080001f5e <fork>:
{
    80001f5e:	7139                	addi	sp,sp,-64
    80001f60:	fc06                	sd	ra,56(sp)
    80001f62:	f822                	sd	s0,48(sp)
    80001f64:	f426                	sd	s1,40(sp)
    80001f66:	f04a                	sd	s2,32(sp)
    80001f68:	ec4e                	sd	s3,24(sp)
    80001f6a:	e852                	sd	s4,16(sp)
    80001f6c:	e456                	sd	s5,8(sp)
    80001f6e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	c00080e7          	jalr	-1024(ra) # 80001b70 <myproc>
    80001f78:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	e06080e7          	jalr	-506(ra) # 80001d80 <allocproc>
    80001f82:	12050163          	beqz	a0,800020a4 <fork+0x146>
    80001f86:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f88:	048ab603          	ld	a2,72(s5)
    80001f8c:	692c                	ld	a1,80(a0)
    80001f8e:	050ab503          	ld	a0,80(s5)
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	5a8080e7          	jalr	1448(ra) # 8000153a <uvmcopy>
    80001f9a:	04054863          	bltz	a0,80001fea <fork+0x8c>
  np->sz = p->sz;
    80001f9e:	048ab783          	ld	a5,72(s5)
    80001fa2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001fa6:	058ab683          	ld	a3,88(s5)
    80001faa:	87b6                	mv	a5,a3
    80001fac:	0589b703          	ld	a4,88(s3)
    80001fb0:	12068693          	addi	a3,a3,288
    80001fb4:	0007b803          	ld	a6,0(a5)
    80001fb8:	6788                	ld	a0,8(a5)
    80001fba:	6b8c                	ld	a1,16(a5)
    80001fbc:	6f90                	ld	a2,24(a5)
    80001fbe:	01073023          	sd	a6,0(a4)
    80001fc2:	e708                	sd	a0,8(a4)
    80001fc4:	eb0c                	sd	a1,16(a4)
    80001fc6:	ef10                	sd	a2,24(a4)
    80001fc8:	02078793          	addi	a5,a5,32
    80001fcc:	02070713          	addi	a4,a4,32
    80001fd0:	fed792e3          	bne	a5,a3,80001fb4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001fd4:	0589b783          	ld	a5,88(s3)
    80001fd8:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fdc:	0d0a8493          	addi	s1,s5,208
    80001fe0:	0d098913          	addi	s2,s3,208
    80001fe4:	150a8a13          	addi	s4,s5,336
    80001fe8:	a00d                	j	8000200a <fork+0xac>
    freeproc(np);
    80001fea:	854e                	mv	a0,s3
    80001fec:	00000097          	auipc	ra,0x0
    80001ff0:	d38080e7          	jalr	-712(ra) # 80001d24 <freeproc>
    release(&np->lock);
    80001ff4:	854e                	mv	a0,s3
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	c80080e7          	jalr	-896(ra) # 80000c76 <release>
    return -1;
    80001ffe:	597d                	li	s2,-1
    80002000:	a841                	j	80002090 <fork+0x132>
  for (i = 0; i < NOFILE; i++)
    80002002:	04a1                	addi	s1,s1,8
    80002004:	0921                	addi	s2,s2,8
    80002006:	01448b63          	beq	s1,s4,8000201c <fork+0xbe>
    if (p->ofile[i])
    8000200a:	6088                	ld	a0,0(s1)
    8000200c:	d97d                	beqz	a0,80002002 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000200e:	00003097          	auipc	ra,0x3
    80002012:	83c080e7          	jalr	-1988(ra) # 8000484a <filedup>
    80002016:	00a93023          	sd	a0,0(s2)
    8000201a:	b7e5                	j	80002002 <fork+0xa4>
  np->cwd = idup(p->cwd);
    8000201c:	150ab503          	ld	a0,336(s5)
    80002020:	00002097          	auipc	ra,0x2
    80002024:	9a0080e7          	jalr	-1632(ra) # 800039c0 <idup>
    80002028:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000202c:	4641                	li	a2,16
    8000202e:	158a8593          	addi	a1,s5,344
    80002032:	15898513          	addi	a0,s3,344
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	dda080e7          	jalr	-550(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    8000203e:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002042:	854e                	mv	a0,s3
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c32080e7          	jalr	-974(ra) # 80000c76 <release>
  acquire(&wait_lock);
    8000204c:	0000f497          	auipc	s1,0xf
    80002050:	69c48493          	addi	s1,s1,1692 # 800116e8 <wait_lock>
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b6c080e7          	jalr	-1172(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000205e:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c12080e7          	jalr	-1006(ra) # 80000c76 <release>
  acquire(&np->lock);
    8000206c:	854e                	mv	a0,s3
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	b54080e7          	jalr	-1196(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002076:	478d                	li	a5,3
    80002078:	00f9ac23          	sw	a5,24(s3)
  enqueue(np);  //add the process into mlq
    8000207c:	854e                	mv	a0,s3
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	78e080e7          	jalr	1934(ra) # 8000180c <enqueue>
  release(&np->lock);
    80002086:	854e                	mv	a0,s3
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	bee080e7          	jalr	-1042(ra) # 80000c76 <release>
}
    80002090:	854a                	mv	a0,s2
    80002092:	70e2                	ld	ra,56(sp)
    80002094:	7442                	ld	s0,48(sp)
    80002096:	74a2                	ld	s1,40(sp)
    80002098:	7902                	ld	s2,32(sp)
    8000209a:	69e2                	ld	s3,24(sp)
    8000209c:	6a42                	ld	s4,16(sp)
    8000209e:	6aa2                	ld	s5,8(sp)
    800020a0:	6121                	addi	sp,sp,64
    800020a2:	8082                	ret
    return -1;
    800020a4:	597d                	li	s2,-1
    800020a6:	b7ed                	j	80002090 <fork+0x132>

00000000800020a8 <scheduler>:
{
    800020a8:	7139                	addi	sp,sp,-64
    800020aa:	fc06                	sd	ra,56(sp)
    800020ac:	f822                	sd	s0,48(sp)
    800020ae:	f426                	sd	s1,40(sp)
    800020b0:	f04a                	sd	s2,32(sp)
    800020b2:	ec4e                	sd	s3,24(sp)
    800020b4:	e852                	sd	s4,16(sp)
    800020b6:	e456                	sd	s5,8(sp)
    800020b8:	0080                	addi	s0,sp,64
    800020ba:	8792                	mv	a5,tp
  int id = r_tp();
    800020bc:	2781                	sext.w	a5,a5
        swtch(&c->context, &p->context);
    800020be:	00779a13          	slli	s4,a5,0x7
    800020c2:	0000f717          	auipc	a4,0xf
    800020c6:	64670713          	addi	a4,a4,1606 # 80011708 <cpus+0x8>
    800020ca:	9a3a                	add	s4,s4,a4
      if (p->state == RUNNABLE)
    800020cc:	490d                	li	s2,3
        p->state = RUNNING;
    800020ce:	4a91                	li	s5,4
        c->proc = p;
    800020d0:	079e                	slli	a5,a5,0x7
    800020d2:	0000f997          	auipc	s3,0xf
    800020d6:	1ce98993          	addi	s3,s3,462 # 800112a0 <qtable>
    800020da:	99be                	add	s3,s3,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020e4:	10079073          	csrw	sstatus,a5
}
    800020e8:	a031                	j	800020f4 <scheduler+0x4c>
      release(&p->lock);
    800020ea:	8526                	mv	a0,s1
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	b8a080e7          	jalr	-1142(ra) # 80000c76 <release>
    while ((p = dequeue()) != 0)
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	7a8080e7          	jalr	1960(ra) # 8000189c <dequeue>
    800020fc:	84aa                	mv	s1,a0
    800020fe:	dd79                	beqz	a0,800020dc <scheduler+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ac0080e7          	jalr	-1344(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd279fe3          	bne	a5,s2,800020ea <scheduler+0x42>
        p->state = RUNNING;
    80002110:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002114:	4699b023          	sd	s1,1120(s3)
        swtch(&c->context, &p->context);
    80002118:	06048593          	addi	a1,s1,96
    8000211c:	8552                	mv	a0,s4
    8000211e:	00001097          	auipc	ra,0x1
    80002122:	802080e7          	jalr	-2046(ra) # 80002920 <swtch>
        c->proc = 0;
    80002126:	4609b023          	sd	zero,1120(s3)
    8000212a:	b7c1                	j	800020ea <scheduler+0x42>

000000008000212c <sched>:
{
    8000212c:	7179                	addi	sp,sp,-48
    8000212e:	f406                	sd	ra,40(sp)
    80002130:	f022                	sd	s0,32(sp)
    80002132:	ec26                	sd	s1,24(sp)
    80002134:	e84a                	sd	s2,16(sp)
    80002136:	e44e                	sd	s3,8(sp)
    80002138:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	a36080e7          	jalr	-1482(ra) # 80001b70 <myproc>
    80002142:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	a04080e7          	jalr	-1532(ra) # 80000b48 <holding>
    8000214c:	c93d                	beqz	a0,800021c2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000214e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002150:	2781                	sext.w	a5,a5
    80002152:	079e                	slli	a5,a5,0x7
    80002154:	0000f717          	auipc	a4,0xf
    80002158:	14c70713          	addi	a4,a4,332 # 800112a0 <qtable>
    8000215c:	97ba                	add	a5,a5,a4
    8000215e:	4d87a703          	lw	a4,1240(a5)
    80002162:	4785                	li	a5,1
    80002164:	06f71763          	bne	a4,a5,800021d2 <sched+0xa6>
  if (p->state == RUNNING)
    80002168:	4c98                	lw	a4,24(s1)
    8000216a:	4791                	li	a5,4
    8000216c:	06f70b63          	beq	a4,a5,800021e2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002170:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002174:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002176:	efb5                	bnez	a5,800021f2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002178:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000217a:	0000f917          	auipc	s2,0xf
    8000217e:	12690913          	addi	s2,s2,294 # 800112a0 <qtable>
    80002182:	2781                	sext.w	a5,a5
    80002184:	079e                	slli	a5,a5,0x7
    80002186:	97ca                	add	a5,a5,s2
    80002188:	4dc7a983          	lw	s3,1244(a5)
    8000218c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000218e:	2781                	sext.w	a5,a5
    80002190:	079e                	slli	a5,a5,0x7
    80002192:	0000f597          	auipc	a1,0xf
    80002196:	57658593          	addi	a1,a1,1398 # 80011708 <cpus+0x8>
    8000219a:	95be                	add	a1,a1,a5
    8000219c:	06048513          	addi	a0,s1,96
    800021a0:	00000097          	auipc	ra,0x0
    800021a4:	780080e7          	jalr	1920(ra) # 80002920 <swtch>
    800021a8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021aa:	2781                	sext.w	a5,a5
    800021ac:	079e                	slli	a5,a5,0x7
    800021ae:	97ca                	add	a5,a5,s2
    800021b0:	4d37ae23          	sw	s3,1244(a5)
}
    800021b4:	70a2                	ld	ra,40(sp)
    800021b6:	7402                	ld	s0,32(sp)
    800021b8:	64e2                	ld	s1,24(sp)
    800021ba:	6942                	ld	s2,16(sp)
    800021bc:	69a2                	ld	s3,8(sp)
    800021be:	6145                	addi	sp,sp,48
    800021c0:	8082                	ret
    panic("sched p->lock");
    800021c2:	00006517          	auipc	a0,0x6
    800021c6:	11e50513          	addi	a0,a0,286 # 800082e0 <digits+0x2a0>
    800021ca:	ffffe097          	auipc	ra,0xffffe
    800021ce:	360080e7          	jalr	864(ra) # 8000052a <panic>
    panic("sched locks");
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	11e50513          	addi	a0,a0,286 # 800082f0 <digits+0x2b0>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	350080e7          	jalr	848(ra) # 8000052a <panic>
    panic("sched running");
    800021e2:	00006517          	auipc	a0,0x6
    800021e6:	11e50513          	addi	a0,a0,286 # 80008300 <digits+0x2c0>
    800021ea:	ffffe097          	auipc	ra,0xffffe
    800021ee:	340080e7          	jalr	832(ra) # 8000052a <panic>
    panic("sched interruptible");
    800021f2:	00006517          	auipc	a0,0x6
    800021f6:	11e50513          	addi	a0,a0,286 # 80008310 <digits+0x2d0>
    800021fa:	ffffe097          	auipc	ra,0xffffe
    800021fe:	330080e7          	jalr	816(ra) # 8000052a <panic>

0000000080002202 <yield>:
{
    80002202:	1101                	addi	sp,sp,-32
    80002204:	ec06                	sd	ra,24(sp)
    80002206:	e822                	sd	s0,16(sp)
    80002208:	e426                	sd	s1,8(sp)
    8000220a:	e04a                	sd	s2,0(sp)
    8000220c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	962080e7          	jalr	-1694(ra) # 80001b70 <myproc>
    80002216:	84aa                	mv	s1,a0
  global_ticks++;  //increament the global ticks/
    80002218:	00007717          	auipc	a4,0x7
    8000221c:	e1870713          	addi	a4,a4,-488 # 80009030 <global_ticks>
    80002220:	431c                	lw	a5,0(a4)
    80002222:	2785                	addiw	a5,a5,1
    80002224:	c31c                	sw	a5,0(a4)
  if (global_ticks % 32 == 0)
    80002226:	8bfd                	andi	a5,a5,31
    80002228:	ebe5                	bnez	a5,80002318 <yield+0x116>
    if (Q3->next != EMPTY)
    8000222a:	0000f797          	auipc	a5,0xf
    8000222e:	49e7b783          	ld	a5,1182(a5) # 800116c8 <qtable+0x428>
    80002232:	577d                	li	a4,-1
    80002234:	04e78e63          	beq	a5,a4,80002290 <yield+0x8e>
      uint64 lQ3 = Q3->prev;
    80002238:	0000f717          	auipc	a4,0xf
    8000223c:	06870713          	addi	a4,a4,104 # 800112a0 <qtable>
    80002240:	42073583          	ld	a1,1056(a4)
      struct qentry *lq3QTable = qtable + lQ3;
    80002244:	00459693          	slli	a3,a1,0x4
    80002248:	00d70633          	add	a2,a4,a3
      struct qentry *fq3QTable = qtable + fQ3;
    8000224c:	00479693          	slli	a3,a5,0x4
    80002250:	96ba                	add	a3,a3,a4
      if (Q2->next != EMPTY)
    80002252:	41873503          	ld	a0,1048(a4)
    80002256:	577d                	li	a4,-1
    80002258:	0ee50663          	beq	a0,a4,80002344 <yield+0x142>
        uint64 lQ2 = Q2->prev;
    8000225c:	0000f717          	auipc	a4,0xf
    80002260:	04470713          	addi	a4,a4,68 # 800112a0 <qtable>
    80002264:	41073803          	ld	a6,1040(a4)
        lq2QTable->next = fQ3;  
    80002268:	00481513          	slli	a0,a6,0x4
    8000226c:	953a                	add	a0,a0,a4
    8000226e:	e51c                	sd	a5,8(a0)
        fq3QTable->prev = lQ2;
    80002270:	0106b023          	sd	a6,0(a3)
        lq3QTable->next = Q2 - qtable;
    80002274:	04100793          	li	a5,65
    80002278:	e61c                	sd	a5,8(a2)
        Q2->prev = lQ3;
    8000227a:	40b73823          	sd	a1,1040(a4)
      Q3->next = EMPTY;
    8000227e:	0000f797          	auipc	a5,0xf
    80002282:	02278793          	addi	a5,a5,34 # 800112a0 <qtable>
    80002286:	577d                	li	a4,-1
    80002288:	42e7b423          	sd	a4,1064(a5)
      Q3->prev = EMPTY;
    8000228c:	42e7b023          	sd	a4,1056(a5)
    if (Q2->next != EMPTY)
    80002290:	0000f797          	auipc	a5,0xf
    80002294:	4287b783          	ld	a5,1064(a5) # 800116b8 <qtable+0x418>
    80002298:	577d                	li	a4,-1
    8000229a:	04e78e63          	beq	a5,a4,800022f6 <yield+0xf4>
      uint64 lQ2 = Q2->prev;
    8000229e:	0000f717          	auipc	a4,0xf
    800022a2:	00270713          	addi	a4,a4,2 # 800112a0 <qtable>
    800022a6:	41073583          	ld	a1,1040(a4)
      struct qentry *lq2QTable = qtable + lQ2;
    800022aa:	00459693          	slli	a3,a1,0x4
    800022ae:	00d70633          	add	a2,a4,a3
      struct qentry *fq2QTable = qtable + fQ2;
    800022b2:	00479693          	slli	a3,a5,0x4
    800022b6:	96ba                	add	a3,a3,a4
      if (Q1->next != EMPTY)
    800022b8:	40873503          	ld	a0,1032(a4)
    800022bc:	577d                	li	a4,-1
    800022be:	0ae50063          	beq	a0,a4,8000235e <yield+0x15c>
        uint64 lQ1 = Q1->prev;
    800022c2:	0000f717          	auipc	a4,0xf
    800022c6:	fde70713          	addi	a4,a4,-34 # 800112a0 <qtable>
    800022ca:	40073803          	ld	a6,1024(a4)
        lq1QTable->next = fQ2;
    800022ce:	00481513          	slli	a0,a6,0x4
    800022d2:	953a                	add	a0,a0,a4
    800022d4:	e51c                	sd	a5,8(a0)
        fq2QTable->prev = lQ1;
    800022d6:	0106b023          	sd	a6,0(a3)
        lq2QTable->next = Q1 - qtable;
    800022da:	04000793          	li	a5,64
    800022de:	e61c                	sd	a5,8(a2)
        Q1->prev = lQ2;
    800022e0:	40b73023          	sd	a1,1024(a4)
      Q2->next = EMPTY;
    800022e4:	0000f797          	auipc	a5,0xf
    800022e8:	fbc78793          	addi	a5,a5,-68 # 800112a0 <qtable>
    800022ec:	577d                	li	a4,-1
    800022ee:	40e7bc23          	sd	a4,1048(a5)
      Q2->prev = EMPTY;
    800022f2:	40e7b823          	sd	a4,1040(a5)
{
    800022f6:	00010497          	auipc	s1,0x10
    800022fa:	80a48493          	addi	s1,s1,-2038 # 80011b00 <proc>
      p->level = 1;
    800022fe:	4705                	li	a4,1
    for (p = proc; p < &proc[NPROC]; p++)
    80002300:	00015797          	auipc	a5,0x15
    80002304:	60078793          	addi	a5,a5,1536 # 80017900 <tickslock>
      p->level = 1;
    80002308:	16e4b823          	sd	a4,368(s1)
      p->ticks = 0;
    8000230c:	1604a423          	sw	zero,360(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80002310:	17848493          	addi	s1,s1,376
    80002314:	fef49ae3          	bne	s1,a5,80002308 <yield+0x106>
  p->ticks++; 
    80002318:	1684a783          	lw	a5,360(s1)
    8000231c:	2785                	addiw	a5,a5,1
    8000231e:	0007869b          	sext.w	a3,a5
    80002322:	16f4a423          	sw	a5,360(s1)
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
    80002326:	1704b783          	ld	a5,368(s1)
    8000232a:	4705                	li	a4,1
    8000232c:	04e78963          	beq	a5,a4,8000237e <yield+0x17c>
    80002330:	4709                	li	a4,2
    80002332:	04e78363          	beq	a5,a4,80002378 <yield+0x176>
    80002336:	470d                	li	a4,3
    80002338:	08e79163          	bne	a5,a4,800023ba <yield+0x1b8>
    8000233c:	478d                	li	a5,3
    8000233e:	06d7de63          	bge	a5,a3,800023ba <yield+0x1b8>
    80002342:	a835                	j	8000237e <yield+0x17c>
        Q2->next = Q3->next;
    80002344:	0000f717          	auipc	a4,0xf
    80002348:	f5c70713          	addi	a4,a4,-164 # 800112a0 <qtable>
    8000234c:	40f73c23          	sd	a5,1048(a4)
        Q2->prev = Q3->prev;
    80002350:	40b73823          	sd	a1,1040(a4)
        lq3QTable->next = Q2 - qtable;
    80002354:	04100793          	li	a5,65
    80002358:	e61c                	sd	a5,8(a2)
        fq3QTable->prev = Q2 - qtable;
    8000235a:	e29c                	sd	a5,0(a3)
    8000235c:	b70d                	j	8000227e <yield+0x7c>
        Q1->next = Q2->next;
    8000235e:	0000f717          	auipc	a4,0xf
    80002362:	f4270713          	addi	a4,a4,-190 # 800112a0 <qtable>
    80002366:	40f73423          	sd	a5,1032(a4)
        Q1->prev = Q2->prev;
    8000236a:	40b73023          	sd	a1,1024(a4)
        lq2QTable->next = Q1 - qtable;
    8000236e:	04000793          	li	a5,64
    80002372:	e61c                	sd	a5,8(a2)
        fq2QTable->prev = Q1 - qtable;
    80002374:	e29c                	sd	a5,0(a3)
    80002376:	b7bd                	j	800022e4 <yield+0xe2>
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
    80002378:	4785                	li	a5,1
    8000237a:	04d7d063          	bge	a5,a3,800023ba <yield+0x1b8>
    acquire(&p->lock);
    8000237e:	8926                	mv	s2,s1
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	840080e7          	jalr	-1984(ra) # 80000bc2 <acquire>
    p->state = RUNNABLE;
    8000238a:	478d                	li	a5,3
    8000238c:	cc9c                	sw	a5,24(s1)
    if (p->level < 3)
    8000238e:	1704b783          	ld	a5,368(s1)
    80002392:	4709                	li	a4,2
    80002394:	00f76563          	bltu	a4,a5,8000239e <yield+0x19c>
      p->level++; //increment the level of process
    80002398:	0785                	addi	a5,a5,1
    8000239a:	16f4b823          	sd	a5,368(s1)
    enqueue(p);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	46c080e7          	jalr	1132(ra) # 8000180c <enqueue>
    sched();
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	d84080e7          	jalr	-636(ra) # 8000212c <sched>
    release(&p->lock);
    800023b0:	854a                	mv	a0,s2
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	8c4080e7          	jalr	-1852(ra) # 80000c76 <release>
}
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6902                	ld	s2,0(sp)
    800023c2:	6105                	addi	sp,sp,32
    800023c4:	8082                	ret

00000000800023c6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023c6:	7179                	addi	sp,sp,-48
    800023c8:	f406                	sd	ra,40(sp)
    800023ca:	f022                	sd	s0,32(sp)
    800023cc:	ec26                	sd	s1,24(sp)
    800023ce:	e84a                	sd	s2,16(sp)
    800023d0:	e44e                	sd	s3,8(sp)
    800023d2:	1800                	addi	s0,sp,48
    800023d4:	89aa                	mv	s3,a0
    800023d6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	798080e7          	jalr	1944(ra) # 80001b70 <myproc>
    800023e0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	7e0080e7          	jalr	2016(ra) # 80000bc2 <acquire>
  release(lk);
    800023ea:	854a                	mv	a0,s2
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	88a080e7          	jalr	-1910(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800023f4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023f8:	4789                	li	a5,2
    800023fa:	cc9c                	sw	a5,24(s1)

  sched();
    800023fc:	00000097          	auipc	ra,0x0
    80002400:	d30080e7          	jalr	-720(ra) # 8000212c <sched>

  // Tidy up.
  p->chan = 0;
    80002404:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	86c080e7          	jalr	-1940(ra) # 80000c76 <release>
  acquire(lk);
    80002412:	854a                	mv	a0,s2
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7ae080e7          	jalr	1966(ra) # 80000bc2 <acquire>
}
    8000241c:	70a2                	ld	ra,40(sp)
    8000241e:	7402                	ld	s0,32(sp)
    80002420:	64e2                	ld	s1,24(sp)
    80002422:	6942                	ld	s2,16(sp)
    80002424:	69a2                	ld	s3,8(sp)
    80002426:	6145                	addi	sp,sp,48
    80002428:	8082                	ret

000000008000242a <wait>:
{
    8000242a:	715d                	addi	sp,sp,-80
    8000242c:	e486                	sd	ra,72(sp)
    8000242e:	e0a2                	sd	s0,64(sp)
    80002430:	fc26                	sd	s1,56(sp)
    80002432:	f84a                	sd	s2,48(sp)
    80002434:	f44e                	sd	s3,40(sp)
    80002436:	f052                	sd	s4,32(sp)
    80002438:	ec56                	sd	s5,24(sp)
    8000243a:	e85a                	sd	s6,16(sp)
    8000243c:	e45e                	sd	s7,8(sp)
    8000243e:	e062                	sd	s8,0(sp)
    80002440:	0880                	addi	s0,sp,80
    80002442:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	72c080e7          	jalr	1836(ra) # 80001b70 <myproc>
    8000244c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000244e:	0000f517          	auipc	a0,0xf
    80002452:	29a50513          	addi	a0,a0,666 # 800116e8 <wait_lock>
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	76c080e7          	jalr	1900(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000245e:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002460:	4a15                	li	s4,5
        havekids = 1;
    80002462:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002464:	00015997          	auipc	s3,0x15
    80002468:	49c98993          	addi	s3,s3,1180 # 80017900 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000246c:	0000fc17          	auipc	s8,0xf
    80002470:	27cc0c13          	addi	s8,s8,636 # 800116e8 <wait_lock>
    havekids = 0;
    80002474:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002476:	0000f497          	auipc	s1,0xf
    8000247a:	68a48493          	addi	s1,s1,1674 # 80011b00 <proc>
    8000247e:	a0bd                	j	800024ec <wait+0xc2>
          pid = np->pid;
    80002480:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002484:	000b0e63          	beqz	s6,800024a0 <wait+0x76>
    80002488:	4691                	li	a3,4
    8000248a:	02c48613          	addi	a2,s1,44
    8000248e:	85da                	mv	a1,s6
    80002490:	05093503          	ld	a0,80(s2)
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	1aa080e7          	jalr	426(ra) # 8000163e <copyout>
    8000249c:	02054563          	bltz	a0,800024c6 <wait+0x9c>
          freeproc(np);
    800024a0:	8526                	mv	a0,s1
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	882080e7          	jalr	-1918(ra) # 80001d24 <freeproc>
          release(&np->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7ca080e7          	jalr	1994(ra) # 80000c76 <release>
          release(&wait_lock);
    800024b4:	0000f517          	auipc	a0,0xf
    800024b8:	23450513          	addi	a0,a0,564 # 800116e8 <wait_lock>
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7ba080e7          	jalr	1978(ra) # 80000c76 <release>
          return pid;
    800024c4:	a09d                	j	8000252a <wait+0x100>
            release(&np->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7ae080e7          	jalr	1966(ra) # 80000c76 <release>
            release(&wait_lock);
    800024d0:	0000f517          	auipc	a0,0xf
    800024d4:	21850513          	addi	a0,a0,536 # 800116e8 <wait_lock>
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	79e080e7          	jalr	1950(ra) # 80000c76 <release>
            return -1;
    800024e0:	59fd                	li	s3,-1
    800024e2:	a0a1                	j	8000252a <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800024e4:	17848493          	addi	s1,s1,376
    800024e8:	03348463          	beq	s1,s3,80002510 <wait+0xe6>
      if (np->parent == p)
    800024ec:	7c9c                	ld	a5,56(s1)
    800024ee:	ff279be3          	bne	a5,s2,800024e4 <wait+0xba>
        acquire(&np->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	6ce080e7          	jalr	1742(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    800024fc:	4c9c                	lw	a5,24(s1)
    800024fe:	f94781e3          	beq	a5,s4,80002480 <wait+0x56>
        release(&np->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	772080e7          	jalr	1906(ra) # 80000c76 <release>
        havekids = 1;
    8000250c:	8756                	mv	a4,s5
    8000250e:	bfd9                	j	800024e4 <wait+0xba>
    if (!havekids || p->killed)
    80002510:	c701                	beqz	a4,80002518 <wait+0xee>
    80002512:	02892783          	lw	a5,40(s2)
    80002516:	c79d                	beqz	a5,80002544 <wait+0x11a>
      release(&wait_lock);
    80002518:	0000f517          	auipc	a0,0xf
    8000251c:	1d050513          	addi	a0,a0,464 # 800116e8 <wait_lock>
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	756080e7          	jalr	1878(ra) # 80000c76 <release>
      return -1;
    80002528:	59fd                	li	s3,-1
}
    8000252a:	854e                	mv	a0,s3
    8000252c:	60a6                	ld	ra,72(sp)
    8000252e:	6406                	ld	s0,64(sp)
    80002530:	74e2                	ld	s1,56(sp)
    80002532:	7942                	ld	s2,48(sp)
    80002534:	79a2                	ld	s3,40(sp)
    80002536:	7a02                	ld	s4,32(sp)
    80002538:	6ae2                	ld	s5,24(sp)
    8000253a:	6b42                	ld	s6,16(sp)
    8000253c:	6ba2                	ld	s7,8(sp)
    8000253e:	6c02                	ld	s8,0(sp)
    80002540:	6161                	addi	sp,sp,80
    80002542:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002544:	85e2                	mv	a1,s8
    80002546:	854a                	mv	a0,s2
    80002548:	00000097          	auipc	ra,0x0
    8000254c:	e7e080e7          	jalr	-386(ra) # 800023c6 <sleep>
    havekids = 0;
    80002550:	b715                	j	80002474 <wait+0x4a>

0000000080002552 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002552:	7139                	addi	sp,sp,-64
    80002554:	fc06                	sd	ra,56(sp)
    80002556:	f822                	sd	s0,48(sp)
    80002558:	f426                	sd	s1,40(sp)
    8000255a:	f04a                	sd	s2,32(sp)
    8000255c:	ec4e                	sd	s3,24(sp)
    8000255e:	e852                	sd	s4,16(sp)
    80002560:	e456                	sd	s5,8(sp)
    80002562:	0080                	addi	s0,sp,64
    80002564:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002566:	0000f497          	auipc	s1,0xf
    8000256a:	59a48493          	addi	s1,s1,1434 # 80011b00 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000256e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002570:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002572:	00015917          	auipc	s2,0x15
    80002576:	38e90913          	addi	s2,s2,910 # 80017900 <tickslock>
    8000257a:	a811                	j	8000258e <wakeup+0x3c>
        //Leyuan & Lee
        enqueue(p);   // add process to mlq
      }
      release(&p->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	6f8080e7          	jalr	1784(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002586:	17848493          	addi	s1,s1,376
    8000258a:	03248b63          	beq	s1,s2,800025c0 <wakeup+0x6e>
    if (p != myproc())
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	5e2080e7          	jalr	1506(ra) # 80001b70 <myproc>
    80002596:	fea488e3          	beq	s1,a0,80002586 <wakeup+0x34>
      acquire(&p->lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	626080e7          	jalr	1574(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800025a4:	4c9c                	lw	a5,24(s1)
    800025a6:	fd379be3          	bne	a5,s3,8000257c <wakeup+0x2a>
    800025aa:	709c                	ld	a5,32(s1)
    800025ac:	fd4798e3          	bne	a5,s4,8000257c <wakeup+0x2a>
        p->state = RUNNABLE;
    800025b0:	0154ac23          	sw	s5,24(s1)
        enqueue(p);   // add process to mlq
    800025b4:	8526                	mv	a0,s1
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	256080e7          	jalr	598(ra) # 8000180c <enqueue>
    800025be:	bf7d                	j	8000257c <wakeup+0x2a>
    }
  }
}
    800025c0:	70e2                	ld	ra,56(sp)
    800025c2:	7442                	ld	s0,48(sp)
    800025c4:	74a2                	ld	s1,40(sp)
    800025c6:	7902                	ld	s2,32(sp)
    800025c8:	69e2                	ld	s3,24(sp)
    800025ca:	6a42                	ld	s4,16(sp)
    800025cc:	6aa2                	ld	s5,8(sp)
    800025ce:	6121                	addi	sp,sp,64
    800025d0:	8082                	ret

00000000800025d2 <reparent>:
{
    800025d2:	7179                	addi	sp,sp,-48
    800025d4:	f406                	sd	ra,40(sp)
    800025d6:	f022                	sd	s0,32(sp)
    800025d8:	ec26                	sd	s1,24(sp)
    800025da:	e84a                	sd	s2,16(sp)
    800025dc:	e44e                	sd	s3,8(sp)
    800025de:	e052                	sd	s4,0(sp)
    800025e0:	1800                	addi	s0,sp,48
    800025e2:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025e4:	0000f497          	auipc	s1,0xf
    800025e8:	51c48493          	addi	s1,s1,1308 # 80011b00 <proc>
      pp->parent = initproc;
    800025ec:	00007a17          	auipc	s4,0x7
    800025f0:	a3ca0a13          	addi	s4,s4,-1476 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025f4:	00015997          	auipc	s3,0x15
    800025f8:	30c98993          	addi	s3,s3,780 # 80017900 <tickslock>
    800025fc:	a029                	j	80002606 <reparent+0x34>
    800025fe:	17848493          	addi	s1,s1,376
    80002602:	01348d63          	beq	s1,s3,8000261c <reparent+0x4a>
    if (pp->parent == p)
    80002606:	7c9c                	ld	a5,56(s1)
    80002608:	ff279be3          	bne	a5,s2,800025fe <reparent+0x2c>
      pp->parent = initproc;
    8000260c:	000a3503          	ld	a0,0(s4)
    80002610:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002612:	00000097          	auipc	ra,0x0
    80002616:	f40080e7          	jalr	-192(ra) # 80002552 <wakeup>
    8000261a:	b7d5                	j	800025fe <reparent+0x2c>
}
    8000261c:	70a2                	ld	ra,40(sp)
    8000261e:	7402                	ld	s0,32(sp)
    80002620:	64e2                	ld	s1,24(sp)
    80002622:	6942                	ld	s2,16(sp)
    80002624:	69a2                	ld	s3,8(sp)
    80002626:	6a02                	ld	s4,0(sp)
    80002628:	6145                	addi	sp,sp,48
    8000262a:	8082                	ret

000000008000262c <exit>:
{
    8000262c:	7179                	addi	sp,sp,-48
    8000262e:	f406                	sd	ra,40(sp)
    80002630:	f022                	sd	s0,32(sp)
    80002632:	ec26                	sd	s1,24(sp)
    80002634:	e84a                	sd	s2,16(sp)
    80002636:	e44e                	sd	s3,8(sp)
    80002638:	e052                	sd	s4,0(sp)
    8000263a:	1800                	addi	s0,sp,48
    8000263c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	532080e7          	jalr	1330(ra) # 80001b70 <myproc>
    80002646:	89aa                	mv	s3,a0
  if (p == initproc)
    80002648:	00007797          	auipc	a5,0x7
    8000264c:	9e07b783          	ld	a5,-1568(a5) # 80009028 <initproc>
    80002650:	0d050493          	addi	s1,a0,208
    80002654:	15050913          	addi	s2,a0,336
    80002658:	02a79363          	bne	a5,a0,8000267e <exit+0x52>
    panic("init exiting");
    8000265c:	00006517          	auipc	a0,0x6
    80002660:	ccc50513          	addi	a0,a0,-820 # 80008328 <digits+0x2e8>
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	ec6080e7          	jalr	-314(ra) # 8000052a <panic>
      fileclose(f);
    8000266c:	00002097          	auipc	ra,0x2
    80002670:	230080e7          	jalr	560(ra) # 8000489c <fileclose>
      p->ofile[fd] = 0;
    80002674:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002678:	04a1                	addi	s1,s1,8
    8000267a:	01248563          	beq	s1,s2,80002684 <exit+0x58>
    if (p->ofile[fd])
    8000267e:	6088                	ld	a0,0(s1)
    80002680:	f575                	bnez	a0,8000266c <exit+0x40>
    80002682:	bfdd                	j	80002678 <exit+0x4c>
  begin_op();
    80002684:	00002097          	auipc	ra,0x2
    80002688:	d4c080e7          	jalr	-692(ra) # 800043d0 <begin_op>
  iput(p->cwd);
    8000268c:	1509b503          	ld	a0,336(s3)
    80002690:	00001097          	auipc	ra,0x1
    80002694:	528080e7          	jalr	1320(ra) # 80003bb8 <iput>
  end_op();
    80002698:	00002097          	auipc	ra,0x2
    8000269c:	db8080e7          	jalr	-584(ra) # 80004450 <end_op>
  p->cwd = 0;
    800026a0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026a4:	0000f497          	auipc	s1,0xf
    800026a8:	04448493          	addi	s1,s1,68 # 800116e8 <wait_lock>
    800026ac:	8526                	mv	a0,s1
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	514080e7          	jalr	1300(ra) # 80000bc2 <acquire>
  reparent(p);
    800026b6:	854e                	mv	a0,s3
    800026b8:	00000097          	auipc	ra,0x0
    800026bc:	f1a080e7          	jalr	-230(ra) # 800025d2 <reparent>
  wakeup(p->parent);
    800026c0:	0389b503          	ld	a0,56(s3)
    800026c4:	00000097          	auipc	ra,0x0
    800026c8:	e8e080e7          	jalr	-370(ra) # 80002552 <wakeup>
  acquire(&p->lock);
    800026cc:	854e                	mv	a0,s3
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	4f4080e7          	jalr	1268(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800026d6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026da:	4795                	li	a5,5
    800026dc:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800026e0:	8526                	mv	a0,s1
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	594080e7          	jalr	1428(ra) # 80000c76 <release>
  sched();
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	a42080e7          	jalr	-1470(ra) # 8000212c <sched>
  panic("zombie exit");
    800026f2:	00006517          	auipc	a0,0x6
    800026f6:	c4650513          	addi	a0,a0,-954 # 80008338 <digits+0x2f8>
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	e30080e7          	jalr	-464(ra) # 8000052a <panic>

0000000080002702 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002702:	7179                	addi	sp,sp,-48
    80002704:	f406                	sd	ra,40(sp)
    80002706:	f022                	sd	s0,32(sp)
    80002708:	ec26                	sd	s1,24(sp)
    8000270a:	e84a                	sd	s2,16(sp)
    8000270c:	e44e                	sd	s3,8(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002712:	0000f497          	auipc	s1,0xf
    80002716:	3ee48493          	addi	s1,s1,1006 # 80011b00 <proc>
    8000271a:	00015997          	auipc	s3,0x15
    8000271e:	1e698993          	addi	s3,s3,486 # 80017900 <tickslock>
  {
    acquire(&p->lock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	49e080e7          	jalr	1182(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    8000272c:	589c                	lw	a5,48(s1)
    8000272e:	01278d63          	beq	a5,s2,80002748 <kill+0x46>
        enqueue(p);   //add process to mlq
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	542080e7          	jalr	1346(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000273c:	17848493          	addi	s1,s1,376
    80002740:	ff3491e3          	bne	s1,s3,80002722 <kill+0x20>
  }
  return -1;
    80002744:	557d                	li	a0,-1
    80002746:	a829                	j	80002760 <kill+0x5e>
      p->killed = 1;
    80002748:	4785                	li	a5,1
    8000274a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000274c:	4c98                	lw	a4,24(s1)
    8000274e:	4789                	li	a5,2
    80002750:	00f70f63          	beq	a4,a5,8000276e <kill+0x6c>
      release(&p->lock);
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	520080e7          	jalr	1312(ra) # 80000c76 <release>
      return 0;
    8000275e:	4501                	li	a0,0
}
    80002760:	70a2                	ld	ra,40(sp)
    80002762:	7402                	ld	s0,32(sp)
    80002764:	64e2                	ld	s1,24(sp)
    80002766:	6942                	ld	s2,16(sp)
    80002768:	69a2                	ld	s3,8(sp)
    8000276a:	6145                	addi	sp,sp,48
    8000276c:	8082                	ret
        p->state = RUNNABLE;
    8000276e:	478d                	li	a5,3
    80002770:	cc9c                	sw	a5,24(s1)
        enqueue(p);   //add process to mlq
    80002772:	8526                	mv	a0,s1
    80002774:	fffff097          	auipc	ra,0xfffff
    80002778:	098080e7          	jalr	152(ra) # 8000180c <enqueue>
    8000277c:	bfe1                	j	80002754 <kill+0x52>

000000008000277e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000277e:	7179                	addi	sp,sp,-48
    80002780:	f406                	sd	ra,40(sp)
    80002782:	f022                	sd	s0,32(sp)
    80002784:	ec26                	sd	s1,24(sp)
    80002786:	e84a                	sd	s2,16(sp)
    80002788:	e44e                	sd	s3,8(sp)
    8000278a:	e052                	sd	s4,0(sp)
    8000278c:	1800                	addi	s0,sp,48
    8000278e:	84aa                	mv	s1,a0
    80002790:	892e                	mv	s2,a1
    80002792:	89b2                	mv	s3,a2
    80002794:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	3da080e7          	jalr	986(ra) # 80001b70 <myproc>
  if (user_dst)
    8000279e:	c08d                	beqz	s1,800027c0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027a0:	86d2                	mv	a3,s4
    800027a2:	864e                	mv	a2,s3
    800027a4:	85ca                	mv	a1,s2
    800027a6:	6928                	ld	a0,80(a0)
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	e96080e7          	jalr	-362(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027b0:	70a2                	ld	ra,40(sp)
    800027b2:	7402                	ld	s0,32(sp)
    800027b4:	64e2                	ld	s1,24(sp)
    800027b6:	6942                	ld	s2,16(sp)
    800027b8:	69a2                	ld	s3,8(sp)
    800027ba:	6a02                	ld	s4,0(sp)
    800027bc:	6145                	addi	sp,sp,48
    800027be:	8082                	ret
    memmove((char *)dst, src, len);
    800027c0:	000a061b          	sext.w	a2,s4
    800027c4:	85ce                	mv	a1,s3
    800027c6:	854a                	mv	a0,s2
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	552080e7          	jalr	1362(ra) # 80000d1a <memmove>
    return 0;
    800027d0:	8526                	mv	a0,s1
    800027d2:	bff9                	j	800027b0 <either_copyout+0x32>

00000000800027d4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d4:	7179                	addi	sp,sp,-48
    800027d6:	f406                	sd	ra,40(sp)
    800027d8:	f022                	sd	s0,32(sp)
    800027da:	ec26                	sd	s1,24(sp)
    800027dc:	e84a                	sd	s2,16(sp)
    800027de:	e44e                	sd	s3,8(sp)
    800027e0:	e052                	sd	s4,0(sp)
    800027e2:	1800                	addi	s0,sp,48
    800027e4:	892a                	mv	s2,a0
    800027e6:	84ae                	mv	s1,a1
    800027e8:	89b2                	mv	s3,a2
    800027ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	384080e7          	jalr	900(ra) # 80001b70 <myproc>
  if (user_src)
    800027f4:	c08d                	beqz	s1,80002816 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027f6:	86d2                	mv	a3,s4
    800027f8:	864e                	mv	a2,s3
    800027fa:	85ca                	mv	a1,s2
    800027fc:	6928                	ld	a0,80(a0)
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	ecc080e7          	jalr	-308(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002806:	70a2                	ld	ra,40(sp)
    80002808:	7402                	ld	s0,32(sp)
    8000280a:	64e2                	ld	s1,24(sp)
    8000280c:	6942                	ld	s2,16(sp)
    8000280e:	69a2                	ld	s3,8(sp)
    80002810:	6a02                	ld	s4,0(sp)
    80002812:	6145                	addi	sp,sp,48
    80002814:	8082                	ret
    memmove(dst, (char *)src, len);
    80002816:	000a061b          	sext.w	a2,s4
    8000281a:	85ce                	mv	a1,s3
    8000281c:	854a                	mv	a0,s2
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	4fc080e7          	jalr	1276(ra) # 80000d1a <memmove>
    return 0;
    80002826:	8526                	mv	a0,s1
    80002828:	bff9                	j	80002806 <either_copyin+0x32>

000000008000282a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000282a:	715d                	addi	sp,sp,-80
    8000282c:	e486                	sd	ra,72(sp)
    8000282e:	e0a2                	sd	s0,64(sp)
    80002830:	fc26                	sd	s1,56(sp)
    80002832:	f84a                	sd	s2,48(sp)
    80002834:	f44e                	sd	s3,40(sp)
    80002836:	f052                	sd	s4,32(sp)
    80002838:	ec56                	sd	s5,24(sp)
    8000283a:	e85a                	sd	s6,16(sp)
    8000283c:	e45e                	sd	s7,8(sp)
    8000283e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002840:	00006517          	auipc	a0,0x6
    80002844:	88850513          	addi	a0,a0,-1912 # 800080c8 <digits+0x88>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d2c080e7          	jalr	-724(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002850:	0000f497          	auipc	s1,0xf
    80002854:	40848493          	addi	s1,s1,1032 # 80011c58 <proc+0x158>
    80002858:	00015917          	auipc	s2,0x15
    8000285c:	20090913          	addi	s2,s2,512 # 80017a58 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002860:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002862:	00006997          	auipc	s3,0x6
    80002866:	ae698993          	addi	s3,s3,-1306 # 80008348 <digits+0x308>
    printf("%d %s %s", p->pid, state, p->name);
    8000286a:	00006a97          	auipc	s5,0x6
    8000286e:	ae6a8a93          	addi	s5,s5,-1306 # 80008350 <digits+0x310>
    printf("\n");
    80002872:	00006a17          	auipc	s4,0x6
    80002876:	856a0a13          	addi	s4,s4,-1962 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287a:	00006b97          	auipc	s7,0x6
    8000287e:	b0eb8b93          	addi	s7,s7,-1266 # 80008388 <states.0>
    80002882:	a00d                	j	800028a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002884:	ed86a583          	lw	a1,-296(a3)
    80002888:	8556                	mv	a0,s5
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cea080e7          	jalr	-790(ra) # 80000574 <printf>
    printf("\n");
    80002892:	8552                	mv	a0,s4
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	ce0080e7          	jalr	-800(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000289c:	17848493          	addi	s1,s1,376
    800028a0:	03248163          	beq	s1,s2,800028c2 <procdump+0x98>
    if (p->state == UNUSED)
    800028a4:	86a6                	mv	a3,s1
    800028a6:	ec04a783          	lw	a5,-320(s1)
    800028aa:	dbed                	beqz	a5,8000289c <procdump+0x72>
      state = "???";
    800028ac:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ae:	fcfb6be3          	bltu	s6,a5,80002884 <procdump+0x5a>
    800028b2:	1782                	slli	a5,a5,0x20
    800028b4:	9381                	srli	a5,a5,0x20
    800028b6:	078e                	slli	a5,a5,0x3
    800028b8:	97de                	add	a5,a5,s7
    800028ba:	6390                	ld	a2,0(a5)
    800028bc:	f661                	bnez	a2,80002884 <procdump+0x5a>
      state = "???";
    800028be:	864e                	mv	a2,s3
    800028c0:	b7d1                	j	80002884 <procdump+0x5a>
  }
}
    800028c2:	60a6                	ld	ra,72(sp)
    800028c4:	6406                	ld	s0,64(sp)
    800028c6:	74e2                	ld	s1,56(sp)
    800028c8:	7942                	ld	s2,48(sp)
    800028ca:	79a2                	ld	s3,40(sp)
    800028cc:	7a02                	ld	s4,32(sp)
    800028ce:	6ae2                	ld	s5,24(sp)
    800028d0:	6b42                	ld	s6,16(sp)
    800028d2:	6ba2                	ld	s7,8(sp)
    800028d4:	6161                	addi	sp,sp,80
    800028d6:	8082                	ret

00000000800028d8 <kgetpstat>:
/*
*@Author: Leyuan & Lee
*A helper function to send usefull information to the user side.
*/
uint64 kgetpstat(struct pstat *ps)
{
    800028d8:	1141                	addi	sp,sp,-16
    800028da:	e422                	sd	s0,8(sp)
    800028dc:	0800                	addi	s0,sp,16
  for (int i = 0; i < NPROC; ++i)
    800028de:	0000f797          	auipc	a5,0xf
    800028e2:	23a78793          	addi	a5,a5,570 # 80011b18 <proc+0x18>
    800028e6:	00015697          	auipc	a3,0x15
    800028ea:	03268693          	addi	a3,a3,50 # 80017918 <bcache>
  {
    struct proc *p = proc + i;
    ps->inuse[i] = p->state == UNUSED ? 0 : 1;
    800028ee:	4398                	lw	a4,0(a5)
    800028f0:	00e03733          	snez	a4,a4
    800028f4:	c118                	sw	a4,0(a0)
    ps->ticks[i] = p->ticks;
    800028f6:	1507a703          	lw	a4,336(a5)
    800028fa:	20e52023          	sw	a4,512(a0)
    ps->pid[i] = p->pid;
    800028fe:	4f98                	lw	a4,24(a5)
    80002900:	10e52023          	sw	a4,256(a0)
    ps->queue[i] = p->level - 1;
    80002904:	1587b703          	ld	a4,344(a5)
    80002908:	377d                	addiw	a4,a4,-1
    8000290a:	30e52023          	sw	a4,768(a0)
  for (int i = 0; i < NPROC; ++i)
    8000290e:	17878793          	addi	a5,a5,376
    80002912:	0511                	addi	a0,a0,4
    80002914:	fcd79de3          	bne	a5,a3,800028ee <kgetpstat+0x16>
  }
  return 0;
    80002918:	4501                	li	a0,0
    8000291a:	6422                	ld	s0,8(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret

0000000080002920 <swtch>:
    80002920:	00153023          	sd	ra,0(a0)
    80002924:	00253423          	sd	sp,8(a0)
    80002928:	e900                	sd	s0,16(a0)
    8000292a:	ed04                	sd	s1,24(a0)
    8000292c:	03253023          	sd	s2,32(a0)
    80002930:	03353423          	sd	s3,40(a0)
    80002934:	03453823          	sd	s4,48(a0)
    80002938:	03553c23          	sd	s5,56(a0)
    8000293c:	05653023          	sd	s6,64(a0)
    80002940:	05753423          	sd	s7,72(a0)
    80002944:	05853823          	sd	s8,80(a0)
    80002948:	05953c23          	sd	s9,88(a0)
    8000294c:	07a53023          	sd	s10,96(a0)
    80002950:	07b53423          	sd	s11,104(a0)
    80002954:	0005b083          	ld	ra,0(a1)
    80002958:	0085b103          	ld	sp,8(a1)
    8000295c:	6980                	ld	s0,16(a1)
    8000295e:	6d84                	ld	s1,24(a1)
    80002960:	0205b903          	ld	s2,32(a1)
    80002964:	0285b983          	ld	s3,40(a1)
    80002968:	0305ba03          	ld	s4,48(a1)
    8000296c:	0385ba83          	ld	s5,56(a1)
    80002970:	0405bb03          	ld	s6,64(a1)
    80002974:	0485bb83          	ld	s7,72(a1)
    80002978:	0505bc03          	ld	s8,80(a1)
    8000297c:	0585bc83          	ld	s9,88(a1)
    80002980:	0605bd03          	ld	s10,96(a1)
    80002984:	0685bd83          	ld	s11,104(a1)
    80002988:	8082                	ret

000000008000298a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000298a:	1141                	addi	sp,sp,-16
    8000298c:	e406                	sd	ra,8(sp)
    8000298e:	e022                	sd	s0,0(sp)
    80002990:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002992:	00006597          	auipc	a1,0x6
    80002996:	a2658593          	addi	a1,a1,-1498 # 800083b8 <states.0+0x30>
    8000299a:	00015517          	auipc	a0,0x15
    8000299e:	f6650513          	addi	a0,a0,-154 # 80017900 <tickslock>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	190080e7          	jalr	400(ra) # 80000b32 <initlock>
}
    800029aa:	60a2                	ld	ra,8(sp)
    800029ac:	6402                	ld	s0,0(sp)
    800029ae:	0141                	addi	sp,sp,16
    800029b0:	8082                	ret

00000000800029b2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029b2:	1141                	addi	sp,sp,-16
    800029b4:	e422                	sd	s0,8(sp)
    800029b6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b8:	00003797          	auipc	a5,0x3
    800029bc:	50878793          	addi	a5,a5,1288 # 80005ec0 <kernelvec>
    800029c0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029c4:	6422                	ld	s0,8(sp)
    800029c6:	0141                	addi	sp,sp,16
    800029c8:	8082                	ret

00000000800029ca <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029ca:	1141                	addi	sp,sp,-16
    800029cc:	e406                	sd	ra,8(sp)
    800029ce:	e022                	sd	s0,0(sp)
    800029d0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	19e080e7          	jalr	414(ra) # 80001b70 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029da:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029de:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029e4:	00004617          	auipc	a2,0x4
    800029e8:	61c60613          	addi	a2,a2,1564 # 80007000 <_trampoline>
    800029ec:	00004697          	auipc	a3,0x4
    800029f0:	61468693          	addi	a3,a3,1556 # 80007000 <_trampoline>
    800029f4:	8e91                	sub	a3,a3,a2
    800029f6:	040007b7          	lui	a5,0x4000
    800029fa:	17fd                	addi	a5,a5,-1
    800029fc:	07b2                	slli	a5,a5,0xc
    800029fe:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a00:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a04:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a06:	180026f3          	csrr	a3,satp
    80002a0a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a0c:	6d38                	ld	a4,88(a0)
    80002a0e:	6134                	ld	a3,64(a0)
    80002a10:	6585                	lui	a1,0x1
    80002a12:	96ae                	add	a3,a3,a1
    80002a14:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a16:	6d38                	ld	a4,88(a0)
    80002a18:	00000697          	auipc	a3,0x0
    80002a1c:	13868693          	addi	a3,a3,312 # 80002b50 <usertrap>
    80002a20:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a22:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a24:	8692                	mv	a3,tp
    80002a26:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a28:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a2c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a30:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a34:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a38:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a3a:	6f18                	ld	a4,24(a4)
    80002a3c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a40:	692c                	ld	a1,80(a0)
    80002a42:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a44:	00004717          	auipc	a4,0x4
    80002a48:	64c70713          	addi	a4,a4,1612 # 80007090 <userret>
    80002a4c:	8f11                	sub	a4,a4,a2
    80002a4e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a50:	577d                	li	a4,-1
    80002a52:	177e                	slli	a4,a4,0x3f
    80002a54:	8dd9                	or	a1,a1,a4
    80002a56:	02000537          	lui	a0,0x2000
    80002a5a:	157d                	addi	a0,a0,-1
    80002a5c:	0536                	slli	a0,a0,0xd
    80002a5e:	9782                	jalr	a5
}
    80002a60:	60a2                	ld	ra,8(sp)
    80002a62:	6402                	ld	s0,0(sp)
    80002a64:	0141                	addi	sp,sp,16
    80002a66:	8082                	ret

0000000080002a68 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a68:	1101                	addi	sp,sp,-32
    80002a6a:	ec06                	sd	ra,24(sp)
    80002a6c:	e822                	sd	s0,16(sp)
    80002a6e:	e426                	sd	s1,8(sp)
    80002a70:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a72:	00015497          	auipc	s1,0x15
    80002a76:	e8e48493          	addi	s1,s1,-370 # 80017900 <tickslock>
    80002a7a:	8526                	mv	a0,s1
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	146080e7          	jalr	326(ra) # 80000bc2 <acquire>
  ticks++;
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	5b050513          	addi	a0,a0,1456 # 80009034 <ticks>
    80002a8c:	411c                	lw	a5,0(a0)
    80002a8e:	2785                	addiw	a5,a5,1
    80002a90:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	ac0080e7          	jalr	-1344(ra) # 80002552 <wakeup>
  release(&tickslock);
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	1da080e7          	jalr	474(ra) # 80000c76 <release>
}
    80002aa4:	60e2                	ld	ra,24(sp)
    80002aa6:	6442                	ld	s0,16(sp)
    80002aa8:	64a2                	ld	s1,8(sp)
    80002aaa:	6105                	addi	sp,sp,32
    80002aac:	8082                	ret

0000000080002aae <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002abc:	00074d63          	bltz	a4,80002ad6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ac0:	57fd                	li	a5,-1
    80002ac2:	17fe                	slli	a5,a5,0x3f
    80002ac4:	0785                	addi	a5,a5,1
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    
    return 0;
    80002ac6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ac8:	06f70363          	beq	a4,a5,80002b2e <devintr+0x80>
  }
}
    80002acc:	60e2                	ld	ra,24(sp)
    80002ace:	6442                	ld	s0,16(sp)
    80002ad0:	64a2                	ld	s1,8(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret
     (scause & 0xff) == 9){
    80002ad6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ada:	46a5                	li	a3,9
    80002adc:	fed792e3          	bne	a5,a3,80002ac0 <devintr+0x12>
    int irq = plic_claim();
    80002ae0:	00003097          	auipc	ra,0x3
    80002ae4:	4e8080e7          	jalr	1256(ra) # 80005fc8 <plic_claim>
    80002ae8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aea:	47a9                	li	a5,10
    80002aec:	02f50763          	beq	a0,a5,80002b1a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002af0:	4785                	li	a5,1
    80002af2:	02f50963          	beq	a0,a5,80002b24 <devintr+0x76>
    return 1;
    80002af6:	4505                	li	a0,1
    } else if(irq){
    80002af8:	d8f1                	beqz	s1,80002acc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002afa:	85a6                	mv	a1,s1
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	8c450513          	addi	a0,a0,-1852 # 800083c0 <states.0+0x38>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a70080e7          	jalr	-1424(ra) # 80000574 <printf>
      plic_complete(irq);
    80002b0c:	8526                	mv	a0,s1
    80002b0e:	00003097          	auipc	ra,0x3
    80002b12:	4de080e7          	jalr	1246(ra) # 80005fec <plic_complete>
    return 1;
    80002b16:	4505                	li	a0,1
    80002b18:	bf55                	j	80002acc <devintr+0x1e>
      uartintr();
    80002b1a:	ffffe097          	auipc	ra,0xffffe
    80002b1e:	e6c080e7          	jalr	-404(ra) # 80000986 <uartintr>
    80002b22:	b7ed                	j	80002b0c <devintr+0x5e>
      virtio_disk_intr();
    80002b24:	00004097          	auipc	ra,0x4
    80002b28:	95a080e7          	jalr	-1702(ra) # 8000647e <virtio_disk_intr>
    80002b2c:	b7c5                	j	80002b0c <devintr+0x5e>
    if(cpuid() == 0){
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	016080e7          	jalr	22(ra) # 80001b44 <cpuid>
    80002b36:	c901                	beqz	a0,80002b46 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b38:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b3c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b3e:	14479073          	csrw	sip,a5
    return 2;
    80002b42:	4509                	li	a0,2
    80002b44:	b761                	j	80002acc <devintr+0x1e>
      clockintr();
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	f22080e7          	jalr	-222(ra) # 80002a68 <clockintr>
    80002b4e:	b7ed                	j	80002b38 <devintr+0x8a>

0000000080002b50 <usertrap>:
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	e04a                	sd	s2,0(sp)
    80002b5a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b60:	1007f793          	andi	a5,a5,256
    80002b64:	e3ad                	bnez	a5,80002bc6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b66:	00003797          	auipc	a5,0x3
    80002b6a:	35a78793          	addi	a5,a5,858 # 80005ec0 <kernelvec>
    80002b6e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	ffe080e7          	jalr	-2(ra) # 80001b70 <myproc>
    80002b7a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b7c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7e:	14102773          	csrr	a4,sepc
    80002b82:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b84:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b88:	47a1                	li	a5,8
    80002b8a:	04f71c63          	bne	a4,a5,80002be2 <usertrap+0x92>
    if(p->killed)
    80002b8e:	551c                	lw	a5,40(a0)
    80002b90:	e3b9                	bnez	a5,80002bd6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b92:	6cb8                	ld	a4,88(s1)
    80002b94:	6f1c                	ld	a5,24(a4)
    80002b96:	0791                	addi	a5,a5,4
    80002b98:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b9e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ba2:	10079073          	csrw	sstatus,a5
    syscall();
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	2e0080e7          	jalr	736(ra) # 80002e86 <syscall>
  if(p->killed)
    80002bae:	549c                	lw	a5,40(s1)
    80002bb0:	ebc1                	bnez	a5,80002c40 <usertrap+0xf0>
  usertrapret();
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	e18080e7          	jalr	-488(ra) # 800029ca <usertrapret>
}
    80002bba:	60e2                	ld	ra,24(sp)
    80002bbc:	6442                	ld	s0,16(sp)
    80002bbe:	64a2                	ld	s1,8(sp)
    80002bc0:	6902                	ld	s2,0(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret
    panic("usertrap: not from user mode");
    80002bc6:	00006517          	auipc	a0,0x6
    80002bca:	81a50513          	addi	a0,a0,-2022 # 800083e0 <states.0+0x58>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	95c080e7          	jalr	-1700(ra) # 8000052a <panic>
      exit(-1);
    80002bd6:	557d                	li	a0,-1
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	a54080e7          	jalr	-1452(ra) # 8000262c <exit>
    80002be0:	bf4d                	j	80002b92 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	ecc080e7          	jalr	-308(ra) # 80002aae <devintr>
    80002bea:	892a                	mv	s2,a0
    80002bec:	c501                	beqz	a0,80002bf4 <usertrap+0xa4>
  if(p->killed)
    80002bee:	549c                	lw	a5,40(s1)
    80002bf0:	c3a1                	beqz	a5,80002c30 <usertrap+0xe0>
    80002bf2:	a815                	j	80002c26 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bf8:	5890                	lw	a2,48(s1)
    80002bfa:	00006517          	auipc	a0,0x6
    80002bfe:	80650513          	addi	a0,a0,-2042 # 80008400 <states.0+0x78>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	972080e7          	jalr	-1678(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c0e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c12:	00006517          	auipc	a0,0x6
    80002c16:	81e50513          	addi	a0,a0,-2018 # 80008430 <states.0+0xa8>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	95a080e7          	jalr	-1702(ra) # 80000574 <printf>
    p->killed = 1;
    80002c22:	4785                	li	a5,1
    80002c24:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c26:	557d                	li	a0,-1
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	a04080e7          	jalr	-1532(ra) # 8000262c <exit>
  if(which_dev == 2)
    80002c30:	4789                	li	a5,2
    80002c32:	f8f910e3          	bne	s2,a5,80002bb2 <usertrap+0x62>
    yield();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	5cc080e7          	jalr	1484(ra) # 80002202 <yield>
    80002c3e:	bf95                	j	80002bb2 <usertrap+0x62>
  int which_dev = 0;
    80002c40:	4901                	li	s2,0
    80002c42:	b7d5                	j	80002c26 <usertrap+0xd6>

0000000080002c44 <kerneltrap>:
{
    80002c44:	7179                	addi	sp,sp,-48
    80002c46:	f406                	sd	ra,40(sp)
    80002c48:	f022                	sd	s0,32(sp)
    80002c4a:	ec26                	sd	s1,24(sp)
    80002c4c:	e84a                	sd	s2,16(sp)
    80002c4e:	e44e                	sd	s3,8(sp)
    80002c50:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c52:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c56:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c5e:	1004f793          	andi	a5,s1,256
    80002c62:	cb85                	beqz	a5,80002c92 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c64:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c68:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c6a:	ef85                	bnez	a5,80002ca2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	e42080e7          	jalr	-446(ra) # 80002aae <devintr>
    80002c74:	cd1d                	beqz	a0,80002cb2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c76:	4789                	li	a5,2
    80002c78:	06f50a63          	beq	a0,a5,80002cec <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c7c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c80:	10049073          	csrw	sstatus,s1
}
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6942                	ld	s2,16(sp)
    80002c8c:	69a2                	ld	s3,8(sp)
    80002c8e:	6145                	addi	sp,sp,48
    80002c90:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	7be50513          	addi	a0,a0,1982 # 80008450 <states.0+0xc8>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	890080e7          	jalr	-1904(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	7d650513          	addi	a0,a0,2006 # 80008478 <states.0+0xf0>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	880080e7          	jalr	-1920(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002cb2:	85ce                	mv	a1,s3
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	7e450513          	addi	a0,a0,2020 # 80008498 <states.0+0x110>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	8b8080e7          	jalr	-1864(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cc4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cc8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	7dc50513          	addi	a0,a0,2012 # 800084a8 <states.0+0x120>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	8a0080e7          	jalr	-1888(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002cdc:	00005517          	auipc	a0,0x5
    80002ce0:	7e450513          	addi	a0,a0,2020 # 800084c0 <states.0+0x138>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	846080e7          	jalr	-1978(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	e84080e7          	jalr	-380(ra) # 80001b70 <myproc>
    80002cf4:	d541                	beqz	a0,80002c7c <kerneltrap+0x38>
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	e7a080e7          	jalr	-390(ra) # 80001b70 <myproc>
    80002cfe:	4d18                	lw	a4,24(a0)
    80002d00:	4791                	li	a5,4
    80002d02:	f6f71de3          	bne	a4,a5,80002c7c <kerneltrap+0x38>
    yield();
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	4fc080e7          	jalr	1276(ra) # 80002202 <yield>
    80002d0e:	b7bd                	j	80002c7c <kerneltrap+0x38>

0000000080002d10 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d10:	1101                	addi	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	1000                	addi	s0,sp,32
    80002d1a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	e54080e7          	jalr	-428(ra) # 80001b70 <myproc>
  switch (n) {
    80002d24:	4795                	li	a5,5
    80002d26:	0497e163          	bltu	a5,s1,80002d68 <argraw+0x58>
    80002d2a:	048a                	slli	s1,s1,0x2
    80002d2c:	00005717          	auipc	a4,0x5
    80002d30:	7cc70713          	addi	a4,a4,1996 # 800084f8 <states.0+0x170>
    80002d34:	94ba                	add	s1,s1,a4
    80002d36:	409c                	lw	a5,0(s1)
    80002d38:	97ba                	add	a5,a5,a4
    80002d3a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d3c:	6d3c                	ld	a5,88(a0)
    80002d3e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret
    return p->trapframe->a1;
    80002d4a:	6d3c                	ld	a5,88(a0)
    80002d4c:	7fa8                	ld	a0,120(a5)
    80002d4e:	bfcd                	j	80002d40 <argraw+0x30>
    return p->trapframe->a2;
    80002d50:	6d3c                	ld	a5,88(a0)
    80002d52:	63c8                	ld	a0,128(a5)
    80002d54:	b7f5                	j	80002d40 <argraw+0x30>
    return p->trapframe->a3;
    80002d56:	6d3c                	ld	a5,88(a0)
    80002d58:	67c8                	ld	a0,136(a5)
    80002d5a:	b7dd                	j	80002d40 <argraw+0x30>
    return p->trapframe->a4;
    80002d5c:	6d3c                	ld	a5,88(a0)
    80002d5e:	6bc8                	ld	a0,144(a5)
    80002d60:	b7c5                	j	80002d40 <argraw+0x30>
    return p->trapframe->a5;
    80002d62:	6d3c                	ld	a5,88(a0)
    80002d64:	6fc8                	ld	a0,152(a5)
    80002d66:	bfe9                	j	80002d40 <argraw+0x30>
  panic("argraw");
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	76850513          	addi	a0,a0,1896 # 800084d0 <states.0+0x148>
    80002d70:	ffffd097          	auipc	ra,0xffffd
    80002d74:	7ba080e7          	jalr	1978(ra) # 8000052a <panic>

0000000080002d78 <fetchaddr>:
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	e426                	sd	s1,8(sp)
    80002d80:	e04a                	sd	s2,0(sp)
    80002d82:	1000                	addi	s0,sp,32
    80002d84:	84aa                	mv	s1,a0
    80002d86:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	de8080e7          	jalr	-536(ra) # 80001b70 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d90:	653c                	ld	a5,72(a0)
    80002d92:	02f4f863          	bgeu	s1,a5,80002dc2 <fetchaddr+0x4a>
    80002d96:	00848713          	addi	a4,s1,8
    80002d9a:	02e7e663          	bltu	a5,a4,80002dc6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d9e:	46a1                	li	a3,8
    80002da0:	8626                	mv	a2,s1
    80002da2:	85ca                	mv	a1,s2
    80002da4:	6928                	ld	a0,80(a0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	924080e7          	jalr	-1756(ra) # 800016ca <copyin>
    80002dae:	00a03533          	snez	a0,a0
    80002db2:	40a00533          	neg	a0,a0
}
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6902                	ld	s2,0(sp)
    80002dbe:	6105                	addi	sp,sp,32
    80002dc0:	8082                	ret
    return -1;
    80002dc2:	557d                	li	a0,-1
    80002dc4:	bfcd                	j	80002db6 <fetchaddr+0x3e>
    80002dc6:	557d                	li	a0,-1
    80002dc8:	b7fd                	j	80002db6 <fetchaddr+0x3e>

0000000080002dca <fetchstr>:
{
    80002dca:	7179                	addi	sp,sp,-48
    80002dcc:	f406                	sd	ra,40(sp)
    80002dce:	f022                	sd	s0,32(sp)
    80002dd0:	ec26                	sd	s1,24(sp)
    80002dd2:	e84a                	sd	s2,16(sp)
    80002dd4:	e44e                	sd	s3,8(sp)
    80002dd6:	1800                	addi	s0,sp,48
    80002dd8:	892a                	mv	s2,a0
    80002dda:	84ae                	mv	s1,a1
    80002ddc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	d92080e7          	jalr	-622(ra) # 80001b70 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002de6:	86ce                	mv	a3,s3
    80002de8:	864a                	mv	a2,s2
    80002dea:	85a6                	mv	a1,s1
    80002dec:	6928                	ld	a0,80(a0)
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	96a080e7          	jalr	-1686(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002df6:	00054763          	bltz	a0,80002e04 <fetchstr+0x3a>
  return strlen(buf);
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	046080e7          	jalr	70(ra) # 80000e42 <strlen>
}
    80002e04:	70a2                	ld	ra,40(sp)
    80002e06:	7402                	ld	s0,32(sp)
    80002e08:	64e2                	ld	s1,24(sp)
    80002e0a:	6942                	ld	s2,16(sp)
    80002e0c:	69a2                	ld	s3,8(sp)
    80002e0e:	6145                	addi	sp,sp,48
    80002e10:	8082                	ret

0000000080002e12 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
    80002e1c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	ef2080e7          	jalr	-270(ra) # 80002d10 <argraw>
    80002e26:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e28:	4501                	li	a0,0
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	1000                	addi	s0,sp,32
    80002e3e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	ed0080e7          	jalr	-304(ra) # 80002d10 <argraw>
    80002e48:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e4a:	4501                	li	a0,0
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e56:	1101                	addi	sp,sp,-32
    80002e58:	ec06                	sd	ra,24(sp)
    80002e5a:	e822                	sd	s0,16(sp)
    80002e5c:	e426                	sd	s1,8(sp)
    80002e5e:	e04a                	sd	s2,0(sp)
    80002e60:	1000                	addi	s0,sp,32
    80002e62:	84ae                	mv	s1,a1
    80002e64:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	eaa080e7          	jalr	-342(ra) # 80002d10 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e6e:	864a                	mv	a2,s2
    80002e70:	85a6                	mv	a1,s1
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	f58080e7          	jalr	-168(ra) # 80002dca <fetchstr>
}
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	64a2                	ld	s1,8(sp)
    80002e80:	6902                	ld	s2,0(sp)
    80002e82:	6105                	addi	sp,sp,32
    80002e84:	8082                	ret

0000000080002e86 <syscall>:

};

void
syscall(void)
{
    80002e86:	1101                	addi	sp,sp,-32
    80002e88:	ec06                	sd	ra,24(sp)
    80002e8a:	e822                	sd	s0,16(sp)
    80002e8c:	e426                	sd	s1,8(sp)
    80002e8e:	e04a                	sd	s2,0(sp)
    80002e90:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	cde080e7          	jalr	-802(ra) # 80001b70 <myproc>
    80002e9a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e9c:	05853903          	ld	s2,88(a0)
    80002ea0:	0a893783          	ld	a5,168(s2)
    80002ea4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ea8:	37fd                	addiw	a5,a5,-1
    80002eaa:	4755                	li	a4,21
    80002eac:	00f76f63          	bltu	a4,a5,80002eca <syscall+0x44>
    80002eb0:	00369713          	slli	a4,a3,0x3
    80002eb4:	00005797          	auipc	a5,0x5
    80002eb8:	65c78793          	addi	a5,a5,1628 # 80008510 <syscalls>
    80002ebc:	97ba                	add	a5,a5,a4
    80002ebe:	639c                	ld	a5,0(a5)
    80002ec0:	c789                	beqz	a5,80002eca <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ec2:	9782                	jalr	a5
    80002ec4:	06a93823          	sd	a0,112(s2)
    80002ec8:	a839                	j	80002ee6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eca:	15848613          	addi	a2,s1,344
    80002ece:	588c                	lw	a1,48(s1)
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	60850513          	addi	a0,a0,1544 # 800084d8 <states.0+0x150>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	69c080e7          	jalr	1692(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee0:	6cbc                	ld	a5,88(s1)
    80002ee2:	577d                	li	a4,-1
    80002ee4:	fbb8                	sd	a4,112(a5)
  }
}
    80002ee6:	60e2                	ld	ra,24(sp)
    80002ee8:	6442                	ld	s0,16(sp)
    80002eea:	64a2                	ld	s1,8(sp)
    80002eec:	6902                	ld	s2,0(sp)
    80002eee:	6105                	addi	sp,sp,32
    80002ef0:	8082                	ret

0000000080002ef2 <sys_exit>:
#include "proc.h"
#include "pstat.h"

uint64
sys_exit(void)
{
    80002ef2:	1101                	addi	sp,sp,-32
    80002ef4:	ec06                	sd	ra,24(sp)
    80002ef6:	e822                	sd	s0,16(sp)
    80002ef8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002efa:	fec40593          	addi	a1,s0,-20
    80002efe:	4501                	li	a0,0
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	f12080e7          	jalr	-238(ra) # 80002e12 <argint>
    return -1;
    80002f08:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f0a:	00054963          	bltz	a0,80002f1c <sys_exit+0x2a>
  exit(n);
    80002f0e:	fec42503          	lw	a0,-20(s0)
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	71a080e7          	jalr	1818(ra) # 8000262c <exit>
  return 0;  // not reached
    80002f1a:	4781                	li	a5,0
}
    80002f1c:	853e                	mv	a0,a5
    80002f1e:	60e2                	ld	ra,24(sp)
    80002f20:	6442                	ld	s0,16(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f26:	1141                	addi	sp,sp,-16
    80002f28:	e406                	sd	ra,8(sp)
    80002f2a:	e022                	sd	s0,0(sp)
    80002f2c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	c42080e7          	jalr	-958(ra) # 80001b70 <myproc>
}
    80002f36:	5908                	lw	a0,48(a0)
    80002f38:	60a2                	ld	ra,8(sp)
    80002f3a:	6402                	ld	s0,0(sp)
    80002f3c:	0141                	addi	sp,sp,16
    80002f3e:	8082                	ret

0000000080002f40 <sys_fork>:

uint64
sys_fork(void)
{
    80002f40:	1141                	addi	sp,sp,-16
    80002f42:	e406                	sd	ra,8(sp)
    80002f44:	e022                	sd	s0,0(sp)
    80002f46:	0800                	addi	s0,sp,16
  return fork();
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	016080e7          	jalr	22(ra) # 80001f5e <fork>
}
    80002f50:	60a2                	ld	ra,8(sp)
    80002f52:	6402                	ld	s0,0(sp)
    80002f54:	0141                	addi	sp,sp,16
    80002f56:	8082                	ret

0000000080002f58 <sys_wait>:

uint64
sys_wait(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f60:	fe840593          	addi	a1,s0,-24
    80002f64:	4501                	li	a0,0
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	ece080e7          	jalr	-306(ra) # 80002e34 <argaddr>
    80002f6e:	87aa                	mv	a5,a0
    return -1;
    80002f70:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f72:	0007c863          	bltz	a5,80002f82 <sys_wait+0x2a>
  return wait(p);
    80002f76:	fe843503          	ld	a0,-24(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	4b0080e7          	jalr	1200(ra) # 8000242a <wait>
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret

0000000080002f8a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f8a:	7179                	addi	sp,sp,-48
    80002f8c:	f406                	sd	ra,40(sp)
    80002f8e:	f022                	sd	s0,32(sp)
    80002f90:	ec26                	sd	s1,24(sp)
    80002f92:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f94:	fdc40593          	addi	a1,s0,-36
    80002f98:	4501                	li	a0,0
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	e78080e7          	jalr	-392(ra) # 80002e12 <argint>
    return -1;
    80002fa2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fa4:	00054f63          	bltz	a0,80002fc2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	bc8080e7          	jalr	-1080(ra) # 80001b70 <myproc>
    80002fb0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fb2:	fdc42503          	lw	a0,-36(s0)
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	f34080e7          	jalr	-204(ra) # 80001eea <growproc>
    80002fbe:	00054863          	bltz	a0,80002fce <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fc2:	8526                	mv	a0,s1
    80002fc4:	70a2                	ld	ra,40(sp)
    80002fc6:	7402                	ld	s0,32(sp)
    80002fc8:	64e2                	ld	s1,24(sp)
    80002fca:	6145                	addi	sp,sp,48
    80002fcc:	8082                	ret
    return -1;
    80002fce:	54fd                	li	s1,-1
    80002fd0:	bfcd                	j	80002fc2 <sys_sbrk+0x38>

0000000080002fd2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fd2:	7139                	addi	sp,sp,-64
    80002fd4:	fc06                	sd	ra,56(sp)
    80002fd6:	f822                	sd	s0,48(sp)
    80002fd8:	f426                	sd	s1,40(sp)
    80002fda:	f04a                	sd	s2,32(sp)
    80002fdc:	ec4e                	sd	s3,24(sp)
    80002fde:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fe0:	fcc40593          	addi	a1,s0,-52
    80002fe4:	4501                	li	a0,0
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	e2c080e7          	jalr	-468(ra) # 80002e12 <argint>
    return -1;
    80002fee:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ff0:	06054563          	bltz	a0,8000305a <sys_sleep+0x88>
  acquire(&tickslock);
    80002ff4:	00015517          	auipc	a0,0x15
    80002ff8:	90c50513          	addi	a0,a0,-1780 # 80017900 <tickslock>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	bc6080e7          	jalr	-1082(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003004:	00006917          	auipc	s2,0x6
    80003008:	03092903          	lw	s2,48(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    8000300c:	fcc42783          	lw	a5,-52(s0)
    80003010:	cf85                	beqz	a5,80003048 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003012:	00015997          	auipc	s3,0x15
    80003016:	8ee98993          	addi	s3,s3,-1810 # 80017900 <tickslock>
    8000301a:	00006497          	auipc	s1,0x6
    8000301e:	01a48493          	addi	s1,s1,26 # 80009034 <ticks>
    if(myproc()->killed){
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	b4e080e7          	jalr	-1202(ra) # 80001b70 <myproc>
    8000302a:	551c                	lw	a5,40(a0)
    8000302c:	ef9d                	bnez	a5,8000306a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000302e:	85ce                	mv	a1,s3
    80003030:	8526                	mv	a0,s1
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	394080e7          	jalr	916(ra) # 800023c6 <sleep>
  while(ticks - ticks0 < n){
    8000303a:	409c                	lw	a5,0(s1)
    8000303c:	412787bb          	subw	a5,a5,s2
    80003040:	fcc42703          	lw	a4,-52(s0)
    80003044:	fce7efe3          	bltu	a5,a4,80003022 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003048:	00015517          	auipc	a0,0x15
    8000304c:	8b850513          	addi	a0,a0,-1864 # 80017900 <tickslock>
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	c26080e7          	jalr	-986(ra) # 80000c76 <release>
  return 0;
    80003058:	4781                	li	a5,0
}
    8000305a:	853e                	mv	a0,a5
    8000305c:	70e2                	ld	ra,56(sp)
    8000305e:	7442                	ld	s0,48(sp)
    80003060:	74a2                	ld	s1,40(sp)
    80003062:	7902                	ld	s2,32(sp)
    80003064:	69e2                	ld	s3,24(sp)
    80003066:	6121                	addi	sp,sp,64
    80003068:	8082                	ret
      release(&tickslock);
    8000306a:	00015517          	auipc	a0,0x15
    8000306e:	89650513          	addi	a0,a0,-1898 # 80017900 <tickslock>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c04080e7          	jalr	-1020(ra) # 80000c76 <release>
      return -1;
    8000307a:	57fd                	li	a5,-1
    8000307c:	bff9                	j	8000305a <sys_sleep+0x88>

000000008000307e <sys_kill>:

uint64
sys_kill(void)
{
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003086:	fec40593          	addi	a1,s0,-20
    8000308a:	4501                	li	a0,0
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	d86080e7          	jalr	-634(ra) # 80002e12 <argint>
    80003094:	87aa                	mv	a5,a0
    return -1;
    80003096:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003098:	0007c863          	bltz	a5,800030a8 <sys_kill+0x2a>
  return kill(pid);
    8000309c:	fec42503          	lw	a0,-20(s0)
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	662080e7          	jalr	1634(ra) # 80002702 <kill>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret

00000000800030b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030b0:	1101                	addi	sp,sp,-32
    800030b2:	ec06                	sd	ra,24(sp)
    800030b4:	e822                	sd	s0,16(sp)
    800030b6:	e426                	sd	s1,8(sp)
    800030b8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	84650513          	addi	a0,a0,-1978 # 80017900 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	b00080e7          	jalr	-1280(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800030ca:	00006497          	auipc	s1,0x6
    800030ce:	f6a4a483          	lw	s1,-150(s1) # 80009034 <ticks>
  release(&tickslock);
    800030d2:	00015517          	auipc	a0,0x15
    800030d6:	82e50513          	addi	a0,a0,-2002 # 80017900 <tickslock>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	b9c080e7          	jalr	-1124(ra) # 80000c76 <release>
  return xticks;
}
    800030e2:	02049513          	slli	a0,s1,0x20
    800030e6:	9101                	srli	a0,a0,0x20
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6105                	addi	sp,sp,32
    800030f0:	8082                	ret

00000000800030f2 <sys_getpstat>:

// Leyuan & Lee
//Added new sys call
uint64
sys_getpstat(void)
{
    800030f2:	bd010113          	addi	sp,sp,-1072
    800030f6:	42113423          	sd	ra,1064(sp)
    800030fa:	42813023          	sd	s0,1056(sp)
    800030fe:	40913c23          	sd	s1,1048(sp)
    80003102:	41213823          	sd	s2,1040(sp)
    80003106:	43010413          	addi	s0,sp,1072
  struct proc *p = myproc();
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	a66080e7          	jalr	-1434(ra) # 80001b70 <myproc>
    80003112:	892a                	mv	s2,a0
  uint64 upstat; // user virtual address, pointing to a struct pstat
  struct pstat kpstat; // struct pstat in kernel memory

  // get system call argument
  if(argaddr(0, &upstat) < 0)
    80003114:	fd840593          	addi	a1,s0,-40
    80003118:	4501                	li	a0,0
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	d1a080e7          	jalr	-742(ra) # 80002e34 <argaddr>
    return -1;
    80003122:	54fd                	li	s1,-1
  if(argaddr(0, &upstat) < 0)
    80003124:	02054763          	bltz	a0,80003152 <sys_getpstat+0x60>
  
 // TODO: define kernel side kgetpstat(struct pstat* ps), its purpose is to fill the values into kpstat.
  uint64 result = kgetpstat(&kpstat);
    80003128:	bd840513          	addi	a0,s0,-1064
    8000312c:	fffff097          	auipc	ra,0xfffff
    80003130:	7ac080e7          	jalr	1964(ra) # 800028d8 <kgetpstat>
    80003134:	84aa                	mv	s1,a0

  // copy pstat from kernel memory to user memory
  if(copyout(p->pagetable, upstat, (char *)&kpstat, sizeof(kpstat)) < 0)
    80003136:	40000693          	li	a3,1024
    8000313a:	bd840613          	addi	a2,s0,-1064
    8000313e:	fd843583          	ld	a1,-40(s0)
    80003142:	05093503          	ld	a0,80(s2)
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	4f8080e7          	jalr	1272(ra) # 8000163e <copyout>
    8000314e:	00054e63          	bltz	a0,8000316a <sys_getpstat+0x78>
    return -1;
  return result;
    80003152:	8526                	mv	a0,s1
    80003154:	42813083          	ld	ra,1064(sp)
    80003158:	42013403          	ld	s0,1056(sp)
    8000315c:	41813483          	ld	s1,1048(sp)
    80003160:	41013903          	ld	s2,1040(sp)
    80003164:	43010113          	addi	sp,sp,1072
    80003168:	8082                	ret
    return -1;
    8000316a:	54fd                	li	s1,-1
    8000316c:	b7dd                	j	80003152 <sys_getpstat+0x60>

000000008000316e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000316e:	7179                	addi	sp,sp,-48
    80003170:	f406                	sd	ra,40(sp)
    80003172:	f022                	sd	s0,32(sp)
    80003174:	ec26                	sd	s1,24(sp)
    80003176:	e84a                	sd	s2,16(sp)
    80003178:	e44e                	sd	s3,8(sp)
    8000317a:	e052                	sd	s4,0(sp)
    8000317c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000317e:	00005597          	auipc	a1,0x5
    80003182:	44a58593          	addi	a1,a1,1098 # 800085c8 <syscalls+0xb8>
    80003186:	00014517          	auipc	a0,0x14
    8000318a:	79250513          	addi	a0,a0,1938 # 80017918 <bcache>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	9a4080e7          	jalr	-1628(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003196:	0001c797          	auipc	a5,0x1c
    8000319a:	78278793          	addi	a5,a5,1922 # 8001f918 <bcache+0x8000>
    8000319e:	0001d717          	auipc	a4,0x1d
    800031a2:	9e270713          	addi	a4,a4,-1566 # 8001fb80 <bcache+0x8268>
    800031a6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031aa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ae:	00014497          	auipc	s1,0x14
    800031b2:	78248493          	addi	s1,s1,1922 # 80017930 <bcache+0x18>
    b->next = bcache.head.next;
    800031b6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031b8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031ba:	00005a17          	auipc	s4,0x5
    800031be:	416a0a13          	addi	s4,s4,1046 # 800085d0 <syscalls+0xc0>
    b->next = bcache.head.next;
    800031c2:	2b893783          	ld	a5,696(s2)
    800031c6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031c8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031cc:	85d2                	mv	a1,s4
    800031ce:	01048513          	addi	a0,s1,16
    800031d2:	00001097          	auipc	ra,0x1
    800031d6:	4bc080e7          	jalr	1212(ra) # 8000468e <initsleeplock>
    bcache.head.next->prev = b;
    800031da:	2b893783          	ld	a5,696(s2)
    800031de:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031e0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031e4:	45848493          	addi	s1,s1,1112
    800031e8:	fd349de3          	bne	s1,s3,800031c2 <binit+0x54>
  }
}
    800031ec:	70a2                	ld	ra,40(sp)
    800031ee:	7402                	ld	s0,32(sp)
    800031f0:	64e2                	ld	s1,24(sp)
    800031f2:	6942                	ld	s2,16(sp)
    800031f4:	69a2                	ld	s3,8(sp)
    800031f6:	6a02                	ld	s4,0(sp)
    800031f8:	6145                	addi	sp,sp,48
    800031fa:	8082                	ret

00000000800031fc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031fc:	7179                	addi	sp,sp,-48
    800031fe:	f406                	sd	ra,40(sp)
    80003200:	f022                	sd	s0,32(sp)
    80003202:	ec26                	sd	s1,24(sp)
    80003204:	e84a                	sd	s2,16(sp)
    80003206:	e44e                	sd	s3,8(sp)
    80003208:	1800                	addi	s0,sp,48
    8000320a:	892a                	mv	s2,a0
    8000320c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000320e:	00014517          	auipc	a0,0x14
    80003212:	70a50513          	addi	a0,a0,1802 # 80017918 <bcache>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	9ac080e7          	jalr	-1620(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000321e:	0001d497          	auipc	s1,0x1d
    80003222:	9b24b483          	ld	s1,-1614(s1) # 8001fbd0 <bcache+0x82b8>
    80003226:	0001d797          	auipc	a5,0x1d
    8000322a:	95a78793          	addi	a5,a5,-1702 # 8001fb80 <bcache+0x8268>
    8000322e:	02f48f63          	beq	s1,a5,8000326c <bread+0x70>
    80003232:	873e                	mv	a4,a5
    80003234:	a021                	j	8000323c <bread+0x40>
    80003236:	68a4                	ld	s1,80(s1)
    80003238:	02e48a63          	beq	s1,a4,8000326c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000323c:	449c                	lw	a5,8(s1)
    8000323e:	ff279ce3          	bne	a5,s2,80003236 <bread+0x3a>
    80003242:	44dc                	lw	a5,12(s1)
    80003244:	ff3799e3          	bne	a5,s3,80003236 <bread+0x3a>
      b->refcnt++;
    80003248:	40bc                	lw	a5,64(s1)
    8000324a:	2785                	addiw	a5,a5,1
    8000324c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000324e:	00014517          	auipc	a0,0x14
    80003252:	6ca50513          	addi	a0,a0,1738 # 80017918 <bcache>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	a20080e7          	jalr	-1504(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000325e:	01048513          	addi	a0,s1,16
    80003262:	00001097          	auipc	ra,0x1
    80003266:	466080e7          	jalr	1126(ra) # 800046c8 <acquiresleep>
      return b;
    8000326a:	a8b9                	j	800032c8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000326c:	0001d497          	auipc	s1,0x1d
    80003270:	95c4b483          	ld	s1,-1700(s1) # 8001fbc8 <bcache+0x82b0>
    80003274:	0001d797          	auipc	a5,0x1d
    80003278:	90c78793          	addi	a5,a5,-1780 # 8001fb80 <bcache+0x8268>
    8000327c:	00f48863          	beq	s1,a5,8000328c <bread+0x90>
    80003280:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003282:	40bc                	lw	a5,64(s1)
    80003284:	cf81                	beqz	a5,8000329c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003286:	64a4                	ld	s1,72(s1)
    80003288:	fee49de3          	bne	s1,a4,80003282 <bread+0x86>
  panic("bget: no buffers");
    8000328c:	00005517          	auipc	a0,0x5
    80003290:	34c50513          	addi	a0,a0,844 # 800085d8 <syscalls+0xc8>
    80003294:	ffffd097          	auipc	ra,0xffffd
    80003298:	296080e7          	jalr	662(ra) # 8000052a <panic>
      b->dev = dev;
    8000329c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032a0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032a4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032a8:	4785                	li	a5,1
    800032aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032ac:	00014517          	auipc	a0,0x14
    800032b0:	66c50513          	addi	a0,a0,1644 # 80017918 <bcache>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	9c2080e7          	jalr	-1598(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800032bc:	01048513          	addi	a0,s1,16
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	408080e7          	jalr	1032(ra) # 800046c8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032c8:	409c                	lw	a5,0(s1)
    800032ca:	cb89                	beqz	a5,800032dc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032cc:	8526                	mv	a0,s1
    800032ce:	70a2                	ld	ra,40(sp)
    800032d0:	7402                	ld	s0,32(sp)
    800032d2:	64e2                	ld	s1,24(sp)
    800032d4:	6942                	ld	s2,16(sp)
    800032d6:	69a2                	ld	s3,8(sp)
    800032d8:	6145                	addi	sp,sp,48
    800032da:	8082                	ret
    virtio_disk_rw(b, 0);
    800032dc:	4581                	li	a1,0
    800032de:	8526                	mv	a0,s1
    800032e0:	00003097          	auipc	ra,0x3
    800032e4:	f16080e7          	jalr	-234(ra) # 800061f6 <virtio_disk_rw>
    b->valid = 1;
    800032e8:	4785                	li	a5,1
    800032ea:	c09c                	sw	a5,0(s1)
  return b;
    800032ec:	b7c5                	j	800032cc <bread+0xd0>

00000000800032ee <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032ee:	1101                	addi	sp,sp,-32
    800032f0:	ec06                	sd	ra,24(sp)
    800032f2:	e822                	sd	s0,16(sp)
    800032f4:	e426                	sd	s1,8(sp)
    800032f6:	1000                	addi	s0,sp,32
    800032f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032fa:	0541                	addi	a0,a0,16
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	466080e7          	jalr	1126(ra) # 80004762 <holdingsleep>
    80003304:	cd01                	beqz	a0,8000331c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003306:	4585                	li	a1,1
    80003308:	8526                	mv	a0,s1
    8000330a:	00003097          	auipc	ra,0x3
    8000330e:	eec080e7          	jalr	-276(ra) # 800061f6 <virtio_disk_rw>
}
    80003312:	60e2                	ld	ra,24(sp)
    80003314:	6442                	ld	s0,16(sp)
    80003316:	64a2                	ld	s1,8(sp)
    80003318:	6105                	addi	sp,sp,32
    8000331a:	8082                	ret
    panic("bwrite");
    8000331c:	00005517          	auipc	a0,0x5
    80003320:	2d450513          	addi	a0,a0,724 # 800085f0 <syscalls+0xe0>
    80003324:	ffffd097          	auipc	ra,0xffffd
    80003328:	206080e7          	jalr	518(ra) # 8000052a <panic>

000000008000332c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000332c:	1101                	addi	sp,sp,-32
    8000332e:	ec06                	sd	ra,24(sp)
    80003330:	e822                	sd	s0,16(sp)
    80003332:	e426                	sd	s1,8(sp)
    80003334:	e04a                	sd	s2,0(sp)
    80003336:	1000                	addi	s0,sp,32
    80003338:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000333a:	01050913          	addi	s2,a0,16
    8000333e:	854a                	mv	a0,s2
    80003340:	00001097          	auipc	ra,0x1
    80003344:	422080e7          	jalr	1058(ra) # 80004762 <holdingsleep>
    80003348:	c92d                	beqz	a0,800033ba <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000334a:	854a                	mv	a0,s2
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	3d2080e7          	jalr	978(ra) # 8000471e <releasesleep>

  acquire(&bcache.lock);
    80003354:	00014517          	auipc	a0,0x14
    80003358:	5c450513          	addi	a0,a0,1476 # 80017918 <bcache>
    8000335c:	ffffe097          	auipc	ra,0xffffe
    80003360:	866080e7          	jalr	-1946(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003364:	40bc                	lw	a5,64(s1)
    80003366:	37fd                	addiw	a5,a5,-1
    80003368:	0007871b          	sext.w	a4,a5
    8000336c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000336e:	eb05                	bnez	a4,8000339e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003370:	68bc                	ld	a5,80(s1)
    80003372:	64b8                	ld	a4,72(s1)
    80003374:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003376:	64bc                	ld	a5,72(s1)
    80003378:	68b8                	ld	a4,80(s1)
    8000337a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000337c:	0001c797          	auipc	a5,0x1c
    80003380:	59c78793          	addi	a5,a5,1436 # 8001f918 <bcache+0x8000>
    80003384:	2b87b703          	ld	a4,696(a5)
    80003388:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000338a:	0001c717          	auipc	a4,0x1c
    8000338e:	7f670713          	addi	a4,a4,2038 # 8001fb80 <bcache+0x8268>
    80003392:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003394:	2b87b703          	ld	a4,696(a5)
    80003398:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000339a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000339e:	00014517          	auipc	a0,0x14
    800033a2:	57a50513          	addi	a0,a0,1402 # 80017918 <bcache>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	8d0080e7          	jalr	-1840(ra) # 80000c76 <release>
}
    800033ae:	60e2                	ld	ra,24(sp)
    800033b0:	6442                	ld	s0,16(sp)
    800033b2:	64a2                	ld	s1,8(sp)
    800033b4:	6902                	ld	s2,0(sp)
    800033b6:	6105                	addi	sp,sp,32
    800033b8:	8082                	ret
    panic("brelse");
    800033ba:	00005517          	auipc	a0,0x5
    800033be:	23e50513          	addi	a0,a0,574 # 800085f8 <syscalls+0xe8>
    800033c2:	ffffd097          	auipc	ra,0xffffd
    800033c6:	168080e7          	jalr	360(ra) # 8000052a <panic>

00000000800033ca <bpin>:

void
bpin(struct buf *b) {
    800033ca:	1101                	addi	sp,sp,-32
    800033cc:	ec06                	sd	ra,24(sp)
    800033ce:	e822                	sd	s0,16(sp)
    800033d0:	e426                	sd	s1,8(sp)
    800033d2:	1000                	addi	s0,sp,32
    800033d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033d6:	00014517          	auipc	a0,0x14
    800033da:	54250513          	addi	a0,a0,1346 # 80017918 <bcache>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	7e4080e7          	jalr	2020(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800033e6:	40bc                	lw	a5,64(s1)
    800033e8:	2785                	addiw	a5,a5,1
    800033ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033ec:	00014517          	auipc	a0,0x14
    800033f0:	52c50513          	addi	a0,a0,1324 # 80017918 <bcache>
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	882080e7          	jalr	-1918(ra) # 80000c76 <release>
}
    800033fc:	60e2                	ld	ra,24(sp)
    800033fe:	6442                	ld	s0,16(sp)
    80003400:	64a2                	ld	s1,8(sp)
    80003402:	6105                	addi	sp,sp,32
    80003404:	8082                	ret

0000000080003406 <bunpin>:

void
bunpin(struct buf *b) {
    80003406:	1101                	addi	sp,sp,-32
    80003408:	ec06                	sd	ra,24(sp)
    8000340a:	e822                	sd	s0,16(sp)
    8000340c:	e426                	sd	s1,8(sp)
    8000340e:	1000                	addi	s0,sp,32
    80003410:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003412:	00014517          	auipc	a0,0x14
    80003416:	50650513          	addi	a0,a0,1286 # 80017918 <bcache>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	7a8080e7          	jalr	1960(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003422:	40bc                	lw	a5,64(s1)
    80003424:	37fd                	addiw	a5,a5,-1
    80003426:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003428:	00014517          	auipc	a0,0x14
    8000342c:	4f050513          	addi	a0,a0,1264 # 80017918 <bcache>
    80003430:	ffffe097          	auipc	ra,0xffffe
    80003434:	846080e7          	jalr	-1978(ra) # 80000c76 <release>
}
    80003438:	60e2                	ld	ra,24(sp)
    8000343a:	6442                	ld	s0,16(sp)
    8000343c:	64a2                	ld	s1,8(sp)
    8000343e:	6105                	addi	sp,sp,32
    80003440:	8082                	ret

0000000080003442 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003442:	1101                	addi	sp,sp,-32
    80003444:	ec06                	sd	ra,24(sp)
    80003446:	e822                	sd	s0,16(sp)
    80003448:	e426                	sd	s1,8(sp)
    8000344a:	e04a                	sd	s2,0(sp)
    8000344c:	1000                	addi	s0,sp,32
    8000344e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003450:	00d5d59b          	srliw	a1,a1,0xd
    80003454:	0001d797          	auipc	a5,0x1d
    80003458:	ba07a783          	lw	a5,-1120(a5) # 8001fff4 <sb+0x1c>
    8000345c:	9dbd                	addw	a1,a1,a5
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	d9e080e7          	jalr	-610(ra) # 800031fc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003466:	0074f713          	andi	a4,s1,7
    8000346a:	4785                	li	a5,1
    8000346c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003470:	14ce                	slli	s1,s1,0x33
    80003472:	90d9                	srli	s1,s1,0x36
    80003474:	00950733          	add	a4,a0,s1
    80003478:	05874703          	lbu	a4,88(a4)
    8000347c:	00e7f6b3          	and	a3,a5,a4
    80003480:	c69d                	beqz	a3,800034ae <bfree+0x6c>
    80003482:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003484:	94aa                	add	s1,s1,a0
    80003486:	fff7c793          	not	a5,a5
    8000348a:	8ff9                	and	a5,a5,a4
    8000348c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003490:	00001097          	auipc	ra,0x1
    80003494:	118080e7          	jalr	280(ra) # 800045a8 <log_write>
  brelse(bp);
    80003498:	854a                	mv	a0,s2
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	e92080e7          	jalr	-366(ra) # 8000332c <brelse>
}
    800034a2:	60e2                	ld	ra,24(sp)
    800034a4:	6442                	ld	s0,16(sp)
    800034a6:	64a2                	ld	s1,8(sp)
    800034a8:	6902                	ld	s2,0(sp)
    800034aa:	6105                	addi	sp,sp,32
    800034ac:	8082                	ret
    panic("freeing free block");
    800034ae:	00005517          	auipc	a0,0x5
    800034b2:	15250513          	addi	a0,a0,338 # 80008600 <syscalls+0xf0>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	074080e7          	jalr	116(ra) # 8000052a <panic>

00000000800034be <balloc>:
{
    800034be:	711d                	addi	sp,sp,-96
    800034c0:	ec86                	sd	ra,88(sp)
    800034c2:	e8a2                	sd	s0,80(sp)
    800034c4:	e4a6                	sd	s1,72(sp)
    800034c6:	e0ca                	sd	s2,64(sp)
    800034c8:	fc4e                	sd	s3,56(sp)
    800034ca:	f852                	sd	s4,48(sp)
    800034cc:	f456                	sd	s5,40(sp)
    800034ce:	f05a                	sd	s6,32(sp)
    800034d0:	ec5e                	sd	s7,24(sp)
    800034d2:	e862                	sd	s8,16(sp)
    800034d4:	e466                	sd	s9,8(sp)
    800034d6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034d8:	0001d797          	auipc	a5,0x1d
    800034dc:	b047a783          	lw	a5,-1276(a5) # 8001ffdc <sb+0x4>
    800034e0:	cbd1                	beqz	a5,80003574 <balloc+0xb6>
    800034e2:	8baa                	mv	s7,a0
    800034e4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034e6:	0001db17          	auipc	s6,0x1d
    800034ea:	af2b0b13          	addi	s6,s6,-1294 # 8001ffd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ee:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034f0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034f4:	6c89                	lui	s9,0x2
    800034f6:	a831                	j	80003512 <balloc+0x54>
    brelse(bp);
    800034f8:	854a                	mv	a0,s2
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	e32080e7          	jalr	-462(ra) # 8000332c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003502:	015c87bb          	addw	a5,s9,s5
    80003506:	00078a9b          	sext.w	s5,a5
    8000350a:	004b2703          	lw	a4,4(s6)
    8000350e:	06eaf363          	bgeu	s5,a4,80003574 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003512:	41fad79b          	sraiw	a5,s5,0x1f
    80003516:	0137d79b          	srliw	a5,a5,0x13
    8000351a:	015787bb          	addw	a5,a5,s5
    8000351e:	40d7d79b          	sraiw	a5,a5,0xd
    80003522:	01cb2583          	lw	a1,28(s6)
    80003526:	9dbd                	addw	a1,a1,a5
    80003528:	855e                	mv	a0,s7
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	cd2080e7          	jalr	-814(ra) # 800031fc <bread>
    80003532:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003534:	004b2503          	lw	a0,4(s6)
    80003538:	000a849b          	sext.w	s1,s5
    8000353c:	8662                	mv	a2,s8
    8000353e:	faa4fde3          	bgeu	s1,a0,800034f8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003542:	41f6579b          	sraiw	a5,a2,0x1f
    80003546:	01d7d69b          	srliw	a3,a5,0x1d
    8000354a:	00c6873b          	addw	a4,a3,a2
    8000354e:	00777793          	andi	a5,a4,7
    80003552:	9f95                	subw	a5,a5,a3
    80003554:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003558:	4037571b          	sraiw	a4,a4,0x3
    8000355c:	00e906b3          	add	a3,s2,a4
    80003560:	0586c683          	lbu	a3,88(a3)
    80003564:	00d7f5b3          	and	a1,a5,a3
    80003568:	cd91                	beqz	a1,80003584 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000356a:	2605                	addiw	a2,a2,1
    8000356c:	2485                	addiw	s1,s1,1
    8000356e:	fd4618e3          	bne	a2,s4,8000353e <balloc+0x80>
    80003572:	b759                	j	800034f8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	0a450513          	addi	a0,a0,164 # 80008618 <syscalls+0x108>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	fae080e7          	jalr	-82(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003584:	974a                	add	a4,a4,s2
    80003586:	8fd5                	or	a5,a5,a3
    80003588:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000358c:	854a                	mv	a0,s2
    8000358e:	00001097          	auipc	ra,0x1
    80003592:	01a080e7          	jalr	26(ra) # 800045a8 <log_write>
        brelse(bp);
    80003596:	854a                	mv	a0,s2
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	d94080e7          	jalr	-620(ra) # 8000332c <brelse>
  bp = bread(dev, bno);
    800035a0:	85a6                	mv	a1,s1
    800035a2:	855e                	mv	a0,s7
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	c58080e7          	jalr	-936(ra) # 800031fc <bread>
    800035ac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035ae:	40000613          	li	a2,1024
    800035b2:	4581                	li	a1,0
    800035b4:	05850513          	addi	a0,a0,88
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	706080e7          	jalr	1798(ra) # 80000cbe <memset>
  log_write(bp);
    800035c0:	854a                	mv	a0,s2
    800035c2:	00001097          	auipc	ra,0x1
    800035c6:	fe6080e7          	jalr	-26(ra) # 800045a8 <log_write>
  brelse(bp);
    800035ca:	854a                	mv	a0,s2
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	d60080e7          	jalr	-672(ra) # 8000332c <brelse>
}
    800035d4:	8526                	mv	a0,s1
    800035d6:	60e6                	ld	ra,88(sp)
    800035d8:	6446                	ld	s0,80(sp)
    800035da:	64a6                	ld	s1,72(sp)
    800035dc:	6906                	ld	s2,64(sp)
    800035de:	79e2                	ld	s3,56(sp)
    800035e0:	7a42                	ld	s4,48(sp)
    800035e2:	7aa2                	ld	s5,40(sp)
    800035e4:	7b02                	ld	s6,32(sp)
    800035e6:	6be2                	ld	s7,24(sp)
    800035e8:	6c42                	ld	s8,16(sp)
    800035ea:	6ca2                	ld	s9,8(sp)
    800035ec:	6125                	addi	sp,sp,96
    800035ee:	8082                	ret

00000000800035f0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035f0:	7179                	addi	sp,sp,-48
    800035f2:	f406                	sd	ra,40(sp)
    800035f4:	f022                	sd	s0,32(sp)
    800035f6:	ec26                	sd	s1,24(sp)
    800035f8:	e84a                	sd	s2,16(sp)
    800035fa:	e44e                	sd	s3,8(sp)
    800035fc:	e052                	sd	s4,0(sp)
    800035fe:	1800                	addi	s0,sp,48
    80003600:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003602:	47ad                	li	a5,11
    80003604:	04b7fe63          	bgeu	a5,a1,80003660 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003608:	ff45849b          	addiw	s1,a1,-12
    8000360c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003610:	0ff00793          	li	a5,255
    80003614:	0ae7e363          	bltu	a5,a4,800036ba <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003618:	08052583          	lw	a1,128(a0)
    8000361c:	c5ad                	beqz	a1,80003686 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000361e:	00092503          	lw	a0,0(s2)
    80003622:	00000097          	auipc	ra,0x0
    80003626:	bda080e7          	jalr	-1062(ra) # 800031fc <bread>
    8000362a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000362c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003630:	02049593          	slli	a1,s1,0x20
    80003634:	9181                	srli	a1,a1,0x20
    80003636:	058a                	slli	a1,a1,0x2
    80003638:	00b784b3          	add	s1,a5,a1
    8000363c:	0004a983          	lw	s3,0(s1)
    80003640:	04098d63          	beqz	s3,8000369a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003644:	8552                	mv	a0,s4
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	ce6080e7          	jalr	-794(ra) # 8000332c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000364e:	854e                	mv	a0,s3
    80003650:	70a2                	ld	ra,40(sp)
    80003652:	7402                	ld	s0,32(sp)
    80003654:	64e2                	ld	s1,24(sp)
    80003656:	6942                	ld	s2,16(sp)
    80003658:	69a2                	ld	s3,8(sp)
    8000365a:	6a02                	ld	s4,0(sp)
    8000365c:	6145                	addi	sp,sp,48
    8000365e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003660:	02059493          	slli	s1,a1,0x20
    80003664:	9081                	srli	s1,s1,0x20
    80003666:	048a                	slli	s1,s1,0x2
    80003668:	94aa                	add	s1,s1,a0
    8000366a:	0504a983          	lw	s3,80(s1)
    8000366e:	fe0990e3          	bnez	s3,8000364e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003672:	4108                	lw	a0,0(a0)
    80003674:	00000097          	auipc	ra,0x0
    80003678:	e4a080e7          	jalr	-438(ra) # 800034be <balloc>
    8000367c:	0005099b          	sext.w	s3,a0
    80003680:	0534a823          	sw	s3,80(s1)
    80003684:	b7e9                	j	8000364e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003686:	4108                	lw	a0,0(a0)
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	e36080e7          	jalr	-458(ra) # 800034be <balloc>
    80003690:	0005059b          	sext.w	a1,a0
    80003694:	08b92023          	sw	a1,128(s2)
    80003698:	b759                	j	8000361e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000369a:	00092503          	lw	a0,0(s2)
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	e20080e7          	jalr	-480(ra) # 800034be <balloc>
    800036a6:	0005099b          	sext.w	s3,a0
    800036aa:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800036ae:	8552                	mv	a0,s4
    800036b0:	00001097          	auipc	ra,0x1
    800036b4:	ef8080e7          	jalr	-264(ra) # 800045a8 <log_write>
    800036b8:	b771                	j	80003644 <bmap+0x54>
  panic("bmap: out of range");
    800036ba:	00005517          	auipc	a0,0x5
    800036be:	f7650513          	addi	a0,a0,-138 # 80008630 <syscalls+0x120>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	e68080e7          	jalr	-408(ra) # 8000052a <panic>

00000000800036ca <iget>:
{
    800036ca:	7179                	addi	sp,sp,-48
    800036cc:	f406                	sd	ra,40(sp)
    800036ce:	f022                	sd	s0,32(sp)
    800036d0:	ec26                	sd	s1,24(sp)
    800036d2:	e84a                	sd	s2,16(sp)
    800036d4:	e44e                	sd	s3,8(sp)
    800036d6:	e052                	sd	s4,0(sp)
    800036d8:	1800                	addi	s0,sp,48
    800036da:	89aa                	mv	s3,a0
    800036dc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036de:	0001d517          	auipc	a0,0x1d
    800036e2:	91a50513          	addi	a0,a0,-1766 # 8001fff8 <itable>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	4dc080e7          	jalr	1244(ra) # 80000bc2 <acquire>
  empty = 0;
    800036ee:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036f0:	0001d497          	auipc	s1,0x1d
    800036f4:	92048493          	addi	s1,s1,-1760 # 80020010 <itable+0x18>
    800036f8:	0001e697          	auipc	a3,0x1e
    800036fc:	3a868693          	addi	a3,a3,936 # 80021aa0 <log>
    80003700:	a039                	j	8000370e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003702:	02090b63          	beqz	s2,80003738 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003706:	08848493          	addi	s1,s1,136
    8000370a:	02d48a63          	beq	s1,a3,8000373e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000370e:	449c                	lw	a5,8(s1)
    80003710:	fef059e3          	blez	a5,80003702 <iget+0x38>
    80003714:	4098                	lw	a4,0(s1)
    80003716:	ff3716e3          	bne	a4,s3,80003702 <iget+0x38>
    8000371a:	40d8                	lw	a4,4(s1)
    8000371c:	ff4713e3          	bne	a4,s4,80003702 <iget+0x38>
      ip->ref++;
    80003720:	2785                	addiw	a5,a5,1
    80003722:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003724:	0001d517          	auipc	a0,0x1d
    80003728:	8d450513          	addi	a0,a0,-1836 # 8001fff8 <itable>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	54a080e7          	jalr	1354(ra) # 80000c76 <release>
      return ip;
    80003734:	8926                	mv	s2,s1
    80003736:	a03d                	j	80003764 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003738:	f7f9                	bnez	a5,80003706 <iget+0x3c>
    8000373a:	8926                	mv	s2,s1
    8000373c:	b7e9                	j	80003706 <iget+0x3c>
  if(empty == 0)
    8000373e:	02090c63          	beqz	s2,80003776 <iget+0xac>
  ip->dev = dev;
    80003742:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003746:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000374a:	4785                	li	a5,1
    8000374c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003750:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003754:	0001d517          	auipc	a0,0x1d
    80003758:	8a450513          	addi	a0,a0,-1884 # 8001fff8 <itable>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	51a080e7          	jalr	1306(ra) # 80000c76 <release>
}
    80003764:	854a                	mv	a0,s2
    80003766:	70a2                	ld	ra,40(sp)
    80003768:	7402                	ld	s0,32(sp)
    8000376a:	64e2                	ld	s1,24(sp)
    8000376c:	6942                	ld	s2,16(sp)
    8000376e:	69a2                	ld	s3,8(sp)
    80003770:	6a02                	ld	s4,0(sp)
    80003772:	6145                	addi	sp,sp,48
    80003774:	8082                	ret
    panic("iget: no inodes");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	ed250513          	addi	a0,a0,-302 # 80008648 <syscalls+0x138>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dac080e7          	jalr	-596(ra) # 8000052a <panic>

0000000080003786 <fsinit>:
fsinit(int dev) {
    80003786:	7179                	addi	sp,sp,-48
    80003788:	f406                	sd	ra,40(sp)
    8000378a:	f022                	sd	s0,32(sp)
    8000378c:	ec26                	sd	s1,24(sp)
    8000378e:	e84a                	sd	s2,16(sp)
    80003790:	e44e                	sd	s3,8(sp)
    80003792:	1800                	addi	s0,sp,48
    80003794:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003796:	4585                	li	a1,1
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	a64080e7          	jalr	-1436(ra) # 800031fc <bread>
    800037a0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037a2:	0001d997          	auipc	s3,0x1d
    800037a6:	83698993          	addi	s3,s3,-1994 # 8001ffd8 <sb>
    800037aa:	02000613          	li	a2,32
    800037ae:	05850593          	addi	a1,a0,88
    800037b2:	854e                	mv	a0,s3
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	566080e7          	jalr	1382(ra) # 80000d1a <memmove>
  brelse(bp);
    800037bc:	8526                	mv	a0,s1
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	b6e080e7          	jalr	-1170(ra) # 8000332c <brelse>
  if(sb.magic != FSMAGIC)
    800037c6:	0009a703          	lw	a4,0(s3)
    800037ca:	102037b7          	lui	a5,0x10203
    800037ce:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037d2:	02f71263          	bne	a4,a5,800037f6 <fsinit+0x70>
  initlog(dev, &sb);
    800037d6:	0001d597          	auipc	a1,0x1d
    800037da:	80258593          	addi	a1,a1,-2046 # 8001ffd8 <sb>
    800037de:	854a                	mv	a0,s2
    800037e0:	00001097          	auipc	ra,0x1
    800037e4:	b4c080e7          	jalr	-1204(ra) # 8000432c <initlog>
}
    800037e8:	70a2                	ld	ra,40(sp)
    800037ea:	7402                	ld	s0,32(sp)
    800037ec:	64e2                	ld	s1,24(sp)
    800037ee:	6942                	ld	s2,16(sp)
    800037f0:	69a2                	ld	s3,8(sp)
    800037f2:	6145                	addi	sp,sp,48
    800037f4:	8082                	ret
    panic("invalid file system");
    800037f6:	00005517          	auipc	a0,0x5
    800037fa:	e6250513          	addi	a0,a0,-414 # 80008658 <syscalls+0x148>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	d2c080e7          	jalr	-724(ra) # 8000052a <panic>

0000000080003806 <iinit>:
{
    80003806:	7179                	addi	sp,sp,-48
    80003808:	f406                	sd	ra,40(sp)
    8000380a:	f022                	sd	s0,32(sp)
    8000380c:	ec26                	sd	s1,24(sp)
    8000380e:	e84a                	sd	s2,16(sp)
    80003810:	e44e                	sd	s3,8(sp)
    80003812:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003814:	00005597          	auipc	a1,0x5
    80003818:	e5c58593          	addi	a1,a1,-420 # 80008670 <syscalls+0x160>
    8000381c:	0001c517          	auipc	a0,0x1c
    80003820:	7dc50513          	addi	a0,a0,2012 # 8001fff8 <itable>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	30e080e7          	jalr	782(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000382c:	0001c497          	auipc	s1,0x1c
    80003830:	7f448493          	addi	s1,s1,2036 # 80020020 <itable+0x28>
    80003834:	0001e997          	auipc	s3,0x1e
    80003838:	27c98993          	addi	s3,s3,636 # 80021ab0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000383c:	00005917          	auipc	s2,0x5
    80003840:	e3c90913          	addi	s2,s2,-452 # 80008678 <syscalls+0x168>
    80003844:	85ca                	mv	a1,s2
    80003846:	8526                	mv	a0,s1
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	e46080e7          	jalr	-442(ra) # 8000468e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003850:	08848493          	addi	s1,s1,136
    80003854:	ff3498e3          	bne	s1,s3,80003844 <iinit+0x3e>
}
    80003858:	70a2                	ld	ra,40(sp)
    8000385a:	7402                	ld	s0,32(sp)
    8000385c:	64e2                	ld	s1,24(sp)
    8000385e:	6942                	ld	s2,16(sp)
    80003860:	69a2                	ld	s3,8(sp)
    80003862:	6145                	addi	sp,sp,48
    80003864:	8082                	ret

0000000080003866 <ialloc>:
{
    80003866:	715d                	addi	sp,sp,-80
    80003868:	e486                	sd	ra,72(sp)
    8000386a:	e0a2                	sd	s0,64(sp)
    8000386c:	fc26                	sd	s1,56(sp)
    8000386e:	f84a                	sd	s2,48(sp)
    80003870:	f44e                	sd	s3,40(sp)
    80003872:	f052                	sd	s4,32(sp)
    80003874:	ec56                	sd	s5,24(sp)
    80003876:	e85a                	sd	s6,16(sp)
    80003878:	e45e                	sd	s7,8(sp)
    8000387a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000387c:	0001c717          	auipc	a4,0x1c
    80003880:	76872703          	lw	a4,1896(a4) # 8001ffe4 <sb+0xc>
    80003884:	4785                	li	a5,1
    80003886:	04e7fa63          	bgeu	a5,a4,800038da <ialloc+0x74>
    8000388a:	8aaa                	mv	s5,a0
    8000388c:	8bae                	mv	s7,a1
    8000388e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003890:	0001ca17          	auipc	s4,0x1c
    80003894:	748a0a13          	addi	s4,s4,1864 # 8001ffd8 <sb>
    80003898:	00048b1b          	sext.w	s6,s1
    8000389c:	0044d793          	srli	a5,s1,0x4
    800038a0:	018a2583          	lw	a1,24(s4)
    800038a4:	9dbd                	addw	a1,a1,a5
    800038a6:	8556                	mv	a0,s5
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	954080e7          	jalr	-1708(ra) # 800031fc <bread>
    800038b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038b2:	05850993          	addi	s3,a0,88
    800038b6:	00f4f793          	andi	a5,s1,15
    800038ba:	079a                	slli	a5,a5,0x6
    800038bc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038be:	00099783          	lh	a5,0(s3)
    800038c2:	c785                	beqz	a5,800038ea <ialloc+0x84>
    brelse(bp);
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	a68080e7          	jalr	-1432(ra) # 8000332c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038cc:	0485                	addi	s1,s1,1
    800038ce:	00ca2703          	lw	a4,12(s4)
    800038d2:	0004879b          	sext.w	a5,s1
    800038d6:	fce7e1e3          	bltu	a5,a4,80003898 <ialloc+0x32>
  panic("ialloc: no inodes");
    800038da:	00005517          	auipc	a0,0x5
    800038de:	da650513          	addi	a0,a0,-602 # 80008680 <syscalls+0x170>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	c48080e7          	jalr	-952(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800038ea:	04000613          	li	a2,64
    800038ee:	4581                	li	a1,0
    800038f0:	854e                	mv	a0,s3
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	3cc080e7          	jalr	972(ra) # 80000cbe <memset>
      dip->type = type;
    800038fa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038fe:	854a                	mv	a0,s2
    80003900:	00001097          	auipc	ra,0x1
    80003904:	ca8080e7          	jalr	-856(ra) # 800045a8 <log_write>
      brelse(bp);
    80003908:	854a                	mv	a0,s2
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	a22080e7          	jalr	-1502(ra) # 8000332c <brelse>
      return iget(dev, inum);
    80003912:	85da                	mv	a1,s6
    80003914:	8556                	mv	a0,s5
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	db4080e7          	jalr	-588(ra) # 800036ca <iget>
}
    8000391e:	60a6                	ld	ra,72(sp)
    80003920:	6406                	ld	s0,64(sp)
    80003922:	74e2                	ld	s1,56(sp)
    80003924:	7942                	ld	s2,48(sp)
    80003926:	79a2                	ld	s3,40(sp)
    80003928:	7a02                	ld	s4,32(sp)
    8000392a:	6ae2                	ld	s5,24(sp)
    8000392c:	6b42                	ld	s6,16(sp)
    8000392e:	6ba2                	ld	s7,8(sp)
    80003930:	6161                	addi	sp,sp,80
    80003932:	8082                	ret

0000000080003934 <iupdate>:
{
    80003934:	1101                	addi	sp,sp,-32
    80003936:	ec06                	sd	ra,24(sp)
    80003938:	e822                	sd	s0,16(sp)
    8000393a:	e426                	sd	s1,8(sp)
    8000393c:	e04a                	sd	s2,0(sp)
    8000393e:	1000                	addi	s0,sp,32
    80003940:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003942:	415c                	lw	a5,4(a0)
    80003944:	0047d79b          	srliw	a5,a5,0x4
    80003948:	0001c597          	auipc	a1,0x1c
    8000394c:	6a85a583          	lw	a1,1704(a1) # 8001fff0 <sb+0x18>
    80003950:	9dbd                	addw	a1,a1,a5
    80003952:	4108                	lw	a0,0(a0)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	8a8080e7          	jalr	-1880(ra) # 800031fc <bread>
    8000395c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395e:	05850793          	addi	a5,a0,88
    80003962:	40c8                	lw	a0,4(s1)
    80003964:	893d                	andi	a0,a0,15
    80003966:	051a                	slli	a0,a0,0x6
    80003968:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000396a:	04449703          	lh	a4,68(s1)
    8000396e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003972:	04649703          	lh	a4,70(s1)
    80003976:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000397a:	04849703          	lh	a4,72(s1)
    8000397e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003982:	04a49703          	lh	a4,74(s1)
    80003986:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000398a:	44f8                	lw	a4,76(s1)
    8000398c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000398e:	03400613          	li	a2,52
    80003992:	05048593          	addi	a1,s1,80
    80003996:	0531                	addi	a0,a0,12
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	382080e7          	jalr	898(ra) # 80000d1a <memmove>
  log_write(bp);
    800039a0:	854a                	mv	a0,s2
    800039a2:	00001097          	auipc	ra,0x1
    800039a6:	c06080e7          	jalr	-1018(ra) # 800045a8 <log_write>
  brelse(bp);
    800039aa:	854a                	mv	a0,s2
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	980080e7          	jalr	-1664(ra) # 8000332c <brelse>
}
    800039b4:	60e2                	ld	ra,24(sp)
    800039b6:	6442                	ld	s0,16(sp)
    800039b8:	64a2                	ld	s1,8(sp)
    800039ba:	6902                	ld	s2,0(sp)
    800039bc:	6105                	addi	sp,sp,32
    800039be:	8082                	ret

00000000800039c0 <idup>:
{
    800039c0:	1101                	addi	sp,sp,-32
    800039c2:	ec06                	sd	ra,24(sp)
    800039c4:	e822                	sd	s0,16(sp)
    800039c6:	e426                	sd	s1,8(sp)
    800039c8:	1000                	addi	s0,sp,32
    800039ca:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039cc:	0001c517          	auipc	a0,0x1c
    800039d0:	62c50513          	addi	a0,a0,1580 # 8001fff8 <itable>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	1ee080e7          	jalr	494(ra) # 80000bc2 <acquire>
  ip->ref++;
    800039dc:	449c                	lw	a5,8(s1)
    800039de:	2785                	addiw	a5,a5,1
    800039e0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039e2:	0001c517          	auipc	a0,0x1c
    800039e6:	61650513          	addi	a0,a0,1558 # 8001fff8 <itable>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	28c080e7          	jalr	652(ra) # 80000c76 <release>
}
    800039f2:	8526                	mv	a0,s1
    800039f4:	60e2                	ld	ra,24(sp)
    800039f6:	6442                	ld	s0,16(sp)
    800039f8:	64a2                	ld	s1,8(sp)
    800039fa:	6105                	addi	sp,sp,32
    800039fc:	8082                	ret

00000000800039fe <ilock>:
{
    800039fe:	1101                	addi	sp,sp,-32
    80003a00:	ec06                	sd	ra,24(sp)
    80003a02:	e822                	sd	s0,16(sp)
    80003a04:	e426                	sd	s1,8(sp)
    80003a06:	e04a                	sd	s2,0(sp)
    80003a08:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a0a:	c115                	beqz	a0,80003a2e <ilock+0x30>
    80003a0c:	84aa                	mv	s1,a0
    80003a0e:	451c                	lw	a5,8(a0)
    80003a10:	00f05f63          	blez	a5,80003a2e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a14:	0541                	addi	a0,a0,16
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	cb2080e7          	jalr	-846(ra) # 800046c8 <acquiresleep>
  if(ip->valid == 0){
    80003a1e:	40bc                	lw	a5,64(s1)
    80003a20:	cf99                	beqz	a5,80003a3e <ilock+0x40>
}
    80003a22:	60e2                	ld	ra,24(sp)
    80003a24:	6442                	ld	s0,16(sp)
    80003a26:	64a2                	ld	s1,8(sp)
    80003a28:	6902                	ld	s2,0(sp)
    80003a2a:	6105                	addi	sp,sp,32
    80003a2c:	8082                	ret
    panic("ilock");
    80003a2e:	00005517          	auipc	a0,0x5
    80003a32:	c6a50513          	addi	a0,a0,-918 # 80008698 <syscalls+0x188>
    80003a36:	ffffd097          	auipc	ra,0xffffd
    80003a3a:	af4080e7          	jalr	-1292(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a3e:	40dc                	lw	a5,4(s1)
    80003a40:	0047d79b          	srliw	a5,a5,0x4
    80003a44:	0001c597          	auipc	a1,0x1c
    80003a48:	5ac5a583          	lw	a1,1452(a1) # 8001fff0 <sb+0x18>
    80003a4c:	9dbd                	addw	a1,a1,a5
    80003a4e:	4088                	lw	a0,0(s1)
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	7ac080e7          	jalr	1964(ra) # 800031fc <bread>
    80003a58:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a5a:	05850593          	addi	a1,a0,88
    80003a5e:	40dc                	lw	a5,4(s1)
    80003a60:	8bbd                	andi	a5,a5,15
    80003a62:	079a                	slli	a5,a5,0x6
    80003a64:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a66:	00059783          	lh	a5,0(a1)
    80003a6a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a6e:	00259783          	lh	a5,2(a1)
    80003a72:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a76:	00459783          	lh	a5,4(a1)
    80003a7a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a7e:	00659783          	lh	a5,6(a1)
    80003a82:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a86:	459c                	lw	a5,8(a1)
    80003a88:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a8a:	03400613          	li	a2,52
    80003a8e:	05b1                	addi	a1,a1,12
    80003a90:	05048513          	addi	a0,s1,80
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	286080e7          	jalr	646(ra) # 80000d1a <memmove>
    brelse(bp);
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	88e080e7          	jalr	-1906(ra) # 8000332c <brelse>
    ip->valid = 1;
    80003aa6:	4785                	li	a5,1
    80003aa8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003aaa:	04449783          	lh	a5,68(s1)
    80003aae:	fbb5                	bnez	a5,80003a22 <ilock+0x24>
      panic("ilock: no type");
    80003ab0:	00005517          	auipc	a0,0x5
    80003ab4:	bf050513          	addi	a0,a0,-1040 # 800086a0 <syscalls+0x190>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	a72080e7          	jalr	-1422(ra) # 8000052a <panic>

0000000080003ac0 <iunlock>:
{
    80003ac0:	1101                	addi	sp,sp,-32
    80003ac2:	ec06                	sd	ra,24(sp)
    80003ac4:	e822                	sd	s0,16(sp)
    80003ac6:	e426                	sd	s1,8(sp)
    80003ac8:	e04a                	sd	s2,0(sp)
    80003aca:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003acc:	c905                	beqz	a0,80003afc <iunlock+0x3c>
    80003ace:	84aa                	mv	s1,a0
    80003ad0:	01050913          	addi	s2,a0,16
    80003ad4:	854a                	mv	a0,s2
    80003ad6:	00001097          	auipc	ra,0x1
    80003ada:	c8c080e7          	jalr	-884(ra) # 80004762 <holdingsleep>
    80003ade:	cd19                	beqz	a0,80003afc <iunlock+0x3c>
    80003ae0:	449c                	lw	a5,8(s1)
    80003ae2:	00f05d63          	blez	a5,80003afc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	00001097          	auipc	ra,0x1
    80003aec:	c36080e7          	jalr	-970(ra) # 8000471e <releasesleep>
}
    80003af0:	60e2                	ld	ra,24(sp)
    80003af2:	6442                	ld	s0,16(sp)
    80003af4:	64a2                	ld	s1,8(sp)
    80003af6:	6902                	ld	s2,0(sp)
    80003af8:	6105                	addi	sp,sp,32
    80003afa:	8082                	ret
    panic("iunlock");
    80003afc:	00005517          	auipc	a0,0x5
    80003b00:	bb450513          	addi	a0,a0,-1100 # 800086b0 <syscalls+0x1a0>
    80003b04:	ffffd097          	auipc	ra,0xffffd
    80003b08:	a26080e7          	jalr	-1498(ra) # 8000052a <panic>

0000000080003b0c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b0c:	7179                	addi	sp,sp,-48
    80003b0e:	f406                	sd	ra,40(sp)
    80003b10:	f022                	sd	s0,32(sp)
    80003b12:	ec26                	sd	s1,24(sp)
    80003b14:	e84a                	sd	s2,16(sp)
    80003b16:	e44e                	sd	s3,8(sp)
    80003b18:	e052                	sd	s4,0(sp)
    80003b1a:	1800                	addi	s0,sp,48
    80003b1c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b1e:	05050493          	addi	s1,a0,80
    80003b22:	08050913          	addi	s2,a0,128
    80003b26:	a021                	j	80003b2e <itrunc+0x22>
    80003b28:	0491                	addi	s1,s1,4
    80003b2a:	01248d63          	beq	s1,s2,80003b44 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b2e:	408c                	lw	a1,0(s1)
    80003b30:	dde5                	beqz	a1,80003b28 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b32:	0009a503          	lw	a0,0(s3)
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	90c080e7          	jalr	-1780(ra) # 80003442 <bfree>
      ip->addrs[i] = 0;
    80003b3e:	0004a023          	sw	zero,0(s1)
    80003b42:	b7dd                	j	80003b28 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b44:	0809a583          	lw	a1,128(s3)
    80003b48:	e185                	bnez	a1,80003b68 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b4a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b4e:	854e                	mv	a0,s3
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	de4080e7          	jalr	-540(ra) # 80003934 <iupdate>
}
    80003b58:	70a2                	ld	ra,40(sp)
    80003b5a:	7402                	ld	s0,32(sp)
    80003b5c:	64e2                	ld	s1,24(sp)
    80003b5e:	6942                	ld	s2,16(sp)
    80003b60:	69a2                	ld	s3,8(sp)
    80003b62:	6a02                	ld	s4,0(sp)
    80003b64:	6145                	addi	sp,sp,48
    80003b66:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b68:	0009a503          	lw	a0,0(s3)
    80003b6c:	fffff097          	auipc	ra,0xfffff
    80003b70:	690080e7          	jalr	1680(ra) # 800031fc <bread>
    80003b74:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b76:	05850493          	addi	s1,a0,88
    80003b7a:	45850913          	addi	s2,a0,1112
    80003b7e:	a021                	j	80003b86 <itrunc+0x7a>
    80003b80:	0491                	addi	s1,s1,4
    80003b82:	01248b63          	beq	s1,s2,80003b98 <itrunc+0x8c>
      if(a[j])
    80003b86:	408c                	lw	a1,0(s1)
    80003b88:	dde5                	beqz	a1,80003b80 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b8a:	0009a503          	lw	a0,0(s3)
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	8b4080e7          	jalr	-1868(ra) # 80003442 <bfree>
    80003b96:	b7ed                	j	80003b80 <itrunc+0x74>
    brelse(bp);
    80003b98:	8552                	mv	a0,s4
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	792080e7          	jalr	1938(ra) # 8000332c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ba2:	0809a583          	lw	a1,128(s3)
    80003ba6:	0009a503          	lw	a0,0(s3)
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	898080e7          	jalr	-1896(ra) # 80003442 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bb2:	0809a023          	sw	zero,128(s3)
    80003bb6:	bf51                	j	80003b4a <itrunc+0x3e>

0000000080003bb8 <iput>:
{
    80003bb8:	1101                	addi	sp,sp,-32
    80003bba:	ec06                	sd	ra,24(sp)
    80003bbc:	e822                	sd	s0,16(sp)
    80003bbe:	e426                	sd	s1,8(sp)
    80003bc0:	e04a                	sd	s2,0(sp)
    80003bc2:	1000                	addi	s0,sp,32
    80003bc4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bc6:	0001c517          	auipc	a0,0x1c
    80003bca:	43250513          	addi	a0,a0,1074 # 8001fff8 <itable>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	ff4080e7          	jalr	-12(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bd6:	4498                	lw	a4,8(s1)
    80003bd8:	4785                	li	a5,1
    80003bda:	02f70363          	beq	a4,a5,80003c00 <iput+0x48>
  ip->ref--;
    80003bde:	449c                	lw	a5,8(s1)
    80003be0:	37fd                	addiw	a5,a5,-1
    80003be2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003be4:	0001c517          	auipc	a0,0x1c
    80003be8:	41450513          	addi	a0,a0,1044 # 8001fff8 <itable>
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	08a080e7          	jalr	138(ra) # 80000c76 <release>
}
    80003bf4:	60e2                	ld	ra,24(sp)
    80003bf6:	6442                	ld	s0,16(sp)
    80003bf8:	64a2                	ld	s1,8(sp)
    80003bfa:	6902                	ld	s2,0(sp)
    80003bfc:	6105                	addi	sp,sp,32
    80003bfe:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c00:	40bc                	lw	a5,64(s1)
    80003c02:	dff1                	beqz	a5,80003bde <iput+0x26>
    80003c04:	04a49783          	lh	a5,74(s1)
    80003c08:	fbf9                	bnez	a5,80003bde <iput+0x26>
    acquiresleep(&ip->lock);
    80003c0a:	01048913          	addi	s2,s1,16
    80003c0e:	854a                	mv	a0,s2
    80003c10:	00001097          	auipc	ra,0x1
    80003c14:	ab8080e7          	jalr	-1352(ra) # 800046c8 <acquiresleep>
    release(&itable.lock);
    80003c18:	0001c517          	auipc	a0,0x1c
    80003c1c:	3e050513          	addi	a0,a0,992 # 8001fff8 <itable>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	056080e7          	jalr	86(ra) # 80000c76 <release>
    itrunc(ip);
    80003c28:	8526                	mv	a0,s1
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	ee2080e7          	jalr	-286(ra) # 80003b0c <itrunc>
    ip->type = 0;
    80003c32:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c36:	8526                	mv	a0,s1
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	cfc080e7          	jalr	-772(ra) # 80003934 <iupdate>
    ip->valid = 0;
    80003c40:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c44:	854a                	mv	a0,s2
    80003c46:	00001097          	auipc	ra,0x1
    80003c4a:	ad8080e7          	jalr	-1320(ra) # 8000471e <releasesleep>
    acquire(&itable.lock);
    80003c4e:	0001c517          	auipc	a0,0x1c
    80003c52:	3aa50513          	addi	a0,a0,938 # 8001fff8 <itable>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	f6c080e7          	jalr	-148(ra) # 80000bc2 <acquire>
    80003c5e:	b741                	j	80003bde <iput+0x26>

0000000080003c60 <iunlockput>:
{
    80003c60:	1101                	addi	sp,sp,-32
    80003c62:	ec06                	sd	ra,24(sp)
    80003c64:	e822                	sd	s0,16(sp)
    80003c66:	e426                	sd	s1,8(sp)
    80003c68:	1000                	addi	s0,sp,32
    80003c6a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	e54080e7          	jalr	-428(ra) # 80003ac0 <iunlock>
  iput(ip);
    80003c74:	8526                	mv	a0,s1
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	f42080e7          	jalr	-190(ra) # 80003bb8 <iput>
}
    80003c7e:	60e2                	ld	ra,24(sp)
    80003c80:	6442                	ld	s0,16(sp)
    80003c82:	64a2                	ld	s1,8(sp)
    80003c84:	6105                	addi	sp,sp,32
    80003c86:	8082                	ret

0000000080003c88 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c88:	1141                	addi	sp,sp,-16
    80003c8a:	e422                	sd	s0,8(sp)
    80003c8c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c8e:	411c                	lw	a5,0(a0)
    80003c90:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c92:	415c                	lw	a5,4(a0)
    80003c94:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c96:	04451783          	lh	a5,68(a0)
    80003c9a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c9e:	04a51783          	lh	a5,74(a0)
    80003ca2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ca6:	04c56783          	lwu	a5,76(a0)
    80003caa:	e99c                	sd	a5,16(a1)
}
    80003cac:	6422                	ld	s0,8(sp)
    80003cae:	0141                	addi	sp,sp,16
    80003cb0:	8082                	ret

0000000080003cb2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cb2:	457c                	lw	a5,76(a0)
    80003cb4:	0ed7e963          	bltu	a5,a3,80003da6 <readi+0xf4>
{
    80003cb8:	7159                	addi	sp,sp,-112
    80003cba:	f486                	sd	ra,104(sp)
    80003cbc:	f0a2                	sd	s0,96(sp)
    80003cbe:	eca6                	sd	s1,88(sp)
    80003cc0:	e8ca                	sd	s2,80(sp)
    80003cc2:	e4ce                	sd	s3,72(sp)
    80003cc4:	e0d2                	sd	s4,64(sp)
    80003cc6:	fc56                	sd	s5,56(sp)
    80003cc8:	f85a                	sd	s6,48(sp)
    80003cca:	f45e                	sd	s7,40(sp)
    80003ccc:	f062                	sd	s8,32(sp)
    80003cce:	ec66                	sd	s9,24(sp)
    80003cd0:	e86a                	sd	s10,16(sp)
    80003cd2:	e46e                	sd	s11,8(sp)
    80003cd4:	1880                	addi	s0,sp,112
    80003cd6:	8baa                	mv	s7,a0
    80003cd8:	8c2e                	mv	s8,a1
    80003cda:	8ab2                	mv	s5,a2
    80003cdc:	84b6                	mv	s1,a3
    80003cde:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ce0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ce2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ce4:	0ad76063          	bltu	a4,a3,80003d84 <readi+0xd2>
  if(off + n > ip->size)
    80003ce8:	00e7f463          	bgeu	a5,a4,80003cf0 <readi+0x3e>
    n = ip->size - off;
    80003cec:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf0:	0a0b0963          	beqz	s6,80003da2 <readi+0xf0>
    80003cf4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cfa:	5cfd                	li	s9,-1
    80003cfc:	a82d                	j	80003d36 <readi+0x84>
    80003cfe:	020a1d93          	slli	s11,s4,0x20
    80003d02:	020ddd93          	srli	s11,s11,0x20
    80003d06:	05890793          	addi	a5,s2,88
    80003d0a:	86ee                	mv	a3,s11
    80003d0c:	963e                	add	a2,a2,a5
    80003d0e:	85d6                	mv	a1,s5
    80003d10:	8562                	mv	a0,s8
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	a6c080e7          	jalr	-1428(ra) # 8000277e <either_copyout>
    80003d1a:	05950d63          	beq	a0,s9,80003d74 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d1e:	854a                	mv	a0,s2
    80003d20:	fffff097          	auipc	ra,0xfffff
    80003d24:	60c080e7          	jalr	1548(ra) # 8000332c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d28:	013a09bb          	addw	s3,s4,s3
    80003d2c:	009a04bb          	addw	s1,s4,s1
    80003d30:	9aee                	add	s5,s5,s11
    80003d32:	0569f763          	bgeu	s3,s6,80003d80 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d36:	000ba903          	lw	s2,0(s7)
    80003d3a:	00a4d59b          	srliw	a1,s1,0xa
    80003d3e:	855e                	mv	a0,s7
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	8b0080e7          	jalr	-1872(ra) # 800035f0 <bmap>
    80003d48:	0005059b          	sext.w	a1,a0
    80003d4c:	854a                	mv	a0,s2
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	4ae080e7          	jalr	1198(ra) # 800031fc <bread>
    80003d56:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d58:	3ff4f613          	andi	a2,s1,1023
    80003d5c:	40cd07bb          	subw	a5,s10,a2
    80003d60:	413b073b          	subw	a4,s6,s3
    80003d64:	8a3e                	mv	s4,a5
    80003d66:	2781                	sext.w	a5,a5
    80003d68:	0007069b          	sext.w	a3,a4
    80003d6c:	f8f6f9e3          	bgeu	a3,a5,80003cfe <readi+0x4c>
    80003d70:	8a3a                	mv	s4,a4
    80003d72:	b771                	j	80003cfe <readi+0x4c>
      brelse(bp);
    80003d74:	854a                	mv	a0,s2
    80003d76:	fffff097          	auipc	ra,0xfffff
    80003d7a:	5b6080e7          	jalr	1462(ra) # 8000332c <brelse>
      tot = -1;
    80003d7e:	59fd                	li	s3,-1
  }
  return tot;
    80003d80:	0009851b          	sext.w	a0,s3
}
    80003d84:	70a6                	ld	ra,104(sp)
    80003d86:	7406                	ld	s0,96(sp)
    80003d88:	64e6                	ld	s1,88(sp)
    80003d8a:	6946                	ld	s2,80(sp)
    80003d8c:	69a6                	ld	s3,72(sp)
    80003d8e:	6a06                	ld	s4,64(sp)
    80003d90:	7ae2                	ld	s5,56(sp)
    80003d92:	7b42                	ld	s6,48(sp)
    80003d94:	7ba2                	ld	s7,40(sp)
    80003d96:	7c02                	ld	s8,32(sp)
    80003d98:	6ce2                	ld	s9,24(sp)
    80003d9a:	6d42                	ld	s10,16(sp)
    80003d9c:	6da2                	ld	s11,8(sp)
    80003d9e:	6165                	addi	sp,sp,112
    80003da0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003da2:	89da                	mv	s3,s6
    80003da4:	bff1                	j	80003d80 <readi+0xce>
    return 0;
    80003da6:	4501                	li	a0,0
}
    80003da8:	8082                	ret

0000000080003daa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003daa:	457c                	lw	a5,76(a0)
    80003dac:	10d7e863          	bltu	a5,a3,80003ebc <writei+0x112>
{
    80003db0:	7159                	addi	sp,sp,-112
    80003db2:	f486                	sd	ra,104(sp)
    80003db4:	f0a2                	sd	s0,96(sp)
    80003db6:	eca6                	sd	s1,88(sp)
    80003db8:	e8ca                	sd	s2,80(sp)
    80003dba:	e4ce                	sd	s3,72(sp)
    80003dbc:	e0d2                	sd	s4,64(sp)
    80003dbe:	fc56                	sd	s5,56(sp)
    80003dc0:	f85a                	sd	s6,48(sp)
    80003dc2:	f45e                	sd	s7,40(sp)
    80003dc4:	f062                	sd	s8,32(sp)
    80003dc6:	ec66                	sd	s9,24(sp)
    80003dc8:	e86a                	sd	s10,16(sp)
    80003dca:	e46e                	sd	s11,8(sp)
    80003dcc:	1880                	addi	s0,sp,112
    80003dce:	8b2a                	mv	s6,a0
    80003dd0:	8c2e                	mv	s8,a1
    80003dd2:	8ab2                	mv	s5,a2
    80003dd4:	8936                	mv	s2,a3
    80003dd6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003dd8:	00e687bb          	addw	a5,a3,a4
    80003ddc:	0ed7e263          	bltu	a5,a3,80003ec0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003de0:	00043737          	lui	a4,0x43
    80003de4:	0ef76063          	bltu	a4,a5,80003ec4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de8:	0c0b8863          	beqz	s7,80003eb8 <writei+0x10e>
    80003dec:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dee:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003df2:	5cfd                	li	s9,-1
    80003df4:	a091                	j	80003e38 <writei+0x8e>
    80003df6:	02099d93          	slli	s11,s3,0x20
    80003dfa:	020ddd93          	srli	s11,s11,0x20
    80003dfe:	05848793          	addi	a5,s1,88
    80003e02:	86ee                	mv	a3,s11
    80003e04:	8656                	mv	a2,s5
    80003e06:	85e2                	mv	a1,s8
    80003e08:	953e                	add	a0,a0,a5
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	9ca080e7          	jalr	-1590(ra) # 800027d4 <either_copyin>
    80003e12:	07950263          	beq	a0,s9,80003e76 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e16:	8526                	mv	a0,s1
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	790080e7          	jalr	1936(ra) # 800045a8 <log_write>
    brelse(bp);
    80003e20:	8526                	mv	a0,s1
    80003e22:	fffff097          	auipc	ra,0xfffff
    80003e26:	50a080e7          	jalr	1290(ra) # 8000332c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e2a:	01498a3b          	addw	s4,s3,s4
    80003e2e:	0129893b          	addw	s2,s3,s2
    80003e32:	9aee                	add	s5,s5,s11
    80003e34:	057a7663          	bgeu	s4,s7,80003e80 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e38:	000b2483          	lw	s1,0(s6)
    80003e3c:	00a9559b          	srliw	a1,s2,0xa
    80003e40:	855a                	mv	a0,s6
    80003e42:	fffff097          	auipc	ra,0xfffff
    80003e46:	7ae080e7          	jalr	1966(ra) # 800035f0 <bmap>
    80003e4a:	0005059b          	sext.w	a1,a0
    80003e4e:	8526                	mv	a0,s1
    80003e50:	fffff097          	auipc	ra,0xfffff
    80003e54:	3ac080e7          	jalr	940(ra) # 800031fc <bread>
    80003e58:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5a:	3ff97513          	andi	a0,s2,1023
    80003e5e:	40ad07bb          	subw	a5,s10,a0
    80003e62:	414b873b          	subw	a4,s7,s4
    80003e66:	89be                	mv	s3,a5
    80003e68:	2781                	sext.w	a5,a5
    80003e6a:	0007069b          	sext.w	a3,a4
    80003e6e:	f8f6f4e3          	bgeu	a3,a5,80003df6 <writei+0x4c>
    80003e72:	89ba                	mv	s3,a4
    80003e74:	b749                	j	80003df6 <writei+0x4c>
      brelse(bp);
    80003e76:	8526                	mv	a0,s1
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	4b4080e7          	jalr	1204(ra) # 8000332c <brelse>
  }

  if(off > ip->size)
    80003e80:	04cb2783          	lw	a5,76(s6)
    80003e84:	0127f463          	bgeu	a5,s2,80003e8c <writei+0xe2>
    ip->size = off;
    80003e88:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e8c:	855a                	mv	a0,s6
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	aa6080e7          	jalr	-1370(ra) # 80003934 <iupdate>

  return tot;
    80003e96:	000a051b          	sext.w	a0,s4
}
    80003e9a:	70a6                	ld	ra,104(sp)
    80003e9c:	7406                	ld	s0,96(sp)
    80003e9e:	64e6                	ld	s1,88(sp)
    80003ea0:	6946                	ld	s2,80(sp)
    80003ea2:	69a6                	ld	s3,72(sp)
    80003ea4:	6a06                	ld	s4,64(sp)
    80003ea6:	7ae2                	ld	s5,56(sp)
    80003ea8:	7b42                	ld	s6,48(sp)
    80003eaa:	7ba2                	ld	s7,40(sp)
    80003eac:	7c02                	ld	s8,32(sp)
    80003eae:	6ce2                	ld	s9,24(sp)
    80003eb0:	6d42                	ld	s10,16(sp)
    80003eb2:	6da2                	ld	s11,8(sp)
    80003eb4:	6165                	addi	sp,sp,112
    80003eb6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eb8:	8a5e                	mv	s4,s7
    80003eba:	bfc9                	j	80003e8c <writei+0xe2>
    return -1;
    80003ebc:	557d                	li	a0,-1
}
    80003ebe:	8082                	ret
    return -1;
    80003ec0:	557d                	li	a0,-1
    80003ec2:	bfe1                	j	80003e9a <writei+0xf0>
    return -1;
    80003ec4:	557d                	li	a0,-1
    80003ec6:	bfd1                	j	80003e9a <writei+0xf0>

0000000080003ec8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ec8:	1141                	addi	sp,sp,-16
    80003eca:	e406                	sd	ra,8(sp)
    80003ecc:	e022                	sd	s0,0(sp)
    80003ece:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ed0:	4639                	li	a2,14
    80003ed2:	ffffd097          	auipc	ra,0xffffd
    80003ed6:	ec4080e7          	jalr	-316(ra) # 80000d96 <strncmp>
}
    80003eda:	60a2                	ld	ra,8(sp)
    80003edc:	6402                	ld	s0,0(sp)
    80003ede:	0141                	addi	sp,sp,16
    80003ee0:	8082                	ret

0000000080003ee2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ee2:	7139                	addi	sp,sp,-64
    80003ee4:	fc06                	sd	ra,56(sp)
    80003ee6:	f822                	sd	s0,48(sp)
    80003ee8:	f426                	sd	s1,40(sp)
    80003eea:	f04a                	sd	s2,32(sp)
    80003eec:	ec4e                	sd	s3,24(sp)
    80003eee:	e852                	sd	s4,16(sp)
    80003ef0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ef2:	04451703          	lh	a4,68(a0)
    80003ef6:	4785                	li	a5,1
    80003ef8:	00f71a63          	bne	a4,a5,80003f0c <dirlookup+0x2a>
    80003efc:	892a                	mv	s2,a0
    80003efe:	89ae                	mv	s3,a1
    80003f00:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f02:	457c                	lw	a5,76(a0)
    80003f04:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f06:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f08:	e79d                	bnez	a5,80003f36 <dirlookup+0x54>
    80003f0a:	a8a5                	j	80003f82 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f0c:	00004517          	auipc	a0,0x4
    80003f10:	7ac50513          	addi	a0,a0,1964 # 800086b8 <syscalls+0x1a8>
    80003f14:	ffffc097          	auipc	ra,0xffffc
    80003f18:	616080e7          	jalr	1558(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003f1c:	00004517          	auipc	a0,0x4
    80003f20:	7b450513          	addi	a0,a0,1972 # 800086d0 <syscalls+0x1c0>
    80003f24:	ffffc097          	auipc	ra,0xffffc
    80003f28:	606080e7          	jalr	1542(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f2c:	24c1                	addiw	s1,s1,16
    80003f2e:	04c92783          	lw	a5,76(s2)
    80003f32:	04f4f763          	bgeu	s1,a5,80003f80 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f36:	4741                	li	a4,16
    80003f38:	86a6                	mv	a3,s1
    80003f3a:	fc040613          	addi	a2,s0,-64
    80003f3e:	4581                	li	a1,0
    80003f40:	854a                	mv	a0,s2
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	d70080e7          	jalr	-656(ra) # 80003cb2 <readi>
    80003f4a:	47c1                	li	a5,16
    80003f4c:	fcf518e3          	bne	a0,a5,80003f1c <dirlookup+0x3a>
    if(de.inum == 0)
    80003f50:	fc045783          	lhu	a5,-64(s0)
    80003f54:	dfe1                	beqz	a5,80003f2c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f56:	fc240593          	addi	a1,s0,-62
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	f6c080e7          	jalr	-148(ra) # 80003ec8 <namecmp>
    80003f64:	f561                	bnez	a0,80003f2c <dirlookup+0x4a>
      if(poff)
    80003f66:	000a0463          	beqz	s4,80003f6e <dirlookup+0x8c>
        *poff = off;
    80003f6a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f6e:	fc045583          	lhu	a1,-64(s0)
    80003f72:	00092503          	lw	a0,0(s2)
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	754080e7          	jalr	1876(ra) # 800036ca <iget>
    80003f7e:	a011                	j	80003f82 <dirlookup+0xa0>
  return 0;
    80003f80:	4501                	li	a0,0
}
    80003f82:	70e2                	ld	ra,56(sp)
    80003f84:	7442                	ld	s0,48(sp)
    80003f86:	74a2                	ld	s1,40(sp)
    80003f88:	7902                	ld	s2,32(sp)
    80003f8a:	69e2                	ld	s3,24(sp)
    80003f8c:	6a42                	ld	s4,16(sp)
    80003f8e:	6121                	addi	sp,sp,64
    80003f90:	8082                	ret

0000000080003f92 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f92:	711d                	addi	sp,sp,-96
    80003f94:	ec86                	sd	ra,88(sp)
    80003f96:	e8a2                	sd	s0,80(sp)
    80003f98:	e4a6                	sd	s1,72(sp)
    80003f9a:	e0ca                	sd	s2,64(sp)
    80003f9c:	fc4e                	sd	s3,56(sp)
    80003f9e:	f852                	sd	s4,48(sp)
    80003fa0:	f456                	sd	s5,40(sp)
    80003fa2:	f05a                	sd	s6,32(sp)
    80003fa4:	ec5e                	sd	s7,24(sp)
    80003fa6:	e862                	sd	s8,16(sp)
    80003fa8:	e466                	sd	s9,8(sp)
    80003faa:	1080                	addi	s0,sp,96
    80003fac:	84aa                	mv	s1,a0
    80003fae:	8aae                	mv	s5,a1
    80003fb0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fb2:	00054703          	lbu	a4,0(a0)
    80003fb6:	02f00793          	li	a5,47
    80003fba:	02f70363          	beq	a4,a5,80003fe0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fbe:	ffffe097          	auipc	ra,0xffffe
    80003fc2:	bb2080e7          	jalr	-1102(ra) # 80001b70 <myproc>
    80003fc6:	15053503          	ld	a0,336(a0)
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	9f6080e7          	jalr	-1546(ra) # 800039c0 <idup>
    80003fd2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fd4:	02f00913          	li	s2,47
  len = path - s;
    80003fd8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fda:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fdc:	4b85                	li	s7,1
    80003fde:	a865                	j	80004096 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fe0:	4585                	li	a1,1
    80003fe2:	4505                	li	a0,1
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	6e6080e7          	jalr	1766(ra) # 800036ca <iget>
    80003fec:	89aa                	mv	s3,a0
    80003fee:	b7dd                	j	80003fd4 <namex+0x42>
      iunlockput(ip);
    80003ff0:	854e                	mv	a0,s3
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	c6e080e7          	jalr	-914(ra) # 80003c60 <iunlockput>
      return 0;
    80003ffa:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ffc:	854e                	mv	a0,s3
    80003ffe:	60e6                	ld	ra,88(sp)
    80004000:	6446                	ld	s0,80(sp)
    80004002:	64a6                	ld	s1,72(sp)
    80004004:	6906                	ld	s2,64(sp)
    80004006:	79e2                	ld	s3,56(sp)
    80004008:	7a42                	ld	s4,48(sp)
    8000400a:	7aa2                	ld	s5,40(sp)
    8000400c:	7b02                	ld	s6,32(sp)
    8000400e:	6be2                	ld	s7,24(sp)
    80004010:	6c42                	ld	s8,16(sp)
    80004012:	6ca2                	ld	s9,8(sp)
    80004014:	6125                	addi	sp,sp,96
    80004016:	8082                	ret
      iunlock(ip);
    80004018:	854e                	mv	a0,s3
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	aa6080e7          	jalr	-1370(ra) # 80003ac0 <iunlock>
      return ip;
    80004022:	bfe9                	j	80003ffc <namex+0x6a>
      iunlockput(ip);
    80004024:	854e                	mv	a0,s3
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	c3a080e7          	jalr	-966(ra) # 80003c60 <iunlockput>
      return 0;
    8000402e:	89e6                	mv	s3,s9
    80004030:	b7f1                	j	80003ffc <namex+0x6a>
  len = path - s;
    80004032:	40b48633          	sub	a2,s1,a1
    80004036:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000403a:	099c5463          	bge	s8,s9,800040c2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000403e:	4639                	li	a2,14
    80004040:	8552                	mv	a0,s4
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	cd8080e7          	jalr	-808(ra) # 80000d1a <memmove>
  while(*path == '/')
    8000404a:	0004c783          	lbu	a5,0(s1)
    8000404e:	01279763          	bne	a5,s2,8000405c <namex+0xca>
    path++;
    80004052:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004054:	0004c783          	lbu	a5,0(s1)
    80004058:	ff278de3          	beq	a5,s2,80004052 <namex+0xc0>
    ilock(ip);
    8000405c:	854e                	mv	a0,s3
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	9a0080e7          	jalr	-1632(ra) # 800039fe <ilock>
    if(ip->type != T_DIR){
    80004066:	04499783          	lh	a5,68(s3)
    8000406a:	f97793e3          	bne	a5,s7,80003ff0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000406e:	000a8563          	beqz	s5,80004078 <namex+0xe6>
    80004072:	0004c783          	lbu	a5,0(s1)
    80004076:	d3cd                	beqz	a5,80004018 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004078:	865a                	mv	a2,s6
    8000407a:	85d2                	mv	a1,s4
    8000407c:	854e                	mv	a0,s3
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	e64080e7          	jalr	-412(ra) # 80003ee2 <dirlookup>
    80004086:	8caa                	mv	s9,a0
    80004088:	dd51                	beqz	a0,80004024 <namex+0x92>
    iunlockput(ip);
    8000408a:	854e                	mv	a0,s3
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	bd4080e7          	jalr	-1068(ra) # 80003c60 <iunlockput>
    ip = next;
    80004094:	89e6                	mv	s3,s9
  while(*path == '/')
    80004096:	0004c783          	lbu	a5,0(s1)
    8000409a:	05279763          	bne	a5,s2,800040e8 <namex+0x156>
    path++;
    8000409e:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040a0:	0004c783          	lbu	a5,0(s1)
    800040a4:	ff278de3          	beq	a5,s2,8000409e <namex+0x10c>
  if(*path == 0)
    800040a8:	c79d                	beqz	a5,800040d6 <namex+0x144>
    path++;
    800040aa:	85a6                	mv	a1,s1
  len = path - s;
    800040ac:	8cda                	mv	s9,s6
    800040ae:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800040b0:	01278963          	beq	a5,s2,800040c2 <namex+0x130>
    800040b4:	dfbd                	beqz	a5,80004032 <namex+0xa0>
    path++;
    800040b6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040b8:	0004c783          	lbu	a5,0(s1)
    800040bc:	ff279ce3          	bne	a5,s2,800040b4 <namex+0x122>
    800040c0:	bf8d                	j	80004032 <namex+0xa0>
    memmove(name, s, len);
    800040c2:	2601                	sext.w	a2,a2
    800040c4:	8552                	mv	a0,s4
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	c54080e7          	jalr	-940(ra) # 80000d1a <memmove>
    name[len] = 0;
    800040ce:	9cd2                	add	s9,s9,s4
    800040d0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800040d4:	bf9d                	j	8000404a <namex+0xb8>
  if(nameiparent){
    800040d6:	f20a83e3          	beqz	s5,80003ffc <namex+0x6a>
    iput(ip);
    800040da:	854e                	mv	a0,s3
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	adc080e7          	jalr	-1316(ra) # 80003bb8 <iput>
    return 0;
    800040e4:	4981                	li	s3,0
    800040e6:	bf19                	j	80003ffc <namex+0x6a>
  if(*path == 0)
    800040e8:	d7fd                	beqz	a5,800040d6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040ea:	0004c783          	lbu	a5,0(s1)
    800040ee:	85a6                	mv	a1,s1
    800040f0:	b7d1                	j	800040b4 <namex+0x122>

00000000800040f2 <dirlink>:
{
    800040f2:	7139                	addi	sp,sp,-64
    800040f4:	fc06                	sd	ra,56(sp)
    800040f6:	f822                	sd	s0,48(sp)
    800040f8:	f426                	sd	s1,40(sp)
    800040fa:	f04a                	sd	s2,32(sp)
    800040fc:	ec4e                	sd	s3,24(sp)
    800040fe:	e852                	sd	s4,16(sp)
    80004100:	0080                	addi	s0,sp,64
    80004102:	892a                	mv	s2,a0
    80004104:	8a2e                	mv	s4,a1
    80004106:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004108:	4601                	li	a2,0
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	dd8080e7          	jalr	-552(ra) # 80003ee2 <dirlookup>
    80004112:	e93d                	bnez	a0,80004188 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004114:	04c92483          	lw	s1,76(s2)
    80004118:	c49d                	beqz	s1,80004146 <dirlink+0x54>
    8000411a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000411c:	4741                	li	a4,16
    8000411e:	86a6                	mv	a3,s1
    80004120:	fc040613          	addi	a2,s0,-64
    80004124:	4581                	li	a1,0
    80004126:	854a                	mv	a0,s2
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	b8a080e7          	jalr	-1142(ra) # 80003cb2 <readi>
    80004130:	47c1                	li	a5,16
    80004132:	06f51163          	bne	a0,a5,80004194 <dirlink+0xa2>
    if(de.inum == 0)
    80004136:	fc045783          	lhu	a5,-64(s0)
    8000413a:	c791                	beqz	a5,80004146 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000413c:	24c1                	addiw	s1,s1,16
    8000413e:	04c92783          	lw	a5,76(s2)
    80004142:	fcf4ede3          	bltu	s1,a5,8000411c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004146:	4639                	li	a2,14
    80004148:	85d2                	mv	a1,s4
    8000414a:	fc240513          	addi	a0,s0,-62
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	c84080e7          	jalr	-892(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004156:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000415a:	4741                	li	a4,16
    8000415c:	86a6                	mv	a3,s1
    8000415e:	fc040613          	addi	a2,s0,-64
    80004162:	4581                	li	a1,0
    80004164:	854a                	mv	a0,s2
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	c44080e7          	jalr	-956(ra) # 80003daa <writei>
    8000416e:	872a                	mv	a4,a0
    80004170:	47c1                	li	a5,16
  return 0;
    80004172:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004174:	02f71863          	bne	a4,a5,800041a4 <dirlink+0xb2>
}
    80004178:	70e2                	ld	ra,56(sp)
    8000417a:	7442                	ld	s0,48(sp)
    8000417c:	74a2                	ld	s1,40(sp)
    8000417e:	7902                	ld	s2,32(sp)
    80004180:	69e2                	ld	s3,24(sp)
    80004182:	6a42                	ld	s4,16(sp)
    80004184:	6121                	addi	sp,sp,64
    80004186:	8082                	ret
    iput(ip);
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	a30080e7          	jalr	-1488(ra) # 80003bb8 <iput>
    return -1;
    80004190:	557d                	li	a0,-1
    80004192:	b7dd                	j	80004178 <dirlink+0x86>
      panic("dirlink read");
    80004194:	00004517          	auipc	a0,0x4
    80004198:	54c50513          	addi	a0,a0,1356 # 800086e0 <syscalls+0x1d0>
    8000419c:	ffffc097          	auipc	ra,0xffffc
    800041a0:	38e080e7          	jalr	910(ra) # 8000052a <panic>
    panic("dirlink");
    800041a4:	00004517          	auipc	a0,0x4
    800041a8:	64c50513          	addi	a0,a0,1612 # 800087f0 <syscalls+0x2e0>
    800041ac:	ffffc097          	auipc	ra,0xffffc
    800041b0:	37e080e7          	jalr	894(ra) # 8000052a <panic>

00000000800041b4 <namei>:

struct inode*
namei(char *path)
{
    800041b4:	1101                	addi	sp,sp,-32
    800041b6:	ec06                	sd	ra,24(sp)
    800041b8:	e822                	sd	s0,16(sp)
    800041ba:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041bc:	fe040613          	addi	a2,s0,-32
    800041c0:	4581                	li	a1,0
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	dd0080e7          	jalr	-560(ra) # 80003f92 <namex>
}
    800041ca:	60e2                	ld	ra,24(sp)
    800041cc:	6442                	ld	s0,16(sp)
    800041ce:	6105                	addi	sp,sp,32
    800041d0:	8082                	ret

00000000800041d2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041d2:	1141                	addi	sp,sp,-16
    800041d4:	e406                	sd	ra,8(sp)
    800041d6:	e022                	sd	s0,0(sp)
    800041d8:	0800                	addi	s0,sp,16
    800041da:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041dc:	4585                	li	a1,1
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	db4080e7          	jalr	-588(ra) # 80003f92 <namex>
}
    800041e6:	60a2                	ld	ra,8(sp)
    800041e8:	6402                	ld	s0,0(sp)
    800041ea:	0141                	addi	sp,sp,16
    800041ec:	8082                	ret

00000000800041ee <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041ee:	1101                	addi	sp,sp,-32
    800041f0:	ec06                	sd	ra,24(sp)
    800041f2:	e822                	sd	s0,16(sp)
    800041f4:	e426                	sd	s1,8(sp)
    800041f6:	e04a                	sd	s2,0(sp)
    800041f8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041fa:	0001e917          	auipc	s2,0x1e
    800041fe:	8a690913          	addi	s2,s2,-1882 # 80021aa0 <log>
    80004202:	01892583          	lw	a1,24(s2)
    80004206:	02892503          	lw	a0,40(s2)
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	ff2080e7          	jalr	-14(ra) # 800031fc <bread>
    80004212:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004214:	02c92683          	lw	a3,44(s2)
    80004218:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000421a:	02d05763          	blez	a3,80004248 <write_head+0x5a>
    8000421e:	0001e797          	auipc	a5,0x1e
    80004222:	8b278793          	addi	a5,a5,-1870 # 80021ad0 <log+0x30>
    80004226:	05c50713          	addi	a4,a0,92
    8000422a:	36fd                	addiw	a3,a3,-1
    8000422c:	1682                	slli	a3,a3,0x20
    8000422e:	9281                	srli	a3,a3,0x20
    80004230:	068a                	slli	a3,a3,0x2
    80004232:	0001e617          	auipc	a2,0x1e
    80004236:	8a260613          	addi	a2,a2,-1886 # 80021ad4 <log+0x34>
    8000423a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000423c:	4390                	lw	a2,0(a5)
    8000423e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004240:	0791                	addi	a5,a5,4
    80004242:	0711                	addi	a4,a4,4
    80004244:	fed79ce3          	bne	a5,a3,8000423c <write_head+0x4e>
  }
  bwrite(buf);
    80004248:	8526                	mv	a0,s1
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	0a4080e7          	jalr	164(ra) # 800032ee <bwrite>
  brelse(buf);
    80004252:	8526                	mv	a0,s1
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	0d8080e7          	jalr	216(ra) # 8000332c <brelse>
}
    8000425c:	60e2                	ld	ra,24(sp)
    8000425e:	6442                	ld	s0,16(sp)
    80004260:	64a2                	ld	s1,8(sp)
    80004262:	6902                	ld	s2,0(sp)
    80004264:	6105                	addi	sp,sp,32
    80004266:	8082                	ret

0000000080004268 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004268:	0001e797          	auipc	a5,0x1e
    8000426c:	8647a783          	lw	a5,-1948(a5) # 80021acc <log+0x2c>
    80004270:	0af05d63          	blez	a5,8000432a <install_trans+0xc2>
{
    80004274:	7139                	addi	sp,sp,-64
    80004276:	fc06                	sd	ra,56(sp)
    80004278:	f822                	sd	s0,48(sp)
    8000427a:	f426                	sd	s1,40(sp)
    8000427c:	f04a                	sd	s2,32(sp)
    8000427e:	ec4e                	sd	s3,24(sp)
    80004280:	e852                	sd	s4,16(sp)
    80004282:	e456                	sd	s5,8(sp)
    80004284:	e05a                	sd	s6,0(sp)
    80004286:	0080                	addi	s0,sp,64
    80004288:	8b2a                	mv	s6,a0
    8000428a:	0001ea97          	auipc	s5,0x1e
    8000428e:	846a8a93          	addi	s5,s5,-1978 # 80021ad0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004292:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004294:	0001e997          	auipc	s3,0x1e
    80004298:	80c98993          	addi	s3,s3,-2036 # 80021aa0 <log>
    8000429c:	a00d                	j	800042be <install_trans+0x56>
    brelse(lbuf);
    8000429e:	854a                	mv	a0,s2
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	08c080e7          	jalr	140(ra) # 8000332c <brelse>
    brelse(dbuf);
    800042a8:	8526                	mv	a0,s1
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	082080e7          	jalr	130(ra) # 8000332c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b2:	2a05                	addiw	s4,s4,1
    800042b4:	0a91                	addi	s5,s5,4
    800042b6:	02c9a783          	lw	a5,44(s3)
    800042ba:	04fa5e63          	bge	s4,a5,80004316 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042be:	0189a583          	lw	a1,24(s3)
    800042c2:	014585bb          	addw	a1,a1,s4
    800042c6:	2585                	addiw	a1,a1,1
    800042c8:	0289a503          	lw	a0,40(s3)
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	f30080e7          	jalr	-208(ra) # 800031fc <bread>
    800042d4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042d6:	000aa583          	lw	a1,0(s5)
    800042da:	0289a503          	lw	a0,40(s3)
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	f1e080e7          	jalr	-226(ra) # 800031fc <bread>
    800042e6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042e8:	40000613          	li	a2,1024
    800042ec:	05890593          	addi	a1,s2,88
    800042f0:	05850513          	addi	a0,a0,88
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	a26080e7          	jalr	-1498(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	ff0080e7          	jalr	-16(ra) # 800032ee <bwrite>
    if(recovering == 0)
    80004306:	f80b1ce3          	bnez	s6,8000429e <install_trans+0x36>
      bunpin(dbuf);
    8000430a:	8526                	mv	a0,s1
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	0fa080e7          	jalr	250(ra) # 80003406 <bunpin>
    80004314:	b769                	j	8000429e <install_trans+0x36>
}
    80004316:	70e2                	ld	ra,56(sp)
    80004318:	7442                	ld	s0,48(sp)
    8000431a:	74a2                	ld	s1,40(sp)
    8000431c:	7902                	ld	s2,32(sp)
    8000431e:	69e2                	ld	s3,24(sp)
    80004320:	6a42                	ld	s4,16(sp)
    80004322:	6aa2                	ld	s5,8(sp)
    80004324:	6b02                	ld	s6,0(sp)
    80004326:	6121                	addi	sp,sp,64
    80004328:	8082                	ret
    8000432a:	8082                	ret

000000008000432c <initlog>:
{
    8000432c:	7179                	addi	sp,sp,-48
    8000432e:	f406                	sd	ra,40(sp)
    80004330:	f022                	sd	s0,32(sp)
    80004332:	ec26                	sd	s1,24(sp)
    80004334:	e84a                	sd	s2,16(sp)
    80004336:	e44e                	sd	s3,8(sp)
    80004338:	1800                	addi	s0,sp,48
    8000433a:	892a                	mv	s2,a0
    8000433c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000433e:	0001d497          	auipc	s1,0x1d
    80004342:	76248493          	addi	s1,s1,1890 # 80021aa0 <log>
    80004346:	00004597          	auipc	a1,0x4
    8000434a:	3aa58593          	addi	a1,a1,938 # 800086f0 <syscalls+0x1e0>
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffc097          	auipc	ra,0xffffc
    80004354:	7e2080e7          	jalr	2018(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004358:	0149a583          	lw	a1,20(s3)
    8000435c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000435e:	0109a783          	lw	a5,16(s3)
    80004362:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004364:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004368:	854a                	mv	a0,s2
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	e92080e7          	jalr	-366(ra) # 800031fc <bread>
  log.lh.n = lh->n;
    80004372:	4d34                	lw	a3,88(a0)
    80004374:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004376:	02d05563          	blez	a3,800043a0 <initlog+0x74>
    8000437a:	05c50793          	addi	a5,a0,92
    8000437e:	0001d717          	auipc	a4,0x1d
    80004382:	75270713          	addi	a4,a4,1874 # 80021ad0 <log+0x30>
    80004386:	36fd                	addiw	a3,a3,-1
    80004388:	1682                	slli	a3,a3,0x20
    8000438a:	9281                	srli	a3,a3,0x20
    8000438c:	068a                	slli	a3,a3,0x2
    8000438e:	06050613          	addi	a2,a0,96
    80004392:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004394:	4390                	lw	a2,0(a5)
    80004396:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004398:	0791                	addi	a5,a5,4
    8000439a:	0711                	addi	a4,a4,4
    8000439c:	fed79ce3          	bne	a5,a3,80004394 <initlog+0x68>
  brelse(buf);
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	f8c080e7          	jalr	-116(ra) # 8000332c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043a8:	4505                	li	a0,1
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	ebe080e7          	jalr	-322(ra) # 80004268 <install_trans>
  log.lh.n = 0;
    800043b2:	0001d797          	auipc	a5,0x1d
    800043b6:	7007ad23          	sw	zero,1818(a5) # 80021acc <log+0x2c>
  write_head(); // clear the log
    800043ba:	00000097          	auipc	ra,0x0
    800043be:	e34080e7          	jalr	-460(ra) # 800041ee <write_head>
}
    800043c2:	70a2                	ld	ra,40(sp)
    800043c4:	7402                	ld	s0,32(sp)
    800043c6:	64e2                	ld	s1,24(sp)
    800043c8:	6942                	ld	s2,16(sp)
    800043ca:	69a2                	ld	s3,8(sp)
    800043cc:	6145                	addi	sp,sp,48
    800043ce:	8082                	ret

00000000800043d0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	e04a                	sd	s2,0(sp)
    800043da:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043dc:	0001d517          	auipc	a0,0x1d
    800043e0:	6c450513          	addi	a0,a0,1732 # 80021aa0 <log>
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	7de080e7          	jalr	2014(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800043ec:	0001d497          	auipc	s1,0x1d
    800043f0:	6b448493          	addi	s1,s1,1716 # 80021aa0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043f4:	4979                	li	s2,30
    800043f6:	a039                	j	80004404 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043f8:	85a6                	mv	a1,s1
    800043fa:	8526                	mv	a0,s1
    800043fc:	ffffe097          	auipc	ra,0xffffe
    80004400:	fca080e7          	jalr	-54(ra) # 800023c6 <sleep>
    if(log.committing){
    80004404:	50dc                	lw	a5,36(s1)
    80004406:	fbed                	bnez	a5,800043f8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004408:	509c                	lw	a5,32(s1)
    8000440a:	0017871b          	addiw	a4,a5,1
    8000440e:	0007069b          	sext.w	a3,a4
    80004412:	0027179b          	slliw	a5,a4,0x2
    80004416:	9fb9                	addw	a5,a5,a4
    80004418:	0017979b          	slliw	a5,a5,0x1
    8000441c:	54d8                	lw	a4,44(s1)
    8000441e:	9fb9                	addw	a5,a5,a4
    80004420:	00f95963          	bge	s2,a5,80004432 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004424:	85a6                	mv	a1,s1
    80004426:	8526                	mv	a0,s1
    80004428:	ffffe097          	auipc	ra,0xffffe
    8000442c:	f9e080e7          	jalr	-98(ra) # 800023c6 <sleep>
    80004430:	bfd1                	j	80004404 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004432:	0001d517          	auipc	a0,0x1d
    80004436:	66e50513          	addi	a0,a0,1646 # 80021aa0 <log>
    8000443a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	83a080e7          	jalr	-1990(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004444:	60e2                	ld	ra,24(sp)
    80004446:	6442                	ld	s0,16(sp)
    80004448:	64a2                	ld	s1,8(sp)
    8000444a:	6902                	ld	s2,0(sp)
    8000444c:	6105                	addi	sp,sp,32
    8000444e:	8082                	ret

0000000080004450 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004450:	7139                	addi	sp,sp,-64
    80004452:	fc06                	sd	ra,56(sp)
    80004454:	f822                	sd	s0,48(sp)
    80004456:	f426                	sd	s1,40(sp)
    80004458:	f04a                	sd	s2,32(sp)
    8000445a:	ec4e                	sd	s3,24(sp)
    8000445c:	e852                	sd	s4,16(sp)
    8000445e:	e456                	sd	s5,8(sp)
    80004460:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004462:	0001d497          	auipc	s1,0x1d
    80004466:	63e48493          	addi	s1,s1,1598 # 80021aa0 <log>
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	756080e7          	jalr	1878(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004474:	509c                	lw	a5,32(s1)
    80004476:	37fd                	addiw	a5,a5,-1
    80004478:	0007891b          	sext.w	s2,a5
    8000447c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000447e:	50dc                	lw	a5,36(s1)
    80004480:	e7b9                	bnez	a5,800044ce <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004482:	04091e63          	bnez	s2,800044de <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004486:	0001d497          	auipc	s1,0x1d
    8000448a:	61a48493          	addi	s1,s1,1562 # 80021aa0 <log>
    8000448e:	4785                	li	a5,1
    80004490:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004492:	8526                	mv	a0,s1
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	7e2080e7          	jalr	2018(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000449c:	54dc                	lw	a5,44(s1)
    8000449e:	06f04763          	bgtz	a5,8000450c <end_op+0xbc>
    acquire(&log.lock);
    800044a2:	0001d497          	auipc	s1,0x1d
    800044a6:	5fe48493          	addi	s1,s1,1534 # 80021aa0 <log>
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	716080e7          	jalr	1814(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800044b4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044b8:	8526                	mv	a0,s1
    800044ba:	ffffe097          	auipc	ra,0xffffe
    800044be:	098080e7          	jalr	152(ra) # 80002552 <wakeup>
    release(&log.lock);
    800044c2:	8526                	mv	a0,s1
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	7b2080e7          	jalr	1970(ra) # 80000c76 <release>
}
    800044cc:	a03d                	j	800044fa <end_op+0xaa>
    panic("log.committing");
    800044ce:	00004517          	auipc	a0,0x4
    800044d2:	22a50513          	addi	a0,a0,554 # 800086f8 <syscalls+0x1e8>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	054080e7          	jalr	84(ra) # 8000052a <panic>
    wakeup(&log);
    800044de:	0001d497          	auipc	s1,0x1d
    800044e2:	5c248493          	addi	s1,s1,1474 # 80021aa0 <log>
    800044e6:	8526                	mv	a0,s1
    800044e8:	ffffe097          	auipc	ra,0xffffe
    800044ec:	06a080e7          	jalr	106(ra) # 80002552 <wakeup>
  release(&log.lock);
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	784080e7          	jalr	1924(ra) # 80000c76 <release>
}
    800044fa:	70e2                	ld	ra,56(sp)
    800044fc:	7442                	ld	s0,48(sp)
    800044fe:	74a2                	ld	s1,40(sp)
    80004500:	7902                	ld	s2,32(sp)
    80004502:	69e2                	ld	s3,24(sp)
    80004504:	6a42                	ld	s4,16(sp)
    80004506:	6aa2                	ld	s5,8(sp)
    80004508:	6121                	addi	sp,sp,64
    8000450a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000450c:	0001da97          	auipc	s5,0x1d
    80004510:	5c4a8a93          	addi	s5,s5,1476 # 80021ad0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004514:	0001da17          	auipc	s4,0x1d
    80004518:	58ca0a13          	addi	s4,s4,1420 # 80021aa0 <log>
    8000451c:	018a2583          	lw	a1,24(s4)
    80004520:	012585bb          	addw	a1,a1,s2
    80004524:	2585                	addiw	a1,a1,1
    80004526:	028a2503          	lw	a0,40(s4)
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	cd2080e7          	jalr	-814(ra) # 800031fc <bread>
    80004532:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004534:	000aa583          	lw	a1,0(s5)
    80004538:	028a2503          	lw	a0,40(s4)
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	cc0080e7          	jalr	-832(ra) # 800031fc <bread>
    80004544:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004546:	40000613          	li	a2,1024
    8000454a:	05850593          	addi	a1,a0,88
    8000454e:	05848513          	addi	a0,s1,88
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	7c8080e7          	jalr	1992(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000455a:	8526                	mv	a0,s1
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	d92080e7          	jalr	-622(ra) # 800032ee <bwrite>
    brelse(from);
    80004564:	854e                	mv	a0,s3
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	dc6080e7          	jalr	-570(ra) # 8000332c <brelse>
    brelse(to);
    8000456e:	8526                	mv	a0,s1
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	dbc080e7          	jalr	-580(ra) # 8000332c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004578:	2905                	addiw	s2,s2,1
    8000457a:	0a91                	addi	s5,s5,4
    8000457c:	02ca2783          	lw	a5,44(s4)
    80004580:	f8f94ee3          	blt	s2,a5,8000451c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004584:	00000097          	auipc	ra,0x0
    80004588:	c6a080e7          	jalr	-918(ra) # 800041ee <write_head>
    install_trans(0); // Now install writes to home locations
    8000458c:	4501                	li	a0,0
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	cda080e7          	jalr	-806(ra) # 80004268 <install_trans>
    log.lh.n = 0;
    80004596:	0001d797          	auipc	a5,0x1d
    8000459a:	5207ab23          	sw	zero,1334(a5) # 80021acc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	c50080e7          	jalr	-944(ra) # 800041ee <write_head>
    800045a6:	bdf5                	j	800044a2 <end_op+0x52>

00000000800045a8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045a8:	1101                	addi	sp,sp,-32
    800045aa:	ec06                	sd	ra,24(sp)
    800045ac:	e822                	sd	s0,16(sp)
    800045ae:	e426                	sd	s1,8(sp)
    800045b0:	e04a                	sd	s2,0(sp)
    800045b2:	1000                	addi	s0,sp,32
    800045b4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045b6:	0001d917          	auipc	s2,0x1d
    800045ba:	4ea90913          	addi	s2,s2,1258 # 80021aa0 <log>
    800045be:	854a                	mv	a0,s2
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	602080e7          	jalr	1538(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045c8:	02c92603          	lw	a2,44(s2)
    800045cc:	47f5                	li	a5,29
    800045ce:	06c7c563          	blt	a5,a2,80004638 <log_write+0x90>
    800045d2:	0001d797          	auipc	a5,0x1d
    800045d6:	4ea7a783          	lw	a5,1258(a5) # 80021abc <log+0x1c>
    800045da:	37fd                	addiw	a5,a5,-1
    800045dc:	04f65e63          	bge	a2,a5,80004638 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045e0:	0001d797          	auipc	a5,0x1d
    800045e4:	4e07a783          	lw	a5,1248(a5) # 80021ac0 <log+0x20>
    800045e8:	06f05063          	blez	a5,80004648 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045ec:	4781                	li	a5,0
    800045ee:	06c05563          	blez	a2,80004658 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045f2:	44cc                	lw	a1,12(s1)
    800045f4:	0001d717          	auipc	a4,0x1d
    800045f8:	4dc70713          	addi	a4,a4,1244 # 80021ad0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045fc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045fe:	4314                	lw	a3,0(a4)
    80004600:	04b68c63          	beq	a3,a1,80004658 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004604:	2785                	addiw	a5,a5,1
    80004606:	0711                	addi	a4,a4,4
    80004608:	fef61be3          	bne	a2,a5,800045fe <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000460c:	0621                	addi	a2,a2,8
    8000460e:	060a                	slli	a2,a2,0x2
    80004610:	0001d797          	auipc	a5,0x1d
    80004614:	49078793          	addi	a5,a5,1168 # 80021aa0 <log>
    80004618:	963e                	add	a2,a2,a5
    8000461a:	44dc                	lw	a5,12(s1)
    8000461c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000461e:	8526                	mv	a0,s1
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	daa080e7          	jalr	-598(ra) # 800033ca <bpin>
    log.lh.n++;
    80004628:	0001d717          	auipc	a4,0x1d
    8000462c:	47870713          	addi	a4,a4,1144 # 80021aa0 <log>
    80004630:	575c                	lw	a5,44(a4)
    80004632:	2785                	addiw	a5,a5,1
    80004634:	d75c                	sw	a5,44(a4)
    80004636:	a835                	j	80004672 <log_write+0xca>
    panic("too big a transaction");
    80004638:	00004517          	auipc	a0,0x4
    8000463c:	0d050513          	addi	a0,a0,208 # 80008708 <syscalls+0x1f8>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	eea080e7          	jalr	-278(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004648:	00004517          	auipc	a0,0x4
    8000464c:	0d850513          	addi	a0,a0,216 # 80008720 <syscalls+0x210>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	eda080e7          	jalr	-294(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004658:	00878713          	addi	a4,a5,8
    8000465c:	00271693          	slli	a3,a4,0x2
    80004660:	0001d717          	auipc	a4,0x1d
    80004664:	44070713          	addi	a4,a4,1088 # 80021aa0 <log>
    80004668:	9736                	add	a4,a4,a3
    8000466a:	44d4                	lw	a3,12(s1)
    8000466c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000466e:	faf608e3          	beq	a2,a5,8000461e <log_write+0x76>
  }
  release(&log.lock);
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	42e50513          	addi	a0,a0,1070 # 80021aa0 <log>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	5fc080e7          	jalr	1532(ra) # 80000c76 <release>
}
    80004682:	60e2                	ld	ra,24(sp)
    80004684:	6442                	ld	s0,16(sp)
    80004686:	64a2                	ld	s1,8(sp)
    80004688:	6902                	ld	s2,0(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	e04a                	sd	s2,0(sp)
    80004698:	1000                	addi	s0,sp,32
    8000469a:	84aa                	mv	s1,a0
    8000469c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000469e:	00004597          	auipc	a1,0x4
    800046a2:	0a258593          	addi	a1,a1,162 # 80008740 <syscalls+0x230>
    800046a6:	0521                	addi	a0,a0,8
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	48a080e7          	jalr	1162(ra) # 80000b32 <initlock>
  lk->name = name;
    800046b0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046b4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b8:	0204a423          	sw	zero,40(s1)
}
    800046bc:	60e2                	ld	ra,24(sp)
    800046be:	6442                	ld	s0,16(sp)
    800046c0:	64a2                	ld	s1,8(sp)
    800046c2:	6902                	ld	s2,0(sp)
    800046c4:	6105                	addi	sp,sp,32
    800046c6:	8082                	ret

00000000800046c8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046c8:	1101                	addi	sp,sp,-32
    800046ca:	ec06                	sd	ra,24(sp)
    800046cc:	e822                	sd	s0,16(sp)
    800046ce:	e426                	sd	s1,8(sp)
    800046d0:	e04a                	sd	s2,0(sp)
    800046d2:	1000                	addi	s0,sp,32
    800046d4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046d6:	00850913          	addi	s2,a0,8
    800046da:	854a                	mv	a0,s2
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	4e6080e7          	jalr	1254(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800046e4:	409c                	lw	a5,0(s1)
    800046e6:	cb89                	beqz	a5,800046f8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046e8:	85ca                	mv	a1,s2
    800046ea:	8526                	mv	a0,s1
    800046ec:	ffffe097          	auipc	ra,0xffffe
    800046f0:	cda080e7          	jalr	-806(ra) # 800023c6 <sleep>
  while (lk->locked) {
    800046f4:	409c                	lw	a5,0(s1)
    800046f6:	fbed                	bnez	a5,800046e8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046f8:	4785                	li	a5,1
    800046fa:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046fc:	ffffd097          	auipc	ra,0xffffd
    80004700:	474080e7          	jalr	1140(ra) # 80001b70 <myproc>
    80004704:	591c                	lw	a5,48(a0)
    80004706:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004708:	854a                	mv	a0,s2
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	56c080e7          	jalr	1388(ra) # 80000c76 <release>
}
    80004712:	60e2                	ld	ra,24(sp)
    80004714:	6442                	ld	s0,16(sp)
    80004716:	64a2                	ld	s1,8(sp)
    80004718:	6902                	ld	s2,0(sp)
    8000471a:	6105                	addi	sp,sp,32
    8000471c:	8082                	ret

000000008000471e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000471e:	1101                	addi	sp,sp,-32
    80004720:	ec06                	sd	ra,24(sp)
    80004722:	e822                	sd	s0,16(sp)
    80004724:	e426                	sd	s1,8(sp)
    80004726:	e04a                	sd	s2,0(sp)
    80004728:	1000                	addi	s0,sp,32
    8000472a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000472c:	00850913          	addi	s2,a0,8
    80004730:	854a                	mv	a0,s2
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	490080e7          	jalr	1168(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000473a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000473e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004742:	8526                	mv	a0,s1
    80004744:	ffffe097          	auipc	ra,0xffffe
    80004748:	e0e080e7          	jalr	-498(ra) # 80002552 <wakeup>
  release(&lk->lk);
    8000474c:	854a                	mv	a0,s2
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	528080e7          	jalr	1320(ra) # 80000c76 <release>
}
    80004756:	60e2                	ld	ra,24(sp)
    80004758:	6442                	ld	s0,16(sp)
    8000475a:	64a2                	ld	s1,8(sp)
    8000475c:	6902                	ld	s2,0(sp)
    8000475e:	6105                	addi	sp,sp,32
    80004760:	8082                	ret

0000000080004762 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004762:	7179                	addi	sp,sp,-48
    80004764:	f406                	sd	ra,40(sp)
    80004766:	f022                	sd	s0,32(sp)
    80004768:	ec26                	sd	s1,24(sp)
    8000476a:	e84a                	sd	s2,16(sp)
    8000476c:	e44e                	sd	s3,8(sp)
    8000476e:	1800                	addi	s0,sp,48
    80004770:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004772:	00850913          	addi	s2,a0,8
    80004776:	854a                	mv	a0,s2
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	44a080e7          	jalr	1098(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004780:	409c                	lw	a5,0(s1)
    80004782:	ef99                	bnez	a5,800047a0 <holdingsleep+0x3e>
    80004784:	4481                	li	s1,0
  release(&lk->lk);
    80004786:	854a                	mv	a0,s2
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	4ee080e7          	jalr	1262(ra) # 80000c76 <release>
  return r;
}
    80004790:	8526                	mv	a0,s1
    80004792:	70a2                	ld	ra,40(sp)
    80004794:	7402                	ld	s0,32(sp)
    80004796:	64e2                	ld	s1,24(sp)
    80004798:	6942                	ld	s2,16(sp)
    8000479a:	69a2                	ld	s3,8(sp)
    8000479c:	6145                	addi	sp,sp,48
    8000479e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047a0:	0284a983          	lw	s3,40(s1)
    800047a4:	ffffd097          	auipc	ra,0xffffd
    800047a8:	3cc080e7          	jalr	972(ra) # 80001b70 <myproc>
    800047ac:	5904                	lw	s1,48(a0)
    800047ae:	413484b3          	sub	s1,s1,s3
    800047b2:	0014b493          	seqz	s1,s1
    800047b6:	bfc1                	j	80004786 <holdingsleep+0x24>

00000000800047b8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047b8:	1141                	addi	sp,sp,-16
    800047ba:	e406                	sd	ra,8(sp)
    800047bc:	e022                	sd	s0,0(sp)
    800047be:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047c0:	00004597          	auipc	a1,0x4
    800047c4:	f9058593          	addi	a1,a1,-112 # 80008750 <syscalls+0x240>
    800047c8:	0001d517          	auipc	a0,0x1d
    800047cc:	42050513          	addi	a0,a0,1056 # 80021be8 <ftable>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	362080e7          	jalr	866(ra) # 80000b32 <initlock>
}
    800047d8:	60a2                	ld	ra,8(sp)
    800047da:	6402                	ld	s0,0(sp)
    800047dc:	0141                	addi	sp,sp,16
    800047de:	8082                	ret

00000000800047e0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047e0:	1101                	addi	sp,sp,-32
    800047e2:	ec06                	sd	ra,24(sp)
    800047e4:	e822                	sd	s0,16(sp)
    800047e6:	e426                	sd	s1,8(sp)
    800047e8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047ea:	0001d517          	auipc	a0,0x1d
    800047ee:	3fe50513          	addi	a0,a0,1022 # 80021be8 <ftable>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	3d0080e7          	jalr	976(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047fa:	0001d497          	auipc	s1,0x1d
    800047fe:	40648493          	addi	s1,s1,1030 # 80021c00 <ftable+0x18>
    80004802:	0001e717          	auipc	a4,0x1e
    80004806:	39e70713          	addi	a4,a4,926 # 80022ba0 <ftable+0xfb8>
    if(f->ref == 0){
    8000480a:	40dc                	lw	a5,4(s1)
    8000480c:	cf99                	beqz	a5,8000482a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000480e:	02848493          	addi	s1,s1,40
    80004812:	fee49ce3          	bne	s1,a4,8000480a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004816:	0001d517          	auipc	a0,0x1d
    8000481a:	3d250513          	addi	a0,a0,978 # 80021be8 <ftable>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	458080e7          	jalr	1112(ra) # 80000c76 <release>
  return 0;
    80004826:	4481                	li	s1,0
    80004828:	a819                	j	8000483e <filealloc+0x5e>
      f->ref = 1;
    8000482a:	4785                	li	a5,1
    8000482c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000482e:	0001d517          	auipc	a0,0x1d
    80004832:	3ba50513          	addi	a0,a0,954 # 80021be8 <ftable>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	440080e7          	jalr	1088(ra) # 80000c76 <release>
}
    8000483e:	8526                	mv	a0,s1
    80004840:	60e2                	ld	ra,24(sp)
    80004842:	6442                	ld	s0,16(sp)
    80004844:	64a2                	ld	s1,8(sp)
    80004846:	6105                	addi	sp,sp,32
    80004848:	8082                	ret

000000008000484a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000484a:	1101                	addi	sp,sp,-32
    8000484c:	ec06                	sd	ra,24(sp)
    8000484e:	e822                	sd	s0,16(sp)
    80004850:	e426                	sd	s1,8(sp)
    80004852:	1000                	addi	s0,sp,32
    80004854:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004856:	0001d517          	auipc	a0,0x1d
    8000485a:	39250513          	addi	a0,a0,914 # 80021be8 <ftable>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	364080e7          	jalr	868(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004866:	40dc                	lw	a5,4(s1)
    80004868:	02f05263          	blez	a5,8000488c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000486c:	2785                	addiw	a5,a5,1
    8000486e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004870:	0001d517          	auipc	a0,0x1d
    80004874:	37850513          	addi	a0,a0,888 # 80021be8 <ftable>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	3fe080e7          	jalr	1022(ra) # 80000c76 <release>
  return f;
}
    80004880:	8526                	mv	a0,s1
    80004882:	60e2                	ld	ra,24(sp)
    80004884:	6442                	ld	s0,16(sp)
    80004886:	64a2                	ld	s1,8(sp)
    80004888:	6105                	addi	sp,sp,32
    8000488a:	8082                	ret
    panic("filedup");
    8000488c:	00004517          	auipc	a0,0x4
    80004890:	ecc50513          	addi	a0,a0,-308 # 80008758 <syscalls+0x248>
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	c96080e7          	jalr	-874(ra) # 8000052a <panic>

000000008000489c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000489c:	7139                	addi	sp,sp,-64
    8000489e:	fc06                	sd	ra,56(sp)
    800048a0:	f822                	sd	s0,48(sp)
    800048a2:	f426                	sd	s1,40(sp)
    800048a4:	f04a                	sd	s2,32(sp)
    800048a6:	ec4e                	sd	s3,24(sp)
    800048a8:	e852                	sd	s4,16(sp)
    800048aa:	e456                	sd	s5,8(sp)
    800048ac:	0080                	addi	s0,sp,64
    800048ae:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048b0:	0001d517          	auipc	a0,0x1d
    800048b4:	33850513          	addi	a0,a0,824 # 80021be8 <ftable>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	30a080e7          	jalr	778(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800048c0:	40dc                	lw	a5,4(s1)
    800048c2:	06f05163          	blez	a5,80004924 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048c6:	37fd                	addiw	a5,a5,-1
    800048c8:	0007871b          	sext.w	a4,a5
    800048cc:	c0dc                	sw	a5,4(s1)
    800048ce:	06e04363          	bgtz	a4,80004934 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048d2:	0004a903          	lw	s2,0(s1)
    800048d6:	0094ca83          	lbu	s5,9(s1)
    800048da:	0104ba03          	ld	s4,16(s1)
    800048de:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048e2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048e6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048ea:	0001d517          	auipc	a0,0x1d
    800048ee:	2fe50513          	addi	a0,a0,766 # 80021be8 <ftable>
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	384080e7          	jalr	900(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800048fa:	4785                	li	a5,1
    800048fc:	04f90d63          	beq	s2,a5,80004956 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004900:	3979                	addiw	s2,s2,-2
    80004902:	4785                	li	a5,1
    80004904:	0527e063          	bltu	a5,s2,80004944 <fileclose+0xa8>
    begin_op();
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	ac8080e7          	jalr	-1336(ra) # 800043d0 <begin_op>
    iput(ff.ip);
    80004910:	854e                	mv	a0,s3
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	2a6080e7          	jalr	678(ra) # 80003bb8 <iput>
    end_op();
    8000491a:	00000097          	auipc	ra,0x0
    8000491e:	b36080e7          	jalr	-1226(ra) # 80004450 <end_op>
    80004922:	a00d                	j	80004944 <fileclose+0xa8>
    panic("fileclose");
    80004924:	00004517          	auipc	a0,0x4
    80004928:	e3c50513          	addi	a0,a0,-452 # 80008760 <syscalls+0x250>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	bfe080e7          	jalr	-1026(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004934:	0001d517          	auipc	a0,0x1d
    80004938:	2b450513          	addi	a0,a0,692 # 80021be8 <ftable>
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	33a080e7          	jalr	826(ra) # 80000c76 <release>
  }
}
    80004944:	70e2                	ld	ra,56(sp)
    80004946:	7442                	ld	s0,48(sp)
    80004948:	74a2                	ld	s1,40(sp)
    8000494a:	7902                	ld	s2,32(sp)
    8000494c:	69e2                	ld	s3,24(sp)
    8000494e:	6a42                	ld	s4,16(sp)
    80004950:	6aa2                	ld	s5,8(sp)
    80004952:	6121                	addi	sp,sp,64
    80004954:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004956:	85d6                	mv	a1,s5
    80004958:	8552                	mv	a0,s4
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	34c080e7          	jalr	844(ra) # 80004ca6 <pipeclose>
    80004962:	b7cd                	j	80004944 <fileclose+0xa8>

0000000080004964 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004964:	715d                	addi	sp,sp,-80
    80004966:	e486                	sd	ra,72(sp)
    80004968:	e0a2                	sd	s0,64(sp)
    8000496a:	fc26                	sd	s1,56(sp)
    8000496c:	f84a                	sd	s2,48(sp)
    8000496e:	f44e                	sd	s3,40(sp)
    80004970:	0880                	addi	s0,sp,80
    80004972:	84aa                	mv	s1,a0
    80004974:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004976:	ffffd097          	auipc	ra,0xffffd
    8000497a:	1fa080e7          	jalr	506(ra) # 80001b70 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000497e:	409c                	lw	a5,0(s1)
    80004980:	37f9                	addiw	a5,a5,-2
    80004982:	4705                	li	a4,1
    80004984:	04f76763          	bltu	a4,a5,800049d2 <filestat+0x6e>
    80004988:	892a                	mv	s2,a0
    ilock(f->ip);
    8000498a:	6c88                	ld	a0,24(s1)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	072080e7          	jalr	114(ra) # 800039fe <ilock>
    stati(f->ip, &st);
    80004994:	fb840593          	addi	a1,s0,-72
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	2ee080e7          	jalr	750(ra) # 80003c88 <stati>
    iunlock(f->ip);
    800049a2:	6c88                	ld	a0,24(s1)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	11c080e7          	jalr	284(ra) # 80003ac0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049ac:	46e1                	li	a3,24
    800049ae:	fb840613          	addi	a2,s0,-72
    800049b2:	85ce                	mv	a1,s3
    800049b4:	05093503          	ld	a0,80(s2)
    800049b8:	ffffd097          	auipc	ra,0xffffd
    800049bc:	c86080e7          	jalr	-890(ra) # 8000163e <copyout>
    800049c0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049c4:	60a6                	ld	ra,72(sp)
    800049c6:	6406                	ld	s0,64(sp)
    800049c8:	74e2                	ld	s1,56(sp)
    800049ca:	7942                	ld	s2,48(sp)
    800049cc:	79a2                	ld	s3,40(sp)
    800049ce:	6161                	addi	sp,sp,80
    800049d0:	8082                	ret
  return -1;
    800049d2:	557d                	li	a0,-1
    800049d4:	bfc5                	j	800049c4 <filestat+0x60>

00000000800049d6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049d6:	7179                	addi	sp,sp,-48
    800049d8:	f406                	sd	ra,40(sp)
    800049da:	f022                	sd	s0,32(sp)
    800049dc:	ec26                	sd	s1,24(sp)
    800049de:	e84a                	sd	s2,16(sp)
    800049e0:	e44e                	sd	s3,8(sp)
    800049e2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049e4:	00854783          	lbu	a5,8(a0)
    800049e8:	c3d5                	beqz	a5,80004a8c <fileread+0xb6>
    800049ea:	84aa                	mv	s1,a0
    800049ec:	89ae                	mv	s3,a1
    800049ee:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f0:	411c                	lw	a5,0(a0)
    800049f2:	4705                	li	a4,1
    800049f4:	04e78963          	beq	a5,a4,80004a46 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049f8:	470d                	li	a4,3
    800049fa:	04e78d63          	beq	a5,a4,80004a54 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049fe:	4709                	li	a4,2
    80004a00:	06e79e63          	bne	a5,a4,80004a7c <fileread+0xa6>
    ilock(f->ip);
    80004a04:	6d08                	ld	a0,24(a0)
    80004a06:	fffff097          	auipc	ra,0xfffff
    80004a0a:	ff8080e7          	jalr	-8(ra) # 800039fe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a0e:	874a                	mv	a4,s2
    80004a10:	5094                	lw	a3,32(s1)
    80004a12:	864e                	mv	a2,s3
    80004a14:	4585                	li	a1,1
    80004a16:	6c88                	ld	a0,24(s1)
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	29a080e7          	jalr	666(ra) # 80003cb2 <readi>
    80004a20:	892a                	mv	s2,a0
    80004a22:	00a05563          	blez	a0,80004a2c <fileread+0x56>
      f->off += r;
    80004a26:	509c                	lw	a5,32(s1)
    80004a28:	9fa9                	addw	a5,a5,a0
    80004a2a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a2c:	6c88                	ld	a0,24(s1)
    80004a2e:	fffff097          	auipc	ra,0xfffff
    80004a32:	092080e7          	jalr	146(ra) # 80003ac0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a36:	854a                	mv	a0,s2
    80004a38:	70a2                	ld	ra,40(sp)
    80004a3a:	7402                	ld	s0,32(sp)
    80004a3c:	64e2                	ld	s1,24(sp)
    80004a3e:	6942                	ld	s2,16(sp)
    80004a40:	69a2                	ld	s3,8(sp)
    80004a42:	6145                	addi	sp,sp,48
    80004a44:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a46:	6908                	ld	a0,16(a0)
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	3c0080e7          	jalr	960(ra) # 80004e08 <piperead>
    80004a50:	892a                	mv	s2,a0
    80004a52:	b7d5                	j	80004a36 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a54:	02451783          	lh	a5,36(a0)
    80004a58:	03079693          	slli	a3,a5,0x30
    80004a5c:	92c1                	srli	a3,a3,0x30
    80004a5e:	4725                	li	a4,9
    80004a60:	02d76863          	bltu	a4,a3,80004a90 <fileread+0xba>
    80004a64:	0792                	slli	a5,a5,0x4
    80004a66:	0001d717          	auipc	a4,0x1d
    80004a6a:	0e270713          	addi	a4,a4,226 # 80021b48 <devsw>
    80004a6e:	97ba                	add	a5,a5,a4
    80004a70:	639c                	ld	a5,0(a5)
    80004a72:	c38d                	beqz	a5,80004a94 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a74:	4505                	li	a0,1
    80004a76:	9782                	jalr	a5
    80004a78:	892a                	mv	s2,a0
    80004a7a:	bf75                	j	80004a36 <fileread+0x60>
    panic("fileread");
    80004a7c:	00004517          	auipc	a0,0x4
    80004a80:	cf450513          	addi	a0,a0,-780 # 80008770 <syscalls+0x260>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	aa6080e7          	jalr	-1370(ra) # 8000052a <panic>
    return -1;
    80004a8c:	597d                	li	s2,-1
    80004a8e:	b765                	j	80004a36 <fileread+0x60>
      return -1;
    80004a90:	597d                	li	s2,-1
    80004a92:	b755                	j	80004a36 <fileread+0x60>
    80004a94:	597d                	li	s2,-1
    80004a96:	b745                	j	80004a36 <fileread+0x60>

0000000080004a98 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a98:	715d                	addi	sp,sp,-80
    80004a9a:	e486                	sd	ra,72(sp)
    80004a9c:	e0a2                	sd	s0,64(sp)
    80004a9e:	fc26                	sd	s1,56(sp)
    80004aa0:	f84a                	sd	s2,48(sp)
    80004aa2:	f44e                	sd	s3,40(sp)
    80004aa4:	f052                	sd	s4,32(sp)
    80004aa6:	ec56                	sd	s5,24(sp)
    80004aa8:	e85a                	sd	s6,16(sp)
    80004aaa:	e45e                	sd	s7,8(sp)
    80004aac:	e062                	sd	s8,0(sp)
    80004aae:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ab0:	00954783          	lbu	a5,9(a0)
    80004ab4:	10078663          	beqz	a5,80004bc0 <filewrite+0x128>
    80004ab8:	892a                	mv	s2,a0
    80004aba:	8aae                	mv	s5,a1
    80004abc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004abe:	411c                	lw	a5,0(a0)
    80004ac0:	4705                	li	a4,1
    80004ac2:	02e78263          	beq	a5,a4,80004ae6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ac6:	470d                	li	a4,3
    80004ac8:	02e78663          	beq	a5,a4,80004af4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004acc:	4709                	li	a4,2
    80004ace:	0ee79163          	bne	a5,a4,80004bb0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ad2:	0ac05d63          	blez	a2,80004b8c <filewrite+0xf4>
    int i = 0;
    80004ad6:	4981                	li	s3,0
    80004ad8:	6b05                	lui	s6,0x1
    80004ada:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ade:	6b85                	lui	s7,0x1
    80004ae0:	c00b8b9b          	addiw	s7,s7,-1024
    80004ae4:	a861                	j	80004b7c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ae6:	6908                	ld	a0,16(a0)
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	22e080e7          	jalr	558(ra) # 80004d16 <pipewrite>
    80004af0:	8a2a                	mv	s4,a0
    80004af2:	a045                	j	80004b92 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004af4:	02451783          	lh	a5,36(a0)
    80004af8:	03079693          	slli	a3,a5,0x30
    80004afc:	92c1                	srli	a3,a3,0x30
    80004afe:	4725                	li	a4,9
    80004b00:	0cd76263          	bltu	a4,a3,80004bc4 <filewrite+0x12c>
    80004b04:	0792                	slli	a5,a5,0x4
    80004b06:	0001d717          	auipc	a4,0x1d
    80004b0a:	04270713          	addi	a4,a4,66 # 80021b48 <devsw>
    80004b0e:	97ba                	add	a5,a5,a4
    80004b10:	679c                	ld	a5,8(a5)
    80004b12:	cbdd                	beqz	a5,80004bc8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b14:	4505                	li	a0,1
    80004b16:	9782                	jalr	a5
    80004b18:	8a2a                	mv	s4,a0
    80004b1a:	a8a5                	j	80004b92 <filewrite+0xfa>
    80004b1c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	8b0080e7          	jalr	-1872(ra) # 800043d0 <begin_op>
      ilock(f->ip);
    80004b28:	01893503          	ld	a0,24(s2)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	ed2080e7          	jalr	-302(ra) # 800039fe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b34:	8762                	mv	a4,s8
    80004b36:	02092683          	lw	a3,32(s2)
    80004b3a:	01598633          	add	a2,s3,s5
    80004b3e:	4585                	li	a1,1
    80004b40:	01893503          	ld	a0,24(s2)
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	266080e7          	jalr	614(ra) # 80003daa <writei>
    80004b4c:	84aa                	mv	s1,a0
    80004b4e:	00a05763          	blez	a0,80004b5c <filewrite+0xc4>
        f->off += r;
    80004b52:	02092783          	lw	a5,32(s2)
    80004b56:	9fa9                	addw	a5,a5,a0
    80004b58:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b5c:	01893503          	ld	a0,24(s2)
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	f60080e7          	jalr	-160(ra) # 80003ac0 <iunlock>
      end_op();
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	8e8080e7          	jalr	-1816(ra) # 80004450 <end_op>

      if(r != n1){
    80004b70:	009c1f63          	bne	s8,s1,80004b8e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b74:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b78:	0149db63          	bge	s3,s4,80004b8e <filewrite+0xf6>
      int n1 = n - i;
    80004b7c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b80:	84be                	mv	s1,a5
    80004b82:	2781                	sext.w	a5,a5
    80004b84:	f8fb5ce3          	bge	s6,a5,80004b1c <filewrite+0x84>
    80004b88:	84de                	mv	s1,s7
    80004b8a:	bf49                	j	80004b1c <filewrite+0x84>
    int i = 0;
    80004b8c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b8e:	013a1f63          	bne	s4,s3,80004bac <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b92:	8552                	mv	a0,s4
    80004b94:	60a6                	ld	ra,72(sp)
    80004b96:	6406                	ld	s0,64(sp)
    80004b98:	74e2                	ld	s1,56(sp)
    80004b9a:	7942                	ld	s2,48(sp)
    80004b9c:	79a2                	ld	s3,40(sp)
    80004b9e:	7a02                	ld	s4,32(sp)
    80004ba0:	6ae2                	ld	s5,24(sp)
    80004ba2:	6b42                	ld	s6,16(sp)
    80004ba4:	6ba2                	ld	s7,8(sp)
    80004ba6:	6c02                	ld	s8,0(sp)
    80004ba8:	6161                	addi	sp,sp,80
    80004baa:	8082                	ret
    ret = (i == n ? n : -1);
    80004bac:	5a7d                	li	s4,-1
    80004bae:	b7d5                	j	80004b92 <filewrite+0xfa>
    panic("filewrite");
    80004bb0:	00004517          	auipc	a0,0x4
    80004bb4:	bd050513          	addi	a0,a0,-1072 # 80008780 <syscalls+0x270>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	972080e7          	jalr	-1678(ra) # 8000052a <panic>
    return -1;
    80004bc0:	5a7d                	li	s4,-1
    80004bc2:	bfc1                	j	80004b92 <filewrite+0xfa>
      return -1;
    80004bc4:	5a7d                	li	s4,-1
    80004bc6:	b7f1                	j	80004b92 <filewrite+0xfa>
    80004bc8:	5a7d                	li	s4,-1
    80004bca:	b7e1                	j	80004b92 <filewrite+0xfa>

0000000080004bcc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bcc:	7179                	addi	sp,sp,-48
    80004bce:	f406                	sd	ra,40(sp)
    80004bd0:	f022                	sd	s0,32(sp)
    80004bd2:	ec26                	sd	s1,24(sp)
    80004bd4:	e84a                	sd	s2,16(sp)
    80004bd6:	e44e                	sd	s3,8(sp)
    80004bd8:	e052                	sd	s4,0(sp)
    80004bda:	1800                	addi	s0,sp,48
    80004bdc:	84aa                	mv	s1,a0
    80004bde:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004be0:	0005b023          	sd	zero,0(a1)
    80004be4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004be8:	00000097          	auipc	ra,0x0
    80004bec:	bf8080e7          	jalr	-1032(ra) # 800047e0 <filealloc>
    80004bf0:	e088                	sd	a0,0(s1)
    80004bf2:	c551                	beqz	a0,80004c7e <pipealloc+0xb2>
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	bec080e7          	jalr	-1044(ra) # 800047e0 <filealloc>
    80004bfc:	00aa3023          	sd	a0,0(s4)
    80004c00:	c92d                	beqz	a0,80004c72 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	ed0080e7          	jalr	-304(ra) # 80000ad2 <kalloc>
    80004c0a:	892a                	mv	s2,a0
    80004c0c:	c125                	beqz	a0,80004c6c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c0e:	4985                	li	s3,1
    80004c10:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c14:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c18:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c1c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c20:	00004597          	auipc	a1,0x4
    80004c24:	b7058593          	addi	a1,a1,-1168 # 80008790 <syscalls+0x280>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	f0a080e7          	jalr	-246(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004c30:	609c                	ld	a5,0(s1)
    80004c32:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c36:	609c                	ld	a5,0(s1)
    80004c38:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c3c:	609c                	ld	a5,0(s1)
    80004c3e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c42:	609c                	ld	a5,0(s1)
    80004c44:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c48:	000a3783          	ld	a5,0(s4)
    80004c4c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c50:	000a3783          	ld	a5,0(s4)
    80004c54:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c58:	000a3783          	ld	a5,0(s4)
    80004c5c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c60:	000a3783          	ld	a5,0(s4)
    80004c64:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c68:	4501                	li	a0,0
    80004c6a:	a025                	j	80004c92 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c6c:	6088                	ld	a0,0(s1)
    80004c6e:	e501                	bnez	a0,80004c76 <pipealloc+0xaa>
    80004c70:	a039                	j	80004c7e <pipealloc+0xb2>
    80004c72:	6088                	ld	a0,0(s1)
    80004c74:	c51d                	beqz	a0,80004ca2 <pipealloc+0xd6>
    fileclose(*f0);
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	c26080e7          	jalr	-986(ra) # 8000489c <fileclose>
  if(*f1)
    80004c7e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c82:	557d                	li	a0,-1
  if(*f1)
    80004c84:	c799                	beqz	a5,80004c92 <pipealloc+0xc6>
    fileclose(*f1);
    80004c86:	853e                	mv	a0,a5
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	c14080e7          	jalr	-1004(ra) # 8000489c <fileclose>
  return -1;
    80004c90:	557d                	li	a0,-1
}
    80004c92:	70a2                	ld	ra,40(sp)
    80004c94:	7402                	ld	s0,32(sp)
    80004c96:	64e2                	ld	s1,24(sp)
    80004c98:	6942                	ld	s2,16(sp)
    80004c9a:	69a2                	ld	s3,8(sp)
    80004c9c:	6a02                	ld	s4,0(sp)
    80004c9e:	6145                	addi	sp,sp,48
    80004ca0:	8082                	ret
  return -1;
    80004ca2:	557d                	li	a0,-1
    80004ca4:	b7fd                	j	80004c92 <pipealloc+0xc6>

0000000080004ca6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ca6:	1101                	addi	sp,sp,-32
    80004ca8:	ec06                	sd	ra,24(sp)
    80004caa:	e822                	sd	s0,16(sp)
    80004cac:	e426                	sd	s1,8(sp)
    80004cae:	e04a                	sd	s2,0(sp)
    80004cb0:	1000                	addi	s0,sp,32
    80004cb2:	84aa                	mv	s1,a0
    80004cb4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	f0c080e7          	jalr	-244(ra) # 80000bc2 <acquire>
  if(writable){
    80004cbe:	02090d63          	beqz	s2,80004cf8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cc2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cc6:	21848513          	addi	a0,s1,536
    80004cca:	ffffe097          	auipc	ra,0xffffe
    80004cce:	888080e7          	jalr	-1912(ra) # 80002552 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cd2:	2204b783          	ld	a5,544(s1)
    80004cd6:	eb95                	bnez	a5,80004d0a <pipeclose+0x64>
    release(&pi->lock);
    80004cd8:	8526                	mv	a0,s1
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	f9c080e7          	jalr	-100(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	cf2080e7          	jalr	-782(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004cec:	60e2                	ld	ra,24(sp)
    80004cee:	6442                	ld	s0,16(sp)
    80004cf0:	64a2                	ld	s1,8(sp)
    80004cf2:	6902                	ld	s2,0(sp)
    80004cf4:	6105                	addi	sp,sp,32
    80004cf6:	8082                	ret
    pi->readopen = 0;
    80004cf8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cfc:	21c48513          	addi	a0,s1,540
    80004d00:	ffffe097          	auipc	ra,0xffffe
    80004d04:	852080e7          	jalr	-1966(ra) # 80002552 <wakeup>
    80004d08:	b7e9                	j	80004cd2 <pipeclose+0x2c>
    release(&pi->lock);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	f6a080e7          	jalr	-150(ra) # 80000c76 <release>
}
    80004d14:	bfe1                	j	80004cec <pipeclose+0x46>

0000000080004d16 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d16:	711d                	addi	sp,sp,-96
    80004d18:	ec86                	sd	ra,88(sp)
    80004d1a:	e8a2                	sd	s0,80(sp)
    80004d1c:	e4a6                	sd	s1,72(sp)
    80004d1e:	e0ca                	sd	s2,64(sp)
    80004d20:	fc4e                	sd	s3,56(sp)
    80004d22:	f852                	sd	s4,48(sp)
    80004d24:	f456                	sd	s5,40(sp)
    80004d26:	f05a                	sd	s6,32(sp)
    80004d28:	ec5e                	sd	s7,24(sp)
    80004d2a:	e862                	sd	s8,16(sp)
    80004d2c:	1080                	addi	s0,sp,96
    80004d2e:	84aa                	mv	s1,a0
    80004d30:	8aae                	mv	s5,a1
    80004d32:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	e3c080e7          	jalr	-452(ra) # 80001b70 <myproc>
    80004d3c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d3e:	8526                	mv	a0,s1
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	e82080e7          	jalr	-382(ra) # 80000bc2 <acquire>
  while(i < n){
    80004d48:	0b405363          	blez	s4,80004dee <pipewrite+0xd8>
  int i = 0;
    80004d4c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d4e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d50:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d54:	21c48b93          	addi	s7,s1,540
    80004d58:	a089                	j	80004d9a <pipewrite+0x84>
      release(&pi->lock);
    80004d5a:	8526                	mv	a0,s1
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	f1a080e7          	jalr	-230(ra) # 80000c76 <release>
      return -1;
    80004d64:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d66:	854a                	mv	a0,s2
    80004d68:	60e6                	ld	ra,88(sp)
    80004d6a:	6446                	ld	s0,80(sp)
    80004d6c:	64a6                	ld	s1,72(sp)
    80004d6e:	6906                	ld	s2,64(sp)
    80004d70:	79e2                	ld	s3,56(sp)
    80004d72:	7a42                	ld	s4,48(sp)
    80004d74:	7aa2                	ld	s5,40(sp)
    80004d76:	7b02                	ld	s6,32(sp)
    80004d78:	6be2                	ld	s7,24(sp)
    80004d7a:	6c42                	ld	s8,16(sp)
    80004d7c:	6125                	addi	sp,sp,96
    80004d7e:	8082                	ret
      wakeup(&pi->nread);
    80004d80:	8562                	mv	a0,s8
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	7d0080e7          	jalr	2000(ra) # 80002552 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d8a:	85a6                	mv	a1,s1
    80004d8c:	855e                	mv	a0,s7
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	638080e7          	jalr	1592(ra) # 800023c6 <sleep>
  while(i < n){
    80004d96:	05495d63          	bge	s2,s4,80004df0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004d9a:	2204a783          	lw	a5,544(s1)
    80004d9e:	dfd5                	beqz	a5,80004d5a <pipewrite+0x44>
    80004da0:	0289a783          	lw	a5,40(s3)
    80004da4:	fbdd                	bnez	a5,80004d5a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004da6:	2184a783          	lw	a5,536(s1)
    80004daa:	21c4a703          	lw	a4,540(s1)
    80004dae:	2007879b          	addiw	a5,a5,512
    80004db2:	fcf707e3          	beq	a4,a5,80004d80 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004db6:	4685                	li	a3,1
    80004db8:	01590633          	add	a2,s2,s5
    80004dbc:	faf40593          	addi	a1,s0,-81
    80004dc0:	0509b503          	ld	a0,80(s3)
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	906080e7          	jalr	-1786(ra) # 800016ca <copyin>
    80004dcc:	03650263          	beq	a0,s6,80004df0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dd0:	21c4a783          	lw	a5,540(s1)
    80004dd4:	0017871b          	addiw	a4,a5,1
    80004dd8:	20e4ae23          	sw	a4,540(s1)
    80004ddc:	1ff7f793          	andi	a5,a5,511
    80004de0:	97a6                	add	a5,a5,s1
    80004de2:	faf44703          	lbu	a4,-81(s0)
    80004de6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dea:	2905                	addiw	s2,s2,1
    80004dec:	b76d                	j	80004d96 <pipewrite+0x80>
  int i = 0;
    80004dee:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004df0:	21848513          	addi	a0,s1,536
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	75e080e7          	jalr	1886(ra) # 80002552 <wakeup>
  release(&pi->lock);
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	e78080e7          	jalr	-392(ra) # 80000c76 <release>
  return i;
    80004e06:	b785                	j	80004d66 <pipewrite+0x50>

0000000080004e08 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e08:	715d                	addi	sp,sp,-80
    80004e0a:	e486                	sd	ra,72(sp)
    80004e0c:	e0a2                	sd	s0,64(sp)
    80004e0e:	fc26                	sd	s1,56(sp)
    80004e10:	f84a                	sd	s2,48(sp)
    80004e12:	f44e                	sd	s3,40(sp)
    80004e14:	f052                	sd	s4,32(sp)
    80004e16:	ec56                	sd	s5,24(sp)
    80004e18:	e85a                	sd	s6,16(sp)
    80004e1a:	0880                	addi	s0,sp,80
    80004e1c:	84aa                	mv	s1,a0
    80004e1e:	892e                	mv	s2,a1
    80004e20:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	d4e080e7          	jalr	-690(ra) # 80001b70 <myproc>
    80004e2a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	ffffc097          	auipc	ra,0xffffc
    80004e32:	d94080e7          	jalr	-620(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e36:	2184a703          	lw	a4,536(s1)
    80004e3a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e3e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e42:	02f71463          	bne	a4,a5,80004e6a <piperead+0x62>
    80004e46:	2244a783          	lw	a5,548(s1)
    80004e4a:	c385                	beqz	a5,80004e6a <piperead+0x62>
    if(pr->killed){
    80004e4c:	028a2783          	lw	a5,40(s4)
    80004e50:	ebc1                	bnez	a5,80004ee0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e52:	85a6                	mv	a1,s1
    80004e54:	854e                	mv	a0,s3
    80004e56:	ffffd097          	auipc	ra,0xffffd
    80004e5a:	570080e7          	jalr	1392(ra) # 800023c6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e5e:	2184a703          	lw	a4,536(s1)
    80004e62:	21c4a783          	lw	a5,540(s1)
    80004e66:	fef700e3          	beq	a4,a5,80004e46 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e6a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e6c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e6e:	05505363          	blez	s5,80004eb4 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e72:	2184a783          	lw	a5,536(s1)
    80004e76:	21c4a703          	lw	a4,540(s1)
    80004e7a:	02f70d63          	beq	a4,a5,80004eb4 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e7e:	0017871b          	addiw	a4,a5,1
    80004e82:	20e4ac23          	sw	a4,536(s1)
    80004e86:	1ff7f793          	andi	a5,a5,511
    80004e8a:	97a6                	add	a5,a5,s1
    80004e8c:	0187c783          	lbu	a5,24(a5)
    80004e90:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e94:	4685                	li	a3,1
    80004e96:	fbf40613          	addi	a2,s0,-65
    80004e9a:	85ca                	mv	a1,s2
    80004e9c:	050a3503          	ld	a0,80(s4)
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	79e080e7          	jalr	1950(ra) # 8000163e <copyout>
    80004ea8:	01650663          	beq	a0,s6,80004eb4 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eac:	2985                	addiw	s3,s3,1
    80004eae:	0905                	addi	s2,s2,1
    80004eb0:	fd3a91e3          	bne	s5,s3,80004e72 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eb4:	21c48513          	addi	a0,s1,540
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	69a080e7          	jalr	1690(ra) # 80002552 <wakeup>
  release(&pi->lock);
    80004ec0:	8526                	mv	a0,s1
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	db4080e7          	jalr	-588(ra) # 80000c76 <release>
  return i;
}
    80004eca:	854e                	mv	a0,s3
    80004ecc:	60a6                	ld	ra,72(sp)
    80004ece:	6406                	ld	s0,64(sp)
    80004ed0:	74e2                	ld	s1,56(sp)
    80004ed2:	7942                	ld	s2,48(sp)
    80004ed4:	79a2                	ld	s3,40(sp)
    80004ed6:	7a02                	ld	s4,32(sp)
    80004ed8:	6ae2                	ld	s5,24(sp)
    80004eda:	6b42                	ld	s6,16(sp)
    80004edc:	6161                	addi	sp,sp,80
    80004ede:	8082                	ret
      release(&pi->lock);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	d94080e7          	jalr	-620(ra) # 80000c76 <release>
      return -1;
    80004eea:	59fd                	li	s3,-1
    80004eec:	bff9                	j	80004eca <piperead+0xc2>

0000000080004eee <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004eee:	de010113          	addi	sp,sp,-544
    80004ef2:	20113c23          	sd	ra,536(sp)
    80004ef6:	20813823          	sd	s0,528(sp)
    80004efa:	20913423          	sd	s1,520(sp)
    80004efe:	21213023          	sd	s2,512(sp)
    80004f02:	ffce                	sd	s3,504(sp)
    80004f04:	fbd2                	sd	s4,496(sp)
    80004f06:	f7d6                	sd	s5,488(sp)
    80004f08:	f3da                	sd	s6,480(sp)
    80004f0a:	efde                	sd	s7,472(sp)
    80004f0c:	ebe2                	sd	s8,464(sp)
    80004f0e:	e7e6                	sd	s9,456(sp)
    80004f10:	e3ea                	sd	s10,448(sp)
    80004f12:	ff6e                	sd	s11,440(sp)
    80004f14:	1400                	addi	s0,sp,544
    80004f16:	892a                	mv	s2,a0
    80004f18:	dea43423          	sd	a0,-536(s0)
    80004f1c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	c50080e7          	jalr	-944(ra) # 80001b70 <myproc>
    80004f28:	84aa                	mv	s1,a0

  begin_op();
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	4a6080e7          	jalr	1190(ra) # 800043d0 <begin_op>

  if((ip = namei(path)) == 0){
    80004f32:	854a                	mv	a0,s2
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	280080e7          	jalr	640(ra) # 800041b4 <namei>
    80004f3c:	c93d                	beqz	a0,80004fb2 <exec+0xc4>
    80004f3e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f40:	fffff097          	auipc	ra,0xfffff
    80004f44:	abe080e7          	jalr	-1346(ra) # 800039fe <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f48:	04000713          	li	a4,64
    80004f4c:	4681                	li	a3,0
    80004f4e:	e4840613          	addi	a2,s0,-440
    80004f52:	4581                	li	a1,0
    80004f54:	8556                	mv	a0,s5
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	d5c080e7          	jalr	-676(ra) # 80003cb2 <readi>
    80004f5e:	04000793          	li	a5,64
    80004f62:	00f51a63          	bne	a0,a5,80004f76 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f66:	e4842703          	lw	a4,-440(s0)
    80004f6a:	464c47b7          	lui	a5,0x464c4
    80004f6e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f72:	04f70663          	beq	a4,a5,80004fbe <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f76:	8556                	mv	a0,s5
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	ce8080e7          	jalr	-792(ra) # 80003c60 <iunlockput>
    end_op();
    80004f80:	fffff097          	auipc	ra,0xfffff
    80004f84:	4d0080e7          	jalr	1232(ra) # 80004450 <end_op>
  }
  return -1;
    80004f88:	557d                	li	a0,-1
}
    80004f8a:	21813083          	ld	ra,536(sp)
    80004f8e:	21013403          	ld	s0,528(sp)
    80004f92:	20813483          	ld	s1,520(sp)
    80004f96:	20013903          	ld	s2,512(sp)
    80004f9a:	79fe                	ld	s3,504(sp)
    80004f9c:	7a5e                	ld	s4,496(sp)
    80004f9e:	7abe                	ld	s5,488(sp)
    80004fa0:	7b1e                	ld	s6,480(sp)
    80004fa2:	6bfe                	ld	s7,472(sp)
    80004fa4:	6c5e                	ld	s8,464(sp)
    80004fa6:	6cbe                	ld	s9,456(sp)
    80004fa8:	6d1e                	ld	s10,448(sp)
    80004faa:	7dfa                	ld	s11,440(sp)
    80004fac:	22010113          	addi	sp,sp,544
    80004fb0:	8082                	ret
    end_op();
    80004fb2:	fffff097          	auipc	ra,0xfffff
    80004fb6:	49e080e7          	jalr	1182(ra) # 80004450 <end_op>
    return -1;
    80004fba:	557d                	li	a0,-1
    80004fbc:	b7f9                	j	80004f8a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fbe:	8526                	mv	a0,s1
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	c76080e7          	jalr	-906(ra) # 80001c36 <proc_pagetable>
    80004fc8:	8b2a                	mv	s6,a0
    80004fca:	d555                	beqz	a0,80004f76 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fcc:	e6842783          	lw	a5,-408(s0)
    80004fd0:	e8045703          	lhu	a4,-384(s0)
    80004fd4:	c735                	beqz	a4,80005040 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fd6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fdc:	6a05                	lui	s4,0x1
    80004fde:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004fe2:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004fe6:	6d85                	lui	s11,0x1
    80004fe8:	7d7d                	lui	s10,0xfffff
    80004fea:	ac1d                	j	80005220 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fec:	00003517          	auipc	a0,0x3
    80004ff0:	7ac50513          	addi	a0,a0,1964 # 80008798 <syscalls+0x288>
    80004ff4:	ffffb097          	auipc	ra,0xffffb
    80004ff8:	536080e7          	jalr	1334(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ffc:	874a                	mv	a4,s2
    80004ffe:	009c86bb          	addw	a3,s9,s1
    80005002:	4581                	li	a1,0
    80005004:	8556                	mv	a0,s5
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	cac080e7          	jalr	-852(ra) # 80003cb2 <readi>
    8000500e:	2501                	sext.w	a0,a0
    80005010:	1aa91863          	bne	s2,a0,800051c0 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005014:	009d84bb          	addw	s1,s11,s1
    80005018:	013d09bb          	addw	s3,s10,s3
    8000501c:	1f74f263          	bgeu	s1,s7,80005200 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005020:	02049593          	slli	a1,s1,0x20
    80005024:	9181                	srli	a1,a1,0x20
    80005026:	95e2                	add	a1,a1,s8
    80005028:	855a                	mv	a0,s6
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	022080e7          	jalr	34(ra) # 8000104c <walkaddr>
    80005032:	862a                	mv	a2,a0
    if(pa == 0)
    80005034:	dd45                	beqz	a0,80004fec <exec+0xfe>
      n = PGSIZE;
    80005036:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005038:	fd49f2e3          	bgeu	s3,s4,80004ffc <exec+0x10e>
      n = sz - i;
    8000503c:	894e                	mv	s2,s3
    8000503e:	bf7d                	j	80004ffc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005040:	4481                	li	s1,0
  iunlockput(ip);
    80005042:	8556                	mv	a0,s5
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	c1c080e7          	jalr	-996(ra) # 80003c60 <iunlockput>
  end_op();
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	404080e7          	jalr	1028(ra) # 80004450 <end_op>
  p = myproc();
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	b1c080e7          	jalr	-1252(ra) # 80001b70 <myproc>
    8000505c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000505e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005062:	6785                	lui	a5,0x1
    80005064:	17fd                	addi	a5,a5,-1
    80005066:	94be                	add	s1,s1,a5
    80005068:	77fd                	lui	a5,0xfffff
    8000506a:	8fe5                	and	a5,a5,s1
    8000506c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005070:	6609                	lui	a2,0x2
    80005072:	963e                	add	a2,a2,a5
    80005074:	85be                	mv	a1,a5
    80005076:	855a                	mv	a0,s6
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	376080e7          	jalr	886(ra) # 800013ee <uvmalloc>
    80005080:	8c2a                	mv	s8,a0
  ip = 0;
    80005082:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005084:	12050e63          	beqz	a0,800051c0 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005088:	75f9                	lui	a1,0xffffe
    8000508a:	95aa                	add	a1,a1,a0
    8000508c:	855a                	mv	a0,s6
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	57e080e7          	jalr	1406(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80005096:	7afd                	lui	s5,0xfffff
    80005098:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000509a:	df043783          	ld	a5,-528(s0)
    8000509e:	6388                	ld	a0,0(a5)
    800050a0:	c925                	beqz	a0,80005110 <exec+0x222>
    800050a2:	e8840993          	addi	s3,s0,-376
    800050a6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800050aa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ac:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	d94080e7          	jalr	-620(ra) # 80000e42 <strlen>
    800050b6:	0015079b          	addiw	a5,a0,1
    800050ba:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050be:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050c2:	13596363          	bltu	s2,s5,800051e8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050c6:	df043d83          	ld	s11,-528(s0)
    800050ca:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050ce:	8552                	mv	a0,s4
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	d72080e7          	jalr	-654(ra) # 80000e42 <strlen>
    800050d8:	0015069b          	addiw	a3,a0,1
    800050dc:	8652                	mv	a2,s4
    800050de:	85ca                	mv	a1,s2
    800050e0:	855a                	mv	a0,s6
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	55c080e7          	jalr	1372(ra) # 8000163e <copyout>
    800050ea:	10054363          	bltz	a0,800051f0 <exec+0x302>
    ustack[argc] = sp;
    800050ee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050f2:	0485                	addi	s1,s1,1
    800050f4:	008d8793          	addi	a5,s11,8
    800050f8:	def43823          	sd	a5,-528(s0)
    800050fc:	008db503          	ld	a0,8(s11)
    80005100:	c911                	beqz	a0,80005114 <exec+0x226>
    if(argc >= MAXARG)
    80005102:	09a1                	addi	s3,s3,8
    80005104:	fb3c95e3          	bne	s9,s3,800050ae <exec+0x1c0>
  sz = sz1;
    80005108:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000510c:	4a81                	li	s5,0
    8000510e:	a84d                	j	800051c0 <exec+0x2d2>
  sp = sz;
    80005110:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005112:	4481                	li	s1,0
  ustack[argc] = 0;
    80005114:	00349793          	slli	a5,s1,0x3
    80005118:	f9040713          	addi	a4,s0,-112
    8000511c:	97ba                	add	a5,a5,a4
    8000511e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005122:	00148693          	addi	a3,s1,1
    80005126:	068e                	slli	a3,a3,0x3
    80005128:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000512c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005130:	01597663          	bgeu	s2,s5,8000513c <exec+0x24e>
  sz = sz1;
    80005134:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005138:	4a81                	li	s5,0
    8000513a:	a059                	j	800051c0 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000513c:	e8840613          	addi	a2,s0,-376
    80005140:	85ca                	mv	a1,s2
    80005142:	855a                	mv	a0,s6
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	4fa080e7          	jalr	1274(ra) # 8000163e <copyout>
    8000514c:	0a054663          	bltz	a0,800051f8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005150:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005154:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005158:	de843783          	ld	a5,-536(s0)
    8000515c:	0007c703          	lbu	a4,0(a5)
    80005160:	cf11                	beqz	a4,8000517c <exec+0x28e>
    80005162:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005164:	02f00693          	li	a3,47
    80005168:	a039                	j	80005176 <exec+0x288>
      last = s+1;
    8000516a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000516e:	0785                	addi	a5,a5,1
    80005170:	fff7c703          	lbu	a4,-1(a5)
    80005174:	c701                	beqz	a4,8000517c <exec+0x28e>
    if(*s == '/')
    80005176:	fed71ce3          	bne	a4,a3,8000516e <exec+0x280>
    8000517a:	bfc5                	j	8000516a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000517c:	4641                	li	a2,16
    8000517e:	de843583          	ld	a1,-536(s0)
    80005182:	158b8513          	addi	a0,s7,344
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	c8a080e7          	jalr	-886(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    8000518e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005192:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005196:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000519a:	058bb783          	ld	a5,88(s7)
    8000519e:	e6043703          	ld	a4,-416(s0)
    800051a2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051a4:	058bb783          	ld	a5,88(s7)
    800051a8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051ac:	85ea                	mv	a1,s10
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	b24080e7          	jalr	-1244(ra) # 80001cd2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051b6:	0004851b          	sext.w	a0,s1
    800051ba:	bbc1                	j	80004f8a <exec+0x9c>
    800051bc:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051c0:	df843583          	ld	a1,-520(s0)
    800051c4:	855a                	mv	a0,s6
    800051c6:	ffffd097          	auipc	ra,0xffffd
    800051ca:	b0c080e7          	jalr	-1268(ra) # 80001cd2 <proc_freepagetable>
  if(ip){
    800051ce:	da0a94e3          	bnez	s5,80004f76 <exec+0x88>
  return -1;
    800051d2:	557d                	li	a0,-1
    800051d4:	bb5d                	j	80004f8a <exec+0x9c>
    800051d6:	de943c23          	sd	s1,-520(s0)
    800051da:	b7dd                	j	800051c0 <exec+0x2d2>
    800051dc:	de943c23          	sd	s1,-520(s0)
    800051e0:	b7c5                	j	800051c0 <exec+0x2d2>
    800051e2:	de943c23          	sd	s1,-520(s0)
    800051e6:	bfe9                	j	800051c0 <exec+0x2d2>
  sz = sz1;
    800051e8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ec:	4a81                	li	s5,0
    800051ee:	bfc9                	j	800051c0 <exec+0x2d2>
  sz = sz1;
    800051f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051f4:	4a81                	li	s5,0
    800051f6:	b7e9                	j	800051c0 <exec+0x2d2>
  sz = sz1;
    800051f8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051fc:	4a81                	li	s5,0
    800051fe:	b7c9                	j	800051c0 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005200:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005204:	e0843783          	ld	a5,-504(s0)
    80005208:	0017869b          	addiw	a3,a5,1
    8000520c:	e0d43423          	sd	a3,-504(s0)
    80005210:	e0043783          	ld	a5,-512(s0)
    80005214:	0387879b          	addiw	a5,a5,56
    80005218:	e8045703          	lhu	a4,-384(s0)
    8000521c:	e2e6d3e3          	bge	a3,a4,80005042 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005220:	2781                	sext.w	a5,a5
    80005222:	e0f43023          	sd	a5,-512(s0)
    80005226:	03800713          	li	a4,56
    8000522a:	86be                	mv	a3,a5
    8000522c:	e1040613          	addi	a2,s0,-496
    80005230:	4581                	li	a1,0
    80005232:	8556                	mv	a0,s5
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	a7e080e7          	jalr	-1410(ra) # 80003cb2 <readi>
    8000523c:	03800793          	li	a5,56
    80005240:	f6f51ee3          	bne	a0,a5,800051bc <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005244:	e1042783          	lw	a5,-496(s0)
    80005248:	4705                	li	a4,1
    8000524a:	fae79de3          	bne	a5,a4,80005204 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000524e:	e3843603          	ld	a2,-456(s0)
    80005252:	e3043783          	ld	a5,-464(s0)
    80005256:	f8f660e3          	bltu	a2,a5,800051d6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000525a:	e2043783          	ld	a5,-480(s0)
    8000525e:	963e                	add	a2,a2,a5
    80005260:	f6f66ee3          	bltu	a2,a5,800051dc <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005264:	85a6                	mv	a1,s1
    80005266:	855a                	mv	a0,s6
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	186080e7          	jalr	390(ra) # 800013ee <uvmalloc>
    80005270:	dea43c23          	sd	a0,-520(s0)
    80005274:	d53d                	beqz	a0,800051e2 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005276:	e2043c03          	ld	s8,-480(s0)
    8000527a:	de043783          	ld	a5,-544(s0)
    8000527e:	00fc77b3          	and	a5,s8,a5
    80005282:	ff9d                	bnez	a5,800051c0 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005284:	e1842c83          	lw	s9,-488(s0)
    80005288:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000528c:	f60b8ae3          	beqz	s7,80005200 <exec+0x312>
    80005290:	89de                	mv	s3,s7
    80005292:	4481                	li	s1,0
    80005294:	b371                	j	80005020 <exec+0x132>

0000000080005296 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005296:	7179                	addi	sp,sp,-48
    80005298:	f406                	sd	ra,40(sp)
    8000529a:	f022                	sd	s0,32(sp)
    8000529c:	ec26                	sd	s1,24(sp)
    8000529e:	e84a                	sd	s2,16(sp)
    800052a0:	1800                	addi	s0,sp,48
    800052a2:	892e                	mv	s2,a1
    800052a4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052a6:	fdc40593          	addi	a1,s0,-36
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	b68080e7          	jalr	-1176(ra) # 80002e12 <argint>
    800052b2:	04054063          	bltz	a0,800052f2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052b6:	fdc42703          	lw	a4,-36(s0)
    800052ba:	47bd                	li	a5,15
    800052bc:	02e7ed63          	bltu	a5,a4,800052f6 <argfd+0x60>
    800052c0:	ffffd097          	auipc	ra,0xffffd
    800052c4:	8b0080e7          	jalr	-1872(ra) # 80001b70 <myproc>
    800052c8:	fdc42703          	lw	a4,-36(s0)
    800052cc:	01a70793          	addi	a5,a4,26
    800052d0:	078e                	slli	a5,a5,0x3
    800052d2:	953e                	add	a0,a0,a5
    800052d4:	611c                	ld	a5,0(a0)
    800052d6:	c395                	beqz	a5,800052fa <argfd+0x64>
    return -1;
  if(pfd)
    800052d8:	00090463          	beqz	s2,800052e0 <argfd+0x4a>
    *pfd = fd;
    800052dc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052e0:	4501                	li	a0,0
  if(pf)
    800052e2:	c091                	beqz	s1,800052e6 <argfd+0x50>
    *pf = f;
    800052e4:	e09c                	sd	a5,0(s1)
}
    800052e6:	70a2                	ld	ra,40(sp)
    800052e8:	7402                	ld	s0,32(sp)
    800052ea:	64e2                	ld	s1,24(sp)
    800052ec:	6942                	ld	s2,16(sp)
    800052ee:	6145                	addi	sp,sp,48
    800052f0:	8082                	ret
    return -1;
    800052f2:	557d                	li	a0,-1
    800052f4:	bfcd                	j	800052e6 <argfd+0x50>
    return -1;
    800052f6:	557d                	li	a0,-1
    800052f8:	b7fd                	j	800052e6 <argfd+0x50>
    800052fa:	557d                	li	a0,-1
    800052fc:	b7ed                	j	800052e6 <argfd+0x50>

00000000800052fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052fe:	1101                	addi	sp,sp,-32
    80005300:	ec06                	sd	ra,24(sp)
    80005302:	e822                	sd	s0,16(sp)
    80005304:	e426                	sd	s1,8(sp)
    80005306:	1000                	addi	s0,sp,32
    80005308:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000530a:	ffffd097          	auipc	ra,0xffffd
    8000530e:	866080e7          	jalr	-1946(ra) # 80001b70 <myproc>
    80005312:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005314:	0d050793          	addi	a5,a0,208
    80005318:	4501                	li	a0,0
    8000531a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000531c:	6398                	ld	a4,0(a5)
    8000531e:	cb19                	beqz	a4,80005334 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005320:	2505                	addiw	a0,a0,1
    80005322:	07a1                	addi	a5,a5,8
    80005324:	fed51ce3          	bne	a0,a3,8000531c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005328:	557d                	li	a0,-1
}
    8000532a:	60e2                	ld	ra,24(sp)
    8000532c:	6442                	ld	s0,16(sp)
    8000532e:	64a2                	ld	s1,8(sp)
    80005330:	6105                	addi	sp,sp,32
    80005332:	8082                	ret
      p->ofile[fd] = f;
    80005334:	01a50793          	addi	a5,a0,26
    80005338:	078e                	slli	a5,a5,0x3
    8000533a:	963e                	add	a2,a2,a5
    8000533c:	e204                	sd	s1,0(a2)
      return fd;
    8000533e:	b7f5                	j	8000532a <fdalloc+0x2c>

0000000080005340 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005340:	715d                	addi	sp,sp,-80
    80005342:	e486                	sd	ra,72(sp)
    80005344:	e0a2                	sd	s0,64(sp)
    80005346:	fc26                	sd	s1,56(sp)
    80005348:	f84a                	sd	s2,48(sp)
    8000534a:	f44e                	sd	s3,40(sp)
    8000534c:	f052                	sd	s4,32(sp)
    8000534e:	ec56                	sd	s5,24(sp)
    80005350:	0880                	addi	s0,sp,80
    80005352:	89ae                	mv	s3,a1
    80005354:	8ab2                	mv	s5,a2
    80005356:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005358:	fb040593          	addi	a1,s0,-80
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	e76080e7          	jalr	-394(ra) # 800041d2 <nameiparent>
    80005364:	892a                	mv	s2,a0
    80005366:	12050e63          	beqz	a0,800054a2 <create+0x162>
    return 0;

  ilock(dp);
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	694080e7          	jalr	1684(ra) # 800039fe <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005372:	4601                	li	a2,0
    80005374:	fb040593          	addi	a1,s0,-80
    80005378:	854a                	mv	a0,s2
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	b68080e7          	jalr	-1176(ra) # 80003ee2 <dirlookup>
    80005382:	84aa                	mv	s1,a0
    80005384:	c921                	beqz	a0,800053d4 <create+0x94>
    iunlockput(dp);
    80005386:	854a                	mv	a0,s2
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	8d8080e7          	jalr	-1832(ra) # 80003c60 <iunlockput>
    ilock(ip);
    80005390:	8526                	mv	a0,s1
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	66c080e7          	jalr	1644(ra) # 800039fe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000539a:	2981                	sext.w	s3,s3
    8000539c:	4789                	li	a5,2
    8000539e:	02f99463          	bne	s3,a5,800053c6 <create+0x86>
    800053a2:	0444d783          	lhu	a5,68(s1)
    800053a6:	37f9                	addiw	a5,a5,-2
    800053a8:	17c2                	slli	a5,a5,0x30
    800053aa:	93c1                	srli	a5,a5,0x30
    800053ac:	4705                	li	a4,1
    800053ae:	00f76c63          	bltu	a4,a5,800053c6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053b2:	8526                	mv	a0,s1
    800053b4:	60a6                	ld	ra,72(sp)
    800053b6:	6406                	ld	s0,64(sp)
    800053b8:	74e2                	ld	s1,56(sp)
    800053ba:	7942                	ld	s2,48(sp)
    800053bc:	79a2                	ld	s3,40(sp)
    800053be:	7a02                	ld	s4,32(sp)
    800053c0:	6ae2                	ld	s5,24(sp)
    800053c2:	6161                	addi	sp,sp,80
    800053c4:	8082                	ret
    iunlockput(ip);
    800053c6:	8526                	mv	a0,s1
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	898080e7          	jalr	-1896(ra) # 80003c60 <iunlockput>
    return 0;
    800053d0:	4481                	li	s1,0
    800053d2:	b7c5                	j	800053b2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053d4:	85ce                	mv	a1,s3
    800053d6:	00092503          	lw	a0,0(s2)
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	48c080e7          	jalr	1164(ra) # 80003866 <ialloc>
    800053e2:	84aa                	mv	s1,a0
    800053e4:	c521                	beqz	a0,8000542c <create+0xec>
  ilock(ip);
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	618080e7          	jalr	1560(ra) # 800039fe <ilock>
  ip->major = major;
    800053ee:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053f2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053f6:	4a05                	li	s4,1
    800053f8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800053fc:	8526                	mv	a0,s1
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	536080e7          	jalr	1334(ra) # 80003934 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005406:	2981                	sext.w	s3,s3
    80005408:	03498a63          	beq	s3,s4,8000543c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000540c:	40d0                	lw	a2,4(s1)
    8000540e:	fb040593          	addi	a1,s0,-80
    80005412:	854a                	mv	a0,s2
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	cde080e7          	jalr	-802(ra) # 800040f2 <dirlink>
    8000541c:	06054b63          	bltz	a0,80005492 <create+0x152>
  iunlockput(dp);
    80005420:	854a                	mv	a0,s2
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	83e080e7          	jalr	-1986(ra) # 80003c60 <iunlockput>
  return ip;
    8000542a:	b761                	j	800053b2 <create+0x72>
    panic("create: ialloc");
    8000542c:	00003517          	auipc	a0,0x3
    80005430:	38c50513          	addi	a0,a0,908 # 800087b8 <syscalls+0x2a8>
    80005434:	ffffb097          	auipc	ra,0xffffb
    80005438:	0f6080e7          	jalr	246(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000543c:	04a95783          	lhu	a5,74(s2)
    80005440:	2785                	addiw	a5,a5,1
    80005442:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005446:	854a                	mv	a0,s2
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	4ec080e7          	jalr	1260(ra) # 80003934 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005450:	40d0                	lw	a2,4(s1)
    80005452:	00003597          	auipc	a1,0x3
    80005456:	37658593          	addi	a1,a1,886 # 800087c8 <syscalls+0x2b8>
    8000545a:	8526                	mv	a0,s1
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	c96080e7          	jalr	-874(ra) # 800040f2 <dirlink>
    80005464:	00054f63          	bltz	a0,80005482 <create+0x142>
    80005468:	00492603          	lw	a2,4(s2)
    8000546c:	00003597          	auipc	a1,0x3
    80005470:	36458593          	addi	a1,a1,868 # 800087d0 <syscalls+0x2c0>
    80005474:	8526                	mv	a0,s1
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	c7c080e7          	jalr	-900(ra) # 800040f2 <dirlink>
    8000547e:	f80557e3          	bgez	a0,8000540c <create+0xcc>
      panic("create dots");
    80005482:	00003517          	auipc	a0,0x3
    80005486:	35650513          	addi	a0,a0,854 # 800087d8 <syscalls+0x2c8>
    8000548a:	ffffb097          	auipc	ra,0xffffb
    8000548e:	0a0080e7          	jalr	160(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005492:	00003517          	auipc	a0,0x3
    80005496:	35650513          	addi	a0,a0,854 # 800087e8 <syscalls+0x2d8>
    8000549a:	ffffb097          	auipc	ra,0xffffb
    8000549e:	090080e7          	jalr	144(ra) # 8000052a <panic>
    return 0;
    800054a2:	84aa                	mv	s1,a0
    800054a4:	b739                	j	800053b2 <create+0x72>

00000000800054a6 <sys_dup>:
{
    800054a6:	7179                	addi	sp,sp,-48
    800054a8:	f406                	sd	ra,40(sp)
    800054aa:	f022                	sd	s0,32(sp)
    800054ac:	ec26                	sd	s1,24(sp)
    800054ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054b0:	fd840613          	addi	a2,s0,-40
    800054b4:	4581                	li	a1,0
    800054b6:	4501                	li	a0,0
    800054b8:	00000097          	auipc	ra,0x0
    800054bc:	dde080e7          	jalr	-546(ra) # 80005296 <argfd>
    return -1;
    800054c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054c2:	02054363          	bltz	a0,800054e8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054c6:	fd843503          	ld	a0,-40(s0)
    800054ca:	00000097          	auipc	ra,0x0
    800054ce:	e34080e7          	jalr	-460(ra) # 800052fe <fdalloc>
    800054d2:	84aa                	mv	s1,a0
    return -1;
    800054d4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054d6:	00054963          	bltz	a0,800054e8 <sys_dup+0x42>
  filedup(f);
    800054da:	fd843503          	ld	a0,-40(s0)
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	36c080e7          	jalr	876(ra) # 8000484a <filedup>
  return fd;
    800054e6:	87a6                	mv	a5,s1
}
    800054e8:	853e                	mv	a0,a5
    800054ea:	70a2                	ld	ra,40(sp)
    800054ec:	7402                	ld	s0,32(sp)
    800054ee:	64e2                	ld	s1,24(sp)
    800054f0:	6145                	addi	sp,sp,48
    800054f2:	8082                	ret

00000000800054f4 <sys_read>:
{
    800054f4:	7179                	addi	sp,sp,-48
    800054f6:	f406                	sd	ra,40(sp)
    800054f8:	f022                	sd	s0,32(sp)
    800054fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fc:	fe840613          	addi	a2,s0,-24
    80005500:	4581                	li	a1,0
    80005502:	4501                	li	a0,0
    80005504:	00000097          	auipc	ra,0x0
    80005508:	d92080e7          	jalr	-622(ra) # 80005296 <argfd>
    return -1;
    8000550c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550e:	04054163          	bltz	a0,80005550 <sys_read+0x5c>
    80005512:	fe440593          	addi	a1,s0,-28
    80005516:	4509                	li	a0,2
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	8fa080e7          	jalr	-1798(ra) # 80002e12 <argint>
    return -1;
    80005520:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005522:	02054763          	bltz	a0,80005550 <sys_read+0x5c>
    80005526:	fd840593          	addi	a1,s0,-40
    8000552a:	4505                	li	a0,1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	908080e7          	jalr	-1784(ra) # 80002e34 <argaddr>
    return -1;
    80005534:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005536:	00054d63          	bltz	a0,80005550 <sys_read+0x5c>
  return fileread(f, p, n);
    8000553a:	fe442603          	lw	a2,-28(s0)
    8000553e:	fd843583          	ld	a1,-40(s0)
    80005542:	fe843503          	ld	a0,-24(s0)
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	490080e7          	jalr	1168(ra) # 800049d6 <fileread>
    8000554e:	87aa                	mv	a5,a0
}
    80005550:	853e                	mv	a0,a5
    80005552:	70a2                	ld	ra,40(sp)
    80005554:	7402                	ld	s0,32(sp)
    80005556:	6145                	addi	sp,sp,48
    80005558:	8082                	ret

000000008000555a <sys_write>:
{
    8000555a:	7179                	addi	sp,sp,-48
    8000555c:	f406                	sd	ra,40(sp)
    8000555e:	f022                	sd	s0,32(sp)
    80005560:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005562:	fe840613          	addi	a2,s0,-24
    80005566:	4581                	li	a1,0
    80005568:	4501                	li	a0,0
    8000556a:	00000097          	auipc	ra,0x0
    8000556e:	d2c080e7          	jalr	-724(ra) # 80005296 <argfd>
    return -1;
    80005572:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005574:	04054163          	bltz	a0,800055b6 <sys_write+0x5c>
    80005578:	fe440593          	addi	a1,s0,-28
    8000557c:	4509                	li	a0,2
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	894080e7          	jalr	-1900(ra) # 80002e12 <argint>
    return -1;
    80005586:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005588:	02054763          	bltz	a0,800055b6 <sys_write+0x5c>
    8000558c:	fd840593          	addi	a1,s0,-40
    80005590:	4505                	li	a0,1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	8a2080e7          	jalr	-1886(ra) # 80002e34 <argaddr>
    return -1;
    8000559a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000559c:	00054d63          	bltz	a0,800055b6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800055a0:	fe442603          	lw	a2,-28(s0)
    800055a4:	fd843583          	ld	a1,-40(s0)
    800055a8:	fe843503          	ld	a0,-24(s0)
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	4ec080e7          	jalr	1260(ra) # 80004a98 <filewrite>
    800055b4:	87aa                	mv	a5,a0
}
    800055b6:	853e                	mv	a0,a5
    800055b8:	70a2                	ld	ra,40(sp)
    800055ba:	7402                	ld	s0,32(sp)
    800055bc:	6145                	addi	sp,sp,48
    800055be:	8082                	ret

00000000800055c0 <sys_close>:
{
    800055c0:	1101                	addi	sp,sp,-32
    800055c2:	ec06                	sd	ra,24(sp)
    800055c4:	e822                	sd	s0,16(sp)
    800055c6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055c8:	fe040613          	addi	a2,s0,-32
    800055cc:	fec40593          	addi	a1,s0,-20
    800055d0:	4501                	li	a0,0
    800055d2:	00000097          	auipc	ra,0x0
    800055d6:	cc4080e7          	jalr	-828(ra) # 80005296 <argfd>
    return -1;
    800055da:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055dc:	02054463          	bltz	a0,80005604 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055e0:	ffffc097          	auipc	ra,0xffffc
    800055e4:	590080e7          	jalr	1424(ra) # 80001b70 <myproc>
    800055e8:	fec42783          	lw	a5,-20(s0)
    800055ec:	07e9                	addi	a5,a5,26
    800055ee:	078e                	slli	a5,a5,0x3
    800055f0:	97aa                	add	a5,a5,a0
    800055f2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055f6:	fe043503          	ld	a0,-32(s0)
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	2a2080e7          	jalr	674(ra) # 8000489c <fileclose>
  return 0;
    80005602:	4781                	li	a5,0
}
    80005604:	853e                	mv	a0,a5
    80005606:	60e2                	ld	ra,24(sp)
    80005608:	6442                	ld	s0,16(sp)
    8000560a:	6105                	addi	sp,sp,32
    8000560c:	8082                	ret

000000008000560e <sys_fstat>:
{
    8000560e:	1101                	addi	sp,sp,-32
    80005610:	ec06                	sd	ra,24(sp)
    80005612:	e822                	sd	s0,16(sp)
    80005614:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005616:	fe840613          	addi	a2,s0,-24
    8000561a:	4581                	li	a1,0
    8000561c:	4501                	li	a0,0
    8000561e:	00000097          	auipc	ra,0x0
    80005622:	c78080e7          	jalr	-904(ra) # 80005296 <argfd>
    return -1;
    80005626:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005628:	02054563          	bltz	a0,80005652 <sys_fstat+0x44>
    8000562c:	fe040593          	addi	a1,s0,-32
    80005630:	4505                	li	a0,1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	802080e7          	jalr	-2046(ra) # 80002e34 <argaddr>
    return -1;
    8000563a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000563c:	00054b63          	bltz	a0,80005652 <sys_fstat+0x44>
  return filestat(f, st);
    80005640:	fe043583          	ld	a1,-32(s0)
    80005644:	fe843503          	ld	a0,-24(s0)
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	31c080e7          	jalr	796(ra) # 80004964 <filestat>
    80005650:	87aa                	mv	a5,a0
}
    80005652:	853e                	mv	a0,a5
    80005654:	60e2                	ld	ra,24(sp)
    80005656:	6442                	ld	s0,16(sp)
    80005658:	6105                	addi	sp,sp,32
    8000565a:	8082                	ret

000000008000565c <sys_link>:
{
    8000565c:	7169                	addi	sp,sp,-304
    8000565e:	f606                	sd	ra,296(sp)
    80005660:	f222                	sd	s0,288(sp)
    80005662:	ee26                	sd	s1,280(sp)
    80005664:	ea4a                	sd	s2,272(sp)
    80005666:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005668:	08000613          	li	a2,128
    8000566c:	ed040593          	addi	a1,s0,-304
    80005670:	4501                	li	a0,0
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	7e4080e7          	jalr	2020(ra) # 80002e56 <argstr>
    return -1;
    8000567a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000567c:	10054e63          	bltz	a0,80005798 <sys_link+0x13c>
    80005680:	08000613          	li	a2,128
    80005684:	f5040593          	addi	a1,s0,-176
    80005688:	4505                	li	a0,1
    8000568a:	ffffd097          	auipc	ra,0xffffd
    8000568e:	7cc080e7          	jalr	1996(ra) # 80002e56 <argstr>
    return -1;
    80005692:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005694:	10054263          	bltz	a0,80005798 <sys_link+0x13c>
  begin_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	d38080e7          	jalr	-712(ra) # 800043d0 <begin_op>
  if((ip = namei(old)) == 0){
    800056a0:	ed040513          	addi	a0,s0,-304
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	b10080e7          	jalr	-1264(ra) # 800041b4 <namei>
    800056ac:	84aa                	mv	s1,a0
    800056ae:	c551                	beqz	a0,8000573a <sys_link+0xde>
  ilock(ip);
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	34e080e7          	jalr	846(ra) # 800039fe <ilock>
  if(ip->type == T_DIR){
    800056b8:	04449703          	lh	a4,68(s1)
    800056bc:	4785                	li	a5,1
    800056be:	08f70463          	beq	a4,a5,80005746 <sys_link+0xea>
  ip->nlink++;
    800056c2:	04a4d783          	lhu	a5,74(s1)
    800056c6:	2785                	addiw	a5,a5,1
    800056c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	266080e7          	jalr	614(ra) # 80003934 <iupdate>
  iunlock(ip);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	3e8080e7          	jalr	1000(ra) # 80003ac0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056e0:	fd040593          	addi	a1,s0,-48
    800056e4:	f5040513          	addi	a0,s0,-176
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	aea080e7          	jalr	-1302(ra) # 800041d2 <nameiparent>
    800056f0:	892a                	mv	s2,a0
    800056f2:	c935                	beqz	a0,80005766 <sys_link+0x10a>
  ilock(dp);
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	30a080e7          	jalr	778(ra) # 800039fe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056fc:	00092703          	lw	a4,0(s2)
    80005700:	409c                	lw	a5,0(s1)
    80005702:	04f71d63          	bne	a4,a5,8000575c <sys_link+0x100>
    80005706:	40d0                	lw	a2,4(s1)
    80005708:	fd040593          	addi	a1,s0,-48
    8000570c:	854a                	mv	a0,s2
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	9e4080e7          	jalr	-1564(ra) # 800040f2 <dirlink>
    80005716:	04054363          	bltz	a0,8000575c <sys_link+0x100>
  iunlockput(dp);
    8000571a:	854a                	mv	a0,s2
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	544080e7          	jalr	1348(ra) # 80003c60 <iunlockput>
  iput(ip);
    80005724:	8526                	mv	a0,s1
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	492080e7          	jalr	1170(ra) # 80003bb8 <iput>
  end_op();
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	d22080e7          	jalr	-734(ra) # 80004450 <end_op>
  return 0;
    80005736:	4781                	li	a5,0
    80005738:	a085                	j	80005798 <sys_link+0x13c>
    end_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	d16080e7          	jalr	-746(ra) # 80004450 <end_op>
    return -1;
    80005742:	57fd                	li	a5,-1
    80005744:	a891                	j	80005798 <sys_link+0x13c>
    iunlockput(ip);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	518080e7          	jalr	1304(ra) # 80003c60 <iunlockput>
    end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	d00080e7          	jalr	-768(ra) # 80004450 <end_op>
    return -1;
    80005758:	57fd                	li	a5,-1
    8000575a:	a83d                	j	80005798 <sys_link+0x13c>
    iunlockput(dp);
    8000575c:	854a                	mv	a0,s2
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	502080e7          	jalr	1282(ra) # 80003c60 <iunlockput>
  ilock(ip);
    80005766:	8526                	mv	a0,s1
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	296080e7          	jalr	662(ra) # 800039fe <ilock>
  ip->nlink--;
    80005770:	04a4d783          	lhu	a5,74(s1)
    80005774:	37fd                	addiw	a5,a5,-1
    80005776:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000577a:	8526                	mv	a0,s1
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	1b8080e7          	jalr	440(ra) # 80003934 <iupdate>
  iunlockput(ip);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	4da080e7          	jalr	1242(ra) # 80003c60 <iunlockput>
  end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	cc2080e7          	jalr	-830(ra) # 80004450 <end_op>
  return -1;
    80005796:	57fd                	li	a5,-1
}
    80005798:	853e                	mv	a0,a5
    8000579a:	70b2                	ld	ra,296(sp)
    8000579c:	7412                	ld	s0,288(sp)
    8000579e:	64f2                	ld	s1,280(sp)
    800057a0:	6952                	ld	s2,272(sp)
    800057a2:	6155                	addi	sp,sp,304
    800057a4:	8082                	ret

00000000800057a6 <sys_unlink>:
{
    800057a6:	7151                	addi	sp,sp,-240
    800057a8:	f586                	sd	ra,232(sp)
    800057aa:	f1a2                	sd	s0,224(sp)
    800057ac:	eda6                	sd	s1,216(sp)
    800057ae:	e9ca                	sd	s2,208(sp)
    800057b0:	e5ce                	sd	s3,200(sp)
    800057b2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057b4:	08000613          	li	a2,128
    800057b8:	f3040593          	addi	a1,s0,-208
    800057bc:	4501                	li	a0,0
    800057be:	ffffd097          	auipc	ra,0xffffd
    800057c2:	698080e7          	jalr	1688(ra) # 80002e56 <argstr>
    800057c6:	18054163          	bltz	a0,80005948 <sys_unlink+0x1a2>
  begin_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	c06080e7          	jalr	-1018(ra) # 800043d0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057d2:	fb040593          	addi	a1,s0,-80
    800057d6:	f3040513          	addi	a0,s0,-208
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	9f8080e7          	jalr	-1544(ra) # 800041d2 <nameiparent>
    800057e2:	84aa                	mv	s1,a0
    800057e4:	c979                	beqz	a0,800058ba <sys_unlink+0x114>
  ilock(dp);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	218080e7          	jalr	536(ra) # 800039fe <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057ee:	00003597          	auipc	a1,0x3
    800057f2:	fda58593          	addi	a1,a1,-38 # 800087c8 <syscalls+0x2b8>
    800057f6:	fb040513          	addi	a0,s0,-80
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	6ce080e7          	jalr	1742(ra) # 80003ec8 <namecmp>
    80005802:	14050a63          	beqz	a0,80005956 <sys_unlink+0x1b0>
    80005806:	00003597          	auipc	a1,0x3
    8000580a:	fca58593          	addi	a1,a1,-54 # 800087d0 <syscalls+0x2c0>
    8000580e:	fb040513          	addi	a0,s0,-80
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	6b6080e7          	jalr	1718(ra) # 80003ec8 <namecmp>
    8000581a:	12050e63          	beqz	a0,80005956 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000581e:	f2c40613          	addi	a2,s0,-212
    80005822:	fb040593          	addi	a1,s0,-80
    80005826:	8526                	mv	a0,s1
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	6ba080e7          	jalr	1722(ra) # 80003ee2 <dirlookup>
    80005830:	892a                	mv	s2,a0
    80005832:	12050263          	beqz	a0,80005956 <sys_unlink+0x1b0>
  ilock(ip);
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	1c8080e7          	jalr	456(ra) # 800039fe <ilock>
  if(ip->nlink < 1)
    8000583e:	04a91783          	lh	a5,74(s2)
    80005842:	08f05263          	blez	a5,800058c6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005846:	04491703          	lh	a4,68(s2)
    8000584a:	4785                	li	a5,1
    8000584c:	08f70563          	beq	a4,a5,800058d6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005850:	4641                	li	a2,16
    80005852:	4581                	li	a1,0
    80005854:	fc040513          	addi	a0,s0,-64
    80005858:	ffffb097          	auipc	ra,0xffffb
    8000585c:	466080e7          	jalr	1126(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005860:	4741                	li	a4,16
    80005862:	f2c42683          	lw	a3,-212(s0)
    80005866:	fc040613          	addi	a2,s0,-64
    8000586a:	4581                	li	a1,0
    8000586c:	8526                	mv	a0,s1
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	53c080e7          	jalr	1340(ra) # 80003daa <writei>
    80005876:	47c1                	li	a5,16
    80005878:	0af51563          	bne	a0,a5,80005922 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000587c:	04491703          	lh	a4,68(s2)
    80005880:	4785                	li	a5,1
    80005882:	0af70863          	beq	a4,a5,80005932 <sys_unlink+0x18c>
  iunlockput(dp);
    80005886:	8526                	mv	a0,s1
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	3d8080e7          	jalr	984(ra) # 80003c60 <iunlockput>
  ip->nlink--;
    80005890:	04a95783          	lhu	a5,74(s2)
    80005894:	37fd                	addiw	a5,a5,-1
    80005896:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000589a:	854a                	mv	a0,s2
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	098080e7          	jalr	152(ra) # 80003934 <iupdate>
  iunlockput(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	3ba080e7          	jalr	954(ra) # 80003c60 <iunlockput>
  end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	ba2080e7          	jalr	-1118(ra) # 80004450 <end_op>
  return 0;
    800058b6:	4501                	li	a0,0
    800058b8:	a84d                	j	8000596a <sys_unlink+0x1c4>
    end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	b96080e7          	jalr	-1130(ra) # 80004450 <end_op>
    return -1;
    800058c2:	557d                	li	a0,-1
    800058c4:	a05d                	j	8000596a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058c6:	00003517          	auipc	a0,0x3
    800058ca:	f3250513          	addi	a0,a0,-206 # 800087f8 <syscalls+0x2e8>
    800058ce:	ffffb097          	auipc	ra,0xffffb
    800058d2:	c5c080e7          	jalr	-932(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058d6:	04c92703          	lw	a4,76(s2)
    800058da:	02000793          	li	a5,32
    800058de:	f6e7f9e3          	bgeu	a5,a4,80005850 <sys_unlink+0xaa>
    800058e2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058e6:	4741                	li	a4,16
    800058e8:	86ce                	mv	a3,s3
    800058ea:	f1840613          	addi	a2,s0,-232
    800058ee:	4581                	li	a1,0
    800058f0:	854a                	mv	a0,s2
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	3c0080e7          	jalr	960(ra) # 80003cb2 <readi>
    800058fa:	47c1                	li	a5,16
    800058fc:	00f51b63          	bne	a0,a5,80005912 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005900:	f1845783          	lhu	a5,-232(s0)
    80005904:	e7a1                	bnez	a5,8000594c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005906:	29c1                	addiw	s3,s3,16
    80005908:	04c92783          	lw	a5,76(s2)
    8000590c:	fcf9ede3          	bltu	s3,a5,800058e6 <sys_unlink+0x140>
    80005910:	b781                	j	80005850 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005912:	00003517          	auipc	a0,0x3
    80005916:	efe50513          	addi	a0,a0,-258 # 80008810 <syscalls+0x300>
    8000591a:	ffffb097          	auipc	ra,0xffffb
    8000591e:	c10080e7          	jalr	-1008(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005922:	00003517          	auipc	a0,0x3
    80005926:	f0650513          	addi	a0,a0,-250 # 80008828 <syscalls+0x318>
    8000592a:	ffffb097          	auipc	ra,0xffffb
    8000592e:	c00080e7          	jalr	-1024(ra) # 8000052a <panic>
    dp->nlink--;
    80005932:	04a4d783          	lhu	a5,74(s1)
    80005936:	37fd                	addiw	a5,a5,-1
    80005938:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000593c:	8526                	mv	a0,s1
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	ff6080e7          	jalr	-10(ra) # 80003934 <iupdate>
    80005946:	b781                	j	80005886 <sys_unlink+0xe0>
    return -1;
    80005948:	557d                	li	a0,-1
    8000594a:	a005                	j	8000596a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000594c:	854a                	mv	a0,s2
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	312080e7          	jalr	786(ra) # 80003c60 <iunlockput>
  iunlockput(dp);
    80005956:	8526                	mv	a0,s1
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	308080e7          	jalr	776(ra) # 80003c60 <iunlockput>
  end_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	af0080e7          	jalr	-1296(ra) # 80004450 <end_op>
  return -1;
    80005968:	557d                	li	a0,-1
}
    8000596a:	70ae                	ld	ra,232(sp)
    8000596c:	740e                	ld	s0,224(sp)
    8000596e:	64ee                	ld	s1,216(sp)
    80005970:	694e                	ld	s2,208(sp)
    80005972:	69ae                	ld	s3,200(sp)
    80005974:	616d                	addi	sp,sp,240
    80005976:	8082                	ret

0000000080005978 <sys_open>:

uint64
sys_open(void)
{
    80005978:	7131                	addi	sp,sp,-192
    8000597a:	fd06                	sd	ra,184(sp)
    8000597c:	f922                	sd	s0,176(sp)
    8000597e:	f526                	sd	s1,168(sp)
    80005980:	f14a                	sd	s2,160(sp)
    80005982:	ed4e                	sd	s3,152(sp)
    80005984:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005986:	08000613          	li	a2,128
    8000598a:	f5040593          	addi	a1,s0,-176
    8000598e:	4501                	li	a0,0
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	4c6080e7          	jalr	1222(ra) # 80002e56 <argstr>
    return -1;
    80005998:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000599a:	0c054163          	bltz	a0,80005a5c <sys_open+0xe4>
    8000599e:	f4c40593          	addi	a1,s0,-180
    800059a2:	4505                	li	a0,1
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	46e080e7          	jalr	1134(ra) # 80002e12 <argint>
    800059ac:	0a054863          	bltz	a0,80005a5c <sys_open+0xe4>

  begin_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	a20080e7          	jalr	-1504(ra) # 800043d0 <begin_op>

  if(omode & O_CREATE){
    800059b8:	f4c42783          	lw	a5,-180(s0)
    800059bc:	2007f793          	andi	a5,a5,512
    800059c0:	cbdd                	beqz	a5,80005a76 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059c2:	4681                	li	a3,0
    800059c4:	4601                	li	a2,0
    800059c6:	4589                	li	a1,2
    800059c8:	f5040513          	addi	a0,s0,-176
    800059cc:	00000097          	auipc	ra,0x0
    800059d0:	974080e7          	jalr	-1676(ra) # 80005340 <create>
    800059d4:	892a                	mv	s2,a0
    if(ip == 0){
    800059d6:	c959                	beqz	a0,80005a6c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059d8:	04491703          	lh	a4,68(s2)
    800059dc:	478d                	li	a5,3
    800059de:	00f71763          	bne	a4,a5,800059ec <sys_open+0x74>
    800059e2:	04695703          	lhu	a4,70(s2)
    800059e6:	47a5                	li	a5,9
    800059e8:	0ce7ec63          	bltu	a5,a4,80005ac0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	df4080e7          	jalr	-524(ra) # 800047e0 <filealloc>
    800059f4:	89aa                	mv	s3,a0
    800059f6:	10050263          	beqz	a0,80005afa <sys_open+0x182>
    800059fa:	00000097          	auipc	ra,0x0
    800059fe:	904080e7          	jalr	-1788(ra) # 800052fe <fdalloc>
    80005a02:	84aa                	mv	s1,a0
    80005a04:	0e054663          	bltz	a0,80005af0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a08:	04491703          	lh	a4,68(s2)
    80005a0c:	478d                	li	a5,3
    80005a0e:	0cf70463          	beq	a4,a5,80005ad6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a12:	4789                	li	a5,2
    80005a14:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a18:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a1c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a20:	f4c42783          	lw	a5,-180(s0)
    80005a24:	0017c713          	xori	a4,a5,1
    80005a28:	8b05                	andi	a4,a4,1
    80005a2a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a2e:	0037f713          	andi	a4,a5,3
    80005a32:	00e03733          	snez	a4,a4
    80005a36:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a3a:	4007f793          	andi	a5,a5,1024
    80005a3e:	c791                	beqz	a5,80005a4a <sys_open+0xd2>
    80005a40:	04491703          	lh	a4,68(s2)
    80005a44:	4789                	li	a5,2
    80005a46:	08f70f63          	beq	a4,a5,80005ae4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	074080e7          	jalr	116(ra) # 80003ac0 <iunlock>
  end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	9fc080e7          	jalr	-1540(ra) # 80004450 <end_op>

  return fd;
}
    80005a5c:	8526                	mv	a0,s1
    80005a5e:	70ea                	ld	ra,184(sp)
    80005a60:	744a                	ld	s0,176(sp)
    80005a62:	74aa                	ld	s1,168(sp)
    80005a64:	790a                	ld	s2,160(sp)
    80005a66:	69ea                	ld	s3,152(sp)
    80005a68:	6129                	addi	sp,sp,192
    80005a6a:	8082                	ret
      end_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	9e4080e7          	jalr	-1564(ra) # 80004450 <end_op>
      return -1;
    80005a74:	b7e5                	j	80005a5c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a76:	f5040513          	addi	a0,s0,-176
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	73a080e7          	jalr	1850(ra) # 800041b4 <namei>
    80005a82:	892a                	mv	s2,a0
    80005a84:	c905                	beqz	a0,80005ab4 <sys_open+0x13c>
    ilock(ip);
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	f78080e7          	jalr	-136(ra) # 800039fe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a8e:	04491703          	lh	a4,68(s2)
    80005a92:	4785                	li	a5,1
    80005a94:	f4f712e3          	bne	a4,a5,800059d8 <sys_open+0x60>
    80005a98:	f4c42783          	lw	a5,-180(s0)
    80005a9c:	dba1                	beqz	a5,800059ec <sys_open+0x74>
      iunlockput(ip);
    80005a9e:	854a                	mv	a0,s2
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	1c0080e7          	jalr	448(ra) # 80003c60 <iunlockput>
      end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	9a8080e7          	jalr	-1624(ra) # 80004450 <end_op>
      return -1;
    80005ab0:	54fd                	li	s1,-1
    80005ab2:	b76d                	j	80005a5c <sys_open+0xe4>
      end_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	99c080e7          	jalr	-1636(ra) # 80004450 <end_op>
      return -1;
    80005abc:	54fd                	li	s1,-1
    80005abe:	bf79                	j	80005a5c <sys_open+0xe4>
    iunlockput(ip);
    80005ac0:	854a                	mv	a0,s2
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	19e080e7          	jalr	414(ra) # 80003c60 <iunlockput>
    end_op();
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	986080e7          	jalr	-1658(ra) # 80004450 <end_op>
    return -1;
    80005ad2:	54fd                	li	s1,-1
    80005ad4:	b761                	j	80005a5c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ad6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ada:	04691783          	lh	a5,70(s2)
    80005ade:	02f99223          	sh	a5,36(s3)
    80005ae2:	bf2d                	j	80005a1c <sys_open+0xa4>
    itrunc(ip);
    80005ae4:	854a                	mv	a0,s2
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	026080e7          	jalr	38(ra) # 80003b0c <itrunc>
    80005aee:	bfb1                	j	80005a4a <sys_open+0xd2>
      fileclose(f);
    80005af0:	854e                	mv	a0,s3
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	daa080e7          	jalr	-598(ra) # 8000489c <fileclose>
    iunlockput(ip);
    80005afa:	854a                	mv	a0,s2
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	164080e7          	jalr	356(ra) # 80003c60 <iunlockput>
    end_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	94c080e7          	jalr	-1716(ra) # 80004450 <end_op>
    return -1;
    80005b0c:	54fd                	li	s1,-1
    80005b0e:	b7b9                	j	80005a5c <sys_open+0xe4>

0000000080005b10 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b10:	7175                	addi	sp,sp,-144
    80005b12:	e506                	sd	ra,136(sp)
    80005b14:	e122                	sd	s0,128(sp)
    80005b16:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	8b8080e7          	jalr	-1864(ra) # 800043d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b20:	08000613          	li	a2,128
    80005b24:	f7040593          	addi	a1,s0,-144
    80005b28:	4501                	li	a0,0
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	32c080e7          	jalr	812(ra) # 80002e56 <argstr>
    80005b32:	02054963          	bltz	a0,80005b64 <sys_mkdir+0x54>
    80005b36:	4681                	li	a3,0
    80005b38:	4601                	li	a2,0
    80005b3a:	4585                	li	a1,1
    80005b3c:	f7040513          	addi	a0,s0,-144
    80005b40:	00000097          	auipc	ra,0x0
    80005b44:	800080e7          	jalr	-2048(ra) # 80005340 <create>
    80005b48:	cd11                	beqz	a0,80005b64 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	116080e7          	jalr	278(ra) # 80003c60 <iunlockput>
  end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	8fe080e7          	jalr	-1794(ra) # 80004450 <end_op>
  return 0;
    80005b5a:	4501                	li	a0,0
}
    80005b5c:	60aa                	ld	ra,136(sp)
    80005b5e:	640a                	ld	s0,128(sp)
    80005b60:	6149                	addi	sp,sp,144
    80005b62:	8082                	ret
    end_op();
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	8ec080e7          	jalr	-1812(ra) # 80004450 <end_op>
    return -1;
    80005b6c:	557d                	li	a0,-1
    80005b6e:	b7fd                	j	80005b5c <sys_mkdir+0x4c>

0000000080005b70 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b70:	7135                	addi	sp,sp,-160
    80005b72:	ed06                	sd	ra,152(sp)
    80005b74:	e922                	sd	s0,144(sp)
    80005b76:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	858080e7          	jalr	-1960(ra) # 800043d0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b80:	08000613          	li	a2,128
    80005b84:	f7040593          	addi	a1,s0,-144
    80005b88:	4501                	li	a0,0
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	2cc080e7          	jalr	716(ra) # 80002e56 <argstr>
    80005b92:	04054a63          	bltz	a0,80005be6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b96:	f6c40593          	addi	a1,s0,-148
    80005b9a:	4505                	li	a0,1
    80005b9c:	ffffd097          	auipc	ra,0xffffd
    80005ba0:	276080e7          	jalr	630(ra) # 80002e12 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ba4:	04054163          	bltz	a0,80005be6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ba8:	f6840593          	addi	a1,s0,-152
    80005bac:	4509                	li	a0,2
    80005bae:	ffffd097          	auipc	ra,0xffffd
    80005bb2:	264080e7          	jalr	612(ra) # 80002e12 <argint>
     argint(1, &major) < 0 ||
    80005bb6:	02054863          	bltz	a0,80005be6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bba:	f6841683          	lh	a3,-152(s0)
    80005bbe:	f6c41603          	lh	a2,-148(s0)
    80005bc2:	458d                	li	a1,3
    80005bc4:	f7040513          	addi	a0,s0,-144
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	778080e7          	jalr	1912(ra) # 80005340 <create>
     argint(2, &minor) < 0 ||
    80005bd0:	c919                	beqz	a0,80005be6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	08e080e7          	jalr	142(ra) # 80003c60 <iunlockput>
  end_op();
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	876080e7          	jalr	-1930(ra) # 80004450 <end_op>
  return 0;
    80005be2:	4501                	li	a0,0
    80005be4:	a031                	j	80005bf0 <sys_mknod+0x80>
    end_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	86a080e7          	jalr	-1942(ra) # 80004450 <end_op>
    return -1;
    80005bee:	557d                	li	a0,-1
}
    80005bf0:	60ea                	ld	ra,152(sp)
    80005bf2:	644a                	ld	s0,144(sp)
    80005bf4:	610d                	addi	sp,sp,160
    80005bf6:	8082                	ret

0000000080005bf8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bf8:	7135                	addi	sp,sp,-160
    80005bfa:	ed06                	sd	ra,152(sp)
    80005bfc:	e922                	sd	s0,144(sp)
    80005bfe:	e526                	sd	s1,136(sp)
    80005c00:	e14a                	sd	s2,128(sp)
    80005c02:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c04:	ffffc097          	auipc	ra,0xffffc
    80005c08:	f6c080e7          	jalr	-148(ra) # 80001b70 <myproc>
    80005c0c:	892a                	mv	s2,a0
  
  begin_op();
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	7c2080e7          	jalr	1986(ra) # 800043d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c16:	08000613          	li	a2,128
    80005c1a:	f6040593          	addi	a1,s0,-160
    80005c1e:	4501                	li	a0,0
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	236080e7          	jalr	566(ra) # 80002e56 <argstr>
    80005c28:	04054b63          	bltz	a0,80005c7e <sys_chdir+0x86>
    80005c2c:	f6040513          	addi	a0,s0,-160
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	584080e7          	jalr	1412(ra) # 800041b4 <namei>
    80005c38:	84aa                	mv	s1,a0
    80005c3a:	c131                	beqz	a0,80005c7e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	dc2080e7          	jalr	-574(ra) # 800039fe <ilock>
  if(ip->type != T_DIR){
    80005c44:	04449703          	lh	a4,68(s1)
    80005c48:	4785                	li	a5,1
    80005c4a:	04f71063          	bne	a4,a5,80005c8a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c4e:	8526                	mv	a0,s1
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	e70080e7          	jalr	-400(ra) # 80003ac0 <iunlock>
  iput(p->cwd);
    80005c58:	15093503          	ld	a0,336(s2)
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	f5c080e7          	jalr	-164(ra) # 80003bb8 <iput>
  end_op();
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	7ec080e7          	jalr	2028(ra) # 80004450 <end_op>
  p->cwd = ip;
    80005c6c:	14993823          	sd	s1,336(s2)
  return 0;
    80005c70:	4501                	li	a0,0
}
    80005c72:	60ea                	ld	ra,152(sp)
    80005c74:	644a                	ld	s0,144(sp)
    80005c76:	64aa                	ld	s1,136(sp)
    80005c78:	690a                	ld	s2,128(sp)
    80005c7a:	610d                	addi	sp,sp,160
    80005c7c:	8082                	ret
    end_op();
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	7d2080e7          	jalr	2002(ra) # 80004450 <end_op>
    return -1;
    80005c86:	557d                	li	a0,-1
    80005c88:	b7ed                	j	80005c72 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	fd4080e7          	jalr	-44(ra) # 80003c60 <iunlockput>
    end_op();
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	7bc080e7          	jalr	1980(ra) # 80004450 <end_op>
    return -1;
    80005c9c:	557d                	li	a0,-1
    80005c9e:	bfd1                	j	80005c72 <sys_chdir+0x7a>

0000000080005ca0 <sys_exec>:

uint64
sys_exec(void)
{
    80005ca0:	7145                	addi	sp,sp,-464
    80005ca2:	e786                	sd	ra,456(sp)
    80005ca4:	e3a2                	sd	s0,448(sp)
    80005ca6:	ff26                	sd	s1,440(sp)
    80005ca8:	fb4a                	sd	s2,432(sp)
    80005caa:	f74e                	sd	s3,424(sp)
    80005cac:	f352                	sd	s4,416(sp)
    80005cae:	ef56                	sd	s5,408(sp)
    80005cb0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cb2:	08000613          	li	a2,128
    80005cb6:	f4040593          	addi	a1,s0,-192
    80005cba:	4501                	li	a0,0
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	19a080e7          	jalr	410(ra) # 80002e56 <argstr>
    return -1;
    80005cc4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cc6:	0c054a63          	bltz	a0,80005d9a <sys_exec+0xfa>
    80005cca:	e3840593          	addi	a1,s0,-456
    80005cce:	4505                	li	a0,1
    80005cd0:	ffffd097          	auipc	ra,0xffffd
    80005cd4:	164080e7          	jalr	356(ra) # 80002e34 <argaddr>
    80005cd8:	0c054163          	bltz	a0,80005d9a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cdc:	10000613          	li	a2,256
    80005ce0:	4581                	li	a1,0
    80005ce2:	e4040513          	addi	a0,s0,-448
    80005ce6:	ffffb097          	auipc	ra,0xffffb
    80005cea:	fd8080e7          	jalr	-40(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cee:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cf2:	89a6                	mv	s3,s1
    80005cf4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cf6:	02000a13          	li	s4,32
    80005cfa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cfe:	00391793          	slli	a5,s2,0x3
    80005d02:	e3040593          	addi	a1,s0,-464
    80005d06:	e3843503          	ld	a0,-456(s0)
    80005d0a:	953e                	add	a0,a0,a5
    80005d0c:	ffffd097          	auipc	ra,0xffffd
    80005d10:	06c080e7          	jalr	108(ra) # 80002d78 <fetchaddr>
    80005d14:	02054a63          	bltz	a0,80005d48 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d18:	e3043783          	ld	a5,-464(s0)
    80005d1c:	c3b9                	beqz	a5,80005d62 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d1e:	ffffb097          	auipc	ra,0xffffb
    80005d22:	db4080e7          	jalr	-588(ra) # 80000ad2 <kalloc>
    80005d26:	85aa                	mv	a1,a0
    80005d28:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d2c:	cd11                	beqz	a0,80005d48 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d2e:	6605                	lui	a2,0x1
    80005d30:	e3043503          	ld	a0,-464(s0)
    80005d34:	ffffd097          	auipc	ra,0xffffd
    80005d38:	096080e7          	jalr	150(ra) # 80002dca <fetchstr>
    80005d3c:	00054663          	bltz	a0,80005d48 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d40:	0905                	addi	s2,s2,1
    80005d42:	09a1                	addi	s3,s3,8
    80005d44:	fb491be3          	bne	s2,s4,80005cfa <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d48:	10048913          	addi	s2,s1,256
    80005d4c:	6088                	ld	a0,0(s1)
    80005d4e:	c529                	beqz	a0,80005d98 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d50:	ffffb097          	auipc	ra,0xffffb
    80005d54:	c86080e7          	jalr	-890(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d58:	04a1                	addi	s1,s1,8
    80005d5a:	ff2499e3          	bne	s1,s2,80005d4c <sys_exec+0xac>
  return -1;
    80005d5e:	597d                	li	s2,-1
    80005d60:	a82d                	j	80005d9a <sys_exec+0xfa>
      argv[i] = 0;
    80005d62:	0a8e                	slli	s5,s5,0x3
    80005d64:	fc040793          	addi	a5,s0,-64
    80005d68:	9abe                	add	s5,s5,a5
    80005d6a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005d6e:	e4040593          	addi	a1,s0,-448
    80005d72:	f4040513          	addi	a0,s0,-192
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	178080e7          	jalr	376(ra) # 80004eee <exec>
    80005d7e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d80:	10048993          	addi	s3,s1,256
    80005d84:	6088                	ld	a0,0(s1)
    80005d86:	c911                	beqz	a0,80005d9a <sys_exec+0xfa>
    kfree(argv[i]);
    80005d88:	ffffb097          	auipc	ra,0xffffb
    80005d8c:	c4e080e7          	jalr	-946(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d90:	04a1                	addi	s1,s1,8
    80005d92:	ff3499e3          	bne	s1,s3,80005d84 <sys_exec+0xe4>
    80005d96:	a011                	j	80005d9a <sys_exec+0xfa>
  return -1;
    80005d98:	597d                	li	s2,-1
}
    80005d9a:	854a                	mv	a0,s2
    80005d9c:	60be                	ld	ra,456(sp)
    80005d9e:	641e                	ld	s0,448(sp)
    80005da0:	74fa                	ld	s1,440(sp)
    80005da2:	795a                	ld	s2,432(sp)
    80005da4:	79ba                	ld	s3,424(sp)
    80005da6:	7a1a                	ld	s4,416(sp)
    80005da8:	6afa                	ld	s5,408(sp)
    80005daa:	6179                	addi	sp,sp,464
    80005dac:	8082                	ret

0000000080005dae <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dae:	7139                	addi	sp,sp,-64
    80005db0:	fc06                	sd	ra,56(sp)
    80005db2:	f822                	sd	s0,48(sp)
    80005db4:	f426                	sd	s1,40(sp)
    80005db6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	db8080e7          	jalr	-584(ra) # 80001b70 <myproc>
    80005dc0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005dc2:	fd840593          	addi	a1,s0,-40
    80005dc6:	4501                	li	a0,0
    80005dc8:	ffffd097          	auipc	ra,0xffffd
    80005dcc:	06c080e7          	jalr	108(ra) # 80002e34 <argaddr>
    return -1;
    80005dd0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005dd2:	0e054063          	bltz	a0,80005eb2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005dd6:	fc840593          	addi	a1,s0,-56
    80005dda:	fd040513          	addi	a0,s0,-48
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	dee080e7          	jalr	-530(ra) # 80004bcc <pipealloc>
    return -1;
    80005de6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005de8:	0c054563          	bltz	a0,80005eb2 <sys_pipe+0x104>
  fd0 = -1;
    80005dec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005df0:	fd043503          	ld	a0,-48(s0)
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	50a080e7          	jalr	1290(ra) # 800052fe <fdalloc>
    80005dfc:	fca42223          	sw	a0,-60(s0)
    80005e00:	08054c63          	bltz	a0,80005e98 <sys_pipe+0xea>
    80005e04:	fc843503          	ld	a0,-56(s0)
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	4f6080e7          	jalr	1270(ra) # 800052fe <fdalloc>
    80005e10:	fca42023          	sw	a0,-64(s0)
    80005e14:	06054863          	bltz	a0,80005e84 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e18:	4691                	li	a3,4
    80005e1a:	fc440613          	addi	a2,s0,-60
    80005e1e:	fd843583          	ld	a1,-40(s0)
    80005e22:	68a8                	ld	a0,80(s1)
    80005e24:	ffffc097          	auipc	ra,0xffffc
    80005e28:	81a080e7          	jalr	-2022(ra) # 8000163e <copyout>
    80005e2c:	02054063          	bltz	a0,80005e4c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e30:	4691                	li	a3,4
    80005e32:	fc040613          	addi	a2,s0,-64
    80005e36:	fd843583          	ld	a1,-40(s0)
    80005e3a:	0591                	addi	a1,a1,4
    80005e3c:	68a8                	ld	a0,80(s1)
    80005e3e:	ffffc097          	auipc	ra,0xffffc
    80005e42:	800080e7          	jalr	-2048(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e46:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e48:	06055563          	bgez	a0,80005eb2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e4c:	fc442783          	lw	a5,-60(s0)
    80005e50:	07e9                	addi	a5,a5,26
    80005e52:	078e                	slli	a5,a5,0x3
    80005e54:	97a6                	add	a5,a5,s1
    80005e56:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e5a:	fc042503          	lw	a0,-64(s0)
    80005e5e:	0569                	addi	a0,a0,26
    80005e60:	050e                	slli	a0,a0,0x3
    80005e62:	9526                	add	a0,a0,s1
    80005e64:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e68:	fd043503          	ld	a0,-48(s0)
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	a30080e7          	jalr	-1488(ra) # 8000489c <fileclose>
    fileclose(wf);
    80005e74:	fc843503          	ld	a0,-56(s0)
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	a24080e7          	jalr	-1500(ra) # 8000489c <fileclose>
    return -1;
    80005e80:	57fd                	li	a5,-1
    80005e82:	a805                	j	80005eb2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e84:	fc442783          	lw	a5,-60(s0)
    80005e88:	0007c863          	bltz	a5,80005e98 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e8c:	01a78513          	addi	a0,a5,26
    80005e90:	050e                	slli	a0,a0,0x3
    80005e92:	9526                	add	a0,a0,s1
    80005e94:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e98:	fd043503          	ld	a0,-48(s0)
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	a00080e7          	jalr	-1536(ra) # 8000489c <fileclose>
    fileclose(wf);
    80005ea4:	fc843503          	ld	a0,-56(s0)
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	9f4080e7          	jalr	-1548(ra) # 8000489c <fileclose>
    return -1;
    80005eb0:	57fd                	li	a5,-1
}
    80005eb2:	853e                	mv	a0,a5
    80005eb4:	70e2                	ld	ra,56(sp)
    80005eb6:	7442                	ld	s0,48(sp)
    80005eb8:	74a2                	ld	s1,40(sp)
    80005eba:	6121                	addi	sp,sp,64
    80005ebc:	8082                	ret
	...

0000000080005ec0 <kernelvec>:
    80005ec0:	7111                	addi	sp,sp,-256
    80005ec2:	e006                	sd	ra,0(sp)
    80005ec4:	e40a                	sd	sp,8(sp)
    80005ec6:	e80e                	sd	gp,16(sp)
    80005ec8:	ec12                	sd	tp,24(sp)
    80005eca:	f016                	sd	t0,32(sp)
    80005ecc:	f41a                	sd	t1,40(sp)
    80005ece:	f81e                	sd	t2,48(sp)
    80005ed0:	fc22                	sd	s0,56(sp)
    80005ed2:	e0a6                	sd	s1,64(sp)
    80005ed4:	e4aa                	sd	a0,72(sp)
    80005ed6:	e8ae                	sd	a1,80(sp)
    80005ed8:	ecb2                	sd	a2,88(sp)
    80005eda:	f0b6                	sd	a3,96(sp)
    80005edc:	f4ba                	sd	a4,104(sp)
    80005ede:	f8be                	sd	a5,112(sp)
    80005ee0:	fcc2                	sd	a6,120(sp)
    80005ee2:	e146                	sd	a7,128(sp)
    80005ee4:	e54a                	sd	s2,136(sp)
    80005ee6:	e94e                	sd	s3,144(sp)
    80005ee8:	ed52                	sd	s4,152(sp)
    80005eea:	f156                	sd	s5,160(sp)
    80005eec:	f55a                	sd	s6,168(sp)
    80005eee:	f95e                	sd	s7,176(sp)
    80005ef0:	fd62                	sd	s8,184(sp)
    80005ef2:	e1e6                	sd	s9,192(sp)
    80005ef4:	e5ea                	sd	s10,200(sp)
    80005ef6:	e9ee                	sd	s11,208(sp)
    80005ef8:	edf2                	sd	t3,216(sp)
    80005efa:	f1f6                	sd	t4,224(sp)
    80005efc:	f5fa                	sd	t5,232(sp)
    80005efe:	f9fe                	sd	t6,240(sp)
    80005f00:	d45fc0ef          	jal	ra,80002c44 <kerneltrap>
    80005f04:	6082                	ld	ra,0(sp)
    80005f06:	6122                	ld	sp,8(sp)
    80005f08:	61c2                	ld	gp,16(sp)
    80005f0a:	7282                	ld	t0,32(sp)
    80005f0c:	7322                	ld	t1,40(sp)
    80005f0e:	73c2                	ld	t2,48(sp)
    80005f10:	7462                	ld	s0,56(sp)
    80005f12:	6486                	ld	s1,64(sp)
    80005f14:	6526                	ld	a0,72(sp)
    80005f16:	65c6                	ld	a1,80(sp)
    80005f18:	6666                	ld	a2,88(sp)
    80005f1a:	7686                	ld	a3,96(sp)
    80005f1c:	7726                	ld	a4,104(sp)
    80005f1e:	77c6                	ld	a5,112(sp)
    80005f20:	7866                	ld	a6,120(sp)
    80005f22:	688a                	ld	a7,128(sp)
    80005f24:	692a                	ld	s2,136(sp)
    80005f26:	69ca                	ld	s3,144(sp)
    80005f28:	6a6a                	ld	s4,152(sp)
    80005f2a:	7a8a                	ld	s5,160(sp)
    80005f2c:	7b2a                	ld	s6,168(sp)
    80005f2e:	7bca                	ld	s7,176(sp)
    80005f30:	7c6a                	ld	s8,184(sp)
    80005f32:	6c8e                	ld	s9,192(sp)
    80005f34:	6d2e                	ld	s10,200(sp)
    80005f36:	6dce                	ld	s11,208(sp)
    80005f38:	6e6e                	ld	t3,216(sp)
    80005f3a:	7e8e                	ld	t4,224(sp)
    80005f3c:	7f2e                	ld	t5,232(sp)
    80005f3e:	7fce                	ld	t6,240(sp)
    80005f40:	6111                	addi	sp,sp,256
    80005f42:	10200073          	sret
    80005f46:	00000013          	nop
    80005f4a:	00000013          	nop
    80005f4e:	0001                	nop

0000000080005f50 <timervec>:
    80005f50:	34051573          	csrrw	a0,mscratch,a0
    80005f54:	e10c                	sd	a1,0(a0)
    80005f56:	e510                	sd	a2,8(a0)
    80005f58:	e914                	sd	a3,16(a0)
    80005f5a:	6d0c                	ld	a1,24(a0)
    80005f5c:	7110                	ld	a2,32(a0)
    80005f5e:	6194                	ld	a3,0(a1)
    80005f60:	96b2                	add	a3,a3,a2
    80005f62:	e194                	sd	a3,0(a1)
    80005f64:	4589                	li	a1,2
    80005f66:	14459073          	csrw	sip,a1
    80005f6a:	6914                	ld	a3,16(a0)
    80005f6c:	6510                	ld	a2,8(a0)
    80005f6e:	610c                	ld	a1,0(a0)
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	30200073          	mret
	...

0000000080005f7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f7a:	1141                	addi	sp,sp,-16
    80005f7c:	e422                	sd	s0,8(sp)
    80005f7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f80:	0c0007b7          	lui	a5,0xc000
    80005f84:	4705                	li	a4,1
    80005f86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f88:	c3d8                	sw	a4,4(a5)
}
    80005f8a:	6422                	ld	s0,8(sp)
    80005f8c:	0141                	addi	sp,sp,16
    80005f8e:	8082                	ret

0000000080005f90 <plicinithart>:

void
plicinithart(void)
{
    80005f90:	1141                	addi	sp,sp,-16
    80005f92:	e406                	sd	ra,8(sp)
    80005f94:	e022                	sd	s0,0(sp)
    80005f96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	bac080e7          	jalr	-1108(ra) # 80001b44 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fa0:	0085171b          	slliw	a4,a0,0x8
    80005fa4:	0c0027b7          	lui	a5,0xc002
    80005fa8:	97ba                	add	a5,a5,a4
    80005faa:	40200713          	li	a4,1026
    80005fae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fb2:	00d5151b          	slliw	a0,a0,0xd
    80005fb6:	0c2017b7          	lui	a5,0xc201
    80005fba:	953e                	add	a0,a0,a5
    80005fbc:	00052023          	sw	zero,0(a0)
}
    80005fc0:	60a2                	ld	ra,8(sp)
    80005fc2:	6402                	ld	s0,0(sp)
    80005fc4:	0141                	addi	sp,sp,16
    80005fc6:	8082                	ret

0000000080005fc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fc8:	1141                	addi	sp,sp,-16
    80005fca:	e406                	sd	ra,8(sp)
    80005fcc:	e022                	sd	s0,0(sp)
    80005fce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd0:	ffffc097          	auipc	ra,0xffffc
    80005fd4:	b74080e7          	jalr	-1164(ra) # 80001b44 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fd8:	00d5179b          	slliw	a5,a0,0xd
    80005fdc:	0c201537          	lui	a0,0xc201
    80005fe0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fe2:	4148                	lw	a0,4(a0)
    80005fe4:	60a2                	ld	ra,8(sp)
    80005fe6:	6402                	ld	s0,0(sp)
    80005fe8:	0141                	addi	sp,sp,16
    80005fea:	8082                	ret

0000000080005fec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fec:	1101                	addi	sp,sp,-32
    80005fee:	ec06                	sd	ra,24(sp)
    80005ff0:	e822                	sd	s0,16(sp)
    80005ff2:	e426                	sd	s1,8(sp)
    80005ff4:	1000                	addi	s0,sp,32
    80005ff6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ff8:	ffffc097          	auipc	ra,0xffffc
    80005ffc:	b4c080e7          	jalr	-1204(ra) # 80001b44 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006000:	00d5151b          	slliw	a0,a0,0xd
    80006004:	0c2017b7          	lui	a5,0xc201
    80006008:	97aa                	add	a5,a5,a0
    8000600a:	c3c4                	sw	s1,4(a5)
}
    8000600c:	60e2                	ld	ra,24(sp)
    8000600e:	6442                	ld	s0,16(sp)
    80006010:	64a2                	ld	s1,8(sp)
    80006012:	6105                	addi	sp,sp,32
    80006014:	8082                	ret

0000000080006016 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006016:	1141                	addi	sp,sp,-16
    80006018:	e406                	sd	ra,8(sp)
    8000601a:	e022                	sd	s0,0(sp)
    8000601c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000601e:	479d                	li	a5,7
    80006020:	06a7c963          	blt	a5,a0,80006092 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006024:	0001d797          	auipc	a5,0x1d
    80006028:	fdc78793          	addi	a5,a5,-36 # 80023000 <disk>
    8000602c:	00a78733          	add	a4,a5,a0
    80006030:	6789                	lui	a5,0x2
    80006032:	97ba                	add	a5,a5,a4
    80006034:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006038:	e7ad                	bnez	a5,800060a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000603a:	00451793          	slli	a5,a0,0x4
    8000603e:	0001f717          	auipc	a4,0x1f
    80006042:	fc270713          	addi	a4,a4,-62 # 80025000 <disk+0x2000>
    80006046:	6314                	ld	a3,0(a4)
    80006048:	96be                	add	a3,a3,a5
    8000604a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000604e:	6314                	ld	a3,0(a4)
    80006050:	96be                	add	a3,a3,a5
    80006052:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006056:	6314                	ld	a3,0(a4)
    80006058:	96be                	add	a3,a3,a5
    8000605a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000605e:	6318                	ld	a4,0(a4)
    80006060:	97ba                	add	a5,a5,a4
    80006062:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006066:	0001d797          	auipc	a5,0x1d
    8000606a:	f9a78793          	addi	a5,a5,-102 # 80023000 <disk>
    8000606e:	97aa                	add	a5,a5,a0
    80006070:	6509                	lui	a0,0x2
    80006072:	953e                	add	a0,a0,a5
    80006074:	4785                	li	a5,1
    80006076:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000607a:	0001f517          	auipc	a0,0x1f
    8000607e:	f9e50513          	addi	a0,a0,-98 # 80025018 <disk+0x2018>
    80006082:	ffffc097          	auipc	ra,0xffffc
    80006086:	4d0080e7          	jalr	1232(ra) # 80002552 <wakeup>
}
    8000608a:	60a2                	ld	ra,8(sp)
    8000608c:	6402                	ld	s0,0(sp)
    8000608e:	0141                	addi	sp,sp,16
    80006090:	8082                	ret
    panic("free_desc 1");
    80006092:	00002517          	auipc	a0,0x2
    80006096:	7a650513          	addi	a0,a0,1958 # 80008838 <syscalls+0x328>
    8000609a:	ffffa097          	auipc	ra,0xffffa
    8000609e:	490080e7          	jalr	1168(ra) # 8000052a <panic>
    panic("free_desc 2");
    800060a2:	00002517          	auipc	a0,0x2
    800060a6:	7a650513          	addi	a0,a0,1958 # 80008848 <syscalls+0x338>
    800060aa:	ffffa097          	auipc	ra,0xffffa
    800060ae:	480080e7          	jalr	1152(ra) # 8000052a <panic>

00000000800060b2 <virtio_disk_init>:
{
    800060b2:	1101                	addi	sp,sp,-32
    800060b4:	ec06                	sd	ra,24(sp)
    800060b6:	e822                	sd	s0,16(sp)
    800060b8:	e426                	sd	s1,8(sp)
    800060ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060bc:	00002597          	auipc	a1,0x2
    800060c0:	79c58593          	addi	a1,a1,1948 # 80008858 <syscalls+0x348>
    800060c4:	0001f517          	auipc	a0,0x1f
    800060c8:	06450513          	addi	a0,a0,100 # 80025128 <disk+0x2128>
    800060cc:	ffffb097          	auipc	ra,0xffffb
    800060d0:	a66080e7          	jalr	-1434(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060d4:	100017b7          	lui	a5,0x10001
    800060d8:	4398                	lw	a4,0(a5)
    800060da:	2701                	sext.w	a4,a4
    800060dc:	747277b7          	lui	a5,0x74727
    800060e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060e4:	0ef71163          	bne	a4,a5,800061c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060e8:	100017b7          	lui	a5,0x10001
    800060ec:	43dc                	lw	a5,4(a5)
    800060ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060f0:	4705                	li	a4,1
    800060f2:	0ce79a63          	bne	a5,a4,800061c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060f6:	100017b7          	lui	a5,0x10001
    800060fa:	479c                	lw	a5,8(a5)
    800060fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060fe:	4709                	li	a4,2
    80006100:	0ce79363          	bne	a5,a4,800061c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006104:	100017b7          	lui	a5,0x10001
    80006108:	47d8                	lw	a4,12(a5)
    8000610a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000610c:	554d47b7          	lui	a5,0x554d4
    80006110:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006114:	0af71963          	bne	a4,a5,800061c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006118:	100017b7          	lui	a5,0x10001
    8000611c:	4705                	li	a4,1
    8000611e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006120:	470d                	li	a4,3
    80006122:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006124:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006126:	c7ffe737          	lui	a4,0xc7ffe
    8000612a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000612e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006130:	2701                	sext.w	a4,a4
    80006132:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006134:	472d                	li	a4,11
    80006136:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006138:	473d                	li	a4,15
    8000613a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000613c:	6705                	lui	a4,0x1
    8000613e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006140:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006144:	5bdc                	lw	a5,52(a5)
    80006146:	2781                	sext.w	a5,a5
  if(max == 0)
    80006148:	c7d9                	beqz	a5,800061d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000614a:	471d                	li	a4,7
    8000614c:	08f77d63          	bgeu	a4,a5,800061e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006150:	100014b7          	lui	s1,0x10001
    80006154:	47a1                	li	a5,8
    80006156:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006158:	6609                	lui	a2,0x2
    8000615a:	4581                	li	a1,0
    8000615c:	0001d517          	auipc	a0,0x1d
    80006160:	ea450513          	addi	a0,a0,-348 # 80023000 <disk>
    80006164:	ffffb097          	auipc	ra,0xffffb
    80006168:	b5a080e7          	jalr	-1190(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000616c:	0001d717          	auipc	a4,0x1d
    80006170:	e9470713          	addi	a4,a4,-364 # 80023000 <disk>
    80006174:	00c75793          	srli	a5,a4,0xc
    80006178:	2781                	sext.w	a5,a5
    8000617a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000617c:	0001f797          	auipc	a5,0x1f
    80006180:	e8478793          	addi	a5,a5,-380 # 80025000 <disk+0x2000>
    80006184:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006186:	0001d717          	auipc	a4,0x1d
    8000618a:	efa70713          	addi	a4,a4,-262 # 80023080 <disk+0x80>
    8000618e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006190:	0001e717          	auipc	a4,0x1e
    80006194:	e7070713          	addi	a4,a4,-400 # 80024000 <disk+0x1000>
    80006198:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000619a:	4705                	li	a4,1
    8000619c:	00e78c23          	sb	a4,24(a5)
    800061a0:	00e78ca3          	sb	a4,25(a5)
    800061a4:	00e78d23          	sb	a4,26(a5)
    800061a8:	00e78da3          	sb	a4,27(a5)
    800061ac:	00e78e23          	sb	a4,28(a5)
    800061b0:	00e78ea3          	sb	a4,29(a5)
    800061b4:	00e78f23          	sb	a4,30(a5)
    800061b8:	00e78fa3          	sb	a4,31(a5)
}
    800061bc:	60e2                	ld	ra,24(sp)
    800061be:	6442                	ld	s0,16(sp)
    800061c0:	64a2                	ld	s1,8(sp)
    800061c2:	6105                	addi	sp,sp,32
    800061c4:	8082                	ret
    panic("could not find virtio disk");
    800061c6:	00002517          	auipc	a0,0x2
    800061ca:	6a250513          	addi	a0,a0,1698 # 80008868 <syscalls+0x358>
    800061ce:	ffffa097          	auipc	ra,0xffffa
    800061d2:	35c080e7          	jalr	860(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800061d6:	00002517          	auipc	a0,0x2
    800061da:	6b250513          	addi	a0,a0,1714 # 80008888 <syscalls+0x378>
    800061de:	ffffa097          	auipc	ra,0xffffa
    800061e2:	34c080e7          	jalr	844(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800061e6:	00002517          	auipc	a0,0x2
    800061ea:	6c250513          	addi	a0,a0,1730 # 800088a8 <syscalls+0x398>
    800061ee:	ffffa097          	auipc	ra,0xffffa
    800061f2:	33c080e7          	jalr	828(ra) # 8000052a <panic>

00000000800061f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061f6:	7119                	addi	sp,sp,-128
    800061f8:	fc86                	sd	ra,120(sp)
    800061fa:	f8a2                	sd	s0,112(sp)
    800061fc:	f4a6                	sd	s1,104(sp)
    800061fe:	f0ca                	sd	s2,96(sp)
    80006200:	ecce                	sd	s3,88(sp)
    80006202:	e8d2                	sd	s4,80(sp)
    80006204:	e4d6                	sd	s5,72(sp)
    80006206:	e0da                	sd	s6,64(sp)
    80006208:	fc5e                	sd	s7,56(sp)
    8000620a:	f862                	sd	s8,48(sp)
    8000620c:	f466                	sd	s9,40(sp)
    8000620e:	f06a                	sd	s10,32(sp)
    80006210:	ec6e                	sd	s11,24(sp)
    80006212:	0100                	addi	s0,sp,128
    80006214:	8aaa                	mv	s5,a0
    80006216:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006218:	00c52c83          	lw	s9,12(a0)
    8000621c:	001c9c9b          	slliw	s9,s9,0x1
    80006220:	1c82                	slli	s9,s9,0x20
    80006222:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006226:	0001f517          	auipc	a0,0x1f
    8000622a:	f0250513          	addi	a0,a0,-254 # 80025128 <disk+0x2128>
    8000622e:	ffffb097          	auipc	ra,0xffffb
    80006232:	994080e7          	jalr	-1644(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006236:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006238:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000623a:	0001dc17          	auipc	s8,0x1d
    8000623e:	dc6c0c13          	addi	s8,s8,-570 # 80023000 <disk>
    80006242:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006244:	4b0d                	li	s6,3
    80006246:	a0ad                	j	800062b0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006248:	00fc0733          	add	a4,s8,a5
    8000624c:	975e                	add	a4,a4,s7
    8000624e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006252:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006254:	0207c563          	bltz	a5,8000627e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006258:	2905                	addiw	s2,s2,1
    8000625a:	0611                	addi	a2,a2,4
    8000625c:	19690d63          	beq	s2,s6,800063f6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006260:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006262:	0001f717          	auipc	a4,0x1f
    80006266:	db670713          	addi	a4,a4,-586 # 80025018 <disk+0x2018>
    8000626a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000626c:	00074683          	lbu	a3,0(a4)
    80006270:	fee1                	bnez	a3,80006248 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006272:	2785                	addiw	a5,a5,1
    80006274:	0705                	addi	a4,a4,1
    80006276:	fe979be3          	bne	a5,s1,8000626c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000627a:	57fd                	li	a5,-1
    8000627c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000627e:	01205d63          	blez	s2,80006298 <virtio_disk_rw+0xa2>
    80006282:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006284:	000a2503          	lw	a0,0(s4)
    80006288:	00000097          	auipc	ra,0x0
    8000628c:	d8e080e7          	jalr	-626(ra) # 80006016 <free_desc>
      for(int j = 0; j < i; j++)
    80006290:	2d85                	addiw	s11,s11,1
    80006292:	0a11                	addi	s4,s4,4
    80006294:	ffb918e3          	bne	s2,s11,80006284 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006298:	0001f597          	auipc	a1,0x1f
    8000629c:	e9058593          	addi	a1,a1,-368 # 80025128 <disk+0x2128>
    800062a0:	0001f517          	auipc	a0,0x1f
    800062a4:	d7850513          	addi	a0,a0,-648 # 80025018 <disk+0x2018>
    800062a8:	ffffc097          	auipc	ra,0xffffc
    800062ac:	11e080e7          	jalr	286(ra) # 800023c6 <sleep>
  for(int i = 0; i < 3; i++){
    800062b0:	f8040a13          	addi	s4,s0,-128
{
    800062b4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062b6:	894e                	mv	s2,s3
    800062b8:	b765                	j	80006260 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ba:	0001f697          	auipc	a3,0x1f
    800062be:	d466b683          	ld	a3,-698(a3) # 80025000 <disk+0x2000>
    800062c2:	96ba                	add	a3,a3,a4
    800062c4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062c8:	0001d817          	auipc	a6,0x1d
    800062cc:	d3880813          	addi	a6,a6,-712 # 80023000 <disk>
    800062d0:	0001f697          	auipc	a3,0x1f
    800062d4:	d3068693          	addi	a3,a3,-720 # 80025000 <disk+0x2000>
    800062d8:	6290                	ld	a2,0(a3)
    800062da:	963a                	add	a2,a2,a4
    800062dc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800062e0:	0015e593          	ori	a1,a1,1
    800062e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800062e8:	f8842603          	lw	a2,-120(s0)
    800062ec:	628c                	ld	a1,0(a3)
    800062ee:	972e                	add	a4,a4,a1
    800062f0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062f4:	20050593          	addi	a1,a0,512
    800062f8:	0592                	slli	a1,a1,0x4
    800062fa:	95c2                	add	a1,a1,a6
    800062fc:	577d                	li	a4,-1
    800062fe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006302:	00461713          	slli	a4,a2,0x4
    80006306:	6290                	ld	a2,0(a3)
    80006308:	963a                	add	a2,a2,a4
    8000630a:	03078793          	addi	a5,a5,48
    8000630e:	97c2                	add	a5,a5,a6
    80006310:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006312:	629c                	ld	a5,0(a3)
    80006314:	97ba                	add	a5,a5,a4
    80006316:	4605                	li	a2,1
    80006318:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000631a:	629c                	ld	a5,0(a3)
    8000631c:	97ba                	add	a5,a5,a4
    8000631e:	4809                	li	a6,2
    80006320:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006324:	629c                	ld	a5,0(a3)
    80006326:	973e                	add	a4,a4,a5
    80006328:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000632c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006330:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006334:	6698                	ld	a4,8(a3)
    80006336:	00275783          	lhu	a5,2(a4)
    8000633a:	8b9d                	andi	a5,a5,7
    8000633c:	0786                	slli	a5,a5,0x1
    8000633e:	97ba                	add	a5,a5,a4
    80006340:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006344:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006348:	6698                	ld	a4,8(a3)
    8000634a:	00275783          	lhu	a5,2(a4)
    8000634e:	2785                	addiw	a5,a5,1
    80006350:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006354:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006358:	100017b7          	lui	a5,0x10001
    8000635c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006360:	004aa783          	lw	a5,4(s5)
    80006364:	02c79163          	bne	a5,a2,80006386 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006368:	0001f917          	auipc	s2,0x1f
    8000636c:	dc090913          	addi	s2,s2,-576 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006370:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006372:	85ca                	mv	a1,s2
    80006374:	8556                	mv	a0,s5
    80006376:	ffffc097          	auipc	ra,0xffffc
    8000637a:	050080e7          	jalr	80(ra) # 800023c6 <sleep>
  while(b->disk == 1) {
    8000637e:	004aa783          	lw	a5,4(s5)
    80006382:	fe9788e3          	beq	a5,s1,80006372 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006386:	f8042903          	lw	s2,-128(s0)
    8000638a:	20090793          	addi	a5,s2,512
    8000638e:	00479713          	slli	a4,a5,0x4
    80006392:	0001d797          	auipc	a5,0x1d
    80006396:	c6e78793          	addi	a5,a5,-914 # 80023000 <disk>
    8000639a:	97ba                	add	a5,a5,a4
    8000639c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063a0:	0001f997          	auipc	s3,0x1f
    800063a4:	c6098993          	addi	s3,s3,-928 # 80025000 <disk+0x2000>
    800063a8:	00491713          	slli	a4,s2,0x4
    800063ac:	0009b783          	ld	a5,0(s3)
    800063b0:	97ba                	add	a5,a5,a4
    800063b2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063b6:	854a                	mv	a0,s2
    800063b8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063bc:	00000097          	auipc	ra,0x0
    800063c0:	c5a080e7          	jalr	-934(ra) # 80006016 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063c4:	8885                	andi	s1,s1,1
    800063c6:	f0ed                	bnez	s1,800063a8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063c8:	0001f517          	auipc	a0,0x1f
    800063cc:	d6050513          	addi	a0,a0,-672 # 80025128 <disk+0x2128>
    800063d0:	ffffb097          	auipc	ra,0xffffb
    800063d4:	8a6080e7          	jalr	-1882(ra) # 80000c76 <release>
}
    800063d8:	70e6                	ld	ra,120(sp)
    800063da:	7446                	ld	s0,112(sp)
    800063dc:	74a6                	ld	s1,104(sp)
    800063de:	7906                	ld	s2,96(sp)
    800063e0:	69e6                	ld	s3,88(sp)
    800063e2:	6a46                	ld	s4,80(sp)
    800063e4:	6aa6                	ld	s5,72(sp)
    800063e6:	6b06                	ld	s6,64(sp)
    800063e8:	7be2                	ld	s7,56(sp)
    800063ea:	7c42                	ld	s8,48(sp)
    800063ec:	7ca2                	ld	s9,40(sp)
    800063ee:	7d02                	ld	s10,32(sp)
    800063f0:	6de2                	ld	s11,24(sp)
    800063f2:	6109                	addi	sp,sp,128
    800063f4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063f6:	f8042503          	lw	a0,-128(s0)
    800063fa:	20050793          	addi	a5,a0,512
    800063fe:	0792                	slli	a5,a5,0x4
  if(write)
    80006400:	0001d817          	auipc	a6,0x1d
    80006404:	c0080813          	addi	a6,a6,-1024 # 80023000 <disk>
    80006408:	00f80733          	add	a4,a6,a5
    8000640c:	01a036b3          	snez	a3,s10
    80006410:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006414:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006418:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000641c:	7679                	lui	a2,0xffffe
    8000641e:	963e                	add	a2,a2,a5
    80006420:	0001f697          	auipc	a3,0x1f
    80006424:	be068693          	addi	a3,a3,-1056 # 80025000 <disk+0x2000>
    80006428:	6298                	ld	a4,0(a3)
    8000642a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000642c:	0a878593          	addi	a1,a5,168
    80006430:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006432:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006434:	6298                	ld	a4,0(a3)
    80006436:	9732                	add	a4,a4,a2
    80006438:	45c1                	li	a1,16
    8000643a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000643c:	6298                	ld	a4,0(a3)
    8000643e:	9732                	add	a4,a4,a2
    80006440:	4585                	li	a1,1
    80006442:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006446:	f8442703          	lw	a4,-124(s0)
    8000644a:	628c                	ld	a1,0(a3)
    8000644c:	962e                	add	a2,a2,a1
    8000644e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006452:	0712                	slli	a4,a4,0x4
    80006454:	6290                	ld	a2,0(a3)
    80006456:	963a                	add	a2,a2,a4
    80006458:	058a8593          	addi	a1,s5,88
    8000645c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000645e:	6294                	ld	a3,0(a3)
    80006460:	96ba                	add	a3,a3,a4
    80006462:	40000613          	li	a2,1024
    80006466:	c690                	sw	a2,8(a3)
  if(write)
    80006468:	e40d19e3          	bnez	s10,800062ba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000646c:	0001f697          	auipc	a3,0x1f
    80006470:	b946b683          	ld	a3,-1132(a3) # 80025000 <disk+0x2000>
    80006474:	96ba                	add	a3,a3,a4
    80006476:	4609                	li	a2,2
    80006478:	00c69623          	sh	a2,12(a3)
    8000647c:	b5b1                	j	800062c8 <virtio_disk_rw+0xd2>

000000008000647e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000647e:	1101                	addi	sp,sp,-32
    80006480:	ec06                	sd	ra,24(sp)
    80006482:	e822                	sd	s0,16(sp)
    80006484:	e426                	sd	s1,8(sp)
    80006486:	e04a                	sd	s2,0(sp)
    80006488:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000648a:	0001f517          	auipc	a0,0x1f
    8000648e:	c9e50513          	addi	a0,a0,-866 # 80025128 <disk+0x2128>
    80006492:	ffffa097          	auipc	ra,0xffffa
    80006496:	730080e7          	jalr	1840(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000649a:	10001737          	lui	a4,0x10001
    8000649e:	533c                	lw	a5,96(a4)
    800064a0:	8b8d                	andi	a5,a5,3
    800064a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064a8:	0001f797          	auipc	a5,0x1f
    800064ac:	b5878793          	addi	a5,a5,-1192 # 80025000 <disk+0x2000>
    800064b0:	6b94                	ld	a3,16(a5)
    800064b2:	0207d703          	lhu	a4,32(a5)
    800064b6:	0026d783          	lhu	a5,2(a3)
    800064ba:	06f70163          	beq	a4,a5,8000651c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064be:	0001d917          	auipc	s2,0x1d
    800064c2:	b4290913          	addi	s2,s2,-1214 # 80023000 <disk>
    800064c6:	0001f497          	auipc	s1,0x1f
    800064ca:	b3a48493          	addi	s1,s1,-1222 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064ce:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064d2:	6898                	ld	a4,16(s1)
    800064d4:	0204d783          	lhu	a5,32(s1)
    800064d8:	8b9d                	andi	a5,a5,7
    800064da:	078e                	slli	a5,a5,0x3
    800064dc:	97ba                	add	a5,a5,a4
    800064de:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064e0:	20078713          	addi	a4,a5,512
    800064e4:	0712                	slli	a4,a4,0x4
    800064e6:	974a                	add	a4,a4,s2
    800064e8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064ec:	e731                	bnez	a4,80006538 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064ee:	20078793          	addi	a5,a5,512
    800064f2:	0792                	slli	a5,a5,0x4
    800064f4:	97ca                	add	a5,a5,s2
    800064f6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064fc:	ffffc097          	auipc	ra,0xffffc
    80006500:	056080e7          	jalr	86(ra) # 80002552 <wakeup>

    disk.used_idx += 1;
    80006504:	0204d783          	lhu	a5,32(s1)
    80006508:	2785                	addiw	a5,a5,1
    8000650a:	17c2                	slli	a5,a5,0x30
    8000650c:	93c1                	srli	a5,a5,0x30
    8000650e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006512:	6898                	ld	a4,16(s1)
    80006514:	00275703          	lhu	a4,2(a4)
    80006518:	faf71be3          	bne	a4,a5,800064ce <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000651c:	0001f517          	auipc	a0,0x1f
    80006520:	c0c50513          	addi	a0,a0,-1012 # 80025128 <disk+0x2128>
    80006524:	ffffa097          	auipc	ra,0xffffa
    80006528:	752080e7          	jalr	1874(ra) # 80000c76 <release>
}
    8000652c:	60e2                	ld	ra,24(sp)
    8000652e:	6442                	ld	s0,16(sp)
    80006530:	64a2                	ld	s1,8(sp)
    80006532:	6902                	ld	s2,0(sp)
    80006534:	6105                	addi	sp,sp,32
    80006536:	8082                	ret
      panic("virtio_disk_intr status");
    80006538:	00002517          	auipc	a0,0x2
    8000653c:	39050513          	addi	a0,a0,912 # 800088c8 <syscalls+0x3b8>
    80006540:	ffffa097          	auipc	ra,0xffffa
    80006544:	fea080e7          	jalr	-22(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
