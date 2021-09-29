
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
    80000068:	efc78793          	addi	a5,a5,-260 # 80005f60 <timervec>
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
    80000122:	6be080e7          	jalr	1726(ra) # 800027dc <either_copyin>
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
    800001b6:	9c6080e7          	jalr	-1594(ra) # 80001b78 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	20c080e7          	jalr	524(ra) # 800023ce <sleep>
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
    80000202:	588080e7          	jalr	1416(ra) # 80002786 <either_copyout>
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
    800002e2:	554080e7          	jalr	1364(ra) # 80002832 <procdump>
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
    80000436:	128080e7          	jalr	296(ra) # 8000255a <wakeup>
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
    80000882:	cdc080e7          	jalr	-804(ra) # 8000255a <wakeup>
    
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
    8000090e:	ac4080e7          	jalr	-1340(ra) # 800023ce <sleep>
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
    80000b60:	000080e7          	jalr	ra # 80001b5c <mycpu>
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
    80000b92:	fce080e7          	jalr	-50(ra) # 80001b5c <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	fc2080e7          	jalr	-62(ra) # 80001b5c <mycpu>
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
    80000bb6:	faa080e7          	jalr	-86(ra) # 80001b5c <mycpu>
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
    80000bf6:	f6a080e7          	jalr	-150(ra) # 80001b5c <mycpu>
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
    80000c22:	f3e080e7          	jalr	-194(ra) # 80001b5c <mycpu>
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
    80000e78:	cd8080e7          	jalr	-808(ra) # 80001b4c <cpuid>
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
    80000e94:	cbc080e7          	jalr	-836(ra) # 80001b4c <cpuid>
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
    80000eb6:	b08080e7          	jalr	-1272(ra) # 800029ba <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	0e6080e7          	jalr	230(ra) # 80005fa0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	1ee080e7          	jalr	494(ra) # 800020b0 <scheduler>
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
    80000f2e:	a68080e7          	jalr	-1432(ra) # 80002992 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	a88080e7          	jalr	-1400(ra) # 800029ba <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	050080e7          	jalr	80(ra) # 80005f8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	05e080e7          	jalr	94(ra) # 80005fa0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	22c080e7          	jalr	556(ra) # 80003176 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	8bc080e7          	jalr	-1860(ra) # 8000380e <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	866080e7          	jalr	-1946(ra) # 800047c0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	160080e7          	jalr	352(ra) # 800060c2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	ef4080e7          	jalr	-268(ra) # 80001e5e <userinit>
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
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Leyuan & Lee
void enqueue(struct proc *p)
{
    8000180c:	1101                	addi	sp,sp,-32
    8000180e:	ec06                	sd	ra,24(sp)
    80001810:	e822                	sd	s0,16(sp)
    80001812:	e426                	sd	s1,8(sp)
    80001814:	1000                	addi	s0,sp,32
    80001816:	84aa                	mv	s1,a0
  if (p->level > 3)
    80001818:	17053703          	ld	a4,368(a0)
    8000181c:	478d                	li	a5,3
    8000181e:	06e7e163          	bltu	a5,a4,80001880 <enqueue+0x74>
  {
    printf("enqueue level error");
  }
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

  if (mlq->next == EMPTY)
    80001856:	678c                	ld	a1,8(a5)
    80001858:	567d                	li	a2,-1
    8000185a:	02c58c63          	beq	a1,a2,80001892 <enqueue+0x86>
    //   printf("Pindex %d \n", pindex);
    // }
  }
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
      if (qfirst->prev != qindex)
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
  ticks = 0;
    80001b14:	00007797          	auipc	a5,0x7
    80001b18:	5207a023          	sw	zero,1312(a5) # 80009034 <ticks>

  struct qentry *q;

  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001b1c:	0000f797          	auipc	a5,0xf
    80001b20:	78478793          	addi	a5,a5,1924 # 800112a0 <qtable>
  {
    q->prev = EMPTY;
    80001b24:	577d                	li	a4,-1
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001b26:	00010697          	auipc	a3,0x10
    80001b2a:	baa68693          	addi	a3,a3,-1110 # 800116d0 <pid_lock>
    q->prev = EMPTY;
    80001b2e:	e398                	sd	a4,0(a5)
    q->next = EMPTY;
    80001b30:	e798                	sd	a4,8(a5)
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001b32:	07c1                	addi	a5,a5,16
    80001b34:	fed79de3          	bne	a5,a3,80001b2e <procinit+0xb6>
  }
}
    80001b38:	70e2                	ld	ra,56(sp)
    80001b3a:	7442                	ld	s0,48(sp)
    80001b3c:	74a2                	ld	s1,40(sp)
    80001b3e:	7902                	ld	s2,32(sp)
    80001b40:	69e2                	ld	s3,24(sp)
    80001b42:	6a42                	ld	s4,16(sp)
    80001b44:	6aa2                	ld	s5,8(sp)
    80001b46:	6b02                	ld	s6,0(sp)
    80001b48:	6121                	addi	sp,sp,64
    80001b4a:	8082                	ret

0000000080001b4c <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b4c:	1141                	addi	sp,sp,-16
    80001b4e:	e422                	sd	s0,8(sp)
    80001b50:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b52:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b54:	2501                	sext.w	a0,a0
    80001b56:	6422                	ld	s0,8(sp)
    80001b58:	0141                	addi	sp,sp,16
    80001b5a:	8082                	ret

0000000080001b5c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b5c:	1141                	addi	sp,sp,-16
    80001b5e:	e422                	sd	s0,8(sp)
    80001b60:	0800                	addi	s0,sp,16
    80001b62:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b64:	2781                	sext.w	a5,a5
    80001b66:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b68:	00010517          	auipc	a0,0x10
    80001b6c:	b9850513          	addi	a0,a0,-1128 # 80011700 <cpus>
    80001b70:	953e                	add	a0,a0,a5
    80001b72:	6422                	ld	s0,8(sp)
    80001b74:	0141                	addi	sp,sp,16
    80001b76:	8082                	ret

0000000080001b78 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
  push_off();
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	ff4080e7          	jalr	-12(ra) # 80000b76 <push_off>
    80001b8a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b8c:	2781                	sext.w	a5,a5
    80001b8e:	079e                	slli	a5,a5,0x7
    80001b90:	0000f717          	auipc	a4,0xf
    80001b94:	71070713          	addi	a4,a4,1808 # 800112a0 <qtable>
    80001b98:	97ba                	add	a5,a5,a4
    80001b9a:	4607b483          	ld	s1,1120(a5)
  pop_off();
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	078080e7          	jalr	120(ra) # 80000c16 <pop_off>
  return p;
}
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6105                	addi	sp,sp,32
    80001bb0:	8082                	ret

0000000080001bb2 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bb2:	1141                	addi	sp,sp,-16
    80001bb4:	e406                	sd	ra,8(sp)
    80001bb6:	e022                	sd	s0,0(sp)
    80001bb8:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bba:	00000097          	auipc	ra,0x0
    80001bbe:	fbe080e7          	jalr	-66(ra) # 80001b78 <myproc>
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	0b4080e7          	jalr	180(ra) # 80000c76 <release>

  if (first)
    80001bca:	00007797          	auipc	a5,0x7
    80001bce:	d167a783          	lw	a5,-746(a5) # 800088e0 <first.1>
    80001bd2:	eb89                	bnez	a5,80001be4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bd4:	00001097          	auipc	ra,0x1
    80001bd8:	dfe080e7          	jalr	-514(ra) # 800029d2 <usertrapret>
}
    80001bdc:	60a2                	ld	ra,8(sp)
    80001bde:	6402                	ld	s0,0(sp)
    80001be0:	0141                	addi	sp,sp,16
    80001be2:	8082                	ret
    first = 0;
    80001be4:	00007797          	auipc	a5,0x7
    80001be8:	ce07ae23          	sw	zero,-772(a5) # 800088e0 <first.1>
    fsinit(ROOTDEV);
    80001bec:	4505                	li	a0,1
    80001bee:	00002097          	auipc	ra,0x2
    80001bf2:	ba0080e7          	jalr	-1120(ra) # 8000378e <fsinit>
    80001bf6:	bff9                	j	80001bd4 <forkret+0x22>

0000000080001bf8 <allocpid>:
{
    80001bf8:	1101                	addi	sp,sp,-32
    80001bfa:	ec06                	sd	ra,24(sp)
    80001bfc:	e822                	sd	s0,16(sp)
    80001bfe:	e426                	sd	s1,8(sp)
    80001c00:	e04a                	sd	s2,0(sp)
    80001c02:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c04:	00010917          	auipc	s2,0x10
    80001c08:	acc90913          	addi	s2,s2,-1332 # 800116d0 <pid_lock>
    80001c0c:	854a                	mv	a0,s2
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	fb4080e7          	jalr	-76(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001c16:	00007797          	auipc	a5,0x7
    80001c1a:	cce78793          	addi	a5,a5,-818 # 800088e4 <nextpid>
    80001c1e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c20:	0014871b          	addiw	a4,s1,1
    80001c24:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c26:	854a                	mv	a0,s2
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	04e080e7          	jalr	78(ra) # 80000c76 <release>
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret

0000000080001c3e <proc_pagetable>:
{
    80001c3e:	1101                	addi	sp,sp,-32
    80001c40:	ec06                	sd	ra,24(sp)
    80001c42:	e822                	sd	s0,16(sp)
    80001c44:	e426                	sd	s1,8(sp)
    80001c46:	e04a                	sd	s2,0(sp)
    80001c48:	1000                	addi	s0,sp,32
    80001c4a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	6ba080e7          	jalr	1722(ra) # 80001306 <uvmcreate>
    80001c54:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c56:	c121                	beqz	a0,80001c96 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c58:	4729                	li	a4,10
    80001c5a:	00005697          	auipc	a3,0x5
    80001c5e:	3a668693          	addi	a3,a3,934 # 80007000 <_trampoline>
    80001c62:	6605                	lui	a2,0x1
    80001c64:	040005b7          	lui	a1,0x4000
    80001c68:	15fd                	addi	a1,a1,-1
    80001c6a:	05b2                	slli	a1,a1,0xc
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	422080e7          	jalr	1058(ra) # 8000108e <mappages>
    80001c74:	02054863          	bltz	a0,80001ca4 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c78:	4719                	li	a4,6
    80001c7a:	05893683          	ld	a3,88(s2)
    80001c7e:	6605                	lui	a2,0x1
    80001c80:	020005b7          	lui	a1,0x2000
    80001c84:	15fd                	addi	a1,a1,-1
    80001c86:	05b6                	slli	a1,a1,0xd
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	404080e7          	jalr	1028(ra) # 8000108e <mappages>
    80001c92:	02054163          	bltz	a0,80001cb4 <proc_pagetable+0x76>
}
    80001c96:	8526                	mv	a0,s1
    80001c98:	60e2                	ld	ra,24(sp)
    80001c9a:	6442                	ld	s0,16(sp)
    80001c9c:	64a2                	ld	s1,8(sp)
    80001c9e:	6902                	ld	s2,0(sp)
    80001ca0:	6105                	addi	sp,sp,32
    80001ca2:	8082                	ret
    uvmfree(pagetable, 0);
    80001ca4:	4581                	li	a1,0
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	85a080e7          	jalr	-1958(ra) # 80001502 <uvmfree>
    return 0;
    80001cb0:	4481                	li	s1,0
    80001cb2:	b7d5                	j	80001c96 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cb4:	4681                	li	a3,0
    80001cb6:	4605                	li	a2,1
    80001cb8:	040005b7          	lui	a1,0x4000
    80001cbc:	15fd                	addi	a1,a1,-1
    80001cbe:	05b2                	slli	a1,a1,0xc
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	580080e7          	jalr	1408(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cca:	4581                	li	a1,0
    80001ccc:	8526                	mv	a0,s1
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	834080e7          	jalr	-1996(ra) # 80001502 <uvmfree>
    return 0;
    80001cd6:	4481                	li	s1,0
    80001cd8:	bf7d                	j	80001c96 <proc_pagetable+0x58>

0000000080001cda <proc_freepagetable>:
{
    80001cda:	1101                	addi	sp,sp,-32
    80001cdc:	ec06                	sd	ra,24(sp)
    80001cde:	e822                	sd	s0,16(sp)
    80001ce0:	e426                	sd	s1,8(sp)
    80001ce2:	e04a                	sd	s2,0(sp)
    80001ce4:	1000                	addi	s0,sp,32
    80001ce6:	84aa                	mv	s1,a0
    80001ce8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cea:	4681                	li	a3,0
    80001cec:	4605                	li	a2,1
    80001cee:	040005b7          	lui	a1,0x4000
    80001cf2:	15fd                	addi	a1,a1,-1
    80001cf4:	05b2                	slli	a1,a1,0xc
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	54c080e7          	jalr	1356(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cfe:	4681                	li	a3,0
    80001d00:	4605                	li	a2,1
    80001d02:	020005b7          	lui	a1,0x2000
    80001d06:	15fd                	addi	a1,a1,-1
    80001d08:	05b6                	slli	a1,a1,0xd
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	536080e7          	jalr	1334(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d14:	85ca                	mv	a1,s2
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	7ea080e7          	jalr	2026(ra) # 80001502 <uvmfree>
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret

0000000080001d2c <freeproc>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	1000                	addi	s0,sp,32
    80001d36:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d38:	6d28                	ld	a0,88(a0)
    80001d3a:	c509                	beqz	a0,80001d44 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	c9a080e7          	jalr	-870(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001d44:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d48:	68a8                	ld	a0,80(s1)
    80001d4a:	c511                	beqz	a0,80001d56 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d4c:	64ac                	ld	a1,72(s1)
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	f8c080e7          	jalr	-116(ra) # 80001cda <proc_freepagetable>
  p->pagetable = 0;
    80001d56:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d5a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d5e:	0204a823          	sw	zero,48(s1)
  p->ticks = 0; //Leyuan & Lee
    80001d62:	1604a423          	sw	zero,360(s1)
  p->parent = 0;
    80001d66:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d6a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d6e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d72:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d76:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d7a:	0004ac23          	sw	zero,24(s1)
}
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6105                	addi	sp,sp,32
    80001d86:	8082                	ret

0000000080001d88 <allocproc>:
{
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	e04a                	sd	s2,0(sp)
    80001d92:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d94:	00010497          	auipc	s1,0x10
    80001d98:	d6c48493          	addi	s1,s1,-660 # 80011b00 <proc>
    80001d9c:	00016917          	auipc	s2,0x16
    80001da0:	b6490913          	addi	s2,s2,-1180 # 80017900 <tickslock>
    acquire(&p->lock);
    80001da4:	8526                	mv	a0,s1
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	e1c080e7          	jalr	-484(ra) # 80000bc2 <acquire>
    if (p->state == UNUSED)
    80001dae:	4c9c                	lw	a5,24(s1)
    80001db0:	cf81                	beqz	a5,80001dc8 <allocproc+0x40>
      release(&p->lock);
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	ec2080e7          	jalr	-318(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dbc:	17848493          	addi	s1,s1,376
    80001dc0:	ff2492e3          	bne	s1,s2,80001da4 <allocproc+0x1c>
  return 0;
    80001dc4:	4481                	li	s1,0
    80001dc6:	a8a9                	j	80001e20 <allocproc+0x98>
  p->pid = allocpid();
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	e30080e7          	jalr	-464(ra) # 80001bf8 <allocpid>
    80001dd0:	d888                	sw	a0,48(s1)
  p->ticks = 0; //Leyuan & Lee
    80001dd2:	1604a423          	sw	zero,360(s1)
  p->level = 1;
    80001dd6:	4785                	li	a5,1
    80001dd8:	16f4b823          	sd	a5,368(s1)
  p->state = USED;
    80001ddc:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	cf4080e7          	jalr	-780(ra) # 80000ad2 <kalloc>
    80001de6:	892a                	mv	s2,a0
    80001de8:	eca8                	sd	a0,88(s1)
    80001dea:	c131                	beqz	a0,80001e2e <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001dec:	8526                	mv	a0,s1
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e50080e7          	jalr	-432(ra) # 80001c3e <proc_pagetable>
    80001df6:	892a                	mv	s2,a0
    80001df8:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001dfa:	c531                	beqz	a0,80001e46 <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001dfc:	07000613          	li	a2,112
    80001e00:	4581                	li	a1,0
    80001e02:	06048513          	addi	a0,s1,96
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	eb8080e7          	jalr	-328(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001e0e:	00000797          	auipc	a5,0x0
    80001e12:	da478793          	addi	a5,a5,-604 # 80001bb2 <forkret>
    80001e16:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e18:	60bc                	ld	a5,64(s1)
    80001e1a:	6705                	lui	a4,0x1
    80001e1c:	97ba                	add	a5,a5,a4
    80001e1e:	f4bc                	sd	a5,104(s1)
}
    80001e20:	8526                	mv	a0,s1
    80001e22:	60e2                	ld	ra,24(sp)
    80001e24:	6442                	ld	s0,16(sp)
    80001e26:	64a2                	ld	s1,8(sp)
    80001e28:	6902                	ld	s2,0(sp)
    80001e2a:	6105                	addi	sp,sp,32
    80001e2c:	8082                	ret
    freeproc(p);
    80001e2e:	8526                	mv	a0,s1
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	efc080e7          	jalr	-260(ra) # 80001d2c <freeproc>
    release(&p->lock);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e3c080e7          	jalr	-452(ra) # 80000c76 <release>
    return 0;
    80001e42:	84ca                	mv	s1,s2
    80001e44:	bff1                	j	80001e20 <allocproc+0x98>
    freeproc(p);
    80001e46:	8526                	mv	a0,s1
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	ee4080e7          	jalr	-284(ra) # 80001d2c <freeproc>
    release(&p->lock);
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e24080e7          	jalr	-476(ra) # 80000c76 <release>
    return 0;
    80001e5a:	84ca                	mv	s1,s2
    80001e5c:	b7d1                	j	80001e20 <allocproc+0x98>

0000000080001e5e <userinit>:
{
    80001e5e:	1101                	addi	sp,sp,-32
    80001e60:	ec06                	sd	ra,24(sp)
    80001e62:	e822                	sd	s0,16(sp)
    80001e64:	e426                	sd	s1,8(sp)
    80001e66:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	f20080e7          	jalr	-224(ra) # 80001d88 <allocproc>
    80001e70:	84aa                	mv	s1,a0
  initproc = p;
    80001e72:	00007797          	auipc	a5,0x7
    80001e76:	1aa7bb23          	sd	a0,438(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e7a:	03400613          	li	a2,52
    80001e7e:	00007597          	auipc	a1,0x7
    80001e82:	a7258593          	addi	a1,a1,-1422 # 800088f0 <initcode>
    80001e86:	6928                	ld	a0,80(a0)
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	4ac080e7          	jalr	1196(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001e90:	6785                	lui	a5,0x1
    80001e92:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e94:	6cb8                	ld	a4,88(s1)
    80001e96:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e9a:	6cb8                	ld	a4,88(s1)
    80001e9c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e9e:	4641                	li	a2,16
    80001ea0:	00006597          	auipc	a1,0x6
    80001ea4:	42858593          	addi	a1,a1,1064 # 800082c8 <digits+0x288>
    80001ea8:	15848513          	addi	a0,s1,344
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	f64080e7          	jalr	-156(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001eb4:	00006517          	auipc	a0,0x6
    80001eb8:	42450513          	addi	a0,a0,1060 # 800082d8 <digits+0x298>
    80001ebc:	00002097          	auipc	ra,0x2
    80001ec0:	300080e7          	jalr	768(ra) # 800041bc <namei>
    80001ec4:	14a4b823          	sd	a0,336(s1)
  global_ticks = 0; //Leyuan & Lee
    80001ec8:	00007797          	auipc	a5,0x7
    80001ecc:	1607a423          	sw	zero,360(a5) # 80009030 <global_ticks>
  p->state = RUNNABLE;
    80001ed0:	478d                	li	a5,3
    80001ed2:	cc9c                	sw	a5,24(s1)
  enqueue(p);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	936080e7          	jalr	-1738(ra) # 8000180c <enqueue>
  release(&p->lock);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	d96080e7          	jalr	-618(ra) # 80000c76 <release>
}
    80001ee8:	60e2                	ld	ra,24(sp)
    80001eea:	6442                	ld	s0,16(sp)
    80001eec:	64a2                	ld	s1,8(sp)
    80001eee:	6105                	addi	sp,sp,32
    80001ef0:	8082                	ret

0000000080001ef2 <growproc>:
{
    80001ef2:	1101                	addi	sp,sp,-32
    80001ef4:	ec06                	sd	ra,24(sp)
    80001ef6:	e822                	sd	s0,16(sp)
    80001ef8:	e426                	sd	s1,8(sp)
    80001efa:	e04a                	sd	s2,0(sp)
    80001efc:	1000                	addi	s0,sp,32
    80001efe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f00:	00000097          	auipc	ra,0x0
    80001f04:	c78080e7          	jalr	-904(ra) # 80001b78 <myproc>
    80001f08:	892a                	mv	s2,a0
  sz = p->sz;
    80001f0a:	652c                	ld	a1,72(a0)
    80001f0c:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001f10:	00904f63          	bgtz	s1,80001f2e <growproc+0x3c>
  else if (n < 0)
    80001f14:	0204cc63          	bltz	s1,80001f4c <growproc+0x5a>
  p->sz = sz;
    80001f18:	1602                	slli	a2,a2,0x20
    80001f1a:	9201                	srli	a2,a2,0x20
    80001f1c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f20:	4501                	li	a0,0
}
    80001f22:	60e2                	ld	ra,24(sp)
    80001f24:	6442                	ld	s0,16(sp)
    80001f26:	64a2                	ld	s1,8(sp)
    80001f28:	6902                	ld	s2,0(sp)
    80001f2a:	6105                	addi	sp,sp,32
    80001f2c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001f2e:	9e25                	addw	a2,a2,s1
    80001f30:	1602                	slli	a2,a2,0x20
    80001f32:	9201                	srli	a2,a2,0x20
    80001f34:	1582                	slli	a1,a1,0x20
    80001f36:	9181                	srli	a1,a1,0x20
    80001f38:	6928                	ld	a0,80(a0)
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	4b4080e7          	jalr	1204(ra) # 800013ee <uvmalloc>
    80001f42:	0005061b          	sext.w	a2,a0
    80001f46:	fa69                	bnez	a2,80001f18 <growproc+0x26>
      return -1;
    80001f48:	557d                	li	a0,-1
    80001f4a:	bfe1                	j	80001f22 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f4c:	9e25                	addw	a2,a2,s1
    80001f4e:	1602                	slli	a2,a2,0x20
    80001f50:	9201                	srli	a2,a2,0x20
    80001f52:	1582                	slli	a1,a1,0x20
    80001f54:	9181                	srli	a1,a1,0x20
    80001f56:	6928                	ld	a0,80(a0)
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	44e080e7          	jalr	1102(ra) # 800013a6 <uvmdealloc>
    80001f60:	0005061b          	sext.w	a2,a0
    80001f64:	bf55                	j	80001f18 <growproc+0x26>

0000000080001f66 <fork>:
{
    80001f66:	7139                	addi	sp,sp,-64
    80001f68:	fc06                	sd	ra,56(sp)
    80001f6a:	f822                	sd	s0,48(sp)
    80001f6c:	f426                	sd	s1,40(sp)
    80001f6e:	f04a                	sd	s2,32(sp)
    80001f70:	ec4e                	sd	s3,24(sp)
    80001f72:	e852                	sd	s4,16(sp)
    80001f74:	e456                	sd	s5,8(sp)
    80001f76:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f78:	00000097          	auipc	ra,0x0
    80001f7c:	c00080e7          	jalr	-1024(ra) # 80001b78 <myproc>
    80001f80:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	e06080e7          	jalr	-506(ra) # 80001d88 <allocproc>
    80001f8a:	12050163          	beqz	a0,800020ac <fork+0x146>
    80001f8e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f90:	048ab603          	ld	a2,72(s5)
    80001f94:	692c                	ld	a1,80(a0)
    80001f96:	050ab503          	ld	a0,80(s5)
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	5a0080e7          	jalr	1440(ra) # 8000153a <uvmcopy>
    80001fa2:	04054863          	bltz	a0,80001ff2 <fork+0x8c>
  np->sz = p->sz;
    80001fa6:	048ab783          	ld	a5,72(s5)
    80001faa:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001fae:	058ab683          	ld	a3,88(s5)
    80001fb2:	87b6                	mv	a5,a3
    80001fb4:	0589b703          	ld	a4,88(s3)
    80001fb8:	12068693          	addi	a3,a3,288
    80001fbc:	0007b803          	ld	a6,0(a5)
    80001fc0:	6788                	ld	a0,8(a5)
    80001fc2:	6b8c                	ld	a1,16(a5)
    80001fc4:	6f90                	ld	a2,24(a5)
    80001fc6:	01073023          	sd	a6,0(a4)
    80001fca:	e708                	sd	a0,8(a4)
    80001fcc:	eb0c                	sd	a1,16(a4)
    80001fce:	ef10                	sd	a2,24(a4)
    80001fd0:	02078793          	addi	a5,a5,32
    80001fd4:	02070713          	addi	a4,a4,32
    80001fd8:	fed792e3          	bne	a5,a3,80001fbc <fork+0x56>
  np->trapframe->a0 = 0;
    80001fdc:	0589b783          	ld	a5,88(s3)
    80001fe0:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fe4:	0d0a8493          	addi	s1,s5,208
    80001fe8:	0d098913          	addi	s2,s3,208
    80001fec:	150a8a13          	addi	s4,s5,336
    80001ff0:	a00d                	j	80002012 <fork+0xac>
    freeproc(np);
    80001ff2:	854e                	mv	a0,s3
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	d38080e7          	jalr	-712(ra) # 80001d2c <freeproc>
    release(&np->lock);
    80001ffc:	854e                	mv	a0,s3
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	c78080e7          	jalr	-904(ra) # 80000c76 <release>
    return -1;
    80002006:	597d                	li	s2,-1
    80002008:	a841                	j	80002098 <fork+0x132>
  for (i = 0; i < NOFILE; i++)
    8000200a:	04a1                	addi	s1,s1,8
    8000200c:	0921                	addi	s2,s2,8
    8000200e:	01448b63          	beq	s1,s4,80002024 <fork+0xbe>
    if (p->ofile[i])
    80002012:	6088                	ld	a0,0(s1)
    80002014:	d97d                	beqz	a0,8000200a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002016:	00003097          	auipc	ra,0x3
    8000201a:	83c080e7          	jalr	-1988(ra) # 80004852 <filedup>
    8000201e:	00a93023          	sd	a0,0(s2)
    80002022:	b7e5                	j	8000200a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002024:	150ab503          	ld	a0,336(s5)
    80002028:	00002097          	auipc	ra,0x2
    8000202c:	9a0080e7          	jalr	-1632(ra) # 800039c8 <idup>
    80002030:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002034:	4641                	li	a2,16
    80002036:	158a8593          	addi	a1,s5,344
    8000203a:	15898513          	addi	a0,s3,344
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	dd2080e7          	jalr	-558(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002046:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    8000204a:	854e                	mv	a0,s3
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c2a080e7          	jalr	-982(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80002054:	0000f497          	auipc	s1,0xf
    80002058:	69448493          	addi	s1,s1,1684 # 800116e8 <wait_lock>
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	b64080e7          	jalr	-1180(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002066:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	c0a080e7          	jalr	-1014(ra) # 80000c76 <release>
  acquire(&np->lock);
    80002074:	854e                	mv	a0,s3
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	b4c080e7          	jalr	-1204(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    8000207e:	478d                	li	a5,3
    80002080:	00f9ac23          	sw	a5,24(s3)
  enqueue(np);
    80002084:	854e                	mv	a0,s3
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	786080e7          	jalr	1926(ra) # 8000180c <enqueue>
  release(&np->lock);
    8000208e:	854e                	mv	a0,s3
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	be6080e7          	jalr	-1050(ra) # 80000c76 <release>
}
    80002098:	854a                	mv	a0,s2
    8000209a:	70e2                	ld	ra,56(sp)
    8000209c:	7442                	ld	s0,48(sp)
    8000209e:	74a2                	ld	s1,40(sp)
    800020a0:	7902                	ld	s2,32(sp)
    800020a2:	69e2                	ld	s3,24(sp)
    800020a4:	6a42                	ld	s4,16(sp)
    800020a6:	6aa2                	ld	s5,8(sp)
    800020a8:	6121                	addi	sp,sp,64
    800020aa:	8082                	ret
    return -1;
    800020ac:	597d                	li	s2,-1
    800020ae:	b7ed                	j	80002098 <fork+0x132>

00000000800020b0 <scheduler>:
{
    800020b0:	7139                	addi	sp,sp,-64
    800020b2:	fc06                	sd	ra,56(sp)
    800020b4:	f822                	sd	s0,48(sp)
    800020b6:	f426                	sd	s1,40(sp)
    800020b8:	f04a                	sd	s2,32(sp)
    800020ba:	ec4e                	sd	s3,24(sp)
    800020bc:	e852                	sd	s4,16(sp)
    800020be:	e456                	sd	s5,8(sp)
    800020c0:	0080                	addi	s0,sp,64
    800020c2:	8792                	mv	a5,tp
  int id = r_tp();
    800020c4:	2781                	sext.w	a5,a5
        swtch(&c->context, &p->context);
    800020c6:	00779a13          	slli	s4,a5,0x7
    800020ca:	0000f717          	auipc	a4,0xf
    800020ce:	63e70713          	addi	a4,a4,1598 # 80011708 <cpus+0x8>
    800020d2:	9a3a                	add	s4,s4,a4
      if (p->state == RUNNABLE)
    800020d4:	490d                	li	s2,3
        p->state = RUNNING;
    800020d6:	4a91                	li	s5,4
        c->proc = p;
    800020d8:	079e                	slli	a5,a5,0x7
    800020da:	0000f997          	auipc	s3,0xf
    800020de:	1c698993          	addi	s3,s3,454 # 800112a0 <qtable>
    800020e2:	99be                	add	s3,s3,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ec:	10079073          	csrw	sstatus,a5
}
    800020f0:	a031                	j	800020fc <scheduler+0x4c>
      release(&p->lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	b82080e7          	jalr	-1150(ra) # 80000c76 <release>
    while ((p = dequeue()) != 0)
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	7a0080e7          	jalr	1952(ra) # 8000189c <dequeue>
    80002104:	84aa                	mv	s1,a0
    80002106:	dd79                	beqz	a0,800020e4 <scheduler+0x34>
      acquire(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	ab8080e7          	jalr	-1352(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80002112:	4c9c                	lw	a5,24(s1)
    80002114:	fd279fe3          	bne	a5,s2,800020f2 <scheduler+0x42>
        p->state = RUNNING;
    80002118:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    8000211c:	4699b023          	sd	s1,1120(s3)
        swtch(&c->context, &p->context);
    80002120:	06048593          	addi	a1,s1,96
    80002124:	8552                	mv	a0,s4
    80002126:	00001097          	auipc	ra,0x1
    8000212a:	802080e7          	jalr	-2046(ra) # 80002928 <swtch>
        c->proc = 0;
    8000212e:	4609b023          	sd	zero,1120(s3)
    80002132:	b7c1                	j	800020f2 <scheduler+0x42>

0000000080002134 <sched>:
{
    80002134:	7179                	addi	sp,sp,-48
    80002136:	f406                	sd	ra,40(sp)
    80002138:	f022                	sd	s0,32(sp)
    8000213a:	ec26                	sd	s1,24(sp)
    8000213c:	e84a                	sd	s2,16(sp)
    8000213e:	e44e                	sd	s3,8(sp)
    80002140:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002142:	00000097          	auipc	ra,0x0
    80002146:	a36080e7          	jalr	-1482(ra) # 80001b78 <myproc>
    8000214a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	9fc080e7          	jalr	-1540(ra) # 80000b48 <holding>
    80002154:	c93d                	beqz	a0,800021ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002156:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002158:	2781                	sext.w	a5,a5
    8000215a:	079e                	slli	a5,a5,0x7
    8000215c:	0000f717          	auipc	a4,0xf
    80002160:	14470713          	addi	a4,a4,324 # 800112a0 <qtable>
    80002164:	97ba                	add	a5,a5,a4
    80002166:	4d87a703          	lw	a4,1240(a5)
    8000216a:	4785                	li	a5,1
    8000216c:	06f71763          	bne	a4,a5,800021da <sched+0xa6>
  if (p->state == RUNNING)
    80002170:	4c98                	lw	a4,24(s1)
    80002172:	4791                	li	a5,4
    80002174:	06f70b63          	beq	a4,a5,800021ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002178:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000217c:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000217e:	efb5                	bnez	a5,800021fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002180:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002182:	0000f917          	auipc	s2,0xf
    80002186:	11e90913          	addi	s2,s2,286 # 800112a0 <qtable>
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	97ca                	add	a5,a5,s2
    80002190:	4dc7a983          	lw	s3,1244(a5)
    80002194:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	0000f597          	auipc	a1,0xf
    8000219e:	56e58593          	addi	a1,a1,1390 # 80011708 <cpus+0x8>
    800021a2:	95be                	add	a1,a1,a5
    800021a4:	06048513          	addi	a0,s1,96
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	780080e7          	jalr	1920(ra) # 80002928 <swtch>
    800021b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021b2:	2781                	sext.w	a5,a5
    800021b4:	079e                	slli	a5,a5,0x7
    800021b6:	97ca                	add	a5,a5,s2
    800021b8:	4d37ae23          	sw	s3,1244(a5)
}
    800021bc:	70a2                	ld	ra,40(sp)
    800021be:	7402                	ld	s0,32(sp)
    800021c0:	64e2                	ld	s1,24(sp)
    800021c2:	6942                	ld	s2,16(sp)
    800021c4:	69a2                	ld	s3,8(sp)
    800021c6:	6145                	addi	sp,sp,48
    800021c8:	8082                	ret
    panic("sched p->lock");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	11650513          	addi	a0,a0,278 # 800082e0 <digits+0x2a0>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	358080e7          	jalr	856(ra) # 8000052a <panic>
    panic("sched locks");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	11650513          	addi	a0,a0,278 # 800082f0 <digits+0x2b0>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	348080e7          	jalr	840(ra) # 8000052a <panic>
    panic("sched running");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	11650513          	addi	a0,a0,278 # 80008300 <digits+0x2c0>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	338080e7          	jalr	824(ra) # 8000052a <panic>
    panic("sched interruptible");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	11650513          	addi	a0,a0,278 # 80008310 <digits+0x2d0>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	328080e7          	jalr	808(ra) # 8000052a <panic>

000000008000220a <yield>:
{
    8000220a:	1101                	addi	sp,sp,-32
    8000220c:	ec06                	sd	ra,24(sp)
    8000220e:	e822                	sd	s0,16(sp)
    80002210:	e426                	sd	s1,8(sp)
    80002212:	e04a                	sd	s2,0(sp)
    80002214:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	962080e7          	jalr	-1694(ra) # 80001b78 <myproc>
    8000221e:	84aa                	mv	s1,a0
  global_ticks++;
    80002220:	00007717          	auipc	a4,0x7
    80002224:	e1070713          	addi	a4,a4,-496 # 80009030 <global_ticks>
    80002228:	431c                	lw	a5,0(a4)
    8000222a:	2785                	addiw	a5,a5,1
    8000222c:	c31c                	sw	a5,0(a4)
  if (global_ticks % 32 == 0)
    8000222e:	8bfd                	andi	a5,a5,31
    80002230:	ebe5                	bnez	a5,80002320 <yield+0x116>
    if (Q3->next != EMPTY)
    80002232:	0000f797          	auipc	a5,0xf
    80002236:	4967b783          	ld	a5,1174(a5) # 800116c8 <qtable+0x428>
    8000223a:	577d                	li	a4,-1
    8000223c:	04e78e63          	beq	a5,a4,80002298 <yield+0x8e>
      uint64 lQ3 = Q3->prev;
    80002240:	0000f717          	auipc	a4,0xf
    80002244:	06070713          	addi	a4,a4,96 # 800112a0 <qtable>
    80002248:	42073583          	ld	a1,1056(a4)
      struct qentry *lq3QTable = qtable + lQ3;
    8000224c:	00459693          	slli	a3,a1,0x4
    80002250:	00d70633          	add	a2,a4,a3
      struct qentry *fq3QTable = qtable + fQ3;
    80002254:	00479693          	slli	a3,a5,0x4
    80002258:	96ba                	add	a3,a3,a4
      if (Q2->next != EMPTY)
    8000225a:	41873503          	ld	a0,1048(a4)
    8000225e:	577d                	li	a4,-1
    80002260:	0ee50663          	beq	a0,a4,8000234c <yield+0x142>
        uint64 lQ2 = Q2->prev;
    80002264:	0000f717          	auipc	a4,0xf
    80002268:	03c70713          	addi	a4,a4,60 # 800112a0 <qtable>
    8000226c:	41073803          	ld	a6,1040(a4)
        lq2QTable->next = fQ3;
    80002270:	00481513          	slli	a0,a6,0x4
    80002274:	953a                	add	a0,a0,a4
    80002276:	e51c                	sd	a5,8(a0)
        fq3QTable->prev = lQ2;
    80002278:	0106b023          	sd	a6,0(a3)
        lq3QTable->next = Q2 - qtable;
    8000227c:	04100793          	li	a5,65
    80002280:	e61c                	sd	a5,8(a2)
        Q2->prev = lQ3;
    80002282:	40b73823          	sd	a1,1040(a4)
      Q3->next = EMPTY;
    80002286:	0000f797          	auipc	a5,0xf
    8000228a:	01a78793          	addi	a5,a5,26 # 800112a0 <qtable>
    8000228e:	577d                	li	a4,-1
    80002290:	42e7b423          	sd	a4,1064(a5)
      Q3->prev = EMPTY;
    80002294:	42e7b023          	sd	a4,1056(a5)
    if (Q2->next != EMPTY)
    80002298:	0000f797          	auipc	a5,0xf
    8000229c:	4207b783          	ld	a5,1056(a5) # 800116b8 <qtable+0x418>
    800022a0:	577d                	li	a4,-1
    800022a2:	04e78e63          	beq	a5,a4,800022fe <yield+0xf4>
      uint64 lQ2 = Q2->prev;
    800022a6:	0000f717          	auipc	a4,0xf
    800022aa:	ffa70713          	addi	a4,a4,-6 # 800112a0 <qtable>
    800022ae:	41073583          	ld	a1,1040(a4)
      struct qentry *lq2QTable = qtable + lQ2;
    800022b2:	00459693          	slli	a3,a1,0x4
    800022b6:	00d70633          	add	a2,a4,a3
      struct qentry *fq2QTable = qtable + fQ2;
    800022ba:	00479693          	slli	a3,a5,0x4
    800022be:	96ba                	add	a3,a3,a4
      if (Q1->next != EMPTY)
    800022c0:	40873503          	ld	a0,1032(a4)
    800022c4:	577d                	li	a4,-1
    800022c6:	0ae50063          	beq	a0,a4,80002366 <yield+0x15c>
        uint64 lQ1 = Q1->prev;
    800022ca:	0000f717          	auipc	a4,0xf
    800022ce:	fd670713          	addi	a4,a4,-42 # 800112a0 <qtable>
    800022d2:	40073803          	ld	a6,1024(a4)
        lq1QTable->next = fQ2;
    800022d6:	00481513          	slli	a0,a6,0x4
    800022da:	953a                	add	a0,a0,a4
    800022dc:	e51c                	sd	a5,8(a0)
        fq2QTable->prev = lQ1;
    800022de:	0106b023          	sd	a6,0(a3)
        lq2QTable->next = Q1 - qtable;
    800022e2:	04000793          	li	a5,64
    800022e6:	e61c                	sd	a5,8(a2)
        Q1->prev = lQ2;
    800022e8:	40b73023          	sd	a1,1024(a4)
      Q2->next = EMPTY;
    800022ec:	0000f797          	auipc	a5,0xf
    800022f0:	fb478793          	addi	a5,a5,-76 # 800112a0 <qtable>
    800022f4:	577d                	li	a4,-1
    800022f6:	40e7bc23          	sd	a4,1048(a5)
      Q2->prev = EMPTY;
    800022fa:	40e7b823          	sd	a4,1040(a5)
{
    800022fe:	00010497          	auipc	s1,0x10
    80002302:	80248493          	addi	s1,s1,-2046 # 80011b00 <proc>
      p->level = 1;
    80002306:	4705                	li	a4,1
    for (p = proc; p < &proc[NPROC]; p++)
    80002308:	00015797          	auipc	a5,0x15
    8000230c:	5f878793          	addi	a5,a5,1528 # 80017900 <tickslock>
      p->level = 1;
    80002310:	16e4b823          	sd	a4,368(s1)
      p->ticks = 0;
    80002314:	1604a423          	sw	zero,360(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80002318:	17848493          	addi	s1,s1,376
    8000231c:	fef49ae3          	bne	s1,a5,80002310 <yield+0x106>
  p->ticks++;
    80002320:	1684a783          	lw	a5,360(s1)
    80002324:	2785                	addiw	a5,a5,1
    80002326:	0007869b          	sext.w	a3,a5
    8000232a:	16f4a423          	sw	a5,360(s1)
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
    8000232e:	1704b783          	ld	a5,368(s1)
    80002332:	4705                	li	a4,1
    80002334:	04e78963          	beq	a5,a4,80002386 <yield+0x17c>
    80002338:	4709                	li	a4,2
    8000233a:	04e78363          	beq	a5,a4,80002380 <yield+0x176>
    8000233e:	470d                	li	a4,3
    80002340:	08e79163          	bne	a5,a4,800023c2 <yield+0x1b8>
    80002344:	478d                	li	a5,3
    80002346:	06d7de63          	bge	a5,a3,800023c2 <yield+0x1b8>
    8000234a:	a835                	j	80002386 <yield+0x17c>
        Q2->next = Q3->next;
    8000234c:	0000f717          	auipc	a4,0xf
    80002350:	f5470713          	addi	a4,a4,-172 # 800112a0 <qtable>
    80002354:	40f73c23          	sd	a5,1048(a4)
        Q2->prev = Q3->prev;
    80002358:	40b73823          	sd	a1,1040(a4)
        lq3QTable->next = Q2 - qtable;
    8000235c:	04100793          	li	a5,65
    80002360:	e61c                	sd	a5,8(a2)
        fq3QTable->prev = Q2 - qtable;
    80002362:	e29c                	sd	a5,0(a3)
    80002364:	b70d                	j	80002286 <yield+0x7c>
        Q1->next = Q2->next;
    80002366:	0000f717          	auipc	a4,0xf
    8000236a:	f3a70713          	addi	a4,a4,-198 # 800112a0 <qtable>
    8000236e:	40f73423          	sd	a5,1032(a4)
        Q1->prev = Q2->prev;
    80002372:	40b73023          	sd	a1,1024(a4)
        lq2QTable->next = Q1 - qtable;
    80002376:	04000793          	li	a5,64
    8000237a:	e61c                	sd	a5,8(a2)
        fq2QTable->prev = Q1 - qtable;
    8000237c:	e29c                	sd	a5,0(a3)
    8000237e:	b7bd                	j	800022ec <yield+0xe2>
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
    80002380:	4785                	li	a5,1
    80002382:	04d7d063          	bge	a5,a3,800023c2 <yield+0x1b8>
    acquire(&p->lock);
    80002386:	8926                	mv	s2,s1
    80002388:	8526                	mv	a0,s1
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	838080e7          	jalr	-1992(ra) # 80000bc2 <acquire>
    p->state = RUNNABLE;
    80002392:	478d                	li	a5,3
    80002394:	cc9c                	sw	a5,24(s1)
    if (p->level < 3)
    80002396:	1704b783          	ld	a5,368(s1)
    8000239a:	4709                	li	a4,2
    8000239c:	00f76563          	bltu	a4,a5,800023a6 <yield+0x19c>
      p->level++;
    800023a0:	0785                	addi	a5,a5,1
    800023a2:	16f4b823          	sd	a5,368(s1)
    enqueue(p); //might need to discuss
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	464080e7          	jalr	1124(ra) # 8000180c <enqueue>
    sched();
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	d84080e7          	jalr	-636(ra) # 80002134 <sched>
    release(&p->lock);
    800023b8:	854a                	mv	a0,s2
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8bc080e7          	jalr	-1860(ra) # 80000c76 <release>
}
    800023c2:	60e2                	ld	ra,24(sp)
    800023c4:	6442                	ld	s0,16(sp)
    800023c6:	64a2                	ld	s1,8(sp)
    800023c8:	6902                	ld	s2,0(sp)
    800023ca:	6105                	addi	sp,sp,32
    800023cc:	8082                	ret

00000000800023ce <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023ce:	7179                	addi	sp,sp,-48
    800023d0:	f406                	sd	ra,40(sp)
    800023d2:	f022                	sd	s0,32(sp)
    800023d4:	ec26                	sd	s1,24(sp)
    800023d6:	e84a                	sd	s2,16(sp)
    800023d8:	e44e                	sd	s3,8(sp)
    800023da:	1800                	addi	s0,sp,48
    800023dc:	89aa                	mv	s3,a0
    800023de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	798080e7          	jalr	1944(ra) # 80001b78 <myproc>
    800023e8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7d8080e7          	jalr	2008(ra) # 80000bc2 <acquire>
  release(lk);
    800023f2:	854a                	mv	a0,s2
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	882080e7          	jalr	-1918(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800023fc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002400:	4789                	li	a5,2
    80002402:	cc9c                	sw	a5,24(s1)

  sched();
    80002404:	00000097          	auipc	ra,0x0
    80002408:	d30080e7          	jalr	-720(ra) # 80002134 <sched>

  // Tidy up.
  p->chan = 0;
    8000240c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	864080e7          	jalr	-1948(ra) # 80000c76 <release>
  acquire(lk);
    8000241a:	854a                	mv	a0,s2
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7a6080e7          	jalr	1958(ra) # 80000bc2 <acquire>
}
    80002424:	70a2                	ld	ra,40(sp)
    80002426:	7402                	ld	s0,32(sp)
    80002428:	64e2                	ld	s1,24(sp)
    8000242a:	6942                	ld	s2,16(sp)
    8000242c:	69a2                	ld	s3,8(sp)
    8000242e:	6145                	addi	sp,sp,48
    80002430:	8082                	ret

0000000080002432 <wait>:
{
    80002432:	715d                	addi	sp,sp,-80
    80002434:	e486                	sd	ra,72(sp)
    80002436:	e0a2                	sd	s0,64(sp)
    80002438:	fc26                	sd	s1,56(sp)
    8000243a:	f84a                	sd	s2,48(sp)
    8000243c:	f44e                	sd	s3,40(sp)
    8000243e:	f052                	sd	s4,32(sp)
    80002440:	ec56                	sd	s5,24(sp)
    80002442:	e85a                	sd	s6,16(sp)
    80002444:	e45e                	sd	s7,8(sp)
    80002446:	e062                	sd	s8,0(sp)
    80002448:	0880                	addi	s0,sp,80
    8000244a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	72c080e7          	jalr	1836(ra) # 80001b78 <myproc>
    80002454:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002456:	0000f517          	auipc	a0,0xf
    8000245a:	29250513          	addi	a0,a0,658 # 800116e8 <wait_lock>
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	764080e7          	jalr	1892(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002466:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002468:	4a15                	li	s4,5
        havekids = 1;
    8000246a:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000246c:	00015997          	auipc	s3,0x15
    80002470:	49498993          	addi	s3,s3,1172 # 80017900 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002474:	0000fc17          	auipc	s8,0xf
    80002478:	274c0c13          	addi	s8,s8,628 # 800116e8 <wait_lock>
    havekids = 0;
    8000247c:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000247e:	0000f497          	auipc	s1,0xf
    80002482:	68248493          	addi	s1,s1,1666 # 80011b00 <proc>
    80002486:	a0bd                	j	800024f4 <wait+0xc2>
          pid = np->pid;
    80002488:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000248c:	000b0e63          	beqz	s6,800024a8 <wait+0x76>
    80002490:	4691                	li	a3,4
    80002492:	02c48613          	addi	a2,s1,44
    80002496:	85da                	mv	a1,s6
    80002498:	05093503          	ld	a0,80(s2)
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	1a2080e7          	jalr	418(ra) # 8000163e <copyout>
    800024a4:	02054563          	bltz	a0,800024ce <wait+0x9c>
          freeproc(np);
    800024a8:	8526                	mv	a0,s1
    800024aa:	00000097          	auipc	ra,0x0
    800024ae:	882080e7          	jalr	-1918(ra) # 80001d2c <freeproc>
          release(&np->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7c2080e7          	jalr	1986(ra) # 80000c76 <release>
          release(&wait_lock);
    800024bc:	0000f517          	auipc	a0,0xf
    800024c0:	22c50513          	addi	a0,a0,556 # 800116e8 <wait_lock>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	7b2080e7          	jalr	1970(ra) # 80000c76 <release>
          return pid;
    800024cc:	a09d                	j	80002532 <wait+0x100>
            release(&np->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7a6080e7          	jalr	1958(ra) # 80000c76 <release>
            release(&wait_lock);
    800024d8:	0000f517          	auipc	a0,0xf
    800024dc:	21050513          	addi	a0,a0,528 # 800116e8 <wait_lock>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	796080e7          	jalr	1942(ra) # 80000c76 <release>
            return -1;
    800024e8:	59fd                	li	s3,-1
    800024ea:	a0a1                	j	80002532 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800024ec:	17848493          	addi	s1,s1,376
    800024f0:	03348463          	beq	s1,s3,80002518 <wait+0xe6>
      if (np->parent == p)
    800024f4:	7c9c                	ld	a5,56(s1)
    800024f6:	ff279be3          	bne	a5,s2,800024ec <wait+0xba>
        acquire(&np->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	6c6080e7          	jalr	1734(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    80002504:	4c9c                	lw	a5,24(s1)
    80002506:	f94781e3          	beq	a5,s4,80002488 <wait+0x56>
        release(&np->lock);
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	76a080e7          	jalr	1898(ra) # 80000c76 <release>
        havekids = 1;
    80002514:	8756                	mv	a4,s5
    80002516:	bfd9                	j	800024ec <wait+0xba>
    if (!havekids || p->killed)
    80002518:	c701                	beqz	a4,80002520 <wait+0xee>
    8000251a:	02892783          	lw	a5,40(s2)
    8000251e:	c79d                	beqz	a5,8000254c <wait+0x11a>
      release(&wait_lock);
    80002520:	0000f517          	auipc	a0,0xf
    80002524:	1c850513          	addi	a0,a0,456 # 800116e8 <wait_lock>
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	74e080e7          	jalr	1870(ra) # 80000c76 <release>
      return -1;
    80002530:	59fd                	li	s3,-1
}
    80002532:	854e                	mv	a0,s3
    80002534:	60a6                	ld	ra,72(sp)
    80002536:	6406                	ld	s0,64(sp)
    80002538:	74e2                	ld	s1,56(sp)
    8000253a:	7942                	ld	s2,48(sp)
    8000253c:	79a2                	ld	s3,40(sp)
    8000253e:	7a02                	ld	s4,32(sp)
    80002540:	6ae2                	ld	s5,24(sp)
    80002542:	6b42                	ld	s6,16(sp)
    80002544:	6ba2                	ld	s7,8(sp)
    80002546:	6c02                	ld	s8,0(sp)
    80002548:	6161                	addi	sp,sp,80
    8000254a:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000254c:	85e2                	mv	a1,s8
    8000254e:	854a                	mv	a0,s2
    80002550:	00000097          	auipc	ra,0x0
    80002554:	e7e080e7          	jalr	-386(ra) # 800023ce <sleep>
    havekids = 0;
    80002558:	b715                	j	8000247c <wait+0x4a>

000000008000255a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000255a:	7139                	addi	sp,sp,-64
    8000255c:	fc06                	sd	ra,56(sp)
    8000255e:	f822                	sd	s0,48(sp)
    80002560:	f426                	sd	s1,40(sp)
    80002562:	f04a                	sd	s2,32(sp)
    80002564:	ec4e                	sd	s3,24(sp)
    80002566:	e852                	sd	s4,16(sp)
    80002568:	e456                	sd	s5,8(sp)
    8000256a:	0080                	addi	s0,sp,64
    8000256c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000256e:	0000f497          	auipc	s1,0xf
    80002572:	59248493          	addi	s1,s1,1426 # 80011b00 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002576:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002578:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000257a:	00015917          	auipc	s2,0x15
    8000257e:	38690913          	addi	s2,s2,902 # 80017900 <tickslock>
    80002582:	a811                	j	80002596 <wakeup+0x3c>
        //Leyuan & Lee
        enqueue(p);
      }
      release(&p->lock);
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	6f0080e7          	jalr	1776(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000258e:	17848493          	addi	s1,s1,376
    80002592:	03248b63          	beq	s1,s2,800025c8 <wakeup+0x6e>
    if (p != myproc())
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	5e2080e7          	jalr	1506(ra) # 80001b78 <myproc>
    8000259e:	fea488e3          	beq	s1,a0,8000258e <wakeup+0x34>
      acquire(&p->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	61e080e7          	jalr	1566(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800025ac:	4c9c                	lw	a5,24(s1)
    800025ae:	fd379be3          	bne	a5,s3,80002584 <wakeup+0x2a>
    800025b2:	709c                	ld	a5,32(s1)
    800025b4:	fd4798e3          	bne	a5,s4,80002584 <wakeup+0x2a>
        p->state = RUNNABLE;
    800025b8:	0154ac23          	sw	s5,24(s1)
        enqueue(p);
    800025bc:	8526                	mv	a0,s1
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	24e080e7          	jalr	590(ra) # 8000180c <enqueue>
    800025c6:	bf7d                	j	80002584 <wakeup+0x2a>
    }
  }
}
    800025c8:	70e2                	ld	ra,56(sp)
    800025ca:	7442                	ld	s0,48(sp)
    800025cc:	74a2                	ld	s1,40(sp)
    800025ce:	7902                	ld	s2,32(sp)
    800025d0:	69e2                	ld	s3,24(sp)
    800025d2:	6a42                	ld	s4,16(sp)
    800025d4:	6aa2                	ld	s5,8(sp)
    800025d6:	6121                	addi	sp,sp,64
    800025d8:	8082                	ret

00000000800025da <reparent>:
{
    800025da:	7179                	addi	sp,sp,-48
    800025dc:	f406                	sd	ra,40(sp)
    800025de:	f022                	sd	s0,32(sp)
    800025e0:	ec26                	sd	s1,24(sp)
    800025e2:	e84a                	sd	s2,16(sp)
    800025e4:	e44e                	sd	s3,8(sp)
    800025e6:	e052                	sd	s4,0(sp)
    800025e8:	1800                	addi	s0,sp,48
    800025ea:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025ec:	0000f497          	auipc	s1,0xf
    800025f0:	51448493          	addi	s1,s1,1300 # 80011b00 <proc>
      pp->parent = initproc;
    800025f4:	00007a17          	auipc	s4,0x7
    800025f8:	a34a0a13          	addi	s4,s4,-1484 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025fc:	00015997          	auipc	s3,0x15
    80002600:	30498993          	addi	s3,s3,772 # 80017900 <tickslock>
    80002604:	a029                	j	8000260e <reparent+0x34>
    80002606:	17848493          	addi	s1,s1,376
    8000260a:	01348d63          	beq	s1,s3,80002624 <reparent+0x4a>
    if (pp->parent == p)
    8000260e:	7c9c                	ld	a5,56(s1)
    80002610:	ff279be3          	bne	a5,s2,80002606 <reparent+0x2c>
      pp->parent = initproc;
    80002614:	000a3503          	ld	a0,0(s4)
    80002618:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000261a:	00000097          	auipc	ra,0x0
    8000261e:	f40080e7          	jalr	-192(ra) # 8000255a <wakeup>
    80002622:	b7d5                	j	80002606 <reparent+0x2c>
}
    80002624:	70a2                	ld	ra,40(sp)
    80002626:	7402                	ld	s0,32(sp)
    80002628:	64e2                	ld	s1,24(sp)
    8000262a:	6942                	ld	s2,16(sp)
    8000262c:	69a2                	ld	s3,8(sp)
    8000262e:	6a02                	ld	s4,0(sp)
    80002630:	6145                	addi	sp,sp,48
    80002632:	8082                	ret

0000000080002634 <exit>:
{
    80002634:	7179                	addi	sp,sp,-48
    80002636:	f406                	sd	ra,40(sp)
    80002638:	f022                	sd	s0,32(sp)
    8000263a:	ec26                	sd	s1,24(sp)
    8000263c:	e84a                	sd	s2,16(sp)
    8000263e:	e44e                	sd	s3,8(sp)
    80002640:	e052                	sd	s4,0(sp)
    80002642:	1800                	addi	s0,sp,48
    80002644:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	532080e7          	jalr	1330(ra) # 80001b78 <myproc>
    8000264e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002650:	00007797          	auipc	a5,0x7
    80002654:	9d87b783          	ld	a5,-1576(a5) # 80009028 <initproc>
    80002658:	0d050493          	addi	s1,a0,208
    8000265c:	15050913          	addi	s2,a0,336
    80002660:	02a79363          	bne	a5,a0,80002686 <exit+0x52>
    panic("init exiting");
    80002664:	00006517          	auipc	a0,0x6
    80002668:	cc450513          	addi	a0,a0,-828 # 80008328 <digits+0x2e8>
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	ebe080e7          	jalr	-322(ra) # 8000052a <panic>
      fileclose(f);
    80002674:	00002097          	auipc	ra,0x2
    80002678:	230080e7          	jalr	560(ra) # 800048a4 <fileclose>
      p->ofile[fd] = 0;
    8000267c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002680:	04a1                	addi	s1,s1,8
    80002682:	01248563          	beq	s1,s2,8000268c <exit+0x58>
    if (p->ofile[fd])
    80002686:	6088                	ld	a0,0(s1)
    80002688:	f575                	bnez	a0,80002674 <exit+0x40>
    8000268a:	bfdd                	j	80002680 <exit+0x4c>
  begin_op();
    8000268c:	00002097          	auipc	ra,0x2
    80002690:	d4c080e7          	jalr	-692(ra) # 800043d8 <begin_op>
  iput(p->cwd);
    80002694:	1509b503          	ld	a0,336(s3)
    80002698:	00001097          	auipc	ra,0x1
    8000269c:	528080e7          	jalr	1320(ra) # 80003bc0 <iput>
  end_op();
    800026a0:	00002097          	auipc	ra,0x2
    800026a4:	db8080e7          	jalr	-584(ra) # 80004458 <end_op>
  p->cwd = 0;
    800026a8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026ac:	0000f497          	auipc	s1,0xf
    800026b0:	03c48493          	addi	s1,s1,60 # 800116e8 <wait_lock>
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	50c080e7          	jalr	1292(ra) # 80000bc2 <acquire>
  reparent(p);
    800026be:	854e                	mv	a0,s3
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	f1a080e7          	jalr	-230(ra) # 800025da <reparent>
  wakeup(p->parent);
    800026c8:	0389b503          	ld	a0,56(s3)
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	e8e080e7          	jalr	-370(ra) # 8000255a <wakeup>
  acquire(&p->lock);
    800026d4:	854e                	mv	a0,s3
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	4ec080e7          	jalr	1260(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800026de:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026e2:	4795                	li	a5,5
    800026e4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800026e8:	8526                	mv	a0,s1
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	58c080e7          	jalr	1420(ra) # 80000c76 <release>
  sched();
    800026f2:	00000097          	auipc	ra,0x0
    800026f6:	a42080e7          	jalr	-1470(ra) # 80002134 <sched>
  panic("zombie exit");
    800026fa:	00006517          	auipc	a0,0x6
    800026fe:	c3e50513          	addi	a0,a0,-962 # 80008338 <digits+0x2f8>
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	e28080e7          	jalr	-472(ra) # 8000052a <panic>

000000008000270a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000270a:	7179                	addi	sp,sp,-48
    8000270c:	f406                	sd	ra,40(sp)
    8000270e:	f022                	sd	s0,32(sp)
    80002710:	ec26                	sd	s1,24(sp)
    80002712:	e84a                	sd	s2,16(sp)
    80002714:	e44e                	sd	s3,8(sp)
    80002716:	1800                	addi	s0,sp,48
    80002718:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000271a:	0000f497          	auipc	s1,0xf
    8000271e:	3e648493          	addi	s1,s1,998 # 80011b00 <proc>
    80002722:	00015997          	auipc	s3,0x15
    80002726:	1de98993          	addi	s3,s3,478 # 80017900 <tickslock>
  {
    acquire(&p->lock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	496080e7          	jalr	1174(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002734:	589c                	lw	a5,48(s1)
    80002736:	01278d63          	beq	a5,s2,80002750 <kill+0x46>
        enqueue(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	53a080e7          	jalr	1338(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002744:	17848493          	addi	s1,s1,376
    80002748:	ff3491e3          	bne	s1,s3,8000272a <kill+0x20>
  }
  return -1;
    8000274c:	557d                	li	a0,-1
    8000274e:	a829                	j	80002768 <kill+0x5e>
      p->killed = 1;
    80002750:	4785                	li	a5,1
    80002752:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002754:	4c98                	lw	a4,24(s1)
    80002756:	4789                	li	a5,2
    80002758:	00f70f63          	beq	a4,a5,80002776 <kill+0x6c>
      release(&p->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	518080e7          	jalr	1304(ra) # 80000c76 <release>
      return 0;
    80002766:	4501                	li	a0,0
}
    80002768:	70a2                	ld	ra,40(sp)
    8000276a:	7402                	ld	s0,32(sp)
    8000276c:	64e2                	ld	s1,24(sp)
    8000276e:	6942                	ld	s2,16(sp)
    80002770:	69a2                	ld	s3,8(sp)
    80002772:	6145                	addi	sp,sp,48
    80002774:	8082                	ret
        p->state = RUNNABLE;
    80002776:	478d                	li	a5,3
    80002778:	cc9c                	sw	a5,24(s1)
        enqueue(p);
    8000277a:	8526                	mv	a0,s1
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	090080e7          	jalr	144(ra) # 8000180c <enqueue>
    80002784:	bfe1                	j	8000275c <kill+0x52>

0000000080002786 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002786:	7179                	addi	sp,sp,-48
    80002788:	f406                	sd	ra,40(sp)
    8000278a:	f022                	sd	s0,32(sp)
    8000278c:	ec26                	sd	s1,24(sp)
    8000278e:	e84a                	sd	s2,16(sp)
    80002790:	e44e                	sd	s3,8(sp)
    80002792:	e052                	sd	s4,0(sp)
    80002794:	1800                	addi	s0,sp,48
    80002796:	84aa                	mv	s1,a0
    80002798:	892e                	mv	s2,a1
    8000279a:	89b2                	mv	s3,a2
    8000279c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000279e:	fffff097          	auipc	ra,0xfffff
    800027a2:	3da080e7          	jalr	986(ra) # 80001b78 <myproc>
  if (user_dst)
    800027a6:	c08d                	beqz	s1,800027c8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027a8:	86d2                	mv	a3,s4
    800027aa:	864e                	mv	a2,s3
    800027ac:	85ca                	mv	a1,s2
    800027ae:	6928                	ld	a0,80(a0)
    800027b0:	fffff097          	auipc	ra,0xfffff
    800027b4:	e8e080e7          	jalr	-370(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027b8:	70a2                	ld	ra,40(sp)
    800027ba:	7402                	ld	s0,32(sp)
    800027bc:	64e2                	ld	s1,24(sp)
    800027be:	6942                	ld	s2,16(sp)
    800027c0:	69a2                	ld	s3,8(sp)
    800027c2:	6a02                	ld	s4,0(sp)
    800027c4:	6145                	addi	sp,sp,48
    800027c6:	8082                	ret
    memmove((char *)dst, src, len);
    800027c8:	000a061b          	sext.w	a2,s4
    800027cc:	85ce                	mv	a1,s3
    800027ce:	854a                	mv	a0,s2
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	54a080e7          	jalr	1354(ra) # 80000d1a <memmove>
    return 0;
    800027d8:	8526                	mv	a0,s1
    800027da:	bff9                	j	800027b8 <either_copyout+0x32>

00000000800027dc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027dc:	7179                	addi	sp,sp,-48
    800027de:	f406                	sd	ra,40(sp)
    800027e0:	f022                	sd	s0,32(sp)
    800027e2:	ec26                	sd	s1,24(sp)
    800027e4:	e84a                	sd	s2,16(sp)
    800027e6:	e44e                	sd	s3,8(sp)
    800027e8:	e052                	sd	s4,0(sp)
    800027ea:	1800                	addi	s0,sp,48
    800027ec:	892a                	mv	s2,a0
    800027ee:	84ae                	mv	s1,a1
    800027f0:	89b2                	mv	s3,a2
    800027f2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027f4:	fffff097          	auipc	ra,0xfffff
    800027f8:	384080e7          	jalr	900(ra) # 80001b78 <myproc>
  if (user_src)
    800027fc:	c08d                	beqz	s1,8000281e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027fe:	86d2                	mv	a3,s4
    80002800:	864e                	mv	a2,s3
    80002802:	85ca                	mv	a1,s2
    80002804:	6928                	ld	a0,80(a0)
    80002806:	fffff097          	auipc	ra,0xfffff
    8000280a:	ec4080e7          	jalr	-316(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000280e:	70a2                	ld	ra,40(sp)
    80002810:	7402                	ld	s0,32(sp)
    80002812:	64e2                	ld	s1,24(sp)
    80002814:	6942                	ld	s2,16(sp)
    80002816:	69a2                	ld	s3,8(sp)
    80002818:	6a02                	ld	s4,0(sp)
    8000281a:	6145                	addi	sp,sp,48
    8000281c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000281e:	000a061b          	sext.w	a2,s4
    80002822:	85ce                	mv	a1,s3
    80002824:	854a                	mv	a0,s2
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	4f4080e7          	jalr	1268(ra) # 80000d1a <memmove>
    return 0;
    8000282e:	8526                	mv	a0,s1
    80002830:	bff9                	j	8000280e <either_copyin+0x32>

0000000080002832 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002832:	715d                	addi	sp,sp,-80
    80002834:	e486                	sd	ra,72(sp)
    80002836:	e0a2                	sd	s0,64(sp)
    80002838:	fc26                	sd	s1,56(sp)
    8000283a:	f84a                	sd	s2,48(sp)
    8000283c:	f44e                	sd	s3,40(sp)
    8000283e:	f052                	sd	s4,32(sp)
    80002840:	ec56                	sd	s5,24(sp)
    80002842:	e85a                	sd	s6,16(sp)
    80002844:	e45e                	sd	s7,8(sp)
    80002846:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002848:	00006517          	auipc	a0,0x6
    8000284c:	88050513          	addi	a0,a0,-1920 # 800080c8 <digits+0x88>
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	d24080e7          	jalr	-732(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002858:	0000f497          	auipc	s1,0xf
    8000285c:	40048493          	addi	s1,s1,1024 # 80011c58 <proc+0x158>
    80002860:	00015917          	auipc	s2,0x15
    80002864:	1f890913          	addi	s2,s2,504 # 80017a58 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002868:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000286a:	00006997          	auipc	s3,0x6
    8000286e:	ade98993          	addi	s3,s3,-1314 # 80008348 <digits+0x308>
    printf("%d %s %s", p->pid, state, p->name);
    80002872:	00006a97          	auipc	s5,0x6
    80002876:	adea8a93          	addi	s5,s5,-1314 # 80008350 <digits+0x310>
    printf("\n");
    8000287a:	00006a17          	auipc	s4,0x6
    8000287e:	84ea0a13          	addi	s4,s4,-1970 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002882:	00006b97          	auipc	s7,0x6
    80002886:	b06b8b93          	addi	s7,s7,-1274 # 80008388 <states.0>
    8000288a:	a00d                	j	800028ac <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000288c:	ed86a583          	lw	a1,-296(a3)
    80002890:	8556                	mv	a0,s5
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	ce2080e7          	jalr	-798(ra) # 80000574 <printf>
    printf("\n");
    8000289a:	8552                	mv	a0,s4
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	cd8080e7          	jalr	-808(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028a4:	17848493          	addi	s1,s1,376
    800028a8:	03248163          	beq	s1,s2,800028ca <procdump+0x98>
    if (p->state == UNUSED)
    800028ac:	86a6                	mv	a3,s1
    800028ae:	ec04a783          	lw	a5,-320(s1)
    800028b2:	dbed                	beqz	a5,800028a4 <procdump+0x72>
      state = "???";
    800028b4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b6:	fcfb6be3          	bltu	s6,a5,8000288c <procdump+0x5a>
    800028ba:	1782                	slli	a5,a5,0x20
    800028bc:	9381                	srli	a5,a5,0x20
    800028be:	078e                	slli	a5,a5,0x3
    800028c0:	97de                	add	a5,a5,s7
    800028c2:	6390                	ld	a2,0(a5)
    800028c4:	f661                	bnez	a2,8000288c <procdump+0x5a>
      state = "???";
    800028c6:	864e                	mv	a2,s3
    800028c8:	b7d1                	j	8000288c <procdump+0x5a>
  }
}
    800028ca:	60a6                	ld	ra,72(sp)
    800028cc:	6406                	ld	s0,64(sp)
    800028ce:	74e2                	ld	s1,56(sp)
    800028d0:	7942                	ld	s2,48(sp)
    800028d2:	79a2                	ld	s3,40(sp)
    800028d4:	7a02                	ld	s4,32(sp)
    800028d6:	6ae2                	ld	s5,24(sp)
    800028d8:	6b42                	ld	s6,16(sp)
    800028da:	6ba2                	ld	s7,8(sp)
    800028dc:	6161                	addi	sp,sp,80
    800028de:	8082                	ret

00000000800028e0 <kgetpstat>:

//Leyuan & Lee
uint64 kgetpstat(struct pstat *ps)
{
    800028e0:	1141                	addi	sp,sp,-16
    800028e2:	e422                	sd	s0,8(sp)
    800028e4:	0800                	addi	s0,sp,16
  for (int i = 0; i < NPROC; ++i)
    800028e6:	0000f797          	auipc	a5,0xf
    800028ea:	23278793          	addi	a5,a5,562 # 80011b18 <proc+0x18>
    800028ee:	00015697          	auipc	a3,0x15
    800028f2:	02a68693          	addi	a3,a3,42 # 80017918 <bcache>
  {
    struct proc *p = proc + i;
    ps->inuse[i] = p->state == UNUSED ? 0 : 1;
    800028f6:	4398                	lw	a4,0(a5)
    800028f8:	00e03733          	snez	a4,a4
    800028fc:	c118                	sw	a4,0(a0)
    ps->ticks[i] = p->ticks;
    800028fe:	1507a703          	lw	a4,336(a5)
    80002902:	20e52023          	sw	a4,512(a0)
    ps->pid[i] = p->pid;
    80002906:	4f98                	lw	a4,24(a5)
    80002908:	10e52023          	sw	a4,256(a0)
    ps->queue[i] = p->level - 1;
    8000290c:	1587b703          	ld	a4,344(a5)
    80002910:	377d                	addiw	a4,a4,-1
    80002912:	30e52023          	sw	a4,768(a0)
  for (int i = 0; i < NPROC; ++i)
    80002916:	17878793          	addi	a5,a5,376
    8000291a:	0511                	addi	a0,a0,4
    8000291c:	fcd79de3          	bne	a5,a3,800028f6 <kgetpstat+0x16>
  }
  return 0;
    80002920:	4501                	li	a0,0
    80002922:	6422                	ld	s0,8(sp)
    80002924:	0141                	addi	sp,sp,16
    80002926:	8082                	ret

0000000080002928 <swtch>:
    80002928:	00153023          	sd	ra,0(a0)
    8000292c:	00253423          	sd	sp,8(a0)
    80002930:	e900                	sd	s0,16(a0)
    80002932:	ed04                	sd	s1,24(a0)
    80002934:	03253023          	sd	s2,32(a0)
    80002938:	03353423          	sd	s3,40(a0)
    8000293c:	03453823          	sd	s4,48(a0)
    80002940:	03553c23          	sd	s5,56(a0)
    80002944:	05653023          	sd	s6,64(a0)
    80002948:	05753423          	sd	s7,72(a0)
    8000294c:	05853823          	sd	s8,80(a0)
    80002950:	05953c23          	sd	s9,88(a0)
    80002954:	07a53023          	sd	s10,96(a0)
    80002958:	07b53423          	sd	s11,104(a0)
    8000295c:	0005b083          	ld	ra,0(a1)
    80002960:	0085b103          	ld	sp,8(a1)
    80002964:	6980                	ld	s0,16(a1)
    80002966:	6d84                	ld	s1,24(a1)
    80002968:	0205b903          	ld	s2,32(a1)
    8000296c:	0285b983          	ld	s3,40(a1)
    80002970:	0305ba03          	ld	s4,48(a1)
    80002974:	0385ba83          	ld	s5,56(a1)
    80002978:	0405bb03          	ld	s6,64(a1)
    8000297c:	0485bb83          	ld	s7,72(a1)
    80002980:	0505bc03          	ld	s8,80(a1)
    80002984:	0585bc83          	ld	s9,88(a1)
    80002988:	0605bd03          	ld	s10,96(a1)
    8000298c:	0685bd83          	ld	s11,104(a1)
    80002990:	8082                	ret

0000000080002992 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002992:	1141                	addi	sp,sp,-16
    80002994:	e406                	sd	ra,8(sp)
    80002996:	e022                	sd	s0,0(sp)
    80002998:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000299a:	00006597          	auipc	a1,0x6
    8000299e:	a1e58593          	addi	a1,a1,-1506 # 800083b8 <states.0+0x30>
    800029a2:	00015517          	auipc	a0,0x15
    800029a6:	f5e50513          	addi	a0,a0,-162 # 80017900 <tickslock>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	188080e7          	jalr	392(ra) # 80000b32 <initlock>
}
    800029b2:	60a2                	ld	ra,8(sp)
    800029b4:	6402                	ld	s0,0(sp)
    800029b6:	0141                	addi	sp,sp,16
    800029b8:	8082                	ret

00000000800029ba <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029ba:	1141                	addi	sp,sp,-16
    800029bc:	e422                	sd	s0,8(sp)
    800029be:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c0:	00003797          	auipc	a5,0x3
    800029c4:	51078793          	addi	a5,a5,1296 # 80005ed0 <kernelvec>
    800029c8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029cc:	6422                	ld	s0,8(sp)
    800029ce:	0141                	addi	sp,sp,16
    800029d0:	8082                	ret

00000000800029d2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029d2:	1141                	addi	sp,sp,-16
    800029d4:	e406                	sd	ra,8(sp)
    800029d6:	e022                	sd	s0,0(sp)
    800029d8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	19e080e7          	jalr	414(ra) # 80001b78 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029e6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ec:	00004617          	auipc	a2,0x4
    800029f0:	61460613          	addi	a2,a2,1556 # 80007000 <_trampoline>
    800029f4:	00004697          	auipc	a3,0x4
    800029f8:	60c68693          	addi	a3,a3,1548 # 80007000 <_trampoline>
    800029fc:	8e91                	sub	a3,a3,a2
    800029fe:	040007b7          	lui	a5,0x4000
    80002a02:	17fd                	addi	a5,a5,-1
    80002a04:	07b2                	slli	a5,a5,0xc
    80002a06:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a08:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a0c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a0e:	180026f3          	csrr	a3,satp
    80002a12:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a14:	6d38                	ld	a4,88(a0)
    80002a16:	6134                	ld	a3,64(a0)
    80002a18:	6585                	lui	a1,0x1
    80002a1a:	96ae                	add	a3,a3,a1
    80002a1c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a1e:	6d38                	ld	a4,88(a0)
    80002a20:	00000697          	auipc	a3,0x0
    80002a24:	13868693          	addi	a3,a3,312 # 80002b58 <usertrap>
    80002a28:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a2a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a2c:	8692                	mv	a3,tp
    80002a2e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a34:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a38:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a3c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a40:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a42:	6f18                	ld	a4,24(a4)
    80002a44:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a48:	692c                	ld	a1,80(a0)
    80002a4a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a4c:	00004717          	auipc	a4,0x4
    80002a50:	64470713          	addi	a4,a4,1604 # 80007090 <userret>
    80002a54:	8f11                	sub	a4,a4,a2
    80002a56:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a58:	577d                	li	a4,-1
    80002a5a:	177e                	slli	a4,a4,0x3f
    80002a5c:	8dd9                	or	a1,a1,a4
    80002a5e:	02000537          	lui	a0,0x2000
    80002a62:	157d                	addi	a0,a0,-1
    80002a64:	0536                	slli	a0,a0,0xd
    80002a66:	9782                	jalr	a5
}
    80002a68:	60a2                	ld	ra,8(sp)
    80002a6a:	6402                	ld	s0,0(sp)
    80002a6c:	0141                	addi	sp,sp,16
    80002a6e:	8082                	ret

0000000080002a70 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a7a:	00015497          	auipc	s1,0x15
    80002a7e:	e8648493          	addi	s1,s1,-378 # 80017900 <tickslock>
    80002a82:	8526                	mv	a0,s1
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	13e080e7          	jalr	318(ra) # 80000bc2 <acquire>
  ticks++;
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	5a850513          	addi	a0,a0,1448 # 80009034 <ticks>
    80002a94:	411c                	lw	a5,0(a0)
    80002a96:	2785                	addiw	a5,a5,1
    80002a98:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	ac0080e7          	jalr	-1344(ra) # 8000255a <wakeup>
  release(&tickslock);
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	1d2080e7          	jalr	466(ra) # 80000c76 <release>
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret

0000000080002ab6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ab6:	1101                	addi	sp,sp,-32
    80002ab8:	ec06                	sd	ra,24(sp)
    80002aba:	e822                	sd	s0,16(sp)
    80002abc:	e426                	sd	s1,8(sp)
    80002abe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ac4:	00074d63          	bltz	a4,80002ade <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ac8:	57fd                	li	a5,-1
    80002aca:	17fe                	slli	a5,a5,0x3f
    80002acc:	0785                	addi	a5,a5,1
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    
    return 0;
    80002ace:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ad0:	06f70363          	beq	a4,a5,80002b36 <devintr+0x80>
  }
}
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	64a2                	ld	s1,8(sp)
    80002ada:	6105                	addi	sp,sp,32
    80002adc:	8082                	ret
     (scause & 0xff) == 9){
    80002ade:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ae2:	46a5                	li	a3,9
    80002ae4:	fed792e3          	bne	a5,a3,80002ac8 <devintr+0x12>
    int irq = plic_claim();
    80002ae8:	00003097          	auipc	ra,0x3
    80002aec:	4f0080e7          	jalr	1264(ra) # 80005fd8 <plic_claim>
    80002af0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002af2:	47a9                	li	a5,10
    80002af4:	02f50763          	beq	a0,a5,80002b22 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002af8:	4785                	li	a5,1
    80002afa:	02f50963          	beq	a0,a5,80002b2c <devintr+0x76>
    return 1;
    80002afe:	4505                	li	a0,1
    } else if(irq){
    80002b00:	d8f1                	beqz	s1,80002ad4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b02:	85a6                	mv	a1,s1
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	8bc50513          	addi	a0,a0,-1860 # 800083c0 <states.0+0x38>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a68080e7          	jalr	-1432(ra) # 80000574 <printf>
      plic_complete(irq);
    80002b14:	8526                	mv	a0,s1
    80002b16:	00003097          	auipc	ra,0x3
    80002b1a:	4e6080e7          	jalr	1254(ra) # 80005ffc <plic_complete>
    return 1;
    80002b1e:	4505                	li	a0,1
    80002b20:	bf55                	j	80002ad4 <devintr+0x1e>
      uartintr();
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	e64080e7          	jalr	-412(ra) # 80000986 <uartintr>
    80002b2a:	b7ed                	j	80002b14 <devintr+0x5e>
      virtio_disk_intr();
    80002b2c:	00004097          	auipc	ra,0x4
    80002b30:	962080e7          	jalr	-1694(ra) # 8000648e <virtio_disk_intr>
    80002b34:	b7c5                	j	80002b14 <devintr+0x5e>
    if(cpuid() == 0){
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	016080e7          	jalr	22(ra) # 80001b4c <cpuid>
    80002b3e:	c901                	beqz	a0,80002b4e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b40:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b44:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b46:	14479073          	csrw	sip,a5
    return 2;
    80002b4a:	4509                	li	a0,2
    80002b4c:	b761                	j	80002ad4 <devintr+0x1e>
      clockintr();
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	f22080e7          	jalr	-222(ra) # 80002a70 <clockintr>
    80002b56:	b7ed                	j	80002b40 <devintr+0x8a>

0000000080002b58 <usertrap>:
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	e04a                	sd	s2,0(sp)
    80002b62:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b64:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b68:	1007f793          	andi	a5,a5,256
    80002b6c:	e3ad                	bnez	a5,80002bce <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b6e:	00003797          	auipc	a5,0x3
    80002b72:	36278793          	addi	a5,a5,866 # 80005ed0 <kernelvec>
    80002b76:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	ffe080e7          	jalr	-2(ra) # 80001b78 <myproc>
    80002b82:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b84:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b86:	14102773          	csrr	a4,sepc
    80002b8a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b90:	47a1                	li	a5,8
    80002b92:	04f71c63          	bne	a4,a5,80002bea <usertrap+0x92>
    if(p->killed)
    80002b96:	551c                	lw	a5,40(a0)
    80002b98:	e3b9                	bnez	a5,80002bde <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b9a:	6cb8                	ld	a4,88(s1)
    80002b9c:	6f1c                	ld	a5,24(a4)
    80002b9e:	0791                	addi	a5,a5,4
    80002ba0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ba6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002baa:	10079073          	csrw	sstatus,a5
    syscall();
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	2e0080e7          	jalr	736(ra) # 80002e8e <syscall>
  if(p->killed)
    80002bb6:	549c                	lw	a5,40(s1)
    80002bb8:	ebc1                	bnez	a5,80002c48 <usertrap+0xf0>
  usertrapret();
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	e18080e7          	jalr	-488(ra) # 800029d2 <usertrapret>
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6902                	ld	s2,0(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret
    panic("usertrap: not from user mode");
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	81250513          	addi	a0,a0,-2030 # 800083e0 <states.0+0x58>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	954080e7          	jalr	-1708(ra) # 8000052a <panic>
      exit(-1);
    80002bde:	557d                	li	a0,-1
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	a54080e7          	jalr	-1452(ra) # 80002634 <exit>
    80002be8:	bf4d                	j	80002b9a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	ecc080e7          	jalr	-308(ra) # 80002ab6 <devintr>
    80002bf2:	892a                	mv	s2,a0
    80002bf4:	c501                	beqz	a0,80002bfc <usertrap+0xa4>
  if(p->killed)
    80002bf6:	549c                	lw	a5,40(s1)
    80002bf8:	c3a1                	beqz	a5,80002c38 <usertrap+0xe0>
    80002bfa:	a815                	j	80002c2e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bfc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c00:	5890                	lw	a2,48(s1)
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	7fe50513          	addi	a0,a0,2046 # 80008400 <states.0+0x78>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	96a080e7          	jalr	-1686(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c16:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c1a:	00006517          	auipc	a0,0x6
    80002c1e:	81650513          	addi	a0,a0,-2026 # 80008430 <states.0+0xa8>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	952080e7          	jalr	-1710(ra) # 80000574 <printf>
    p->killed = 1;
    80002c2a:	4785                	li	a5,1
    80002c2c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c2e:	557d                	li	a0,-1
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	a04080e7          	jalr	-1532(ra) # 80002634 <exit>
  if(which_dev == 2)
    80002c38:	4789                	li	a5,2
    80002c3a:	f8f910e3          	bne	s2,a5,80002bba <usertrap+0x62>
    yield();
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	5cc080e7          	jalr	1484(ra) # 8000220a <yield>
    80002c46:	bf95                	j	80002bba <usertrap+0x62>
  int which_dev = 0;
    80002c48:	4901                	li	s2,0
    80002c4a:	b7d5                	j	80002c2e <usertrap+0xd6>

0000000080002c4c <kerneltrap>:
{
    80002c4c:	7179                	addi	sp,sp,-48
    80002c4e:	f406                	sd	ra,40(sp)
    80002c50:	f022                	sd	s0,32(sp)
    80002c52:	ec26                	sd	s1,24(sp)
    80002c54:	e84a                	sd	s2,16(sp)
    80002c56:	e44e                	sd	s3,8(sp)
    80002c58:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c62:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c66:	1004f793          	andi	a5,s1,256
    80002c6a:	cb85                	beqz	a5,80002c9a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c70:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c72:	ef85                	bnez	a5,80002caa <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	e42080e7          	jalr	-446(ra) # 80002ab6 <devintr>
    80002c7c:	cd1d                	beqz	a0,80002cba <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c7e:	4789                	li	a5,2
    80002c80:	06f50a63          	beq	a0,a5,80002cf4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c84:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c88:	10049073          	csrw	sstatus,s1
}
    80002c8c:	70a2                	ld	ra,40(sp)
    80002c8e:	7402                	ld	s0,32(sp)
    80002c90:	64e2                	ld	s1,24(sp)
    80002c92:	6942                	ld	s2,16(sp)
    80002c94:	69a2                	ld	s3,8(sp)
    80002c96:	6145                	addi	sp,sp,48
    80002c98:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c9a:	00005517          	auipc	a0,0x5
    80002c9e:	7b650513          	addi	a0,a0,1974 # 80008450 <states.0+0xc8>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	888080e7          	jalr	-1912(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	7ce50513          	addi	a0,a0,1998 # 80008478 <states.0+0xf0>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	878080e7          	jalr	-1928(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002cba:	85ce                	mv	a1,s3
    80002cbc:	00005517          	auipc	a0,0x5
    80002cc0:	7dc50513          	addi	a0,a0,2012 # 80008498 <states.0+0x110>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	8b0080e7          	jalr	-1872(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ccc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cd0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cd4:	00005517          	auipc	a0,0x5
    80002cd8:	7d450513          	addi	a0,a0,2004 # 800084a8 <states.0+0x120>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	898080e7          	jalr	-1896(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002ce4:	00005517          	auipc	a0,0x5
    80002ce8:	7dc50513          	addi	a0,a0,2012 # 800084c0 <states.0+0x138>
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	83e080e7          	jalr	-1986(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	e84080e7          	jalr	-380(ra) # 80001b78 <myproc>
    80002cfc:	d541                	beqz	a0,80002c84 <kerneltrap+0x38>
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	e7a080e7          	jalr	-390(ra) # 80001b78 <myproc>
    80002d06:	4d18                	lw	a4,24(a0)
    80002d08:	4791                	li	a5,4
    80002d0a:	f6f71de3          	bne	a4,a5,80002c84 <kerneltrap+0x38>
    yield();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	4fc080e7          	jalr	1276(ra) # 8000220a <yield>
    80002d16:	b7bd                	j	80002c84 <kerneltrap+0x38>

0000000080002d18 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	e426                	sd	s1,8(sp)
    80002d20:	1000                	addi	s0,sp,32
    80002d22:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	e54080e7          	jalr	-428(ra) # 80001b78 <myproc>
  switch (n) {
    80002d2c:	4795                	li	a5,5
    80002d2e:	0497e163          	bltu	a5,s1,80002d70 <argraw+0x58>
    80002d32:	048a                	slli	s1,s1,0x2
    80002d34:	00005717          	auipc	a4,0x5
    80002d38:	7c470713          	addi	a4,a4,1988 # 800084f8 <states.0+0x170>
    80002d3c:	94ba                	add	s1,s1,a4
    80002d3e:	409c                	lw	a5,0(s1)
    80002d40:	97ba                	add	a5,a5,a4
    80002d42:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d44:	6d3c                	ld	a5,88(a0)
    80002d46:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret
    return p->trapframe->a1;
    80002d52:	6d3c                	ld	a5,88(a0)
    80002d54:	7fa8                	ld	a0,120(a5)
    80002d56:	bfcd                	j	80002d48 <argraw+0x30>
    return p->trapframe->a2;
    80002d58:	6d3c                	ld	a5,88(a0)
    80002d5a:	63c8                	ld	a0,128(a5)
    80002d5c:	b7f5                	j	80002d48 <argraw+0x30>
    return p->trapframe->a3;
    80002d5e:	6d3c                	ld	a5,88(a0)
    80002d60:	67c8                	ld	a0,136(a5)
    80002d62:	b7dd                	j	80002d48 <argraw+0x30>
    return p->trapframe->a4;
    80002d64:	6d3c                	ld	a5,88(a0)
    80002d66:	6bc8                	ld	a0,144(a5)
    80002d68:	b7c5                	j	80002d48 <argraw+0x30>
    return p->trapframe->a5;
    80002d6a:	6d3c                	ld	a5,88(a0)
    80002d6c:	6fc8                	ld	a0,152(a5)
    80002d6e:	bfe9                	j	80002d48 <argraw+0x30>
  panic("argraw");
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	76050513          	addi	a0,a0,1888 # 800084d0 <states.0+0x148>
    80002d78:	ffffd097          	auipc	ra,0xffffd
    80002d7c:	7b2080e7          	jalr	1970(ra) # 8000052a <panic>

0000000080002d80 <fetchaddr>:
{
    80002d80:	1101                	addi	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	e426                	sd	s1,8(sp)
    80002d88:	e04a                	sd	s2,0(sp)
    80002d8a:	1000                	addi	s0,sp,32
    80002d8c:	84aa                	mv	s1,a0
    80002d8e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	de8080e7          	jalr	-536(ra) # 80001b78 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d98:	653c                	ld	a5,72(a0)
    80002d9a:	02f4f863          	bgeu	s1,a5,80002dca <fetchaddr+0x4a>
    80002d9e:	00848713          	addi	a4,s1,8
    80002da2:	02e7e663          	bltu	a5,a4,80002dce <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002da6:	46a1                	li	a3,8
    80002da8:	8626                	mv	a2,s1
    80002daa:	85ca                	mv	a1,s2
    80002dac:	6928                	ld	a0,80(a0)
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	91c080e7          	jalr	-1764(ra) # 800016ca <copyin>
    80002db6:	00a03533          	snez	a0,a0
    80002dba:	40a00533          	neg	a0,a0
}
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	64a2                	ld	s1,8(sp)
    80002dc4:	6902                	ld	s2,0(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret
    return -1;
    80002dca:	557d                	li	a0,-1
    80002dcc:	bfcd                	j	80002dbe <fetchaddr+0x3e>
    80002dce:	557d                	li	a0,-1
    80002dd0:	b7fd                	j	80002dbe <fetchaddr+0x3e>

0000000080002dd2 <fetchstr>:
{
    80002dd2:	7179                	addi	sp,sp,-48
    80002dd4:	f406                	sd	ra,40(sp)
    80002dd6:	f022                	sd	s0,32(sp)
    80002dd8:	ec26                	sd	s1,24(sp)
    80002dda:	e84a                	sd	s2,16(sp)
    80002ddc:	e44e                	sd	s3,8(sp)
    80002dde:	1800                	addi	s0,sp,48
    80002de0:	892a                	mv	s2,a0
    80002de2:	84ae                	mv	s1,a1
    80002de4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	d92080e7          	jalr	-622(ra) # 80001b78 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dee:	86ce                	mv	a3,s3
    80002df0:	864a                	mv	a2,s2
    80002df2:	85a6                	mv	a1,s1
    80002df4:	6928                	ld	a0,80(a0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	962080e7          	jalr	-1694(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002dfe:	00054763          	bltz	a0,80002e0c <fetchstr+0x3a>
  return strlen(buf);
    80002e02:	8526                	mv	a0,s1
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	03e080e7          	jalr	62(ra) # 80000e42 <strlen>
}
    80002e0c:	70a2                	ld	ra,40(sp)
    80002e0e:	7402                	ld	s0,32(sp)
    80002e10:	64e2                	ld	s1,24(sp)
    80002e12:	6942                	ld	s2,16(sp)
    80002e14:	69a2                	ld	s3,8(sp)
    80002e16:	6145                	addi	sp,sp,48
    80002e18:	8082                	ret

0000000080002e1a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	1000                	addi	s0,sp,32
    80002e24:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	ef2080e7          	jalr	-270(ra) # 80002d18 <argraw>
    80002e2e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e30:	4501                	li	a0,0
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	e426                	sd	s1,8(sp)
    80002e44:	1000                	addi	s0,sp,32
    80002e46:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	ed0080e7          	jalr	-304(ra) # 80002d18 <argraw>
    80002e50:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e52:	4501                	li	a0,0
    80002e54:	60e2                	ld	ra,24(sp)
    80002e56:	6442                	ld	s0,16(sp)
    80002e58:	64a2                	ld	s1,8(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e5e:	1101                	addi	sp,sp,-32
    80002e60:	ec06                	sd	ra,24(sp)
    80002e62:	e822                	sd	s0,16(sp)
    80002e64:	e426                	sd	s1,8(sp)
    80002e66:	e04a                	sd	s2,0(sp)
    80002e68:	1000                	addi	s0,sp,32
    80002e6a:	84ae                	mv	s1,a1
    80002e6c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	eaa080e7          	jalr	-342(ra) # 80002d18 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e76:	864a                	mv	a2,s2
    80002e78:	85a6                	mv	a1,s1
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	f58080e7          	jalr	-168(ra) # 80002dd2 <fetchstr>
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6902                	ld	s2,0(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret

0000000080002e8e <syscall>:

};

void
syscall(void)
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	e426                	sd	s1,8(sp)
    80002e96:	e04a                	sd	s2,0(sp)
    80002e98:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	cde080e7          	jalr	-802(ra) # 80001b78 <myproc>
    80002ea2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ea4:	05853903          	ld	s2,88(a0)
    80002ea8:	0a893783          	ld	a5,168(s2)
    80002eac:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eb0:	37fd                	addiw	a5,a5,-1
    80002eb2:	4755                	li	a4,21
    80002eb4:	00f76f63          	bltu	a4,a5,80002ed2 <syscall+0x44>
    80002eb8:	00369713          	slli	a4,a3,0x3
    80002ebc:	00005797          	auipc	a5,0x5
    80002ec0:	65478793          	addi	a5,a5,1620 # 80008510 <syscalls>
    80002ec4:	97ba                	add	a5,a5,a4
    80002ec6:	639c                	ld	a5,0(a5)
    80002ec8:	c789                	beqz	a5,80002ed2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002eca:	9782                	jalr	a5
    80002ecc:	06a93823          	sd	a0,112(s2)
    80002ed0:	a839                	j	80002eee <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ed2:	15848613          	addi	a2,s1,344
    80002ed6:	588c                	lw	a1,48(s1)
    80002ed8:	00005517          	auipc	a0,0x5
    80002edc:	60050513          	addi	a0,a0,1536 # 800084d8 <states.0+0x150>
    80002ee0:	ffffd097          	auipc	ra,0xffffd
    80002ee4:	694080e7          	jalr	1684(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee8:	6cbc                	ld	a5,88(s1)
    80002eea:	577d                	li	a4,-1
    80002eec:	fbb8                	sd	a4,112(a5)
  }
}
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	64a2                	ld	s1,8(sp)
    80002ef4:	6902                	ld	s2,0(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret

0000000080002efa <sys_exit>:
#include "proc.h"
#include "pstat.h"

uint64
sys_exit(void)
{
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f02:	fec40593          	addi	a1,s0,-20
    80002f06:	4501                	li	a0,0
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	f12080e7          	jalr	-238(ra) # 80002e1a <argint>
    return -1;
    80002f10:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f12:	00054963          	bltz	a0,80002f24 <sys_exit+0x2a>
  exit(n);
    80002f16:	fec42503          	lw	a0,-20(s0)
    80002f1a:	fffff097          	auipc	ra,0xfffff
    80002f1e:	71a080e7          	jalr	1818(ra) # 80002634 <exit>
  return 0;  // not reached
    80002f22:	4781                	li	a5,0
}
    80002f24:	853e                	mv	a0,a5
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret

0000000080002f2e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f2e:	1141                	addi	sp,sp,-16
    80002f30:	e406                	sd	ra,8(sp)
    80002f32:	e022                	sd	s0,0(sp)
    80002f34:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	c42080e7          	jalr	-958(ra) # 80001b78 <myproc>
}
    80002f3e:	5908                	lw	a0,48(a0)
    80002f40:	60a2                	ld	ra,8(sp)
    80002f42:	6402                	ld	s0,0(sp)
    80002f44:	0141                	addi	sp,sp,16
    80002f46:	8082                	ret

0000000080002f48 <sys_fork>:

uint64
sys_fork(void)
{
    80002f48:	1141                	addi	sp,sp,-16
    80002f4a:	e406                	sd	ra,8(sp)
    80002f4c:	e022                	sd	s0,0(sp)
    80002f4e:	0800                	addi	s0,sp,16
  return fork();
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	016080e7          	jalr	22(ra) # 80001f66 <fork>
}
    80002f58:	60a2                	ld	ra,8(sp)
    80002f5a:	6402                	ld	s0,0(sp)
    80002f5c:	0141                	addi	sp,sp,16
    80002f5e:	8082                	ret

0000000080002f60 <sys_wait>:

uint64
sys_wait(void)
{
    80002f60:	1101                	addi	sp,sp,-32
    80002f62:	ec06                	sd	ra,24(sp)
    80002f64:	e822                	sd	s0,16(sp)
    80002f66:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f68:	fe840593          	addi	a1,s0,-24
    80002f6c:	4501                	li	a0,0
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	ece080e7          	jalr	-306(ra) # 80002e3c <argaddr>
    80002f76:	87aa                	mv	a5,a0
    return -1;
    80002f78:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f7a:	0007c863          	bltz	a5,80002f8a <sys_wait+0x2a>
  return wait(p);
    80002f7e:	fe843503          	ld	a0,-24(s0)
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	4b0080e7          	jalr	1200(ra) # 80002432 <wait>
}
    80002f8a:	60e2                	ld	ra,24(sp)
    80002f8c:	6442                	ld	s0,16(sp)
    80002f8e:	6105                	addi	sp,sp,32
    80002f90:	8082                	ret

0000000080002f92 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f92:	7179                	addi	sp,sp,-48
    80002f94:	f406                	sd	ra,40(sp)
    80002f96:	f022                	sd	s0,32(sp)
    80002f98:	ec26                	sd	s1,24(sp)
    80002f9a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f9c:	fdc40593          	addi	a1,s0,-36
    80002fa0:	4501                	li	a0,0
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	e78080e7          	jalr	-392(ra) # 80002e1a <argint>
    return -1;
    80002faa:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fac:	00054f63          	bltz	a0,80002fca <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	bc8080e7          	jalr	-1080(ra) # 80001b78 <myproc>
    80002fb8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fba:	fdc42503          	lw	a0,-36(s0)
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	f34080e7          	jalr	-204(ra) # 80001ef2 <growproc>
    80002fc6:	00054863          	bltz	a0,80002fd6 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fca:	8526                	mv	a0,s1
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6145                	addi	sp,sp,48
    80002fd4:	8082                	ret
    return -1;
    80002fd6:	54fd                	li	s1,-1
    80002fd8:	bfcd                	j	80002fca <sys_sbrk+0x38>

0000000080002fda <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fda:	7139                	addi	sp,sp,-64
    80002fdc:	fc06                	sd	ra,56(sp)
    80002fde:	f822                	sd	s0,48(sp)
    80002fe0:	f426                	sd	s1,40(sp)
    80002fe2:	f04a                	sd	s2,32(sp)
    80002fe4:	ec4e                	sd	s3,24(sp)
    80002fe6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fe8:	fcc40593          	addi	a1,s0,-52
    80002fec:	4501                	li	a0,0
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	e2c080e7          	jalr	-468(ra) # 80002e1a <argint>
    return -1;
    80002ff6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ff8:	06054563          	bltz	a0,80003062 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ffc:	00015517          	auipc	a0,0x15
    80003000:	90450513          	addi	a0,a0,-1788 # 80017900 <tickslock>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	bbe080e7          	jalr	-1090(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000300c:	00006917          	auipc	s2,0x6
    80003010:	02892903          	lw	s2,40(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    80003014:	fcc42783          	lw	a5,-52(s0)
    80003018:	cf85                	beqz	a5,80003050 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000301a:	00015997          	auipc	s3,0x15
    8000301e:	8e698993          	addi	s3,s3,-1818 # 80017900 <tickslock>
    80003022:	00006497          	auipc	s1,0x6
    80003026:	01248493          	addi	s1,s1,18 # 80009034 <ticks>
    if(myproc()->killed){
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	b4e080e7          	jalr	-1202(ra) # 80001b78 <myproc>
    80003032:	551c                	lw	a5,40(a0)
    80003034:	ef9d                	bnez	a5,80003072 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003036:	85ce                	mv	a1,s3
    80003038:	8526                	mv	a0,s1
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	394080e7          	jalr	916(ra) # 800023ce <sleep>
  while(ticks - ticks0 < n){
    80003042:	409c                	lw	a5,0(s1)
    80003044:	412787bb          	subw	a5,a5,s2
    80003048:	fcc42703          	lw	a4,-52(s0)
    8000304c:	fce7efe3          	bltu	a5,a4,8000302a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003050:	00015517          	auipc	a0,0x15
    80003054:	8b050513          	addi	a0,a0,-1872 # 80017900 <tickslock>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c1e080e7          	jalr	-994(ra) # 80000c76 <release>
  return 0;
    80003060:	4781                	li	a5,0
}
    80003062:	853e                	mv	a0,a5
    80003064:	70e2                	ld	ra,56(sp)
    80003066:	7442                	ld	s0,48(sp)
    80003068:	74a2                	ld	s1,40(sp)
    8000306a:	7902                	ld	s2,32(sp)
    8000306c:	69e2                	ld	s3,24(sp)
    8000306e:	6121                	addi	sp,sp,64
    80003070:	8082                	ret
      release(&tickslock);
    80003072:	00015517          	auipc	a0,0x15
    80003076:	88e50513          	addi	a0,a0,-1906 # 80017900 <tickslock>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	bfc080e7          	jalr	-1028(ra) # 80000c76 <release>
      return -1;
    80003082:	57fd                	li	a5,-1
    80003084:	bff9                	j	80003062 <sys_sleep+0x88>

0000000080003086 <sys_kill>:

uint64
sys_kill(void)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000308e:	fec40593          	addi	a1,s0,-20
    80003092:	4501                	li	a0,0
    80003094:	00000097          	auipc	ra,0x0
    80003098:	d86080e7          	jalr	-634(ra) # 80002e1a <argint>
    8000309c:	87aa                	mv	a5,a0
    return -1;
    8000309e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030a0:	0007c863          	bltz	a5,800030b0 <sys_kill+0x2a>
  return kill(pid);
    800030a4:	fec42503          	lw	a0,-20(s0)
    800030a8:	fffff097          	auipc	ra,0xfffff
    800030ac:	662080e7          	jalr	1634(ra) # 8000270a <kill>
}
    800030b0:	60e2                	ld	ra,24(sp)
    800030b2:	6442                	ld	s0,16(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret

00000000800030b8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030b8:	1101                	addi	sp,sp,-32
    800030ba:	ec06                	sd	ra,24(sp)
    800030bc:	e822                	sd	s0,16(sp)
    800030be:	e426                	sd	s1,8(sp)
    800030c0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030c2:	00015517          	auipc	a0,0x15
    800030c6:	83e50513          	addi	a0,a0,-1986 # 80017900 <tickslock>
    800030ca:	ffffe097          	auipc	ra,0xffffe
    800030ce:	af8080e7          	jalr	-1288(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800030d2:	00006497          	auipc	s1,0x6
    800030d6:	f624a483          	lw	s1,-158(s1) # 80009034 <ticks>
  release(&tickslock);
    800030da:	00015517          	auipc	a0,0x15
    800030de:	82650513          	addi	a0,a0,-2010 # 80017900 <tickslock>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	b94080e7          	jalr	-1132(ra) # 80000c76 <release>
  return xticks;
}
    800030ea:	02049513          	slli	a0,s1,0x20
    800030ee:	9101                	srli	a0,a0,0x20
    800030f0:	60e2                	ld	ra,24(sp)
    800030f2:	6442                	ld	s0,16(sp)
    800030f4:	64a2                	ld	s1,8(sp)
    800030f6:	6105                	addi	sp,sp,32
    800030f8:	8082                	ret

00000000800030fa <sys_getpstat>:

// Leyuan & Lee
//Added new sys call
uint64
sys_getpstat(void)
{
    800030fa:	bd010113          	addi	sp,sp,-1072
    800030fe:	42113423          	sd	ra,1064(sp)
    80003102:	42813023          	sd	s0,1056(sp)
    80003106:	40913c23          	sd	s1,1048(sp)
    8000310a:	41213823          	sd	s2,1040(sp)
    8000310e:	43010413          	addi	s0,sp,1072
  struct proc *p = myproc();
    80003112:	fffff097          	auipc	ra,0xfffff
    80003116:	a66080e7          	jalr	-1434(ra) # 80001b78 <myproc>
    8000311a:	892a                	mv	s2,a0
  uint64 upstat; // user virtual address, pointing to a struct pstat
  struct pstat kpstat; // struct pstat in kernel memory

  // get system call argument
  if(argaddr(0, &upstat) < 0)
    8000311c:	fd840593          	addi	a1,s0,-40
    80003120:	4501                	li	a0,0
    80003122:	00000097          	auipc	ra,0x0
    80003126:	d1a080e7          	jalr	-742(ra) # 80002e3c <argaddr>
    return -1;
    8000312a:	54fd                	li	s1,-1
  if(argaddr(0, &upstat) < 0)
    8000312c:	02054763          	bltz	a0,8000315a <sys_getpstat+0x60>
  
 // TODO: define kernel side kgetpstat(struct pstat* ps), its purpose is to fill the values into kpstat.
  uint64 result = kgetpstat(&kpstat);
    80003130:	bd840513          	addi	a0,s0,-1064
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	7ac080e7          	jalr	1964(ra) # 800028e0 <kgetpstat>
    8000313c:	84aa                	mv	s1,a0

  // copy pstat from kernel memory to user memory
  if(copyout(p->pagetable, upstat, (char *)&kpstat, sizeof(kpstat)) < 0)
    8000313e:	40000693          	li	a3,1024
    80003142:	bd840613          	addi	a2,s0,-1064
    80003146:	fd843583          	ld	a1,-40(s0)
    8000314a:	05093503          	ld	a0,80(s2)
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	4f0080e7          	jalr	1264(ra) # 8000163e <copyout>
    80003156:	00054e63          	bltz	a0,80003172 <sys_getpstat+0x78>
    return -1;
  return result;
    8000315a:	8526                	mv	a0,s1
    8000315c:	42813083          	ld	ra,1064(sp)
    80003160:	42013403          	ld	s0,1056(sp)
    80003164:	41813483          	ld	s1,1048(sp)
    80003168:	41013903          	ld	s2,1040(sp)
    8000316c:	43010113          	addi	sp,sp,1072
    80003170:	8082                	ret
    return -1;
    80003172:	54fd                	li	s1,-1
    80003174:	b7dd                	j	8000315a <sys_getpstat+0x60>

0000000080003176 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003176:	7179                	addi	sp,sp,-48
    80003178:	f406                	sd	ra,40(sp)
    8000317a:	f022                	sd	s0,32(sp)
    8000317c:	ec26                	sd	s1,24(sp)
    8000317e:	e84a                	sd	s2,16(sp)
    80003180:	e44e                	sd	s3,8(sp)
    80003182:	e052                	sd	s4,0(sp)
    80003184:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003186:	00005597          	auipc	a1,0x5
    8000318a:	44258593          	addi	a1,a1,1090 # 800085c8 <syscalls+0xb8>
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	78a50513          	addi	a0,a0,1930 # 80017918 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	99c080e7          	jalr	-1636(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000319e:	0001c797          	auipc	a5,0x1c
    800031a2:	77a78793          	addi	a5,a5,1914 # 8001f918 <bcache+0x8000>
    800031a6:	0001d717          	auipc	a4,0x1d
    800031aa:	9da70713          	addi	a4,a4,-1574 # 8001fb80 <bcache+0x8268>
    800031ae:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031b2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031b6:	00014497          	auipc	s1,0x14
    800031ba:	77a48493          	addi	s1,s1,1914 # 80017930 <bcache+0x18>
    b->next = bcache.head.next;
    800031be:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031c0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031c2:	00005a17          	auipc	s4,0x5
    800031c6:	40ea0a13          	addi	s4,s4,1038 # 800085d0 <syscalls+0xc0>
    b->next = bcache.head.next;
    800031ca:	2b893783          	ld	a5,696(s2)
    800031ce:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031d0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031d4:	85d2                	mv	a1,s4
    800031d6:	01048513          	addi	a0,s1,16
    800031da:	00001097          	auipc	ra,0x1
    800031de:	4bc080e7          	jalr	1212(ra) # 80004696 <initsleeplock>
    bcache.head.next->prev = b;
    800031e2:	2b893783          	ld	a5,696(s2)
    800031e6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031e8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ec:	45848493          	addi	s1,s1,1112
    800031f0:	fd349de3          	bne	s1,s3,800031ca <binit+0x54>
  }
}
    800031f4:	70a2                	ld	ra,40(sp)
    800031f6:	7402                	ld	s0,32(sp)
    800031f8:	64e2                	ld	s1,24(sp)
    800031fa:	6942                	ld	s2,16(sp)
    800031fc:	69a2                	ld	s3,8(sp)
    800031fe:	6a02                	ld	s4,0(sp)
    80003200:	6145                	addi	sp,sp,48
    80003202:	8082                	ret

0000000080003204 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003204:	7179                	addi	sp,sp,-48
    80003206:	f406                	sd	ra,40(sp)
    80003208:	f022                	sd	s0,32(sp)
    8000320a:	ec26                	sd	s1,24(sp)
    8000320c:	e84a                	sd	s2,16(sp)
    8000320e:	e44e                	sd	s3,8(sp)
    80003210:	1800                	addi	s0,sp,48
    80003212:	892a                	mv	s2,a0
    80003214:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003216:	00014517          	auipc	a0,0x14
    8000321a:	70250513          	addi	a0,a0,1794 # 80017918 <bcache>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	9a4080e7          	jalr	-1628(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003226:	0001d497          	auipc	s1,0x1d
    8000322a:	9aa4b483          	ld	s1,-1622(s1) # 8001fbd0 <bcache+0x82b8>
    8000322e:	0001d797          	auipc	a5,0x1d
    80003232:	95278793          	addi	a5,a5,-1710 # 8001fb80 <bcache+0x8268>
    80003236:	02f48f63          	beq	s1,a5,80003274 <bread+0x70>
    8000323a:	873e                	mv	a4,a5
    8000323c:	a021                	j	80003244 <bread+0x40>
    8000323e:	68a4                	ld	s1,80(s1)
    80003240:	02e48a63          	beq	s1,a4,80003274 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003244:	449c                	lw	a5,8(s1)
    80003246:	ff279ce3          	bne	a5,s2,8000323e <bread+0x3a>
    8000324a:	44dc                	lw	a5,12(s1)
    8000324c:	ff3799e3          	bne	a5,s3,8000323e <bread+0x3a>
      b->refcnt++;
    80003250:	40bc                	lw	a5,64(s1)
    80003252:	2785                	addiw	a5,a5,1
    80003254:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003256:	00014517          	auipc	a0,0x14
    8000325a:	6c250513          	addi	a0,a0,1730 # 80017918 <bcache>
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	a18080e7          	jalr	-1512(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003266:	01048513          	addi	a0,s1,16
    8000326a:	00001097          	auipc	ra,0x1
    8000326e:	466080e7          	jalr	1126(ra) # 800046d0 <acquiresleep>
      return b;
    80003272:	a8b9                	j	800032d0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003274:	0001d497          	auipc	s1,0x1d
    80003278:	9544b483          	ld	s1,-1708(s1) # 8001fbc8 <bcache+0x82b0>
    8000327c:	0001d797          	auipc	a5,0x1d
    80003280:	90478793          	addi	a5,a5,-1788 # 8001fb80 <bcache+0x8268>
    80003284:	00f48863          	beq	s1,a5,80003294 <bread+0x90>
    80003288:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000328a:	40bc                	lw	a5,64(s1)
    8000328c:	cf81                	beqz	a5,800032a4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000328e:	64a4                	ld	s1,72(s1)
    80003290:	fee49de3          	bne	s1,a4,8000328a <bread+0x86>
  panic("bget: no buffers");
    80003294:	00005517          	auipc	a0,0x5
    80003298:	34450513          	addi	a0,a0,836 # 800085d8 <syscalls+0xc8>
    8000329c:	ffffd097          	auipc	ra,0xffffd
    800032a0:	28e080e7          	jalr	654(ra) # 8000052a <panic>
      b->dev = dev;
    800032a4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032a8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032ac:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032b0:	4785                	li	a5,1
    800032b2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032b4:	00014517          	auipc	a0,0x14
    800032b8:	66450513          	addi	a0,a0,1636 # 80017918 <bcache>
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	9ba080e7          	jalr	-1606(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800032c4:	01048513          	addi	a0,s1,16
    800032c8:	00001097          	auipc	ra,0x1
    800032cc:	408080e7          	jalr	1032(ra) # 800046d0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032d0:	409c                	lw	a5,0(s1)
    800032d2:	cb89                	beqz	a5,800032e4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032d4:	8526                	mv	a0,s1
    800032d6:	70a2                	ld	ra,40(sp)
    800032d8:	7402                	ld	s0,32(sp)
    800032da:	64e2                	ld	s1,24(sp)
    800032dc:	6942                	ld	s2,16(sp)
    800032de:	69a2                	ld	s3,8(sp)
    800032e0:	6145                	addi	sp,sp,48
    800032e2:	8082                	ret
    virtio_disk_rw(b, 0);
    800032e4:	4581                	li	a1,0
    800032e6:	8526                	mv	a0,s1
    800032e8:	00003097          	auipc	ra,0x3
    800032ec:	f1e080e7          	jalr	-226(ra) # 80006206 <virtio_disk_rw>
    b->valid = 1;
    800032f0:	4785                	li	a5,1
    800032f2:	c09c                	sw	a5,0(s1)
  return b;
    800032f4:	b7c5                	j	800032d4 <bread+0xd0>

00000000800032f6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	e426                	sd	s1,8(sp)
    800032fe:	1000                	addi	s0,sp,32
    80003300:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003302:	0541                	addi	a0,a0,16
    80003304:	00001097          	auipc	ra,0x1
    80003308:	466080e7          	jalr	1126(ra) # 8000476a <holdingsleep>
    8000330c:	cd01                	beqz	a0,80003324 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000330e:	4585                	li	a1,1
    80003310:	8526                	mv	a0,s1
    80003312:	00003097          	auipc	ra,0x3
    80003316:	ef4080e7          	jalr	-268(ra) # 80006206 <virtio_disk_rw>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6105                	addi	sp,sp,32
    80003322:	8082                	ret
    panic("bwrite");
    80003324:	00005517          	auipc	a0,0x5
    80003328:	2cc50513          	addi	a0,a0,716 # 800085f0 <syscalls+0xe0>
    8000332c:	ffffd097          	auipc	ra,0xffffd
    80003330:	1fe080e7          	jalr	510(ra) # 8000052a <panic>

0000000080003334 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003334:	1101                	addi	sp,sp,-32
    80003336:	ec06                	sd	ra,24(sp)
    80003338:	e822                	sd	s0,16(sp)
    8000333a:	e426                	sd	s1,8(sp)
    8000333c:	e04a                	sd	s2,0(sp)
    8000333e:	1000                	addi	s0,sp,32
    80003340:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003342:	01050913          	addi	s2,a0,16
    80003346:	854a                	mv	a0,s2
    80003348:	00001097          	auipc	ra,0x1
    8000334c:	422080e7          	jalr	1058(ra) # 8000476a <holdingsleep>
    80003350:	c92d                	beqz	a0,800033c2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003352:	854a                	mv	a0,s2
    80003354:	00001097          	auipc	ra,0x1
    80003358:	3d2080e7          	jalr	978(ra) # 80004726 <releasesleep>

  acquire(&bcache.lock);
    8000335c:	00014517          	auipc	a0,0x14
    80003360:	5bc50513          	addi	a0,a0,1468 # 80017918 <bcache>
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	85e080e7          	jalr	-1954(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000336c:	40bc                	lw	a5,64(s1)
    8000336e:	37fd                	addiw	a5,a5,-1
    80003370:	0007871b          	sext.w	a4,a5
    80003374:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003376:	eb05                	bnez	a4,800033a6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003378:	68bc                	ld	a5,80(s1)
    8000337a:	64b8                	ld	a4,72(s1)
    8000337c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000337e:	64bc                	ld	a5,72(s1)
    80003380:	68b8                	ld	a4,80(s1)
    80003382:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003384:	0001c797          	auipc	a5,0x1c
    80003388:	59478793          	addi	a5,a5,1428 # 8001f918 <bcache+0x8000>
    8000338c:	2b87b703          	ld	a4,696(a5)
    80003390:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003392:	0001c717          	auipc	a4,0x1c
    80003396:	7ee70713          	addi	a4,a4,2030 # 8001fb80 <bcache+0x8268>
    8000339a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000339c:	2b87b703          	ld	a4,696(a5)
    800033a0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033a2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033a6:	00014517          	auipc	a0,0x14
    800033aa:	57250513          	addi	a0,a0,1394 # 80017918 <bcache>
    800033ae:	ffffe097          	auipc	ra,0xffffe
    800033b2:	8c8080e7          	jalr	-1848(ra) # 80000c76 <release>
}
    800033b6:	60e2                	ld	ra,24(sp)
    800033b8:	6442                	ld	s0,16(sp)
    800033ba:	64a2                	ld	s1,8(sp)
    800033bc:	6902                	ld	s2,0(sp)
    800033be:	6105                	addi	sp,sp,32
    800033c0:	8082                	ret
    panic("brelse");
    800033c2:	00005517          	auipc	a0,0x5
    800033c6:	23650513          	addi	a0,a0,566 # 800085f8 <syscalls+0xe8>
    800033ca:	ffffd097          	auipc	ra,0xffffd
    800033ce:	160080e7          	jalr	352(ra) # 8000052a <panic>

00000000800033d2 <bpin>:

void
bpin(struct buf *b) {
    800033d2:	1101                	addi	sp,sp,-32
    800033d4:	ec06                	sd	ra,24(sp)
    800033d6:	e822                	sd	s0,16(sp)
    800033d8:	e426                	sd	s1,8(sp)
    800033da:	1000                	addi	s0,sp,32
    800033dc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033de:	00014517          	auipc	a0,0x14
    800033e2:	53a50513          	addi	a0,a0,1338 # 80017918 <bcache>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	7dc080e7          	jalr	2012(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800033ee:	40bc                	lw	a5,64(s1)
    800033f0:	2785                	addiw	a5,a5,1
    800033f2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033f4:	00014517          	auipc	a0,0x14
    800033f8:	52450513          	addi	a0,a0,1316 # 80017918 <bcache>
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	87a080e7          	jalr	-1926(ra) # 80000c76 <release>
}
    80003404:	60e2                	ld	ra,24(sp)
    80003406:	6442                	ld	s0,16(sp)
    80003408:	64a2                	ld	s1,8(sp)
    8000340a:	6105                	addi	sp,sp,32
    8000340c:	8082                	ret

000000008000340e <bunpin>:

void
bunpin(struct buf *b) {
    8000340e:	1101                	addi	sp,sp,-32
    80003410:	ec06                	sd	ra,24(sp)
    80003412:	e822                	sd	s0,16(sp)
    80003414:	e426                	sd	s1,8(sp)
    80003416:	1000                	addi	s0,sp,32
    80003418:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000341a:	00014517          	auipc	a0,0x14
    8000341e:	4fe50513          	addi	a0,a0,1278 # 80017918 <bcache>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	7a0080e7          	jalr	1952(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000342a:	40bc                	lw	a5,64(s1)
    8000342c:	37fd                	addiw	a5,a5,-1
    8000342e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003430:	00014517          	auipc	a0,0x14
    80003434:	4e850513          	addi	a0,a0,1256 # 80017918 <bcache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	83e080e7          	jalr	-1986(ra) # 80000c76 <release>
}
    80003440:	60e2                	ld	ra,24(sp)
    80003442:	6442                	ld	s0,16(sp)
    80003444:	64a2                	ld	s1,8(sp)
    80003446:	6105                	addi	sp,sp,32
    80003448:	8082                	ret

000000008000344a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	e426                	sd	s1,8(sp)
    80003452:	e04a                	sd	s2,0(sp)
    80003454:	1000                	addi	s0,sp,32
    80003456:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003458:	00d5d59b          	srliw	a1,a1,0xd
    8000345c:	0001d797          	auipc	a5,0x1d
    80003460:	b987a783          	lw	a5,-1128(a5) # 8001fff4 <sb+0x1c>
    80003464:	9dbd                	addw	a1,a1,a5
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	d9e080e7          	jalr	-610(ra) # 80003204 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000346e:	0074f713          	andi	a4,s1,7
    80003472:	4785                	li	a5,1
    80003474:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003478:	14ce                	slli	s1,s1,0x33
    8000347a:	90d9                	srli	s1,s1,0x36
    8000347c:	00950733          	add	a4,a0,s1
    80003480:	05874703          	lbu	a4,88(a4)
    80003484:	00e7f6b3          	and	a3,a5,a4
    80003488:	c69d                	beqz	a3,800034b6 <bfree+0x6c>
    8000348a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000348c:	94aa                	add	s1,s1,a0
    8000348e:	fff7c793          	not	a5,a5
    80003492:	8ff9                	and	a5,a5,a4
    80003494:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003498:	00001097          	auipc	ra,0x1
    8000349c:	118080e7          	jalr	280(ra) # 800045b0 <log_write>
  brelse(bp);
    800034a0:	854a                	mv	a0,s2
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	e92080e7          	jalr	-366(ra) # 80003334 <brelse>
}
    800034aa:	60e2                	ld	ra,24(sp)
    800034ac:	6442                	ld	s0,16(sp)
    800034ae:	64a2                	ld	s1,8(sp)
    800034b0:	6902                	ld	s2,0(sp)
    800034b2:	6105                	addi	sp,sp,32
    800034b4:	8082                	ret
    panic("freeing free block");
    800034b6:	00005517          	auipc	a0,0x5
    800034ba:	14a50513          	addi	a0,a0,330 # 80008600 <syscalls+0xf0>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	06c080e7          	jalr	108(ra) # 8000052a <panic>

00000000800034c6 <balloc>:
{
    800034c6:	711d                	addi	sp,sp,-96
    800034c8:	ec86                	sd	ra,88(sp)
    800034ca:	e8a2                	sd	s0,80(sp)
    800034cc:	e4a6                	sd	s1,72(sp)
    800034ce:	e0ca                	sd	s2,64(sp)
    800034d0:	fc4e                	sd	s3,56(sp)
    800034d2:	f852                	sd	s4,48(sp)
    800034d4:	f456                	sd	s5,40(sp)
    800034d6:	f05a                	sd	s6,32(sp)
    800034d8:	ec5e                	sd	s7,24(sp)
    800034da:	e862                	sd	s8,16(sp)
    800034dc:	e466                	sd	s9,8(sp)
    800034de:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034e0:	0001d797          	auipc	a5,0x1d
    800034e4:	afc7a783          	lw	a5,-1284(a5) # 8001ffdc <sb+0x4>
    800034e8:	cbd1                	beqz	a5,8000357c <balloc+0xb6>
    800034ea:	8baa                	mv	s7,a0
    800034ec:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034ee:	0001db17          	auipc	s6,0x1d
    800034f2:	aeab0b13          	addi	s6,s6,-1302 # 8001ffd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034f8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034fc:	6c89                	lui	s9,0x2
    800034fe:	a831                	j	8000351a <balloc+0x54>
    brelse(bp);
    80003500:	854a                	mv	a0,s2
    80003502:	00000097          	auipc	ra,0x0
    80003506:	e32080e7          	jalr	-462(ra) # 80003334 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000350a:	015c87bb          	addw	a5,s9,s5
    8000350e:	00078a9b          	sext.w	s5,a5
    80003512:	004b2703          	lw	a4,4(s6)
    80003516:	06eaf363          	bgeu	s5,a4,8000357c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000351a:	41fad79b          	sraiw	a5,s5,0x1f
    8000351e:	0137d79b          	srliw	a5,a5,0x13
    80003522:	015787bb          	addw	a5,a5,s5
    80003526:	40d7d79b          	sraiw	a5,a5,0xd
    8000352a:	01cb2583          	lw	a1,28(s6)
    8000352e:	9dbd                	addw	a1,a1,a5
    80003530:	855e                	mv	a0,s7
    80003532:	00000097          	auipc	ra,0x0
    80003536:	cd2080e7          	jalr	-814(ra) # 80003204 <bread>
    8000353a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000353c:	004b2503          	lw	a0,4(s6)
    80003540:	000a849b          	sext.w	s1,s5
    80003544:	8662                	mv	a2,s8
    80003546:	faa4fde3          	bgeu	s1,a0,80003500 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000354a:	41f6579b          	sraiw	a5,a2,0x1f
    8000354e:	01d7d69b          	srliw	a3,a5,0x1d
    80003552:	00c6873b          	addw	a4,a3,a2
    80003556:	00777793          	andi	a5,a4,7
    8000355a:	9f95                	subw	a5,a5,a3
    8000355c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003560:	4037571b          	sraiw	a4,a4,0x3
    80003564:	00e906b3          	add	a3,s2,a4
    80003568:	0586c683          	lbu	a3,88(a3)
    8000356c:	00d7f5b3          	and	a1,a5,a3
    80003570:	cd91                	beqz	a1,8000358c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003572:	2605                	addiw	a2,a2,1
    80003574:	2485                	addiw	s1,s1,1
    80003576:	fd4618e3          	bne	a2,s4,80003546 <balloc+0x80>
    8000357a:	b759                	j	80003500 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000357c:	00005517          	auipc	a0,0x5
    80003580:	09c50513          	addi	a0,a0,156 # 80008618 <syscalls+0x108>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	fa6080e7          	jalr	-90(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000358c:	974a                	add	a4,a4,s2
    8000358e:	8fd5                	or	a5,a5,a3
    80003590:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003594:	854a                	mv	a0,s2
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	01a080e7          	jalr	26(ra) # 800045b0 <log_write>
        brelse(bp);
    8000359e:	854a                	mv	a0,s2
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	d94080e7          	jalr	-620(ra) # 80003334 <brelse>
  bp = bread(dev, bno);
    800035a8:	85a6                	mv	a1,s1
    800035aa:	855e                	mv	a0,s7
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	c58080e7          	jalr	-936(ra) # 80003204 <bread>
    800035b4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035b6:	40000613          	li	a2,1024
    800035ba:	4581                	li	a1,0
    800035bc:	05850513          	addi	a0,a0,88
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	6fe080e7          	jalr	1790(ra) # 80000cbe <memset>
  log_write(bp);
    800035c8:	854a                	mv	a0,s2
    800035ca:	00001097          	auipc	ra,0x1
    800035ce:	fe6080e7          	jalr	-26(ra) # 800045b0 <log_write>
  brelse(bp);
    800035d2:	854a                	mv	a0,s2
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	d60080e7          	jalr	-672(ra) # 80003334 <brelse>
}
    800035dc:	8526                	mv	a0,s1
    800035de:	60e6                	ld	ra,88(sp)
    800035e0:	6446                	ld	s0,80(sp)
    800035e2:	64a6                	ld	s1,72(sp)
    800035e4:	6906                	ld	s2,64(sp)
    800035e6:	79e2                	ld	s3,56(sp)
    800035e8:	7a42                	ld	s4,48(sp)
    800035ea:	7aa2                	ld	s5,40(sp)
    800035ec:	7b02                	ld	s6,32(sp)
    800035ee:	6be2                	ld	s7,24(sp)
    800035f0:	6c42                	ld	s8,16(sp)
    800035f2:	6ca2                	ld	s9,8(sp)
    800035f4:	6125                	addi	sp,sp,96
    800035f6:	8082                	ret

00000000800035f8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035f8:	7179                	addi	sp,sp,-48
    800035fa:	f406                	sd	ra,40(sp)
    800035fc:	f022                	sd	s0,32(sp)
    800035fe:	ec26                	sd	s1,24(sp)
    80003600:	e84a                	sd	s2,16(sp)
    80003602:	e44e                	sd	s3,8(sp)
    80003604:	e052                	sd	s4,0(sp)
    80003606:	1800                	addi	s0,sp,48
    80003608:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000360a:	47ad                	li	a5,11
    8000360c:	04b7fe63          	bgeu	a5,a1,80003668 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003610:	ff45849b          	addiw	s1,a1,-12
    80003614:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003618:	0ff00793          	li	a5,255
    8000361c:	0ae7e363          	bltu	a5,a4,800036c2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003620:	08052583          	lw	a1,128(a0)
    80003624:	c5ad                	beqz	a1,8000368e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003626:	00092503          	lw	a0,0(s2)
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	bda080e7          	jalr	-1062(ra) # 80003204 <bread>
    80003632:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003634:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003638:	02049593          	slli	a1,s1,0x20
    8000363c:	9181                	srli	a1,a1,0x20
    8000363e:	058a                	slli	a1,a1,0x2
    80003640:	00b784b3          	add	s1,a5,a1
    80003644:	0004a983          	lw	s3,0(s1)
    80003648:	04098d63          	beqz	s3,800036a2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000364c:	8552                	mv	a0,s4
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	ce6080e7          	jalr	-794(ra) # 80003334 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003656:	854e                	mv	a0,s3
    80003658:	70a2                	ld	ra,40(sp)
    8000365a:	7402                	ld	s0,32(sp)
    8000365c:	64e2                	ld	s1,24(sp)
    8000365e:	6942                	ld	s2,16(sp)
    80003660:	69a2                	ld	s3,8(sp)
    80003662:	6a02                	ld	s4,0(sp)
    80003664:	6145                	addi	sp,sp,48
    80003666:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003668:	02059493          	slli	s1,a1,0x20
    8000366c:	9081                	srli	s1,s1,0x20
    8000366e:	048a                	slli	s1,s1,0x2
    80003670:	94aa                	add	s1,s1,a0
    80003672:	0504a983          	lw	s3,80(s1)
    80003676:	fe0990e3          	bnez	s3,80003656 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000367a:	4108                	lw	a0,0(a0)
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	e4a080e7          	jalr	-438(ra) # 800034c6 <balloc>
    80003684:	0005099b          	sext.w	s3,a0
    80003688:	0534a823          	sw	s3,80(s1)
    8000368c:	b7e9                	j	80003656 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000368e:	4108                	lw	a0,0(a0)
    80003690:	00000097          	auipc	ra,0x0
    80003694:	e36080e7          	jalr	-458(ra) # 800034c6 <balloc>
    80003698:	0005059b          	sext.w	a1,a0
    8000369c:	08b92023          	sw	a1,128(s2)
    800036a0:	b759                	j	80003626 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036a2:	00092503          	lw	a0,0(s2)
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	e20080e7          	jalr	-480(ra) # 800034c6 <balloc>
    800036ae:	0005099b          	sext.w	s3,a0
    800036b2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800036b6:	8552                	mv	a0,s4
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	ef8080e7          	jalr	-264(ra) # 800045b0 <log_write>
    800036c0:	b771                	j	8000364c <bmap+0x54>
  panic("bmap: out of range");
    800036c2:	00005517          	auipc	a0,0x5
    800036c6:	f6e50513          	addi	a0,a0,-146 # 80008630 <syscalls+0x120>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	e60080e7          	jalr	-416(ra) # 8000052a <panic>

00000000800036d2 <iget>:
{
    800036d2:	7179                	addi	sp,sp,-48
    800036d4:	f406                	sd	ra,40(sp)
    800036d6:	f022                	sd	s0,32(sp)
    800036d8:	ec26                	sd	s1,24(sp)
    800036da:	e84a                	sd	s2,16(sp)
    800036dc:	e44e                	sd	s3,8(sp)
    800036de:	e052                	sd	s4,0(sp)
    800036e0:	1800                	addi	s0,sp,48
    800036e2:	89aa                	mv	s3,a0
    800036e4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036e6:	0001d517          	auipc	a0,0x1d
    800036ea:	91250513          	addi	a0,a0,-1774 # 8001fff8 <itable>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	4d4080e7          	jalr	1236(ra) # 80000bc2 <acquire>
  empty = 0;
    800036f6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036f8:	0001d497          	auipc	s1,0x1d
    800036fc:	91848493          	addi	s1,s1,-1768 # 80020010 <itable+0x18>
    80003700:	0001e697          	auipc	a3,0x1e
    80003704:	3a068693          	addi	a3,a3,928 # 80021aa0 <log>
    80003708:	a039                	j	80003716 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000370a:	02090b63          	beqz	s2,80003740 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000370e:	08848493          	addi	s1,s1,136
    80003712:	02d48a63          	beq	s1,a3,80003746 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003716:	449c                	lw	a5,8(s1)
    80003718:	fef059e3          	blez	a5,8000370a <iget+0x38>
    8000371c:	4098                	lw	a4,0(s1)
    8000371e:	ff3716e3          	bne	a4,s3,8000370a <iget+0x38>
    80003722:	40d8                	lw	a4,4(s1)
    80003724:	ff4713e3          	bne	a4,s4,8000370a <iget+0x38>
      ip->ref++;
    80003728:	2785                	addiw	a5,a5,1
    8000372a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000372c:	0001d517          	auipc	a0,0x1d
    80003730:	8cc50513          	addi	a0,a0,-1844 # 8001fff8 <itable>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	542080e7          	jalr	1346(ra) # 80000c76 <release>
      return ip;
    8000373c:	8926                	mv	s2,s1
    8000373e:	a03d                	j	8000376c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003740:	f7f9                	bnez	a5,8000370e <iget+0x3c>
    80003742:	8926                	mv	s2,s1
    80003744:	b7e9                	j	8000370e <iget+0x3c>
  if(empty == 0)
    80003746:	02090c63          	beqz	s2,8000377e <iget+0xac>
  ip->dev = dev;
    8000374a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000374e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003752:	4785                	li	a5,1
    80003754:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003758:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000375c:	0001d517          	auipc	a0,0x1d
    80003760:	89c50513          	addi	a0,a0,-1892 # 8001fff8 <itable>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	512080e7          	jalr	1298(ra) # 80000c76 <release>
}
    8000376c:	854a                	mv	a0,s2
    8000376e:	70a2                	ld	ra,40(sp)
    80003770:	7402                	ld	s0,32(sp)
    80003772:	64e2                	ld	s1,24(sp)
    80003774:	6942                	ld	s2,16(sp)
    80003776:	69a2                	ld	s3,8(sp)
    80003778:	6a02                	ld	s4,0(sp)
    8000377a:	6145                	addi	sp,sp,48
    8000377c:	8082                	ret
    panic("iget: no inodes");
    8000377e:	00005517          	auipc	a0,0x5
    80003782:	eca50513          	addi	a0,a0,-310 # 80008648 <syscalls+0x138>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	da4080e7          	jalr	-604(ra) # 8000052a <panic>

000000008000378e <fsinit>:
fsinit(int dev) {
    8000378e:	7179                	addi	sp,sp,-48
    80003790:	f406                	sd	ra,40(sp)
    80003792:	f022                	sd	s0,32(sp)
    80003794:	ec26                	sd	s1,24(sp)
    80003796:	e84a                	sd	s2,16(sp)
    80003798:	e44e                	sd	s3,8(sp)
    8000379a:	1800                	addi	s0,sp,48
    8000379c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000379e:	4585                	li	a1,1
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	a64080e7          	jalr	-1436(ra) # 80003204 <bread>
    800037a8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037aa:	0001d997          	auipc	s3,0x1d
    800037ae:	82e98993          	addi	s3,s3,-2002 # 8001ffd8 <sb>
    800037b2:	02000613          	li	a2,32
    800037b6:	05850593          	addi	a1,a0,88
    800037ba:	854e                	mv	a0,s3
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	55e080e7          	jalr	1374(ra) # 80000d1a <memmove>
  brelse(bp);
    800037c4:	8526                	mv	a0,s1
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	b6e080e7          	jalr	-1170(ra) # 80003334 <brelse>
  if(sb.magic != FSMAGIC)
    800037ce:	0009a703          	lw	a4,0(s3)
    800037d2:	102037b7          	lui	a5,0x10203
    800037d6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037da:	02f71263          	bne	a4,a5,800037fe <fsinit+0x70>
  initlog(dev, &sb);
    800037de:	0001c597          	auipc	a1,0x1c
    800037e2:	7fa58593          	addi	a1,a1,2042 # 8001ffd8 <sb>
    800037e6:	854a                	mv	a0,s2
    800037e8:	00001097          	auipc	ra,0x1
    800037ec:	b4c080e7          	jalr	-1204(ra) # 80004334 <initlog>
}
    800037f0:	70a2                	ld	ra,40(sp)
    800037f2:	7402                	ld	s0,32(sp)
    800037f4:	64e2                	ld	s1,24(sp)
    800037f6:	6942                	ld	s2,16(sp)
    800037f8:	69a2                	ld	s3,8(sp)
    800037fa:	6145                	addi	sp,sp,48
    800037fc:	8082                	ret
    panic("invalid file system");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	e5a50513          	addi	a0,a0,-422 # 80008658 <syscalls+0x148>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d24080e7          	jalr	-732(ra) # 8000052a <panic>

000000008000380e <iinit>:
{
    8000380e:	7179                	addi	sp,sp,-48
    80003810:	f406                	sd	ra,40(sp)
    80003812:	f022                	sd	s0,32(sp)
    80003814:	ec26                	sd	s1,24(sp)
    80003816:	e84a                	sd	s2,16(sp)
    80003818:	e44e                	sd	s3,8(sp)
    8000381a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000381c:	00005597          	auipc	a1,0x5
    80003820:	e5458593          	addi	a1,a1,-428 # 80008670 <syscalls+0x160>
    80003824:	0001c517          	auipc	a0,0x1c
    80003828:	7d450513          	addi	a0,a0,2004 # 8001fff8 <itable>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	306080e7          	jalr	774(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003834:	0001c497          	auipc	s1,0x1c
    80003838:	7ec48493          	addi	s1,s1,2028 # 80020020 <itable+0x28>
    8000383c:	0001e997          	auipc	s3,0x1e
    80003840:	27498993          	addi	s3,s3,628 # 80021ab0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003844:	00005917          	auipc	s2,0x5
    80003848:	e3490913          	addi	s2,s2,-460 # 80008678 <syscalls+0x168>
    8000384c:	85ca                	mv	a1,s2
    8000384e:	8526                	mv	a0,s1
    80003850:	00001097          	auipc	ra,0x1
    80003854:	e46080e7          	jalr	-442(ra) # 80004696 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003858:	08848493          	addi	s1,s1,136
    8000385c:	ff3498e3          	bne	s1,s3,8000384c <iinit+0x3e>
}
    80003860:	70a2                	ld	ra,40(sp)
    80003862:	7402                	ld	s0,32(sp)
    80003864:	64e2                	ld	s1,24(sp)
    80003866:	6942                	ld	s2,16(sp)
    80003868:	69a2                	ld	s3,8(sp)
    8000386a:	6145                	addi	sp,sp,48
    8000386c:	8082                	ret

000000008000386e <ialloc>:
{
    8000386e:	715d                	addi	sp,sp,-80
    80003870:	e486                	sd	ra,72(sp)
    80003872:	e0a2                	sd	s0,64(sp)
    80003874:	fc26                	sd	s1,56(sp)
    80003876:	f84a                	sd	s2,48(sp)
    80003878:	f44e                	sd	s3,40(sp)
    8000387a:	f052                	sd	s4,32(sp)
    8000387c:	ec56                	sd	s5,24(sp)
    8000387e:	e85a                	sd	s6,16(sp)
    80003880:	e45e                	sd	s7,8(sp)
    80003882:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003884:	0001c717          	auipc	a4,0x1c
    80003888:	76072703          	lw	a4,1888(a4) # 8001ffe4 <sb+0xc>
    8000388c:	4785                	li	a5,1
    8000388e:	04e7fa63          	bgeu	a5,a4,800038e2 <ialloc+0x74>
    80003892:	8aaa                	mv	s5,a0
    80003894:	8bae                	mv	s7,a1
    80003896:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003898:	0001ca17          	auipc	s4,0x1c
    8000389c:	740a0a13          	addi	s4,s4,1856 # 8001ffd8 <sb>
    800038a0:	00048b1b          	sext.w	s6,s1
    800038a4:	0044d793          	srli	a5,s1,0x4
    800038a8:	018a2583          	lw	a1,24(s4)
    800038ac:	9dbd                	addw	a1,a1,a5
    800038ae:	8556                	mv	a0,s5
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	954080e7          	jalr	-1708(ra) # 80003204 <bread>
    800038b8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038ba:	05850993          	addi	s3,a0,88
    800038be:	00f4f793          	andi	a5,s1,15
    800038c2:	079a                	slli	a5,a5,0x6
    800038c4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038c6:	00099783          	lh	a5,0(s3)
    800038ca:	c785                	beqz	a5,800038f2 <ialloc+0x84>
    brelse(bp);
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	a68080e7          	jalr	-1432(ra) # 80003334 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038d4:	0485                	addi	s1,s1,1
    800038d6:	00ca2703          	lw	a4,12(s4)
    800038da:	0004879b          	sext.w	a5,s1
    800038de:	fce7e1e3          	bltu	a5,a4,800038a0 <ialloc+0x32>
  panic("ialloc: no inodes");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	d9e50513          	addi	a0,a0,-610 # 80008680 <syscalls+0x170>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c40080e7          	jalr	-960(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800038f2:	04000613          	li	a2,64
    800038f6:	4581                	li	a1,0
    800038f8:	854e                	mv	a0,s3
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	3c4080e7          	jalr	964(ra) # 80000cbe <memset>
      dip->type = type;
    80003902:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003906:	854a                	mv	a0,s2
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	ca8080e7          	jalr	-856(ra) # 800045b0 <log_write>
      brelse(bp);
    80003910:	854a                	mv	a0,s2
    80003912:	00000097          	auipc	ra,0x0
    80003916:	a22080e7          	jalr	-1502(ra) # 80003334 <brelse>
      return iget(dev, inum);
    8000391a:	85da                	mv	a1,s6
    8000391c:	8556                	mv	a0,s5
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	db4080e7          	jalr	-588(ra) # 800036d2 <iget>
}
    80003926:	60a6                	ld	ra,72(sp)
    80003928:	6406                	ld	s0,64(sp)
    8000392a:	74e2                	ld	s1,56(sp)
    8000392c:	7942                	ld	s2,48(sp)
    8000392e:	79a2                	ld	s3,40(sp)
    80003930:	7a02                	ld	s4,32(sp)
    80003932:	6ae2                	ld	s5,24(sp)
    80003934:	6b42                	ld	s6,16(sp)
    80003936:	6ba2                	ld	s7,8(sp)
    80003938:	6161                	addi	sp,sp,80
    8000393a:	8082                	ret

000000008000393c <iupdate>:
{
    8000393c:	1101                	addi	sp,sp,-32
    8000393e:	ec06                	sd	ra,24(sp)
    80003940:	e822                	sd	s0,16(sp)
    80003942:	e426                	sd	s1,8(sp)
    80003944:	e04a                	sd	s2,0(sp)
    80003946:	1000                	addi	s0,sp,32
    80003948:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000394a:	415c                	lw	a5,4(a0)
    8000394c:	0047d79b          	srliw	a5,a5,0x4
    80003950:	0001c597          	auipc	a1,0x1c
    80003954:	6a05a583          	lw	a1,1696(a1) # 8001fff0 <sb+0x18>
    80003958:	9dbd                	addw	a1,a1,a5
    8000395a:	4108                	lw	a0,0(a0)
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	8a8080e7          	jalr	-1880(ra) # 80003204 <bread>
    80003964:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003966:	05850793          	addi	a5,a0,88
    8000396a:	40c8                	lw	a0,4(s1)
    8000396c:	893d                	andi	a0,a0,15
    8000396e:	051a                	slli	a0,a0,0x6
    80003970:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003972:	04449703          	lh	a4,68(s1)
    80003976:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000397a:	04649703          	lh	a4,70(s1)
    8000397e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003982:	04849703          	lh	a4,72(s1)
    80003986:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000398a:	04a49703          	lh	a4,74(s1)
    8000398e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003992:	44f8                	lw	a4,76(s1)
    80003994:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003996:	03400613          	li	a2,52
    8000399a:	05048593          	addi	a1,s1,80
    8000399e:	0531                	addi	a0,a0,12
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	37a080e7          	jalr	890(ra) # 80000d1a <memmove>
  log_write(bp);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00001097          	auipc	ra,0x1
    800039ae:	c06080e7          	jalr	-1018(ra) # 800045b0 <log_write>
  brelse(bp);
    800039b2:	854a                	mv	a0,s2
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	980080e7          	jalr	-1664(ra) # 80003334 <brelse>
}
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6902                	ld	s2,0(sp)
    800039c4:	6105                	addi	sp,sp,32
    800039c6:	8082                	ret

00000000800039c8 <idup>:
{
    800039c8:	1101                	addi	sp,sp,-32
    800039ca:	ec06                	sd	ra,24(sp)
    800039cc:	e822                	sd	s0,16(sp)
    800039ce:	e426                	sd	s1,8(sp)
    800039d0:	1000                	addi	s0,sp,32
    800039d2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039d4:	0001c517          	auipc	a0,0x1c
    800039d8:	62450513          	addi	a0,a0,1572 # 8001fff8 <itable>
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	1e6080e7          	jalr	486(ra) # 80000bc2 <acquire>
  ip->ref++;
    800039e4:	449c                	lw	a5,8(s1)
    800039e6:	2785                	addiw	a5,a5,1
    800039e8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ea:	0001c517          	auipc	a0,0x1c
    800039ee:	60e50513          	addi	a0,a0,1550 # 8001fff8 <itable>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	284080e7          	jalr	644(ra) # 80000c76 <release>
}
    800039fa:	8526                	mv	a0,s1
    800039fc:	60e2                	ld	ra,24(sp)
    800039fe:	6442                	ld	s0,16(sp)
    80003a00:	64a2                	ld	s1,8(sp)
    80003a02:	6105                	addi	sp,sp,32
    80003a04:	8082                	ret

0000000080003a06 <ilock>:
{
    80003a06:	1101                	addi	sp,sp,-32
    80003a08:	ec06                	sd	ra,24(sp)
    80003a0a:	e822                	sd	s0,16(sp)
    80003a0c:	e426                	sd	s1,8(sp)
    80003a0e:	e04a                	sd	s2,0(sp)
    80003a10:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a12:	c115                	beqz	a0,80003a36 <ilock+0x30>
    80003a14:	84aa                	mv	s1,a0
    80003a16:	451c                	lw	a5,8(a0)
    80003a18:	00f05f63          	blez	a5,80003a36 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a1c:	0541                	addi	a0,a0,16
    80003a1e:	00001097          	auipc	ra,0x1
    80003a22:	cb2080e7          	jalr	-846(ra) # 800046d0 <acquiresleep>
  if(ip->valid == 0){
    80003a26:	40bc                	lw	a5,64(s1)
    80003a28:	cf99                	beqz	a5,80003a46 <ilock+0x40>
}
    80003a2a:	60e2                	ld	ra,24(sp)
    80003a2c:	6442                	ld	s0,16(sp)
    80003a2e:	64a2                	ld	s1,8(sp)
    80003a30:	6902                	ld	s2,0(sp)
    80003a32:	6105                	addi	sp,sp,32
    80003a34:	8082                	ret
    panic("ilock");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	c6250513          	addi	a0,a0,-926 # 80008698 <syscalls+0x188>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	aec080e7          	jalr	-1300(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a46:	40dc                	lw	a5,4(s1)
    80003a48:	0047d79b          	srliw	a5,a5,0x4
    80003a4c:	0001c597          	auipc	a1,0x1c
    80003a50:	5a45a583          	lw	a1,1444(a1) # 8001fff0 <sb+0x18>
    80003a54:	9dbd                	addw	a1,a1,a5
    80003a56:	4088                	lw	a0,0(s1)
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	7ac080e7          	jalr	1964(ra) # 80003204 <bread>
    80003a60:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a62:	05850593          	addi	a1,a0,88
    80003a66:	40dc                	lw	a5,4(s1)
    80003a68:	8bbd                	andi	a5,a5,15
    80003a6a:	079a                	slli	a5,a5,0x6
    80003a6c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a6e:	00059783          	lh	a5,0(a1)
    80003a72:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a76:	00259783          	lh	a5,2(a1)
    80003a7a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a7e:	00459783          	lh	a5,4(a1)
    80003a82:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a86:	00659783          	lh	a5,6(a1)
    80003a8a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a8e:	459c                	lw	a5,8(a1)
    80003a90:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a92:	03400613          	li	a2,52
    80003a96:	05b1                	addi	a1,a1,12
    80003a98:	05048513          	addi	a0,s1,80
    80003a9c:	ffffd097          	auipc	ra,0xffffd
    80003aa0:	27e080e7          	jalr	638(ra) # 80000d1a <memmove>
    brelse(bp);
    80003aa4:	854a                	mv	a0,s2
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	88e080e7          	jalr	-1906(ra) # 80003334 <brelse>
    ip->valid = 1;
    80003aae:	4785                	li	a5,1
    80003ab0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ab2:	04449783          	lh	a5,68(s1)
    80003ab6:	fbb5                	bnez	a5,80003a2a <ilock+0x24>
      panic("ilock: no type");
    80003ab8:	00005517          	auipc	a0,0x5
    80003abc:	be850513          	addi	a0,a0,-1048 # 800086a0 <syscalls+0x190>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	a6a080e7          	jalr	-1430(ra) # 8000052a <panic>

0000000080003ac8 <iunlock>:
{
    80003ac8:	1101                	addi	sp,sp,-32
    80003aca:	ec06                	sd	ra,24(sp)
    80003acc:	e822                	sd	s0,16(sp)
    80003ace:	e426                	sd	s1,8(sp)
    80003ad0:	e04a                	sd	s2,0(sp)
    80003ad2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ad4:	c905                	beqz	a0,80003b04 <iunlock+0x3c>
    80003ad6:	84aa                	mv	s1,a0
    80003ad8:	01050913          	addi	s2,a0,16
    80003adc:	854a                	mv	a0,s2
    80003ade:	00001097          	auipc	ra,0x1
    80003ae2:	c8c080e7          	jalr	-884(ra) # 8000476a <holdingsleep>
    80003ae6:	cd19                	beqz	a0,80003b04 <iunlock+0x3c>
    80003ae8:	449c                	lw	a5,8(s1)
    80003aea:	00f05d63          	blez	a5,80003b04 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aee:	854a                	mv	a0,s2
    80003af0:	00001097          	auipc	ra,0x1
    80003af4:	c36080e7          	jalr	-970(ra) # 80004726 <releasesleep>
}
    80003af8:	60e2                	ld	ra,24(sp)
    80003afa:	6442                	ld	s0,16(sp)
    80003afc:	64a2                	ld	s1,8(sp)
    80003afe:	6902                	ld	s2,0(sp)
    80003b00:	6105                	addi	sp,sp,32
    80003b02:	8082                	ret
    panic("iunlock");
    80003b04:	00005517          	auipc	a0,0x5
    80003b08:	bac50513          	addi	a0,a0,-1108 # 800086b0 <syscalls+0x1a0>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a1e080e7          	jalr	-1506(ra) # 8000052a <panic>

0000000080003b14 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b14:	7179                	addi	sp,sp,-48
    80003b16:	f406                	sd	ra,40(sp)
    80003b18:	f022                	sd	s0,32(sp)
    80003b1a:	ec26                	sd	s1,24(sp)
    80003b1c:	e84a                	sd	s2,16(sp)
    80003b1e:	e44e                	sd	s3,8(sp)
    80003b20:	e052                	sd	s4,0(sp)
    80003b22:	1800                	addi	s0,sp,48
    80003b24:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b26:	05050493          	addi	s1,a0,80
    80003b2a:	08050913          	addi	s2,a0,128
    80003b2e:	a021                	j	80003b36 <itrunc+0x22>
    80003b30:	0491                	addi	s1,s1,4
    80003b32:	01248d63          	beq	s1,s2,80003b4c <itrunc+0x38>
    if(ip->addrs[i]){
    80003b36:	408c                	lw	a1,0(s1)
    80003b38:	dde5                	beqz	a1,80003b30 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b3a:	0009a503          	lw	a0,0(s3)
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	90c080e7          	jalr	-1780(ra) # 8000344a <bfree>
      ip->addrs[i] = 0;
    80003b46:	0004a023          	sw	zero,0(s1)
    80003b4a:	b7dd                	j	80003b30 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b4c:	0809a583          	lw	a1,128(s3)
    80003b50:	e185                	bnez	a1,80003b70 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b52:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b56:	854e                	mv	a0,s3
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	de4080e7          	jalr	-540(ra) # 8000393c <iupdate>
}
    80003b60:	70a2                	ld	ra,40(sp)
    80003b62:	7402                	ld	s0,32(sp)
    80003b64:	64e2                	ld	s1,24(sp)
    80003b66:	6942                	ld	s2,16(sp)
    80003b68:	69a2                	ld	s3,8(sp)
    80003b6a:	6a02                	ld	s4,0(sp)
    80003b6c:	6145                	addi	sp,sp,48
    80003b6e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b70:	0009a503          	lw	a0,0(s3)
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	690080e7          	jalr	1680(ra) # 80003204 <bread>
    80003b7c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b7e:	05850493          	addi	s1,a0,88
    80003b82:	45850913          	addi	s2,a0,1112
    80003b86:	a021                	j	80003b8e <itrunc+0x7a>
    80003b88:	0491                	addi	s1,s1,4
    80003b8a:	01248b63          	beq	s1,s2,80003ba0 <itrunc+0x8c>
      if(a[j])
    80003b8e:	408c                	lw	a1,0(s1)
    80003b90:	dde5                	beqz	a1,80003b88 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b92:	0009a503          	lw	a0,0(s3)
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	8b4080e7          	jalr	-1868(ra) # 8000344a <bfree>
    80003b9e:	b7ed                	j	80003b88 <itrunc+0x74>
    brelse(bp);
    80003ba0:	8552                	mv	a0,s4
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	792080e7          	jalr	1938(ra) # 80003334 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003baa:	0809a583          	lw	a1,128(s3)
    80003bae:	0009a503          	lw	a0,0(s3)
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	898080e7          	jalr	-1896(ra) # 8000344a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bba:	0809a023          	sw	zero,128(s3)
    80003bbe:	bf51                	j	80003b52 <itrunc+0x3e>

0000000080003bc0 <iput>:
{
    80003bc0:	1101                	addi	sp,sp,-32
    80003bc2:	ec06                	sd	ra,24(sp)
    80003bc4:	e822                	sd	s0,16(sp)
    80003bc6:	e426                	sd	s1,8(sp)
    80003bc8:	e04a                	sd	s2,0(sp)
    80003bca:	1000                	addi	s0,sp,32
    80003bcc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bce:	0001c517          	auipc	a0,0x1c
    80003bd2:	42a50513          	addi	a0,a0,1066 # 8001fff8 <itable>
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	fec080e7          	jalr	-20(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bde:	4498                	lw	a4,8(s1)
    80003be0:	4785                	li	a5,1
    80003be2:	02f70363          	beq	a4,a5,80003c08 <iput+0x48>
  ip->ref--;
    80003be6:	449c                	lw	a5,8(s1)
    80003be8:	37fd                	addiw	a5,a5,-1
    80003bea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bec:	0001c517          	auipc	a0,0x1c
    80003bf0:	40c50513          	addi	a0,a0,1036 # 8001fff8 <itable>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	082080e7          	jalr	130(ra) # 80000c76 <release>
}
    80003bfc:	60e2                	ld	ra,24(sp)
    80003bfe:	6442                	ld	s0,16(sp)
    80003c00:	64a2                	ld	s1,8(sp)
    80003c02:	6902                	ld	s2,0(sp)
    80003c04:	6105                	addi	sp,sp,32
    80003c06:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c08:	40bc                	lw	a5,64(s1)
    80003c0a:	dff1                	beqz	a5,80003be6 <iput+0x26>
    80003c0c:	04a49783          	lh	a5,74(s1)
    80003c10:	fbf9                	bnez	a5,80003be6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c12:	01048913          	addi	s2,s1,16
    80003c16:	854a                	mv	a0,s2
    80003c18:	00001097          	auipc	ra,0x1
    80003c1c:	ab8080e7          	jalr	-1352(ra) # 800046d0 <acquiresleep>
    release(&itable.lock);
    80003c20:	0001c517          	auipc	a0,0x1c
    80003c24:	3d850513          	addi	a0,a0,984 # 8001fff8 <itable>
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	04e080e7          	jalr	78(ra) # 80000c76 <release>
    itrunc(ip);
    80003c30:	8526                	mv	a0,s1
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	ee2080e7          	jalr	-286(ra) # 80003b14 <itrunc>
    ip->type = 0;
    80003c3a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c3e:	8526                	mv	a0,s1
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	cfc080e7          	jalr	-772(ra) # 8000393c <iupdate>
    ip->valid = 0;
    80003c48:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c4c:	854a                	mv	a0,s2
    80003c4e:	00001097          	auipc	ra,0x1
    80003c52:	ad8080e7          	jalr	-1320(ra) # 80004726 <releasesleep>
    acquire(&itable.lock);
    80003c56:	0001c517          	auipc	a0,0x1c
    80003c5a:	3a250513          	addi	a0,a0,930 # 8001fff8 <itable>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	f64080e7          	jalr	-156(ra) # 80000bc2 <acquire>
    80003c66:	b741                	j	80003be6 <iput+0x26>

0000000080003c68 <iunlockput>:
{
    80003c68:	1101                	addi	sp,sp,-32
    80003c6a:	ec06                	sd	ra,24(sp)
    80003c6c:	e822                	sd	s0,16(sp)
    80003c6e:	e426                	sd	s1,8(sp)
    80003c70:	1000                	addi	s0,sp,32
    80003c72:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	e54080e7          	jalr	-428(ra) # 80003ac8 <iunlock>
  iput(ip);
    80003c7c:	8526                	mv	a0,s1
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	f42080e7          	jalr	-190(ra) # 80003bc0 <iput>
}
    80003c86:	60e2                	ld	ra,24(sp)
    80003c88:	6442                	ld	s0,16(sp)
    80003c8a:	64a2                	ld	s1,8(sp)
    80003c8c:	6105                	addi	sp,sp,32
    80003c8e:	8082                	ret

0000000080003c90 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c90:	1141                	addi	sp,sp,-16
    80003c92:	e422                	sd	s0,8(sp)
    80003c94:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c96:	411c                	lw	a5,0(a0)
    80003c98:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c9a:	415c                	lw	a5,4(a0)
    80003c9c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c9e:	04451783          	lh	a5,68(a0)
    80003ca2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ca6:	04a51783          	lh	a5,74(a0)
    80003caa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cae:	04c56783          	lwu	a5,76(a0)
    80003cb2:	e99c                	sd	a5,16(a1)
}
    80003cb4:	6422                	ld	s0,8(sp)
    80003cb6:	0141                	addi	sp,sp,16
    80003cb8:	8082                	ret

0000000080003cba <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cba:	457c                	lw	a5,76(a0)
    80003cbc:	0ed7e963          	bltu	a5,a3,80003dae <readi+0xf4>
{
    80003cc0:	7159                	addi	sp,sp,-112
    80003cc2:	f486                	sd	ra,104(sp)
    80003cc4:	f0a2                	sd	s0,96(sp)
    80003cc6:	eca6                	sd	s1,88(sp)
    80003cc8:	e8ca                	sd	s2,80(sp)
    80003cca:	e4ce                	sd	s3,72(sp)
    80003ccc:	e0d2                	sd	s4,64(sp)
    80003cce:	fc56                	sd	s5,56(sp)
    80003cd0:	f85a                	sd	s6,48(sp)
    80003cd2:	f45e                	sd	s7,40(sp)
    80003cd4:	f062                	sd	s8,32(sp)
    80003cd6:	ec66                	sd	s9,24(sp)
    80003cd8:	e86a                	sd	s10,16(sp)
    80003cda:	e46e                	sd	s11,8(sp)
    80003cdc:	1880                	addi	s0,sp,112
    80003cde:	8baa                	mv	s7,a0
    80003ce0:	8c2e                	mv	s8,a1
    80003ce2:	8ab2                	mv	s5,a2
    80003ce4:	84b6                	mv	s1,a3
    80003ce6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ce8:	9f35                	addw	a4,a4,a3
    return 0;
    80003cea:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cec:	0ad76063          	bltu	a4,a3,80003d8c <readi+0xd2>
  if(off + n > ip->size)
    80003cf0:	00e7f463          	bgeu	a5,a4,80003cf8 <readi+0x3e>
    n = ip->size - off;
    80003cf4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf8:	0a0b0963          	beqz	s6,80003daa <readi+0xf0>
    80003cfc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cfe:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d02:	5cfd                	li	s9,-1
    80003d04:	a82d                	j	80003d3e <readi+0x84>
    80003d06:	020a1d93          	slli	s11,s4,0x20
    80003d0a:	020ddd93          	srli	s11,s11,0x20
    80003d0e:	05890793          	addi	a5,s2,88
    80003d12:	86ee                	mv	a3,s11
    80003d14:	963e                	add	a2,a2,a5
    80003d16:	85d6                	mv	a1,s5
    80003d18:	8562                	mv	a0,s8
    80003d1a:	fffff097          	auipc	ra,0xfffff
    80003d1e:	a6c080e7          	jalr	-1428(ra) # 80002786 <either_copyout>
    80003d22:	05950d63          	beq	a0,s9,80003d7c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d26:	854a                	mv	a0,s2
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	60c080e7          	jalr	1548(ra) # 80003334 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d30:	013a09bb          	addw	s3,s4,s3
    80003d34:	009a04bb          	addw	s1,s4,s1
    80003d38:	9aee                	add	s5,s5,s11
    80003d3a:	0569f763          	bgeu	s3,s6,80003d88 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d3e:	000ba903          	lw	s2,0(s7)
    80003d42:	00a4d59b          	srliw	a1,s1,0xa
    80003d46:	855e                	mv	a0,s7
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	8b0080e7          	jalr	-1872(ra) # 800035f8 <bmap>
    80003d50:	0005059b          	sext.w	a1,a0
    80003d54:	854a                	mv	a0,s2
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	4ae080e7          	jalr	1198(ra) # 80003204 <bread>
    80003d5e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d60:	3ff4f613          	andi	a2,s1,1023
    80003d64:	40cd07bb          	subw	a5,s10,a2
    80003d68:	413b073b          	subw	a4,s6,s3
    80003d6c:	8a3e                	mv	s4,a5
    80003d6e:	2781                	sext.w	a5,a5
    80003d70:	0007069b          	sext.w	a3,a4
    80003d74:	f8f6f9e3          	bgeu	a3,a5,80003d06 <readi+0x4c>
    80003d78:	8a3a                	mv	s4,a4
    80003d7a:	b771                	j	80003d06 <readi+0x4c>
      brelse(bp);
    80003d7c:	854a                	mv	a0,s2
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	5b6080e7          	jalr	1462(ra) # 80003334 <brelse>
      tot = -1;
    80003d86:	59fd                	li	s3,-1
  }
  return tot;
    80003d88:	0009851b          	sext.w	a0,s3
}
    80003d8c:	70a6                	ld	ra,104(sp)
    80003d8e:	7406                	ld	s0,96(sp)
    80003d90:	64e6                	ld	s1,88(sp)
    80003d92:	6946                	ld	s2,80(sp)
    80003d94:	69a6                	ld	s3,72(sp)
    80003d96:	6a06                	ld	s4,64(sp)
    80003d98:	7ae2                	ld	s5,56(sp)
    80003d9a:	7b42                	ld	s6,48(sp)
    80003d9c:	7ba2                	ld	s7,40(sp)
    80003d9e:	7c02                	ld	s8,32(sp)
    80003da0:	6ce2                	ld	s9,24(sp)
    80003da2:	6d42                	ld	s10,16(sp)
    80003da4:	6da2                	ld	s11,8(sp)
    80003da6:	6165                	addi	sp,sp,112
    80003da8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003daa:	89da                	mv	s3,s6
    80003dac:	bff1                	j	80003d88 <readi+0xce>
    return 0;
    80003dae:	4501                	li	a0,0
}
    80003db0:	8082                	ret

0000000080003db2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003db2:	457c                	lw	a5,76(a0)
    80003db4:	10d7e863          	bltu	a5,a3,80003ec4 <writei+0x112>
{
    80003db8:	7159                	addi	sp,sp,-112
    80003dba:	f486                	sd	ra,104(sp)
    80003dbc:	f0a2                	sd	s0,96(sp)
    80003dbe:	eca6                	sd	s1,88(sp)
    80003dc0:	e8ca                	sd	s2,80(sp)
    80003dc2:	e4ce                	sd	s3,72(sp)
    80003dc4:	e0d2                	sd	s4,64(sp)
    80003dc6:	fc56                	sd	s5,56(sp)
    80003dc8:	f85a                	sd	s6,48(sp)
    80003dca:	f45e                	sd	s7,40(sp)
    80003dcc:	f062                	sd	s8,32(sp)
    80003dce:	ec66                	sd	s9,24(sp)
    80003dd0:	e86a                	sd	s10,16(sp)
    80003dd2:	e46e                	sd	s11,8(sp)
    80003dd4:	1880                	addi	s0,sp,112
    80003dd6:	8b2a                	mv	s6,a0
    80003dd8:	8c2e                	mv	s8,a1
    80003dda:	8ab2                	mv	s5,a2
    80003ddc:	8936                	mv	s2,a3
    80003dde:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003de0:	00e687bb          	addw	a5,a3,a4
    80003de4:	0ed7e263          	bltu	a5,a3,80003ec8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003de8:	00043737          	lui	a4,0x43
    80003dec:	0ef76063          	bltu	a4,a5,80003ecc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df0:	0c0b8863          	beqz	s7,80003ec0 <writei+0x10e>
    80003df4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003df6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dfa:	5cfd                	li	s9,-1
    80003dfc:	a091                	j	80003e40 <writei+0x8e>
    80003dfe:	02099d93          	slli	s11,s3,0x20
    80003e02:	020ddd93          	srli	s11,s11,0x20
    80003e06:	05848793          	addi	a5,s1,88
    80003e0a:	86ee                	mv	a3,s11
    80003e0c:	8656                	mv	a2,s5
    80003e0e:	85e2                	mv	a1,s8
    80003e10:	953e                	add	a0,a0,a5
    80003e12:	fffff097          	auipc	ra,0xfffff
    80003e16:	9ca080e7          	jalr	-1590(ra) # 800027dc <either_copyin>
    80003e1a:	07950263          	beq	a0,s9,80003e7e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e1e:	8526                	mv	a0,s1
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	790080e7          	jalr	1936(ra) # 800045b0 <log_write>
    brelse(bp);
    80003e28:	8526                	mv	a0,s1
    80003e2a:	fffff097          	auipc	ra,0xfffff
    80003e2e:	50a080e7          	jalr	1290(ra) # 80003334 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e32:	01498a3b          	addw	s4,s3,s4
    80003e36:	0129893b          	addw	s2,s3,s2
    80003e3a:	9aee                	add	s5,s5,s11
    80003e3c:	057a7663          	bgeu	s4,s7,80003e88 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e40:	000b2483          	lw	s1,0(s6)
    80003e44:	00a9559b          	srliw	a1,s2,0xa
    80003e48:	855a                	mv	a0,s6
    80003e4a:	fffff097          	auipc	ra,0xfffff
    80003e4e:	7ae080e7          	jalr	1966(ra) # 800035f8 <bmap>
    80003e52:	0005059b          	sext.w	a1,a0
    80003e56:	8526                	mv	a0,s1
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	3ac080e7          	jalr	940(ra) # 80003204 <bread>
    80003e60:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e62:	3ff97513          	andi	a0,s2,1023
    80003e66:	40ad07bb          	subw	a5,s10,a0
    80003e6a:	414b873b          	subw	a4,s7,s4
    80003e6e:	89be                	mv	s3,a5
    80003e70:	2781                	sext.w	a5,a5
    80003e72:	0007069b          	sext.w	a3,a4
    80003e76:	f8f6f4e3          	bgeu	a3,a5,80003dfe <writei+0x4c>
    80003e7a:	89ba                	mv	s3,a4
    80003e7c:	b749                	j	80003dfe <writei+0x4c>
      brelse(bp);
    80003e7e:	8526                	mv	a0,s1
    80003e80:	fffff097          	auipc	ra,0xfffff
    80003e84:	4b4080e7          	jalr	1204(ra) # 80003334 <brelse>
  }

  if(off > ip->size)
    80003e88:	04cb2783          	lw	a5,76(s6)
    80003e8c:	0127f463          	bgeu	a5,s2,80003e94 <writei+0xe2>
    ip->size = off;
    80003e90:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e94:	855a                	mv	a0,s6
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	aa6080e7          	jalr	-1370(ra) # 8000393c <iupdate>

  return tot;
    80003e9e:	000a051b          	sext.w	a0,s4
}
    80003ea2:	70a6                	ld	ra,104(sp)
    80003ea4:	7406                	ld	s0,96(sp)
    80003ea6:	64e6                	ld	s1,88(sp)
    80003ea8:	6946                	ld	s2,80(sp)
    80003eaa:	69a6                	ld	s3,72(sp)
    80003eac:	6a06                	ld	s4,64(sp)
    80003eae:	7ae2                	ld	s5,56(sp)
    80003eb0:	7b42                	ld	s6,48(sp)
    80003eb2:	7ba2                	ld	s7,40(sp)
    80003eb4:	7c02                	ld	s8,32(sp)
    80003eb6:	6ce2                	ld	s9,24(sp)
    80003eb8:	6d42                	ld	s10,16(sp)
    80003eba:	6da2                	ld	s11,8(sp)
    80003ebc:	6165                	addi	sp,sp,112
    80003ebe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ec0:	8a5e                	mv	s4,s7
    80003ec2:	bfc9                	j	80003e94 <writei+0xe2>
    return -1;
    80003ec4:	557d                	li	a0,-1
}
    80003ec6:	8082                	ret
    return -1;
    80003ec8:	557d                	li	a0,-1
    80003eca:	bfe1                	j	80003ea2 <writei+0xf0>
    return -1;
    80003ecc:	557d                	li	a0,-1
    80003ece:	bfd1                	j	80003ea2 <writei+0xf0>

0000000080003ed0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ed0:	1141                	addi	sp,sp,-16
    80003ed2:	e406                	sd	ra,8(sp)
    80003ed4:	e022                	sd	s0,0(sp)
    80003ed6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ed8:	4639                	li	a2,14
    80003eda:	ffffd097          	auipc	ra,0xffffd
    80003ede:	ebc080e7          	jalr	-324(ra) # 80000d96 <strncmp>
}
    80003ee2:	60a2                	ld	ra,8(sp)
    80003ee4:	6402                	ld	s0,0(sp)
    80003ee6:	0141                	addi	sp,sp,16
    80003ee8:	8082                	ret

0000000080003eea <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eea:	7139                	addi	sp,sp,-64
    80003eec:	fc06                	sd	ra,56(sp)
    80003eee:	f822                	sd	s0,48(sp)
    80003ef0:	f426                	sd	s1,40(sp)
    80003ef2:	f04a                	sd	s2,32(sp)
    80003ef4:	ec4e                	sd	s3,24(sp)
    80003ef6:	e852                	sd	s4,16(sp)
    80003ef8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003efa:	04451703          	lh	a4,68(a0)
    80003efe:	4785                	li	a5,1
    80003f00:	00f71a63          	bne	a4,a5,80003f14 <dirlookup+0x2a>
    80003f04:	892a                	mv	s2,a0
    80003f06:	89ae                	mv	s3,a1
    80003f08:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0a:	457c                	lw	a5,76(a0)
    80003f0c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f0e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f10:	e79d                	bnez	a5,80003f3e <dirlookup+0x54>
    80003f12:	a8a5                	j	80003f8a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f14:	00004517          	auipc	a0,0x4
    80003f18:	7a450513          	addi	a0,a0,1956 # 800086b8 <syscalls+0x1a8>
    80003f1c:	ffffc097          	auipc	ra,0xffffc
    80003f20:	60e080e7          	jalr	1550(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003f24:	00004517          	auipc	a0,0x4
    80003f28:	7ac50513          	addi	a0,a0,1964 # 800086d0 <syscalls+0x1c0>
    80003f2c:	ffffc097          	auipc	ra,0xffffc
    80003f30:	5fe080e7          	jalr	1534(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f34:	24c1                	addiw	s1,s1,16
    80003f36:	04c92783          	lw	a5,76(s2)
    80003f3a:	04f4f763          	bgeu	s1,a5,80003f88 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f3e:	4741                	li	a4,16
    80003f40:	86a6                	mv	a3,s1
    80003f42:	fc040613          	addi	a2,s0,-64
    80003f46:	4581                	li	a1,0
    80003f48:	854a                	mv	a0,s2
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	d70080e7          	jalr	-656(ra) # 80003cba <readi>
    80003f52:	47c1                	li	a5,16
    80003f54:	fcf518e3          	bne	a0,a5,80003f24 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f58:	fc045783          	lhu	a5,-64(s0)
    80003f5c:	dfe1                	beqz	a5,80003f34 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f5e:	fc240593          	addi	a1,s0,-62
    80003f62:	854e                	mv	a0,s3
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	f6c080e7          	jalr	-148(ra) # 80003ed0 <namecmp>
    80003f6c:	f561                	bnez	a0,80003f34 <dirlookup+0x4a>
      if(poff)
    80003f6e:	000a0463          	beqz	s4,80003f76 <dirlookup+0x8c>
        *poff = off;
    80003f72:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f76:	fc045583          	lhu	a1,-64(s0)
    80003f7a:	00092503          	lw	a0,0(s2)
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	754080e7          	jalr	1876(ra) # 800036d2 <iget>
    80003f86:	a011                	j	80003f8a <dirlookup+0xa0>
  return 0;
    80003f88:	4501                	li	a0,0
}
    80003f8a:	70e2                	ld	ra,56(sp)
    80003f8c:	7442                	ld	s0,48(sp)
    80003f8e:	74a2                	ld	s1,40(sp)
    80003f90:	7902                	ld	s2,32(sp)
    80003f92:	69e2                	ld	s3,24(sp)
    80003f94:	6a42                	ld	s4,16(sp)
    80003f96:	6121                	addi	sp,sp,64
    80003f98:	8082                	ret

0000000080003f9a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f9a:	711d                	addi	sp,sp,-96
    80003f9c:	ec86                	sd	ra,88(sp)
    80003f9e:	e8a2                	sd	s0,80(sp)
    80003fa0:	e4a6                	sd	s1,72(sp)
    80003fa2:	e0ca                	sd	s2,64(sp)
    80003fa4:	fc4e                	sd	s3,56(sp)
    80003fa6:	f852                	sd	s4,48(sp)
    80003fa8:	f456                	sd	s5,40(sp)
    80003faa:	f05a                	sd	s6,32(sp)
    80003fac:	ec5e                	sd	s7,24(sp)
    80003fae:	e862                	sd	s8,16(sp)
    80003fb0:	e466                	sd	s9,8(sp)
    80003fb2:	1080                	addi	s0,sp,96
    80003fb4:	84aa                	mv	s1,a0
    80003fb6:	8aae                	mv	s5,a1
    80003fb8:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fba:	00054703          	lbu	a4,0(a0)
    80003fbe:	02f00793          	li	a5,47
    80003fc2:	02f70363          	beq	a4,a5,80003fe8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fc6:	ffffe097          	auipc	ra,0xffffe
    80003fca:	bb2080e7          	jalr	-1102(ra) # 80001b78 <myproc>
    80003fce:	15053503          	ld	a0,336(a0)
    80003fd2:	00000097          	auipc	ra,0x0
    80003fd6:	9f6080e7          	jalr	-1546(ra) # 800039c8 <idup>
    80003fda:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fdc:	02f00913          	li	s2,47
  len = path - s;
    80003fe0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fe2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fe4:	4b85                	li	s7,1
    80003fe6:	a865                	j	8000409e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fe8:	4585                	li	a1,1
    80003fea:	4505                	li	a0,1
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	6e6080e7          	jalr	1766(ra) # 800036d2 <iget>
    80003ff4:	89aa                	mv	s3,a0
    80003ff6:	b7dd                	j	80003fdc <namex+0x42>
      iunlockput(ip);
    80003ff8:	854e                	mv	a0,s3
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	c6e080e7          	jalr	-914(ra) # 80003c68 <iunlockput>
      return 0;
    80004002:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004004:	854e                	mv	a0,s3
    80004006:	60e6                	ld	ra,88(sp)
    80004008:	6446                	ld	s0,80(sp)
    8000400a:	64a6                	ld	s1,72(sp)
    8000400c:	6906                	ld	s2,64(sp)
    8000400e:	79e2                	ld	s3,56(sp)
    80004010:	7a42                	ld	s4,48(sp)
    80004012:	7aa2                	ld	s5,40(sp)
    80004014:	7b02                	ld	s6,32(sp)
    80004016:	6be2                	ld	s7,24(sp)
    80004018:	6c42                	ld	s8,16(sp)
    8000401a:	6ca2                	ld	s9,8(sp)
    8000401c:	6125                	addi	sp,sp,96
    8000401e:	8082                	ret
      iunlock(ip);
    80004020:	854e                	mv	a0,s3
    80004022:	00000097          	auipc	ra,0x0
    80004026:	aa6080e7          	jalr	-1370(ra) # 80003ac8 <iunlock>
      return ip;
    8000402a:	bfe9                	j	80004004 <namex+0x6a>
      iunlockput(ip);
    8000402c:	854e                	mv	a0,s3
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	c3a080e7          	jalr	-966(ra) # 80003c68 <iunlockput>
      return 0;
    80004036:	89e6                	mv	s3,s9
    80004038:	b7f1                	j	80004004 <namex+0x6a>
  len = path - s;
    8000403a:	40b48633          	sub	a2,s1,a1
    8000403e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004042:	099c5463          	bge	s8,s9,800040ca <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004046:	4639                	li	a2,14
    80004048:	8552                	mv	a0,s4
    8000404a:	ffffd097          	auipc	ra,0xffffd
    8000404e:	cd0080e7          	jalr	-816(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004052:	0004c783          	lbu	a5,0(s1)
    80004056:	01279763          	bne	a5,s2,80004064 <namex+0xca>
    path++;
    8000405a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000405c:	0004c783          	lbu	a5,0(s1)
    80004060:	ff278de3          	beq	a5,s2,8000405a <namex+0xc0>
    ilock(ip);
    80004064:	854e                	mv	a0,s3
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	9a0080e7          	jalr	-1632(ra) # 80003a06 <ilock>
    if(ip->type != T_DIR){
    8000406e:	04499783          	lh	a5,68(s3)
    80004072:	f97793e3          	bne	a5,s7,80003ff8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004076:	000a8563          	beqz	s5,80004080 <namex+0xe6>
    8000407a:	0004c783          	lbu	a5,0(s1)
    8000407e:	d3cd                	beqz	a5,80004020 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004080:	865a                	mv	a2,s6
    80004082:	85d2                	mv	a1,s4
    80004084:	854e                	mv	a0,s3
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	e64080e7          	jalr	-412(ra) # 80003eea <dirlookup>
    8000408e:	8caa                	mv	s9,a0
    80004090:	dd51                	beqz	a0,8000402c <namex+0x92>
    iunlockput(ip);
    80004092:	854e                	mv	a0,s3
    80004094:	00000097          	auipc	ra,0x0
    80004098:	bd4080e7          	jalr	-1068(ra) # 80003c68 <iunlockput>
    ip = next;
    8000409c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000409e:	0004c783          	lbu	a5,0(s1)
    800040a2:	05279763          	bne	a5,s2,800040f0 <namex+0x156>
    path++;
    800040a6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040a8:	0004c783          	lbu	a5,0(s1)
    800040ac:	ff278de3          	beq	a5,s2,800040a6 <namex+0x10c>
  if(*path == 0)
    800040b0:	c79d                	beqz	a5,800040de <namex+0x144>
    path++;
    800040b2:	85a6                	mv	a1,s1
  len = path - s;
    800040b4:	8cda                	mv	s9,s6
    800040b6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800040b8:	01278963          	beq	a5,s2,800040ca <namex+0x130>
    800040bc:	dfbd                	beqz	a5,8000403a <namex+0xa0>
    path++;
    800040be:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040c0:	0004c783          	lbu	a5,0(s1)
    800040c4:	ff279ce3          	bne	a5,s2,800040bc <namex+0x122>
    800040c8:	bf8d                	j	8000403a <namex+0xa0>
    memmove(name, s, len);
    800040ca:	2601                	sext.w	a2,a2
    800040cc:	8552                	mv	a0,s4
    800040ce:	ffffd097          	auipc	ra,0xffffd
    800040d2:	c4c080e7          	jalr	-948(ra) # 80000d1a <memmove>
    name[len] = 0;
    800040d6:	9cd2                	add	s9,s9,s4
    800040d8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800040dc:	bf9d                	j	80004052 <namex+0xb8>
  if(nameiparent){
    800040de:	f20a83e3          	beqz	s5,80004004 <namex+0x6a>
    iput(ip);
    800040e2:	854e                	mv	a0,s3
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	adc080e7          	jalr	-1316(ra) # 80003bc0 <iput>
    return 0;
    800040ec:	4981                	li	s3,0
    800040ee:	bf19                	j	80004004 <namex+0x6a>
  if(*path == 0)
    800040f0:	d7fd                	beqz	a5,800040de <namex+0x144>
  while(*path != '/' && *path != 0)
    800040f2:	0004c783          	lbu	a5,0(s1)
    800040f6:	85a6                	mv	a1,s1
    800040f8:	b7d1                	j	800040bc <namex+0x122>

00000000800040fa <dirlink>:
{
    800040fa:	7139                	addi	sp,sp,-64
    800040fc:	fc06                	sd	ra,56(sp)
    800040fe:	f822                	sd	s0,48(sp)
    80004100:	f426                	sd	s1,40(sp)
    80004102:	f04a                	sd	s2,32(sp)
    80004104:	ec4e                	sd	s3,24(sp)
    80004106:	e852                	sd	s4,16(sp)
    80004108:	0080                	addi	s0,sp,64
    8000410a:	892a                	mv	s2,a0
    8000410c:	8a2e                	mv	s4,a1
    8000410e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004110:	4601                	li	a2,0
    80004112:	00000097          	auipc	ra,0x0
    80004116:	dd8080e7          	jalr	-552(ra) # 80003eea <dirlookup>
    8000411a:	e93d                	bnez	a0,80004190 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000411c:	04c92483          	lw	s1,76(s2)
    80004120:	c49d                	beqz	s1,8000414e <dirlink+0x54>
    80004122:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004124:	4741                	li	a4,16
    80004126:	86a6                	mv	a3,s1
    80004128:	fc040613          	addi	a2,s0,-64
    8000412c:	4581                	li	a1,0
    8000412e:	854a                	mv	a0,s2
    80004130:	00000097          	auipc	ra,0x0
    80004134:	b8a080e7          	jalr	-1142(ra) # 80003cba <readi>
    80004138:	47c1                	li	a5,16
    8000413a:	06f51163          	bne	a0,a5,8000419c <dirlink+0xa2>
    if(de.inum == 0)
    8000413e:	fc045783          	lhu	a5,-64(s0)
    80004142:	c791                	beqz	a5,8000414e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004144:	24c1                	addiw	s1,s1,16
    80004146:	04c92783          	lw	a5,76(s2)
    8000414a:	fcf4ede3          	bltu	s1,a5,80004124 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000414e:	4639                	li	a2,14
    80004150:	85d2                	mv	a1,s4
    80004152:	fc240513          	addi	a0,s0,-62
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	c7c080e7          	jalr	-900(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    8000415e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004162:	4741                	li	a4,16
    80004164:	86a6                	mv	a3,s1
    80004166:	fc040613          	addi	a2,s0,-64
    8000416a:	4581                	li	a1,0
    8000416c:	854a                	mv	a0,s2
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	c44080e7          	jalr	-956(ra) # 80003db2 <writei>
    80004176:	872a                	mv	a4,a0
    80004178:	47c1                	li	a5,16
  return 0;
    8000417a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000417c:	02f71863          	bne	a4,a5,800041ac <dirlink+0xb2>
}
    80004180:	70e2                	ld	ra,56(sp)
    80004182:	7442                	ld	s0,48(sp)
    80004184:	74a2                	ld	s1,40(sp)
    80004186:	7902                	ld	s2,32(sp)
    80004188:	69e2                	ld	s3,24(sp)
    8000418a:	6a42                	ld	s4,16(sp)
    8000418c:	6121                	addi	sp,sp,64
    8000418e:	8082                	ret
    iput(ip);
    80004190:	00000097          	auipc	ra,0x0
    80004194:	a30080e7          	jalr	-1488(ra) # 80003bc0 <iput>
    return -1;
    80004198:	557d                	li	a0,-1
    8000419a:	b7dd                	j	80004180 <dirlink+0x86>
      panic("dirlink read");
    8000419c:	00004517          	auipc	a0,0x4
    800041a0:	54450513          	addi	a0,a0,1348 # 800086e0 <syscalls+0x1d0>
    800041a4:	ffffc097          	auipc	ra,0xffffc
    800041a8:	386080e7          	jalr	902(ra) # 8000052a <panic>
    panic("dirlink");
    800041ac:	00004517          	auipc	a0,0x4
    800041b0:	64450513          	addi	a0,a0,1604 # 800087f0 <syscalls+0x2e0>
    800041b4:	ffffc097          	auipc	ra,0xffffc
    800041b8:	376080e7          	jalr	886(ra) # 8000052a <panic>

00000000800041bc <namei>:

struct inode*
namei(char *path)
{
    800041bc:	1101                	addi	sp,sp,-32
    800041be:	ec06                	sd	ra,24(sp)
    800041c0:	e822                	sd	s0,16(sp)
    800041c2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041c4:	fe040613          	addi	a2,s0,-32
    800041c8:	4581                	li	a1,0
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	dd0080e7          	jalr	-560(ra) # 80003f9a <namex>
}
    800041d2:	60e2                	ld	ra,24(sp)
    800041d4:	6442                	ld	s0,16(sp)
    800041d6:	6105                	addi	sp,sp,32
    800041d8:	8082                	ret

00000000800041da <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041da:	1141                	addi	sp,sp,-16
    800041dc:	e406                	sd	ra,8(sp)
    800041de:	e022                	sd	s0,0(sp)
    800041e0:	0800                	addi	s0,sp,16
    800041e2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041e4:	4585                	li	a1,1
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	db4080e7          	jalr	-588(ra) # 80003f9a <namex>
}
    800041ee:	60a2                	ld	ra,8(sp)
    800041f0:	6402                	ld	s0,0(sp)
    800041f2:	0141                	addi	sp,sp,16
    800041f4:	8082                	ret

00000000800041f6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041f6:	1101                	addi	sp,sp,-32
    800041f8:	ec06                	sd	ra,24(sp)
    800041fa:	e822                	sd	s0,16(sp)
    800041fc:	e426                	sd	s1,8(sp)
    800041fe:	e04a                	sd	s2,0(sp)
    80004200:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004202:	0001e917          	auipc	s2,0x1e
    80004206:	89e90913          	addi	s2,s2,-1890 # 80021aa0 <log>
    8000420a:	01892583          	lw	a1,24(s2)
    8000420e:	02892503          	lw	a0,40(s2)
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	ff2080e7          	jalr	-14(ra) # 80003204 <bread>
    8000421a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000421c:	02c92683          	lw	a3,44(s2)
    80004220:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004222:	02d05763          	blez	a3,80004250 <write_head+0x5a>
    80004226:	0001e797          	auipc	a5,0x1e
    8000422a:	8aa78793          	addi	a5,a5,-1878 # 80021ad0 <log+0x30>
    8000422e:	05c50713          	addi	a4,a0,92
    80004232:	36fd                	addiw	a3,a3,-1
    80004234:	1682                	slli	a3,a3,0x20
    80004236:	9281                	srli	a3,a3,0x20
    80004238:	068a                	slli	a3,a3,0x2
    8000423a:	0001e617          	auipc	a2,0x1e
    8000423e:	89a60613          	addi	a2,a2,-1894 # 80021ad4 <log+0x34>
    80004242:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004244:	4390                	lw	a2,0(a5)
    80004246:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004248:	0791                	addi	a5,a5,4
    8000424a:	0711                	addi	a4,a4,4
    8000424c:	fed79ce3          	bne	a5,a3,80004244 <write_head+0x4e>
  }
  bwrite(buf);
    80004250:	8526                	mv	a0,s1
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	0a4080e7          	jalr	164(ra) # 800032f6 <bwrite>
  brelse(buf);
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	0d8080e7          	jalr	216(ra) # 80003334 <brelse>
}
    80004264:	60e2                	ld	ra,24(sp)
    80004266:	6442                	ld	s0,16(sp)
    80004268:	64a2                	ld	s1,8(sp)
    8000426a:	6902                	ld	s2,0(sp)
    8000426c:	6105                	addi	sp,sp,32
    8000426e:	8082                	ret

0000000080004270 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004270:	0001e797          	auipc	a5,0x1e
    80004274:	85c7a783          	lw	a5,-1956(a5) # 80021acc <log+0x2c>
    80004278:	0af05d63          	blez	a5,80004332 <install_trans+0xc2>
{
    8000427c:	7139                	addi	sp,sp,-64
    8000427e:	fc06                	sd	ra,56(sp)
    80004280:	f822                	sd	s0,48(sp)
    80004282:	f426                	sd	s1,40(sp)
    80004284:	f04a                	sd	s2,32(sp)
    80004286:	ec4e                	sd	s3,24(sp)
    80004288:	e852                	sd	s4,16(sp)
    8000428a:	e456                	sd	s5,8(sp)
    8000428c:	e05a                	sd	s6,0(sp)
    8000428e:	0080                	addi	s0,sp,64
    80004290:	8b2a                	mv	s6,a0
    80004292:	0001ea97          	auipc	s5,0x1e
    80004296:	83ea8a93          	addi	s5,s5,-1986 # 80021ad0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000429c:	0001e997          	auipc	s3,0x1e
    800042a0:	80498993          	addi	s3,s3,-2044 # 80021aa0 <log>
    800042a4:	a00d                	j	800042c6 <install_trans+0x56>
    brelse(lbuf);
    800042a6:	854a                	mv	a0,s2
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	08c080e7          	jalr	140(ra) # 80003334 <brelse>
    brelse(dbuf);
    800042b0:	8526                	mv	a0,s1
    800042b2:	fffff097          	auipc	ra,0xfffff
    800042b6:	082080e7          	jalr	130(ra) # 80003334 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ba:	2a05                	addiw	s4,s4,1
    800042bc:	0a91                	addi	s5,s5,4
    800042be:	02c9a783          	lw	a5,44(s3)
    800042c2:	04fa5e63          	bge	s4,a5,8000431e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042c6:	0189a583          	lw	a1,24(s3)
    800042ca:	014585bb          	addw	a1,a1,s4
    800042ce:	2585                	addiw	a1,a1,1
    800042d0:	0289a503          	lw	a0,40(s3)
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	f30080e7          	jalr	-208(ra) # 80003204 <bread>
    800042dc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042de:	000aa583          	lw	a1,0(s5)
    800042e2:	0289a503          	lw	a0,40(s3)
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	f1e080e7          	jalr	-226(ra) # 80003204 <bread>
    800042ee:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042f0:	40000613          	li	a2,1024
    800042f4:	05890593          	addi	a1,s2,88
    800042f8:	05850513          	addi	a0,a0,88
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	a1e080e7          	jalr	-1506(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004304:	8526                	mv	a0,s1
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	ff0080e7          	jalr	-16(ra) # 800032f6 <bwrite>
    if(recovering == 0)
    8000430e:	f80b1ce3          	bnez	s6,800042a6 <install_trans+0x36>
      bunpin(dbuf);
    80004312:	8526                	mv	a0,s1
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	0fa080e7          	jalr	250(ra) # 8000340e <bunpin>
    8000431c:	b769                	j	800042a6 <install_trans+0x36>
}
    8000431e:	70e2                	ld	ra,56(sp)
    80004320:	7442                	ld	s0,48(sp)
    80004322:	74a2                	ld	s1,40(sp)
    80004324:	7902                	ld	s2,32(sp)
    80004326:	69e2                	ld	s3,24(sp)
    80004328:	6a42                	ld	s4,16(sp)
    8000432a:	6aa2                	ld	s5,8(sp)
    8000432c:	6b02                	ld	s6,0(sp)
    8000432e:	6121                	addi	sp,sp,64
    80004330:	8082                	ret
    80004332:	8082                	ret

0000000080004334 <initlog>:
{
    80004334:	7179                	addi	sp,sp,-48
    80004336:	f406                	sd	ra,40(sp)
    80004338:	f022                	sd	s0,32(sp)
    8000433a:	ec26                	sd	s1,24(sp)
    8000433c:	e84a                	sd	s2,16(sp)
    8000433e:	e44e                	sd	s3,8(sp)
    80004340:	1800                	addi	s0,sp,48
    80004342:	892a                	mv	s2,a0
    80004344:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004346:	0001d497          	auipc	s1,0x1d
    8000434a:	75a48493          	addi	s1,s1,1882 # 80021aa0 <log>
    8000434e:	00004597          	auipc	a1,0x4
    80004352:	3a258593          	addi	a1,a1,930 # 800086f0 <syscalls+0x1e0>
    80004356:	8526                	mv	a0,s1
    80004358:	ffffc097          	auipc	ra,0xffffc
    8000435c:	7da080e7          	jalr	2010(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004360:	0149a583          	lw	a1,20(s3)
    80004364:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004366:	0109a783          	lw	a5,16(s3)
    8000436a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000436c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004370:	854a                	mv	a0,s2
    80004372:	fffff097          	auipc	ra,0xfffff
    80004376:	e92080e7          	jalr	-366(ra) # 80003204 <bread>
  log.lh.n = lh->n;
    8000437a:	4d34                	lw	a3,88(a0)
    8000437c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000437e:	02d05563          	blez	a3,800043a8 <initlog+0x74>
    80004382:	05c50793          	addi	a5,a0,92
    80004386:	0001d717          	auipc	a4,0x1d
    8000438a:	74a70713          	addi	a4,a4,1866 # 80021ad0 <log+0x30>
    8000438e:	36fd                	addiw	a3,a3,-1
    80004390:	1682                	slli	a3,a3,0x20
    80004392:	9281                	srli	a3,a3,0x20
    80004394:	068a                	slli	a3,a3,0x2
    80004396:	06050613          	addi	a2,a0,96
    8000439a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000439c:	4390                	lw	a2,0(a5)
    8000439e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043a0:	0791                	addi	a5,a5,4
    800043a2:	0711                	addi	a4,a4,4
    800043a4:	fed79ce3          	bne	a5,a3,8000439c <initlog+0x68>
  brelse(buf);
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	f8c080e7          	jalr	-116(ra) # 80003334 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043b0:	4505                	li	a0,1
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	ebe080e7          	jalr	-322(ra) # 80004270 <install_trans>
  log.lh.n = 0;
    800043ba:	0001d797          	auipc	a5,0x1d
    800043be:	7007a923          	sw	zero,1810(a5) # 80021acc <log+0x2c>
  write_head(); // clear the log
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	e34080e7          	jalr	-460(ra) # 800041f6 <write_head>
}
    800043ca:	70a2                	ld	ra,40(sp)
    800043cc:	7402                	ld	s0,32(sp)
    800043ce:	64e2                	ld	s1,24(sp)
    800043d0:	6942                	ld	s2,16(sp)
    800043d2:	69a2                	ld	s3,8(sp)
    800043d4:	6145                	addi	sp,sp,48
    800043d6:	8082                	ret

00000000800043d8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043d8:	1101                	addi	sp,sp,-32
    800043da:	ec06                	sd	ra,24(sp)
    800043dc:	e822                	sd	s0,16(sp)
    800043de:	e426                	sd	s1,8(sp)
    800043e0:	e04a                	sd	s2,0(sp)
    800043e2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043e4:	0001d517          	auipc	a0,0x1d
    800043e8:	6bc50513          	addi	a0,a0,1724 # 80021aa0 <log>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	7d6080e7          	jalr	2006(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800043f4:	0001d497          	auipc	s1,0x1d
    800043f8:	6ac48493          	addi	s1,s1,1708 # 80021aa0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043fc:	4979                	li	s2,30
    800043fe:	a039                	j	8000440c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004400:	85a6                	mv	a1,s1
    80004402:	8526                	mv	a0,s1
    80004404:	ffffe097          	auipc	ra,0xffffe
    80004408:	fca080e7          	jalr	-54(ra) # 800023ce <sleep>
    if(log.committing){
    8000440c:	50dc                	lw	a5,36(s1)
    8000440e:	fbed                	bnez	a5,80004400 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004410:	509c                	lw	a5,32(s1)
    80004412:	0017871b          	addiw	a4,a5,1
    80004416:	0007069b          	sext.w	a3,a4
    8000441a:	0027179b          	slliw	a5,a4,0x2
    8000441e:	9fb9                	addw	a5,a5,a4
    80004420:	0017979b          	slliw	a5,a5,0x1
    80004424:	54d8                	lw	a4,44(s1)
    80004426:	9fb9                	addw	a5,a5,a4
    80004428:	00f95963          	bge	s2,a5,8000443a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000442c:	85a6                	mv	a1,s1
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	f9e080e7          	jalr	-98(ra) # 800023ce <sleep>
    80004438:	bfd1                	j	8000440c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000443a:	0001d517          	auipc	a0,0x1d
    8000443e:	66650513          	addi	a0,a0,1638 # 80021aa0 <log>
    80004442:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	832080e7          	jalr	-1998(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000444c:	60e2                	ld	ra,24(sp)
    8000444e:	6442                	ld	s0,16(sp)
    80004450:	64a2                	ld	s1,8(sp)
    80004452:	6902                	ld	s2,0(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret

0000000080004458 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004458:	7139                	addi	sp,sp,-64
    8000445a:	fc06                	sd	ra,56(sp)
    8000445c:	f822                	sd	s0,48(sp)
    8000445e:	f426                	sd	s1,40(sp)
    80004460:	f04a                	sd	s2,32(sp)
    80004462:	ec4e                	sd	s3,24(sp)
    80004464:	e852                	sd	s4,16(sp)
    80004466:	e456                	sd	s5,8(sp)
    80004468:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000446a:	0001d497          	auipc	s1,0x1d
    8000446e:	63648493          	addi	s1,s1,1590 # 80021aa0 <log>
    80004472:	8526                	mv	a0,s1
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	74e080e7          	jalr	1870(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000447c:	509c                	lw	a5,32(s1)
    8000447e:	37fd                	addiw	a5,a5,-1
    80004480:	0007891b          	sext.w	s2,a5
    80004484:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004486:	50dc                	lw	a5,36(s1)
    80004488:	e7b9                	bnez	a5,800044d6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000448a:	04091e63          	bnez	s2,800044e6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000448e:	0001d497          	auipc	s1,0x1d
    80004492:	61248493          	addi	s1,s1,1554 # 80021aa0 <log>
    80004496:	4785                	li	a5,1
    80004498:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000449a:	8526                	mv	a0,s1
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	7da080e7          	jalr	2010(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044a4:	54dc                	lw	a5,44(s1)
    800044a6:	06f04763          	bgtz	a5,80004514 <end_op+0xbc>
    acquire(&log.lock);
    800044aa:	0001d497          	auipc	s1,0x1d
    800044ae:	5f648493          	addi	s1,s1,1526 # 80021aa0 <log>
    800044b2:	8526                	mv	a0,s1
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	70e080e7          	jalr	1806(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800044bc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044c0:	8526                	mv	a0,s1
    800044c2:	ffffe097          	auipc	ra,0xffffe
    800044c6:	098080e7          	jalr	152(ra) # 8000255a <wakeup>
    release(&log.lock);
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7aa080e7          	jalr	1962(ra) # 80000c76 <release>
}
    800044d4:	a03d                	j	80004502 <end_op+0xaa>
    panic("log.committing");
    800044d6:	00004517          	auipc	a0,0x4
    800044da:	22250513          	addi	a0,a0,546 # 800086f8 <syscalls+0x1e8>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	04c080e7          	jalr	76(ra) # 8000052a <panic>
    wakeup(&log);
    800044e6:	0001d497          	auipc	s1,0x1d
    800044ea:	5ba48493          	addi	s1,s1,1466 # 80021aa0 <log>
    800044ee:	8526                	mv	a0,s1
    800044f0:	ffffe097          	auipc	ra,0xffffe
    800044f4:	06a080e7          	jalr	106(ra) # 8000255a <wakeup>
  release(&log.lock);
    800044f8:	8526                	mv	a0,s1
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	77c080e7          	jalr	1916(ra) # 80000c76 <release>
}
    80004502:	70e2                	ld	ra,56(sp)
    80004504:	7442                	ld	s0,48(sp)
    80004506:	74a2                	ld	s1,40(sp)
    80004508:	7902                	ld	s2,32(sp)
    8000450a:	69e2                	ld	s3,24(sp)
    8000450c:	6a42                	ld	s4,16(sp)
    8000450e:	6aa2                	ld	s5,8(sp)
    80004510:	6121                	addi	sp,sp,64
    80004512:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004514:	0001da97          	auipc	s5,0x1d
    80004518:	5bca8a93          	addi	s5,s5,1468 # 80021ad0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000451c:	0001da17          	auipc	s4,0x1d
    80004520:	584a0a13          	addi	s4,s4,1412 # 80021aa0 <log>
    80004524:	018a2583          	lw	a1,24(s4)
    80004528:	012585bb          	addw	a1,a1,s2
    8000452c:	2585                	addiw	a1,a1,1
    8000452e:	028a2503          	lw	a0,40(s4)
    80004532:	fffff097          	auipc	ra,0xfffff
    80004536:	cd2080e7          	jalr	-814(ra) # 80003204 <bread>
    8000453a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000453c:	000aa583          	lw	a1,0(s5)
    80004540:	028a2503          	lw	a0,40(s4)
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	cc0080e7          	jalr	-832(ra) # 80003204 <bread>
    8000454c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000454e:	40000613          	li	a2,1024
    80004552:	05850593          	addi	a1,a0,88
    80004556:	05848513          	addi	a0,s1,88
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	7c0080e7          	jalr	1984(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004562:	8526                	mv	a0,s1
    80004564:	fffff097          	auipc	ra,0xfffff
    80004568:	d92080e7          	jalr	-622(ra) # 800032f6 <bwrite>
    brelse(from);
    8000456c:	854e                	mv	a0,s3
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	dc6080e7          	jalr	-570(ra) # 80003334 <brelse>
    brelse(to);
    80004576:	8526                	mv	a0,s1
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	dbc080e7          	jalr	-580(ra) # 80003334 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004580:	2905                	addiw	s2,s2,1
    80004582:	0a91                	addi	s5,s5,4
    80004584:	02ca2783          	lw	a5,44(s4)
    80004588:	f8f94ee3          	blt	s2,a5,80004524 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	c6a080e7          	jalr	-918(ra) # 800041f6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004594:	4501                	li	a0,0
    80004596:	00000097          	auipc	ra,0x0
    8000459a:	cda080e7          	jalr	-806(ra) # 80004270 <install_trans>
    log.lh.n = 0;
    8000459e:	0001d797          	auipc	a5,0x1d
    800045a2:	5207a723          	sw	zero,1326(a5) # 80021acc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	c50080e7          	jalr	-944(ra) # 800041f6 <write_head>
    800045ae:	bdf5                	j	800044aa <end_op+0x52>

00000000800045b0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045b0:	1101                	addi	sp,sp,-32
    800045b2:	ec06                	sd	ra,24(sp)
    800045b4:	e822                	sd	s0,16(sp)
    800045b6:	e426                	sd	s1,8(sp)
    800045b8:	e04a                	sd	s2,0(sp)
    800045ba:	1000                	addi	s0,sp,32
    800045bc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045be:	0001d917          	auipc	s2,0x1d
    800045c2:	4e290913          	addi	s2,s2,1250 # 80021aa0 <log>
    800045c6:	854a                	mv	a0,s2
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	5fa080e7          	jalr	1530(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045d0:	02c92603          	lw	a2,44(s2)
    800045d4:	47f5                	li	a5,29
    800045d6:	06c7c563          	blt	a5,a2,80004640 <log_write+0x90>
    800045da:	0001d797          	auipc	a5,0x1d
    800045de:	4e27a783          	lw	a5,1250(a5) # 80021abc <log+0x1c>
    800045e2:	37fd                	addiw	a5,a5,-1
    800045e4:	04f65e63          	bge	a2,a5,80004640 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045e8:	0001d797          	auipc	a5,0x1d
    800045ec:	4d87a783          	lw	a5,1240(a5) # 80021ac0 <log+0x20>
    800045f0:	06f05063          	blez	a5,80004650 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045f4:	4781                	li	a5,0
    800045f6:	06c05563          	blez	a2,80004660 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045fa:	44cc                	lw	a1,12(s1)
    800045fc:	0001d717          	auipc	a4,0x1d
    80004600:	4d470713          	addi	a4,a4,1236 # 80021ad0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004604:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004606:	4314                	lw	a3,0(a4)
    80004608:	04b68c63          	beq	a3,a1,80004660 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000460c:	2785                	addiw	a5,a5,1
    8000460e:	0711                	addi	a4,a4,4
    80004610:	fef61be3          	bne	a2,a5,80004606 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004614:	0621                	addi	a2,a2,8
    80004616:	060a                	slli	a2,a2,0x2
    80004618:	0001d797          	auipc	a5,0x1d
    8000461c:	48878793          	addi	a5,a5,1160 # 80021aa0 <log>
    80004620:	963e                	add	a2,a2,a5
    80004622:	44dc                	lw	a5,12(s1)
    80004624:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004626:	8526                	mv	a0,s1
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	daa080e7          	jalr	-598(ra) # 800033d2 <bpin>
    log.lh.n++;
    80004630:	0001d717          	auipc	a4,0x1d
    80004634:	47070713          	addi	a4,a4,1136 # 80021aa0 <log>
    80004638:	575c                	lw	a5,44(a4)
    8000463a:	2785                	addiw	a5,a5,1
    8000463c:	d75c                	sw	a5,44(a4)
    8000463e:	a835                	j	8000467a <log_write+0xca>
    panic("too big a transaction");
    80004640:	00004517          	auipc	a0,0x4
    80004644:	0c850513          	addi	a0,a0,200 # 80008708 <syscalls+0x1f8>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	ee2080e7          	jalr	-286(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004650:	00004517          	auipc	a0,0x4
    80004654:	0d050513          	addi	a0,a0,208 # 80008720 <syscalls+0x210>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	ed2080e7          	jalr	-302(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004660:	00878713          	addi	a4,a5,8
    80004664:	00271693          	slli	a3,a4,0x2
    80004668:	0001d717          	auipc	a4,0x1d
    8000466c:	43870713          	addi	a4,a4,1080 # 80021aa0 <log>
    80004670:	9736                	add	a4,a4,a3
    80004672:	44d4                	lw	a3,12(s1)
    80004674:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004676:	faf608e3          	beq	a2,a5,80004626 <log_write+0x76>
  }
  release(&log.lock);
    8000467a:	0001d517          	auipc	a0,0x1d
    8000467e:	42650513          	addi	a0,a0,1062 # 80021aa0 <log>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	5f4080e7          	jalr	1524(ra) # 80000c76 <release>
}
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	64a2                	ld	s1,8(sp)
    80004690:	6902                	ld	s2,0(sp)
    80004692:	6105                	addi	sp,sp,32
    80004694:	8082                	ret

0000000080004696 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	e04a                	sd	s2,0(sp)
    800046a0:	1000                	addi	s0,sp,32
    800046a2:	84aa                	mv	s1,a0
    800046a4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046a6:	00004597          	auipc	a1,0x4
    800046aa:	09a58593          	addi	a1,a1,154 # 80008740 <syscalls+0x230>
    800046ae:	0521                	addi	a0,a0,8
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	482080e7          	jalr	1154(ra) # 80000b32 <initlock>
  lk->name = name;
    800046b8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c0:	0204a423          	sw	zero,40(s1)
}
    800046c4:	60e2                	ld	ra,24(sp)
    800046c6:	6442                	ld	s0,16(sp)
    800046c8:	64a2                	ld	s1,8(sp)
    800046ca:	6902                	ld	s2,0(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret

00000000800046d0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	e04a                	sd	s2,0(sp)
    800046da:	1000                	addi	s0,sp,32
    800046dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046de:	00850913          	addi	s2,a0,8
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	4de080e7          	jalr	1246(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	cb89                	beqz	a5,80004700 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046f0:	85ca                	mv	a1,s2
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffe097          	auipc	ra,0xffffe
    800046f8:	cda080e7          	jalr	-806(ra) # 800023ce <sleep>
  while (lk->locked) {
    800046fc:	409c                	lw	a5,0(s1)
    800046fe:	fbed                	bnez	a5,800046f0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004700:	4785                	li	a5,1
    80004702:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004704:	ffffd097          	auipc	ra,0xffffd
    80004708:	474080e7          	jalr	1140(ra) # 80001b78 <myproc>
    8000470c:	591c                	lw	a5,48(a0)
    8000470e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004710:	854a                	mv	a0,s2
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	564080e7          	jalr	1380(ra) # 80000c76 <release>
}
    8000471a:	60e2                	ld	ra,24(sp)
    8000471c:	6442                	ld	s0,16(sp)
    8000471e:	64a2                	ld	s1,8(sp)
    80004720:	6902                	ld	s2,0(sp)
    80004722:	6105                	addi	sp,sp,32
    80004724:	8082                	ret

0000000080004726 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004726:	1101                	addi	sp,sp,-32
    80004728:	ec06                	sd	ra,24(sp)
    8000472a:	e822                	sd	s0,16(sp)
    8000472c:	e426                	sd	s1,8(sp)
    8000472e:	e04a                	sd	s2,0(sp)
    80004730:	1000                	addi	s0,sp,32
    80004732:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004734:	00850913          	addi	s2,a0,8
    80004738:	854a                	mv	a0,s2
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	488080e7          	jalr	1160(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004742:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004746:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000474a:	8526                	mv	a0,s1
    8000474c:	ffffe097          	auipc	ra,0xffffe
    80004750:	e0e080e7          	jalr	-498(ra) # 8000255a <wakeup>
  release(&lk->lk);
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	520080e7          	jalr	1312(ra) # 80000c76 <release>
}
    8000475e:	60e2                	ld	ra,24(sp)
    80004760:	6442                	ld	s0,16(sp)
    80004762:	64a2                	ld	s1,8(sp)
    80004764:	6902                	ld	s2,0(sp)
    80004766:	6105                	addi	sp,sp,32
    80004768:	8082                	ret

000000008000476a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000476a:	7179                	addi	sp,sp,-48
    8000476c:	f406                	sd	ra,40(sp)
    8000476e:	f022                	sd	s0,32(sp)
    80004770:	ec26                	sd	s1,24(sp)
    80004772:	e84a                	sd	s2,16(sp)
    80004774:	e44e                	sd	s3,8(sp)
    80004776:	1800                	addi	s0,sp,48
    80004778:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000477a:	00850913          	addi	s2,a0,8
    8000477e:	854a                	mv	a0,s2
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	442080e7          	jalr	1090(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004788:	409c                	lw	a5,0(s1)
    8000478a:	ef99                	bnez	a5,800047a8 <holdingsleep+0x3e>
    8000478c:	4481                	li	s1,0
  release(&lk->lk);
    8000478e:	854a                	mv	a0,s2
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	4e6080e7          	jalr	1254(ra) # 80000c76 <release>
  return r;
}
    80004798:	8526                	mv	a0,s1
    8000479a:	70a2                	ld	ra,40(sp)
    8000479c:	7402                	ld	s0,32(sp)
    8000479e:	64e2                	ld	s1,24(sp)
    800047a0:	6942                	ld	s2,16(sp)
    800047a2:	69a2                	ld	s3,8(sp)
    800047a4:	6145                	addi	sp,sp,48
    800047a6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047a8:	0284a983          	lw	s3,40(s1)
    800047ac:	ffffd097          	auipc	ra,0xffffd
    800047b0:	3cc080e7          	jalr	972(ra) # 80001b78 <myproc>
    800047b4:	5904                	lw	s1,48(a0)
    800047b6:	413484b3          	sub	s1,s1,s3
    800047ba:	0014b493          	seqz	s1,s1
    800047be:	bfc1                	j	8000478e <holdingsleep+0x24>

00000000800047c0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047c0:	1141                	addi	sp,sp,-16
    800047c2:	e406                	sd	ra,8(sp)
    800047c4:	e022                	sd	s0,0(sp)
    800047c6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047c8:	00004597          	auipc	a1,0x4
    800047cc:	f8858593          	addi	a1,a1,-120 # 80008750 <syscalls+0x240>
    800047d0:	0001d517          	auipc	a0,0x1d
    800047d4:	41850513          	addi	a0,a0,1048 # 80021be8 <ftable>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	35a080e7          	jalr	858(ra) # 80000b32 <initlock>
}
    800047e0:	60a2                	ld	ra,8(sp)
    800047e2:	6402                	ld	s0,0(sp)
    800047e4:	0141                	addi	sp,sp,16
    800047e6:	8082                	ret

00000000800047e8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047e8:	1101                	addi	sp,sp,-32
    800047ea:	ec06                	sd	ra,24(sp)
    800047ec:	e822                	sd	s0,16(sp)
    800047ee:	e426                	sd	s1,8(sp)
    800047f0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047f2:	0001d517          	auipc	a0,0x1d
    800047f6:	3f650513          	addi	a0,a0,1014 # 80021be8 <ftable>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	3c8080e7          	jalr	968(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004802:	0001d497          	auipc	s1,0x1d
    80004806:	3fe48493          	addi	s1,s1,1022 # 80021c00 <ftable+0x18>
    8000480a:	0001e717          	auipc	a4,0x1e
    8000480e:	39670713          	addi	a4,a4,918 # 80022ba0 <ftable+0xfb8>
    if(f->ref == 0){
    80004812:	40dc                	lw	a5,4(s1)
    80004814:	cf99                	beqz	a5,80004832 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004816:	02848493          	addi	s1,s1,40
    8000481a:	fee49ce3          	bne	s1,a4,80004812 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000481e:	0001d517          	auipc	a0,0x1d
    80004822:	3ca50513          	addi	a0,a0,970 # 80021be8 <ftable>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	450080e7          	jalr	1104(ra) # 80000c76 <release>
  return 0;
    8000482e:	4481                	li	s1,0
    80004830:	a819                	j	80004846 <filealloc+0x5e>
      f->ref = 1;
    80004832:	4785                	li	a5,1
    80004834:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004836:	0001d517          	auipc	a0,0x1d
    8000483a:	3b250513          	addi	a0,a0,946 # 80021be8 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	438080e7          	jalr	1080(ra) # 80000c76 <release>
}
    80004846:	8526                	mv	a0,s1
    80004848:	60e2                	ld	ra,24(sp)
    8000484a:	6442                	ld	s0,16(sp)
    8000484c:	64a2                	ld	s1,8(sp)
    8000484e:	6105                	addi	sp,sp,32
    80004850:	8082                	ret

0000000080004852 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004852:	1101                	addi	sp,sp,-32
    80004854:	ec06                	sd	ra,24(sp)
    80004856:	e822                	sd	s0,16(sp)
    80004858:	e426                	sd	s1,8(sp)
    8000485a:	1000                	addi	s0,sp,32
    8000485c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000485e:	0001d517          	auipc	a0,0x1d
    80004862:	38a50513          	addi	a0,a0,906 # 80021be8 <ftable>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	35c080e7          	jalr	860(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000486e:	40dc                	lw	a5,4(s1)
    80004870:	02f05263          	blez	a5,80004894 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004874:	2785                	addiw	a5,a5,1
    80004876:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004878:	0001d517          	auipc	a0,0x1d
    8000487c:	37050513          	addi	a0,a0,880 # 80021be8 <ftable>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	3f6080e7          	jalr	1014(ra) # 80000c76 <release>
  return f;
}
    80004888:	8526                	mv	a0,s1
    8000488a:	60e2                	ld	ra,24(sp)
    8000488c:	6442                	ld	s0,16(sp)
    8000488e:	64a2                	ld	s1,8(sp)
    80004890:	6105                	addi	sp,sp,32
    80004892:	8082                	ret
    panic("filedup");
    80004894:	00004517          	auipc	a0,0x4
    80004898:	ec450513          	addi	a0,a0,-316 # 80008758 <syscalls+0x248>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	c8e080e7          	jalr	-882(ra) # 8000052a <panic>

00000000800048a4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048a4:	7139                	addi	sp,sp,-64
    800048a6:	fc06                	sd	ra,56(sp)
    800048a8:	f822                	sd	s0,48(sp)
    800048aa:	f426                	sd	s1,40(sp)
    800048ac:	f04a                	sd	s2,32(sp)
    800048ae:	ec4e                	sd	s3,24(sp)
    800048b0:	e852                	sd	s4,16(sp)
    800048b2:	e456                	sd	s5,8(sp)
    800048b4:	0080                	addi	s0,sp,64
    800048b6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048b8:	0001d517          	auipc	a0,0x1d
    800048bc:	33050513          	addi	a0,a0,816 # 80021be8 <ftable>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	302080e7          	jalr	770(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800048c8:	40dc                	lw	a5,4(s1)
    800048ca:	06f05163          	blez	a5,8000492c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048ce:	37fd                	addiw	a5,a5,-1
    800048d0:	0007871b          	sext.w	a4,a5
    800048d4:	c0dc                	sw	a5,4(s1)
    800048d6:	06e04363          	bgtz	a4,8000493c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048da:	0004a903          	lw	s2,0(s1)
    800048de:	0094ca83          	lbu	s5,9(s1)
    800048e2:	0104ba03          	ld	s4,16(s1)
    800048e6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048ea:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048ee:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048f2:	0001d517          	auipc	a0,0x1d
    800048f6:	2f650513          	addi	a0,a0,758 # 80021be8 <ftable>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	37c080e7          	jalr	892(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004902:	4785                	li	a5,1
    80004904:	04f90d63          	beq	s2,a5,8000495e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004908:	3979                	addiw	s2,s2,-2
    8000490a:	4785                	li	a5,1
    8000490c:	0527e063          	bltu	a5,s2,8000494c <fileclose+0xa8>
    begin_op();
    80004910:	00000097          	auipc	ra,0x0
    80004914:	ac8080e7          	jalr	-1336(ra) # 800043d8 <begin_op>
    iput(ff.ip);
    80004918:	854e                	mv	a0,s3
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	2a6080e7          	jalr	678(ra) # 80003bc0 <iput>
    end_op();
    80004922:	00000097          	auipc	ra,0x0
    80004926:	b36080e7          	jalr	-1226(ra) # 80004458 <end_op>
    8000492a:	a00d                	j	8000494c <fileclose+0xa8>
    panic("fileclose");
    8000492c:	00004517          	auipc	a0,0x4
    80004930:	e3450513          	addi	a0,a0,-460 # 80008760 <syscalls+0x250>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	bf6080e7          	jalr	-1034(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000493c:	0001d517          	auipc	a0,0x1d
    80004940:	2ac50513          	addi	a0,a0,684 # 80021be8 <ftable>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	332080e7          	jalr	818(ra) # 80000c76 <release>
  }
}
    8000494c:	70e2                	ld	ra,56(sp)
    8000494e:	7442                	ld	s0,48(sp)
    80004950:	74a2                	ld	s1,40(sp)
    80004952:	7902                	ld	s2,32(sp)
    80004954:	69e2                	ld	s3,24(sp)
    80004956:	6a42                	ld	s4,16(sp)
    80004958:	6aa2                	ld	s5,8(sp)
    8000495a:	6121                	addi	sp,sp,64
    8000495c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000495e:	85d6                	mv	a1,s5
    80004960:	8552                	mv	a0,s4
    80004962:	00000097          	auipc	ra,0x0
    80004966:	34c080e7          	jalr	844(ra) # 80004cae <pipeclose>
    8000496a:	b7cd                	j	8000494c <fileclose+0xa8>

000000008000496c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000496c:	715d                	addi	sp,sp,-80
    8000496e:	e486                	sd	ra,72(sp)
    80004970:	e0a2                	sd	s0,64(sp)
    80004972:	fc26                	sd	s1,56(sp)
    80004974:	f84a                	sd	s2,48(sp)
    80004976:	f44e                	sd	s3,40(sp)
    80004978:	0880                	addi	s0,sp,80
    8000497a:	84aa                	mv	s1,a0
    8000497c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000497e:	ffffd097          	auipc	ra,0xffffd
    80004982:	1fa080e7          	jalr	506(ra) # 80001b78 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004986:	409c                	lw	a5,0(s1)
    80004988:	37f9                	addiw	a5,a5,-2
    8000498a:	4705                	li	a4,1
    8000498c:	04f76763          	bltu	a4,a5,800049da <filestat+0x6e>
    80004990:	892a                	mv	s2,a0
    ilock(f->ip);
    80004992:	6c88                	ld	a0,24(s1)
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	072080e7          	jalr	114(ra) # 80003a06 <ilock>
    stati(f->ip, &st);
    8000499c:	fb840593          	addi	a1,s0,-72
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	2ee080e7          	jalr	750(ra) # 80003c90 <stati>
    iunlock(f->ip);
    800049aa:	6c88                	ld	a0,24(s1)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	11c080e7          	jalr	284(ra) # 80003ac8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049b4:	46e1                	li	a3,24
    800049b6:	fb840613          	addi	a2,s0,-72
    800049ba:	85ce                	mv	a1,s3
    800049bc:	05093503          	ld	a0,80(s2)
    800049c0:	ffffd097          	auipc	ra,0xffffd
    800049c4:	c7e080e7          	jalr	-898(ra) # 8000163e <copyout>
    800049c8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049cc:	60a6                	ld	ra,72(sp)
    800049ce:	6406                	ld	s0,64(sp)
    800049d0:	74e2                	ld	s1,56(sp)
    800049d2:	7942                	ld	s2,48(sp)
    800049d4:	79a2                	ld	s3,40(sp)
    800049d6:	6161                	addi	sp,sp,80
    800049d8:	8082                	ret
  return -1;
    800049da:	557d                	li	a0,-1
    800049dc:	bfc5                	j	800049cc <filestat+0x60>

00000000800049de <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049de:	7179                	addi	sp,sp,-48
    800049e0:	f406                	sd	ra,40(sp)
    800049e2:	f022                	sd	s0,32(sp)
    800049e4:	ec26                	sd	s1,24(sp)
    800049e6:	e84a                	sd	s2,16(sp)
    800049e8:	e44e                	sd	s3,8(sp)
    800049ea:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049ec:	00854783          	lbu	a5,8(a0)
    800049f0:	c3d5                	beqz	a5,80004a94 <fileread+0xb6>
    800049f2:	84aa                	mv	s1,a0
    800049f4:	89ae                	mv	s3,a1
    800049f6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f8:	411c                	lw	a5,0(a0)
    800049fa:	4705                	li	a4,1
    800049fc:	04e78963          	beq	a5,a4,80004a4e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a00:	470d                	li	a4,3
    80004a02:	04e78d63          	beq	a5,a4,80004a5c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a06:	4709                	li	a4,2
    80004a08:	06e79e63          	bne	a5,a4,80004a84 <fileread+0xa6>
    ilock(f->ip);
    80004a0c:	6d08                	ld	a0,24(a0)
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	ff8080e7          	jalr	-8(ra) # 80003a06 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a16:	874a                	mv	a4,s2
    80004a18:	5094                	lw	a3,32(s1)
    80004a1a:	864e                	mv	a2,s3
    80004a1c:	4585                	li	a1,1
    80004a1e:	6c88                	ld	a0,24(s1)
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	29a080e7          	jalr	666(ra) # 80003cba <readi>
    80004a28:	892a                	mv	s2,a0
    80004a2a:	00a05563          	blez	a0,80004a34 <fileread+0x56>
      f->off += r;
    80004a2e:	509c                	lw	a5,32(s1)
    80004a30:	9fa9                	addw	a5,a5,a0
    80004a32:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a34:	6c88                	ld	a0,24(s1)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	092080e7          	jalr	146(ra) # 80003ac8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a3e:	854a                	mv	a0,s2
    80004a40:	70a2                	ld	ra,40(sp)
    80004a42:	7402                	ld	s0,32(sp)
    80004a44:	64e2                	ld	s1,24(sp)
    80004a46:	6942                	ld	s2,16(sp)
    80004a48:	69a2                	ld	s3,8(sp)
    80004a4a:	6145                	addi	sp,sp,48
    80004a4c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a4e:	6908                	ld	a0,16(a0)
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	3c0080e7          	jalr	960(ra) # 80004e10 <piperead>
    80004a58:	892a                	mv	s2,a0
    80004a5a:	b7d5                	j	80004a3e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a5c:	02451783          	lh	a5,36(a0)
    80004a60:	03079693          	slli	a3,a5,0x30
    80004a64:	92c1                	srli	a3,a3,0x30
    80004a66:	4725                	li	a4,9
    80004a68:	02d76863          	bltu	a4,a3,80004a98 <fileread+0xba>
    80004a6c:	0792                	slli	a5,a5,0x4
    80004a6e:	0001d717          	auipc	a4,0x1d
    80004a72:	0da70713          	addi	a4,a4,218 # 80021b48 <devsw>
    80004a76:	97ba                	add	a5,a5,a4
    80004a78:	639c                	ld	a5,0(a5)
    80004a7a:	c38d                	beqz	a5,80004a9c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a7c:	4505                	li	a0,1
    80004a7e:	9782                	jalr	a5
    80004a80:	892a                	mv	s2,a0
    80004a82:	bf75                	j	80004a3e <fileread+0x60>
    panic("fileread");
    80004a84:	00004517          	auipc	a0,0x4
    80004a88:	cec50513          	addi	a0,a0,-788 # 80008770 <syscalls+0x260>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	a9e080e7          	jalr	-1378(ra) # 8000052a <panic>
    return -1;
    80004a94:	597d                	li	s2,-1
    80004a96:	b765                	j	80004a3e <fileread+0x60>
      return -1;
    80004a98:	597d                	li	s2,-1
    80004a9a:	b755                	j	80004a3e <fileread+0x60>
    80004a9c:	597d                	li	s2,-1
    80004a9e:	b745                	j	80004a3e <fileread+0x60>

0000000080004aa0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004aa0:	715d                	addi	sp,sp,-80
    80004aa2:	e486                	sd	ra,72(sp)
    80004aa4:	e0a2                	sd	s0,64(sp)
    80004aa6:	fc26                	sd	s1,56(sp)
    80004aa8:	f84a                	sd	s2,48(sp)
    80004aaa:	f44e                	sd	s3,40(sp)
    80004aac:	f052                	sd	s4,32(sp)
    80004aae:	ec56                	sd	s5,24(sp)
    80004ab0:	e85a                	sd	s6,16(sp)
    80004ab2:	e45e                	sd	s7,8(sp)
    80004ab4:	e062                	sd	s8,0(sp)
    80004ab6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ab8:	00954783          	lbu	a5,9(a0)
    80004abc:	10078663          	beqz	a5,80004bc8 <filewrite+0x128>
    80004ac0:	892a                	mv	s2,a0
    80004ac2:	8aae                	mv	s5,a1
    80004ac4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ac6:	411c                	lw	a5,0(a0)
    80004ac8:	4705                	li	a4,1
    80004aca:	02e78263          	beq	a5,a4,80004aee <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ace:	470d                	li	a4,3
    80004ad0:	02e78663          	beq	a5,a4,80004afc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ad4:	4709                	li	a4,2
    80004ad6:	0ee79163          	bne	a5,a4,80004bb8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ada:	0ac05d63          	blez	a2,80004b94 <filewrite+0xf4>
    int i = 0;
    80004ade:	4981                	li	s3,0
    80004ae0:	6b05                	lui	s6,0x1
    80004ae2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ae6:	6b85                	lui	s7,0x1
    80004ae8:	c00b8b9b          	addiw	s7,s7,-1024
    80004aec:	a861                	j	80004b84 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004aee:	6908                	ld	a0,16(a0)
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	22e080e7          	jalr	558(ra) # 80004d1e <pipewrite>
    80004af8:	8a2a                	mv	s4,a0
    80004afa:	a045                	j	80004b9a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004afc:	02451783          	lh	a5,36(a0)
    80004b00:	03079693          	slli	a3,a5,0x30
    80004b04:	92c1                	srli	a3,a3,0x30
    80004b06:	4725                	li	a4,9
    80004b08:	0cd76263          	bltu	a4,a3,80004bcc <filewrite+0x12c>
    80004b0c:	0792                	slli	a5,a5,0x4
    80004b0e:	0001d717          	auipc	a4,0x1d
    80004b12:	03a70713          	addi	a4,a4,58 # 80021b48 <devsw>
    80004b16:	97ba                	add	a5,a5,a4
    80004b18:	679c                	ld	a5,8(a5)
    80004b1a:	cbdd                	beqz	a5,80004bd0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b1c:	4505                	li	a0,1
    80004b1e:	9782                	jalr	a5
    80004b20:	8a2a                	mv	s4,a0
    80004b22:	a8a5                	j	80004b9a <filewrite+0xfa>
    80004b24:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b28:	00000097          	auipc	ra,0x0
    80004b2c:	8b0080e7          	jalr	-1872(ra) # 800043d8 <begin_op>
      ilock(f->ip);
    80004b30:	01893503          	ld	a0,24(s2)
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	ed2080e7          	jalr	-302(ra) # 80003a06 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b3c:	8762                	mv	a4,s8
    80004b3e:	02092683          	lw	a3,32(s2)
    80004b42:	01598633          	add	a2,s3,s5
    80004b46:	4585                	li	a1,1
    80004b48:	01893503          	ld	a0,24(s2)
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	266080e7          	jalr	614(ra) # 80003db2 <writei>
    80004b54:	84aa                	mv	s1,a0
    80004b56:	00a05763          	blez	a0,80004b64 <filewrite+0xc4>
        f->off += r;
    80004b5a:	02092783          	lw	a5,32(s2)
    80004b5e:	9fa9                	addw	a5,a5,a0
    80004b60:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b64:	01893503          	ld	a0,24(s2)
    80004b68:	fffff097          	auipc	ra,0xfffff
    80004b6c:	f60080e7          	jalr	-160(ra) # 80003ac8 <iunlock>
      end_op();
    80004b70:	00000097          	auipc	ra,0x0
    80004b74:	8e8080e7          	jalr	-1816(ra) # 80004458 <end_op>

      if(r != n1){
    80004b78:	009c1f63          	bne	s8,s1,80004b96 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b7c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b80:	0149db63          	bge	s3,s4,80004b96 <filewrite+0xf6>
      int n1 = n - i;
    80004b84:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b88:	84be                	mv	s1,a5
    80004b8a:	2781                	sext.w	a5,a5
    80004b8c:	f8fb5ce3          	bge	s6,a5,80004b24 <filewrite+0x84>
    80004b90:	84de                	mv	s1,s7
    80004b92:	bf49                	j	80004b24 <filewrite+0x84>
    int i = 0;
    80004b94:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b96:	013a1f63          	bne	s4,s3,80004bb4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b9a:	8552                	mv	a0,s4
    80004b9c:	60a6                	ld	ra,72(sp)
    80004b9e:	6406                	ld	s0,64(sp)
    80004ba0:	74e2                	ld	s1,56(sp)
    80004ba2:	7942                	ld	s2,48(sp)
    80004ba4:	79a2                	ld	s3,40(sp)
    80004ba6:	7a02                	ld	s4,32(sp)
    80004ba8:	6ae2                	ld	s5,24(sp)
    80004baa:	6b42                	ld	s6,16(sp)
    80004bac:	6ba2                	ld	s7,8(sp)
    80004bae:	6c02                	ld	s8,0(sp)
    80004bb0:	6161                	addi	sp,sp,80
    80004bb2:	8082                	ret
    ret = (i == n ? n : -1);
    80004bb4:	5a7d                	li	s4,-1
    80004bb6:	b7d5                	j	80004b9a <filewrite+0xfa>
    panic("filewrite");
    80004bb8:	00004517          	auipc	a0,0x4
    80004bbc:	bc850513          	addi	a0,a0,-1080 # 80008780 <syscalls+0x270>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	96a080e7          	jalr	-1686(ra) # 8000052a <panic>
    return -1;
    80004bc8:	5a7d                	li	s4,-1
    80004bca:	bfc1                	j	80004b9a <filewrite+0xfa>
      return -1;
    80004bcc:	5a7d                	li	s4,-1
    80004bce:	b7f1                	j	80004b9a <filewrite+0xfa>
    80004bd0:	5a7d                	li	s4,-1
    80004bd2:	b7e1                	j	80004b9a <filewrite+0xfa>

0000000080004bd4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bd4:	7179                	addi	sp,sp,-48
    80004bd6:	f406                	sd	ra,40(sp)
    80004bd8:	f022                	sd	s0,32(sp)
    80004bda:	ec26                	sd	s1,24(sp)
    80004bdc:	e84a                	sd	s2,16(sp)
    80004bde:	e44e                	sd	s3,8(sp)
    80004be0:	e052                	sd	s4,0(sp)
    80004be2:	1800                	addi	s0,sp,48
    80004be4:	84aa                	mv	s1,a0
    80004be6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004be8:	0005b023          	sd	zero,0(a1)
    80004bec:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bf0:	00000097          	auipc	ra,0x0
    80004bf4:	bf8080e7          	jalr	-1032(ra) # 800047e8 <filealloc>
    80004bf8:	e088                	sd	a0,0(s1)
    80004bfa:	c551                	beqz	a0,80004c86 <pipealloc+0xb2>
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	bec080e7          	jalr	-1044(ra) # 800047e8 <filealloc>
    80004c04:	00aa3023          	sd	a0,0(s4)
    80004c08:	c92d                	beqz	a0,80004c7a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	ec8080e7          	jalr	-312(ra) # 80000ad2 <kalloc>
    80004c12:	892a                	mv	s2,a0
    80004c14:	c125                	beqz	a0,80004c74 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c16:	4985                	li	s3,1
    80004c18:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c1c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c20:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c24:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c28:	00004597          	auipc	a1,0x4
    80004c2c:	b6858593          	addi	a1,a1,-1176 # 80008790 <syscalls+0x280>
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	f02080e7          	jalr	-254(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004c38:	609c                	ld	a5,0(s1)
    80004c3a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c3e:	609c                	ld	a5,0(s1)
    80004c40:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c44:	609c                	ld	a5,0(s1)
    80004c46:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c4a:	609c                	ld	a5,0(s1)
    80004c4c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c50:	000a3783          	ld	a5,0(s4)
    80004c54:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c58:	000a3783          	ld	a5,0(s4)
    80004c5c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c60:	000a3783          	ld	a5,0(s4)
    80004c64:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c68:	000a3783          	ld	a5,0(s4)
    80004c6c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c70:	4501                	li	a0,0
    80004c72:	a025                	j	80004c9a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c74:	6088                	ld	a0,0(s1)
    80004c76:	e501                	bnez	a0,80004c7e <pipealloc+0xaa>
    80004c78:	a039                	j	80004c86 <pipealloc+0xb2>
    80004c7a:	6088                	ld	a0,0(s1)
    80004c7c:	c51d                	beqz	a0,80004caa <pipealloc+0xd6>
    fileclose(*f0);
    80004c7e:	00000097          	auipc	ra,0x0
    80004c82:	c26080e7          	jalr	-986(ra) # 800048a4 <fileclose>
  if(*f1)
    80004c86:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c8a:	557d                	li	a0,-1
  if(*f1)
    80004c8c:	c799                	beqz	a5,80004c9a <pipealloc+0xc6>
    fileclose(*f1);
    80004c8e:	853e                	mv	a0,a5
    80004c90:	00000097          	auipc	ra,0x0
    80004c94:	c14080e7          	jalr	-1004(ra) # 800048a4 <fileclose>
  return -1;
    80004c98:	557d                	li	a0,-1
}
    80004c9a:	70a2                	ld	ra,40(sp)
    80004c9c:	7402                	ld	s0,32(sp)
    80004c9e:	64e2                	ld	s1,24(sp)
    80004ca0:	6942                	ld	s2,16(sp)
    80004ca2:	69a2                	ld	s3,8(sp)
    80004ca4:	6a02                	ld	s4,0(sp)
    80004ca6:	6145                	addi	sp,sp,48
    80004ca8:	8082                	ret
  return -1;
    80004caa:	557d                	li	a0,-1
    80004cac:	b7fd                	j	80004c9a <pipealloc+0xc6>

0000000080004cae <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cae:	1101                	addi	sp,sp,-32
    80004cb0:	ec06                	sd	ra,24(sp)
    80004cb2:	e822                	sd	s0,16(sp)
    80004cb4:	e426                	sd	s1,8(sp)
    80004cb6:	e04a                	sd	s2,0(sp)
    80004cb8:	1000                	addi	s0,sp,32
    80004cba:	84aa                	mv	s1,a0
    80004cbc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	f04080e7          	jalr	-252(ra) # 80000bc2 <acquire>
  if(writable){
    80004cc6:	02090d63          	beqz	s2,80004d00 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cca:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cce:	21848513          	addi	a0,s1,536
    80004cd2:	ffffe097          	auipc	ra,0xffffe
    80004cd6:	888080e7          	jalr	-1912(ra) # 8000255a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cda:	2204b783          	ld	a5,544(s1)
    80004cde:	eb95                	bnez	a5,80004d12 <pipeclose+0x64>
    release(&pi->lock);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	f94080e7          	jalr	-108(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	cea080e7          	jalr	-790(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004cf4:	60e2                	ld	ra,24(sp)
    80004cf6:	6442                	ld	s0,16(sp)
    80004cf8:	64a2                	ld	s1,8(sp)
    80004cfa:	6902                	ld	s2,0(sp)
    80004cfc:	6105                	addi	sp,sp,32
    80004cfe:	8082                	ret
    pi->readopen = 0;
    80004d00:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d04:	21c48513          	addi	a0,s1,540
    80004d08:	ffffe097          	auipc	ra,0xffffe
    80004d0c:	852080e7          	jalr	-1966(ra) # 8000255a <wakeup>
    80004d10:	b7e9                	j	80004cda <pipeclose+0x2c>
    release(&pi->lock);
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	f62080e7          	jalr	-158(ra) # 80000c76 <release>
}
    80004d1c:	bfe1                	j	80004cf4 <pipeclose+0x46>

0000000080004d1e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d1e:	711d                	addi	sp,sp,-96
    80004d20:	ec86                	sd	ra,88(sp)
    80004d22:	e8a2                	sd	s0,80(sp)
    80004d24:	e4a6                	sd	s1,72(sp)
    80004d26:	e0ca                	sd	s2,64(sp)
    80004d28:	fc4e                	sd	s3,56(sp)
    80004d2a:	f852                	sd	s4,48(sp)
    80004d2c:	f456                	sd	s5,40(sp)
    80004d2e:	f05a                	sd	s6,32(sp)
    80004d30:	ec5e                	sd	s7,24(sp)
    80004d32:	e862                	sd	s8,16(sp)
    80004d34:	1080                	addi	s0,sp,96
    80004d36:	84aa                	mv	s1,a0
    80004d38:	8aae                	mv	s5,a1
    80004d3a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	e3c080e7          	jalr	-452(ra) # 80001b78 <myproc>
    80004d44:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d46:	8526                	mv	a0,s1
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	e7a080e7          	jalr	-390(ra) # 80000bc2 <acquire>
  while(i < n){
    80004d50:	0b405363          	blez	s4,80004df6 <pipewrite+0xd8>
  int i = 0;
    80004d54:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d56:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d58:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d5c:	21c48b93          	addi	s7,s1,540
    80004d60:	a089                	j	80004da2 <pipewrite+0x84>
      release(&pi->lock);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	f12080e7          	jalr	-238(ra) # 80000c76 <release>
      return -1;
    80004d6c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d6e:	854a                	mv	a0,s2
    80004d70:	60e6                	ld	ra,88(sp)
    80004d72:	6446                	ld	s0,80(sp)
    80004d74:	64a6                	ld	s1,72(sp)
    80004d76:	6906                	ld	s2,64(sp)
    80004d78:	79e2                	ld	s3,56(sp)
    80004d7a:	7a42                	ld	s4,48(sp)
    80004d7c:	7aa2                	ld	s5,40(sp)
    80004d7e:	7b02                	ld	s6,32(sp)
    80004d80:	6be2                	ld	s7,24(sp)
    80004d82:	6c42                	ld	s8,16(sp)
    80004d84:	6125                	addi	sp,sp,96
    80004d86:	8082                	ret
      wakeup(&pi->nread);
    80004d88:	8562                	mv	a0,s8
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	7d0080e7          	jalr	2000(ra) # 8000255a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d92:	85a6                	mv	a1,s1
    80004d94:	855e                	mv	a0,s7
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	638080e7          	jalr	1592(ra) # 800023ce <sleep>
  while(i < n){
    80004d9e:	05495d63          	bge	s2,s4,80004df8 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004da2:	2204a783          	lw	a5,544(s1)
    80004da6:	dfd5                	beqz	a5,80004d62 <pipewrite+0x44>
    80004da8:	0289a783          	lw	a5,40(s3)
    80004dac:	fbdd                	bnez	a5,80004d62 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dae:	2184a783          	lw	a5,536(s1)
    80004db2:	21c4a703          	lw	a4,540(s1)
    80004db6:	2007879b          	addiw	a5,a5,512
    80004dba:	fcf707e3          	beq	a4,a5,80004d88 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dbe:	4685                	li	a3,1
    80004dc0:	01590633          	add	a2,s2,s5
    80004dc4:	faf40593          	addi	a1,s0,-81
    80004dc8:	0509b503          	ld	a0,80(s3)
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	8fe080e7          	jalr	-1794(ra) # 800016ca <copyin>
    80004dd4:	03650263          	beq	a0,s6,80004df8 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dd8:	21c4a783          	lw	a5,540(s1)
    80004ddc:	0017871b          	addiw	a4,a5,1
    80004de0:	20e4ae23          	sw	a4,540(s1)
    80004de4:	1ff7f793          	andi	a5,a5,511
    80004de8:	97a6                	add	a5,a5,s1
    80004dea:	faf44703          	lbu	a4,-81(s0)
    80004dee:	00e78c23          	sb	a4,24(a5)
      i++;
    80004df2:	2905                	addiw	s2,s2,1
    80004df4:	b76d                	j	80004d9e <pipewrite+0x80>
  int i = 0;
    80004df6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004df8:	21848513          	addi	a0,s1,536
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	75e080e7          	jalr	1886(ra) # 8000255a <wakeup>
  release(&pi->lock);
    80004e04:	8526                	mv	a0,s1
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	e70080e7          	jalr	-400(ra) # 80000c76 <release>
  return i;
    80004e0e:	b785                	j	80004d6e <pipewrite+0x50>

0000000080004e10 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e10:	715d                	addi	sp,sp,-80
    80004e12:	e486                	sd	ra,72(sp)
    80004e14:	e0a2                	sd	s0,64(sp)
    80004e16:	fc26                	sd	s1,56(sp)
    80004e18:	f84a                	sd	s2,48(sp)
    80004e1a:	f44e                	sd	s3,40(sp)
    80004e1c:	f052                	sd	s4,32(sp)
    80004e1e:	ec56                	sd	s5,24(sp)
    80004e20:	e85a                	sd	s6,16(sp)
    80004e22:	0880                	addi	s0,sp,80
    80004e24:	84aa                	mv	s1,a0
    80004e26:	892e                	mv	s2,a1
    80004e28:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	d4e080e7          	jalr	-690(ra) # 80001b78 <myproc>
    80004e32:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e34:	8526                	mv	a0,s1
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	d8c080e7          	jalr	-628(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e3e:	2184a703          	lw	a4,536(s1)
    80004e42:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e46:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e4a:	02f71463          	bne	a4,a5,80004e72 <piperead+0x62>
    80004e4e:	2244a783          	lw	a5,548(s1)
    80004e52:	c385                	beqz	a5,80004e72 <piperead+0x62>
    if(pr->killed){
    80004e54:	028a2783          	lw	a5,40(s4)
    80004e58:	ebc1                	bnez	a5,80004ee8 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e5a:	85a6                	mv	a1,s1
    80004e5c:	854e                	mv	a0,s3
    80004e5e:	ffffd097          	auipc	ra,0xffffd
    80004e62:	570080e7          	jalr	1392(ra) # 800023ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e66:	2184a703          	lw	a4,536(s1)
    80004e6a:	21c4a783          	lw	a5,540(s1)
    80004e6e:	fef700e3          	beq	a4,a5,80004e4e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e72:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e74:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e76:	05505363          	blez	s5,80004ebc <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e7a:	2184a783          	lw	a5,536(s1)
    80004e7e:	21c4a703          	lw	a4,540(s1)
    80004e82:	02f70d63          	beq	a4,a5,80004ebc <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e86:	0017871b          	addiw	a4,a5,1
    80004e8a:	20e4ac23          	sw	a4,536(s1)
    80004e8e:	1ff7f793          	andi	a5,a5,511
    80004e92:	97a6                	add	a5,a5,s1
    80004e94:	0187c783          	lbu	a5,24(a5)
    80004e98:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e9c:	4685                	li	a3,1
    80004e9e:	fbf40613          	addi	a2,s0,-65
    80004ea2:	85ca                	mv	a1,s2
    80004ea4:	050a3503          	ld	a0,80(s4)
    80004ea8:	ffffc097          	auipc	ra,0xffffc
    80004eac:	796080e7          	jalr	1942(ra) # 8000163e <copyout>
    80004eb0:	01650663          	beq	a0,s6,80004ebc <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb4:	2985                	addiw	s3,s3,1
    80004eb6:	0905                	addi	s2,s2,1
    80004eb8:	fd3a91e3          	bne	s5,s3,80004e7a <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ebc:	21c48513          	addi	a0,s1,540
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	69a080e7          	jalr	1690(ra) # 8000255a <wakeup>
  release(&pi->lock);
    80004ec8:	8526                	mv	a0,s1
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	dac080e7          	jalr	-596(ra) # 80000c76 <release>
  return i;
}
    80004ed2:	854e                	mv	a0,s3
    80004ed4:	60a6                	ld	ra,72(sp)
    80004ed6:	6406                	ld	s0,64(sp)
    80004ed8:	74e2                	ld	s1,56(sp)
    80004eda:	7942                	ld	s2,48(sp)
    80004edc:	79a2                	ld	s3,40(sp)
    80004ede:	7a02                	ld	s4,32(sp)
    80004ee0:	6ae2                	ld	s5,24(sp)
    80004ee2:	6b42                	ld	s6,16(sp)
    80004ee4:	6161                	addi	sp,sp,80
    80004ee6:	8082                	ret
      release(&pi->lock);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	d8c080e7          	jalr	-628(ra) # 80000c76 <release>
      return -1;
    80004ef2:	59fd                	li	s3,-1
    80004ef4:	bff9                	j	80004ed2 <piperead+0xc2>

0000000080004ef6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ef6:	de010113          	addi	sp,sp,-544
    80004efa:	20113c23          	sd	ra,536(sp)
    80004efe:	20813823          	sd	s0,528(sp)
    80004f02:	20913423          	sd	s1,520(sp)
    80004f06:	21213023          	sd	s2,512(sp)
    80004f0a:	ffce                	sd	s3,504(sp)
    80004f0c:	fbd2                	sd	s4,496(sp)
    80004f0e:	f7d6                	sd	s5,488(sp)
    80004f10:	f3da                	sd	s6,480(sp)
    80004f12:	efde                	sd	s7,472(sp)
    80004f14:	ebe2                	sd	s8,464(sp)
    80004f16:	e7e6                	sd	s9,456(sp)
    80004f18:	e3ea                	sd	s10,448(sp)
    80004f1a:	ff6e                	sd	s11,440(sp)
    80004f1c:	1400                	addi	s0,sp,544
    80004f1e:	892a                	mv	s2,a0
    80004f20:	dea43423          	sd	a0,-536(s0)
    80004f24:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f28:	ffffd097          	auipc	ra,0xffffd
    80004f2c:	c50080e7          	jalr	-944(ra) # 80001b78 <myproc>
    80004f30:	84aa                	mv	s1,a0

  begin_op();
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	4a6080e7          	jalr	1190(ra) # 800043d8 <begin_op>

  if((ip = namei(path)) == 0){
    80004f3a:	854a                	mv	a0,s2
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	280080e7          	jalr	640(ra) # 800041bc <namei>
    80004f44:	c93d                	beqz	a0,80004fba <exec+0xc4>
    80004f46:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	abe080e7          	jalr	-1346(ra) # 80003a06 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f50:	04000713          	li	a4,64
    80004f54:	4681                	li	a3,0
    80004f56:	e4840613          	addi	a2,s0,-440
    80004f5a:	4581                	li	a1,0
    80004f5c:	8556                	mv	a0,s5
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	d5c080e7          	jalr	-676(ra) # 80003cba <readi>
    80004f66:	04000793          	li	a5,64
    80004f6a:	00f51a63          	bne	a0,a5,80004f7e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f6e:	e4842703          	lw	a4,-440(s0)
    80004f72:	464c47b7          	lui	a5,0x464c4
    80004f76:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f7a:	04f70663          	beq	a4,a5,80004fc6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f7e:	8556                	mv	a0,s5
    80004f80:	fffff097          	auipc	ra,0xfffff
    80004f84:	ce8080e7          	jalr	-792(ra) # 80003c68 <iunlockput>
    end_op();
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	4d0080e7          	jalr	1232(ra) # 80004458 <end_op>
  }
  return -1;
    80004f90:	557d                	li	a0,-1
}
    80004f92:	21813083          	ld	ra,536(sp)
    80004f96:	21013403          	ld	s0,528(sp)
    80004f9a:	20813483          	ld	s1,520(sp)
    80004f9e:	20013903          	ld	s2,512(sp)
    80004fa2:	79fe                	ld	s3,504(sp)
    80004fa4:	7a5e                	ld	s4,496(sp)
    80004fa6:	7abe                	ld	s5,488(sp)
    80004fa8:	7b1e                	ld	s6,480(sp)
    80004faa:	6bfe                	ld	s7,472(sp)
    80004fac:	6c5e                	ld	s8,464(sp)
    80004fae:	6cbe                	ld	s9,456(sp)
    80004fb0:	6d1e                	ld	s10,448(sp)
    80004fb2:	7dfa                	ld	s11,440(sp)
    80004fb4:	22010113          	addi	sp,sp,544
    80004fb8:	8082                	ret
    end_op();
    80004fba:	fffff097          	auipc	ra,0xfffff
    80004fbe:	49e080e7          	jalr	1182(ra) # 80004458 <end_op>
    return -1;
    80004fc2:	557d                	li	a0,-1
    80004fc4:	b7f9                	j	80004f92 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fc6:	8526                	mv	a0,s1
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	c76080e7          	jalr	-906(ra) # 80001c3e <proc_pagetable>
    80004fd0:	8b2a                	mv	s6,a0
    80004fd2:	d555                	beqz	a0,80004f7e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd4:	e6842783          	lw	a5,-408(s0)
    80004fd8:	e8045703          	lhu	a4,-384(s0)
    80004fdc:	c735                	beqz	a4,80005048 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fde:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fe4:	6a05                	lui	s4,0x1
    80004fe6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004fea:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004fee:	6d85                	lui	s11,0x1
    80004ff0:	7d7d                	lui	s10,0xfffff
    80004ff2:	ac1d                	j	80005228 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ff4:	00003517          	auipc	a0,0x3
    80004ff8:	7a450513          	addi	a0,a0,1956 # 80008798 <syscalls+0x288>
    80004ffc:	ffffb097          	auipc	ra,0xffffb
    80005000:	52e080e7          	jalr	1326(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005004:	874a                	mv	a4,s2
    80005006:	009c86bb          	addw	a3,s9,s1
    8000500a:	4581                	li	a1,0
    8000500c:	8556                	mv	a0,s5
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	cac080e7          	jalr	-852(ra) # 80003cba <readi>
    80005016:	2501                	sext.w	a0,a0
    80005018:	1aa91863          	bne	s2,a0,800051c8 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000501c:	009d84bb          	addw	s1,s11,s1
    80005020:	013d09bb          	addw	s3,s10,s3
    80005024:	1f74f263          	bgeu	s1,s7,80005208 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005028:	02049593          	slli	a1,s1,0x20
    8000502c:	9181                	srli	a1,a1,0x20
    8000502e:	95e2                	add	a1,a1,s8
    80005030:	855a                	mv	a0,s6
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	01a080e7          	jalr	26(ra) # 8000104c <walkaddr>
    8000503a:	862a                	mv	a2,a0
    if(pa == 0)
    8000503c:	dd45                	beqz	a0,80004ff4 <exec+0xfe>
      n = PGSIZE;
    8000503e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005040:	fd49f2e3          	bgeu	s3,s4,80005004 <exec+0x10e>
      n = sz - i;
    80005044:	894e                	mv	s2,s3
    80005046:	bf7d                	j	80005004 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005048:	4481                	li	s1,0
  iunlockput(ip);
    8000504a:	8556                	mv	a0,s5
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	c1c080e7          	jalr	-996(ra) # 80003c68 <iunlockput>
  end_op();
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	404080e7          	jalr	1028(ra) # 80004458 <end_op>
  p = myproc();
    8000505c:	ffffd097          	auipc	ra,0xffffd
    80005060:	b1c080e7          	jalr	-1252(ra) # 80001b78 <myproc>
    80005064:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005066:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000506a:	6785                	lui	a5,0x1
    8000506c:	17fd                	addi	a5,a5,-1
    8000506e:	94be                	add	s1,s1,a5
    80005070:	77fd                	lui	a5,0xfffff
    80005072:	8fe5                	and	a5,a5,s1
    80005074:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005078:	6609                	lui	a2,0x2
    8000507a:	963e                	add	a2,a2,a5
    8000507c:	85be                	mv	a1,a5
    8000507e:	855a                	mv	a0,s6
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	36e080e7          	jalr	878(ra) # 800013ee <uvmalloc>
    80005088:	8c2a                	mv	s8,a0
  ip = 0;
    8000508a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000508c:	12050e63          	beqz	a0,800051c8 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005090:	75f9                	lui	a1,0xffffe
    80005092:	95aa                	add	a1,a1,a0
    80005094:	855a                	mv	a0,s6
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	576080e7          	jalr	1398(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    8000509e:	7afd                	lui	s5,0xfffff
    800050a0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050a2:	df043783          	ld	a5,-528(s0)
    800050a6:	6388                	ld	a0,0(a5)
    800050a8:	c925                	beqz	a0,80005118 <exec+0x222>
    800050aa:	e8840993          	addi	s3,s0,-376
    800050ae:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800050b2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050b4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	d8c080e7          	jalr	-628(ra) # 80000e42 <strlen>
    800050be:	0015079b          	addiw	a5,a0,1
    800050c2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050c6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050ca:	13596363          	bltu	s2,s5,800051f0 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050ce:	df043d83          	ld	s11,-528(s0)
    800050d2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050d6:	8552                	mv	a0,s4
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	d6a080e7          	jalr	-662(ra) # 80000e42 <strlen>
    800050e0:	0015069b          	addiw	a3,a0,1
    800050e4:	8652                	mv	a2,s4
    800050e6:	85ca                	mv	a1,s2
    800050e8:	855a                	mv	a0,s6
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	554080e7          	jalr	1364(ra) # 8000163e <copyout>
    800050f2:	10054363          	bltz	a0,800051f8 <exec+0x302>
    ustack[argc] = sp;
    800050f6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050fa:	0485                	addi	s1,s1,1
    800050fc:	008d8793          	addi	a5,s11,8
    80005100:	def43823          	sd	a5,-528(s0)
    80005104:	008db503          	ld	a0,8(s11)
    80005108:	c911                	beqz	a0,8000511c <exec+0x226>
    if(argc >= MAXARG)
    8000510a:	09a1                	addi	s3,s3,8
    8000510c:	fb3c95e3          	bne	s9,s3,800050b6 <exec+0x1c0>
  sz = sz1;
    80005110:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005114:	4a81                	li	s5,0
    80005116:	a84d                	j	800051c8 <exec+0x2d2>
  sp = sz;
    80005118:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000511a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000511c:	00349793          	slli	a5,s1,0x3
    80005120:	f9040713          	addi	a4,s0,-112
    80005124:	97ba                	add	a5,a5,a4
    80005126:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000512a:	00148693          	addi	a3,s1,1
    8000512e:	068e                	slli	a3,a3,0x3
    80005130:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005134:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005138:	01597663          	bgeu	s2,s5,80005144 <exec+0x24e>
  sz = sz1;
    8000513c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005140:	4a81                	li	s5,0
    80005142:	a059                	j	800051c8 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005144:	e8840613          	addi	a2,s0,-376
    80005148:	85ca                	mv	a1,s2
    8000514a:	855a                	mv	a0,s6
    8000514c:	ffffc097          	auipc	ra,0xffffc
    80005150:	4f2080e7          	jalr	1266(ra) # 8000163e <copyout>
    80005154:	0a054663          	bltz	a0,80005200 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005158:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000515c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005160:	de843783          	ld	a5,-536(s0)
    80005164:	0007c703          	lbu	a4,0(a5)
    80005168:	cf11                	beqz	a4,80005184 <exec+0x28e>
    8000516a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000516c:	02f00693          	li	a3,47
    80005170:	a039                	j	8000517e <exec+0x288>
      last = s+1;
    80005172:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005176:	0785                	addi	a5,a5,1
    80005178:	fff7c703          	lbu	a4,-1(a5)
    8000517c:	c701                	beqz	a4,80005184 <exec+0x28e>
    if(*s == '/')
    8000517e:	fed71ce3          	bne	a4,a3,80005176 <exec+0x280>
    80005182:	bfc5                	j	80005172 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005184:	4641                	li	a2,16
    80005186:	de843583          	ld	a1,-536(s0)
    8000518a:	158b8513          	addi	a0,s7,344
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	c82080e7          	jalr	-894(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005196:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000519a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000519e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051a2:	058bb783          	ld	a5,88(s7)
    800051a6:	e6043703          	ld	a4,-416(s0)
    800051aa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051ac:	058bb783          	ld	a5,88(s7)
    800051b0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051b4:	85ea                	mv	a1,s10
    800051b6:	ffffd097          	auipc	ra,0xffffd
    800051ba:	b24080e7          	jalr	-1244(ra) # 80001cda <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051be:	0004851b          	sext.w	a0,s1
    800051c2:	bbc1                	j	80004f92 <exec+0x9c>
    800051c4:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051c8:	df843583          	ld	a1,-520(s0)
    800051cc:	855a                	mv	a0,s6
    800051ce:	ffffd097          	auipc	ra,0xffffd
    800051d2:	b0c080e7          	jalr	-1268(ra) # 80001cda <proc_freepagetable>
  if(ip){
    800051d6:	da0a94e3          	bnez	s5,80004f7e <exec+0x88>
  return -1;
    800051da:	557d                	li	a0,-1
    800051dc:	bb5d                	j	80004f92 <exec+0x9c>
    800051de:	de943c23          	sd	s1,-520(s0)
    800051e2:	b7dd                	j	800051c8 <exec+0x2d2>
    800051e4:	de943c23          	sd	s1,-520(s0)
    800051e8:	b7c5                	j	800051c8 <exec+0x2d2>
    800051ea:	de943c23          	sd	s1,-520(s0)
    800051ee:	bfe9                	j	800051c8 <exec+0x2d2>
  sz = sz1;
    800051f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051f4:	4a81                	li	s5,0
    800051f6:	bfc9                	j	800051c8 <exec+0x2d2>
  sz = sz1;
    800051f8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051fc:	4a81                	li	s5,0
    800051fe:	b7e9                	j	800051c8 <exec+0x2d2>
  sz = sz1;
    80005200:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005204:	4a81                	li	s5,0
    80005206:	b7c9                	j	800051c8 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005208:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000520c:	e0843783          	ld	a5,-504(s0)
    80005210:	0017869b          	addiw	a3,a5,1
    80005214:	e0d43423          	sd	a3,-504(s0)
    80005218:	e0043783          	ld	a5,-512(s0)
    8000521c:	0387879b          	addiw	a5,a5,56
    80005220:	e8045703          	lhu	a4,-384(s0)
    80005224:	e2e6d3e3          	bge	a3,a4,8000504a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005228:	2781                	sext.w	a5,a5
    8000522a:	e0f43023          	sd	a5,-512(s0)
    8000522e:	03800713          	li	a4,56
    80005232:	86be                	mv	a3,a5
    80005234:	e1040613          	addi	a2,s0,-496
    80005238:	4581                	li	a1,0
    8000523a:	8556                	mv	a0,s5
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	a7e080e7          	jalr	-1410(ra) # 80003cba <readi>
    80005244:	03800793          	li	a5,56
    80005248:	f6f51ee3          	bne	a0,a5,800051c4 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000524c:	e1042783          	lw	a5,-496(s0)
    80005250:	4705                	li	a4,1
    80005252:	fae79de3          	bne	a5,a4,8000520c <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005256:	e3843603          	ld	a2,-456(s0)
    8000525a:	e3043783          	ld	a5,-464(s0)
    8000525e:	f8f660e3          	bltu	a2,a5,800051de <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005262:	e2043783          	ld	a5,-480(s0)
    80005266:	963e                	add	a2,a2,a5
    80005268:	f6f66ee3          	bltu	a2,a5,800051e4 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000526c:	85a6                	mv	a1,s1
    8000526e:	855a                	mv	a0,s6
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	17e080e7          	jalr	382(ra) # 800013ee <uvmalloc>
    80005278:	dea43c23          	sd	a0,-520(s0)
    8000527c:	d53d                	beqz	a0,800051ea <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000527e:	e2043c03          	ld	s8,-480(s0)
    80005282:	de043783          	ld	a5,-544(s0)
    80005286:	00fc77b3          	and	a5,s8,a5
    8000528a:	ff9d                	bnez	a5,800051c8 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000528c:	e1842c83          	lw	s9,-488(s0)
    80005290:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005294:	f60b8ae3          	beqz	s7,80005208 <exec+0x312>
    80005298:	89de                	mv	s3,s7
    8000529a:	4481                	li	s1,0
    8000529c:	b371                	j	80005028 <exec+0x132>

000000008000529e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000529e:	7179                	addi	sp,sp,-48
    800052a0:	f406                	sd	ra,40(sp)
    800052a2:	f022                	sd	s0,32(sp)
    800052a4:	ec26                	sd	s1,24(sp)
    800052a6:	e84a                	sd	s2,16(sp)
    800052a8:	1800                	addi	s0,sp,48
    800052aa:	892e                	mv	s2,a1
    800052ac:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052ae:	fdc40593          	addi	a1,s0,-36
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	b68080e7          	jalr	-1176(ra) # 80002e1a <argint>
    800052ba:	04054063          	bltz	a0,800052fa <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052be:	fdc42703          	lw	a4,-36(s0)
    800052c2:	47bd                	li	a5,15
    800052c4:	02e7ed63          	bltu	a5,a4,800052fe <argfd+0x60>
    800052c8:	ffffd097          	auipc	ra,0xffffd
    800052cc:	8b0080e7          	jalr	-1872(ra) # 80001b78 <myproc>
    800052d0:	fdc42703          	lw	a4,-36(s0)
    800052d4:	01a70793          	addi	a5,a4,26
    800052d8:	078e                	slli	a5,a5,0x3
    800052da:	953e                	add	a0,a0,a5
    800052dc:	611c                	ld	a5,0(a0)
    800052de:	c395                	beqz	a5,80005302 <argfd+0x64>
    return -1;
  if(pfd)
    800052e0:	00090463          	beqz	s2,800052e8 <argfd+0x4a>
    *pfd = fd;
    800052e4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052e8:	4501                	li	a0,0
  if(pf)
    800052ea:	c091                	beqz	s1,800052ee <argfd+0x50>
    *pf = f;
    800052ec:	e09c                	sd	a5,0(s1)
}
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	64e2                	ld	s1,24(sp)
    800052f4:	6942                	ld	s2,16(sp)
    800052f6:	6145                	addi	sp,sp,48
    800052f8:	8082                	ret
    return -1;
    800052fa:	557d                	li	a0,-1
    800052fc:	bfcd                	j	800052ee <argfd+0x50>
    return -1;
    800052fe:	557d                	li	a0,-1
    80005300:	b7fd                	j	800052ee <argfd+0x50>
    80005302:	557d                	li	a0,-1
    80005304:	b7ed                	j	800052ee <argfd+0x50>

0000000080005306 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005306:	1101                	addi	sp,sp,-32
    80005308:	ec06                	sd	ra,24(sp)
    8000530a:	e822                	sd	s0,16(sp)
    8000530c:	e426                	sd	s1,8(sp)
    8000530e:	1000                	addi	s0,sp,32
    80005310:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	866080e7          	jalr	-1946(ra) # 80001b78 <myproc>
    8000531a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000531c:	0d050793          	addi	a5,a0,208
    80005320:	4501                	li	a0,0
    80005322:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005324:	6398                	ld	a4,0(a5)
    80005326:	cb19                	beqz	a4,8000533c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005328:	2505                	addiw	a0,a0,1
    8000532a:	07a1                	addi	a5,a5,8
    8000532c:	fed51ce3          	bne	a0,a3,80005324 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005330:	557d                	li	a0,-1
}
    80005332:	60e2                	ld	ra,24(sp)
    80005334:	6442                	ld	s0,16(sp)
    80005336:	64a2                	ld	s1,8(sp)
    80005338:	6105                	addi	sp,sp,32
    8000533a:	8082                	ret
      p->ofile[fd] = f;
    8000533c:	01a50793          	addi	a5,a0,26
    80005340:	078e                	slli	a5,a5,0x3
    80005342:	963e                	add	a2,a2,a5
    80005344:	e204                	sd	s1,0(a2)
      return fd;
    80005346:	b7f5                	j	80005332 <fdalloc+0x2c>

0000000080005348 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005348:	715d                	addi	sp,sp,-80
    8000534a:	e486                	sd	ra,72(sp)
    8000534c:	e0a2                	sd	s0,64(sp)
    8000534e:	fc26                	sd	s1,56(sp)
    80005350:	f84a                	sd	s2,48(sp)
    80005352:	f44e                	sd	s3,40(sp)
    80005354:	f052                	sd	s4,32(sp)
    80005356:	ec56                	sd	s5,24(sp)
    80005358:	0880                	addi	s0,sp,80
    8000535a:	89ae                	mv	s3,a1
    8000535c:	8ab2                	mv	s5,a2
    8000535e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005360:	fb040593          	addi	a1,s0,-80
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	e76080e7          	jalr	-394(ra) # 800041da <nameiparent>
    8000536c:	892a                	mv	s2,a0
    8000536e:	12050e63          	beqz	a0,800054aa <create+0x162>
    return 0;

  ilock(dp);
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	694080e7          	jalr	1684(ra) # 80003a06 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000537a:	4601                	li	a2,0
    8000537c:	fb040593          	addi	a1,s0,-80
    80005380:	854a                	mv	a0,s2
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	b68080e7          	jalr	-1176(ra) # 80003eea <dirlookup>
    8000538a:	84aa                	mv	s1,a0
    8000538c:	c921                	beqz	a0,800053dc <create+0x94>
    iunlockput(dp);
    8000538e:	854a                	mv	a0,s2
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	8d8080e7          	jalr	-1832(ra) # 80003c68 <iunlockput>
    ilock(ip);
    80005398:	8526                	mv	a0,s1
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	66c080e7          	jalr	1644(ra) # 80003a06 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053a2:	2981                	sext.w	s3,s3
    800053a4:	4789                	li	a5,2
    800053a6:	02f99463          	bne	s3,a5,800053ce <create+0x86>
    800053aa:	0444d783          	lhu	a5,68(s1)
    800053ae:	37f9                	addiw	a5,a5,-2
    800053b0:	17c2                	slli	a5,a5,0x30
    800053b2:	93c1                	srli	a5,a5,0x30
    800053b4:	4705                	li	a4,1
    800053b6:	00f76c63          	bltu	a4,a5,800053ce <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053ba:	8526                	mv	a0,s1
    800053bc:	60a6                	ld	ra,72(sp)
    800053be:	6406                	ld	s0,64(sp)
    800053c0:	74e2                	ld	s1,56(sp)
    800053c2:	7942                	ld	s2,48(sp)
    800053c4:	79a2                	ld	s3,40(sp)
    800053c6:	7a02                	ld	s4,32(sp)
    800053c8:	6ae2                	ld	s5,24(sp)
    800053ca:	6161                	addi	sp,sp,80
    800053cc:	8082                	ret
    iunlockput(ip);
    800053ce:	8526                	mv	a0,s1
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	898080e7          	jalr	-1896(ra) # 80003c68 <iunlockput>
    return 0;
    800053d8:	4481                	li	s1,0
    800053da:	b7c5                	j	800053ba <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053dc:	85ce                	mv	a1,s3
    800053de:	00092503          	lw	a0,0(s2)
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	48c080e7          	jalr	1164(ra) # 8000386e <ialloc>
    800053ea:	84aa                	mv	s1,a0
    800053ec:	c521                	beqz	a0,80005434 <create+0xec>
  ilock(ip);
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	618080e7          	jalr	1560(ra) # 80003a06 <ilock>
  ip->major = major;
    800053f6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053fa:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053fe:	4a05                	li	s4,1
    80005400:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	536080e7          	jalr	1334(ra) # 8000393c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000540e:	2981                	sext.w	s3,s3
    80005410:	03498a63          	beq	s3,s4,80005444 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005414:	40d0                	lw	a2,4(s1)
    80005416:	fb040593          	addi	a1,s0,-80
    8000541a:	854a                	mv	a0,s2
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	cde080e7          	jalr	-802(ra) # 800040fa <dirlink>
    80005424:	06054b63          	bltz	a0,8000549a <create+0x152>
  iunlockput(dp);
    80005428:	854a                	mv	a0,s2
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	83e080e7          	jalr	-1986(ra) # 80003c68 <iunlockput>
  return ip;
    80005432:	b761                	j	800053ba <create+0x72>
    panic("create: ialloc");
    80005434:	00003517          	auipc	a0,0x3
    80005438:	38450513          	addi	a0,a0,900 # 800087b8 <syscalls+0x2a8>
    8000543c:	ffffb097          	auipc	ra,0xffffb
    80005440:	0ee080e7          	jalr	238(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005444:	04a95783          	lhu	a5,74(s2)
    80005448:	2785                	addiw	a5,a5,1
    8000544a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000544e:	854a                	mv	a0,s2
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	4ec080e7          	jalr	1260(ra) # 8000393c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005458:	40d0                	lw	a2,4(s1)
    8000545a:	00003597          	auipc	a1,0x3
    8000545e:	36e58593          	addi	a1,a1,878 # 800087c8 <syscalls+0x2b8>
    80005462:	8526                	mv	a0,s1
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	c96080e7          	jalr	-874(ra) # 800040fa <dirlink>
    8000546c:	00054f63          	bltz	a0,8000548a <create+0x142>
    80005470:	00492603          	lw	a2,4(s2)
    80005474:	00003597          	auipc	a1,0x3
    80005478:	35c58593          	addi	a1,a1,860 # 800087d0 <syscalls+0x2c0>
    8000547c:	8526                	mv	a0,s1
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	c7c080e7          	jalr	-900(ra) # 800040fa <dirlink>
    80005486:	f80557e3          	bgez	a0,80005414 <create+0xcc>
      panic("create dots");
    8000548a:	00003517          	auipc	a0,0x3
    8000548e:	34e50513          	addi	a0,a0,846 # 800087d8 <syscalls+0x2c8>
    80005492:	ffffb097          	auipc	ra,0xffffb
    80005496:	098080e7          	jalr	152(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000549a:	00003517          	auipc	a0,0x3
    8000549e:	34e50513          	addi	a0,a0,846 # 800087e8 <syscalls+0x2d8>
    800054a2:	ffffb097          	auipc	ra,0xffffb
    800054a6:	088080e7          	jalr	136(ra) # 8000052a <panic>
    return 0;
    800054aa:	84aa                	mv	s1,a0
    800054ac:	b739                	j	800053ba <create+0x72>

00000000800054ae <sys_dup>:
{
    800054ae:	7179                	addi	sp,sp,-48
    800054b0:	f406                	sd	ra,40(sp)
    800054b2:	f022                	sd	s0,32(sp)
    800054b4:	ec26                	sd	s1,24(sp)
    800054b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054b8:	fd840613          	addi	a2,s0,-40
    800054bc:	4581                	li	a1,0
    800054be:	4501                	li	a0,0
    800054c0:	00000097          	auipc	ra,0x0
    800054c4:	dde080e7          	jalr	-546(ra) # 8000529e <argfd>
    return -1;
    800054c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054ca:	02054363          	bltz	a0,800054f0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054ce:	fd843503          	ld	a0,-40(s0)
    800054d2:	00000097          	auipc	ra,0x0
    800054d6:	e34080e7          	jalr	-460(ra) # 80005306 <fdalloc>
    800054da:	84aa                	mv	s1,a0
    return -1;
    800054dc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054de:	00054963          	bltz	a0,800054f0 <sys_dup+0x42>
  filedup(f);
    800054e2:	fd843503          	ld	a0,-40(s0)
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	36c080e7          	jalr	876(ra) # 80004852 <filedup>
  return fd;
    800054ee:	87a6                	mv	a5,s1
}
    800054f0:	853e                	mv	a0,a5
    800054f2:	70a2                	ld	ra,40(sp)
    800054f4:	7402                	ld	s0,32(sp)
    800054f6:	64e2                	ld	s1,24(sp)
    800054f8:	6145                	addi	sp,sp,48
    800054fa:	8082                	ret

00000000800054fc <sys_read>:
{
    800054fc:	7179                	addi	sp,sp,-48
    800054fe:	f406                	sd	ra,40(sp)
    80005500:	f022                	sd	s0,32(sp)
    80005502:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005504:	fe840613          	addi	a2,s0,-24
    80005508:	4581                	li	a1,0
    8000550a:	4501                	li	a0,0
    8000550c:	00000097          	auipc	ra,0x0
    80005510:	d92080e7          	jalr	-622(ra) # 8000529e <argfd>
    return -1;
    80005514:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005516:	04054163          	bltz	a0,80005558 <sys_read+0x5c>
    8000551a:	fe440593          	addi	a1,s0,-28
    8000551e:	4509                	li	a0,2
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	8fa080e7          	jalr	-1798(ra) # 80002e1a <argint>
    return -1;
    80005528:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000552a:	02054763          	bltz	a0,80005558 <sys_read+0x5c>
    8000552e:	fd840593          	addi	a1,s0,-40
    80005532:	4505                	li	a0,1
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	908080e7          	jalr	-1784(ra) # 80002e3c <argaddr>
    return -1;
    8000553c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553e:	00054d63          	bltz	a0,80005558 <sys_read+0x5c>
  return fileread(f, p, n);
    80005542:	fe442603          	lw	a2,-28(s0)
    80005546:	fd843583          	ld	a1,-40(s0)
    8000554a:	fe843503          	ld	a0,-24(s0)
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	490080e7          	jalr	1168(ra) # 800049de <fileread>
    80005556:	87aa                	mv	a5,a0
}
    80005558:	853e                	mv	a0,a5
    8000555a:	70a2                	ld	ra,40(sp)
    8000555c:	7402                	ld	s0,32(sp)
    8000555e:	6145                	addi	sp,sp,48
    80005560:	8082                	ret

0000000080005562 <sys_write>:
{
    80005562:	7179                	addi	sp,sp,-48
    80005564:	f406                	sd	ra,40(sp)
    80005566:	f022                	sd	s0,32(sp)
    80005568:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000556a:	fe840613          	addi	a2,s0,-24
    8000556e:	4581                	li	a1,0
    80005570:	4501                	li	a0,0
    80005572:	00000097          	auipc	ra,0x0
    80005576:	d2c080e7          	jalr	-724(ra) # 8000529e <argfd>
    return -1;
    8000557a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000557c:	04054163          	bltz	a0,800055be <sys_write+0x5c>
    80005580:	fe440593          	addi	a1,s0,-28
    80005584:	4509                	li	a0,2
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	894080e7          	jalr	-1900(ra) # 80002e1a <argint>
    return -1;
    8000558e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005590:	02054763          	bltz	a0,800055be <sys_write+0x5c>
    80005594:	fd840593          	addi	a1,s0,-40
    80005598:	4505                	li	a0,1
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	8a2080e7          	jalr	-1886(ra) # 80002e3c <argaddr>
    return -1;
    800055a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a4:	00054d63          	bltz	a0,800055be <sys_write+0x5c>
  return filewrite(f, p, n);
    800055a8:	fe442603          	lw	a2,-28(s0)
    800055ac:	fd843583          	ld	a1,-40(s0)
    800055b0:	fe843503          	ld	a0,-24(s0)
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	4ec080e7          	jalr	1260(ra) # 80004aa0 <filewrite>
    800055bc:	87aa                	mv	a5,a0
}
    800055be:	853e                	mv	a0,a5
    800055c0:	70a2                	ld	ra,40(sp)
    800055c2:	7402                	ld	s0,32(sp)
    800055c4:	6145                	addi	sp,sp,48
    800055c6:	8082                	ret

00000000800055c8 <sys_close>:
{
    800055c8:	1101                	addi	sp,sp,-32
    800055ca:	ec06                	sd	ra,24(sp)
    800055cc:	e822                	sd	s0,16(sp)
    800055ce:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055d0:	fe040613          	addi	a2,s0,-32
    800055d4:	fec40593          	addi	a1,s0,-20
    800055d8:	4501                	li	a0,0
    800055da:	00000097          	auipc	ra,0x0
    800055de:	cc4080e7          	jalr	-828(ra) # 8000529e <argfd>
    return -1;
    800055e2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055e4:	02054463          	bltz	a0,8000560c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055e8:	ffffc097          	auipc	ra,0xffffc
    800055ec:	590080e7          	jalr	1424(ra) # 80001b78 <myproc>
    800055f0:	fec42783          	lw	a5,-20(s0)
    800055f4:	07e9                	addi	a5,a5,26
    800055f6:	078e                	slli	a5,a5,0x3
    800055f8:	97aa                	add	a5,a5,a0
    800055fa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055fe:	fe043503          	ld	a0,-32(s0)
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	2a2080e7          	jalr	674(ra) # 800048a4 <fileclose>
  return 0;
    8000560a:	4781                	li	a5,0
}
    8000560c:	853e                	mv	a0,a5
    8000560e:	60e2                	ld	ra,24(sp)
    80005610:	6442                	ld	s0,16(sp)
    80005612:	6105                	addi	sp,sp,32
    80005614:	8082                	ret

0000000080005616 <sys_fstat>:
{
    80005616:	1101                	addi	sp,sp,-32
    80005618:	ec06                	sd	ra,24(sp)
    8000561a:	e822                	sd	s0,16(sp)
    8000561c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000561e:	fe840613          	addi	a2,s0,-24
    80005622:	4581                	li	a1,0
    80005624:	4501                	li	a0,0
    80005626:	00000097          	auipc	ra,0x0
    8000562a:	c78080e7          	jalr	-904(ra) # 8000529e <argfd>
    return -1;
    8000562e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005630:	02054563          	bltz	a0,8000565a <sys_fstat+0x44>
    80005634:	fe040593          	addi	a1,s0,-32
    80005638:	4505                	li	a0,1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	802080e7          	jalr	-2046(ra) # 80002e3c <argaddr>
    return -1;
    80005642:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005644:	00054b63          	bltz	a0,8000565a <sys_fstat+0x44>
  return filestat(f, st);
    80005648:	fe043583          	ld	a1,-32(s0)
    8000564c:	fe843503          	ld	a0,-24(s0)
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	31c080e7          	jalr	796(ra) # 8000496c <filestat>
    80005658:	87aa                	mv	a5,a0
}
    8000565a:	853e                	mv	a0,a5
    8000565c:	60e2                	ld	ra,24(sp)
    8000565e:	6442                	ld	s0,16(sp)
    80005660:	6105                	addi	sp,sp,32
    80005662:	8082                	ret

0000000080005664 <sys_link>:
{
    80005664:	7169                	addi	sp,sp,-304
    80005666:	f606                	sd	ra,296(sp)
    80005668:	f222                	sd	s0,288(sp)
    8000566a:	ee26                	sd	s1,280(sp)
    8000566c:	ea4a                	sd	s2,272(sp)
    8000566e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005670:	08000613          	li	a2,128
    80005674:	ed040593          	addi	a1,s0,-304
    80005678:	4501                	li	a0,0
    8000567a:	ffffd097          	auipc	ra,0xffffd
    8000567e:	7e4080e7          	jalr	2020(ra) # 80002e5e <argstr>
    return -1;
    80005682:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005684:	10054e63          	bltz	a0,800057a0 <sys_link+0x13c>
    80005688:	08000613          	li	a2,128
    8000568c:	f5040593          	addi	a1,s0,-176
    80005690:	4505                	li	a0,1
    80005692:	ffffd097          	auipc	ra,0xffffd
    80005696:	7cc080e7          	jalr	1996(ra) # 80002e5e <argstr>
    return -1;
    8000569a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569c:	10054263          	bltz	a0,800057a0 <sys_link+0x13c>
  begin_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	d38080e7          	jalr	-712(ra) # 800043d8 <begin_op>
  if((ip = namei(old)) == 0){
    800056a8:	ed040513          	addi	a0,s0,-304
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	b10080e7          	jalr	-1264(ra) # 800041bc <namei>
    800056b4:	84aa                	mv	s1,a0
    800056b6:	c551                	beqz	a0,80005742 <sys_link+0xde>
  ilock(ip);
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	34e080e7          	jalr	846(ra) # 80003a06 <ilock>
  if(ip->type == T_DIR){
    800056c0:	04449703          	lh	a4,68(s1)
    800056c4:	4785                	li	a5,1
    800056c6:	08f70463          	beq	a4,a5,8000574e <sys_link+0xea>
  ip->nlink++;
    800056ca:	04a4d783          	lhu	a5,74(s1)
    800056ce:	2785                	addiw	a5,a5,1
    800056d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	266080e7          	jalr	614(ra) # 8000393c <iupdate>
  iunlock(ip);
    800056de:	8526                	mv	a0,s1
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	3e8080e7          	jalr	1000(ra) # 80003ac8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056e8:	fd040593          	addi	a1,s0,-48
    800056ec:	f5040513          	addi	a0,s0,-176
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	aea080e7          	jalr	-1302(ra) # 800041da <nameiparent>
    800056f8:	892a                	mv	s2,a0
    800056fa:	c935                	beqz	a0,8000576e <sys_link+0x10a>
  ilock(dp);
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	30a080e7          	jalr	778(ra) # 80003a06 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005704:	00092703          	lw	a4,0(s2)
    80005708:	409c                	lw	a5,0(s1)
    8000570a:	04f71d63          	bne	a4,a5,80005764 <sys_link+0x100>
    8000570e:	40d0                	lw	a2,4(s1)
    80005710:	fd040593          	addi	a1,s0,-48
    80005714:	854a                	mv	a0,s2
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	9e4080e7          	jalr	-1564(ra) # 800040fa <dirlink>
    8000571e:	04054363          	bltz	a0,80005764 <sys_link+0x100>
  iunlockput(dp);
    80005722:	854a                	mv	a0,s2
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	544080e7          	jalr	1348(ra) # 80003c68 <iunlockput>
  iput(ip);
    8000572c:	8526                	mv	a0,s1
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	492080e7          	jalr	1170(ra) # 80003bc0 <iput>
  end_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	d22080e7          	jalr	-734(ra) # 80004458 <end_op>
  return 0;
    8000573e:	4781                	li	a5,0
    80005740:	a085                	j	800057a0 <sys_link+0x13c>
    end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	d16080e7          	jalr	-746(ra) # 80004458 <end_op>
    return -1;
    8000574a:	57fd                	li	a5,-1
    8000574c:	a891                	j	800057a0 <sys_link+0x13c>
    iunlockput(ip);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	518080e7          	jalr	1304(ra) # 80003c68 <iunlockput>
    end_op();
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	d00080e7          	jalr	-768(ra) # 80004458 <end_op>
    return -1;
    80005760:	57fd                	li	a5,-1
    80005762:	a83d                	j	800057a0 <sys_link+0x13c>
    iunlockput(dp);
    80005764:	854a                	mv	a0,s2
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	502080e7          	jalr	1282(ra) # 80003c68 <iunlockput>
  ilock(ip);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	296080e7          	jalr	662(ra) # 80003a06 <ilock>
  ip->nlink--;
    80005778:	04a4d783          	lhu	a5,74(s1)
    8000577c:	37fd                	addiw	a5,a5,-1
    8000577e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	1b8080e7          	jalr	440(ra) # 8000393c <iupdate>
  iunlockput(ip);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	4da080e7          	jalr	1242(ra) # 80003c68 <iunlockput>
  end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	cc2080e7          	jalr	-830(ra) # 80004458 <end_op>
  return -1;
    8000579e:	57fd                	li	a5,-1
}
    800057a0:	853e                	mv	a0,a5
    800057a2:	70b2                	ld	ra,296(sp)
    800057a4:	7412                	ld	s0,288(sp)
    800057a6:	64f2                	ld	s1,280(sp)
    800057a8:	6952                	ld	s2,272(sp)
    800057aa:	6155                	addi	sp,sp,304
    800057ac:	8082                	ret

00000000800057ae <sys_unlink>:
{
    800057ae:	7151                	addi	sp,sp,-240
    800057b0:	f586                	sd	ra,232(sp)
    800057b2:	f1a2                	sd	s0,224(sp)
    800057b4:	eda6                	sd	s1,216(sp)
    800057b6:	e9ca                	sd	s2,208(sp)
    800057b8:	e5ce                	sd	s3,200(sp)
    800057ba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057bc:	08000613          	li	a2,128
    800057c0:	f3040593          	addi	a1,s0,-208
    800057c4:	4501                	li	a0,0
    800057c6:	ffffd097          	auipc	ra,0xffffd
    800057ca:	698080e7          	jalr	1688(ra) # 80002e5e <argstr>
    800057ce:	18054163          	bltz	a0,80005950 <sys_unlink+0x1a2>
  begin_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	c06080e7          	jalr	-1018(ra) # 800043d8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057da:	fb040593          	addi	a1,s0,-80
    800057de:	f3040513          	addi	a0,s0,-208
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	9f8080e7          	jalr	-1544(ra) # 800041da <nameiparent>
    800057ea:	84aa                	mv	s1,a0
    800057ec:	c979                	beqz	a0,800058c2 <sys_unlink+0x114>
  ilock(dp);
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	218080e7          	jalr	536(ra) # 80003a06 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057f6:	00003597          	auipc	a1,0x3
    800057fa:	fd258593          	addi	a1,a1,-46 # 800087c8 <syscalls+0x2b8>
    800057fe:	fb040513          	addi	a0,s0,-80
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	6ce080e7          	jalr	1742(ra) # 80003ed0 <namecmp>
    8000580a:	14050a63          	beqz	a0,8000595e <sys_unlink+0x1b0>
    8000580e:	00003597          	auipc	a1,0x3
    80005812:	fc258593          	addi	a1,a1,-62 # 800087d0 <syscalls+0x2c0>
    80005816:	fb040513          	addi	a0,s0,-80
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	6b6080e7          	jalr	1718(ra) # 80003ed0 <namecmp>
    80005822:	12050e63          	beqz	a0,8000595e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005826:	f2c40613          	addi	a2,s0,-212
    8000582a:	fb040593          	addi	a1,s0,-80
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	6ba080e7          	jalr	1722(ra) # 80003eea <dirlookup>
    80005838:	892a                	mv	s2,a0
    8000583a:	12050263          	beqz	a0,8000595e <sys_unlink+0x1b0>
  ilock(ip);
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	1c8080e7          	jalr	456(ra) # 80003a06 <ilock>
  if(ip->nlink < 1)
    80005846:	04a91783          	lh	a5,74(s2)
    8000584a:	08f05263          	blez	a5,800058ce <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000584e:	04491703          	lh	a4,68(s2)
    80005852:	4785                	li	a5,1
    80005854:	08f70563          	beq	a4,a5,800058de <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005858:	4641                	li	a2,16
    8000585a:	4581                	li	a1,0
    8000585c:	fc040513          	addi	a0,s0,-64
    80005860:	ffffb097          	auipc	ra,0xffffb
    80005864:	45e080e7          	jalr	1118(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005868:	4741                	li	a4,16
    8000586a:	f2c42683          	lw	a3,-212(s0)
    8000586e:	fc040613          	addi	a2,s0,-64
    80005872:	4581                	li	a1,0
    80005874:	8526                	mv	a0,s1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	53c080e7          	jalr	1340(ra) # 80003db2 <writei>
    8000587e:	47c1                	li	a5,16
    80005880:	0af51563          	bne	a0,a5,8000592a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005884:	04491703          	lh	a4,68(s2)
    80005888:	4785                	li	a5,1
    8000588a:	0af70863          	beq	a4,a5,8000593a <sys_unlink+0x18c>
  iunlockput(dp);
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	3d8080e7          	jalr	984(ra) # 80003c68 <iunlockput>
  ip->nlink--;
    80005898:	04a95783          	lhu	a5,74(s2)
    8000589c:	37fd                	addiw	a5,a5,-1
    8000589e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	098080e7          	jalr	152(ra) # 8000393c <iupdate>
  iunlockput(ip);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	3ba080e7          	jalr	954(ra) # 80003c68 <iunlockput>
  end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	ba2080e7          	jalr	-1118(ra) # 80004458 <end_op>
  return 0;
    800058be:	4501                	li	a0,0
    800058c0:	a84d                	j	80005972 <sys_unlink+0x1c4>
    end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	b96080e7          	jalr	-1130(ra) # 80004458 <end_op>
    return -1;
    800058ca:	557d                	li	a0,-1
    800058cc:	a05d                	j	80005972 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058ce:	00003517          	auipc	a0,0x3
    800058d2:	f2a50513          	addi	a0,a0,-214 # 800087f8 <syscalls+0x2e8>
    800058d6:	ffffb097          	auipc	ra,0xffffb
    800058da:	c54080e7          	jalr	-940(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058de:	04c92703          	lw	a4,76(s2)
    800058e2:	02000793          	li	a5,32
    800058e6:	f6e7f9e3          	bgeu	a5,a4,80005858 <sys_unlink+0xaa>
    800058ea:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058ee:	4741                	li	a4,16
    800058f0:	86ce                	mv	a3,s3
    800058f2:	f1840613          	addi	a2,s0,-232
    800058f6:	4581                	li	a1,0
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	3c0080e7          	jalr	960(ra) # 80003cba <readi>
    80005902:	47c1                	li	a5,16
    80005904:	00f51b63          	bne	a0,a5,8000591a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005908:	f1845783          	lhu	a5,-232(s0)
    8000590c:	e7a1                	bnez	a5,80005954 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000590e:	29c1                	addiw	s3,s3,16
    80005910:	04c92783          	lw	a5,76(s2)
    80005914:	fcf9ede3          	bltu	s3,a5,800058ee <sys_unlink+0x140>
    80005918:	b781                	j	80005858 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000591a:	00003517          	auipc	a0,0x3
    8000591e:	ef650513          	addi	a0,a0,-266 # 80008810 <syscalls+0x300>
    80005922:	ffffb097          	auipc	ra,0xffffb
    80005926:	c08080e7          	jalr	-1016(ra) # 8000052a <panic>
    panic("unlink: writei");
    8000592a:	00003517          	auipc	a0,0x3
    8000592e:	efe50513          	addi	a0,a0,-258 # 80008828 <syscalls+0x318>
    80005932:	ffffb097          	auipc	ra,0xffffb
    80005936:	bf8080e7          	jalr	-1032(ra) # 8000052a <panic>
    dp->nlink--;
    8000593a:	04a4d783          	lhu	a5,74(s1)
    8000593e:	37fd                	addiw	a5,a5,-1
    80005940:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	ff6080e7          	jalr	-10(ra) # 8000393c <iupdate>
    8000594e:	b781                	j	8000588e <sys_unlink+0xe0>
    return -1;
    80005950:	557d                	li	a0,-1
    80005952:	a005                	j	80005972 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005954:	854a                	mv	a0,s2
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	312080e7          	jalr	786(ra) # 80003c68 <iunlockput>
  iunlockput(dp);
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	308080e7          	jalr	776(ra) # 80003c68 <iunlockput>
  end_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	af0080e7          	jalr	-1296(ra) # 80004458 <end_op>
  return -1;
    80005970:	557d                	li	a0,-1
}
    80005972:	70ae                	ld	ra,232(sp)
    80005974:	740e                	ld	s0,224(sp)
    80005976:	64ee                	ld	s1,216(sp)
    80005978:	694e                	ld	s2,208(sp)
    8000597a:	69ae                	ld	s3,200(sp)
    8000597c:	616d                	addi	sp,sp,240
    8000597e:	8082                	ret

0000000080005980 <sys_open>:

uint64
sys_open(void)
{
    80005980:	7131                	addi	sp,sp,-192
    80005982:	fd06                	sd	ra,184(sp)
    80005984:	f922                	sd	s0,176(sp)
    80005986:	f526                	sd	s1,168(sp)
    80005988:	f14a                	sd	s2,160(sp)
    8000598a:	ed4e                	sd	s3,152(sp)
    8000598c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000598e:	08000613          	li	a2,128
    80005992:	f5040593          	addi	a1,s0,-176
    80005996:	4501                	li	a0,0
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	4c6080e7          	jalr	1222(ra) # 80002e5e <argstr>
    return -1;
    800059a0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059a2:	0c054163          	bltz	a0,80005a64 <sys_open+0xe4>
    800059a6:	f4c40593          	addi	a1,s0,-180
    800059aa:	4505                	li	a0,1
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	46e080e7          	jalr	1134(ra) # 80002e1a <argint>
    800059b4:	0a054863          	bltz	a0,80005a64 <sys_open+0xe4>

  begin_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	a20080e7          	jalr	-1504(ra) # 800043d8 <begin_op>

  if(omode & O_CREATE){
    800059c0:	f4c42783          	lw	a5,-180(s0)
    800059c4:	2007f793          	andi	a5,a5,512
    800059c8:	cbdd                	beqz	a5,80005a7e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059ca:	4681                	li	a3,0
    800059cc:	4601                	li	a2,0
    800059ce:	4589                	li	a1,2
    800059d0:	f5040513          	addi	a0,s0,-176
    800059d4:	00000097          	auipc	ra,0x0
    800059d8:	974080e7          	jalr	-1676(ra) # 80005348 <create>
    800059dc:	892a                	mv	s2,a0
    if(ip == 0){
    800059de:	c959                	beqz	a0,80005a74 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059e0:	04491703          	lh	a4,68(s2)
    800059e4:	478d                	li	a5,3
    800059e6:	00f71763          	bne	a4,a5,800059f4 <sys_open+0x74>
    800059ea:	04695703          	lhu	a4,70(s2)
    800059ee:	47a5                	li	a5,9
    800059f0:	0ce7ec63          	bltu	a5,a4,80005ac8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	df4080e7          	jalr	-524(ra) # 800047e8 <filealloc>
    800059fc:	89aa                	mv	s3,a0
    800059fe:	10050263          	beqz	a0,80005b02 <sys_open+0x182>
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	904080e7          	jalr	-1788(ra) # 80005306 <fdalloc>
    80005a0a:	84aa                	mv	s1,a0
    80005a0c:	0e054663          	bltz	a0,80005af8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a10:	04491703          	lh	a4,68(s2)
    80005a14:	478d                	li	a5,3
    80005a16:	0cf70463          	beq	a4,a5,80005ade <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a1a:	4789                	li	a5,2
    80005a1c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a20:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a24:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a28:	f4c42783          	lw	a5,-180(s0)
    80005a2c:	0017c713          	xori	a4,a5,1
    80005a30:	8b05                	andi	a4,a4,1
    80005a32:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a36:	0037f713          	andi	a4,a5,3
    80005a3a:	00e03733          	snez	a4,a4
    80005a3e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a42:	4007f793          	andi	a5,a5,1024
    80005a46:	c791                	beqz	a5,80005a52 <sys_open+0xd2>
    80005a48:	04491703          	lh	a4,68(s2)
    80005a4c:	4789                	li	a5,2
    80005a4e:	08f70f63          	beq	a4,a5,80005aec <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a52:	854a                	mv	a0,s2
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	074080e7          	jalr	116(ra) # 80003ac8 <iunlock>
  end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	9fc080e7          	jalr	-1540(ra) # 80004458 <end_op>

  return fd;
}
    80005a64:	8526                	mv	a0,s1
    80005a66:	70ea                	ld	ra,184(sp)
    80005a68:	744a                	ld	s0,176(sp)
    80005a6a:	74aa                	ld	s1,168(sp)
    80005a6c:	790a                	ld	s2,160(sp)
    80005a6e:	69ea                	ld	s3,152(sp)
    80005a70:	6129                	addi	sp,sp,192
    80005a72:	8082                	ret
      end_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	9e4080e7          	jalr	-1564(ra) # 80004458 <end_op>
      return -1;
    80005a7c:	b7e5                	j	80005a64 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a7e:	f5040513          	addi	a0,s0,-176
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	73a080e7          	jalr	1850(ra) # 800041bc <namei>
    80005a8a:	892a                	mv	s2,a0
    80005a8c:	c905                	beqz	a0,80005abc <sys_open+0x13c>
    ilock(ip);
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	f78080e7          	jalr	-136(ra) # 80003a06 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a96:	04491703          	lh	a4,68(s2)
    80005a9a:	4785                	li	a5,1
    80005a9c:	f4f712e3          	bne	a4,a5,800059e0 <sys_open+0x60>
    80005aa0:	f4c42783          	lw	a5,-180(s0)
    80005aa4:	dba1                	beqz	a5,800059f4 <sys_open+0x74>
      iunlockput(ip);
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	1c0080e7          	jalr	448(ra) # 80003c68 <iunlockput>
      end_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	9a8080e7          	jalr	-1624(ra) # 80004458 <end_op>
      return -1;
    80005ab8:	54fd                	li	s1,-1
    80005aba:	b76d                	j	80005a64 <sys_open+0xe4>
      end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	99c080e7          	jalr	-1636(ra) # 80004458 <end_op>
      return -1;
    80005ac4:	54fd                	li	s1,-1
    80005ac6:	bf79                	j	80005a64 <sys_open+0xe4>
    iunlockput(ip);
    80005ac8:	854a                	mv	a0,s2
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	19e080e7          	jalr	414(ra) # 80003c68 <iunlockput>
    end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	986080e7          	jalr	-1658(ra) # 80004458 <end_op>
    return -1;
    80005ada:	54fd                	li	s1,-1
    80005adc:	b761                	j	80005a64 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ade:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ae2:	04691783          	lh	a5,70(s2)
    80005ae6:	02f99223          	sh	a5,36(s3)
    80005aea:	bf2d                	j	80005a24 <sys_open+0xa4>
    itrunc(ip);
    80005aec:	854a                	mv	a0,s2
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	026080e7          	jalr	38(ra) # 80003b14 <itrunc>
    80005af6:	bfb1                	j	80005a52 <sys_open+0xd2>
      fileclose(f);
    80005af8:	854e                	mv	a0,s3
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	daa080e7          	jalr	-598(ra) # 800048a4 <fileclose>
    iunlockput(ip);
    80005b02:	854a                	mv	a0,s2
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	164080e7          	jalr	356(ra) # 80003c68 <iunlockput>
    end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	94c080e7          	jalr	-1716(ra) # 80004458 <end_op>
    return -1;
    80005b14:	54fd                	li	s1,-1
    80005b16:	b7b9                	j	80005a64 <sys_open+0xe4>

0000000080005b18 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b18:	7175                	addi	sp,sp,-144
    80005b1a:	e506                	sd	ra,136(sp)
    80005b1c:	e122                	sd	s0,128(sp)
    80005b1e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	8b8080e7          	jalr	-1864(ra) # 800043d8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b28:	08000613          	li	a2,128
    80005b2c:	f7040593          	addi	a1,s0,-144
    80005b30:	4501                	li	a0,0
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	32c080e7          	jalr	812(ra) # 80002e5e <argstr>
    80005b3a:	02054963          	bltz	a0,80005b6c <sys_mkdir+0x54>
    80005b3e:	4681                	li	a3,0
    80005b40:	4601                	li	a2,0
    80005b42:	4585                	li	a1,1
    80005b44:	f7040513          	addi	a0,s0,-144
    80005b48:	00000097          	auipc	ra,0x0
    80005b4c:	800080e7          	jalr	-2048(ra) # 80005348 <create>
    80005b50:	cd11                	beqz	a0,80005b6c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	116080e7          	jalr	278(ra) # 80003c68 <iunlockput>
  end_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	8fe080e7          	jalr	-1794(ra) # 80004458 <end_op>
  return 0;
    80005b62:	4501                	li	a0,0
}
    80005b64:	60aa                	ld	ra,136(sp)
    80005b66:	640a                	ld	s0,128(sp)
    80005b68:	6149                	addi	sp,sp,144
    80005b6a:	8082                	ret
    end_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	8ec080e7          	jalr	-1812(ra) # 80004458 <end_op>
    return -1;
    80005b74:	557d                	li	a0,-1
    80005b76:	b7fd                	j	80005b64 <sys_mkdir+0x4c>

0000000080005b78 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b78:	7135                	addi	sp,sp,-160
    80005b7a:	ed06                	sd	ra,152(sp)
    80005b7c:	e922                	sd	s0,144(sp)
    80005b7e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	858080e7          	jalr	-1960(ra) # 800043d8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b88:	08000613          	li	a2,128
    80005b8c:	f7040593          	addi	a1,s0,-144
    80005b90:	4501                	li	a0,0
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	2cc080e7          	jalr	716(ra) # 80002e5e <argstr>
    80005b9a:	04054a63          	bltz	a0,80005bee <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b9e:	f6c40593          	addi	a1,s0,-148
    80005ba2:	4505                	li	a0,1
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	276080e7          	jalr	630(ra) # 80002e1a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bac:	04054163          	bltz	a0,80005bee <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bb0:	f6840593          	addi	a1,s0,-152
    80005bb4:	4509                	li	a0,2
    80005bb6:	ffffd097          	auipc	ra,0xffffd
    80005bba:	264080e7          	jalr	612(ra) # 80002e1a <argint>
     argint(1, &major) < 0 ||
    80005bbe:	02054863          	bltz	a0,80005bee <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bc2:	f6841683          	lh	a3,-152(s0)
    80005bc6:	f6c41603          	lh	a2,-148(s0)
    80005bca:	458d                	li	a1,3
    80005bcc:	f7040513          	addi	a0,s0,-144
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	778080e7          	jalr	1912(ra) # 80005348 <create>
     argint(2, &minor) < 0 ||
    80005bd8:	c919                	beqz	a0,80005bee <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	08e080e7          	jalr	142(ra) # 80003c68 <iunlockput>
  end_op();
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	876080e7          	jalr	-1930(ra) # 80004458 <end_op>
  return 0;
    80005bea:	4501                	li	a0,0
    80005bec:	a031                	j	80005bf8 <sys_mknod+0x80>
    end_op();
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	86a080e7          	jalr	-1942(ra) # 80004458 <end_op>
    return -1;
    80005bf6:	557d                	li	a0,-1
}
    80005bf8:	60ea                	ld	ra,152(sp)
    80005bfa:	644a                	ld	s0,144(sp)
    80005bfc:	610d                	addi	sp,sp,160
    80005bfe:	8082                	ret

0000000080005c00 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c00:	7135                	addi	sp,sp,-160
    80005c02:	ed06                	sd	ra,152(sp)
    80005c04:	e922                	sd	s0,144(sp)
    80005c06:	e526                	sd	s1,136(sp)
    80005c08:	e14a                	sd	s2,128(sp)
    80005c0a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c0c:	ffffc097          	auipc	ra,0xffffc
    80005c10:	f6c080e7          	jalr	-148(ra) # 80001b78 <myproc>
    80005c14:	892a                	mv	s2,a0
  
  begin_op();
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	7c2080e7          	jalr	1986(ra) # 800043d8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c1e:	08000613          	li	a2,128
    80005c22:	f6040593          	addi	a1,s0,-160
    80005c26:	4501                	li	a0,0
    80005c28:	ffffd097          	auipc	ra,0xffffd
    80005c2c:	236080e7          	jalr	566(ra) # 80002e5e <argstr>
    80005c30:	04054b63          	bltz	a0,80005c86 <sys_chdir+0x86>
    80005c34:	f6040513          	addi	a0,s0,-160
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	584080e7          	jalr	1412(ra) # 800041bc <namei>
    80005c40:	84aa                	mv	s1,a0
    80005c42:	c131                	beqz	a0,80005c86 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	dc2080e7          	jalr	-574(ra) # 80003a06 <ilock>
  if(ip->type != T_DIR){
    80005c4c:	04449703          	lh	a4,68(s1)
    80005c50:	4785                	li	a5,1
    80005c52:	04f71063          	bne	a4,a5,80005c92 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	e70080e7          	jalr	-400(ra) # 80003ac8 <iunlock>
  iput(p->cwd);
    80005c60:	15093503          	ld	a0,336(s2)
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	f5c080e7          	jalr	-164(ra) # 80003bc0 <iput>
  end_op();
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	7ec080e7          	jalr	2028(ra) # 80004458 <end_op>
  p->cwd = ip;
    80005c74:	14993823          	sd	s1,336(s2)
  return 0;
    80005c78:	4501                	li	a0,0
}
    80005c7a:	60ea                	ld	ra,152(sp)
    80005c7c:	644a                	ld	s0,144(sp)
    80005c7e:	64aa                	ld	s1,136(sp)
    80005c80:	690a                	ld	s2,128(sp)
    80005c82:	610d                	addi	sp,sp,160
    80005c84:	8082                	ret
    end_op();
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	7d2080e7          	jalr	2002(ra) # 80004458 <end_op>
    return -1;
    80005c8e:	557d                	li	a0,-1
    80005c90:	b7ed                	j	80005c7a <sys_chdir+0x7a>
    iunlockput(ip);
    80005c92:	8526                	mv	a0,s1
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	fd4080e7          	jalr	-44(ra) # 80003c68 <iunlockput>
    end_op();
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	7bc080e7          	jalr	1980(ra) # 80004458 <end_op>
    return -1;
    80005ca4:	557d                	li	a0,-1
    80005ca6:	bfd1                	j	80005c7a <sys_chdir+0x7a>

0000000080005ca8 <sys_exec>:

uint64
sys_exec(void)
{
    80005ca8:	7145                	addi	sp,sp,-464
    80005caa:	e786                	sd	ra,456(sp)
    80005cac:	e3a2                	sd	s0,448(sp)
    80005cae:	ff26                	sd	s1,440(sp)
    80005cb0:	fb4a                	sd	s2,432(sp)
    80005cb2:	f74e                	sd	s3,424(sp)
    80005cb4:	f352                	sd	s4,416(sp)
    80005cb6:	ef56                	sd	s5,408(sp)
    80005cb8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cba:	08000613          	li	a2,128
    80005cbe:	f4040593          	addi	a1,s0,-192
    80005cc2:	4501                	li	a0,0
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	19a080e7          	jalr	410(ra) # 80002e5e <argstr>
    return -1;
    80005ccc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cce:	0c054a63          	bltz	a0,80005da2 <sys_exec+0xfa>
    80005cd2:	e3840593          	addi	a1,s0,-456
    80005cd6:	4505                	li	a0,1
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	164080e7          	jalr	356(ra) # 80002e3c <argaddr>
    80005ce0:	0c054163          	bltz	a0,80005da2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ce4:	10000613          	li	a2,256
    80005ce8:	4581                	li	a1,0
    80005cea:	e4040513          	addi	a0,s0,-448
    80005cee:	ffffb097          	auipc	ra,0xffffb
    80005cf2:	fd0080e7          	jalr	-48(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cf6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cfa:	89a6                	mv	s3,s1
    80005cfc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cfe:	02000a13          	li	s4,32
    80005d02:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d06:	00391793          	slli	a5,s2,0x3
    80005d0a:	e3040593          	addi	a1,s0,-464
    80005d0e:	e3843503          	ld	a0,-456(s0)
    80005d12:	953e                	add	a0,a0,a5
    80005d14:	ffffd097          	auipc	ra,0xffffd
    80005d18:	06c080e7          	jalr	108(ra) # 80002d80 <fetchaddr>
    80005d1c:	02054a63          	bltz	a0,80005d50 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d20:	e3043783          	ld	a5,-464(s0)
    80005d24:	c3b9                	beqz	a5,80005d6a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d26:	ffffb097          	auipc	ra,0xffffb
    80005d2a:	dac080e7          	jalr	-596(ra) # 80000ad2 <kalloc>
    80005d2e:	85aa                	mv	a1,a0
    80005d30:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d34:	cd11                	beqz	a0,80005d50 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d36:	6605                	lui	a2,0x1
    80005d38:	e3043503          	ld	a0,-464(s0)
    80005d3c:	ffffd097          	auipc	ra,0xffffd
    80005d40:	096080e7          	jalr	150(ra) # 80002dd2 <fetchstr>
    80005d44:	00054663          	bltz	a0,80005d50 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d48:	0905                	addi	s2,s2,1
    80005d4a:	09a1                	addi	s3,s3,8
    80005d4c:	fb491be3          	bne	s2,s4,80005d02 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d50:	10048913          	addi	s2,s1,256
    80005d54:	6088                	ld	a0,0(s1)
    80005d56:	c529                	beqz	a0,80005da0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d58:	ffffb097          	auipc	ra,0xffffb
    80005d5c:	c7e080e7          	jalr	-898(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d60:	04a1                	addi	s1,s1,8
    80005d62:	ff2499e3          	bne	s1,s2,80005d54 <sys_exec+0xac>
  return -1;
    80005d66:	597d                	li	s2,-1
    80005d68:	a82d                	j	80005da2 <sys_exec+0xfa>
      argv[i] = 0;
    80005d6a:	0a8e                	slli	s5,s5,0x3
    80005d6c:	fc040793          	addi	a5,s0,-64
    80005d70:	9abe                	add	s5,s5,a5
    80005d72:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005d76:	e4040593          	addi	a1,s0,-448
    80005d7a:	f4040513          	addi	a0,s0,-192
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	178080e7          	jalr	376(ra) # 80004ef6 <exec>
    80005d86:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d88:	10048993          	addi	s3,s1,256
    80005d8c:	6088                	ld	a0,0(s1)
    80005d8e:	c911                	beqz	a0,80005da2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d90:	ffffb097          	auipc	ra,0xffffb
    80005d94:	c46080e7          	jalr	-954(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d98:	04a1                	addi	s1,s1,8
    80005d9a:	ff3499e3          	bne	s1,s3,80005d8c <sys_exec+0xe4>
    80005d9e:	a011                	j	80005da2 <sys_exec+0xfa>
  return -1;
    80005da0:	597d                	li	s2,-1
}
    80005da2:	854a                	mv	a0,s2
    80005da4:	60be                	ld	ra,456(sp)
    80005da6:	641e                	ld	s0,448(sp)
    80005da8:	74fa                	ld	s1,440(sp)
    80005daa:	795a                	ld	s2,432(sp)
    80005dac:	79ba                	ld	s3,424(sp)
    80005dae:	7a1a                	ld	s4,416(sp)
    80005db0:	6afa                	ld	s5,408(sp)
    80005db2:	6179                	addi	sp,sp,464
    80005db4:	8082                	ret

0000000080005db6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005db6:	7139                	addi	sp,sp,-64
    80005db8:	fc06                	sd	ra,56(sp)
    80005dba:	f822                	sd	s0,48(sp)
    80005dbc:	f426                	sd	s1,40(sp)
    80005dbe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	db8080e7          	jalr	-584(ra) # 80001b78 <myproc>
    80005dc8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005dca:	fd840593          	addi	a1,s0,-40
    80005dce:	4501                	li	a0,0
    80005dd0:	ffffd097          	auipc	ra,0xffffd
    80005dd4:	06c080e7          	jalr	108(ra) # 80002e3c <argaddr>
    return -1;
    80005dd8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005dda:	0e054063          	bltz	a0,80005eba <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005dde:	fc840593          	addi	a1,s0,-56
    80005de2:	fd040513          	addi	a0,s0,-48
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	dee080e7          	jalr	-530(ra) # 80004bd4 <pipealloc>
    return -1;
    80005dee:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005df0:	0c054563          	bltz	a0,80005eba <sys_pipe+0x104>
  fd0 = -1;
    80005df4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005df8:	fd043503          	ld	a0,-48(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	50a080e7          	jalr	1290(ra) # 80005306 <fdalloc>
    80005e04:	fca42223          	sw	a0,-60(s0)
    80005e08:	08054c63          	bltz	a0,80005ea0 <sys_pipe+0xea>
    80005e0c:	fc843503          	ld	a0,-56(s0)
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	4f6080e7          	jalr	1270(ra) # 80005306 <fdalloc>
    80005e18:	fca42023          	sw	a0,-64(s0)
    80005e1c:	06054863          	bltz	a0,80005e8c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e20:	4691                	li	a3,4
    80005e22:	fc440613          	addi	a2,s0,-60
    80005e26:	fd843583          	ld	a1,-40(s0)
    80005e2a:	68a8                	ld	a0,80(s1)
    80005e2c:	ffffc097          	auipc	ra,0xffffc
    80005e30:	812080e7          	jalr	-2030(ra) # 8000163e <copyout>
    80005e34:	02054063          	bltz	a0,80005e54 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e38:	4691                	li	a3,4
    80005e3a:	fc040613          	addi	a2,s0,-64
    80005e3e:	fd843583          	ld	a1,-40(s0)
    80005e42:	0591                	addi	a1,a1,4
    80005e44:	68a8                	ld	a0,80(s1)
    80005e46:	ffffb097          	auipc	ra,0xffffb
    80005e4a:	7f8080e7          	jalr	2040(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e4e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e50:	06055563          	bgez	a0,80005eba <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e54:	fc442783          	lw	a5,-60(s0)
    80005e58:	07e9                	addi	a5,a5,26
    80005e5a:	078e                	slli	a5,a5,0x3
    80005e5c:	97a6                	add	a5,a5,s1
    80005e5e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e62:	fc042503          	lw	a0,-64(s0)
    80005e66:	0569                	addi	a0,a0,26
    80005e68:	050e                	slli	a0,a0,0x3
    80005e6a:	9526                	add	a0,a0,s1
    80005e6c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e70:	fd043503          	ld	a0,-48(s0)
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	a30080e7          	jalr	-1488(ra) # 800048a4 <fileclose>
    fileclose(wf);
    80005e7c:	fc843503          	ld	a0,-56(s0)
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	a24080e7          	jalr	-1500(ra) # 800048a4 <fileclose>
    return -1;
    80005e88:	57fd                	li	a5,-1
    80005e8a:	a805                	j	80005eba <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e8c:	fc442783          	lw	a5,-60(s0)
    80005e90:	0007c863          	bltz	a5,80005ea0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e94:	01a78513          	addi	a0,a5,26
    80005e98:	050e                	slli	a0,a0,0x3
    80005e9a:	9526                	add	a0,a0,s1
    80005e9c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ea0:	fd043503          	ld	a0,-48(s0)
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	a00080e7          	jalr	-1536(ra) # 800048a4 <fileclose>
    fileclose(wf);
    80005eac:	fc843503          	ld	a0,-56(s0)
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	9f4080e7          	jalr	-1548(ra) # 800048a4 <fileclose>
    return -1;
    80005eb8:	57fd                	li	a5,-1
}
    80005eba:	853e                	mv	a0,a5
    80005ebc:	70e2                	ld	ra,56(sp)
    80005ebe:	7442                	ld	s0,48(sp)
    80005ec0:	74a2                	ld	s1,40(sp)
    80005ec2:	6121                	addi	sp,sp,64
    80005ec4:	8082                	ret
	...

0000000080005ed0 <kernelvec>:
    80005ed0:	7111                	addi	sp,sp,-256
    80005ed2:	e006                	sd	ra,0(sp)
    80005ed4:	e40a                	sd	sp,8(sp)
    80005ed6:	e80e                	sd	gp,16(sp)
    80005ed8:	ec12                	sd	tp,24(sp)
    80005eda:	f016                	sd	t0,32(sp)
    80005edc:	f41a                	sd	t1,40(sp)
    80005ede:	f81e                	sd	t2,48(sp)
    80005ee0:	fc22                	sd	s0,56(sp)
    80005ee2:	e0a6                	sd	s1,64(sp)
    80005ee4:	e4aa                	sd	a0,72(sp)
    80005ee6:	e8ae                	sd	a1,80(sp)
    80005ee8:	ecb2                	sd	a2,88(sp)
    80005eea:	f0b6                	sd	a3,96(sp)
    80005eec:	f4ba                	sd	a4,104(sp)
    80005eee:	f8be                	sd	a5,112(sp)
    80005ef0:	fcc2                	sd	a6,120(sp)
    80005ef2:	e146                	sd	a7,128(sp)
    80005ef4:	e54a                	sd	s2,136(sp)
    80005ef6:	e94e                	sd	s3,144(sp)
    80005ef8:	ed52                	sd	s4,152(sp)
    80005efa:	f156                	sd	s5,160(sp)
    80005efc:	f55a                	sd	s6,168(sp)
    80005efe:	f95e                	sd	s7,176(sp)
    80005f00:	fd62                	sd	s8,184(sp)
    80005f02:	e1e6                	sd	s9,192(sp)
    80005f04:	e5ea                	sd	s10,200(sp)
    80005f06:	e9ee                	sd	s11,208(sp)
    80005f08:	edf2                	sd	t3,216(sp)
    80005f0a:	f1f6                	sd	t4,224(sp)
    80005f0c:	f5fa                	sd	t5,232(sp)
    80005f0e:	f9fe                	sd	t6,240(sp)
    80005f10:	d3dfc0ef          	jal	ra,80002c4c <kerneltrap>
    80005f14:	6082                	ld	ra,0(sp)
    80005f16:	6122                	ld	sp,8(sp)
    80005f18:	61c2                	ld	gp,16(sp)
    80005f1a:	7282                	ld	t0,32(sp)
    80005f1c:	7322                	ld	t1,40(sp)
    80005f1e:	73c2                	ld	t2,48(sp)
    80005f20:	7462                	ld	s0,56(sp)
    80005f22:	6486                	ld	s1,64(sp)
    80005f24:	6526                	ld	a0,72(sp)
    80005f26:	65c6                	ld	a1,80(sp)
    80005f28:	6666                	ld	a2,88(sp)
    80005f2a:	7686                	ld	a3,96(sp)
    80005f2c:	7726                	ld	a4,104(sp)
    80005f2e:	77c6                	ld	a5,112(sp)
    80005f30:	7866                	ld	a6,120(sp)
    80005f32:	688a                	ld	a7,128(sp)
    80005f34:	692a                	ld	s2,136(sp)
    80005f36:	69ca                	ld	s3,144(sp)
    80005f38:	6a6a                	ld	s4,152(sp)
    80005f3a:	7a8a                	ld	s5,160(sp)
    80005f3c:	7b2a                	ld	s6,168(sp)
    80005f3e:	7bca                	ld	s7,176(sp)
    80005f40:	7c6a                	ld	s8,184(sp)
    80005f42:	6c8e                	ld	s9,192(sp)
    80005f44:	6d2e                	ld	s10,200(sp)
    80005f46:	6dce                	ld	s11,208(sp)
    80005f48:	6e6e                	ld	t3,216(sp)
    80005f4a:	7e8e                	ld	t4,224(sp)
    80005f4c:	7f2e                	ld	t5,232(sp)
    80005f4e:	7fce                	ld	t6,240(sp)
    80005f50:	6111                	addi	sp,sp,256
    80005f52:	10200073          	sret
    80005f56:	00000013          	nop
    80005f5a:	00000013          	nop
    80005f5e:	0001                	nop

0000000080005f60 <timervec>:
    80005f60:	34051573          	csrrw	a0,mscratch,a0
    80005f64:	e10c                	sd	a1,0(a0)
    80005f66:	e510                	sd	a2,8(a0)
    80005f68:	e914                	sd	a3,16(a0)
    80005f6a:	6d0c                	ld	a1,24(a0)
    80005f6c:	7110                	ld	a2,32(a0)
    80005f6e:	6194                	ld	a3,0(a1)
    80005f70:	96b2                	add	a3,a3,a2
    80005f72:	e194                	sd	a3,0(a1)
    80005f74:	4589                	li	a1,2
    80005f76:	14459073          	csrw	sip,a1
    80005f7a:	6914                	ld	a3,16(a0)
    80005f7c:	6510                	ld	a2,8(a0)
    80005f7e:	610c                	ld	a1,0(a0)
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	30200073          	mret
	...

0000000080005f8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f8a:	1141                	addi	sp,sp,-16
    80005f8c:	e422                	sd	s0,8(sp)
    80005f8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f90:	0c0007b7          	lui	a5,0xc000
    80005f94:	4705                	li	a4,1
    80005f96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f98:	c3d8                	sw	a4,4(a5)
}
    80005f9a:	6422                	ld	s0,8(sp)
    80005f9c:	0141                	addi	sp,sp,16
    80005f9e:	8082                	ret

0000000080005fa0 <plicinithart>:

void
plicinithart(void)
{
    80005fa0:	1141                	addi	sp,sp,-16
    80005fa2:	e406                	sd	ra,8(sp)
    80005fa4:	e022                	sd	s0,0(sp)
    80005fa6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	ba4080e7          	jalr	-1116(ra) # 80001b4c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fb0:	0085171b          	slliw	a4,a0,0x8
    80005fb4:	0c0027b7          	lui	a5,0xc002
    80005fb8:	97ba                	add	a5,a5,a4
    80005fba:	40200713          	li	a4,1026
    80005fbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fc2:	00d5151b          	slliw	a0,a0,0xd
    80005fc6:	0c2017b7          	lui	a5,0xc201
    80005fca:	953e                	add	a0,a0,a5
    80005fcc:	00052023          	sw	zero,0(a0)
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret

0000000080005fd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fd8:	1141                	addi	sp,sp,-16
    80005fda:	e406                	sd	ra,8(sp)
    80005fdc:	e022                	sd	s0,0(sp)
    80005fde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe0:	ffffc097          	auipc	ra,0xffffc
    80005fe4:	b6c080e7          	jalr	-1172(ra) # 80001b4c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fe8:	00d5179b          	slliw	a5,a0,0xd
    80005fec:	0c201537          	lui	a0,0xc201
    80005ff0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ff2:	4148                	lw	a0,4(a0)
    80005ff4:	60a2                	ld	ra,8(sp)
    80005ff6:	6402                	ld	s0,0(sp)
    80005ff8:	0141                	addi	sp,sp,16
    80005ffa:	8082                	ret

0000000080005ffc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ffc:	1101                	addi	sp,sp,-32
    80005ffe:	ec06                	sd	ra,24(sp)
    80006000:	e822                	sd	s0,16(sp)
    80006002:	e426                	sd	s1,8(sp)
    80006004:	1000                	addi	s0,sp,32
    80006006:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	b44080e7          	jalr	-1212(ra) # 80001b4c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006010:	00d5151b          	slliw	a0,a0,0xd
    80006014:	0c2017b7          	lui	a5,0xc201
    80006018:	97aa                	add	a5,a5,a0
    8000601a:	c3c4                	sw	s1,4(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret

0000000080006026 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006026:	1141                	addi	sp,sp,-16
    80006028:	e406                	sd	ra,8(sp)
    8000602a:	e022                	sd	s0,0(sp)
    8000602c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000602e:	479d                	li	a5,7
    80006030:	06a7c963          	blt	a5,a0,800060a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006034:	0001d797          	auipc	a5,0x1d
    80006038:	fcc78793          	addi	a5,a5,-52 # 80023000 <disk>
    8000603c:	00a78733          	add	a4,a5,a0
    80006040:	6789                	lui	a5,0x2
    80006042:	97ba                	add	a5,a5,a4
    80006044:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006048:	e7ad                	bnez	a5,800060b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000604a:	00451793          	slli	a5,a0,0x4
    8000604e:	0001f717          	auipc	a4,0x1f
    80006052:	fb270713          	addi	a4,a4,-78 # 80025000 <disk+0x2000>
    80006056:	6314                	ld	a3,0(a4)
    80006058:	96be                	add	a3,a3,a5
    8000605a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000605e:	6314                	ld	a3,0(a4)
    80006060:	96be                	add	a3,a3,a5
    80006062:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006066:	6314                	ld	a3,0(a4)
    80006068:	96be                	add	a3,a3,a5
    8000606a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000606e:	6318                	ld	a4,0(a4)
    80006070:	97ba                	add	a5,a5,a4
    80006072:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006076:	0001d797          	auipc	a5,0x1d
    8000607a:	f8a78793          	addi	a5,a5,-118 # 80023000 <disk>
    8000607e:	97aa                	add	a5,a5,a0
    80006080:	6509                	lui	a0,0x2
    80006082:	953e                	add	a0,a0,a5
    80006084:	4785                	li	a5,1
    80006086:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000608a:	0001f517          	auipc	a0,0x1f
    8000608e:	f8e50513          	addi	a0,a0,-114 # 80025018 <disk+0x2018>
    80006092:	ffffc097          	auipc	ra,0xffffc
    80006096:	4c8080e7          	jalr	1224(ra) # 8000255a <wakeup>
}
    8000609a:	60a2                	ld	ra,8(sp)
    8000609c:	6402                	ld	s0,0(sp)
    8000609e:	0141                	addi	sp,sp,16
    800060a0:	8082                	ret
    panic("free_desc 1");
    800060a2:	00002517          	auipc	a0,0x2
    800060a6:	79650513          	addi	a0,a0,1942 # 80008838 <syscalls+0x328>
    800060aa:	ffffa097          	auipc	ra,0xffffa
    800060ae:	480080e7          	jalr	1152(ra) # 8000052a <panic>
    panic("free_desc 2");
    800060b2:	00002517          	auipc	a0,0x2
    800060b6:	79650513          	addi	a0,a0,1942 # 80008848 <syscalls+0x338>
    800060ba:	ffffa097          	auipc	ra,0xffffa
    800060be:	470080e7          	jalr	1136(ra) # 8000052a <panic>

00000000800060c2 <virtio_disk_init>:
{
    800060c2:	1101                	addi	sp,sp,-32
    800060c4:	ec06                	sd	ra,24(sp)
    800060c6:	e822                	sd	s0,16(sp)
    800060c8:	e426                	sd	s1,8(sp)
    800060ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060cc:	00002597          	auipc	a1,0x2
    800060d0:	78c58593          	addi	a1,a1,1932 # 80008858 <syscalls+0x348>
    800060d4:	0001f517          	auipc	a0,0x1f
    800060d8:	05450513          	addi	a0,a0,84 # 80025128 <disk+0x2128>
    800060dc:	ffffb097          	auipc	ra,0xffffb
    800060e0:	a56080e7          	jalr	-1450(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060e4:	100017b7          	lui	a5,0x10001
    800060e8:	4398                	lw	a4,0(a5)
    800060ea:	2701                	sext.w	a4,a4
    800060ec:	747277b7          	lui	a5,0x74727
    800060f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060f4:	0ef71163          	bne	a4,a5,800061d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060f8:	100017b7          	lui	a5,0x10001
    800060fc:	43dc                	lw	a5,4(a5)
    800060fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006100:	4705                	li	a4,1
    80006102:	0ce79a63          	bne	a5,a4,800061d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006106:	100017b7          	lui	a5,0x10001
    8000610a:	479c                	lw	a5,8(a5)
    8000610c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000610e:	4709                	li	a4,2
    80006110:	0ce79363          	bne	a5,a4,800061d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006114:	100017b7          	lui	a5,0x10001
    80006118:	47d8                	lw	a4,12(a5)
    8000611a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000611c:	554d47b7          	lui	a5,0x554d4
    80006120:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006124:	0af71963          	bne	a4,a5,800061d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006128:	100017b7          	lui	a5,0x10001
    8000612c:	4705                	li	a4,1
    8000612e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006130:	470d                	li	a4,3
    80006132:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006134:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006136:	c7ffe737          	lui	a4,0xc7ffe
    8000613a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000613e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006140:	2701                	sext.w	a4,a4
    80006142:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006144:	472d                	li	a4,11
    80006146:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006148:	473d                	li	a4,15
    8000614a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000614c:	6705                	lui	a4,0x1
    8000614e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006150:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006154:	5bdc                	lw	a5,52(a5)
    80006156:	2781                	sext.w	a5,a5
  if(max == 0)
    80006158:	c7d9                	beqz	a5,800061e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000615a:	471d                	li	a4,7
    8000615c:	08f77d63          	bgeu	a4,a5,800061f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006160:	100014b7          	lui	s1,0x10001
    80006164:	47a1                	li	a5,8
    80006166:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006168:	6609                	lui	a2,0x2
    8000616a:	4581                	li	a1,0
    8000616c:	0001d517          	auipc	a0,0x1d
    80006170:	e9450513          	addi	a0,a0,-364 # 80023000 <disk>
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	b4a080e7          	jalr	-1206(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000617c:	0001d717          	auipc	a4,0x1d
    80006180:	e8470713          	addi	a4,a4,-380 # 80023000 <disk>
    80006184:	00c75793          	srli	a5,a4,0xc
    80006188:	2781                	sext.w	a5,a5
    8000618a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000618c:	0001f797          	auipc	a5,0x1f
    80006190:	e7478793          	addi	a5,a5,-396 # 80025000 <disk+0x2000>
    80006194:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006196:	0001d717          	auipc	a4,0x1d
    8000619a:	eea70713          	addi	a4,a4,-278 # 80023080 <disk+0x80>
    8000619e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800061a0:	0001e717          	auipc	a4,0x1e
    800061a4:	e6070713          	addi	a4,a4,-416 # 80024000 <disk+0x1000>
    800061a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061aa:	4705                	li	a4,1
    800061ac:	00e78c23          	sb	a4,24(a5)
    800061b0:	00e78ca3          	sb	a4,25(a5)
    800061b4:	00e78d23          	sb	a4,26(a5)
    800061b8:	00e78da3          	sb	a4,27(a5)
    800061bc:	00e78e23          	sb	a4,28(a5)
    800061c0:	00e78ea3          	sb	a4,29(a5)
    800061c4:	00e78f23          	sb	a4,30(a5)
    800061c8:	00e78fa3          	sb	a4,31(a5)
}
    800061cc:	60e2                	ld	ra,24(sp)
    800061ce:	6442                	ld	s0,16(sp)
    800061d0:	64a2                	ld	s1,8(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret
    panic("could not find virtio disk");
    800061d6:	00002517          	auipc	a0,0x2
    800061da:	69250513          	addi	a0,a0,1682 # 80008868 <syscalls+0x358>
    800061de:	ffffa097          	auipc	ra,0xffffa
    800061e2:	34c080e7          	jalr	844(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800061e6:	00002517          	auipc	a0,0x2
    800061ea:	6a250513          	addi	a0,a0,1698 # 80008888 <syscalls+0x378>
    800061ee:	ffffa097          	auipc	ra,0xffffa
    800061f2:	33c080e7          	jalr	828(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800061f6:	00002517          	auipc	a0,0x2
    800061fa:	6b250513          	addi	a0,a0,1714 # 800088a8 <syscalls+0x398>
    800061fe:	ffffa097          	auipc	ra,0xffffa
    80006202:	32c080e7          	jalr	812(ra) # 8000052a <panic>

0000000080006206 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006206:	7119                	addi	sp,sp,-128
    80006208:	fc86                	sd	ra,120(sp)
    8000620a:	f8a2                	sd	s0,112(sp)
    8000620c:	f4a6                	sd	s1,104(sp)
    8000620e:	f0ca                	sd	s2,96(sp)
    80006210:	ecce                	sd	s3,88(sp)
    80006212:	e8d2                	sd	s4,80(sp)
    80006214:	e4d6                	sd	s5,72(sp)
    80006216:	e0da                	sd	s6,64(sp)
    80006218:	fc5e                	sd	s7,56(sp)
    8000621a:	f862                	sd	s8,48(sp)
    8000621c:	f466                	sd	s9,40(sp)
    8000621e:	f06a                	sd	s10,32(sp)
    80006220:	ec6e                	sd	s11,24(sp)
    80006222:	0100                	addi	s0,sp,128
    80006224:	8aaa                	mv	s5,a0
    80006226:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006228:	00c52c83          	lw	s9,12(a0)
    8000622c:	001c9c9b          	slliw	s9,s9,0x1
    80006230:	1c82                	slli	s9,s9,0x20
    80006232:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006236:	0001f517          	auipc	a0,0x1f
    8000623a:	ef250513          	addi	a0,a0,-270 # 80025128 <disk+0x2128>
    8000623e:	ffffb097          	auipc	ra,0xffffb
    80006242:	984080e7          	jalr	-1660(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006246:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006248:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000624a:	0001dc17          	auipc	s8,0x1d
    8000624e:	db6c0c13          	addi	s8,s8,-586 # 80023000 <disk>
    80006252:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006254:	4b0d                	li	s6,3
    80006256:	a0ad                	j	800062c0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006258:	00fc0733          	add	a4,s8,a5
    8000625c:	975e                	add	a4,a4,s7
    8000625e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006262:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006264:	0207c563          	bltz	a5,8000628e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006268:	2905                	addiw	s2,s2,1
    8000626a:	0611                	addi	a2,a2,4
    8000626c:	19690d63          	beq	s2,s6,80006406 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006270:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006272:	0001f717          	auipc	a4,0x1f
    80006276:	da670713          	addi	a4,a4,-602 # 80025018 <disk+0x2018>
    8000627a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000627c:	00074683          	lbu	a3,0(a4)
    80006280:	fee1                	bnez	a3,80006258 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006282:	2785                	addiw	a5,a5,1
    80006284:	0705                	addi	a4,a4,1
    80006286:	fe979be3          	bne	a5,s1,8000627c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000628a:	57fd                	li	a5,-1
    8000628c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000628e:	01205d63          	blez	s2,800062a8 <virtio_disk_rw+0xa2>
    80006292:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006294:	000a2503          	lw	a0,0(s4)
    80006298:	00000097          	auipc	ra,0x0
    8000629c:	d8e080e7          	jalr	-626(ra) # 80006026 <free_desc>
      for(int j = 0; j < i; j++)
    800062a0:	2d85                	addiw	s11,s11,1
    800062a2:	0a11                	addi	s4,s4,4
    800062a4:	ffb918e3          	bne	s2,s11,80006294 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a8:	0001f597          	auipc	a1,0x1f
    800062ac:	e8058593          	addi	a1,a1,-384 # 80025128 <disk+0x2128>
    800062b0:	0001f517          	auipc	a0,0x1f
    800062b4:	d6850513          	addi	a0,a0,-664 # 80025018 <disk+0x2018>
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	116080e7          	jalr	278(ra) # 800023ce <sleep>
  for(int i = 0; i < 3; i++){
    800062c0:	f8040a13          	addi	s4,s0,-128
{
    800062c4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062c6:	894e                	mv	s2,s3
    800062c8:	b765                	j	80006270 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ca:	0001f697          	auipc	a3,0x1f
    800062ce:	d366b683          	ld	a3,-714(a3) # 80025000 <disk+0x2000>
    800062d2:	96ba                	add	a3,a3,a4
    800062d4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062d8:	0001d817          	auipc	a6,0x1d
    800062dc:	d2880813          	addi	a6,a6,-728 # 80023000 <disk>
    800062e0:	0001f697          	auipc	a3,0x1f
    800062e4:	d2068693          	addi	a3,a3,-736 # 80025000 <disk+0x2000>
    800062e8:	6290                	ld	a2,0(a3)
    800062ea:	963a                	add	a2,a2,a4
    800062ec:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800062f0:	0015e593          	ori	a1,a1,1
    800062f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800062f8:	f8842603          	lw	a2,-120(s0)
    800062fc:	628c                	ld	a1,0(a3)
    800062fe:	972e                	add	a4,a4,a1
    80006300:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006304:	20050593          	addi	a1,a0,512
    80006308:	0592                	slli	a1,a1,0x4
    8000630a:	95c2                	add	a1,a1,a6
    8000630c:	577d                	li	a4,-1
    8000630e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006312:	00461713          	slli	a4,a2,0x4
    80006316:	6290                	ld	a2,0(a3)
    80006318:	963a                	add	a2,a2,a4
    8000631a:	03078793          	addi	a5,a5,48
    8000631e:	97c2                	add	a5,a5,a6
    80006320:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006322:	629c                	ld	a5,0(a3)
    80006324:	97ba                	add	a5,a5,a4
    80006326:	4605                	li	a2,1
    80006328:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000632a:	629c                	ld	a5,0(a3)
    8000632c:	97ba                	add	a5,a5,a4
    8000632e:	4809                	li	a6,2
    80006330:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006334:	629c                	ld	a5,0(a3)
    80006336:	973e                	add	a4,a4,a5
    80006338:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000633c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006340:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006344:	6698                	ld	a4,8(a3)
    80006346:	00275783          	lhu	a5,2(a4)
    8000634a:	8b9d                	andi	a5,a5,7
    8000634c:	0786                	slli	a5,a5,0x1
    8000634e:	97ba                	add	a5,a5,a4
    80006350:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006354:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006358:	6698                	ld	a4,8(a3)
    8000635a:	00275783          	lhu	a5,2(a4)
    8000635e:	2785                	addiw	a5,a5,1
    80006360:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006364:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006368:	100017b7          	lui	a5,0x10001
    8000636c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006370:	004aa783          	lw	a5,4(s5)
    80006374:	02c79163          	bne	a5,a2,80006396 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006378:	0001f917          	auipc	s2,0x1f
    8000637c:	db090913          	addi	s2,s2,-592 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006380:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006382:	85ca                	mv	a1,s2
    80006384:	8556                	mv	a0,s5
    80006386:	ffffc097          	auipc	ra,0xffffc
    8000638a:	048080e7          	jalr	72(ra) # 800023ce <sleep>
  while(b->disk == 1) {
    8000638e:	004aa783          	lw	a5,4(s5)
    80006392:	fe9788e3          	beq	a5,s1,80006382 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006396:	f8042903          	lw	s2,-128(s0)
    8000639a:	20090793          	addi	a5,s2,512
    8000639e:	00479713          	slli	a4,a5,0x4
    800063a2:	0001d797          	auipc	a5,0x1d
    800063a6:	c5e78793          	addi	a5,a5,-930 # 80023000 <disk>
    800063aa:	97ba                	add	a5,a5,a4
    800063ac:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063b0:	0001f997          	auipc	s3,0x1f
    800063b4:	c5098993          	addi	s3,s3,-944 # 80025000 <disk+0x2000>
    800063b8:	00491713          	slli	a4,s2,0x4
    800063bc:	0009b783          	ld	a5,0(s3)
    800063c0:	97ba                	add	a5,a5,a4
    800063c2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063c6:	854a                	mv	a0,s2
    800063c8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063cc:	00000097          	auipc	ra,0x0
    800063d0:	c5a080e7          	jalr	-934(ra) # 80006026 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063d4:	8885                	andi	s1,s1,1
    800063d6:	f0ed                	bnez	s1,800063b8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063d8:	0001f517          	auipc	a0,0x1f
    800063dc:	d5050513          	addi	a0,a0,-688 # 80025128 <disk+0x2128>
    800063e0:	ffffb097          	auipc	ra,0xffffb
    800063e4:	896080e7          	jalr	-1898(ra) # 80000c76 <release>
}
    800063e8:	70e6                	ld	ra,120(sp)
    800063ea:	7446                	ld	s0,112(sp)
    800063ec:	74a6                	ld	s1,104(sp)
    800063ee:	7906                	ld	s2,96(sp)
    800063f0:	69e6                	ld	s3,88(sp)
    800063f2:	6a46                	ld	s4,80(sp)
    800063f4:	6aa6                	ld	s5,72(sp)
    800063f6:	6b06                	ld	s6,64(sp)
    800063f8:	7be2                	ld	s7,56(sp)
    800063fa:	7c42                	ld	s8,48(sp)
    800063fc:	7ca2                	ld	s9,40(sp)
    800063fe:	7d02                	ld	s10,32(sp)
    80006400:	6de2                	ld	s11,24(sp)
    80006402:	6109                	addi	sp,sp,128
    80006404:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006406:	f8042503          	lw	a0,-128(s0)
    8000640a:	20050793          	addi	a5,a0,512
    8000640e:	0792                	slli	a5,a5,0x4
  if(write)
    80006410:	0001d817          	auipc	a6,0x1d
    80006414:	bf080813          	addi	a6,a6,-1040 # 80023000 <disk>
    80006418:	00f80733          	add	a4,a6,a5
    8000641c:	01a036b3          	snez	a3,s10
    80006420:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006424:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006428:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000642c:	7679                	lui	a2,0xffffe
    8000642e:	963e                	add	a2,a2,a5
    80006430:	0001f697          	auipc	a3,0x1f
    80006434:	bd068693          	addi	a3,a3,-1072 # 80025000 <disk+0x2000>
    80006438:	6298                	ld	a4,0(a3)
    8000643a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000643c:	0a878593          	addi	a1,a5,168
    80006440:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006442:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006444:	6298                	ld	a4,0(a3)
    80006446:	9732                	add	a4,a4,a2
    80006448:	45c1                	li	a1,16
    8000644a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000644c:	6298                	ld	a4,0(a3)
    8000644e:	9732                	add	a4,a4,a2
    80006450:	4585                	li	a1,1
    80006452:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006456:	f8442703          	lw	a4,-124(s0)
    8000645a:	628c                	ld	a1,0(a3)
    8000645c:	962e                	add	a2,a2,a1
    8000645e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006462:	0712                	slli	a4,a4,0x4
    80006464:	6290                	ld	a2,0(a3)
    80006466:	963a                	add	a2,a2,a4
    80006468:	058a8593          	addi	a1,s5,88
    8000646c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000646e:	6294                	ld	a3,0(a3)
    80006470:	96ba                	add	a3,a3,a4
    80006472:	40000613          	li	a2,1024
    80006476:	c690                	sw	a2,8(a3)
  if(write)
    80006478:	e40d19e3          	bnez	s10,800062ca <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000647c:	0001f697          	auipc	a3,0x1f
    80006480:	b846b683          	ld	a3,-1148(a3) # 80025000 <disk+0x2000>
    80006484:	96ba                	add	a3,a3,a4
    80006486:	4609                	li	a2,2
    80006488:	00c69623          	sh	a2,12(a3)
    8000648c:	b5b1                	j	800062d8 <virtio_disk_rw+0xd2>

000000008000648e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000648e:	1101                	addi	sp,sp,-32
    80006490:	ec06                	sd	ra,24(sp)
    80006492:	e822                	sd	s0,16(sp)
    80006494:	e426                	sd	s1,8(sp)
    80006496:	e04a                	sd	s2,0(sp)
    80006498:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000649a:	0001f517          	auipc	a0,0x1f
    8000649e:	c8e50513          	addi	a0,a0,-882 # 80025128 <disk+0x2128>
    800064a2:	ffffa097          	auipc	ra,0xffffa
    800064a6:	720080e7          	jalr	1824(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064aa:	10001737          	lui	a4,0x10001
    800064ae:	533c                	lw	a5,96(a4)
    800064b0:	8b8d                	andi	a5,a5,3
    800064b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064b8:	0001f797          	auipc	a5,0x1f
    800064bc:	b4878793          	addi	a5,a5,-1208 # 80025000 <disk+0x2000>
    800064c0:	6b94                	ld	a3,16(a5)
    800064c2:	0207d703          	lhu	a4,32(a5)
    800064c6:	0026d783          	lhu	a5,2(a3)
    800064ca:	06f70163          	beq	a4,a5,8000652c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064ce:	0001d917          	auipc	s2,0x1d
    800064d2:	b3290913          	addi	s2,s2,-1230 # 80023000 <disk>
    800064d6:	0001f497          	auipc	s1,0x1f
    800064da:	b2a48493          	addi	s1,s1,-1238 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064de:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064e2:	6898                	ld	a4,16(s1)
    800064e4:	0204d783          	lhu	a5,32(s1)
    800064e8:	8b9d                	andi	a5,a5,7
    800064ea:	078e                	slli	a5,a5,0x3
    800064ec:	97ba                	add	a5,a5,a4
    800064ee:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064f0:	20078713          	addi	a4,a5,512
    800064f4:	0712                	slli	a4,a4,0x4
    800064f6:	974a                	add	a4,a4,s2
    800064f8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064fc:	e731                	bnez	a4,80006548 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064fe:	20078793          	addi	a5,a5,512
    80006502:	0792                	slli	a5,a5,0x4
    80006504:	97ca                	add	a5,a5,s2
    80006506:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006508:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000650c:	ffffc097          	auipc	ra,0xffffc
    80006510:	04e080e7          	jalr	78(ra) # 8000255a <wakeup>

    disk.used_idx += 1;
    80006514:	0204d783          	lhu	a5,32(s1)
    80006518:	2785                	addiw	a5,a5,1
    8000651a:	17c2                	slli	a5,a5,0x30
    8000651c:	93c1                	srli	a5,a5,0x30
    8000651e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006522:	6898                	ld	a4,16(s1)
    80006524:	00275703          	lhu	a4,2(a4)
    80006528:	faf71be3          	bne	a4,a5,800064de <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000652c:	0001f517          	auipc	a0,0x1f
    80006530:	bfc50513          	addi	a0,a0,-1028 # 80025128 <disk+0x2128>
    80006534:	ffffa097          	auipc	ra,0xffffa
    80006538:	742080e7          	jalr	1858(ra) # 80000c76 <release>
}
    8000653c:	60e2                	ld	ra,24(sp)
    8000653e:	6442                	ld	s0,16(sp)
    80006540:	64a2                	ld	s1,8(sp)
    80006542:	6902                	ld	s2,0(sp)
    80006544:	6105                	addi	sp,sp,32
    80006546:	8082                	ret
      panic("virtio_disk_intr status");
    80006548:	00002517          	auipc	a0,0x2
    8000654c:	38050513          	addi	a0,a0,896 # 800088c8 <syscalls+0x3b8>
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	fda080e7          	jalr	-38(ra) # 8000052a <panic>
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
