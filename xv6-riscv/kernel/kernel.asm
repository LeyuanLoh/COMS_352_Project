
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	ddc78793          	addi	a5,a5,-548 # 80005e40 <timervec>
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
    80000122:	5a6080e7          	jalr	1446(ra) # 800026c4 <either_copyin>
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
    800001b6:	8fe080e7          	jalr	-1794(ra) # 80001ab0 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	0f4080e7          	jalr	244(ra) # 800022b6 <sleep>
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
    80000202:	470080e7          	jalr	1136(ra) # 8000266e <either_copyout>
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
    800002e2:	43c080e7          	jalr	1084(ra) # 8000271a <procdump>
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
    80000436:	010080e7          	jalr	16(ra) # 80002442 <wakeup>
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
    80000882:	bc4080e7          	jalr	-1084(ra) # 80002442 <wakeup>
    
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
    8000090e:	9ac080e7          	jalr	-1620(ra) # 800022b6 <sleep>
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
    80000b60:	f38080e7          	jalr	-200(ra) # 80001a94 <mycpu>
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
    80000b92:	f06080e7          	jalr	-250(ra) # 80001a94 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	efa080e7          	jalr	-262(ra) # 80001a94 <mycpu>
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
    80000bb6:	ee2080e7          	jalr	-286(ra) # 80001a94 <mycpu>
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
    80000bf6:	ea2080e7          	jalr	-350(ra) # 80001a94 <mycpu>
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
    80000c22:	e76080e7          	jalr	-394(ra) # 80001a94 <mycpu>
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
    80000e78:	c10080e7          	jalr	-1008(ra) # 80001a84 <cpuid>
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
    80000e94:	bf4080e7          	jalr	-1036(ra) # 80001a84 <cpuid>
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
    80000eb6:	9f0080e7          	jalr	-1552(ra) # 800028a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	fc6080e7          	jalr	-58(ra) # 80005e80 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	11e080e7          	jalr	286(ra) # 80001fe0 <scheduler>
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
    80000f26:	a8e080e7          	jalr	-1394(ra) # 800019b0 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	950080e7          	jalr	-1712(ra) # 8000287a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	970080e7          	jalr	-1680(ra) # 800028a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	f30080e7          	jalr	-208(ra) # 80005e6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	f3e080e7          	jalr	-194(ra) # 80005e80 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	114080e7          	jalr	276(ra) # 8000305e <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	7a4080e7          	jalr	1956(ra) # 800036f6 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	74e080e7          	jalr	1870(ra) # 800046a8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	040080e7          	jalr	64(ra) # 80005fa2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	e2c080e7          	jalr	-468(ra) # 80001d96 <userinit>
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
    80001210:	70e080e7          	jalr	1806(ra) # 8000191a <proc_mapstacks>
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
    8000189c:	1141                	addi	sp,sp,-16
    8000189e:	e422                	sd	s0,8(sp)
    800018a0:	0800                	addi	s0,sp,16

  struct qentry *q;

  for (q = qtable + NPROC; q < &qtable[QTABLE_SIZE]; q++)
    800018a2:	00010797          	auipc	a5,0x10
    800018a6:	dfe78793          	addi	a5,a5,-514 # 800116a0 <qtable+0x400>
  {
    if (q->next != EMPTY)
    800018aa:	56fd                	li	a3,-1
  for (q = qtable + NPROC; q < &qtable[QTABLE_SIZE]; q++)
    800018ac:	00010617          	auipc	a2,0x10
    800018b0:	e2460613          	addi	a2,a2,-476 # 800116d0 <pid_lock>
    if (q->next != EMPTY)
    800018b4:	6798                	ld	a4,8(a5)
    800018b6:	00d71963          	bne	a4,a3,800018c8 <dequeue+0x2c>
  for (q = qtable + NPROC; q < &qtable[QTABLE_SIZE]; q++)
    800018ba:	07c1                	addi	a5,a5,16
    800018bc:	fec79ce3          	bne	a5,a2,800018b4 <dequeue+0x18>
      {
        return p;
      }
    }
  }
  return 0;
    800018c0:	4501                	li	a0,0
}
    800018c2:	6422                	ld	s0,8(sp)
    800018c4:	0141                	addi	sp,sp,16
    800018c6:	8082                	ret
      uint64 qindex = q - qtable;
    800018c8:	00010697          	auipc	a3,0x10
    800018cc:	9d868693          	addi	a3,a3,-1576 # 800112a0 <qtable>
    800018d0:	40d785b3          	sub	a1,a5,a3
    800018d4:	8591                	srai	a1,a1,0x4
      p = proc + q->next;
    800018d6:	17800513          	li	a0,376
    800018da:	02a70533          	mul	a0,a4,a0
    800018de:	00010617          	auipc	a2,0x10
    800018e2:	22260613          	addi	a2,a2,546 # 80011b00 <proc>
    800018e6:	9532                	add	a0,a0,a2
      qfirst = qtable + q->next;
    800018e8:	0712                	slli	a4,a4,0x4
    800018ea:	9736                	add	a4,a4,a3
      qsecond = qtable + qfirst->next;
    800018ec:	6710                	ld	a2,8(a4)
      q->next = qfirst->next;
    800018ee:	e790                	sd	a2,8(a5)
      qsecond->prev = qfirst->prev;
    800018f0:	6318                	ld	a4,0(a4)
    800018f2:	0612                	slli	a2,a2,0x4
    800018f4:	96b2                	add	a3,a3,a2
    800018f6:	e298                	sd	a4,0(a3)
      if (q->next == qindex && q->prev == qindex)
    800018f8:	6798                	ld	a4,8(a5)
    800018fa:	00b70963          	beq	a4,a1,8000190c <dequeue+0x70>
      if (p->pid == 0)
    800018fe:	591c                	lw	a5,48(a0)
        return 0;
    80001900:	00f037b3          	snez	a5,a5
    80001904:	40f007b3          	neg	a5,a5
    80001908:	8d7d                	and	a0,a0,a5
    8000190a:	bf65                	j	800018c2 <dequeue+0x26>
      if (q->next == qindex && q->prev == qindex)
    8000190c:	6398                	ld	a4,0(a5)
    8000190e:	feb718e3          	bne	a4,a1,800018fe <dequeue+0x62>
        q->next = EMPTY;
    80001912:	577d                	li	a4,-1
    80001914:	e798                	sd	a4,8(a5)
        q->prev = EMPTY;
    80001916:	e398                	sd	a4,0(a5)
    80001918:	b7dd                	j	800018fe <dequeue+0x62>

000000008000191a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000191a:	7139                	addi	sp,sp,-64
    8000191c:	fc06                	sd	ra,56(sp)
    8000191e:	f822                	sd	s0,48(sp)
    80001920:	f426                	sd	s1,40(sp)
    80001922:	f04a                	sd	s2,32(sp)
    80001924:	ec4e                	sd	s3,24(sp)
    80001926:	e852                	sd	s4,16(sp)
    80001928:	e456                	sd	s5,8(sp)
    8000192a:	e05a                	sd	s6,0(sp)
    8000192c:	0080                	addi	s0,sp,64
    8000192e:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001930:	00010497          	auipc	s1,0x10
    80001934:	1d048493          	addi	s1,s1,464 # 80011b00 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001938:	8b26                	mv	s6,s1
    8000193a:	00006a97          	auipc	s5,0x6
    8000193e:	6c6a8a93          	addi	s5,s5,1734 # 80008000 <etext>
    80001942:	04000937          	lui	s2,0x4000
    80001946:	197d                	addi	s2,s2,-1
    80001948:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194a:	00016a17          	auipc	s4,0x16
    8000194e:	fb6a0a13          	addi	s4,s4,-74 # 80017900 <tickslock>
    char *pa = kalloc();
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	180080e7          	jalr	384(ra) # 80000ad2 <kalloc>
    8000195a:	862a                	mv	a2,a0
    if (pa == 0)
    8000195c:	c131                	beqz	a0,800019a0 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000195e:	416485b3          	sub	a1,s1,s6
    80001962:	858d                	srai	a1,a1,0x3
    80001964:	000ab783          	ld	a5,0(s5)
    80001968:	02f585b3          	mul	a1,a1,a5
    8000196c:	2585                	addiw	a1,a1,1
    8000196e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001972:	4719                	li	a4,6
    80001974:	6685                	lui	a3,0x1
    80001976:	40b905b3          	sub	a1,s2,a1
    8000197a:	854e                	mv	a0,s3
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	7a0080e7          	jalr	1952(ra) # 8000111c <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001984:	17848493          	addi	s1,s1,376
    80001988:	fd4495e3          	bne	s1,s4,80001952 <proc_mapstacks+0x38>
  }
}
    8000198c:	70e2                	ld	ra,56(sp)
    8000198e:	7442                	ld	s0,48(sp)
    80001990:	74a2                	ld	s1,40(sp)
    80001992:	7902                	ld	s2,32(sp)
    80001994:	69e2                	ld	s3,24(sp)
    80001996:	6a42                	ld	s4,16(sp)
    80001998:	6aa2                	ld	s5,8(sp)
    8000199a:	6b02                	ld	s6,0(sp)
    8000199c:	6121                	addi	sp,sp,64
    8000199e:	8082                	ret
      panic("kalloc");
    800019a0:	00007517          	auipc	a0,0x7
    800019a4:	83850513          	addi	a0,a0,-1992 # 800081d8 <digits+0x198>
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	b82080e7          	jalr	-1150(ra) # 8000052a <panic>

00000000800019b0 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800019b0:	7139                	addi	sp,sp,-64
    800019b2:	fc06                	sd	ra,56(sp)
    800019b4:	f822                	sd	s0,48(sp)
    800019b6:	f426                	sd	s1,40(sp)
    800019b8:	f04a                	sd	s2,32(sp)
    800019ba:	ec4e                	sd	s3,24(sp)
    800019bc:	e852                	sd	s4,16(sp)
    800019be:	e456                	sd	s5,8(sp)
    800019c0:	e05a                	sd	s6,0(sp)
    800019c2:	0080                	addi	s0,sp,64

  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800019c4:	00007597          	auipc	a1,0x7
    800019c8:	81c58593          	addi	a1,a1,-2020 # 800081e0 <digits+0x1a0>
    800019cc:	00010517          	auipc	a0,0x10
    800019d0:	d0450513          	addi	a0,a0,-764 # 800116d0 <pid_lock>
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	15e080e7          	jalr	350(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019dc:	00007597          	auipc	a1,0x7
    800019e0:	80c58593          	addi	a1,a1,-2036 # 800081e8 <digits+0x1a8>
    800019e4:	00010517          	auipc	a0,0x10
    800019e8:	d0450513          	addi	a0,a0,-764 # 800116e8 <wait_lock>
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	146080e7          	jalr	326(ra) # 80000b32 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019f4:	00010497          	auipc	s1,0x10
    800019f8:	10c48493          	addi	s1,s1,268 # 80011b00 <proc>
  {
    initlock(&p->lock, "proc");
    800019fc:	00006b17          	auipc	s6,0x6
    80001a00:	7fcb0b13          	addi	s6,s6,2044 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001a04:	8aa6                	mv	s5,s1
    80001a06:	00006a17          	auipc	s4,0x6
    80001a0a:	5faa0a13          	addi	s4,s4,1530 # 80008000 <etext>
    80001a0e:	04000937          	lui	s2,0x4000
    80001a12:	197d                	addi	s2,s2,-1
    80001a14:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a16:	00016997          	auipc	s3,0x16
    80001a1a:	eea98993          	addi	s3,s3,-278 # 80017900 <tickslock>
    initlock(&p->lock, "proc");
    80001a1e:	85da                	mv	a1,s6
    80001a20:	8526                	mv	a0,s1
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	110080e7          	jalr	272(ra) # 80000b32 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001a2a:	415487b3          	sub	a5,s1,s5
    80001a2e:	878d                	srai	a5,a5,0x3
    80001a30:	000a3703          	ld	a4,0(s4)
    80001a34:	02e787b3          	mul	a5,a5,a4
    80001a38:	2785                	addiw	a5,a5,1
    80001a3a:	00d7979b          	slliw	a5,a5,0xd
    80001a3e:	40f907b3          	sub	a5,s2,a5
    80001a42:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a44:	17848493          	addi	s1,s1,376
    80001a48:	fd349be3          	bne	s1,s3,80001a1e <procinit+0x6e>
  }

  //Leyuan & Lee
  ticks = 0;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	5e07a423          	sw	zero,1512(a5) # 80009034 <ticks>

  struct qentry *q;

  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001a54:	00010797          	auipc	a5,0x10
    80001a58:	84c78793          	addi	a5,a5,-1972 # 800112a0 <qtable>
  {
    q->prev = EMPTY;
    80001a5c:	577d                	li	a4,-1
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001a5e:	00010697          	auipc	a3,0x10
    80001a62:	c7268693          	addi	a3,a3,-910 # 800116d0 <pid_lock>
    q->prev = EMPTY;
    80001a66:	e398                	sd	a4,0(a5)
    q->next = EMPTY;
    80001a68:	e798                	sd	a4,8(a5)
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
    80001a6a:	07c1                	addi	a5,a5,16
    80001a6c:	fed79de3          	bne	a5,a3,80001a66 <procinit+0xb6>
  }
}
    80001a70:	70e2                	ld	ra,56(sp)
    80001a72:	7442                	ld	s0,48(sp)
    80001a74:	74a2                	ld	s1,40(sp)
    80001a76:	7902                	ld	s2,32(sp)
    80001a78:	69e2                	ld	s3,24(sp)
    80001a7a:	6a42                	ld	s4,16(sp)
    80001a7c:	6aa2                	ld	s5,8(sp)
    80001a7e:	6b02                	ld	s6,0(sp)
    80001a80:	6121                	addi	sp,sp,64
    80001a82:	8082                	ret

0000000080001a84 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a84:	1141                	addi	sp,sp,-16
    80001a86:	e422                	sd	s0,8(sp)
    80001a88:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a8a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a8c:	2501                	sext.w	a0,a0
    80001a8e:	6422                	ld	s0,8(sp)
    80001a90:	0141                	addi	sp,sp,16
    80001a92:	8082                	ret

0000000080001a94 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a94:	1141                	addi	sp,sp,-16
    80001a96:	e422                	sd	s0,8(sp)
    80001a98:	0800                	addi	s0,sp,16
    80001a9a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a9c:	2781                	sext.w	a5,a5
    80001a9e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aa0:	00010517          	auipc	a0,0x10
    80001aa4:	c6050513          	addi	a0,a0,-928 # 80011700 <cpus>
    80001aa8:	953e                	add	a0,a0,a5
    80001aaa:	6422                	ld	s0,8(sp)
    80001aac:	0141                	addi	sp,sp,16
    80001aae:	8082                	ret

0000000080001ab0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001ab0:	1101                	addi	sp,sp,-32
    80001ab2:	ec06                	sd	ra,24(sp)
    80001ab4:	e822                	sd	s0,16(sp)
    80001ab6:	e426                	sd	s1,8(sp)
    80001ab8:	1000                	addi	s0,sp,32
  push_off();
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	0bc080e7          	jalr	188(ra) # 80000b76 <push_off>
    80001ac2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ac4:	2781                	sext.w	a5,a5
    80001ac6:	079e                	slli	a5,a5,0x7
    80001ac8:	0000f717          	auipc	a4,0xf
    80001acc:	7d870713          	addi	a4,a4,2008 # 800112a0 <qtable>
    80001ad0:	97ba                	add	a5,a5,a4
    80001ad2:	4607b483          	ld	s1,1120(a5)
  pop_off();
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	140080e7          	jalr	320(ra) # 80000c16 <pop_off>
  return p;
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret

0000000080001aea <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001aea:	1141                	addi	sp,sp,-16
    80001aec:	e406                	sd	ra,8(sp)
    80001aee:	e022                	sd	s0,0(sp)
    80001af0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001af2:	00000097          	auipc	ra,0x0
    80001af6:	fbe080e7          	jalr	-66(ra) # 80001ab0 <myproc>
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	17c080e7          	jalr	380(ra) # 80000c76 <release>

  if (first)
    80001b02:	00007797          	auipc	a5,0x7
    80001b06:	d1e7a783          	lw	a5,-738(a5) # 80008820 <first.1>
    80001b0a:	eb89                	bnez	a5,80001b1c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b0c:	00001097          	auipc	ra,0x1
    80001b10:	dae080e7          	jalr	-594(ra) # 800028ba <usertrapret>
}
    80001b14:	60a2                	ld	ra,8(sp)
    80001b16:	6402                	ld	s0,0(sp)
    80001b18:	0141                	addi	sp,sp,16
    80001b1a:	8082                	ret
    first = 0;
    80001b1c:	00007797          	auipc	a5,0x7
    80001b20:	d007a223          	sw	zero,-764(a5) # 80008820 <first.1>
    fsinit(ROOTDEV);
    80001b24:	4505                	li	a0,1
    80001b26:	00002097          	auipc	ra,0x2
    80001b2a:	b50080e7          	jalr	-1200(ra) # 80003676 <fsinit>
    80001b2e:	bff9                	j	80001b0c <forkret+0x22>

0000000080001b30 <allocpid>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	e04a                	sd	s2,0(sp)
    80001b3a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b3c:	00010917          	auipc	s2,0x10
    80001b40:	b9490913          	addi	s2,s2,-1132 # 800116d0 <pid_lock>
    80001b44:	854a                	mv	a0,s2
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	07c080e7          	jalr	124(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001b4e:	00007797          	auipc	a5,0x7
    80001b52:	cd678793          	addi	a5,a5,-810 # 80008824 <nextpid>
    80001b56:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b58:	0014871b          	addiw	a4,s1,1
    80001b5c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b5e:	854a                	mv	a0,s2
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	116080e7          	jalr	278(ra) # 80000c76 <release>
}
    80001b68:	8526                	mv	a0,s1
    80001b6a:	60e2                	ld	ra,24(sp)
    80001b6c:	6442                	ld	s0,16(sp)
    80001b6e:	64a2                	ld	s1,8(sp)
    80001b70:	6902                	ld	s2,0(sp)
    80001b72:	6105                	addi	sp,sp,32
    80001b74:	8082                	ret

0000000080001b76 <proc_pagetable>:
{
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	782080e7          	jalr	1922(ra) # 80001306 <uvmcreate>
    80001b8c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b8e:	c121                	beqz	a0,80001bce <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b90:	4729                	li	a4,10
    80001b92:	00005697          	auipc	a3,0x5
    80001b96:	46e68693          	addi	a3,a3,1134 # 80007000 <_trampoline>
    80001b9a:	6605                	lui	a2,0x1
    80001b9c:	040005b7          	lui	a1,0x4000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b2                	slli	a1,a1,0xc
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	4ea080e7          	jalr	1258(ra) # 8000108e <mappages>
    80001bac:	02054863          	bltz	a0,80001bdc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bb0:	4719                	li	a4,6
    80001bb2:	05893683          	ld	a3,88(s2)
    80001bb6:	6605                	lui	a2,0x1
    80001bb8:	020005b7          	lui	a1,0x2000
    80001bbc:	15fd                	addi	a1,a1,-1
    80001bbe:	05b6                	slli	a1,a1,0xd
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	4cc080e7          	jalr	1228(ra) # 8000108e <mappages>
    80001bca:	02054163          	bltz	a0,80001bec <proc_pagetable+0x76>
}
    80001bce:	8526                	mv	a0,s1
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6902                	ld	s2,0(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret
    uvmfree(pagetable, 0);
    80001bdc:	4581                	li	a1,0
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	922080e7          	jalr	-1758(ra) # 80001502 <uvmfree>
    return 0;
    80001be8:	4481                	li	s1,0
    80001bea:	b7d5                	j	80001bce <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bec:	4681                	li	a3,0
    80001bee:	4605                	li	a2,1
    80001bf0:	040005b7          	lui	a1,0x4000
    80001bf4:	15fd                	addi	a1,a1,-1
    80001bf6:	05b2                	slli	a1,a1,0xc
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	648080e7          	jalr	1608(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c02:	4581                	li	a1,0
    80001c04:	8526                	mv	a0,s1
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	8fc080e7          	jalr	-1796(ra) # 80001502 <uvmfree>
    return 0;
    80001c0e:	4481                	li	s1,0
    80001c10:	bf7d                	j	80001bce <proc_pagetable+0x58>

0000000080001c12 <proc_freepagetable>:
{
    80001c12:	1101                	addi	sp,sp,-32
    80001c14:	ec06                	sd	ra,24(sp)
    80001c16:	e822                	sd	s0,16(sp)
    80001c18:	e426                	sd	s1,8(sp)
    80001c1a:	e04a                	sd	s2,0(sp)
    80001c1c:	1000                	addi	s0,sp,32
    80001c1e:	84aa                	mv	s1,a0
    80001c20:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c22:	4681                	li	a3,0
    80001c24:	4605                	li	a2,1
    80001c26:	040005b7          	lui	a1,0x4000
    80001c2a:	15fd                	addi	a1,a1,-1
    80001c2c:	05b2                	slli	a1,a1,0xc
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	614080e7          	jalr	1556(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c36:	4681                	li	a3,0
    80001c38:	4605                	li	a2,1
    80001c3a:	020005b7          	lui	a1,0x2000
    80001c3e:	15fd                	addi	a1,a1,-1
    80001c40:	05b6                	slli	a1,a1,0xd
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	5fe080e7          	jalr	1534(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c4c:	85ca                	mv	a1,s2
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	8b2080e7          	jalr	-1870(ra) # 80001502 <uvmfree>
}
    80001c58:	60e2                	ld	ra,24(sp)
    80001c5a:	6442                	ld	s0,16(sp)
    80001c5c:	64a2                	ld	s1,8(sp)
    80001c5e:	6902                	ld	s2,0(sp)
    80001c60:	6105                	addi	sp,sp,32
    80001c62:	8082                	ret

0000000080001c64 <freeproc>:
{
    80001c64:	1101                	addi	sp,sp,-32
    80001c66:	ec06                	sd	ra,24(sp)
    80001c68:	e822                	sd	s0,16(sp)
    80001c6a:	e426                	sd	s1,8(sp)
    80001c6c:	1000                	addi	s0,sp,32
    80001c6e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c70:	6d28                	ld	a0,88(a0)
    80001c72:	c509                	beqz	a0,80001c7c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	d62080e7          	jalr	-670(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001c7c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001c80:	68a8                	ld	a0,80(s1)
    80001c82:	c511                	beqz	a0,80001c8e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c84:	64ac                	ld	a1,72(s1)
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	f8c080e7          	jalr	-116(ra) # 80001c12 <proc_freepagetable>
  p->pagetable = 0;
    80001c8e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c92:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c96:	0204a823          	sw	zero,48(s1)
  p->ticks = 0; //Leyuan & Lee
    80001c9a:	1604a423          	sw	zero,360(s1)
  p->parent = 0;
    80001c9e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ca2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ca6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001caa:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cae:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cb2:	0004ac23          	sw	zero,24(s1)
}
    80001cb6:	60e2                	ld	ra,24(sp)
    80001cb8:	6442                	ld	s0,16(sp)
    80001cba:	64a2                	ld	s1,8(sp)
    80001cbc:	6105                	addi	sp,sp,32
    80001cbe:	8082                	ret

0000000080001cc0 <allocproc>:
{
    80001cc0:	1101                	addi	sp,sp,-32
    80001cc2:	ec06                	sd	ra,24(sp)
    80001cc4:	e822                	sd	s0,16(sp)
    80001cc6:	e426                	sd	s1,8(sp)
    80001cc8:	e04a                	sd	s2,0(sp)
    80001cca:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001ccc:	00010497          	auipc	s1,0x10
    80001cd0:	e3448493          	addi	s1,s1,-460 # 80011b00 <proc>
    80001cd4:	00016917          	auipc	s2,0x16
    80001cd8:	c2c90913          	addi	s2,s2,-980 # 80017900 <tickslock>
    acquire(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	ee4080e7          	jalr	-284(ra) # 80000bc2 <acquire>
    if (p->state == UNUSED)
    80001ce6:	4c9c                	lw	a5,24(s1)
    80001ce8:	cf81                	beqz	a5,80001d00 <allocproc+0x40>
      release(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	f8a080e7          	jalr	-118(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cf4:	17848493          	addi	s1,s1,376
    80001cf8:	ff2492e3          	bne	s1,s2,80001cdc <allocproc+0x1c>
  return 0;
    80001cfc:	4481                	li	s1,0
    80001cfe:	a8a9                	j	80001d58 <allocproc+0x98>
  p->pid = allocpid();
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	e30080e7          	jalr	-464(ra) # 80001b30 <allocpid>
    80001d08:	d888                	sw	a0,48(s1)
  p->ticks = 0; //Leyuan & Lee
    80001d0a:	1604a423          	sw	zero,360(s1)
  p->level = 1;
    80001d0e:	4785                	li	a5,1
    80001d10:	16f4b823          	sd	a5,368(s1)
  p->state = USED;
    80001d14:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	dbc080e7          	jalr	-580(ra) # 80000ad2 <kalloc>
    80001d1e:	892a                	mv	s2,a0
    80001d20:	eca8                	sd	a0,88(s1)
    80001d22:	c131                	beqz	a0,80001d66 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001d24:	8526                	mv	a0,s1
    80001d26:	00000097          	auipc	ra,0x0
    80001d2a:	e50080e7          	jalr	-432(ra) # 80001b76 <proc_pagetable>
    80001d2e:	892a                	mv	s2,a0
    80001d30:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d32:	c531                	beqz	a0,80001d7e <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001d34:	07000613          	li	a2,112
    80001d38:	4581                	li	a1,0
    80001d3a:	06048513          	addi	a0,s1,96
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	f80080e7          	jalr	-128(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001d46:	00000797          	auipc	a5,0x0
    80001d4a:	da478793          	addi	a5,a5,-604 # 80001aea <forkret>
    80001d4e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d50:	60bc                	ld	a5,64(s1)
    80001d52:	6705                	lui	a4,0x1
    80001d54:	97ba                	add	a5,a5,a4
    80001d56:	f4bc                	sd	a5,104(s1)
}
    80001d58:	8526                	mv	a0,s1
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret
    freeproc(p);
    80001d66:	8526                	mv	a0,s1
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	efc080e7          	jalr	-260(ra) # 80001c64 <freeproc>
    release(&p->lock);
    80001d70:	8526                	mv	a0,s1
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	f04080e7          	jalr	-252(ra) # 80000c76 <release>
    return 0;
    80001d7a:	84ca                	mv	s1,s2
    80001d7c:	bff1                	j	80001d58 <allocproc+0x98>
    freeproc(p);
    80001d7e:	8526                	mv	a0,s1
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	ee4080e7          	jalr	-284(ra) # 80001c64 <freeproc>
    release(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	eec080e7          	jalr	-276(ra) # 80000c76 <release>
    return 0;
    80001d92:	84ca                	mv	s1,s2
    80001d94:	b7d1                	j	80001d58 <allocproc+0x98>

0000000080001d96 <userinit>:
{
    80001d96:	1101                	addi	sp,sp,-32
    80001d98:	ec06                	sd	ra,24(sp)
    80001d9a:	e822                	sd	s0,16(sp)
    80001d9c:	e426                	sd	s1,8(sp)
    80001d9e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	f20080e7          	jalr	-224(ra) # 80001cc0 <allocproc>
    80001da8:	84aa                	mv	s1,a0
  initproc = p;
    80001daa:	00007797          	auipc	a5,0x7
    80001dae:	26a7bf23          	sd	a0,638(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001db2:	03400613          	li	a2,52
    80001db6:	00007597          	auipc	a1,0x7
    80001dba:	a7a58593          	addi	a1,a1,-1414 # 80008830 <initcode>
    80001dbe:	6928                	ld	a0,80(a0)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	574080e7          	jalr	1396(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001dc8:	6785                	lui	a5,0x1
    80001dca:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dcc:	6cb8                	ld	a4,88(s1)
    80001dce:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001dd2:	6cb8                	ld	a4,88(s1)
    80001dd4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dd6:	4641                	li	a2,16
    80001dd8:	00006597          	auipc	a1,0x6
    80001ddc:	42858593          	addi	a1,a1,1064 # 80008200 <digits+0x1c0>
    80001de0:	15848513          	addi	a0,s1,344
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	02c080e7          	jalr	44(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001dec:	00006517          	auipc	a0,0x6
    80001df0:	42450513          	addi	a0,a0,1060 # 80008210 <digits+0x1d0>
    80001df4:	00002097          	auipc	ra,0x2
    80001df8:	2b0080e7          	jalr	688(ra) # 800040a4 <namei>
    80001dfc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e00:	478d                	li	a5,3
    80001e02:	cc9c                	sw	a5,24(s1)
  enqueue(p);
    80001e04:	8526                	mv	a0,s1
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	a06080e7          	jalr	-1530(ra) # 8000180c <enqueue>
  release(&p->lock);
    80001e0e:	8526                	mv	a0,s1
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e66080e7          	jalr	-410(ra) # 80000c76 <release>
}
    80001e18:	60e2                	ld	ra,24(sp)
    80001e1a:	6442                	ld	s0,16(sp)
    80001e1c:	64a2                	ld	s1,8(sp)
    80001e1e:	6105                	addi	sp,sp,32
    80001e20:	8082                	ret

0000000080001e22 <growproc>:
{
    80001e22:	1101                	addi	sp,sp,-32
    80001e24:	ec06                	sd	ra,24(sp)
    80001e26:	e822                	sd	s0,16(sp)
    80001e28:	e426                	sd	s1,8(sp)
    80001e2a:	e04a                	sd	s2,0(sp)
    80001e2c:	1000                	addi	s0,sp,32
    80001e2e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	c80080e7          	jalr	-896(ra) # 80001ab0 <myproc>
    80001e38:	892a                	mv	s2,a0
  sz = p->sz;
    80001e3a:	652c                	ld	a1,72(a0)
    80001e3c:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001e40:	00904f63          	bgtz	s1,80001e5e <growproc+0x3c>
  else if (n < 0)
    80001e44:	0204cc63          	bltz	s1,80001e7c <growproc+0x5a>
  p->sz = sz;
    80001e48:	1602                	slli	a2,a2,0x20
    80001e4a:	9201                	srli	a2,a2,0x20
    80001e4c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e50:	4501                	li	a0,0
}
    80001e52:	60e2                	ld	ra,24(sp)
    80001e54:	6442                	ld	s0,16(sp)
    80001e56:	64a2                	ld	s1,8(sp)
    80001e58:	6902                	ld	s2,0(sp)
    80001e5a:	6105                	addi	sp,sp,32
    80001e5c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001e5e:	9e25                	addw	a2,a2,s1
    80001e60:	1602                	slli	a2,a2,0x20
    80001e62:	9201                	srli	a2,a2,0x20
    80001e64:	1582                	slli	a1,a1,0x20
    80001e66:	9181                	srli	a1,a1,0x20
    80001e68:	6928                	ld	a0,80(a0)
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	584080e7          	jalr	1412(ra) # 800013ee <uvmalloc>
    80001e72:	0005061b          	sext.w	a2,a0
    80001e76:	fa69                	bnez	a2,80001e48 <growproc+0x26>
      return -1;
    80001e78:	557d                	li	a0,-1
    80001e7a:	bfe1                	j	80001e52 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e7c:	9e25                	addw	a2,a2,s1
    80001e7e:	1602                	slli	a2,a2,0x20
    80001e80:	9201                	srli	a2,a2,0x20
    80001e82:	1582                	slli	a1,a1,0x20
    80001e84:	9181                	srli	a1,a1,0x20
    80001e86:	6928                	ld	a0,80(a0)
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	51e080e7          	jalr	1310(ra) # 800013a6 <uvmdealloc>
    80001e90:	0005061b          	sext.w	a2,a0
    80001e94:	bf55                	j	80001e48 <growproc+0x26>

0000000080001e96 <fork>:
{
    80001e96:	7139                	addi	sp,sp,-64
    80001e98:	fc06                	sd	ra,56(sp)
    80001e9a:	f822                	sd	s0,48(sp)
    80001e9c:	f426                	sd	s1,40(sp)
    80001e9e:	f04a                	sd	s2,32(sp)
    80001ea0:	ec4e                	sd	s3,24(sp)
    80001ea2:	e852                	sd	s4,16(sp)
    80001ea4:	e456                	sd	s5,8(sp)
    80001ea6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	c08080e7          	jalr	-1016(ra) # 80001ab0 <myproc>
    80001eb0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	e0e080e7          	jalr	-498(ra) # 80001cc0 <allocproc>
    80001eba:	12050163          	beqz	a0,80001fdc <fork+0x146>
    80001ebe:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ec0:	048ab603          	ld	a2,72(s5)
    80001ec4:	692c                	ld	a1,80(a0)
    80001ec6:	050ab503          	ld	a0,80(s5)
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	670080e7          	jalr	1648(ra) # 8000153a <uvmcopy>
    80001ed2:	04054863          	bltz	a0,80001f22 <fork+0x8c>
  np->sz = p->sz;
    80001ed6:	048ab783          	ld	a5,72(s5)
    80001eda:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ede:	058ab683          	ld	a3,88(s5)
    80001ee2:	87b6                	mv	a5,a3
    80001ee4:	0589b703          	ld	a4,88(s3)
    80001ee8:	12068693          	addi	a3,a3,288
    80001eec:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ef0:	6788                	ld	a0,8(a5)
    80001ef2:	6b8c                	ld	a1,16(a5)
    80001ef4:	6f90                	ld	a2,24(a5)
    80001ef6:	01073023          	sd	a6,0(a4)
    80001efa:	e708                	sd	a0,8(a4)
    80001efc:	eb0c                	sd	a1,16(a4)
    80001efe:	ef10                	sd	a2,24(a4)
    80001f00:	02078793          	addi	a5,a5,32
    80001f04:	02070713          	addi	a4,a4,32
    80001f08:	fed792e3          	bne	a5,a3,80001eec <fork+0x56>
  np->trapframe->a0 = 0;
    80001f0c:	0589b783          	ld	a5,88(s3)
    80001f10:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f14:	0d0a8493          	addi	s1,s5,208
    80001f18:	0d098913          	addi	s2,s3,208
    80001f1c:	150a8a13          	addi	s4,s5,336
    80001f20:	a00d                	j	80001f42 <fork+0xac>
    freeproc(np);
    80001f22:	854e                	mv	a0,s3
    80001f24:	00000097          	auipc	ra,0x0
    80001f28:	d40080e7          	jalr	-704(ra) # 80001c64 <freeproc>
    release(&np->lock);
    80001f2c:	854e                	mv	a0,s3
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d48080e7          	jalr	-696(ra) # 80000c76 <release>
    return -1;
    80001f36:	597d                	li	s2,-1
    80001f38:	a841                	j	80001fc8 <fork+0x132>
  for (i = 0; i < NOFILE; i++)
    80001f3a:	04a1                	addi	s1,s1,8
    80001f3c:	0921                	addi	s2,s2,8
    80001f3e:	01448b63          	beq	s1,s4,80001f54 <fork+0xbe>
    if (p->ofile[i])
    80001f42:	6088                	ld	a0,0(s1)
    80001f44:	d97d                	beqz	a0,80001f3a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f46:	00002097          	auipc	ra,0x2
    80001f4a:	7f4080e7          	jalr	2036(ra) # 8000473a <filedup>
    80001f4e:	00a93023          	sd	a0,0(s2)
    80001f52:	b7e5                	j	80001f3a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f54:	150ab503          	ld	a0,336(s5)
    80001f58:	00002097          	auipc	ra,0x2
    80001f5c:	958080e7          	jalr	-1704(ra) # 800038b0 <idup>
    80001f60:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f64:	4641                	li	a2,16
    80001f66:	158a8593          	addi	a1,s5,344
    80001f6a:	15898513          	addi	a0,s3,344
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	ea2080e7          	jalr	-350(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001f76:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001f7a:	854e                	mv	a0,s3
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	cfa080e7          	jalr	-774(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001f84:	0000f497          	auipc	s1,0xf
    80001f88:	76448493          	addi	s1,s1,1892 # 800116e8 <wait_lock>
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	c34080e7          	jalr	-972(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001f96:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cda080e7          	jalr	-806(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001fa4:	854e                	mv	a0,s3
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c1c080e7          	jalr	-996(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001fae:	478d                	li	a5,3
    80001fb0:	00f9ac23          	sw	a5,24(s3)
  enqueue(np);
    80001fb4:	854e                	mv	a0,s3
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	856080e7          	jalr	-1962(ra) # 8000180c <enqueue>
  release(&np->lock);
    80001fbe:	854e                	mv	a0,s3
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	cb6080e7          	jalr	-842(ra) # 80000c76 <release>
}
    80001fc8:	854a                	mv	a0,s2
    80001fca:	70e2                	ld	ra,56(sp)
    80001fcc:	7442                	ld	s0,48(sp)
    80001fce:	74a2                	ld	s1,40(sp)
    80001fd0:	7902                	ld	s2,32(sp)
    80001fd2:	69e2                	ld	s3,24(sp)
    80001fd4:	6a42                	ld	s4,16(sp)
    80001fd6:	6aa2                	ld	s5,8(sp)
    80001fd8:	6121                	addi	sp,sp,64
    80001fda:	8082                	ret
    return -1;
    80001fdc:	597d                	li	s2,-1
    80001fde:	b7ed                	j	80001fc8 <fork+0x132>

0000000080001fe0 <scheduler>:
{
    80001fe0:	7139                	addi	sp,sp,-64
    80001fe2:	fc06                	sd	ra,56(sp)
    80001fe4:	f822                	sd	s0,48(sp)
    80001fe6:	f426                	sd	s1,40(sp)
    80001fe8:	f04a                	sd	s2,32(sp)
    80001fea:	ec4e                	sd	s3,24(sp)
    80001fec:	e852                	sd	s4,16(sp)
    80001fee:	e456                	sd	s5,8(sp)
    80001ff0:	0080                	addi	s0,sp,64
    80001ff2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ff4:	2781                	sext.w	a5,a5
        swtch(&c->context, &p->context);
    80001ff6:	00779a13          	slli	s4,a5,0x7
    80001ffa:	0000f717          	auipc	a4,0xf
    80001ffe:	70e70713          	addi	a4,a4,1806 # 80011708 <cpus+0x8>
    80002002:	9a3a                	add	s4,s4,a4
      if (p->state == RUNNABLE)
    80002004:	490d                	li	s2,3
        p->state = RUNNING;
    80002006:	4a91                	li	s5,4
        c->proc = p;
    80002008:	079e                	slli	a5,a5,0x7
    8000200a:	0000f997          	auipc	s3,0xf
    8000200e:	29698993          	addi	s3,s3,662 # 800112a0 <qtable>
    80002012:	99be                	add	s3,s3,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002014:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002018:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000201c:	10079073          	csrw	sstatus,a5
}
    80002020:	a031                	j	8000202c <scheduler+0x4c>
      release(&p->lock);
    80002022:	8526                	mv	a0,s1
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	c52080e7          	jalr	-942(ra) # 80000c76 <release>
    while ((p = dequeue()) != 0)
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	870080e7          	jalr	-1936(ra) # 8000189c <dequeue>
    80002034:	84aa                	mv	s1,a0
    80002036:	dd79                	beqz	a0,80002014 <scheduler+0x34>
      acquire(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	b88080e7          	jalr	-1144(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80002042:	4c9c                	lw	a5,24(s1)
    80002044:	fd279fe3          	bne	a5,s2,80002022 <scheduler+0x42>
        p->state = RUNNING;
    80002048:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    8000204c:	4699b023          	sd	s1,1120(s3)
        swtch(&c->context, &p->context);
    80002050:	06048593          	addi	a1,s1,96
    80002054:	8552                	mv	a0,s4
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	7ba080e7          	jalr	1978(ra) # 80002810 <swtch>
        c->proc = 0;
    8000205e:	4609b023          	sd	zero,1120(s3)
    80002062:	b7c1                	j	80002022 <scheduler+0x42>

0000000080002064 <sched>:
{
    80002064:	7179                	addi	sp,sp,-48
    80002066:	f406                	sd	ra,40(sp)
    80002068:	f022                	sd	s0,32(sp)
    8000206a:	ec26                	sd	s1,24(sp)
    8000206c:	e84a                	sd	s2,16(sp)
    8000206e:	e44e                	sd	s3,8(sp)
    80002070:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	a3e080e7          	jalr	-1474(ra) # 80001ab0 <myproc>
    8000207a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	acc080e7          	jalr	-1332(ra) # 80000b48 <holding>
    80002084:	c93d                	beqz	a0,800020fa <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002086:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002088:	2781                	sext.w	a5,a5
    8000208a:	079e                	slli	a5,a5,0x7
    8000208c:	0000f717          	auipc	a4,0xf
    80002090:	21470713          	addi	a4,a4,532 # 800112a0 <qtable>
    80002094:	97ba                	add	a5,a5,a4
    80002096:	4d87a703          	lw	a4,1240(a5)
    8000209a:	4785                	li	a5,1
    8000209c:	06f71763          	bne	a4,a5,8000210a <sched+0xa6>
  if (p->state == RUNNING)
    800020a0:	4c98                	lw	a4,24(s1)
    800020a2:	4791                	li	a5,4
    800020a4:	06f70b63          	beq	a4,a5,8000211a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020ac:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020ae:	efb5                	bnez	a5,8000212a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020b2:	0000f917          	auipc	s2,0xf
    800020b6:	1ee90913          	addi	s2,s2,494 # 800112a0 <qtable>
    800020ba:	2781                	sext.w	a5,a5
    800020bc:	079e                	slli	a5,a5,0x7
    800020be:	97ca                	add	a5,a5,s2
    800020c0:	4dc7a983          	lw	s3,1244(a5)
    800020c4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020c6:	2781                	sext.w	a5,a5
    800020c8:	079e                	slli	a5,a5,0x7
    800020ca:	0000f597          	auipc	a1,0xf
    800020ce:	63e58593          	addi	a1,a1,1598 # 80011708 <cpus+0x8>
    800020d2:	95be                	add	a1,a1,a5
    800020d4:	06048513          	addi	a0,s1,96
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	738080e7          	jalr	1848(ra) # 80002810 <swtch>
    800020e0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020e2:	2781                	sext.w	a5,a5
    800020e4:	079e                	slli	a5,a5,0x7
    800020e6:	97ca                	add	a5,a5,s2
    800020e8:	4d37ae23          	sw	s3,1244(a5)
}
    800020ec:	70a2                	ld	ra,40(sp)
    800020ee:	7402                	ld	s0,32(sp)
    800020f0:	64e2                	ld	s1,24(sp)
    800020f2:	6942                	ld	s2,16(sp)
    800020f4:	69a2                	ld	s3,8(sp)
    800020f6:	6145                	addi	sp,sp,48
    800020f8:	8082                	ret
    panic("sched p->lock");
    800020fa:	00006517          	auipc	a0,0x6
    800020fe:	11e50513          	addi	a0,a0,286 # 80008218 <digits+0x1d8>
    80002102:	ffffe097          	auipc	ra,0xffffe
    80002106:	428080e7          	jalr	1064(ra) # 8000052a <panic>
    panic("sched locks");
    8000210a:	00006517          	auipc	a0,0x6
    8000210e:	11e50513          	addi	a0,a0,286 # 80008228 <digits+0x1e8>
    80002112:	ffffe097          	auipc	ra,0xffffe
    80002116:	418080e7          	jalr	1048(ra) # 8000052a <panic>
    panic("sched running");
    8000211a:	00006517          	auipc	a0,0x6
    8000211e:	11e50513          	addi	a0,a0,286 # 80008238 <digits+0x1f8>
    80002122:	ffffe097          	auipc	ra,0xffffe
    80002126:	408080e7          	jalr	1032(ra) # 8000052a <panic>
    panic("sched interruptible");
    8000212a:	00006517          	auipc	a0,0x6
    8000212e:	11e50513          	addi	a0,a0,286 # 80008248 <digits+0x208>
    80002132:	ffffe097          	auipc	ra,0xffffe
    80002136:	3f8080e7          	jalr	1016(ra) # 8000052a <panic>

000000008000213a <yield>:
{
    8000213a:	1101                	addi	sp,sp,-32
    8000213c:	ec06                	sd	ra,24(sp)
    8000213e:	e822                	sd	s0,16(sp)
    80002140:	e426                	sd	s1,8(sp)
    80002142:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002144:	00000097          	auipc	ra,0x0
    80002148:	96c080e7          	jalr	-1684(ra) # 80001ab0 <myproc>
    8000214c:	84aa                	mv	s1,a0
  global_ticks++;
    8000214e:	00007717          	auipc	a4,0x7
    80002152:	ee270713          	addi	a4,a4,-286 # 80009030 <global_ticks>
    80002156:	431c                	lw	a5,0(a4)
    80002158:	2785                	addiw	a5,a5,1
    8000215a:	c31c                	sw	a5,0(a4)
  if (global_ticks % 32 == 0)
    8000215c:	8bfd                	andi	a5,a5,31
    8000215e:	ebdd                	bnez	a5,80002214 <yield+0xda>
    if (Q3->next != EMPTY)
    80002160:	0000f797          	auipc	a5,0xf
    80002164:	5687b783          	ld	a5,1384(a5) # 800116c8 <qtable+0x428>
    80002168:	577d                	li	a4,-1
    8000216a:	04e78863          	beq	a5,a4,800021ba <yield+0x80>
      if (Q2->next != EMPTY)
    8000216e:	0000f697          	auipc	a3,0xf
    80002172:	54a6b683          	ld	a3,1354(a3) # 800116b8 <qtable+0x418>
    80002176:	0ce68563          	beq	a3,a4,80002240 <yield+0x106>
        uint64 lQ3 = Q3->prev;
    8000217a:	0000f717          	auipc	a4,0xf
    8000217e:	12670713          	addi	a4,a4,294 # 800112a0 <qtable>
    80002182:	42073603          	ld	a2,1056(a4)
        uint64 lQ2 = Q2->prev;
    80002186:	41073583          	ld	a1,1040(a4)
        lq2QTable->next = fQ3;
    8000218a:	00459693          	slli	a3,a1,0x4
    8000218e:	96ba                	add	a3,a3,a4
    80002190:	e69c                	sd	a5,8(a3)
        fq3QTable->prev = lQ2;
    80002192:	0792                	slli	a5,a5,0x4
    80002194:	97ba                	add	a5,a5,a4
    80002196:	e38c                	sd	a1,0(a5)
        lq3QTable->next = Q2 - qtable;
    80002198:	00461793          	slli	a5,a2,0x4
    8000219c:	97ba                	add	a5,a5,a4
    8000219e:	04100693          	li	a3,65
    800021a2:	e794                	sd	a3,8(a5)
        Q2->prev = lQ3;
    800021a4:	40c73823          	sd	a2,1040(a4)
      Q3->next = EMPTY;
    800021a8:	0000f797          	auipc	a5,0xf
    800021ac:	0f878793          	addi	a5,a5,248 # 800112a0 <qtable>
    800021b0:	577d                	li	a4,-1
    800021b2:	42e7b423          	sd	a4,1064(a5)
      Q3->prev = EMPTY;
    800021b6:	42e7b023          	sd	a4,1056(a5)
    if (Q2->next != EMPTY)
    800021ba:	0000f797          	auipc	a5,0xf
    800021be:	4fe7b783          	ld	a5,1278(a5) # 800116b8 <qtable+0x418>
    800021c2:	577d                	li	a4,-1
    800021c4:	04e78863          	beq	a5,a4,80002214 <yield+0xda>
      if (Q1->next != EMPTY)
    800021c8:	0000f697          	auipc	a3,0xf
    800021cc:	4e06b683          	ld	a3,1248(a3) # 800116a8 <qtable+0x408>
    800021d0:	08e68363          	beq	a3,a4,80002256 <yield+0x11c>
        uint64 lQ2 = Q2->prev;
    800021d4:	0000f717          	auipc	a4,0xf
    800021d8:	0cc70713          	addi	a4,a4,204 # 800112a0 <qtable>
    800021dc:	41073603          	ld	a2,1040(a4)
        uint64 lQ1 = Q1->prev;
    800021e0:	40073583          	ld	a1,1024(a4)
        lq1QTable->next = fQ2;
    800021e4:	00459693          	slli	a3,a1,0x4
    800021e8:	96ba                	add	a3,a3,a4
    800021ea:	e69c                	sd	a5,8(a3)
        fq2QTable->prev = lQ1;
    800021ec:	0792                	slli	a5,a5,0x4
    800021ee:	97ba                	add	a5,a5,a4
    800021f0:	e38c                	sd	a1,0(a5)
        lq2QTable->next = Q1 - qtable;
    800021f2:	00461793          	slli	a5,a2,0x4
    800021f6:	97ba                	add	a5,a5,a4
    800021f8:	04000693          	li	a3,64
    800021fc:	e794                	sd	a3,8(a5)
        Q1->prev = lQ2;
    800021fe:	40c73023          	sd	a2,1024(a4)
      Q2->next = EMPTY;
    80002202:	0000f797          	auipc	a5,0xf
    80002206:	09e78793          	addi	a5,a5,158 # 800112a0 <qtable>
    8000220a:	577d                	li	a4,-1
    8000220c:	40e7bc23          	sd	a4,1048(a5)
      Q2->prev = EMPTY;
    80002210:	40e7b823          	sd	a4,1040(a5)
  p->ticks++;
    80002214:	1684a783          	lw	a5,360(s1)
    80002218:	2785                	addiw	a5,a5,1
    8000221a:	0007869b          	sext.w	a3,a5
    8000221e:	16f4a423          	sw	a5,360(s1)
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
    80002222:	1704b783          	ld	a5,368(s1)
    80002226:	4705                	li	a4,1
    80002228:	04e78563          	beq	a5,a4,80002272 <yield+0x138>
    8000222c:	4709                	li	a4,2
    8000222e:	02e78f63          	beq	a5,a4,8000226c <yield+0x132>
    80002232:	470d                	li	a4,3
    80002234:	06e79c63          	bne	a5,a4,800022ac <yield+0x172>
    80002238:	478d                	li	a5,3
    8000223a:	06d7d963          	bge	a5,a3,800022ac <yield+0x172>
    8000223e:	a815                	j	80002272 <yield+0x138>
        Q2->next = Q3->next;
    80002240:	0000f717          	auipc	a4,0xf
    80002244:	06070713          	addi	a4,a4,96 # 800112a0 <qtable>
    80002248:	40f73c23          	sd	a5,1048(a4)
        Q2->prev = Q3->prev;
    8000224c:	42073783          	ld	a5,1056(a4)
    80002250:	40f73823          	sd	a5,1040(a4)
    80002254:	bf91                	j	800021a8 <yield+0x6e>
        Q1->next = Q2->next;
    80002256:	0000f717          	auipc	a4,0xf
    8000225a:	04a70713          	addi	a4,a4,74 # 800112a0 <qtable>
    8000225e:	40f73423          	sd	a5,1032(a4)
        Q1->prev = Q2->prev;
    80002262:	41073783          	ld	a5,1040(a4)
    80002266:	40f73023          	sd	a5,1024(a4)
    8000226a:	bf61                	j	80002202 <yield+0xc8>
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
    8000226c:	4785                	li	a5,1
    8000226e:	02d7df63          	bge	a5,a3,800022ac <yield+0x172>
    acquire(&p->lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	94e080e7          	jalr	-1714(ra) # 80000bc2 <acquire>
    p->state = RUNNABLE;
    8000227c:	478d                	li	a5,3
    8000227e:	cc9c                	sw	a5,24(s1)
    if (p->level < 3)
    80002280:	1704b783          	ld	a5,368(s1)
    80002284:	4709                	li	a4,2
    80002286:	00f76563          	bltu	a4,a5,80002290 <yield+0x156>
      p->level++;
    8000228a:	0785                	addi	a5,a5,1
    8000228c:	16f4b823          	sd	a5,368(s1)
    enqueue(p); //might need to discuss
    80002290:	8526                	mv	a0,s1
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	57a080e7          	jalr	1402(ra) # 8000180c <enqueue>
    sched();
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	dca080e7          	jalr	-566(ra) # 80002064 <sched>
    release(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9d2080e7          	jalr	-1582(ra) # 80000c76 <release>
}
    800022ac:	60e2                	ld	ra,24(sp)
    800022ae:	6442                	ld	s0,16(sp)
    800022b0:	64a2                	ld	s1,8(sp)
    800022b2:	6105                	addi	sp,sp,32
    800022b4:	8082                	ret

00000000800022b6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	1800                	addi	s0,sp,48
    800022c4:	89aa                	mv	s3,a0
    800022c6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	7e8080e7          	jalr	2024(ra) # 80001ab0 <myproc>
    800022d0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	8f0080e7          	jalr	-1808(ra) # 80000bc2 <acquire>
  release(lk);
    800022da:	854a                	mv	a0,s2
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	99a080e7          	jalr	-1638(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800022e4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022e8:	4789                	li	a5,2
    800022ea:	cc9c                	sw	a5,24(s1)

  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	d78080e7          	jalr	-648(ra) # 80002064 <sched>

  // Tidy up.
  p->chan = 0;
    800022f4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022f8:	8526                	mv	a0,s1
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	97c080e7          	jalr	-1668(ra) # 80000c76 <release>
  acquire(lk);
    80002302:	854a                	mv	a0,s2
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	8be080e7          	jalr	-1858(ra) # 80000bc2 <acquire>
}
    8000230c:	70a2                	ld	ra,40(sp)
    8000230e:	7402                	ld	s0,32(sp)
    80002310:	64e2                	ld	s1,24(sp)
    80002312:	6942                	ld	s2,16(sp)
    80002314:	69a2                	ld	s3,8(sp)
    80002316:	6145                	addi	sp,sp,48
    80002318:	8082                	ret

000000008000231a <wait>:
{
    8000231a:	715d                	addi	sp,sp,-80
    8000231c:	e486                	sd	ra,72(sp)
    8000231e:	e0a2                	sd	s0,64(sp)
    80002320:	fc26                	sd	s1,56(sp)
    80002322:	f84a                	sd	s2,48(sp)
    80002324:	f44e                	sd	s3,40(sp)
    80002326:	f052                	sd	s4,32(sp)
    80002328:	ec56                	sd	s5,24(sp)
    8000232a:	e85a                	sd	s6,16(sp)
    8000232c:	e45e                	sd	s7,8(sp)
    8000232e:	e062                	sd	s8,0(sp)
    80002330:	0880                	addi	s0,sp,80
    80002332:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	77c080e7          	jalr	1916(ra) # 80001ab0 <myproc>
    8000233c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000233e:	0000f517          	auipc	a0,0xf
    80002342:	3aa50513          	addi	a0,a0,938 # 800116e8 <wait_lock>
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	87c080e7          	jalr	-1924(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000234e:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002350:	4a15                	li	s4,5
        havekids = 1;
    80002352:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002354:	00015997          	auipc	s3,0x15
    80002358:	5ac98993          	addi	s3,s3,1452 # 80017900 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000235c:	0000fc17          	auipc	s8,0xf
    80002360:	38cc0c13          	addi	s8,s8,908 # 800116e8 <wait_lock>
    havekids = 0;
    80002364:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002366:	0000f497          	auipc	s1,0xf
    8000236a:	79a48493          	addi	s1,s1,1946 # 80011b00 <proc>
    8000236e:	a0bd                	j	800023dc <wait+0xc2>
          pid = np->pid;
    80002370:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002374:	000b0e63          	beqz	s6,80002390 <wait+0x76>
    80002378:	4691                	li	a3,4
    8000237a:	02c48613          	addi	a2,s1,44
    8000237e:	85da                	mv	a1,s6
    80002380:	05093503          	ld	a0,80(s2)
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	2ba080e7          	jalr	698(ra) # 8000163e <copyout>
    8000238c:	02054563          	bltz	a0,800023b6 <wait+0x9c>
          freeproc(np);
    80002390:	8526                	mv	a0,s1
    80002392:	00000097          	auipc	ra,0x0
    80002396:	8d2080e7          	jalr	-1838(ra) # 80001c64 <freeproc>
          release(&np->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	8da080e7          	jalr	-1830(ra) # 80000c76 <release>
          release(&wait_lock);
    800023a4:	0000f517          	auipc	a0,0xf
    800023a8:	34450513          	addi	a0,a0,836 # 800116e8 <wait_lock>
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	8ca080e7          	jalr	-1846(ra) # 80000c76 <release>
          return pid;
    800023b4:	a09d                	j	8000241a <wait+0x100>
            release(&np->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8be080e7          	jalr	-1858(ra) # 80000c76 <release>
            release(&wait_lock);
    800023c0:	0000f517          	auipc	a0,0xf
    800023c4:	32850513          	addi	a0,a0,808 # 800116e8 <wait_lock>
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8ae080e7          	jalr	-1874(ra) # 80000c76 <release>
            return -1;
    800023d0:	59fd                	li	s3,-1
    800023d2:	a0a1                	j	8000241a <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800023d4:	17848493          	addi	s1,s1,376
    800023d8:	03348463          	beq	s1,s3,80002400 <wait+0xe6>
      if (np->parent == p)
    800023dc:	7c9c                	ld	a5,56(s1)
    800023de:	ff279be3          	bne	a5,s2,800023d4 <wait+0xba>
        acquire(&np->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	7de080e7          	jalr	2014(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    800023ec:	4c9c                	lw	a5,24(s1)
    800023ee:	f94781e3          	beq	a5,s4,80002370 <wait+0x56>
        release(&np->lock);
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	882080e7          	jalr	-1918(ra) # 80000c76 <release>
        havekids = 1;
    800023fc:	8756                	mv	a4,s5
    800023fe:	bfd9                	j	800023d4 <wait+0xba>
    if (!havekids || p->killed)
    80002400:	c701                	beqz	a4,80002408 <wait+0xee>
    80002402:	02892783          	lw	a5,40(s2)
    80002406:	c79d                	beqz	a5,80002434 <wait+0x11a>
      release(&wait_lock);
    80002408:	0000f517          	auipc	a0,0xf
    8000240c:	2e050513          	addi	a0,a0,736 # 800116e8 <wait_lock>
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	866080e7          	jalr	-1946(ra) # 80000c76 <release>
      return -1;
    80002418:	59fd                	li	s3,-1
}
    8000241a:	854e                	mv	a0,s3
    8000241c:	60a6                	ld	ra,72(sp)
    8000241e:	6406                	ld	s0,64(sp)
    80002420:	74e2                	ld	s1,56(sp)
    80002422:	7942                	ld	s2,48(sp)
    80002424:	79a2                	ld	s3,40(sp)
    80002426:	7a02                	ld	s4,32(sp)
    80002428:	6ae2                	ld	s5,24(sp)
    8000242a:	6b42                	ld	s6,16(sp)
    8000242c:	6ba2                	ld	s7,8(sp)
    8000242e:	6c02                	ld	s8,0(sp)
    80002430:	6161                	addi	sp,sp,80
    80002432:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002434:	85e2                	mv	a1,s8
    80002436:	854a                	mv	a0,s2
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	e7e080e7          	jalr	-386(ra) # 800022b6 <sleep>
    havekids = 0;
    80002440:	b715                	j	80002364 <wait+0x4a>

0000000080002442 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002442:	7139                	addi	sp,sp,-64
    80002444:	fc06                	sd	ra,56(sp)
    80002446:	f822                	sd	s0,48(sp)
    80002448:	f426                	sd	s1,40(sp)
    8000244a:	f04a                	sd	s2,32(sp)
    8000244c:	ec4e                	sd	s3,24(sp)
    8000244e:	e852                	sd	s4,16(sp)
    80002450:	e456                	sd	s5,8(sp)
    80002452:	0080                	addi	s0,sp,64
    80002454:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002456:	0000f497          	auipc	s1,0xf
    8000245a:	6aa48493          	addi	s1,s1,1706 # 80011b00 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000245e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002460:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002462:	00015917          	auipc	s2,0x15
    80002466:	49e90913          	addi	s2,s2,1182 # 80017900 <tickslock>
    8000246a:	a811                	j	8000247e <wakeup+0x3c>
        //Leyuan & Lee
        enqueue(p);
      }
      release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	808080e7          	jalr	-2040(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002476:	17848493          	addi	s1,s1,376
    8000247a:	03248b63          	beq	s1,s2,800024b0 <wakeup+0x6e>
    if (p != myproc())
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	632080e7          	jalr	1586(ra) # 80001ab0 <myproc>
    80002486:	fea488e3          	beq	s1,a0,80002476 <wakeup+0x34>
      acquire(&p->lock);
    8000248a:	8526                	mv	a0,s1
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	736080e7          	jalr	1846(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002494:	4c9c                	lw	a5,24(s1)
    80002496:	fd379be3          	bne	a5,s3,8000246c <wakeup+0x2a>
    8000249a:	709c                	ld	a5,32(s1)
    8000249c:	fd4798e3          	bne	a5,s4,8000246c <wakeup+0x2a>
        p->state = RUNNABLE;
    800024a0:	0154ac23          	sw	s5,24(s1)
        enqueue(p);
    800024a4:	8526                	mv	a0,s1
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	366080e7          	jalr	870(ra) # 8000180c <enqueue>
    800024ae:	bf7d                	j	8000246c <wakeup+0x2a>
    }
  }
}
    800024b0:	70e2                	ld	ra,56(sp)
    800024b2:	7442                	ld	s0,48(sp)
    800024b4:	74a2                	ld	s1,40(sp)
    800024b6:	7902                	ld	s2,32(sp)
    800024b8:	69e2                	ld	s3,24(sp)
    800024ba:	6a42                	ld	s4,16(sp)
    800024bc:	6aa2                	ld	s5,8(sp)
    800024be:	6121                	addi	sp,sp,64
    800024c0:	8082                	ret

00000000800024c2 <reparent>:
{
    800024c2:	7179                	addi	sp,sp,-48
    800024c4:	f406                	sd	ra,40(sp)
    800024c6:	f022                	sd	s0,32(sp)
    800024c8:	ec26                	sd	s1,24(sp)
    800024ca:	e84a                	sd	s2,16(sp)
    800024cc:	e44e                	sd	s3,8(sp)
    800024ce:	e052                	sd	s4,0(sp)
    800024d0:	1800                	addi	s0,sp,48
    800024d2:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d4:	0000f497          	auipc	s1,0xf
    800024d8:	62c48493          	addi	s1,s1,1580 # 80011b00 <proc>
      pp->parent = initproc;
    800024dc:	00007a17          	auipc	s4,0x7
    800024e0:	b4ca0a13          	addi	s4,s4,-1204 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024e4:	00015997          	auipc	s3,0x15
    800024e8:	41c98993          	addi	s3,s3,1052 # 80017900 <tickslock>
    800024ec:	a029                	j	800024f6 <reparent+0x34>
    800024ee:	17848493          	addi	s1,s1,376
    800024f2:	01348d63          	beq	s1,s3,8000250c <reparent+0x4a>
    if (pp->parent == p)
    800024f6:	7c9c                	ld	a5,56(s1)
    800024f8:	ff279be3          	bne	a5,s2,800024ee <reparent+0x2c>
      pp->parent = initproc;
    800024fc:	000a3503          	ld	a0,0(s4)
    80002500:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002502:	00000097          	auipc	ra,0x0
    80002506:	f40080e7          	jalr	-192(ra) # 80002442 <wakeup>
    8000250a:	b7d5                	j	800024ee <reparent+0x2c>
}
    8000250c:	70a2                	ld	ra,40(sp)
    8000250e:	7402                	ld	s0,32(sp)
    80002510:	64e2                	ld	s1,24(sp)
    80002512:	6942                	ld	s2,16(sp)
    80002514:	69a2                	ld	s3,8(sp)
    80002516:	6a02                	ld	s4,0(sp)
    80002518:	6145                	addi	sp,sp,48
    8000251a:	8082                	ret

000000008000251c <exit>:
{
    8000251c:	7179                	addi	sp,sp,-48
    8000251e:	f406                	sd	ra,40(sp)
    80002520:	f022                	sd	s0,32(sp)
    80002522:	ec26                	sd	s1,24(sp)
    80002524:	e84a                	sd	s2,16(sp)
    80002526:	e44e                	sd	s3,8(sp)
    80002528:	e052                	sd	s4,0(sp)
    8000252a:	1800                	addi	s0,sp,48
    8000252c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	582080e7          	jalr	1410(ra) # 80001ab0 <myproc>
    80002536:	89aa                	mv	s3,a0
  if (p == initproc)
    80002538:	00007797          	auipc	a5,0x7
    8000253c:	af07b783          	ld	a5,-1296(a5) # 80009028 <initproc>
    80002540:	0d050493          	addi	s1,a0,208
    80002544:	15050913          	addi	s2,a0,336
    80002548:	02a79363          	bne	a5,a0,8000256e <exit+0x52>
    panic("init exiting");
    8000254c:	00006517          	auipc	a0,0x6
    80002550:	d1450513          	addi	a0,a0,-748 # 80008260 <digits+0x220>
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	fd6080e7          	jalr	-42(ra) # 8000052a <panic>
      fileclose(f);
    8000255c:	00002097          	auipc	ra,0x2
    80002560:	230080e7          	jalr	560(ra) # 8000478c <fileclose>
      p->ofile[fd] = 0;
    80002564:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002568:	04a1                	addi	s1,s1,8
    8000256a:	01248563          	beq	s1,s2,80002574 <exit+0x58>
    if (p->ofile[fd])
    8000256e:	6088                	ld	a0,0(s1)
    80002570:	f575                	bnez	a0,8000255c <exit+0x40>
    80002572:	bfdd                	j	80002568 <exit+0x4c>
  begin_op();
    80002574:	00002097          	auipc	ra,0x2
    80002578:	d4c080e7          	jalr	-692(ra) # 800042c0 <begin_op>
  iput(p->cwd);
    8000257c:	1509b503          	ld	a0,336(s3)
    80002580:	00001097          	auipc	ra,0x1
    80002584:	528080e7          	jalr	1320(ra) # 80003aa8 <iput>
  end_op();
    80002588:	00002097          	auipc	ra,0x2
    8000258c:	db8080e7          	jalr	-584(ra) # 80004340 <end_op>
  p->cwd = 0;
    80002590:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002594:	0000f497          	auipc	s1,0xf
    80002598:	15448493          	addi	s1,s1,340 # 800116e8 <wait_lock>
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	624080e7          	jalr	1572(ra) # 80000bc2 <acquire>
  reparent(p);
    800025a6:	854e                	mv	a0,s3
    800025a8:	00000097          	auipc	ra,0x0
    800025ac:	f1a080e7          	jalr	-230(ra) # 800024c2 <reparent>
  wakeup(p->parent);
    800025b0:	0389b503          	ld	a0,56(s3)
    800025b4:	00000097          	auipc	ra,0x0
    800025b8:	e8e080e7          	jalr	-370(ra) # 80002442 <wakeup>
  acquire(&p->lock);
    800025bc:	854e                	mv	a0,s3
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	604080e7          	jalr	1540(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800025c6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025ca:	4795                	li	a5,5
    800025cc:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	6a4080e7          	jalr	1700(ra) # 80000c76 <release>
  sched();
    800025da:	00000097          	auipc	ra,0x0
    800025de:	a8a080e7          	jalr	-1398(ra) # 80002064 <sched>
  panic("zombie exit");
    800025e2:	00006517          	auipc	a0,0x6
    800025e6:	c8e50513          	addi	a0,a0,-882 # 80008270 <digits+0x230>
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	f40080e7          	jalr	-192(ra) # 8000052a <panic>

00000000800025f2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025f2:	7179                	addi	sp,sp,-48
    800025f4:	f406                	sd	ra,40(sp)
    800025f6:	f022                	sd	s0,32(sp)
    800025f8:	ec26                	sd	s1,24(sp)
    800025fa:	e84a                	sd	s2,16(sp)
    800025fc:	e44e                	sd	s3,8(sp)
    800025fe:	1800                	addi	s0,sp,48
    80002600:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002602:	0000f497          	auipc	s1,0xf
    80002606:	4fe48493          	addi	s1,s1,1278 # 80011b00 <proc>
    8000260a:	00015997          	auipc	s3,0x15
    8000260e:	2f698993          	addi	s3,s3,758 # 80017900 <tickslock>
  {
    acquire(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	5ae080e7          	jalr	1454(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    8000261c:	589c                	lw	a5,48(s1)
    8000261e:	01278d63          	beq	a5,s2,80002638 <kill+0x46>
        enqueue(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	652080e7          	jalr	1618(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000262c:	17848493          	addi	s1,s1,376
    80002630:	ff3491e3          	bne	s1,s3,80002612 <kill+0x20>
  }
  return -1;
    80002634:	557d                	li	a0,-1
    80002636:	a829                	j	80002650 <kill+0x5e>
      p->killed = 1;
    80002638:	4785                	li	a5,1
    8000263a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000263c:	4c98                	lw	a4,24(s1)
    8000263e:	4789                	li	a5,2
    80002640:	00f70f63          	beq	a4,a5,8000265e <kill+0x6c>
      release(&p->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	630080e7          	jalr	1584(ra) # 80000c76 <release>
      return 0;
    8000264e:	4501                	li	a0,0
}
    80002650:	70a2                	ld	ra,40(sp)
    80002652:	7402                	ld	s0,32(sp)
    80002654:	64e2                	ld	s1,24(sp)
    80002656:	6942                	ld	s2,16(sp)
    80002658:	69a2                	ld	s3,8(sp)
    8000265a:	6145                	addi	sp,sp,48
    8000265c:	8082                	ret
        p->state = RUNNABLE;
    8000265e:	478d                	li	a5,3
    80002660:	cc9c                	sw	a5,24(s1)
        enqueue(p);
    80002662:	8526                	mv	a0,s1
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	1a8080e7          	jalr	424(ra) # 8000180c <enqueue>
    8000266c:	bfe1                	j	80002644 <kill+0x52>

000000008000266e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000266e:	7179                	addi	sp,sp,-48
    80002670:	f406                	sd	ra,40(sp)
    80002672:	f022                	sd	s0,32(sp)
    80002674:	ec26                	sd	s1,24(sp)
    80002676:	e84a                	sd	s2,16(sp)
    80002678:	e44e                	sd	s3,8(sp)
    8000267a:	e052                	sd	s4,0(sp)
    8000267c:	1800                	addi	s0,sp,48
    8000267e:	84aa                	mv	s1,a0
    80002680:	892e                	mv	s2,a1
    80002682:	89b2                	mv	s3,a2
    80002684:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	42a080e7          	jalr	1066(ra) # 80001ab0 <myproc>
  if (user_dst)
    8000268e:	c08d                	beqz	s1,800026b0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002690:	86d2                	mv	a3,s4
    80002692:	864e                	mv	a2,s3
    80002694:	85ca                	mv	a1,s2
    80002696:	6928                	ld	a0,80(a0)
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	fa6080e7          	jalr	-90(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026a0:	70a2                	ld	ra,40(sp)
    800026a2:	7402                	ld	s0,32(sp)
    800026a4:	64e2                	ld	s1,24(sp)
    800026a6:	6942                	ld	s2,16(sp)
    800026a8:	69a2                	ld	s3,8(sp)
    800026aa:	6a02                	ld	s4,0(sp)
    800026ac:	6145                	addi	sp,sp,48
    800026ae:	8082                	ret
    memmove((char *)dst, src, len);
    800026b0:	000a061b          	sext.w	a2,s4
    800026b4:	85ce                	mv	a1,s3
    800026b6:	854a                	mv	a0,s2
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	662080e7          	jalr	1634(ra) # 80000d1a <memmove>
    return 0;
    800026c0:	8526                	mv	a0,s1
    800026c2:	bff9                	j	800026a0 <either_copyout+0x32>

00000000800026c4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026c4:	7179                	addi	sp,sp,-48
    800026c6:	f406                	sd	ra,40(sp)
    800026c8:	f022                	sd	s0,32(sp)
    800026ca:	ec26                	sd	s1,24(sp)
    800026cc:	e84a                	sd	s2,16(sp)
    800026ce:	e44e                	sd	s3,8(sp)
    800026d0:	e052                	sd	s4,0(sp)
    800026d2:	1800                	addi	s0,sp,48
    800026d4:	892a                	mv	s2,a0
    800026d6:	84ae                	mv	s1,a1
    800026d8:	89b2                	mv	s3,a2
    800026da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	3d4080e7          	jalr	980(ra) # 80001ab0 <myproc>
  if (user_src)
    800026e4:	c08d                	beqz	s1,80002706 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026e6:	86d2                	mv	a3,s4
    800026e8:	864e                	mv	a2,s3
    800026ea:	85ca                	mv	a1,s2
    800026ec:	6928                	ld	a0,80(a0)
    800026ee:	fffff097          	auipc	ra,0xfffff
    800026f2:	fdc080e7          	jalr	-36(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026f6:	70a2                	ld	ra,40(sp)
    800026f8:	7402                	ld	s0,32(sp)
    800026fa:	64e2                	ld	s1,24(sp)
    800026fc:	6942                	ld	s2,16(sp)
    800026fe:	69a2                	ld	s3,8(sp)
    80002700:	6a02                	ld	s4,0(sp)
    80002702:	6145                	addi	sp,sp,48
    80002704:	8082                	ret
    memmove(dst, (char *)src, len);
    80002706:	000a061b          	sext.w	a2,s4
    8000270a:	85ce                	mv	a1,s3
    8000270c:	854a                	mv	a0,s2
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	60c080e7          	jalr	1548(ra) # 80000d1a <memmove>
    return 0;
    80002716:	8526                	mv	a0,s1
    80002718:	bff9                	j	800026f6 <either_copyin+0x32>

000000008000271a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000271a:	715d                	addi	sp,sp,-80
    8000271c:	e486                	sd	ra,72(sp)
    8000271e:	e0a2                	sd	s0,64(sp)
    80002720:	fc26                	sd	s1,56(sp)
    80002722:	f84a                	sd	s2,48(sp)
    80002724:	f44e                	sd	s3,40(sp)
    80002726:	f052                	sd	s4,32(sp)
    80002728:	ec56                	sd	s5,24(sp)
    8000272a:	e85a                	sd	s6,16(sp)
    8000272c:	e45e                	sd	s7,8(sp)
    8000272e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002730:	00006517          	auipc	a0,0x6
    80002734:	99850513          	addi	a0,a0,-1640 # 800080c8 <digits+0x88>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	e3c080e7          	jalr	-452(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002740:	0000f497          	auipc	s1,0xf
    80002744:	51848493          	addi	s1,s1,1304 # 80011c58 <proc+0x158>
    80002748:	00015917          	auipc	s2,0x15
    8000274c:	31090913          	addi	s2,s2,784 # 80017a58 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002750:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002752:	00006997          	auipc	s3,0x6
    80002756:	b2e98993          	addi	s3,s3,-1234 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000275a:	00006a97          	auipc	s5,0x6
    8000275e:	b2ea8a93          	addi	s5,s5,-1234 # 80008288 <digits+0x248>
    printf("\n");
    80002762:	00006a17          	auipc	s4,0x6
    80002766:	966a0a13          	addi	s4,s4,-1690 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000276a:	00006b97          	auipc	s7,0x6
    8000276e:	b56b8b93          	addi	s7,s7,-1194 # 800082c0 <states.0>
    80002772:	a00d                	j	80002794 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002774:	ed86a583          	lw	a1,-296(a3)
    80002778:	8556                	mv	a0,s5
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	dfa080e7          	jalr	-518(ra) # 80000574 <printf>
    printf("\n");
    80002782:	8552                	mv	a0,s4
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	df0080e7          	jalr	-528(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000278c:	17848493          	addi	s1,s1,376
    80002790:	03248163          	beq	s1,s2,800027b2 <procdump+0x98>
    if (p->state == UNUSED)
    80002794:	86a6                	mv	a3,s1
    80002796:	ec04a783          	lw	a5,-320(s1)
    8000279a:	dbed                	beqz	a5,8000278c <procdump+0x72>
      state = "???";
    8000279c:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279e:	fcfb6be3          	bltu	s6,a5,80002774 <procdump+0x5a>
    800027a2:	1782                	slli	a5,a5,0x20
    800027a4:	9381                	srli	a5,a5,0x20
    800027a6:	078e                	slli	a5,a5,0x3
    800027a8:	97de                	add	a5,a5,s7
    800027aa:	6390                	ld	a2,0(a5)
    800027ac:	f661                	bnez	a2,80002774 <procdump+0x5a>
      state = "???";
    800027ae:	864e                	mv	a2,s3
    800027b0:	b7d1                	j	80002774 <procdump+0x5a>
  }
}
    800027b2:	60a6                	ld	ra,72(sp)
    800027b4:	6406                	ld	s0,64(sp)
    800027b6:	74e2                	ld	s1,56(sp)
    800027b8:	7942                	ld	s2,48(sp)
    800027ba:	79a2                	ld	s3,40(sp)
    800027bc:	7a02                	ld	s4,32(sp)
    800027be:	6ae2                	ld	s5,24(sp)
    800027c0:	6b42                	ld	s6,16(sp)
    800027c2:	6ba2                	ld	s7,8(sp)
    800027c4:	6161                	addi	sp,sp,80
    800027c6:	8082                	ret

00000000800027c8 <kgetpstat>:

//Leyuan & Lee
uint64 kgetpstat(struct pstat *ps)
{
    800027c8:	1141                	addi	sp,sp,-16
    800027ca:	e422                	sd	s0,8(sp)
    800027cc:	0800                	addi	s0,sp,16
  for (int i = 0; i < NPROC; ++i)
    800027ce:	0000f797          	auipc	a5,0xf
    800027d2:	34a78793          	addi	a5,a5,842 # 80011b18 <proc+0x18>
    800027d6:	00015697          	auipc	a3,0x15
    800027da:	14268693          	addi	a3,a3,322 # 80017918 <bcache>
  {
    struct proc *p = proc + i;
    ps->inuse[i] = p->state == UNUSED ? 0 : 1;
    800027de:	4398                	lw	a4,0(a5)
    800027e0:	00e03733          	snez	a4,a4
    800027e4:	c118                	sw	a4,0(a0)
    ps->ticks[i] = p->ticks;
    800027e6:	1507a703          	lw	a4,336(a5)
    800027ea:	20e52023          	sw	a4,512(a0)
    ps->pid[i] = p->pid;
    800027ee:	4f98                	lw	a4,24(a5)
    800027f0:	10e52023          	sw	a4,256(a0)
    ps->queue[i] = p->level - 1;
    800027f4:	1587b703          	ld	a4,344(a5)
    800027f8:	377d                	addiw	a4,a4,-1
    800027fa:	30e52023          	sw	a4,768(a0)
  for (int i = 0; i < NPROC; ++i)
    800027fe:	17878793          	addi	a5,a5,376
    80002802:	0511                	addi	a0,a0,4
    80002804:	fcd79de3          	bne	a5,a3,800027de <kgetpstat+0x16>
  }
  return 0;
    80002808:	4501                	li	a0,0
    8000280a:	6422                	ld	s0,8(sp)
    8000280c:	0141                	addi	sp,sp,16
    8000280e:	8082                	ret

0000000080002810 <swtch>:
    80002810:	00153023          	sd	ra,0(a0)
    80002814:	00253423          	sd	sp,8(a0)
    80002818:	e900                	sd	s0,16(a0)
    8000281a:	ed04                	sd	s1,24(a0)
    8000281c:	03253023          	sd	s2,32(a0)
    80002820:	03353423          	sd	s3,40(a0)
    80002824:	03453823          	sd	s4,48(a0)
    80002828:	03553c23          	sd	s5,56(a0)
    8000282c:	05653023          	sd	s6,64(a0)
    80002830:	05753423          	sd	s7,72(a0)
    80002834:	05853823          	sd	s8,80(a0)
    80002838:	05953c23          	sd	s9,88(a0)
    8000283c:	07a53023          	sd	s10,96(a0)
    80002840:	07b53423          	sd	s11,104(a0)
    80002844:	0005b083          	ld	ra,0(a1)
    80002848:	0085b103          	ld	sp,8(a1)
    8000284c:	6980                	ld	s0,16(a1)
    8000284e:	6d84                	ld	s1,24(a1)
    80002850:	0205b903          	ld	s2,32(a1)
    80002854:	0285b983          	ld	s3,40(a1)
    80002858:	0305ba03          	ld	s4,48(a1)
    8000285c:	0385ba83          	ld	s5,56(a1)
    80002860:	0405bb03          	ld	s6,64(a1)
    80002864:	0485bb83          	ld	s7,72(a1)
    80002868:	0505bc03          	ld	s8,80(a1)
    8000286c:	0585bc83          	ld	s9,88(a1)
    80002870:	0605bd03          	ld	s10,96(a1)
    80002874:	0685bd83          	ld	s11,104(a1)
    80002878:	8082                	ret

000000008000287a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000287a:	1141                	addi	sp,sp,-16
    8000287c:	e406                	sd	ra,8(sp)
    8000287e:	e022                	sd	s0,0(sp)
    80002880:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002882:	00006597          	auipc	a1,0x6
    80002886:	a6e58593          	addi	a1,a1,-1426 # 800082f0 <states.0+0x30>
    8000288a:	00015517          	auipc	a0,0x15
    8000288e:	07650513          	addi	a0,a0,118 # 80017900 <tickslock>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	2a0080e7          	jalr	672(ra) # 80000b32 <initlock>
}
    8000289a:	60a2                	ld	ra,8(sp)
    8000289c:	6402                	ld	s0,0(sp)
    8000289e:	0141                	addi	sp,sp,16
    800028a0:	8082                	ret

00000000800028a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028a2:	1141                	addi	sp,sp,-16
    800028a4:	e422                	sd	s0,8(sp)
    800028a6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a8:	00003797          	auipc	a5,0x3
    800028ac:	50878793          	addi	a5,a5,1288 # 80005db0 <kernelvec>
    800028b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028b4:	6422                	ld	s0,8(sp)
    800028b6:	0141                	addi	sp,sp,16
    800028b8:	8082                	ret

00000000800028ba <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028ba:	1141                	addi	sp,sp,-16
    800028bc:	e406                	sd	ra,8(sp)
    800028be:	e022                	sd	s0,0(sp)
    800028c0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028c2:	fffff097          	auipc	ra,0xfffff
    800028c6:	1ee080e7          	jalr	494(ra) # 80001ab0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028d4:	00004617          	auipc	a2,0x4
    800028d8:	72c60613          	addi	a2,a2,1836 # 80007000 <_trampoline>
    800028dc:	00004697          	auipc	a3,0x4
    800028e0:	72468693          	addi	a3,a3,1828 # 80007000 <_trampoline>
    800028e4:	8e91                	sub	a3,a3,a2
    800028e6:	040007b7          	lui	a5,0x4000
    800028ea:	17fd                	addi	a5,a5,-1
    800028ec:	07b2                	slli	a5,a5,0xc
    800028ee:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028f6:	180026f3          	csrr	a3,satp
    800028fa:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028fc:	6d38                	ld	a4,88(a0)
    800028fe:	6134                	ld	a3,64(a0)
    80002900:	6585                	lui	a1,0x1
    80002902:	96ae                	add	a3,a3,a1
    80002904:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002906:	6d38                	ld	a4,88(a0)
    80002908:	00000697          	auipc	a3,0x0
    8000290c:	13868693          	addi	a3,a3,312 # 80002a40 <usertrap>
    80002910:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002912:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002914:	8692                	mv	a3,tp
    80002916:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002918:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000291c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002920:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002924:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002928:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000292a:	6f18                	ld	a4,24(a4)
    8000292c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002930:	692c                	ld	a1,80(a0)
    80002932:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002934:	00004717          	auipc	a4,0x4
    80002938:	75c70713          	addi	a4,a4,1884 # 80007090 <userret>
    8000293c:	8f11                	sub	a4,a4,a2
    8000293e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002940:	577d                	li	a4,-1
    80002942:	177e                	slli	a4,a4,0x3f
    80002944:	8dd9                	or	a1,a1,a4
    80002946:	02000537          	lui	a0,0x2000
    8000294a:	157d                	addi	a0,a0,-1
    8000294c:	0536                	slli	a0,a0,0xd
    8000294e:	9782                	jalr	a5
}
    80002950:	60a2                	ld	ra,8(sp)
    80002952:	6402                	ld	s0,0(sp)
    80002954:	0141                	addi	sp,sp,16
    80002956:	8082                	ret

0000000080002958 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002958:	1101                	addi	sp,sp,-32
    8000295a:	ec06                	sd	ra,24(sp)
    8000295c:	e822                	sd	s0,16(sp)
    8000295e:	e426                	sd	s1,8(sp)
    80002960:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002962:	00015497          	auipc	s1,0x15
    80002966:	f9e48493          	addi	s1,s1,-98 # 80017900 <tickslock>
    8000296a:	8526                	mv	a0,s1
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	256080e7          	jalr	598(ra) # 80000bc2 <acquire>
  ticks++;
    80002974:	00006517          	auipc	a0,0x6
    80002978:	6c050513          	addi	a0,a0,1728 # 80009034 <ticks>
    8000297c:	411c                	lw	a5,0(a0)
    8000297e:	2785                	addiw	a5,a5,1
    80002980:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002982:	00000097          	auipc	ra,0x0
    80002986:	ac0080e7          	jalr	-1344(ra) # 80002442 <wakeup>
  release(&tickslock);
    8000298a:	8526                	mv	a0,s1
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	2ea080e7          	jalr	746(ra) # 80000c76 <release>
}
    80002994:	60e2                	ld	ra,24(sp)
    80002996:	6442                	ld	s0,16(sp)
    80002998:	64a2                	ld	s1,8(sp)
    8000299a:	6105                	addi	sp,sp,32
    8000299c:	8082                	ret

000000008000299e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000299e:	1101                	addi	sp,sp,-32
    800029a0:	ec06                	sd	ra,24(sp)
    800029a2:	e822                	sd	s0,16(sp)
    800029a4:	e426                	sd	s1,8(sp)
    800029a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029ac:	00074d63          	bltz	a4,800029c6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029b0:	57fd                	li	a5,-1
    800029b2:	17fe                	slli	a5,a5,0x3f
    800029b4:	0785                	addi	a5,a5,1
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    
    return 0;
    800029b6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029b8:	06f70363          	beq	a4,a5,80002a1e <devintr+0x80>
  }
}
    800029bc:	60e2                	ld	ra,24(sp)
    800029be:	6442                	ld	s0,16(sp)
    800029c0:	64a2                	ld	s1,8(sp)
    800029c2:	6105                	addi	sp,sp,32
    800029c4:	8082                	ret
     (scause & 0xff) == 9){
    800029c6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029ca:	46a5                	li	a3,9
    800029cc:	fed792e3          	bne	a5,a3,800029b0 <devintr+0x12>
    int irq = plic_claim();
    800029d0:	00003097          	auipc	ra,0x3
    800029d4:	4e8080e7          	jalr	1256(ra) # 80005eb8 <plic_claim>
    800029d8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029da:	47a9                	li	a5,10
    800029dc:	02f50763          	beq	a0,a5,80002a0a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029e0:	4785                	li	a5,1
    800029e2:	02f50963          	beq	a0,a5,80002a14 <devintr+0x76>
    return 1;
    800029e6:	4505                	li	a0,1
    } else if(irq){
    800029e8:	d8f1                	beqz	s1,800029bc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029ea:	85a6                	mv	a1,s1
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	90c50513          	addi	a0,a0,-1780 # 800082f8 <states.0+0x38>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b80080e7          	jalr	-1152(ra) # 80000574 <printf>
      plic_complete(irq);
    800029fc:	8526                	mv	a0,s1
    800029fe:	00003097          	auipc	ra,0x3
    80002a02:	4de080e7          	jalr	1246(ra) # 80005edc <plic_complete>
    return 1;
    80002a06:	4505                	li	a0,1
    80002a08:	bf55                	j	800029bc <devintr+0x1e>
      uartintr();
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	f7c080e7          	jalr	-132(ra) # 80000986 <uartintr>
    80002a12:	b7ed                	j	800029fc <devintr+0x5e>
      virtio_disk_intr();
    80002a14:	00004097          	auipc	ra,0x4
    80002a18:	95a080e7          	jalr	-1702(ra) # 8000636e <virtio_disk_intr>
    80002a1c:	b7c5                	j	800029fc <devintr+0x5e>
    if(cpuid() == 0){
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	066080e7          	jalr	102(ra) # 80001a84 <cpuid>
    80002a26:	c901                	beqz	a0,80002a36 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a28:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a2c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a2e:	14479073          	csrw	sip,a5
    return 2;
    80002a32:	4509                	li	a0,2
    80002a34:	b761                	j	800029bc <devintr+0x1e>
      clockintr();
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	f22080e7          	jalr	-222(ra) # 80002958 <clockintr>
    80002a3e:	b7ed                	j	80002a28 <devintr+0x8a>

0000000080002a40 <usertrap>:
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	e04a                	sd	s2,0(sp)
    80002a4a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a50:	1007f793          	andi	a5,a5,256
    80002a54:	e3ad                	bnez	a5,80002ab6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a56:	00003797          	auipc	a5,0x3
    80002a5a:	35a78793          	addi	a5,a5,858 # 80005db0 <kernelvec>
    80002a5e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	04e080e7          	jalr	78(ra) # 80001ab0 <myproc>
    80002a6a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a6c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6e:	14102773          	csrr	a4,sepc
    80002a72:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a74:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a78:	47a1                	li	a5,8
    80002a7a:	04f71c63          	bne	a4,a5,80002ad2 <usertrap+0x92>
    if(p->killed)
    80002a7e:	551c                	lw	a5,40(a0)
    80002a80:	e3b9                	bnez	a5,80002ac6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a82:	6cb8                	ld	a4,88(s1)
    80002a84:	6f1c                	ld	a5,24(a4)
    80002a86:	0791                	addi	a5,a5,4
    80002a88:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a8e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a92:	10079073          	csrw	sstatus,a5
    syscall();
    80002a96:	00000097          	auipc	ra,0x0
    80002a9a:	2e0080e7          	jalr	736(ra) # 80002d76 <syscall>
  if(p->killed)
    80002a9e:	549c                	lw	a5,40(s1)
    80002aa0:	ebc1                	bnez	a5,80002b30 <usertrap+0xf0>
  usertrapret();
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	e18080e7          	jalr	-488(ra) # 800028ba <usertrapret>
}
    80002aaa:	60e2                	ld	ra,24(sp)
    80002aac:	6442                	ld	s0,16(sp)
    80002aae:	64a2                	ld	s1,8(sp)
    80002ab0:	6902                	ld	s2,0(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret
    panic("usertrap: not from user mode");
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	86250513          	addi	a0,a0,-1950 # 80008318 <states.0+0x58>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	a6c080e7          	jalr	-1428(ra) # 8000052a <panic>
      exit(-1);
    80002ac6:	557d                	li	a0,-1
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	a54080e7          	jalr	-1452(ra) # 8000251c <exit>
    80002ad0:	bf4d                	j	80002a82 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	ecc080e7          	jalr	-308(ra) # 8000299e <devintr>
    80002ada:	892a                	mv	s2,a0
    80002adc:	c501                	beqz	a0,80002ae4 <usertrap+0xa4>
  if(p->killed)
    80002ade:	549c                	lw	a5,40(s1)
    80002ae0:	c3a1                	beqz	a5,80002b20 <usertrap+0xe0>
    80002ae2:	a815                	j	80002b16 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ae8:	5890                	lw	a2,48(s1)
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	84e50513          	addi	a0,a0,-1970 # 80008338 <states.0+0x78>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a82080e7          	jalr	-1406(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002afe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b02:	00006517          	auipc	a0,0x6
    80002b06:	86650513          	addi	a0,a0,-1946 # 80008368 <states.0+0xa8>
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	a6a080e7          	jalr	-1430(ra) # 80000574 <printf>
    p->killed = 1;
    80002b12:	4785                	li	a5,1
    80002b14:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b16:	557d                	li	a0,-1
    80002b18:	00000097          	auipc	ra,0x0
    80002b1c:	a04080e7          	jalr	-1532(ra) # 8000251c <exit>
  if(which_dev == 2)
    80002b20:	4789                	li	a5,2
    80002b22:	f8f910e3          	bne	s2,a5,80002aa2 <usertrap+0x62>
    yield();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	614080e7          	jalr	1556(ra) # 8000213a <yield>
    80002b2e:	bf95                	j	80002aa2 <usertrap+0x62>
  int which_dev = 0;
    80002b30:	4901                	li	s2,0
    80002b32:	b7d5                	j	80002b16 <usertrap+0xd6>

0000000080002b34 <kerneltrap>:
{
    80002b34:	7179                	addi	sp,sp,-48
    80002b36:	f406                	sd	ra,40(sp)
    80002b38:	f022                	sd	s0,32(sp)
    80002b3a:	ec26                	sd	s1,24(sp)
    80002b3c:	e84a                	sd	s2,16(sp)
    80002b3e:	e44e                	sd	s3,8(sp)
    80002b40:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b42:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b46:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b4e:	1004f793          	andi	a5,s1,256
    80002b52:	cb85                	beqz	a5,80002b82 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b54:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b58:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b5a:	ef85                	bnez	a5,80002b92 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	e42080e7          	jalr	-446(ra) # 8000299e <devintr>
    80002b64:	cd1d                	beqz	a0,80002ba2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b66:	4789                	li	a5,2
    80002b68:	06f50a63          	beq	a0,a5,80002bdc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b6c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b70:	10049073          	csrw	sstatus,s1
}
    80002b74:	70a2                	ld	ra,40(sp)
    80002b76:	7402                	ld	s0,32(sp)
    80002b78:	64e2                	ld	s1,24(sp)
    80002b7a:	6942                	ld	s2,16(sp)
    80002b7c:	69a2                	ld	s3,8(sp)
    80002b7e:	6145                	addi	sp,sp,48
    80002b80:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	80650513          	addi	a0,a0,-2042 # 80008388 <states.0+0xc8>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9a0080e7          	jalr	-1632(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002b92:	00006517          	auipc	a0,0x6
    80002b96:	81e50513          	addi	a0,a0,-2018 # 800083b0 <states.0+0xf0>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	990080e7          	jalr	-1648(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002ba2:	85ce                	mv	a1,s3
    80002ba4:	00006517          	auipc	a0,0x6
    80002ba8:	82c50513          	addi	a0,a0,-2004 # 800083d0 <states.0+0x110>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	9c8080e7          	jalr	-1592(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bbc:	00006517          	auipc	a0,0x6
    80002bc0:	82450513          	addi	a0,a0,-2012 # 800083e0 <states.0+0x120>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	9b0080e7          	jalr	-1616(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002bcc:	00006517          	auipc	a0,0x6
    80002bd0:	82c50513          	addi	a0,a0,-2004 # 800083f8 <states.0+0x138>
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	956080e7          	jalr	-1706(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	ed4080e7          	jalr	-300(ra) # 80001ab0 <myproc>
    80002be4:	d541                	beqz	a0,80002b6c <kerneltrap+0x38>
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	eca080e7          	jalr	-310(ra) # 80001ab0 <myproc>
    80002bee:	4d18                	lw	a4,24(a0)
    80002bf0:	4791                	li	a5,4
    80002bf2:	f6f71de3          	bne	a4,a5,80002b6c <kerneltrap+0x38>
    yield();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	544080e7          	jalr	1348(ra) # 8000213a <yield>
    80002bfe:	b7bd                	j	80002b6c <kerneltrap+0x38>

0000000080002c00 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	1000                	addi	s0,sp,32
    80002c0a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	ea4080e7          	jalr	-348(ra) # 80001ab0 <myproc>
  switch (n) {
    80002c14:	4795                	li	a5,5
    80002c16:	0497e163          	bltu	a5,s1,80002c58 <argraw+0x58>
    80002c1a:	048a                	slli	s1,s1,0x2
    80002c1c:	00006717          	auipc	a4,0x6
    80002c20:	81470713          	addi	a4,a4,-2028 # 80008430 <states.0+0x170>
    80002c24:	94ba                	add	s1,s1,a4
    80002c26:	409c                	lw	a5,0(s1)
    80002c28:	97ba                	add	a5,a5,a4
    80002c2a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c2c:	6d3c                	ld	a5,88(a0)
    80002c2e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c30:	60e2                	ld	ra,24(sp)
    80002c32:	6442                	ld	s0,16(sp)
    80002c34:	64a2                	ld	s1,8(sp)
    80002c36:	6105                	addi	sp,sp,32
    80002c38:	8082                	ret
    return p->trapframe->a1;
    80002c3a:	6d3c                	ld	a5,88(a0)
    80002c3c:	7fa8                	ld	a0,120(a5)
    80002c3e:	bfcd                	j	80002c30 <argraw+0x30>
    return p->trapframe->a2;
    80002c40:	6d3c                	ld	a5,88(a0)
    80002c42:	63c8                	ld	a0,128(a5)
    80002c44:	b7f5                	j	80002c30 <argraw+0x30>
    return p->trapframe->a3;
    80002c46:	6d3c                	ld	a5,88(a0)
    80002c48:	67c8                	ld	a0,136(a5)
    80002c4a:	b7dd                	j	80002c30 <argraw+0x30>
    return p->trapframe->a4;
    80002c4c:	6d3c                	ld	a5,88(a0)
    80002c4e:	6bc8                	ld	a0,144(a5)
    80002c50:	b7c5                	j	80002c30 <argraw+0x30>
    return p->trapframe->a5;
    80002c52:	6d3c                	ld	a5,88(a0)
    80002c54:	6fc8                	ld	a0,152(a5)
    80002c56:	bfe9                	j	80002c30 <argraw+0x30>
  panic("argraw");
    80002c58:	00005517          	auipc	a0,0x5
    80002c5c:	7b050513          	addi	a0,a0,1968 # 80008408 <states.0+0x148>
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	8ca080e7          	jalr	-1846(ra) # 8000052a <panic>

0000000080002c68 <fetchaddr>:
{
    80002c68:	1101                	addi	sp,sp,-32
    80002c6a:	ec06                	sd	ra,24(sp)
    80002c6c:	e822                	sd	s0,16(sp)
    80002c6e:	e426                	sd	s1,8(sp)
    80002c70:	e04a                	sd	s2,0(sp)
    80002c72:	1000                	addi	s0,sp,32
    80002c74:	84aa                	mv	s1,a0
    80002c76:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	e38080e7          	jalr	-456(ra) # 80001ab0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c80:	653c                	ld	a5,72(a0)
    80002c82:	02f4f863          	bgeu	s1,a5,80002cb2 <fetchaddr+0x4a>
    80002c86:	00848713          	addi	a4,s1,8
    80002c8a:	02e7e663          	bltu	a5,a4,80002cb6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c8e:	46a1                	li	a3,8
    80002c90:	8626                	mv	a2,s1
    80002c92:	85ca                	mv	a1,s2
    80002c94:	6928                	ld	a0,80(a0)
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	a34080e7          	jalr	-1484(ra) # 800016ca <copyin>
    80002c9e:	00a03533          	snez	a0,a0
    80002ca2:	40a00533          	neg	a0,a0
}
    80002ca6:	60e2                	ld	ra,24(sp)
    80002ca8:	6442                	ld	s0,16(sp)
    80002caa:	64a2                	ld	s1,8(sp)
    80002cac:	6902                	ld	s2,0(sp)
    80002cae:	6105                	addi	sp,sp,32
    80002cb0:	8082                	ret
    return -1;
    80002cb2:	557d                	li	a0,-1
    80002cb4:	bfcd                	j	80002ca6 <fetchaddr+0x3e>
    80002cb6:	557d                	li	a0,-1
    80002cb8:	b7fd                	j	80002ca6 <fetchaddr+0x3e>

0000000080002cba <fetchstr>:
{
    80002cba:	7179                	addi	sp,sp,-48
    80002cbc:	f406                	sd	ra,40(sp)
    80002cbe:	f022                	sd	s0,32(sp)
    80002cc0:	ec26                	sd	s1,24(sp)
    80002cc2:	e84a                	sd	s2,16(sp)
    80002cc4:	e44e                	sd	s3,8(sp)
    80002cc6:	1800                	addi	s0,sp,48
    80002cc8:	892a                	mv	s2,a0
    80002cca:	84ae                	mv	s1,a1
    80002ccc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	de2080e7          	jalr	-542(ra) # 80001ab0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cd6:	86ce                	mv	a3,s3
    80002cd8:	864a                	mv	a2,s2
    80002cda:	85a6                	mv	a1,s1
    80002cdc:	6928                	ld	a0,80(a0)
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	a7a080e7          	jalr	-1414(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002ce6:	00054763          	bltz	a0,80002cf4 <fetchstr+0x3a>
  return strlen(buf);
    80002cea:	8526                	mv	a0,s1
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	156080e7          	jalr	342(ra) # 80000e42 <strlen>
}
    80002cf4:	70a2                	ld	ra,40(sp)
    80002cf6:	7402                	ld	s0,32(sp)
    80002cf8:	64e2                	ld	s1,24(sp)
    80002cfa:	6942                	ld	s2,16(sp)
    80002cfc:	69a2                	ld	s3,8(sp)
    80002cfe:	6145                	addi	sp,sp,48
    80002d00:	8082                	ret

0000000080002d02 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	1000                	addi	s0,sp,32
    80002d0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	ef2080e7          	jalr	-270(ra) # 80002c00 <argraw>
    80002d16:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d18:	4501                	li	a0,0
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	64a2                	ld	s1,8(sp)
    80002d20:	6105                	addi	sp,sp,32
    80002d22:	8082                	ret

0000000080002d24 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	e426                	sd	s1,8(sp)
    80002d2c:	1000                	addi	s0,sp,32
    80002d2e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	ed0080e7          	jalr	-304(ra) # 80002c00 <argraw>
    80002d38:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d3a:	4501                	li	a0,0
    80002d3c:	60e2                	ld	ra,24(sp)
    80002d3e:	6442                	ld	s0,16(sp)
    80002d40:	64a2                	ld	s1,8(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret

0000000080002d46 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	e426                	sd	s1,8(sp)
    80002d4e:	e04a                	sd	s2,0(sp)
    80002d50:	1000                	addi	s0,sp,32
    80002d52:	84ae                	mv	s1,a1
    80002d54:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	eaa080e7          	jalr	-342(ra) # 80002c00 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d5e:	864a                	mv	a2,s2
    80002d60:	85a6                	mv	a1,s1
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	f58080e7          	jalr	-168(ra) # 80002cba <fetchstr>
}
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	64a2                	ld	s1,8(sp)
    80002d70:	6902                	ld	s2,0(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret

0000000080002d76 <syscall>:

};

void
syscall(void)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	e426                	sd	s1,8(sp)
    80002d7e:	e04a                	sd	s2,0(sp)
    80002d80:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	d2e080e7          	jalr	-722(ra) # 80001ab0 <myproc>
    80002d8a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d8c:	05853903          	ld	s2,88(a0)
    80002d90:	0a893783          	ld	a5,168(s2)
    80002d94:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d98:	37fd                	addiw	a5,a5,-1
    80002d9a:	4755                	li	a4,21
    80002d9c:	00f76f63          	bltu	a4,a5,80002dba <syscall+0x44>
    80002da0:	00369713          	slli	a4,a3,0x3
    80002da4:	00005797          	auipc	a5,0x5
    80002da8:	6a478793          	addi	a5,a5,1700 # 80008448 <syscalls>
    80002dac:	97ba                	add	a5,a5,a4
    80002dae:	639c                	ld	a5,0(a5)
    80002db0:	c789                	beqz	a5,80002dba <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002db2:	9782                	jalr	a5
    80002db4:	06a93823          	sd	a0,112(s2)
    80002db8:	a839                	j	80002dd6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dba:	15848613          	addi	a2,s1,344
    80002dbe:	588c                	lw	a1,48(s1)
    80002dc0:	00005517          	auipc	a0,0x5
    80002dc4:	65050513          	addi	a0,a0,1616 # 80008410 <states.0+0x150>
    80002dc8:	ffffd097          	auipc	ra,0xffffd
    80002dcc:	7ac080e7          	jalr	1964(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dd0:	6cbc                	ld	a5,88(s1)
    80002dd2:	577d                	li	a4,-1
    80002dd4:	fbb8                	sd	a4,112(a5)
  }
}
    80002dd6:	60e2                	ld	ra,24(sp)
    80002dd8:	6442                	ld	s0,16(sp)
    80002dda:	64a2                	ld	s1,8(sp)
    80002ddc:	6902                	ld	s2,0(sp)
    80002dde:	6105                	addi	sp,sp,32
    80002de0:	8082                	ret

0000000080002de2 <sys_exit>:
#include "proc.h"
#include "pstat.h"

uint64
sys_exit(void)
{
    80002de2:	1101                	addi	sp,sp,-32
    80002de4:	ec06                	sd	ra,24(sp)
    80002de6:	e822                	sd	s0,16(sp)
    80002de8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dea:	fec40593          	addi	a1,s0,-20
    80002dee:	4501                	li	a0,0
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	f12080e7          	jalr	-238(ra) # 80002d02 <argint>
    return -1;
    80002df8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dfa:	00054963          	bltz	a0,80002e0c <sys_exit+0x2a>
  exit(n);
    80002dfe:	fec42503          	lw	a0,-20(s0)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	71a080e7          	jalr	1818(ra) # 8000251c <exit>
  return 0;  // not reached
    80002e0a:	4781                	li	a5,0
}
    80002e0c:	853e                	mv	a0,a5
    80002e0e:	60e2                	ld	ra,24(sp)
    80002e10:	6442                	ld	s0,16(sp)
    80002e12:	6105                	addi	sp,sp,32
    80002e14:	8082                	ret

0000000080002e16 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e16:	1141                	addi	sp,sp,-16
    80002e18:	e406                	sd	ra,8(sp)
    80002e1a:	e022                	sd	s0,0(sp)
    80002e1c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	c92080e7          	jalr	-878(ra) # 80001ab0 <myproc>
}
    80002e26:	5908                	lw	a0,48(a0)
    80002e28:	60a2                	ld	ra,8(sp)
    80002e2a:	6402                	ld	s0,0(sp)
    80002e2c:	0141                	addi	sp,sp,16
    80002e2e:	8082                	ret

0000000080002e30 <sys_fork>:

uint64
sys_fork(void)
{
    80002e30:	1141                	addi	sp,sp,-16
    80002e32:	e406                	sd	ra,8(sp)
    80002e34:	e022                	sd	s0,0(sp)
    80002e36:	0800                	addi	s0,sp,16
  return fork();
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	05e080e7          	jalr	94(ra) # 80001e96 <fork>
}
    80002e40:	60a2                	ld	ra,8(sp)
    80002e42:	6402                	ld	s0,0(sp)
    80002e44:	0141                	addi	sp,sp,16
    80002e46:	8082                	ret

0000000080002e48 <sys_wait>:

uint64
sys_wait(void)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e50:	fe840593          	addi	a1,s0,-24
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	ece080e7          	jalr	-306(ra) # 80002d24 <argaddr>
    80002e5e:	87aa                	mv	a5,a0
    return -1;
    80002e60:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e62:	0007c863          	bltz	a5,80002e72 <sys_wait+0x2a>
  return wait(p);
    80002e66:	fe843503          	ld	a0,-24(s0)
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	4b0080e7          	jalr	1200(ra) # 8000231a <wait>
}
    80002e72:	60e2                	ld	ra,24(sp)
    80002e74:	6442                	ld	s0,16(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e7a:	7179                	addi	sp,sp,-48
    80002e7c:	f406                	sd	ra,40(sp)
    80002e7e:	f022                	sd	s0,32(sp)
    80002e80:	ec26                	sd	s1,24(sp)
    80002e82:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e84:	fdc40593          	addi	a1,s0,-36
    80002e88:	4501                	li	a0,0
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	e78080e7          	jalr	-392(ra) # 80002d02 <argint>
    return -1;
    80002e92:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002e94:	00054f63          	bltz	a0,80002eb2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	c18080e7          	jalr	-1000(ra) # 80001ab0 <myproc>
    80002ea0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ea2:	fdc42503          	lw	a0,-36(s0)
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	f7c080e7          	jalr	-132(ra) # 80001e22 <growproc>
    80002eae:	00054863          	bltz	a0,80002ebe <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002eb2:	8526                	mv	a0,s1
    80002eb4:	70a2                	ld	ra,40(sp)
    80002eb6:	7402                	ld	s0,32(sp)
    80002eb8:	64e2                	ld	s1,24(sp)
    80002eba:	6145                	addi	sp,sp,48
    80002ebc:	8082                	ret
    return -1;
    80002ebe:	54fd                	li	s1,-1
    80002ec0:	bfcd                	j	80002eb2 <sys_sbrk+0x38>

0000000080002ec2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ec2:	7139                	addi	sp,sp,-64
    80002ec4:	fc06                	sd	ra,56(sp)
    80002ec6:	f822                	sd	s0,48(sp)
    80002ec8:	f426                	sd	s1,40(sp)
    80002eca:	f04a                	sd	s2,32(sp)
    80002ecc:	ec4e                	sd	s3,24(sp)
    80002ece:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ed0:	fcc40593          	addi	a1,s0,-52
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	e2c080e7          	jalr	-468(ra) # 80002d02 <argint>
    return -1;
    80002ede:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee0:	06054563          	bltz	a0,80002f4a <sys_sleep+0x88>
  acquire(&tickslock);
    80002ee4:	00015517          	auipc	a0,0x15
    80002ee8:	a1c50513          	addi	a0,a0,-1508 # 80017900 <tickslock>
    80002eec:	ffffe097          	auipc	ra,0xffffe
    80002ef0:	cd6080e7          	jalr	-810(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002ef4:	00006917          	auipc	s2,0x6
    80002ef8:	14092903          	lw	s2,320(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    80002efc:	fcc42783          	lw	a5,-52(s0)
    80002f00:	cf85                	beqz	a5,80002f38 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f02:	00015997          	auipc	s3,0x15
    80002f06:	9fe98993          	addi	s3,s3,-1538 # 80017900 <tickslock>
    80002f0a:	00006497          	auipc	s1,0x6
    80002f0e:	12a48493          	addi	s1,s1,298 # 80009034 <ticks>
    if(myproc()->killed){
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	b9e080e7          	jalr	-1122(ra) # 80001ab0 <myproc>
    80002f1a:	551c                	lw	a5,40(a0)
    80002f1c:	ef9d                	bnez	a5,80002f5a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f1e:	85ce                	mv	a1,s3
    80002f20:	8526                	mv	a0,s1
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	394080e7          	jalr	916(ra) # 800022b6 <sleep>
  while(ticks - ticks0 < n){
    80002f2a:	409c                	lw	a5,0(s1)
    80002f2c:	412787bb          	subw	a5,a5,s2
    80002f30:	fcc42703          	lw	a4,-52(s0)
    80002f34:	fce7efe3          	bltu	a5,a4,80002f12 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f38:	00015517          	auipc	a0,0x15
    80002f3c:	9c850513          	addi	a0,a0,-1592 # 80017900 <tickslock>
    80002f40:	ffffe097          	auipc	ra,0xffffe
    80002f44:	d36080e7          	jalr	-714(ra) # 80000c76 <release>
  return 0;
    80002f48:	4781                	li	a5,0
}
    80002f4a:	853e                	mv	a0,a5
    80002f4c:	70e2                	ld	ra,56(sp)
    80002f4e:	7442                	ld	s0,48(sp)
    80002f50:	74a2                	ld	s1,40(sp)
    80002f52:	7902                	ld	s2,32(sp)
    80002f54:	69e2                	ld	s3,24(sp)
    80002f56:	6121                	addi	sp,sp,64
    80002f58:	8082                	ret
      release(&tickslock);
    80002f5a:	00015517          	auipc	a0,0x15
    80002f5e:	9a650513          	addi	a0,a0,-1626 # 80017900 <tickslock>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d14080e7          	jalr	-748(ra) # 80000c76 <release>
      return -1;
    80002f6a:	57fd                	li	a5,-1
    80002f6c:	bff9                	j	80002f4a <sys_sleep+0x88>

0000000080002f6e <sys_kill>:

uint64
sys_kill(void)
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f76:	fec40593          	addi	a1,s0,-20
    80002f7a:	4501                	li	a0,0
    80002f7c:	00000097          	auipc	ra,0x0
    80002f80:	d86080e7          	jalr	-634(ra) # 80002d02 <argint>
    80002f84:	87aa                	mv	a5,a0
    return -1;
    80002f86:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f88:	0007c863          	bltz	a5,80002f98 <sys_kill+0x2a>
  return kill(pid);
    80002f8c:	fec42503          	lw	a0,-20(s0)
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	662080e7          	jalr	1634(ra) # 800025f2 <kill>
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	6105                	addi	sp,sp,32
    80002f9e:	8082                	ret

0000000080002fa0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fa0:	1101                	addi	sp,sp,-32
    80002fa2:	ec06                	sd	ra,24(sp)
    80002fa4:	e822                	sd	s0,16(sp)
    80002fa6:	e426                	sd	s1,8(sp)
    80002fa8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002faa:	00015517          	auipc	a0,0x15
    80002fae:	95650513          	addi	a0,a0,-1706 # 80017900 <tickslock>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	c10080e7          	jalr	-1008(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002fba:	00006497          	auipc	s1,0x6
    80002fbe:	07a4a483          	lw	s1,122(s1) # 80009034 <ticks>
  release(&tickslock);
    80002fc2:	00015517          	auipc	a0,0x15
    80002fc6:	93e50513          	addi	a0,a0,-1730 # 80017900 <tickslock>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	cac080e7          	jalr	-852(ra) # 80000c76 <release>
  return xticks;
}
    80002fd2:	02049513          	slli	a0,s1,0x20
    80002fd6:	9101                	srli	a0,a0,0x20
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	64a2                	ld	s1,8(sp)
    80002fde:	6105                	addi	sp,sp,32
    80002fe0:	8082                	ret

0000000080002fe2 <sys_getpstat>:

// Leyuan & Lee
//Added new sys call
uint64
sys_getpstat(void)
{
    80002fe2:	bd010113          	addi	sp,sp,-1072
    80002fe6:	42113423          	sd	ra,1064(sp)
    80002fea:	42813023          	sd	s0,1056(sp)
    80002fee:	40913c23          	sd	s1,1048(sp)
    80002ff2:	41213823          	sd	s2,1040(sp)
    80002ff6:	43010413          	addi	s0,sp,1072
  struct proc *p = myproc();
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	ab6080e7          	jalr	-1354(ra) # 80001ab0 <myproc>
    80003002:	892a                	mv	s2,a0
  uint64 upstat; // user virtual address, pointing to a struct pstat
  struct pstat kpstat; // struct pstat in kernel memory

  // get system call argument
  if(argaddr(0, &upstat) < 0)
    80003004:	fd840593          	addi	a1,s0,-40
    80003008:	4501                	li	a0,0
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	d1a080e7          	jalr	-742(ra) # 80002d24 <argaddr>
    return -1;
    80003012:	54fd                	li	s1,-1
  if(argaddr(0, &upstat) < 0)
    80003014:	02054763          	bltz	a0,80003042 <sys_getpstat+0x60>
  
 // TODO: define kernel side kgetpstat(struct pstat* ps), its purpose is to fill the values into kpstat.
  uint64 result = kgetpstat(&kpstat);
    80003018:	bd840513          	addi	a0,s0,-1064
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	7ac080e7          	jalr	1964(ra) # 800027c8 <kgetpstat>
    80003024:	84aa                	mv	s1,a0

  // copy pstat from kernel memory to user memory
  if(copyout(p->pagetable, upstat, (char *)&kpstat, sizeof(kpstat)) < 0)
    80003026:	40000693          	li	a3,1024
    8000302a:	bd840613          	addi	a2,s0,-1064
    8000302e:	fd843583          	ld	a1,-40(s0)
    80003032:	05093503          	ld	a0,80(s2)
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	608080e7          	jalr	1544(ra) # 8000163e <copyout>
    8000303e:	00054e63          	bltz	a0,8000305a <sys_getpstat+0x78>
    return -1;
  return result;
    80003042:	8526                	mv	a0,s1
    80003044:	42813083          	ld	ra,1064(sp)
    80003048:	42013403          	ld	s0,1056(sp)
    8000304c:	41813483          	ld	s1,1048(sp)
    80003050:	41013903          	ld	s2,1040(sp)
    80003054:	43010113          	addi	sp,sp,1072
    80003058:	8082                	ret
    return -1;
    8000305a:	54fd                	li	s1,-1
    8000305c:	b7dd                	j	80003042 <sys_getpstat+0x60>

000000008000305e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000305e:	7179                	addi	sp,sp,-48
    80003060:	f406                	sd	ra,40(sp)
    80003062:	f022                	sd	s0,32(sp)
    80003064:	ec26                	sd	s1,24(sp)
    80003066:	e84a                	sd	s2,16(sp)
    80003068:	e44e                	sd	s3,8(sp)
    8000306a:	e052                	sd	s4,0(sp)
    8000306c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000306e:	00005597          	auipc	a1,0x5
    80003072:	49258593          	addi	a1,a1,1170 # 80008500 <syscalls+0xb8>
    80003076:	00015517          	auipc	a0,0x15
    8000307a:	8a250513          	addi	a0,a0,-1886 # 80017918 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	ab4080e7          	jalr	-1356(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003086:	0001d797          	auipc	a5,0x1d
    8000308a:	89278793          	addi	a5,a5,-1902 # 8001f918 <bcache+0x8000>
    8000308e:	0001d717          	auipc	a4,0x1d
    80003092:	af270713          	addi	a4,a4,-1294 # 8001fb80 <bcache+0x8268>
    80003096:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000309a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000309e:	00015497          	auipc	s1,0x15
    800030a2:	89248493          	addi	s1,s1,-1902 # 80017930 <bcache+0x18>
    b->next = bcache.head.next;
    800030a6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030a8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030aa:	00005a17          	auipc	s4,0x5
    800030ae:	45ea0a13          	addi	s4,s4,1118 # 80008508 <syscalls+0xc0>
    b->next = bcache.head.next;
    800030b2:	2b893783          	ld	a5,696(s2)
    800030b6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030b8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030bc:	85d2                	mv	a1,s4
    800030be:	01048513          	addi	a0,s1,16
    800030c2:	00001097          	auipc	ra,0x1
    800030c6:	4bc080e7          	jalr	1212(ra) # 8000457e <initsleeplock>
    bcache.head.next->prev = b;
    800030ca:	2b893783          	ld	a5,696(s2)
    800030ce:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030d0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030d4:	45848493          	addi	s1,s1,1112
    800030d8:	fd349de3          	bne	s1,s3,800030b2 <binit+0x54>
  }
}
    800030dc:	70a2                	ld	ra,40(sp)
    800030de:	7402                	ld	s0,32(sp)
    800030e0:	64e2                	ld	s1,24(sp)
    800030e2:	6942                	ld	s2,16(sp)
    800030e4:	69a2                	ld	s3,8(sp)
    800030e6:	6a02                	ld	s4,0(sp)
    800030e8:	6145                	addi	sp,sp,48
    800030ea:	8082                	ret

00000000800030ec <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030ec:	7179                	addi	sp,sp,-48
    800030ee:	f406                	sd	ra,40(sp)
    800030f0:	f022                	sd	s0,32(sp)
    800030f2:	ec26                	sd	s1,24(sp)
    800030f4:	e84a                	sd	s2,16(sp)
    800030f6:	e44e                	sd	s3,8(sp)
    800030f8:	1800                	addi	s0,sp,48
    800030fa:	892a                	mv	s2,a0
    800030fc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030fe:	00015517          	auipc	a0,0x15
    80003102:	81a50513          	addi	a0,a0,-2022 # 80017918 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	abc080e7          	jalr	-1348(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000310e:	0001d497          	auipc	s1,0x1d
    80003112:	ac24b483          	ld	s1,-1342(s1) # 8001fbd0 <bcache+0x82b8>
    80003116:	0001d797          	auipc	a5,0x1d
    8000311a:	a6a78793          	addi	a5,a5,-1430 # 8001fb80 <bcache+0x8268>
    8000311e:	02f48f63          	beq	s1,a5,8000315c <bread+0x70>
    80003122:	873e                	mv	a4,a5
    80003124:	a021                	j	8000312c <bread+0x40>
    80003126:	68a4                	ld	s1,80(s1)
    80003128:	02e48a63          	beq	s1,a4,8000315c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000312c:	449c                	lw	a5,8(s1)
    8000312e:	ff279ce3          	bne	a5,s2,80003126 <bread+0x3a>
    80003132:	44dc                	lw	a5,12(s1)
    80003134:	ff3799e3          	bne	a5,s3,80003126 <bread+0x3a>
      b->refcnt++;
    80003138:	40bc                	lw	a5,64(s1)
    8000313a:	2785                	addiw	a5,a5,1
    8000313c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000313e:	00014517          	auipc	a0,0x14
    80003142:	7da50513          	addi	a0,a0,2010 # 80017918 <bcache>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	b30080e7          	jalr	-1232(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000314e:	01048513          	addi	a0,s1,16
    80003152:	00001097          	auipc	ra,0x1
    80003156:	466080e7          	jalr	1126(ra) # 800045b8 <acquiresleep>
      return b;
    8000315a:	a8b9                	j	800031b8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000315c:	0001d497          	auipc	s1,0x1d
    80003160:	a6c4b483          	ld	s1,-1428(s1) # 8001fbc8 <bcache+0x82b0>
    80003164:	0001d797          	auipc	a5,0x1d
    80003168:	a1c78793          	addi	a5,a5,-1508 # 8001fb80 <bcache+0x8268>
    8000316c:	00f48863          	beq	s1,a5,8000317c <bread+0x90>
    80003170:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003172:	40bc                	lw	a5,64(s1)
    80003174:	cf81                	beqz	a5,8000318c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003176:	64a4                	ld	s1,72(s1)
    80003178:	fee49de3          	bne	s1,a4,80003172 <bread+0x86>
  panic("bget: no buffers");
    8000317c:	00005517          	auipc	a0,0x5
    80003180:	39450513          	addi	a0,a0,916 # 80008510 <syscalls+0xc8>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	3a6080e7          	jalr	934(ra) # 8000052a <panic>
      b->dev = dev;
    8000318c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003190:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003194:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003198:	4785                	li	a5,1
    8000319a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000319c:	00014517          	auipc	a0,0x14
    800031a0:	77c50513          	addi	a0,a0,1916 # 80017918 <bcache>
    800031a4:	ffffe097          	auipc	ra,0xffffe
    800031a8:	ad2080e7          	jalr	-1326(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800031ac:	01048513          	addi	a0,s1,16
    800031b0:	00001097          	auipc	ra,0x1
    800031b4:	408080e7          	jalr	1032(ra) # 800045b8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031b8:	409c                	lw	a5,0(s1)
    800031ba:	cb89                	beqz	a5,800031cc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031bc:	8526                	mv	a0,s1
    800031be:	70a2                	ld	ra,40(sp)
    800031c0:	7402                	ld	s0,32(sp)
    800031c2:	64e2                	ld	s1,24(sp)
    800031c4:	6942                	ld	s2,16(sp)
    800031c6:	69a2                	ld	s3,8(sp)
    800031c8:	6145                	addi	sp,sp,48
    800031ca:	8082                	ret
    virtio_disk_rw(b, 0);
    800031cc:	4581                	li	a1,0
    800031ce:	8526                	mv	a0,s1
    800031d0:	00003097          	auipc	ra,0x3
    800031d4:	f16080e7          	jalr	-234(ra) # 800060e6 <virtio_disk_rw>
    b->valid = 1;
    800031d8:	4785                	li	a5,1
    800031da:	c09c                	sw	a5,0(s1)
  return b;
    800031dc:	b7c5                	j	800031bc <bread+0xd0>

00000000800031de <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031de:	1101                	addi	sp,sp,-32
    800031e0:	ec06                	sd	ra,24(sp)
    800031e2:	e822                	sd	s0,16(sp)
    800031e4:	e426                	sd	s1,8(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ea:	0541                	addi	a0,a0,16
    800031ec:	00001097          	auipc	ra,0x1
    800031f0:	466080e7          	jalr	1126(ra) # 80004652 <holdingsleep>
    800031f4:	cd01                	beqz	a0,8000320c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031f6:	4585                	li	a1,1
    800031f8:	8526                	mv	a0,s1
    800031fa:	00003097          	auipc	ra,0x3
    800031fe:	eec080e7          	jalr	-276(ra) # 800060e6 <virtio_disk_rw>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	64a2                	ld	s1,8(sp)
    80003208:	6105                	addi	sp,sp,32
    8000320a:	8082                	ret
    panic("bwrite");
    8000320c:	00005517          	auipc	a0,0x5
    80003210:	31c50513          	addi	a0,a0,796 # 80008528 <syscalls+0xe0>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	316080e7          	jalr	790(ra) # 8000052a <panic>

000000008000321c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000321c:	1101                	addi	sp,sp,-32
    8000321e:	ec06                	sd	ra,24(sp)
    80003220:	e822                	sd	s0,16(sp)
    80003222:	e426                	sd	s1,8(sp)
    80003224:	e04a                	sd	s2,0(sp)
    80003226:	1000                	addi	s0,sp,32
    80003228:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000322a:	01050913          	addi	s2,a0,16
    8000322e:	854a                	mv	a0,s2
    80003230:	00001097          	auipc	ra,0x1
    80003234:	422080e7          	jalr	1058(ra) # 80004652 <holdingsleep>
    80003238:	c92d                	beqz	a0,800032aa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000323a:	854a                	mv	a0,s2
    8000323c:	00001097          	auipc	ra,0x1
    80003240:	3d2080e7          	jalr	978(ra) # 8000460e <releasesleep>

  acquire(&bcache.lock);
    80003244:	00014517          	auipc	a0,0x14
    80003248:	6d450513          	addi	a0,a0,1748 # 80017918 <bcache>
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	976080e7          	jalr	-1674(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003254:	40bc                	lw	a5,64(s1)
    80003256:	37fd                	addiw	a5,a5,-1
    80003258:	0007871b          	sext.w	a4,a5
    8000325c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000325e:	eb05                	bnez	a4,8000328e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003260:	68bc                	ld	a5,80(s1)
    80003262:	64b8                	ld	a4,72(s1)
    80003264:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003266:	64bc                	ld	a5,72(s1)
    80003268:	68b8                	ld	a4,80(s1)
    8000326a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000326c:	0001c797          	auipc	a5,0x1c
    80003270:	6ac78793          	addi	a5,a5,1708 # 8001f918 <bcache+0x8000>
    80003274:	2b87b703          	ld	a4,696(a5)
    80003278:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000327a:	0001d717          	auipc	a4,0x1d
    8000327e:	90670713          	addi	a4,a4,-1786 # 8001fb80 <bcache+0x8268>
    80003282:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003284:	2b87b703          	ld	a4,696(a5)
    80003288:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000328a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000328e:	00014517          	auipc	a0,0x14
    80003292:	68a50513          	addi	a0,a0,1674 # 80017918 <bcache>
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	9e0080e7          	jalr	-1568(ra) # 80000c76 <release>
}
    8000329e:	60e2                	ld	ra,24(sp)
    800032a0:	6442                	ld	s0,16(sp)
    800032a2:	64a2                	ld	s1,8(sp)
    800032a4:	6902                	ld	s2,0(sp)
    800032a6:	6105                	addi	sp,sp,32
    800032a8:	8082                	ret
    panic("brelse");
    800032aa:	00005517          	auipc	a0,0x5
    800032ae:	28650513          	addi	a0,a0,646 # 80008530 <syscalls+0xe8>
    800032b2:	ffffd097          	auipc	ra,0xffffd
    800032b6:	278080e7          	jalr	632(ra) # 8000052a <panic>

00000000800032ba <bpin>:

void
bpin(struct buf *b) {
    800032ba:	1101                	addi	sp,sp,-32
    800032bc:	ec06                	sd	ra,24(sp)
    800032be:	e822                	sd	s0,16(sp)
    800032c0:	e426                	sd	s1,8(sp)
    800032c2:	1000                	addi	s0,sp,32
    800032c4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032c6:	00014517          	auipc	a0,0x14
    800032ca:	65250513          	addi	a0,a0,1618 # 80017918 <bcache>
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	8f4080e7          	jalr	-1804(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800032d6:	40bc                	lw	a5,64(s1)
    800032d8:	2785                	addiw	a5,a5,1
    800032da:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032dc:	00014517          	auipc	a0,0x14
    800032e0:	63c50513          	addi	a0,a0,1596 # 80017918 <bcache>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	992080e7          	jalr	-1646(ra) # 80000c76 <release>
}
    800032ec:	60e2                	ld	ra,24(sp)
    800032ee:	6442                	ld	s0,16(sp)
    800032f0:	64a2                	ld	s1,8(sp)
    800032f2:	6105                	addi	sp,sp,32
    800032f4:	8082                	ret

00000000800032f6 <bunpin>:

void
bunpin(struct buf *b) {
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	e426                	sd	s1,8(sp)
    800032fe:	1000                	addi	s0,sp,32
    80003300:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003302:	00014517          	auipc	a0,0x14
    80003306:	61650513          	addi	a0,a0,1558 # 80017918 <bcache>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	8b8080e7          	jalr	-1864(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003312:	40bc                	lw	a5,64(s1)
    80003314:	37fd                	addiw	a5,a5,-1
    80003316:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003318:	00014517          	auipc	a0,0x14
    8000331c:	60050513          	addi	a0,a0,1536 # 80017918 <bcache>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	956080e7          	jalr	-1706(ra) # 80000c76 <release>
}
    80003328:	60e2                	ld	ra,24(sp)
    8000332a:	6442                	ld	s0,16(sp)
    8000332c:	64a2                	ld	s1,8(sp)
    8000332e:	6105                	addi	sp,sp,32
    80003330:	8082                	ret

0000000080003332 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003332:	1101                	addi	sp,sp,-32
    80003334:	ec06                	sd	ra,24(sp)
    80003336:	e822                	sd	s0,16(sp)
    80003338:	e426                	sd	s1,8(sp)
    8000333a:	e04a                	sd	s2,0(sp)
    8000333c:	1000                	addi	s0,sp,32
    8000333e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003340:	00d5d59b          	srliw	a1,a1,0xd
    80003344:	0001d797          	auipc	a5,0x1d
    80003348:	cb07a783          	lw	a5,-848(a5) # 8001fff4 <sb+0x1c>
    8000334c:	9dbd                	addw	a1,a1,a5
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	d9e080e7          	jalr	-610(ra) # 800030ec <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003356:	0074f713          	andi	a4,s1,7
    8000335a:	4785                	li	a5,1
    8000335c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003360:	14ce                	slli	s1,s1,0x33
    80003362:	90d9                	srli	s1,s1,0x36
    80003364:	00950733          	add	a4,a0,s1
    80003368:	05874703          	lbu	a4,88(a4)
    8000336c:	00e7f6b3          	and	a3,a5,a4
    80003370:	c69d                	beqz	a3,8000339e <bfree+0x6c>
    80003372:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003374:	94aa                	add	s1,s1,a0
    80003376:	fff7c793          	not	a5,a5
    8000337a:	8ff9                	and	a5,a5,a4
    8000337c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003380:	00001097          	auipc	ra,0x1
    80003384:	118080e7          	jalr	280(ra) # 80004498 <log_write>
  brelse(bp);
    80003388:	854a                	mv	a0,s2
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	e92080e7          	jalr	-366(ra) # 8000321c <brelse>
}
    80003392:	60e2                	ld	ra,24(sp)
    80003394:	6442                	ld	s0,16(sp)
    80003396:	64a2                	ld	s1,8(sp)
    80003398:	6902                	ld	s2,0(sp)
    8000339a:	6105                	addi	sp,sp,32
    8000339c:	8082                	ret
    panic("freeing free block");
    8000339e:	00005517          	auipc	a0,0x5
    800033a2:	19a50513          	addi	a0,a0,410 # 80008538 <syscalls+0xf0>
    800033a6:	ffffd097          	auipc	ra,0xffffd
    800033aa:	184080e7          	jalr	388(ra) # 8000052a <panic>

00000000800033ae <balloc>:
{
    800033ae:	711d                	addi	sp,sp,-96
    800033b0:	ec86                	sd	ra,88(sp)
    800033b2:	e8a2                	sd	s0,80(sp)
    800033b4:	e4a6                	sd	s1,72(sp)
    800033b6:	e0ca                	sd	s2,64(sp)
    800033b8:	fc4e                	sd	s3,56(sp)
    800033ba:	f852                	sd	s4,48(sp)
    800033bc:	f456                	sd	s5,40(sp)
    800033be:	f05a                	sd	s6,32(sp)
    800033c0:	ec5e                	sd	s7,24(sp)
    800033c2:	e862                	sd	s8,16(sp)
    800033c4:	e466                	sd	s9,8(sp)
    800033c6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033c8:	0001d797          	auipc	a5,0x1d
    800033cc:	c147a783          	lw	a5,-1004(a5) # 8001ffdc <sb+0x4>
    800033d0:	cbd1                	beqz	a5,80003464 <balloc+0xb6>
    800033d2:	8baa                	mv	s7,a0
    800033d4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033d6:	0001db17          	auipc	s6,0x1d
    800033da:	c02b0b13          	addi	s6,s6,-1022 # 8001ffd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033de:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033e0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033e4:	6c89                	lui	s9,0x2
    800033e6:	a831                	j	80003402 <balloc+0x54>
    brelse(bp);
    800033e8:	854a                	mv	a0,s2
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	e32080e7          	jalr	-462(ra) # 8000321c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033f2:	015c87bb          	addw	a5,s9,s5
    800033f6:	00078a9b          	sext.w	s5,a5
    800033fa:	004b2703          	lw	a4,4(s6)
    800033fe:	06eaf363          	bgeu	s5,a4,80003464 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003402:	41fad79b          	sraiw	a5,s5,0x1f
    80003406:	0137d79b          	srliw	a5,a5,0x13
    8000340a:	015787bb          	addw	a5,a5,s5
    8000340e:	40d7d79b          	sraiw	a5,a5,0xd
    80003412:	01cb2583          	lw	a1,28(s6)
    80003416:	9dbd                	addw	a1,a1,a5
    80003418:	855e                	mv	a0,s7
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	cd2080e7          	jalr	-814(ra) # 800030ec <bread>
    80003422:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003424:	004b2503          	lw	a0,4(s6)
    80003428:	000a849b          	sext.w	s1,s5
    8000342c:	8662                	mv	a2,s8
    8000342e:	faa4fde3          	bgeu	s1,a0,800033e8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003432:	41f6579b          	sraiw	a5,a2,0x1f
    80003436:	01d7d69b          	srliw	a3,a5,0x1d
    8000343a:	00c6873b          	addw	a4,a3,a2
    8000343e:	00777793          	andi	a5,a4,7
    80003442:	9f95                	subw	a5,a5,a3
    80003444:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003448:	4037571b          	sraiw	a4,a4,0x3
    8000344c:	00e906b3          	add	a3,s2,a4
    80003450:	0586c683          	lbu	a3,88(a3)
    80003454:	00d7f5b3          	and	a1,a5,a3
    80003458:	cd91                	beqz	a1,80003474 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345a:	2605                	addiw	a2,a2,1
    8000345c:	2485                	addiw	s1,s1,1
    8000345e:	fd4618e3          	bne	a2,s4,8000342e <balloc+0x80>
    80003462:	b759                	j	800033e8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003464:	00005517          	auipc	a0,0x5
    80003468:	0ec50513          	addi	a0,a0,236 # 80008550 <syscalls+0x108>
    8000346c:	ffffd097          	auipc	ra,0xffffd
    80003470:	0be080e7          	jalr	190(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003474:	974a                	add	a4,a4,s2
    80003476:	8fd5                	or	a5,a5,a3
    80003478:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000347c:	854a                	mv	a0,s2
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	01a080e7          	jalr	26(ra) # 80004498 <log_write>
        brelse(bp);
    80003486:	854a                	mv	a0,s2
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	d94080e7          	jalr	-620(ra) # 8000321c <brelse>
  bp = bread(dev, bno);
    80003490:	85a6                	mv	a1,s1
    80003492:	855e                	mv	a0,s7
    80003494:	00000097          	auipc	ra,0x0
    80003498:	c58080e7          	jalr	-936(ra) # 800030ec <bread>
    8000349c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000349e:	40000613          	li	a2,1024
    800034a2:	4581                	li	a1,0
    800034a4:	05850513          	addi	a0,a0,88
    800034a8:	ffffe097          	auipc	ra,0xffffe
    800034ac:	816080e7          	jalr	-2026(ra) # 80000cbe <memset>
  log_write(bp);
    800034b0:	854a                	mv	a0,s2
    800034b2:	00001097          	auipc	ra,0x1
    800034b6:	fe6080e7          	jalr	-26(ra) # 80004498 <log_write>
  brelse(bp);
    800034ba:	854a                	mv	a0,s2
    800034bc:	00000097          	auipc	ra,0x0
    800034c0:	d60080e7          	jalr	-672(ra) # 8000321c <brelse>
}
    800034c4:	8526                	mv	a0,s1
    800034c6:	60e6                	ld	ra,88(sp)
    800034c8:	6446                	ld	s0,80(sp)
    800034ca:	64a6                	ld	s1,72(sp)
    800034cc:	6906                	ld	s2,64(sp)
    800034ce:	79e2                	ld	s3,56(sp)
    800034d0:	7a42                	ld	s4,48(sp)
    800034d2:	7aa2                	ld	s5,40(sp)
    800034d4:	7b02                	ld	s6,32(sp)
    800034d6:	6be2                	ld	s7,24(sp)
    800034d8:	6c42                	ld	s8,16(sp)
    800034da:	6ca2                	ld	s9,8(sp)
    800034dc:	6125                	addi	sp,sp,96
    800034de:	8082                	ret

00000000800034e0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034e0:	7179                	addi	sp,sp,-48
    800034e2:	f406                	sd	ra,40(sp)
    800034e4:	f022                	sd	s0,32(sp)
    800034e6:	ec26                	sd	s1,24(sp)
    800034e8:	e84a                	sd	s2,16(sp)
    800034ea:	e44e                	sd	s3,8(sp)
    800034ec:	e052                	sd	s4,0(sp)
    800034ee:	1800                	addi	s0,sp,48
    800034f0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034f2:	47ad                	li	a5,11
    800034f4:	04b7fe63          	bgeu	a5,a1,80003550 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034f8:	ff45849b          	addiw	s1,a1,-12
    800034fc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003500:	0ff00793          	li	a5,255
    80003504:	0ae7e363          	bltu	a5,a4,800035aa <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003508:	08052583          	lw	a1,128(a0)
    8000350c:	c5ad                	beqz	a1,80003576 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000350e:	00092503          	lw	a0,0(s2)
    80003512:	00000097          	auipc	ra,0x0
    80003516:	bda080e7          	jalr	-1062(ra) # 800030ec <bread>
    8000351a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000351c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003520:	02049593          	slli	a1,s1,0x20
    80003524:	9181                	srli	a1,a1,0x20
    80003526:	058a                	slli	a1,a1,0x2
    80003528:	00b784b3          	add	s1,a5,a1
    8000352c:	0004a983          	lw	s3,0(s1)
    80003530:	04098d63          	beqz	s3,8000358a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003534:	8552                	mv	a0,s4
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	ce6080e7          	jalr	-794(ra) # 8000321c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000353e:	854e                	mv	a0,s3
    80003540:	70a2                	ld	ra,40(sp)
    80003542:	7402                	ld	s0,32(sp)
    80003544:	64e2                	ld	s1,24(sp)
    80003546:	6942                	ld	s2,16(sp)
    80003548:	69a2                	ld	s3,8(sp)
    8000354a:	6a02                	ld	s4,0(sp)
    8000354c:	6145                	addi	sp,sp,48
    8000354e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003550:	02059493          	slli	s1,a1,0x20
    80003554:	9081                	srli	s1,s1,0x20
    80003556:	048a                	slli	s1,s1,0x2
    80003558:	94aa                	add	s1,s1,a0
    8000355a:	0504a983          	lw	s3,80(s1)
    8000355e:	fe0990e3          	bnez	s3,8000353e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003562:	4108                	lw	a0,0(a0)
    80003564:	00000097          	auipc	ra,0x0
    80003568:	e4a080e7          	jalr	-438(ra) # 800033ae <balloc>
    8000356c:	0005099b          	sext.w	s3,a0
    80003570:	0534a823          	sw	s3,80(s1)
    80003574:	b7e9                	j	8000353e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003576:	4108                	lw	a0,0(a0)
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	e36080e7          	jalr	-458(ra) # 800033ae <balloc>
    80003580:	0005059b          	sext.w	a1,a0
    80003584:	08b92023          	sw	a1,128(s2)
    80003588:	b759                	j	8000350e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000358a:	00092503          	lw	a0,0(s2)
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	e20080e7          	jalr	-480(ra) # 800033ae <balloc>
    80003596:	0005099b          	sext.w	s3,a0
    8000359a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000359e:	8552                	mv	a0,s4
    800035a0:	00001097          	auipc	ra,0x1
    800035a4:	ef8080e7          	jalr	-264(ra) # 80004498 <log_write>
    800035a8:	b771                	j	80003534 <bmap+0x54>
  panic("bmap: out of range");
    800035aa:	00005517          	auipc	a0,0x5
    800035ae:	fbe50513          	addi	a0,a0,-66 # 80008568 <syscalls+0x120>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	f78080e7          	jalr	-136(ra) # 8000052a <panic>

00000000800035ba <iget>:
{
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	e052                	sd	s4,0(sp)
    800035c8:	1800                	addi	s0,sp,48
    800035ca:	89aa                	mv	s3,a0
    800035cc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035ce:	0001d517          	auipc	a0,0x1d
    800035d2:	a2a50513          	addi	a0,a0,-1494 # 8001fff8 <itable>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	5ec080e7          	jalr	1516(ra) # 80000bc2 <acquire>
  empty = 0;
    800035de:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035e0:	0001d497          	auipc	s1,0x1d
    800035e4:	a3048493          	addi	s1,s1,-1488 # 80020010 <itable+0x18>
    800035e8:	0001e697          	auipc	a3,0x1e
    800035ec:	4b868693          	addi	a3,a3,1208 # 80021aa0 <log>
    800035f0:	a039                	j	800035fe <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035f2:	02090b63          	beqz	s2,80003628 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035f6:	08848493          	addi	s1,s1,136
    800035fa:	02d48a63          	beq	s1,a3,8000362e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035fe:	449c                	lw	a5,8(s1)
    80003600:	fef059e3          	blez	a5,800035f2 <iget+0x38>
    80003604:	4098                	lw	a4,0(s1)
    80003606:	ff3716e3          	bne	a4,s3,800035f2 <iget+0x38>
    8000360a:	40d8                	lw	a4,4(s1)
    8000360c:	ff4713e3          	bne	a4,s4,800035f2 <iget+0x38>
      ip->ref++;
    80003610:	2785                	addiw	a5,a5,1
    80003612:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003614:	0001d517          	auipc	a0,0x1d
    80003618:	9e450513          	addi	a0,a0,-1564 # 8001fff8 <itable>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	65a080e7          	jalr	1626(ra) # 80000c76 <release>
      return ip;
    80003624:	8926                	mv	s2,s1
    80003626:	a03d                	j	80003654 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003628:	f7f9                	bnez	a5,800035f6 <iget+0x3c>
    8000362a:	8926                	mv	s2,s1
    8000362c:	b7e9                	j	800035f6 <iget+0x3c>
  if(empty == 0)
    8000362e:	02090c63          	beqz	s2,80003666 <iget+0xac>
  ip->dev = dev;
    80003632:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003636:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000363a:	4785                	li	a5,1
    8000363c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003640:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003644:	0001d517          	auipc	a0,0x1d
    80003648:	9b450513          	addi	a0,a0,-1612 # 8001fff8 <itable>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	62a080e7          	jalr	1578(ra) # 80000c76 <release>
}
    80003654:	854a                	mv	a0,s2
    80003656:	70a2                	ld	ra,40(sp)
    80003658:	7402                	ld	s0,32(sp)
    8000365a:	64e2                	ld	s1,24(sp)
    8000365c:	6942                	ld	s2,16(sp)
    8000365e:	69a2                	ld	s3,8(sp)
    80003660:	6a02                	ld	s4,0(sp)
    80003662:	6145                	addi	sp,sp,48
    80003664:	8082                	ret
    panic("iget: no inodes");
    80003666:	00005517          	auipc	a0,0x5
    8000366a:	f1a50513          	addi	a0,a0,-230 # 80008580 <syscalls+0x138>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	ebc080e7          	jalr	-324(ra) # 8000052a <panic>

0000000080003676 <fsinit>:
fsinit(int dev) {
    80003676:	7179                	addi	sp,sp,-48
    80003678:	f406                	sd	ra,40(sp)
    8000367a:	f022                	sd	s0,32(sp)
    8000367c:	ec26                	sd	s1,24(sp)
    8000367e:	e84a                	sd	s2,16(sp)
    80003680:	e44e                	sd	s3,8(sp)
    80003682:	1800                	addi	s0,sp,48
    80003684:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003686:	4585                	li	a1,1
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	a64080e7          	jalr	-1436(ra) # 800030ec <bread>
    80003690:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003692:	0001d997          	auipc	s3,0x1d
    80003696:	94698993          	addi	s3,s3,-1722 # 8001ffd8 <sb>
    8000369a:	02000613          	li	a2,32
    8000369e:	05850593          	addi	a1,a0,88
    800036a2:	854e                	mv	a0,s3
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	676080e7          	jalr	1654(ra) # 80000d1a <memmove>
  brelse(bp);
    800036ac:	8526                	mv	a0,s1
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	b6e080e7          	jalr	-1170(ra) # 8000321c <brelse>
  if(sb.magic != FSMAGIC)
    800036b6:	0009a703          	lw	a4,0(s3)
    800036ba:	102037b7          	lui	a5,0x10203
    800036be:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036c2:	02f71263          	bne	a4,a5,800036e6 <fsinit+0x70>
  initlog(dev, &sb);
    800036c6:	0001d597          	auipc	a1,0x1d
    800036ca:	91258593          	addi	a1,a1,-1774 # 8001ffd8 <sb>
    800036ce:	854a                	mv	a0,s2
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	b4c080e7          	jalr	-1204(ra) # 8000421c <initlog>
}
    800036d8:	70a2                	ld	ra,40(sp)
    800036da:	7402                	ld	s0,32(sp)
    800036dc:	64e2                	ld	s1,24(sp)
    800036de:	6942                	ld	s2,16(sp)
    800036e0:	69a2                	ld	s3,8(sp)
    800036e2:	6145                	addi	sp,sp,48
    800036e4:	8082                	ret
    panic("invalid file system");
    800036e6:	00005517          	auipc	a0,0x5
    800036ea:	eaa50513          	addi	a0,a0,-342 # 80008590 <syscalls+0x148>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	e3c080e7          	jalr	-452(ra) # 8000052a <panic>

00000000800036f6 <iinit>:
{
    800036f6:	7179                	addi	sp,sp,-48
    800036f8:	f406                	sd	ra,40(sp)
    800036fa:	f022                	sd	s0,32(sp)
    800036fc:	ec26                	sd	s1,24(sp)
    800036fe:	e84a                	sd	s2,16(sp)
    80003700:	e44e                	sd	s3,8(sp)
    80003702:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003704:	00005597          	auipc	a1,0x5
    80003708:	ea458593          	addi	a1,a1,-348 # 800085a8 <syscalls+0x160>
    8000370c:	0001d517          	auipc	a0,0x1d
    80003710:	8ec50513          	addi	a0,a0,-1812 # 8001fff8 <itable>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	41e080e7          	jalr	1054(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000371c:	0001d497          	auipc	s1,0x1d
    80003720:	90448493          	addi	s1,s1,-1788 # 80020020 <itable+0x28>
    80003724:	0001e997          	auipc	s3,0x1e
    80003728:	38c98993          	addi	s3,s3,908 # 80021ab0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000372c:	00005917          	auipc	s2,0x5
    80003730:	e8490913          	addi	s2,s2,-380 # 800085b0 <syscalls+0x168>
    80003734:	85ca                	mv	a1,s2
    80003736:	8526                	mv	a0,s1
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	e46080e7          	jalr	-442(ra) # 8000457e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003740:	08848493          	addi	s1,s1,136
    80003744:	ff3498e3          	bne	s1,s3,80003734 <iinit+0x3e>
}
    80003748:	70a2                	ld	ra,40(sp)
    8000374a:	7402                	ld	s0,32(sp)
    8000374c:	64e2                	ld	s1,24(sp)
    8000374e:	6942                	ld	s2,16(sp)
    80003750:	69a2                	ld	s3,8(sp)
    80003752:	6145                	addi	sp,sp,48
    80003754:	8082                	ret

0000000080003756 <ialloc>:
{
    80003756:	715d                	addi	sp,sp,-80
    80003758:	e486                	sd	ra,72(sp)
    8000375a:	e0a2                	sd	s0,64(sp)
    8000375c:	fc26                	sd	s1,56(sp)
    8000375e:	f84a                	sd	s2,48(sp)
    80003760:	f44e                	sd	s3,40(sp)
    80003762:	f052                	sd	s4,32(sp)
    80003764:	ec56                	sd	s5,24(sp)
    80003766:	e85a                	sd	s6,16(sp)
    80003768:	e45e                	sd	s7,8(sp)
    8000376a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000376c:	0001d717          	auipc	a4,0x1d
    80003770:	87872703          	lw	a4,-1928(a4) # 8001ffe4 <sb+0xc>
    80003774:	4785                	li	a5,1
    80003776:	04e7fa63          	bgeu	a5,a4,800037ca <ialloc+0x74>
    8000377a:	8aaa                	mv	s5,a0
    8000377c:	8bae                	mv	s7,a1
    8000377e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003780:	0001da17          	auipc	s4,0x1d
    80003784:	858a0a13          	addi	s4,s4,-1960 # 8001ffd8 <sb>
    80003788:	00048b1b          	sext.w	s6,s1
    8000378c:	0044d793          	srli	a5,s1,0x4
    80003790:	018a2583          	lw	a1,24(s4)
    80003794:	9dbd                	addw	a1,a1,a5
    80003796:	8556                	mv	a0,s5
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	954080e7          	jalr	-1708(ra) # 800030ec <bread>
    800037a0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037a2:	05850993          	addi	s3,a0,88
    800037a6:	00f4f793          	andi	a5,s1,15
    800037aa:	079a                	slli	a5,a5,0x6
    800037ac:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037ae:	00099783          	lh	a5,0(s3)
    800037b2:	c785                	beqz	a5,800037da <ialloc+0x84>
    brelse(bp);
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	a68080e7          	jalr	-1432(ra) # 8000321c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037bc:	0485                	addi	s1,s1,1
    800037be:	00ca2703          	lw	a4,12(s4)
    800037c2:	0004879b          	sext.w	a5,s1
    800037c6:	fce7e1e3          	bltu	a5,a4,80003788 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	dee50513          	addi	a0,a0,-530 # 800085b8 <syscalls+0x170>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d58080e7          	jalr	-680(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800037da:	04000613          	li	a2,64
    800037de:	4581                	li	a1,0
    800037e0:	854e                	mv	a0,s3
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	4dc080e7          	jalr	1244(ra) # 80000cbe <memset>
      dip->type = type;
    800037ea:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037ee:	854a                	mv	a0,s2
    800037f0:	00001097          	auipc	ra,0x1
    800037f4:	ca8080e7          	jalr	-856(ra) # 80004498 <log_write>
      brelse(bp);
    800037f8:	854a                	mv	a0,s2
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	a22080e7          	jalr	-1502(ra) # 8000321c <brelse>
      return iget(dev, inum);
    80003802:	85da                	mv	a1,s6
    80003804:	8556                	mv	a0,s5
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	db4080e7          	jalr	-588(ra) # 800035ba <iget>
}
    8000380e:	60a6                	ld	ra,72(sp)
    80003810:	6406                	ld	s0,64(sp)
    80003812:	74e2                	ld	s1,56(sp)
    80003814:	7942                	ld	s2,48(sp)
    80003816:	79a2                	ld	s3,40(sp)
    80003818:	7a02                	ld	s4,32(sp)
    8000381a:	6ae2                	ld	s5,24(sp)
    8000381c:	6b42                	ld	s6,16(sp)
    8000381e:	6ba2                	ld	s7,8(sp)
    80003820:	6161                	addi	sp,sp,80
    80003822:	8082                	ret

0000000080003824 <iupdate>:
{
    80003824:	1101                	addi	sp,sp,-32
    80003826:	ec06                	sd	ra,24(sp)
    80003828:	e822                	sd	s0,16(sp)
    8000382a:	e426                	sd	s1,8(sp)
    8000382c:	e04a                	sd	s2,0(sp)
    8000382e:	1000                	addi	s0,sp,32
    80003830:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003832:	415c                	lw	a5,4(a0)
    80003834:	0047d79b          	srliw	a5,a5,0x4
    80003838:	0001c597          	auipc	a1,0x1c
    8000383c:	7b85a583          	lw	a1,1976(a1) # 8001fff0 <sb+0x18>
    80003840:	9dbd                	addw	a1,a1,a5
    80003842:	4108                	lw	a0,0(a0)
    80003844:	00000097          	auipc	ra,0x0
    80003848:	8a8080e7          	jalr	-1880(ra) # 800030ec <bread>
    8000384c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000384e:	05850793          	addi	a5,a0,88
    80003852:	40c8                	lw	a0,4(s1)
    80003854:	893d                	andi	a0,a0,15
    80003856:	051a                	slli	a0,a0,0x6
    80003858:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000385a:	04449703          	lh	a4,68(s1)
    8000385e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003862:	04649703          	lh	a4,70(s1)
    80003866:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000386a:	04849703          	lh	a4,72(s1)
    8000386e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003872:	04a49703          	lh	a4,74(s1)
    80003876:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000387a:	44f8                	lw	a4,76(s1)
    8000387c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000387e:	03400613          	li	a2,52
    80003882:	05048593          	addi	a1,s1,80
    80003886:	0531                	addi	a0,a0,12
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	492080e7          	jalr	1170(ra) # 80000d1a <memmove>
  log_write(bp);
    80003890:	854a                	mv	a0,s2
    80003892:	00001097          	auipc	ra,0x1
    80003896:	c06080e7          	jalr	-1018(ra) # 80004498 <log_write>
  brelse(bp);
    8000389a:	854a                	mv	a0,s2
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	980080e7          	jalr	-1664(ra) # 8000321c <brelse>
}
    800038a4:	60e2                	ld	ra,24(sp)
    800038a6:	6442                	ld	s0,16(sp)
    800038a8:	64a2                	ld	s1,8(sp)
    800038aa:	6902                	ld	s2,0(sp)
    800038ac:	6105                	addi	sp,sp,32
    800038ae:	8082                	ret

00000000800038b0 <idup>:
{
    800038b0:	1101                	addi	sp,sp,-32
    800038b2:	ec06                	sd	ra,24(sp)
    800038b4:	e822                	sd	s0,16(sp)
    800038b6:	e426                	sd	s1,8(sp)
    800038b8:	1000                	addi	s0,sp,32
    800038ba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038bc:	0001c517          	auipc	a0,0x1c
    800038c0:	73c50513          	addi	a0,a0,1852 # 8001fff8 <itable>
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	2fe080e7          	jalr	766(ra) # 80000bc2 <acquire>
  ip->ref++;
    800038cc:	449c                	lw	a5,8(s1)
    800038ce:	2785                	addiw	a5,a5,1
    800038d0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038d2:	0001c517          	auipc	a0,0x1c
    800038d6:	72650513          	addi	a0,a0,1830 # 8001fff8 <itable>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	39c080e7          	jalr	924(ra) # 80000c76 <release>
}
    800038e2:	8526                	mv	a0,s1
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6105                	addi	sp,sp,32
    800038ec:	8082                	ret

00000000800038ee <ilock>:
{
    800038ee:	1101                	addi	sp,sp,-32
    800038f0:	ec06                	sd	ra,24(sp)
    800038f2:	e822                	sd	s0,16(sp)
    800038f4:	e426                	sd	s1,8(sp)
    800038f6:	e04a                	sd	s2,0(sp)
    800038f8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038fa:	c115                	beqz	a0,8000391e <ilock+0x30>
    800038fc:	84aa                	mv	s1,a0
    800038fe:	451c                	lw	a5,8(a0)
    80003900:	00f05f63          	blez	a5,8000391e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003904:	0541                	addi	a0,a0,16
    80003906:	00001097          	auipc	ra,0x1
    8000390a:	cb2080e7          	jalr	-846(ra) # 800045b8 <acquiresleep>
  if(ip->valid == 0){
    8000390e:	40bc                	lw	a5,64(s1)
    80003910:	cf99                	beqz	a5,8000392e <ilock+0x40>
}
    80003912:	60e2                	ld	ra,24(sp)
    80003914:	6442                	ld	s0,16(sp)
    80003916:	64a2                	ld	s1,8(sp)
    80003918:	6902                	ld	s2,0(sp)
    8000391a:	6105                	addi	sp,sp,32
    8000391c:	8082                	ret
    panic("ilock");
    8000391e:	00005517          	auipc	a0,0x5
    80003922:	cb250513          	addi	a0,a0,-846 # 800085d0 <syscalls+0x188>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	c04080e7          	jalr	-1020(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000392e:	40dc                	lw	a5,4(s1)
    80003930:	0047d79b          	srliw	a5,a5,0x4
    80003934:	0001c597          	auipc	a1,0x1c
    80003938:	6bc5a583          	lw	a1,1724(a1) # 8001fff0 <sb+0x18>
    8000393c:	9dbd                	addw	a1,a1,a5
    8000393e:	4088                	lw	a0,0(s1)
    80003940:	fffff097          	auipc	ra,0xfffff
    80003944:	7ac080e7          	jalr	1964(ra) # 800030ec <bread>
    80003948:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000394a:	05850593          	addi	a1,a0,88
    8000394e:	40dc                	lw	a5,4(s1)
    80003950:	8bbd                	andi	a5,a5,15
    80003952:	079a                	slli	a5,a5,0x6
    80003954:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003956:	00059783          	lh	a5,0(a1)
    8000395a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000395e:	00259783          	lh	a5,2(a1)
    80003962:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003966:	00459783          	lh	a5,4(a1)
    8000396a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000396e:	00659783          	lh	a5,6(a1)
    80003972:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003976:	459c                	lw	a5,8(a1)
    80003978:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000397a:	03400613          	li	a2,52
    8000397e:	05b1                	addi	a1,a1,12
    80003980:	05048513          	addi	a0,s1,80
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	396080e7          	jalr	918(ra) # 80000d1a <memmove>
    brelse(bp);
    8000398c:	854a                	mv	a0,s2
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	88e080e7          	jalr	-1906(ra) # 8000321c <brelse>
    ip->valid = 1;
    80003996:	4785                	li	a5,1
    80003998:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000399a:	04449783          	lh	a5,68(s1)
    8000399e:	fbb5                	bnez	a5,80003912 <ilock+0x24>
      panic("ilock: no type");
    800039a0:	00005517          	auipc	a0,0x5
    800039a4:	c3850513          	addi	a0,a0,-968 # 800085d8 <syscalls+0x190>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	b82080e7          	jalr	-1150(ra) # 8000052a <panic>

00000000800039b0 <iunlock>:
{
    800039b0:	1101                	addi	sp,sp,-32
    800039b2:	ec06                	sd	ra,24(sp)
    800039b4:	e822                	sd	s0,16(sp)
    800039b6:	e426                	sd	s1,8(sp)
    800039b8:	e04a                	sd	s2,0(sp)
    800039ba:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039bc:	c905                	beqz	a0,800039ec <iunlock+0x3c>
    800039be:	84aa                	mv	s1,a0
    800039c0:	01050913          	addi	s2,a0,16
    800039c4:	854a                	mv	a0,s2
    800039c6:	00001097          	auipc	ra,0x1
    800039ca:	c8c080e7          	jalr	-884(ra) # 80004652 <holdingsleep>
    800039ce:	cd19                	beqz	a0,800039ec <iunlock+0x3c>
    800039d0:	449c                	lw	a5,8(s1)
    800039d2:	00f05d63          	blez	a5,800039ec <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039d6:	854a                	mv	a0,s2
    800039d8:	00001097          	auipc	ra,0x1
    800039dc:	c36080e7          	jalr	-970(ra) # 8000460e <releasesleep>
}
    800039e0:	60e2                	ld	ra,24(sp)
    800039e2:	6442                	ld	s0,16(sp)
    800039e4:	64a2                	ld	s1,8(sp)
    800039e6:	6902                	ld	s2,0(sp)
    800039e8:	6105                	addi	sp,sp,32
    800039ea:	8082                	ret
    panic("iunlock");
    800039ec:	00005517          	auipc	a0,0x5
    800039f0:	bfc50513          	addi	a0,a0,-1028 # 800085e8 <syscalls+0x1a0>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	b36080e7          	jalr	-1226(ra) # 8000052a <panic>

00000000800039fc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039fc:	7179                	addi	sp,sp,-48
    800039fe:	f406                	sd	ra,40(sp)
    80003a00:	f022                	sd	s0,32(sp)
    80003a02:	ec26                	sd	s1,24(sp)
    80003a04:	e84a                	sd	s2,16(sp)
    80003a06:	e44e                	sd	s3,8(sp)
    80003a08:	e052                	sd	s4,0(sp)
    80003a0a:	1800                	addi	s0,sp,48
    80003a0c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a0e:	05050493          	addi	s1,a0,80
    80003a12:	08050913          	addi	s2,a0,128
    80003a16:	a021                	j	80003a1e <itrunc+0x22>
    80003a18:	0491                	addi	s1,s1,4
    80003a1a:	01248d63          	beq	s1,s2,80003a34 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a1e:	408c                	lw	a1,0(s1)
    80003a20:	dde5                	beqz	a1,80003a18 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a22:	0009a503          	lw	a0,0(s3)
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	90c080e7          	jalr	-1780(ra) # 80003332 <bfree>
      ip->addrs[i] = 0;
    80003a2e:	0004a023          	sw	zero,0(s1)
    80003a32:	b7dd                	j	80003a18 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a34:	0809a583          	lw	a1,128(s3)
    80003a38:	e185                	bnez	a1,80003a58 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a3a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a3e:	854e                	mv	a0,s3
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	de4080e7          	jalr	-540(ra) # 80003824 <iupdate>
}
    80003a48:	70a2                	ld	ra,40(sp)
    80003a4a:	7402                	ld	s0,32(sp)
    80003a4c:	64e2                	ld	s1,24(sp)
    80003a4e:	6942                	ld	s2,16(sp)
    80003a50:	69a2                	ld	s3,8(sp)
    80003a52:	6a02                	ld	s4,0(sp)
    80003a54:	6145                	addi	sp,sp,48
    80003a56:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a58:	0009a503          	lw	a0,0(s3)
    80003a5c:	fffff097          	auipc	ra,0xfffff
    80003a60:	690080e7          	jalr	1680(ra) # 800030ec <bread>
    80003a64:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a66:	05850493          	addi	s1,a0,88
    80003a6a:	45850913          	addi	s2,a0,1112
    80003a6e:	a021                	j	80003a76 <itrunc+0x7a>
    80003a70:	0491                	addi	s1,s1,4
    80003a72:	01248b63          	beq	s1,s2,80003a88 <itrunc+0x8c>
      if(a[j])
    80003a76:	408c                	lw	a1,0(s1)
    80003a78:	dde5                	beqz	a1,80003a70 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a7a:	0009a503          	lw	a0,0(s3)
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	8b4080e7          	jalr	-1868(ra) # 80003332 <bfree>
    80003a86:	b7ed                	j	80003a70 <itrunc+0x74>
    brelse(bp);
    80003a88:	8552                	mv	a0,s4
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	792080e7          	jalr	1938(ra) # 8000321c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a92:	0809a583          	lw	a1,128(s3)
    80003a96:	0009a503          	lw	a0,0(s3)
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	898080e7          	jalr	-1896(ra) # 80003332 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003aa2:	0809a023          	sw	zero,128(s3)
    80003aa6:	bf51                	j	80003a3a <itrunc+0x3e>

0000000080003aa8 <iput>:
{
    80003aa8:	1101                	addi	sp,sp,-32
    80003aaa:	ec06                	sd	ra,24(sp)
    80003aac:	e822                	sd	s0,16(sp)
    80003aae:	e426                	sd	s1,8(sp)
    80003ab0:	e04a                	sd	s2,0(sp)
    80003ab2:	1000                	addi	s0,sp,32
    80003ab4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ab6:	0001c517          	auipc	a0,0x1c
    80003aba:	54250513          	addi	a0,a0,1346 # 8001fff8 <itable>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	104080e7          	jalr	260(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ac6:	4498                	lw	a4,8(s1)
    80003ac8:	4785                	li	a5,1
    80003aca:	02f70363          	beq	a4,a5,80003af0 <iput+0x48>
  ip->ref--;
    80003ace:	449c                	lw	a5,8(s1)
    80003ad0:	37fd                	addiw	a5,a5,-1
    80003ad2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ad4:	0001c517          	auipc	a0,0x1c
    80003ad8:	52450513          	addi	a0,a0,1316 # 8001fff8 <itable>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	19a080e7          	jalr	410(ra) # 80000c76 <release>
}
    80003ae4:	60e2                	ld	ra,24(sp)
    80003ae6:	6442                	ld	s0,16(sp)
    80003ae8:	64a2                	ld	s1,8(sp)
    80003aea:	6902                	ld	s2,0(sp)
    80003aec:	6105                	addi	sp,sp,32
    80003aee:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003af0:	40bc                	lw	a5,64(s1)
    80003af2:	dff1                	beqz	a5,80003ace <iput+0x26>
    80003af4:	04a49783          	lh	a5,74(s1)
    80003af8:	fbf9                	bnez	a5,80003ace <iput+0x26>
    acquiresleep(&ip->lock);
    80003afa:	01048913          	addi	s2,s1,16
    80003afe:	854a                	mv	a0,s2
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	ab8080e7          	jalr	-1352(ra) # 800045b8 <acquiresleep>
    release(&itable.lock);
    80003b08:	0001c517          	auipc	a0,0x1c
    80003b0c:	4f050513          	addi	a0,a0,1264 # 8001fff8 <itable>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	166080e7          	jalr	358(ra) # 80000c76 <release>
    itrunc(ip);
    80003b18:	8526                	mv	a0,s1
    80003b1a:	00000097          	auipc	ra,0x0
    80003b1e:	ee2080e7          	jalr	-286(ra) # 800039fc <itrunc>
    ip->type = 0;
    80003b22:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b26:	8526                	mv	a0,s1
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	cfc080e7          	jalr	-772(ra) # 80003824 <iupdate>
    ip->valid = 0;
    80003b30:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00001097          	auipc	ra,0x1
    80003b3a:	ad8080e7          	jalr	-1320(ra) # 8000460e <releasesleep>
    acquire(&itable.lock);
    80003b3e:	0001c517          	auipc	a0,0x1c
    80003b42:	4ba50513          	addi	a0,a0,1210 # 8001fff8 <itable>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	07c080e7          	jalr	124(ra) # 80000bc2 <acquire>
    80003b4e:	b741                	j	80003ace <iput+0x26>

0000000080003b50 <iunlockput>:
{
    80003b50:	1101                	addi	sp,sp,-32
    80003b52:	ec06                	sd	ra,24(sp)
    80003b54:	e822                	sd	s0,16(sp)
    80003b56:	e426                	sd	s1,8(sp)
    80003b58:	1000                	addi	s0,sp,32
    80003b5a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	e54080e7          	jalr	-428(ra) # 800039b0 <iunlock>
  iput(ip);
    80003b64:	8526                	mv	a0,s1
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	f42080e7          	jalr	-190(ra) # 80003aa8 <iput>
}
    80003b6e:	60e2                	ld	ra,24(sp)
    80003b70:	6442                	ld	s0,16(sp)
    80003b72:	64a2                	ld	s1,8(sp)
    80003b74:	6105                	addi	sp,sp,32
    80003b76:	8082                	ret

0000000080003b78 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b78:	1141                	addi	sp,sp,-16
    80003b7a:	e422                	sd	s0,8(sp)
    80003b7c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b7e:	411c                	lw	a5,0(a0)
    80003b80:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b82:	415c                	lw	a5,4(a0)
    80003b84:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b86:	04451783          	lh	a5,68(a0)
    80003b8a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b8e:	04a51783          	lh	a5,74(a0)
    80003b92:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b96:	04c56783          	lwu	a5,76(a0)
    80003b9a:	e99c                	sd	a5,16(a1)
}
    80003b9c:	6422                	ld	s0,8(sp)
    80003b9e:	0141                	addi	sp,sp,16
    80003ba0:	8082                	ret

0000000080003ba2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ba2:	457c                	lw	a5,76(a0)
    80003ba4:	0ed7e963          	bltu	a5,a3,80003c96 <readi+0xf4>
{
    80003ba8:	7159                	addi	sp,sp,-112
    80003baa:	f486                	sd	ra,104(sp)
    80003bac:	f0a2                	sd	s0,96(sp)
    80003bae:	eca6                	sd	s1,88(sp)
    80003bb0:	e8ca                	sd	s2,80(sp)
    80003bb2:	e4ce                	sd	s3,72(sp)
    80003bb4:	e0d2                	sd	s4,64(sp)
    80003bb6:	fc56                	sd	s5,56(sp)
    80003bb8:	f85a                	sd	s6,48(sp)
    80003bba:	f45e                	sd	s7,40(sp)
    80003bbc:	f062                	sd	s8,32(sp)
    80003bbe:	ec66                	sd	s9,24(sp)
    80003bc0:	e86a                	sd	s10,16(sp)
    80003bc2:	e46e                	sd	s11,8(sp)
    80003bc4:	1880                	addi	s0,sp,112
    80003bc6:	8baa                	mv	s7,a0
    80003bc8:	8c2e                	mv	s8,a1
    80003bca:	8ab2                	mv	s5,a2
    80003bcc:	84b6                	mv	s1,a3
    80003bce:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bd0:	9f35                	addw	a4,a4,a3
    return 0;
    80003bd2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bd4:	0ad76063          	bltu	a4,a3,80003c74 <readi+0xd2>
  if(off + n > ip->size)
    80003bd8:	00e7f463          	bgeu	a5,a4,80003be0 <readi+0x3e>
    n = ip->size - off;
    80003bdc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be0:	0a0b0963          	beqz	s6,80003c92 <readi+0xf0>
    80003be4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bea:	5cfd                	li	s9,-1
    80003bec:	a82d                	j	80003c26 <readi+0x84>
    80003bee:	020a1d93          	slli	s11,s4,0x20
    80003bf2:	020ddd93          	srli	s11,s11,0x20
    80003bf6:	05890793          	addi	a5,s2,88
    80003bfa:	86ee                	mv	a3,s11
    80003bfc:	963e                	add	a2,a2,a5
    80003bfe:	85d6                	mv	a1,s5
    80003c00:	8562                	mv	a0,s8
    80003c02:	fffff097          	auipc	ra,0xfffff
    80003c06:	a6c080e7          	jalr	-1428(ra) # 8000266e <either_copyout>
    80003c0a:	05950d63          	beq	a0,s9,80003c64 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c0e:	854a                	mv	a0,s2
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	60c080e7          	jalr	1548(ra) # 8000321c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c18:	013a09bb          	addw	s3,s4,s3
    80003c1c:	009a04bb          	addw	s1,s4,s1
    80003c20:	9aee                	add	s5,s5,s11
    80003c22:	0569f763          	bgeu	s3,s6,80003c70 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c26:	000ba903          	lw	s2,0(s7)
    80003c2a:	00a4d59b          	srliw	a1,s1,0xa
    80003c2e:	855e                	mv	a0,s7
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	8b0080e7          	jalr	-1872(ra) # 800034e0 <bmap>
    80003c38:	0005059b          	sext.w	a1,a0
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	fffff097          	auipc	ra,0xfffff
    80003c42:	4ae080e7          	jalr	1198(ra) # 800030ec <bread>
    80003c46:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c48:	3ff4f613          	andi	a2,s1,1023
    80003c4c:	40cd07bb          	subw	a5,s10,a2
    80003c50:	413b073b          	subw	a4,s6,s3
    80003c54:	8a3e                	mv	s4,a5
    80003c56:	2781                	sext.w	a5,a5
    80003c58:	0007069b          	sext.w	a3,a4
    80003c5c:	f8f6f9e3          	bgeu	a3,a5,80003bee <readi+0x4c>
    80003c60:	8a3a                	mv	s4,a4
    80003c62:	b771                	j	80003bee <readi+0x4c>
      brelse(bp);
    80003c64:	854a                	mv	a0,s2
    80003c66:	fffff097          	auipc	ra,0xfffff
    80003c6a:	5b6080e7          	jalr	1462(ra) # 8000321c <brelse>
      tot = -1;
    80003c6e:	59fd                	li	s3,-1
  }
  return tot;
    80003c70:	0009851b          	sext.w	a0,s3
}
    80003c74:	70a6                	ld	ra,104(sp)
    80003c76:	7406                	ld	s0,96(sp)
    80003c78:	64e6                	ld	s1,88(sp)
    80003c7a:	6946                	ld	s2,80(sp)
    80003c7c:	69a6                	ld	s3,72(sp)
    80003c7e:	6a06                	ld	s4,64(sp)
    80003c80:	7ae2                	ld	s5,56(sp)
    80003c82:	7b42                	ld	s6,48(sp)
    80003c84:	7ba2                	ld	s7,40(sp)
    80003c86:	7c02                	ld	s8,32(sp)
    80003c88:	6ce2                	ld	s9,24(sp)
    80003c8a:	6d42                	ld	s10,16(sp)
    80003c8c:	6da2                	ld	s11,8(sp)
    80003c8e:	6165                	addi	sp,sp,112
    80003c90:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c92:	89da                	mv	s3,s6
    80003c94:	bff1                	j	80003c70 <readi+0xce>
    return 0;
    80003c96:	4501                	li	a0,0
}
    80003c98:	8082                	ret

0000000080003c9a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c9a:	457c                	lw	a5,76(a0)
    80003c9c:	10d7e863          	bltu	a5,a3,80003dac <writei+0x112>
{
    80003ca0:	7159                	addi	sp,sp,-112
    80003ca2:	f486                	sd	ra,104(sp)
    80003ca4:	f0a2                	sd	s0,96(sp)
    80003ca6:	eca6                	sd	s1,88(sp)
    80003ca8:	e8ca                	sd	s2,80(sp)
    80003caa:	e4ce                	sd	s3,72(sp)
    80003cac:	e0d2                	sd	s4,64(sp)
    80003cae:	fc56                	sd	s5,56(sp)
    80003cb0:	f85a                	sd	s6,48(sp)
    80003cb2:	f45e                	sd	s7,40(sp)
    80003cb4:	f062                	sd	s8,32(sp)
    80003cb6:	ec66                	sd	s9,24(sp)
    80003cb8:	e86a                	sd	s10,16(sp)
    80003cba:	e46e                	sd	s11,8(sp)
    80003cbc:	1880                	addi	s0,sp,112
    80003cbe:	8b2a                	mv	s6,a0
    80003cc0:	8c2e                	mv	s8,a1
    80003cc2:	8ab2                	mv	s5,a2
    80003cc4:	8936                	mv	s2,a3
    80003cc6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003cc8:	00e687bb          	addw	a5,a3,a4
    80003ccc:	0ed7e263          	bltu	a5,a3,80003db0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cd0:	00043737          	lui	a4,0x43
    80003cd4:	0ef76063          	bltu	a4,a5,80003db4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cd8:	0c0b8863          	beqz	s7,80003da8 <writei+0x10e>
    80003cdc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cde:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ce2:	5cfd                	li	s9,-1
    80003ce4:	a091                	j	80003d28 <writei+0x8e>
    80003ce6:	02099d93          	slli	s11,s3,0x20
    80003cea:	020ddd93          	srli	s11,s11,0x20
    80003cee:	05848793          	addi	a5,s1,88
    80003cf2:	86ee                	mv	a3,s11
    80003cf4:	8656                	mv	a2,s5
    80003cf6:	85e2                	mv	a1,s8
    80003cf8:	953e                	add	a0,a0,a5
    80003cfa:	fffff097          	auipc	ra,0xfffff
    80003cfe:	9ca080e7          	jalr	-1590(ra) # 800026c4 <either_copyin>
    80003d02:	07950263          	beq	a0,s9,80003d66 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d06:	8526                	mv	a0,s1
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	790080e7          	jalr	1936(ra) # 80004498 <log_write>
    brelse(bp);
    80003d10:	8526                	mv	a0,s1
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	50a080e7          	jalr	1290(ra) # 8000321c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d1a:	01498a3b          	addw	s4,s3,s4
    80003d1e:	0129893b          	addw	s2,s3,s2
    80003d22:	9aee                	add	s5,s5,s11
    80003d24:	057a7663          	bgeu	s4,s7,80003d70 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d28:	000b2483          	lw	s1,0(s6)
    80003d2c:	00a9559b          	srliw	a1,s2,0xa
    80003d30:	855a                	mv	a0,s6
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	7ae080e7          	jalr	1966(ra) # 800034e0 <bmap>
    80003d3a:	0005059b          	sext.w	a1,a0
    80003d3e:	8526                	mv	a0,s1
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	3ac080e7          	jalr	940(ra) # 800030ec <bread>
    80003d48:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4a:	3ff97513          	andi	a0,s2,1023
    80003d4e:	40ad07bb          	subw	a5,s10,a0
    80003d52:	414b873b          	subw	a4,s7,s4
    80003d56:	89be                	mv	s3,a5
    80003d58:	2781                	sext.w	a5,a5
    80003d5a:	0007069b          	sext.w	a3,a4
    80003d5e:	f8f6f4e3          	bgeu	a3,a5,80003ce6 <writei+0x4c>
    80003d62:	89ba                	mv	s3,a4
    80003d64:	b749                	j	80003ce6 <writei+0x4c>
      brelse(bp);
    80003d66:	8526                	mv	a0,s1
    80003d68:	fffff097          	auipc	ra,0xfffff
    80003d6c:	4b4080e7          	jalr	1204(ra) # 8000321c <brelse>
  }

  if(off > ip->size)
    80003d70:	04cb2783          	lw	a5,76(s6)
    80003d74:	0127f463          	bgeu	a5,s2,80003d7c <writei+0xe2>
    ip->size = off;
    80003d78:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d7c:	855a                	mv	a0,s6
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	aa6080e7          	jalr	-1370(ra) # 80003824 <iupdate>

  return tot;
    80003d86:	000a051b          	sext.w	a0,s4
}
    80003d8a:	70a6                	ld	ra,104(sp)
    80003d8c:	7406                	ld	s0,96(sp)
    80003d8e:	64e6                	ld	s1,88(sp)
    80003d90:	6946                	ld	s2,80(sp)
    80003d92:	69a6                	ld	s3,72(sp)
    80003d94:	6a06                	ld	s4,64(sp)
    80003d96:	7ae2                	ld	s5,56(sp)
    80003d98:	7b42                	ld	s6,48(sp)
    80003d9a:	7ba2                	ld	s7,40(sp)
    80003d9c:	7c02                	ld	s8,32(sp)
    80003d9e:	6ce2                	ld	s9,24(sp)
    80003da0:	6d42                	ld	s10,16(sp)
    80003da2:	6da2                	ld	s11,8(sp)
    80003da4:	6165                	addi	sp,sp,112
    80003da6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da8:	8a5e                	mv	s4,s7
    80003daa:	bfc9                	j	80003d7c <writei+0xe2>
    return -1;
    80003dac:	557d                	li	a0,-1
}
    80003dae:	8082                	ret
    return -1;
    80003db0:	557d                	li	a0,-1
    80003db2:	bfe1                	j	80003d8a <writei+0xf0>
    return -1;
    80003db4:	557d                	li	a0,-1
    80003db6:	bfd1                	j	80003d8a <writei+0xf0>

0000000080003db8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003db8:	1141                	addi	sp,sp,-16
    80003dba:	e406                	sd	ra,8(sp)
    80003dbc:	e022                	sd	s0,0(sp)
    80003dbe:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dc0:	4639                	li	a2,14
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	fd4080e7          	jalr	-44(ra) # 80000d96 <strncmp>
}
    80003dca:	60a2                	ld	ra,8(sp)
    80003dcc:	6402                	ld	s0,0(sp)
    80003dce:	0141                	addi	sp,sp,16
    80003dd0:	8082                	ret

0000000080003dd2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dd2:	7139                	addi	sp,sp,-64
    80003dd4:	fc06                	sd	ra,56(sp)
    80003dd6:	f822                	sd	s0,48(sp)
    80003dd8:	f426                	sd	s1,40(sp)
    80003dda:	f04a                	sd	s2,32(sp)
    80003ddc:	ec4e                	sd	s3,24(sp)
    80003dde:	e852                	sd	s4,16(sp)
    80003de0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003de2:	04451703          	lh	a4,68(a0)
    80003de6:	4785                	li	a5,1
    80003de8:	00f71a63          	bne	a4,a5,80003dfc <dirlookup+0x2a>
    80003dec:	892a                	mv	s2,a0
    80003dee:	89ae                	mv	s3,a1
    80003df0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df2:	457c                	lw	a5,76(a0)
    80003df4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003df6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df8:	e79d                	bnez	a5,80003e26 <dirlookup+0x54>
    80003dfa:	a8a5                	j	80003e72 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dfc:	00004517          	auipc	a0,0x4
    80003e00:	7f450513          	addi	a0,a0,2036 # 800085f0 <syscalls+0x1a8>
    80003e04:	ffffc097          	auipc	ra,0xffffc
    80003e08:	726080e7          	jalr	1830(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003e0c:	00004517          	auipc	a0,0x4
    80003e10:	7fc50513          	addi	a0,a0,2044 # 80008608 <syscalls+0x1c0>
    80003e14:	ffffc097          	auipc	ra,0xffffc
    80003e18:	716080e7          	jalr	1814(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e1c:	24c1                	addiw	s1,s1,16
    80003e1e:	04c92783          	lw	a5,76(s2)
    80003e22:	04f4f763          	bgeu	s1,a5,80003e70 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e26:	4741                	li	a4,16
    80003e28:	86a6                	mv	a3,s1
    80003e2a:	fc040613          	addi	a2,s0,-64
    80003e2e:	4581                	li	a1,0
    80003e30:	854a                	mv	a0,s2
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	d70080e7          	jalr	-656(ra) # 80003ba2 <readi>
    80003e3a:	47c1                	li	a5,16
    80003e3c:	fcf518e3          	bne	a0,a5,80003e0c <dirlookup+0x3a>
    if(de.inum == 0)
    80003e40:	fc045783          	lhu	a5,-64(s0)
    80003e44:	dfe1                	beqz	a5,80003e1c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e46:	fc240593          	addi	a1,s0,-62
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	f6c080e7          	jalr	-148(ra) # 80003db8 <namecmp>
    80003e54:	f561                	bnez	a0,80003e1c <dirlookup+0x4a>
      if(poff)
    80003e56:	000a0463          	beqz	s4,80003e5e <dirlookup+0x8c>
        *poff = off;
    80003e5a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e5e:	fc045583          	lhu	a1,-64(s0)
    80003e62:	00092503          	lw	a0,0(s2)
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	754080e7          	jalr	1876(ra) # 800035ba <iget>
    80003e6e:	a011                	j	80003e72 <dirlookup+0xa0>
  return 0;
    80003e70:	4501                	li	a0,0
}
    80003e72:	70e2                	ld	ra,56(sp)
    80003e74:	7442                	ld	s0,48(sp)
    80003e76:	74a2                	ld	s1,40(sp)
    80003e78:	7902                	ld	s2,32(sp)
    80003e7a:	69e2                	ld	s3,24(sp)
    80003e7c:	6a42                	ld	s4,16(sp)
    80003e7e:	6121                	addi	sp,sp,64
    80003e80:	8082                	ret

0000000080003e82 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e82:	711d                	addi	sp,sp,-96
    80003e84:	ec86                	sd	ra,88(sp)
    80003e86:	e8a2                	sd	s0,80(sp)
    80003e88:	e4a6                	sd	s1,72(sp)
    80003e8a:	e0ca                	sd	s2,64(sp)
    80003e8c:	fc4e                	sd	s3,56(sp)
    80003e8e:	f852                	sd	s4,48(sp)
    80003e90:	f456                	sd	s5,40(sp)
    80003e92:	f05a                	sd	s6,32(sp)
    80003e94:	ec5e                	sd	s7,24(sp)
    80003e96:	e862                	sd	s8,16(sp)
    80003e98:	e466                	sd	s9,8(sp)
    80003e9a:	1080                	addi	s0,sp,96
    80003e9c:	84aa                	mv	s1,a0
    80003e9e:	8aae                	mv	s5,a1
    80003ea0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ea2:	00054703          	lbu	a4,0(a0)
    80003ea6:	02f00793          	li	a5,47
    80003eaa:	02f70363          	beq	a4,a5,80003ed0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eae:	ffffe097          	auipc	ra,0xffffe
    80003eb2:	c02080e7          	jalr	-1022(ra) # 80001ab0 <myproc>
    80003eb6:	15053503          	ld	a0,336(a0)
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	9f6080e7          	jalr	-1546(ra) # 800038b0 <idup>
    80003ec2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ec4:	02f00913          	li	s2,47
  len = path - s;
    80003ec8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003eca:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ecc:	4b85                	li	s7,1
    80003ece:	a865                	j	80003f86 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ed0:	4585                	li	a1,1
    80003ed2:	4505                	li	a0,1
    80003ed4:	fffff097          	auipc	ra,0xfffff
    80003ed8:	6e6080e7          	jalr	1766(ra) # 800035ba <iget>
    80003edc:	89aa                	mv	s3,a0
    80003ede:	b7dd                	j	80003ec4 <namex+0x42>
      iunlockput(ip);
    80003ee0:	854e                	mv	a0,s3
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	c6e080e7          	jalr	-914(ra) # 80003b50 <iunlockput>
      return 0;
    80003eea:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eec:	854e                	mv	a0,s3
    80003eee:	60e6                	ld	ra,88(sp)
    80003ef0:	6446                	ld	s0,80(sp)
    80003ef2:	64a6                	ld	s1,72(sp)
    80003ef4:	6906                	ld	s2,64(sp)
    80003ef6:	79e2                	ld	s3,56(sp)
    80003ef8:	7a42                	ld	s4,48(sp)
    80003efa:	7aa2                	ld	s5,40(sp)
    80003efc:	7b02                	ld	s6,32(sp)
    80003efe:	6be2                	ld	s7,24(sp)
    80003f00:	6c42                	ld	s8,16(sp)
    80003f02:	6ca2                	ld	s9,8(sp)
    80003f04:	6125                	addi	sp,sp,96
    80003f06:	8082                	ret
      iunlock(ip);
    80003f08:	854e                	mv	a0,s3
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	aa6080e7          	jalr	-1370(ra) # 800039b0 <iunlock>
      return ip;
    80003f12:	bfe9                	j	80003eec <namex+0x6a>
      iunlockput(ip);
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	c3a080e7          	jalr	-966(ra) # 80003b50 <iunlockput>
      return 0;
    80003f1e:	89e6                	mv	s3,s9
    80003f20:	b7f1                	j	80003eec <namex+0x6a>
  len = path - s;
    80003f22:	40b48633          	sub	a2,s1,a1
    80003f26:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f2a:	099c5463          	bge	s8,s9,80003fb2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f2e:	4639                	li	a2,14
    80003f30:	8552                	mv	a0,s4
    80003f32:	ffffd097          	auipc	ra,0xffffd
    80003f36:	de8080e7          	jalr	-536(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003f3a:	0004c783          	lbu	a5,0(s1)
    80003f3e:	01279763          	bne	a5,s2,80003f4c <namex+0xca>
    path++;
    80003f42:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f44:	0004c783          	lbu	a5,0(s1)
    80003f48:	ff278de3          	beq	a5,s2,80003f42 <namex+0xc0>
    ilock(ip);
    80003f4c:	854e                	mv	a0,s3
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	9a0080e7          	jalr	-1632(ra) # 800038ee <ilock>
    if(ip->type != T_DIR){
    80003f56:	04499783          	lh	a5,68(s3)
    80003f5a:	f97793e3          	bne	a5,s7,80003ee0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f5e:	000a8563          	beqz	s5,80003f68 <namex+0xe6>
    80003f62:	0004c783          	lbu	a5,0(s1)
    80003f66:	d3cd                	beqz	a5,80003f08 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f68:	865a                	mv	a2,s6
    80003f6a:	85d2                	mv	a1,s4
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	e64080e7          	jalr	-412(ra) # 80003dd2 <dirlookup>
    80003f76:	8caa                	mv	s9,a0
    80003f78:	dd51                	beqz	a0,80003f14 <namex+0x92>
    iunlockput(ip);
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	bd4080e7          	jalr	-1068(ra) # 80003b50 <iunlockput>
    ip = next;
    80003f84:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f86:	0004c783          	lbu	a5,0(s1)
    80003f8a:	05279763          	bne	a5,s2,80003fd8 <namex+0x156>
    path++;
    80003f8e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f90:	0004c783          	lbu	a5,0(s1)
    80003f94:	ff278de3          	beq	a5,s2,80003f8e <namex+0x10c>
  if(*path == 0)
    80003f98:	c79d                	beqz	a5,80003fc6 <namex+0x144>
    path++;
    80003f9a:	85a6                	mv	a1,s1
  len = path - s;
    80003f9c:	8cda                	mv	s9,s6
    80003f9e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fa0:	01278963          	beq	a5,s2,80003fb2 <namex+0x130>
    80003fa4:	dfbd                	beqz	a5,80003f22 <namex+0xa0>
    path++;
    80003fa6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fa8:	0004c783          	lbu	a5,0(s1)
    80003fac:	ff279ce3          	bne	a5,s2,80003fa4 <namex+0x122>
    80003fb0:	bf8d                	j	80003f22 <namex+0xa0>
    memmove(name, s, len);
    80003fb2:	2601                	sext.w	a2,a2
    80003fb4:	8552                	mv	a0,s4
    80003fb6:	ffffd097          	auipc	ra,0xffffd
    80003fba:	d64080e7          	jalr	-668(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003fbe:	9cd2                	add	s9,s9,s4
    80003fc0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fc4:	bf9d                	j	80003f3a <namex+0xb8>
  if(nameiparent){
    80003fc6:	f20a83e3          	beqz	s5,80003eec <namex+0x6a>
    iput(ip);
    80003fca:	854e                	mv	a0,s3
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	adc080e7          	jalr	-1316(ra) # 80003aa8 <iput>
    return 0;
    80003fd4:	4981                	li	s3,0
    80003fd6:	bf19                	j	80003eec <namex+0x6a>
  if(*path == 0)
    80003fd8:	d7fd                	beqz	a5,80003fc6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fda:	0004c783          	lbu	a5,0(s1)
    80003fde:	85a6                	mv	a1,s1
    80003fe0:	b7d1                	j	80003fa4 <namex+0x122>

0000000080003fe2 <dirlink>:
{
    80003fe2:	7139                	addi	sp,sp,-64
    80003fe4:	fc06                	sd	ra,56(sp)
    80003fe6:	f822                	sd	s0,48(sp)
    80003fe8:	f426                	sd	s1,40(sp)
    80003fea:	f04a                	sd	s2,32(sp)
    80003fec:	ec4e                	sd	s3,24(sp)
    80003fee:	e852                	sd	s4,16(sp)
    80003ff0:	0080                	addi	s0,sp,64
    80003ff2:	892a                	mv	s2,a0
    80003ff4:	8a2e                	mv	s4,a1
    80003ff6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ff8:	4601                	li	a2,0
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	dd8080e7          	jalr	-552(ra) # 80003dd2 <dirlookup>
    80004002:	e93d                	bnez	a0,80004078 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004004:	04c92483          	lw	s1,76(s2)
    80004008:	c49d                	beqz	s1,80004036 <dirlink+0x54>
    8000400a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000400c:	4741                	li	a4,16
    8000400e:	86a6                	mv	a3,s1
    80004010:	fc040613          	addi	a2,s0,-64
    80004014:	4581                	li	a1,0
    80004016:	854a                	mv	a0,s2
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	b8a080e7          	jalr	-1142(ra) # 80003ba2 <readi>
    80004020:	47c1                	li	a5,16
    80004022:	06f51163          	bne	a0,a5,80004084 <dirlink+0xa2>
    if(de.inum == 0)
    80004026:	fc045783          	lhu	a5,-64(s0)
    8000402a:	c791                	beqz	a5,80004036 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000402c:	24c1                	addiw	s1,s1,16
    8000402e:	04c92783          	lw	a5,76(s2)
    80004032:	fcf4ede3          	bltu	s1,a5,8000400c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004036:	4639                	li	a2,14
    80004038:	85d2                	mv	a1,s4
    8000403a:	fc240513          	addi	a0,s0,-62
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	d94080e7          	jalr	-620(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004046:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000404a:	4741                	li	a4,16
    8000404c:	86a6                	mv	a3,s1
    8000404e:	fc040613          	addi	a2,s0,-64
    80004052:	4581                	li	a1,0
    80004054:	854a                	mv	a0,s2
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	c44080e7          	jalr	-956(ra) # 80003c9a <writei>
    8000405e:	872a                	mv	a4,a0
    80004060:	47c1                	li	a5,16
  return 0;
    80004062:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004064:	02f71863          	bne	a4,a5,80004094 <dirlink+0xb2>
}
    80004068:	70e2                	ld	ra,56(sp)
    8000406a:	7442                	ld	s0,48(sp)
    8000406c:	74a2                	ld	s1,40(sp)
    8000406e:	7902                	ld	s2,32(sp)
    80004070:	69e2                	ld	s3,24(sp)
    80004072:	6a42                	ld	s4,16(sp)
    80004074:	6121                	addi	sp,sp,64
    80004076:	8082                	ret
    iput(ip);
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	a30080e7          	jalr	-1488(ra) # 80003aa8 <iput>
    return -1;
    80004080:	557d                	li	a0,-1
    80004082:	b7dd                	j	80004068 <dirlink+0x86>
      panic("dirlink read");
    80004084:	00004517          	auipc	a0,0x4
    80004088:	59450513          	addi	a0,a0,1428 # 80008618 <syscalls+0x1d0>
    8000408c:	ffffc097          	auipc	ra,0xffffc
    80004090:	49e080e7          	jalr	1182(ra) # 8000052a <panic>
    panic("dirlink");
    80004094:	00004517          	auipc	a0,0x4
    80004098:	69450513          	addi	a0,a0,1684 # 80008728 <syscalls+0x2e0>
    8000409c:	ffffc097          	auipc	ra,0xffffc
    800040a0:	48e080e7          	jalr	1166(ra) # 8000052a <panic>

00000000800040a4 <namei>:

struct inode*
namei(char *path)
{
    800040a4:	1101                	addi	sp,sp,-32
    800040a6:	ec06                	sd	ra,24(sp)
    800040a8:	e822                	sd	s0,16(sp)
    800040aa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040ac:	fe040613          	addi	a2,s0,-32
    800040b0:	4581                	li	a1,0
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	dd0080e7          	jalr	-560(ra) # 80003e82 <namex>
}
    800040ba:	60e2                	ld	ra,24(sp)
    800040bc:	6442                	ld	s0,16(sp)
    800040be:	6105                	addi	sp,sp,32
    800040c0:	8082                	ret

00000000800040c2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040c2:	1141                	addi	sp,sp,-16
    800040c4:	e406                	sd	ra,8(sp)
    800040c6:	e022                	sd	s0,0(sp)
    800040c8:	0800                	addi	s0,sp,16
    800040ca:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040cc:	4585                	li	a1,1
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	db4080e7          	jalr	-588(ra) # 80003e82 <namex>
}
    800040d6:	60a2                	ld	ra,8(sp)
    800040d8:	6402                	ld	s0,0(sp)
    800040da:	0141                	addi	sp,sp,16
    800040dc:	8082                	ret

00000000800040de <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040de:	1101                	addi	sp,sp,-32
    800040e0:	ec06                	sd	ra,24(sp)
    800040e2:	e822                	sd	s0,16(sp)
    800040e4:	e426                	sd	s1,8(sp)
    800040e6:	e04a                	sd	s2,0(sp)
    800040e8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040ea:	0001e917          	auipc	s2,0x1e
    800040ee:	9b690913          	addi	s2,s2,-1610 # 80021aa0 <log>
    800040f2:	01892583          	lw	a1,24(s2)
    800040f6:	02892503          	lw	a0,40(s2)
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	ff2080e7          	jalr	-14(ra) # 800030ec <bread>
    80004102:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004104:	02c92683          	lw	a3,44(s2)
    80004108:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000410a:	02d05763          	blez	a3,80004138 <write_head+0x5a>
    8000410e:	0001e797          	auipc	a5,0x1e
    80004112:	9c278793          	addi	a5,a5,-1598 # 80021ad0 <log+0x30>
    80004116:	05c50713          	addi	a4,a0,92
    8000411a:	36fd                	addiw	a3,a3,-1
    8000411c:	1682                	slli	a3,a3,0x20
    8000411e:	9281                	srli	a3,a3,0x20
    80004120:	068a                	slli	a3,a3,0x2
    80004122:	0001e617          	auipc	a2,0x1e
    80004126:	9b260613          	addi	a2,a2,-1614 # 80021ad4 <log+0x34>
    8000412a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000412c:	4390                	lw	a2,0(a5)
    8000412e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004130:	0791                	addi	a5,a5,4
    80004132:	0711                	addi	a4,a4,4
    80004134:	fed79ce3          	bne	a5,a3,8000412c <write_head+0x4e>
  }
  bwrite(buf);
    80004138:	8526                	mv	a0,s1
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	0a4080e7          	jalr	164(ra) # 800031de <bwrite>
  brelse(buf);
    80004142:	8526                	mv	a0,s1
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	0d8080e7          	jalr	216(ra) # 8000321c <brelse>
}
    8000414c:	60e2                	ld	ra,24(sp)
    8000414e:	6442                	ld	s0,16(sp)
    80004150:	64a2                	ld	s1,8(sp)
    80004152:	6902                	ld	s2,0(sp)
    80004154:	6105                	addi	sp,sp,32
    80004156:	8082                	ret

0000000080004158 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004158:	0001e797          	auipc	a5,0x1e
    8000415c:	9747a783          	lw	a5,-1676(a5) # 80021acc <log+0x2c>
    80004160:	0af05d63          	blez	a5,8000421a <install_trans+0xc2>
{
    80004164:	7139                	addi	sp,sp,-64
    80004166:	fc06                	sd	ra,56(sp)
    80004168:	f822                	sd	s0,48(sp)
    8000416a:	f426                	sd	s1,40(sp)
    8000416c:	f04a                	sd	s2,32(sp)
    8000416e:	ec4e                	sd	s3,24(sp)
    80004170:	e852                	sd	s4,16(sp)
    80004172:	e456                	sd	s5,8(sp)
    80004174:	e05a                	sd	s6,0(sp)
    80004176:	0080                	addi	s0,sp,64
    80004178:	8b2a                	mv	s6,a0
    8000417a:	0001ea97          	auipc	s5,0x1e
    8000417e:	956a8a93          	addi	s5,s5,-1706 # 80021ad0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004182:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004184:	0001e997          	auipc	s3,0x1e
    80004188:	91c98993          	addi	s3,s3,-1764 # 80021aa0 <log>
    8000418c:	a00d                	j	800041ae <install_trans+0x56>
    brelse(lbuf);
    8000418e:	854a                	mv	a0,s2
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	08c080e7          	jalr	140(ra) # 8000321c <brelse>
    brelse(dbuf);
    80004198:	8526                	mv	a0,s1
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	082080e7          	jalr	130(ra) # 8000321c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a2:	2a05                	addiw	s4,s4,1
    800041a4:	0a91                	addi	s5,s5,4
    800041a6:	02c9a783          	lw	a5,44(s3)
    800041aa:	04fa5e63          	bge	s4,a5,80004206 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ae:	0189a583          	lw	a1,24(s3)
    800041b2:	014585bb          	addw	a1,a1,s4
    800041b6:	2585                	addiw	a1,a1,1
    800041b8:	0289a503          	lw	a0,40(s3)
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	f30080e7          	jalr	-208(ra) # 800030ec <bread>
    800041c4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041c6:	000aa583          	lw	a1,0(s5)
    800041ca:	0289a503          	lw	a0,40(s3)
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	f1e080e7          	jalr	-226(ra) # 800030ec <bread>
    800041d6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041d8:	40000613          	li	a2,1024
    800041dc:	05890593          	addi	a1,s2,88
    800041e0:	05850513          	addi	a0,a0,88
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	b36080e7          	jalr	-1226(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800041ec:	8526                	mv	a0,s1
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	ff0080e7          	jalr	-16(ra) # 800031de <bwrite>
    if(recovering == 0)
    800041f6:	f80b1ce3          	bnez	s6,8000418e <install_trans+0x36>
      bunpin(dbuf);
    800041fa:	8526                	mv	a0,s1
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	0fa080e7          	jalr	250(ra) # 800032f6 <bunpin>
    80004204:	b769                	j	8000418e <install_trans+0x36>
}
    80004206:	70e2                	ld	ra,56(sp)
    80004208:	7442                	ld	s0,48(sp)
    8000420a:	74a2                	ld	s1,40(sp)
    8000420c:	7902                	ld	s2,32(sp)
    8000420e:	69e2                	ld	s3,24(sp)
    80004210:	6a42                	ld	s4,16(sp)
    80004212:	6aa2                	ld	s5,8(sp)
    80004214:	6b02                	ld	s6,0(sp)
    80004216:	6121                	addi	sp,sp,64
    80004218:	8082                	ret
    8000421a:	8082                	ret

000000008000421c <initlog>:
{
    8000421c:	7179                	addi	sp,sp,-48
    8000421e:	f406                	sd	ra,40(sp)
    80004220:	f022                	sd	s0,32(sp)
    80004222:	ec26                	sd	s1,24(sp)
    80004224:	e84a                	sd	s2,16(sp)
    80004226:	e44e                	sd	s3,8(sp)
    80004228:	1800                	addi	s0,sp,48
    8000422a:	892a                	mv	s2,a0
    8000422c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000422e:	0001e497          	auipc	s1,0x1e
    80004232:	87248493          	addi	s1,s1,-1934 # 80021aa0 <log>
    80004236:	00004597          	auipc	a1,0x4
    8000423a:	3f258593          	addi	a1,a1,1010 # 80008628 <syscalls+0x1e0>
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	8f2080e7          	jalr	-1806(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004248:	0149a583          	lw	a1,20(s3)
    8000424c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000424e:	0109a783          	lw	a5,16(s3)
    80004252:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004254:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004258:	854a                	mv	a0,s2
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	e92080e7          	jalr	-366(ra) # 800030ec <bread>
  log.lh.n = lh->n;
    80004262:	4d34                	lw	a3,88(a0)
    80004264:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004266:	02d05563          	blez	a3,80004290 <initlog+0x74>
    8000426a:	05c50793          	addi	a5,a0,92
    8000426e:	0001e717          	auipc	a4,0x1e
    80004272:	86270713          	addi	a4,a4,-1950 # 80021ad0 <log+0x30>
    80004276:	36fd                	addiw	a3,a3,-1
    80004278:	1682                	slli	a3,a3,0x20
    8000427a:	9281                	srli	a3,a3,0x20
    8000427c:	068a                	slli	a3,a3,0x2
    8000427e:	06050613          	addi	a2,a0,96
    80004282:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004284:	4390                	lw	a2,0(a5)
    80004286:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004288:	0791                	addi	a5,a5,4
    8000428a:	0711                	addi	a4,a4,4
    8000428c:	fed79ce3          	bne	a5,a3,80004284 <initlog+0x68>
  brelse(buf);
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	f8c080e7          	jalr	-116(ra) # 8000321c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004298:	4505                	li	a0,1
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	ebe080e7          	jalr	-322(ra) # 80004158 <install_trans>
  log.lh.n = 0;
    800042a2:	0001e797          	auipc	a5,0x1e
    800042a6:	8207a523          	sw	zero,-2006(a5) # 80021acc <log+0x2c>
  write_head(); // clear the log
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	e34080e7          	jalr	-460(ra) # 800040de <write_head>
}
    800042b2:	70a2                	ld	ra,40(sp)
    800042b4:	7402                	ld	s0,32(sp)
    800042b6:	64e2                	ld	s1,24(sp)
    800042b8:	6942                	ld	s2,16(sp)
    800042ba:	69a2                	ld	s3,8(sp)
    800042bc:	6145                	addi	sp,sp,48
    800042be:	8082                	ret

00000000800042c0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042c0:	1101                	addi	sp,sp,-32
    800042c2:	ec06                	sd	ra,24(sp)
    800042c4:	e822                	sd	s0,16(sp)
    800042c6:	e426                	sd	s1,8(sp)
    800042c8:	e04a                	sd	s2,0(sp)
    800042ca:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042cc:	0001d517          	auipc	a0,0x1d
    800042d0:	7d450513          	addi	a0,a0,2004 # 80021aa0 <log>
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	8ee080e7          	jalr	-1810(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800042dc:	0001d497          	auipc	s1,0x1d
    800042e0:	7c448493          	addi	s1,s1,1988 # 80021aa0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e4:	4979                	li	s2,30
    800042e6:	a039                	j	800042f4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042e8:	85a6                	mv	a1,s1
    800042ea:	8526                	mv	a0,s1
    800042ec:	ffffe097          	auipc	ra,0xffffe
    800042f0:	fca080e7          	jalr	-54(ra) # 800022b6 <sleep>
    if(log.committing){
    800042f4:	50dc                	lw	a5,36(s1)
    800042f6:	fbed                	bnez	a5,800042e8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f8:	509c                	lw	a5,32(s1)
    800042fa:	0017871b          	addiw	a4,a5,1
    800042fe:	0007069b          	sext.w	a3,a4
    80004302:	0027179b          	slliw	a5,a4,0x2
    80004306:	9fb9                	addw	a5,a5,a4
    80004308:	0017979b          	slliw	a5,a5,0x1
    8000430c:	54d8                	lw	a4,44(s1)
    8000430e:	9fb9                	addw	a5,a5,a4
    80004310:	00f95963          	bge	s2,a5,80004322 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004314:	85a6                	mv	a1,s1
    80004316:	8526                	mv	a0,s1
    80004318:	ffffe097          	auipc	ra,0xffffe
    8000431c:	f9e080e7          	jalr	-98(ra) # 800022b6 <sleep>
    80004320:	bfd1                	j	800042f4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004322:	0001d517          	auipc	a0,0x1d
    80004326:	77e50513          	addi	a0,a0,1918 # 80021aa0 <log>
    8000432a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	94a080e7          	jalr	-1718(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004334:	60e2                	ld	ra,24(sp)
    80004336:	6442                	ld	s0,16(sp)
    80004338:	64a2                	ld	s1,8(sp)
    8000433a:	6902                	ld	s2,0(sp)
    8000433c:	6105                	addi	sp,sp,32
    8000433e:	8082                	ret

0000000080004340 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004340:	7139                	addi	sp,sp,-64
    80004342:	fc06                	sd	ra,56(sp)
    80004344:	f822                	sd	s0,48(sp)
    80004346:	f426                	sd	s1,40(sp)
    80004348:	f04a                	sd	s2,32(sp)
    8000434a:	ec4e                	sd	s3,24(sp)
    8000434c:	e852                	sd	s4,16(sp)
    8000434e:	e456                	sd	s5,8(sp)
    80004350:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004352:	0001d497          	auipc	s1,0x1d
    80004356:	74e48493          	addi	s1,s1,1870 # 80021aa0 <log>
    8000435a:	8526                	mv	a0,s1
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	866080e7          	jalr	-1946(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004364:	509c                	lw	a5,32(s1)
    80004366:	37fd                	addiw	a5,a5,-1
    80004368:	0007891b          	sext.w	s2,a5
    8000436c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000436e:	50dc                	lw	a5,36(s1)
    80004370:	e7b9                	bnez	a5,800043be <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004372:	04091e63          	bnez	s2,800043ce <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004376:	0001d497          	auipc	s1,0x1d
    8000437a:	72a48493          	addi	s1,s1,1834 # 80021aa0 <log>
    8000437e:	4785                	li	a5,1
    80004380:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004382:	8526                	mv	a0,s1
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	8f2080e7          	jalr	-1806(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000438c:	54dc                	lw	a5,44(s1)
    8000438e:	06f04763          	bgtz	a5,800043fc <end_op+0xbc>
    acquire(&log.lock);
    80004392:	0001d497          	auipc	s1,0x1d
    80004396:	70e48493          	addi	s1,s1,1806 # 80021aa0 <log>
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	826080e7          	jalr	-2010(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800043a4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	098080e7          	jalr	152(ra) # 80002442 <wakeup>
    release(&log.lock);
    800043b2:	8526                	mv	a0,s1
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	8c2080e7          	jalr	-1854(ra) # 80000c76 <release>
}
    800043bc:	a03d                	j	800043ea <end_op+0xaa>
    panic("log.committing");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	27250513          	addi	a0,a0,626 # 80008630 <syscalls+0x1e8>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	164080e7          	jalr	356(ra) # 8000052a <panic>
    wakeup(&log);
    800043ce:	0001d497          	auipc	s1,0x1d
    800043d2:	6d248493          	addi	s1,s1,1746 # 80021aa0 <log>
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	06a080e7          	jalr	106(ra) # 80002442 <wakeup>
  release(&log.lock);
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	894080e7          	jalr	-1900(ra) # 80000c76 <release>
}
    800043ea:	70e2                	ld	ra,56(sp)
    800043ec:	7442                	ld	s0,48(sp)
    800043ee:	74a2                	ld	s1,40(sp)
    800043f0:	7902                	ld	s2,32(sp)
    800043f2:	69e2                	ld	s3,24(sp)
    800043f4:	6a42                	ld	s4,16(sp)
    800043f6:	6aa2                	ld	s5,8(sp)
    800043f8:	6121                	addi	sp,sp,64
    800043fa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fc:	0001da97          	auipc	s5,0x1d
    80004400:	6d4a8a93          	addi	s5,s5,1748 # 80021ad0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004404:	0001da17          	auipc	s4,0x1d
    80004408:	69ca0a13          	addi	s4,s4,1692 # 80021aa0 <log>
    8000440c:	018a2583          	lw	a1,24(s4)
    80004410:	012585bb          	addw	a1,a1,s2
    80004414:	2585                	addiw	a1,a1,1
    80004416:	028a2503          	lw	a0,40(s4)
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	cd2080e7          	jalr	-814(ra) # 800030ec <bread>
    80004422:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004424:	000aa583          	lw	a1,0(s5)
    80004428:	028a2503          	lw	a0,40(s4)
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	cc0080e7          	jalr	-832(ra) # 800030ec <bread>
    80004434:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004436:	40000613          	li	a2,1024
    8000443a:	05850593          	addi	a1,a0,88
    8000443e:	05848513          	addi	a0,s1,88
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	8d8080e7          	jalr	-1832(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000444a:	8526                	mv	a0,s1
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	d92080e7          	jalr	-622(ra) # 800031de <bwrite>
    brelse(from);
    80004454:	854e                	mv	a0,s3
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	dc6080e7          	jalr	-570(ra) # 8000321c <brelse>
    brelse(to);
    8000445e:	8526                	mv	a0,s1
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	dbc080e7          	jalr	-580(ra) # 8000321c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004468:	2905                	addiw	s2,s2,1
    8000446a:	0a91                	addi	s5,s5,4
    8000446c:	02ca2783          	lw	a5,44(s4)
    80004470:	f8f94ee3          	blt	s2,a5,8000440c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004474:	00000097          	auipc	ra,0x0
    80004478:	c6a080e7          	jalr	-918(ra) # 800040de <write_head>
    install_trans(0); // Now install writes to home locations
    8000447c:	4501                	li	a0,0
    8000447e:	00000097          	auipc	ra,0x0
    80004482:	cda080e7          	jalr	-806(ra) # 80004158 <install_trans>
    log.lh.n = 0;
    80004486:	0001d797          	auipc	a5,0x1d
    8000448a:	6407a323          	sw	zero,1606(a5) # 80021acc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000448e:	00000097          	auipc	ra,0x0
    80004492:	c50080e7          	jalr	-944(ra) # 800040de <write_head>
    80004496:	bdf5                	j	80004392 <end_op+0x52>

0000000080004498 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004498:	1101                	addi	sp,sp,-32
    8000449a:	ec06                	sd	ra,24(sp)
    8000449c:	e822                	sd	s0,16(sp)
    8000449e:	e426                	sd	s1,8(sp)
    800044a0:	e04a                	sd	s2,0(sp)
    800044a2:	1000                	addi	s0,sp,32
    800044a4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044a6:	0001d917          	auipc	s2,0x1d
    800044aa:	5fa90913          	addi	s2,s2,1530 # 80021aa0 <log>
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	712080e7          	jalr	1810(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044b8:	02c92603          	lw	a2,44(s2)
    800044bc:	47f5                	li	a5,29
    800044be:	06c7c563          	blt	a5,a2,80004528 <log_write+0x90>
    800044c2:	0001d797          	auipc	a5,0x1d
    800044c6:	5fa7a783          	lw	a5,1530(a5) # 80021abc <log+0x1c>
    800044ca:	37fd                	addiw	a5,a5,-1
    800044cc:	04f65e63          	bge	a2,a5,80004528 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044d0:	0001d797          	auipc	a5,0x1d
    800044d4:	5f07a783          	lw	a5,1520(a5) # 80021ac0 <log+0x20>
    800044d8:	06f05063          	blez	a5,80004538 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044dc:	4781                	li	a5,0
    800044de:	06c05563          	blez	a2,80004548 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044e2:	44cc                	lw	a1,12(s1)
    800044e4:	0001d717          	auipc	a4,0x1d
    800044e8:	5ec70713          	addi	a4,a4,1516 # 80021ad0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044ec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044ee:	4314                	lw	a3,0(a4)
    800044f0:	04b68c63          	beq	a3,a1,80004548 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044f4:	2785                	addiw	a5,a5,1
    800044f6:	0711                	addi	a4,a4,4
    800044f8:	fef61be3          	bne	a2,a5,800044ee <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044fc:	0621                	addi	a2,a2,8
    800044fe:	060a                	slli	a2,a2,0x2
    80004500:	0001d797          	auipc	a5,0x1d
    80004504:	5a078793          	addi	a5,a5,1440 # 80021aa0 <log>
    80004508:	963e                	add	a2,a2,a5
    8000450a:	44dc                	lw	a5,12(s1)
    8000450c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000450e:	8526                	mv	a0,s1
    80004510:	fffff097          	auipc	ra,0xfffff
    80004514:	daa080e7          	jalr	-598(ra) # 800032ba <bpin>
    log.lh.n++;
    80004518:	0001d717          	auipc	a4,0x1d
    8000451c:	58870713          	addi	a4,a4,1416 # 80021aa0 <log>
    80004520:	575c                	lw	a5,44(a4)
    80004522:	2785                	addiw	a5,a5,1
    80004524:	d75c                	sw	a5,44(a4)
    80004526:	a835                	j	80004562 <log_write+0xca>
    panic("too big a transaction");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	11850513          	addi	a0,a0,280 # 80008640 <syscalls+0x1f8>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	ffa080e7          	jalr	-6(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004538:	00004517          	auipc	a0,0x4
    8000453c:	12050513          	addi	a0,a0,288 # 80008658 <syscalls+0x210>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	fea080e7          	jalr	-22(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004548:	00878713          	addi	a4,a5,8
    8000454c:	00271693          	slli	a3,a4,0x2
    80004550:	0001d717          	auipc	a4,0x1d
    80004554:	55070713          	addi	a4,a4,1360 # 80021aa0 <log>
    80004558:	9736                	add	a4,a4,a3
    8000455a:	44d4                	lw	a3,12(s1)
    8000455c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000455e:	faf608e3          	beq	a2,a5,8000450e <log_write+0x76>
  }
  release(&log.lock);
    80004562:	0001d517          	auipc	a0,0x1d
    80004566:	53e50513          	addi	a0,a0,1342 # 80021aa0 <log>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	70c080e7          	jalr	1804(ra) # 80000c76 <release>
}
    80004572:	60e2                	ld	ra,24(sp)
    80004574:	6442                	ld	s0,16(sp)
    80004576:	64a2                	ld	s1,8(sp)
    80004578:	6902                	ld	s2,0(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret

000000008000457e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000457e:	1101                	addi	sp,sp,-32
    80004580:	ec06                	sd	ra,24(sp)
    80004582:	e822                	sd	s0,16(sp)
    80004584:	e426                	sd	s1,8(sp)
    80004586:	e04a                	sd	s2,0(sp)
    80004588:	1000                	addi	s0,sp,32
    8000458a:	84aa                	mv	s1,a0
    8000458c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000458e:	00004597          	auipc	a1,0x4
    80004592:	0ea58593          	addi	a1,a1,234 # 80008678 <syscalls+0x230>
    80004596:	0521                	addi	a0,a0,8
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	59a080e7          	jalr	1434(ra) # 80000b32 <initlock>
  lk->name = name;
    800045a0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045a8:	0204a423          	sw	zero,40(s1)
}
    800045ac:	60e2                	ld	ra,24(sp)
    800045ae:	6442                	ld	s0,16(sp)
    800045b0:	64a2                	ld	s1,8(sp)
    800045b2:	6902                	ld	s2,0(sp)
    800045b4:	6105                	addi	sp,sp,32
    800045b6:	8082                	ret

00000000800045b8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045b8:	1101                	addi	sp,sp,-32
    800045ba:	ec06                	sd	ra,24(sp)
    800045bc:	e822                	sd	s0,16(sp)
    800045be:	e426                	sd	s1,8(sp)
    800045c0:	e04a                	sd	s2,0(sp)
    800045c2:	1000                	addi	s0,sp,32
    800045c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045c6:	00850913          	addi	s2,a0,8
    800045ca:	854a                	mv	a0,s2
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	5f6080e7          	jalr	1526(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800045d4:	409c                	lw	a5,0(s1)
    800045d6:	cb89                	beqz	a5,800045e8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045d8:	85ca                	mv	a1,s2
    800045da:	8526                	mv	a0,s1
    800045dc:	ffffe097          	auipc	ra,0xffffe
    800045e0:	cda080e7          	jalr	-806(ra) # 800022b6 <sleep>
  while (lk->locked) {
    800045e4:	409c                	lw	a5,0(s1)
    800045e6:	fbed                	bnez	a5,800045d8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045e8:	4785                	li	a5,1
    800045ea:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045ec:	ffffd097          	auipc	ra,0xffffd
    800045f0:	4c4080e7          	jalr	1220(ra) # 80001ab0 <myproc>
    800045f4:	591c                	lw	a5,48(a0)
    800045f6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045f8:	854a                	mv	a0,s2
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	67c080e7          	jalr	1660(ra) # 80000c76 <release>
}
    80004602:	60e2                	ld	ra,24(sp)
    80004604:	6442                	ld	s0,16(sp)
    80004606:	64a2                	ld	s1,8(sp)
    80004608:	6902                	ld	s2,0(sp)
    8000460a:	6105                	addi	sp,sp,32
    8000460c:	8082                	ret

000000008000460e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000460e:	1101                	addi	sp,sp,-32
    80004610:	ec06                	sd	ra,24(sp)
    80004612:	e822                	sd	s0,16(sp)
    80004614:	e426                	sd	s1,8(sp)
    80004616:	e04a                	sd	s2,0(sp)
    80004618:	1000                	addi	s0,sp,32
    8000461a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000461c:	00850913          	addi	s2,a0,8
    80004620:	854a                	mv	a0,s2
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	5a0080e7          	jalr	1440(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000462a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000462e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004632:	8526                	mv	a0,s1
    80004634:	ffffe097          	auipc	ra,0xffffe
    80004638:	e0e080e7          	jalr	-498(ra) # 80002442 <wakeup>
  release(&lk->lk);
    8000463c:	854a                	mv	a0,s2
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	638080e7          	jalr	1592(ra) # 80000c76 <release>
}
    80004646:	60e2                	ld	ra,24(sp)
    80004648:	6442                	ld	s0,16(sp)
    8000464a:	64a2                	ld	s1,8(sp)
    8000464c:	6902                	ld	s2,0(sp)
    8000464e:	6105                	addi	sp,sp,32
    80004650:	8082                	ret

0000000080004652 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004652:	7179                	addi	sp,sp,-48
    80004654:	f406                	sd	ra,40(sp)
    80004656:	f022                	sd	s0,32(sp)
    80004658:	ec26                	sd	s1,24(sp)
    8000465a:	e84a                	sd	s2,16(sp)
    8000465c:	e44e                	sd	s3,8(sp)
    8000465e:	1800                	addi	s0,sp,48
    80004660:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004662:	00850913          	addi	s2,a0,8
    80004666:	854a                	mv	a0,s2
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	55a080e7          	jalr	1370(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004670:	409c                	lw	a5,0(s1)
    80004672:	ef99                	bnez	a5,80004690 <holdingsleep+0x3e>
    80004674:	4481                	li	s1,0
  release(&lk->lk);
    80004676:	854a                	mv	a0,s2
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	5fe080e7          	jalr	1534(ra) # 80000c76 <release>
  return r;
}
    80004680:	8526                	mv	a0,s1
    80004682:	70a2                	ld	ra,40(sp)
    80004684:	7402                	ld	s0,32(sp)
    80004686:	64e2                	ld	s1,24(sp)
    80004688:	6942                	ld	s2,16(sp)
    8000468a:	69a2                	ld	s3,8(sp)
    8000468c:	6145                	addi	sp,sp,48
    8000468e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004690:	0284a983          	lw	s3,40(s1)
    80004694:	ffffd097          	auipc	ra,0xffffd
    80004698:	41c080e7          	jalr	1052(ra) # 80001ab0 <myproc>
    8000469c:	5904                	lw	s1,48(a0)
    8000469e:	413484b3          	sub	s1,s1,s3
    800046a2:	0014b493          	seqz	s1,s1
    800046a6:	bfc1                	j	80004676 <holdingsleep+0x24>

00000000800046a8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046a8:	1141                	addi	sp,sp,-16
    800046aa:	e406                	sd	ra,8(sp)
    800046ac:	e022                	sd	s0,0(sp)
    800046ae:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046b0:	00004597          	auipc	a1,0x4
    800046b4:	fd858593          	addi	a1,a1,-40 # 80008688 <syscalls+0x240>
    800046b8:	0001d517          	auipc	a0,0x1d
    800046bc:	53050513          	addi	a0,a0,1328 # 80021be8 <ftable>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	472080e7          	jalr	1138(ra) # 80000b32 <initlock>
}
    800046c8:	60a2                	ld	ra,8(sp)
    800046ca:	6402                	ld	s0,0(sp)
    800046cc:	0141                	addi	sp,sp,16
    800046ce:	8082                	ret

00000000800046d0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046da:	0001d517          	auipc	a0,0x1d
    800046de:	50e50513          	addi	a0,a0,1294 # 80021be8 <ftable>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	4e0080e7          	jalr	1248(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ea:	0001d497          	auipc	s1,0x1d
    800046ee:	51648493          	addi	s1,s1,1302 # 80021c00 <ftable+0x18>
    800046f2:	0001e717          	auipc	a4,0x1e
    800046f6:	4ae70713          	addi	a4,a4,1198 # 80022ba0 <ftable+0xfb8>
    if(f->ref == 0){
    800046fa:	40dc                	lw	a5,4(s1)
    800046fc:	cf99                	beqz	a5,8000471a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046fe:	02848493          	addi	s1,s1,40
    80004702:	fee49ce3          	bne	s1,a4,800046fa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004706:	0001d517          	auipc	a0,0x1d
    8000470a:	4e250513          	addi	a0,a0,1250 # 80021be8 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	568080e7          	jalr	1384(ra) # 80000c76 <release>
  return 0;
    80004716:	4481                	li	s1,0
    80004718:	a819                	j	8000472e <filealloc+0x5e>
      f->ref = 1;
    8000471a:	4785                	li	a5,1
    8000471c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000471e:	0001d517          	auipc	a0,0x1d
    80004722:	4ca50513          	addi	a0,a0,1226 # 80021be8 <ftable>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	550080e7          	jalr	1360(ra) # 80000c76 <release>
}
    8000472e:	8526                	mv	a0,s1
    80004730:	60e2                	ld	ra,24(sp)
    80004732:	6442                	ld	s0,16(sp)
    80004734:	64a2                	ld	s1,8(sp)
    80004736:	6105                	addi	sp,sp,32
    80004738:	8082                	ret

000000008000473a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000473a:	1101                	addi	sp,sp,-32
    8000473c:	ec06                	sd	ra,24(sp)
    8000473e:	e822                	sd	s0,16(sp)
    80004740:	e426                	sd	s1,8(sp)
    80004742:	1000                	addi	s0,sp,32
    80004744:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004746:	0001d517          	auipc	a0,0x1d
    8000474a:	4a250513          	addi	a0,a0,1186 # 80021be8 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	474080e7          	jalr	1140(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004756:	40dc                	lw	a5,4(s1)
    80004758:	02f05263          	blez	a5,8000477c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000475c:	2785                	addiw	a5,a5,1
    8000475e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004760:	0001d517          	auipc	a0,0x1d
    80004764:	48850513          	addi	a0,a0,1160 # 80021be8 <ftable>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	50e080e7          	jalr	1294(ra) # 80000c76 <release>
  return f;
}
    80004770:	8526                	mv	a0,s1
    80004772:	60e2                	ld	ra,24(sp)
    80004774:	6442                	ld	s0,16(sp)
    80004776:	64a2                	ld	s1,8(sp)
    80004778:	6105                	addi	sp,sp,32
    8000477a:	8082                	ret
    panic("filedup");
    8000477c:	00004517          	auipc	a0,0x4
    80004780:	f1450513          	addi	a0,a0,-236 # 80008690 <syscalls+0x248>
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	da6080e7          	jalr	-602(ra) # 8000052a <panic>

000000008000478c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000478c:	7139                	addi	sp,sp,-64
    8000478e:	fc06                	sd	ra,56(sp)
    80004790:	f822                	sd	s0,48(sp)
    80004792:	f426                	sd	s1,40(sp)
    80004794:	f04a                	sd	s2,32(sp)
    80004796:	ec4e                	sd	s3,24(sp)
    80004798:	e852                	sd	s4,16(sp)
    8000479a:	e456                	sd	s5,8(sp)
    8000479c:	0080                	addi	s0,sp,64
    8000479e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047a0:	0001d517          	auipc	a0,0x1d
    800047a4:	44850513          	addi	a0,a0,1096 # 80021be8 <ftable>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	41a080e7          	jalr	1050(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800047b0:	40dc                	lw	a5,4(s1)
    800047b2:	06f05163          	blez	a5,80004814 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047b6:	37fd                	addiw	a5,a5,-1
    800047b8:	0007871b          	sext.w	a4,a5
    800047bc:	c0dc                	sw	a5,4(s1)
    800047be:	06e04363          	bgtz	a4,80004824 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047c2:	0004a903          	lw	s2,0(s1)
    800047c6:	0094ca83          	lbu	s5,9(s1)
    800047ca:	0104ba03          	ld	s4,16(s1)
    800047ce:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047d2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047d6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047da:	0001d517          	auipc	a0,0x1d
    800047de:	40e50513          	addi	a0,a0,1038 # 80021be8 <ftable>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	494080e7          	jalr	1172(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800047ea:	4785                	li	a5,1
    800047ec:	04f90d63          	beq	s2,a5,80004846 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047f0:	3979                	addiw	s2,s2,-2
    800047f2:	4785                	li	a5,1
    800047f4:	0527e063          	bltu	a5,s2,80004834 <fileclose+0xa8>
    begin_op();
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	ac8080e7          	jalr	-1336(ra) # 800042c0 <begin_op>
    iput(ff.ip);
    80004800:	854e                	mv	a0,s3
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	2a6080e7          	jalr	678(ra) # 80003aa8 <iput>
    end_op();
    8000480a:	00000097          	auipc	ra,0x0
    8000480e:	b36080e7          	jalr	-1226(ra) # 80004340 <end_op>
    80004812:	a00d                	j	80004834 <fileclose+0xa8>
    panic("fileclose");
    80004814:	00004517          	auipc	a0,0x4
    80004818:	e8450513          	addi	a0,a0,-380 # 80008698 <syscalls+0x250>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	d0e080e7          	jalr	-754(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004824:	0001d517          	auipc	a0,0x1d
    80004828:	3c450513          	addi	a0,a0,964 # 80021be8 <ftable>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	44a080e7          	jalr	1098(ra) # 80000c76 <release>
  }
}
    80004834:	70e2                	ld	ra,56(sp)
    80004836:	7442                	ld	s0,48(sp)
    80004838:	74a2                	ld	s1,40(sp)
    8000483a:	7902                	ld	s2,32(sp)
    8000483c:	69e2                	ld	s3,24(sp)
    8000483e:	6a42                	ld	s4,16(sp)
    80004840:	6aa2                	ld	s5,8(sp)
    80004842:	6121                	addi	sp,sp,64
    80004844:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004846:	85d6                	mv	a1,s5
    80004848:	8552                	mv	a0,s4
    8000484a:	00000097          	auipc	ra,0x0
    8000484e:	34c080e7          	jalr	844(ra) # 80004b96 <pipeclose>
    80004852:	b7cd                	j	80004834 <fileclose+0xa8>

0000000080004854 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004854:	715d                	addi	sp,sp,-80
    80004856:	e486                	sd	ra,72(sp)
    80004858:	e0a2                	sd	s0,64(sp)
    8000485a:	fc26                	sd	s1,56(sp)
    8000485c:	f84a                	sd	s2,48(sp)
    8000485e:	f44e                	sd	s3,40(sp)
    80004860:	0880                	addi	s0,sp,80
    80004862:	84aa                	mv	s1,a0
    80004864:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004866:	ffffd097          	auipc	ra,0xffffd
    8000486a:	24a080e7          	jalr	586(ra) # 80001ab0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000486e:	409c                	lw	a5,0(s1)
    80004870:	37f9                	addiw	a5,a5,-2
    80004872:	4705                	li	a4,1
    80004874:	04f76763          	bltu	a4,a5,800048c2 <filestat+0x6e>
    80004878:	892a                	mv	s2,a0
    ilock(f->ip);
    8000487a:	6c88                	ld	a0,24(s1)
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	072080e7          	jalr	114(ra) # 800038ee <ilock>
    stati(f->ip, &st);
    80004884:	fb840593          	addi	a1,s0,-72
    80004888:	6c88                	ld	a0,24(s1)
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	2ee080e7          	jalr	750(ra) # 80003b78 <stati>
    iunlock(f->ip);
    80004892:	6c88                	ld	a0,24(s1)
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	11c080e7          	jalr	284(ra) # 800039b0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000489c:	46e1                	li	a3,24
    8000489e:	fb840613          	addi	a2,s0,-72
    800048a2:	85ce                	mv	a1,s3
    800048a4:	05093503          	ld	a0,80(s2)
    800048a8:	ffffd097          	auipc	ra,0xffffd
    800048ac:	d96080e7          	jalr	-618(ra) # 8000163e <copyout>
    800048b0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048b4:	60a6                	ld	ra,72(sp)
    800048b6:	6406                	ld	s0,64(sp)
    800048b8:	74e2                	ld	s1,56(sp)
    800048ba:	7942                	ld	s2,48(sp)
    800048bc:	79a2                	ld	s3,40(sp)
    800048be:	6161                	addi	sp,sp,80
    800048c0:	8082                	ret
  return -1;
    800048c2:	557d                	li	a0,-1
    800048c4:	bfc5                	j	800048b4 <filestat+0x60>

00000000800048c6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048c6:	7179                	addi	sp,sp,-48
    800048c8:	f406                	sd	ra,40(sp)
    800048ca:	f022                	sd	s0,32(sp)
    800048cc:	ec26                	sd	s1,24(sp)
    800048ce:	e84a                	sd	s2,16(sp)
    800048d0:	e44e                	sd	s3,8(sp)
    800048d2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048d4:	00854783          	lbu	a5,8(a0)
    800048d8:	c3d5                	beqz	a5,8000497c <fileread+0xb6>
    800048da:	84aa                	mv	s1,a0
    800048dc:	89ae                	mv	s3,a1
    800048de:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e0:	411c                	lw	a5,0(a0)
    800048e2:	4705                	li	a4,1
    800048e4:	04e78963          	beq	a5,a4,80004936 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048e8:	470d                	li	a4,3
    800048ea:	04e78d63          	beq	a5,a4,80004944 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048ee:	4709                	li	a4,2
    800048f0:	06e79e63          	bne	a5,a4,8000496c <fileread+0xa6>
    ilock(f->ip);
    800048f4:	6d08                	ld	a0,24(a0)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	ff8080e7          	jalr	-8(ra) # 800038ee <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048fe:	874a                	mv	a4,s2
    80004900:	5094                	lw	a3,32(s1)
    80004902:	864e                	mv	a2,s3
    80004904:	4585                	li	a1,1
    80004906:	6c88                	ld	a0,24(s1)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	29a080e7          	jalr	666(ra) # 80003ba2 <readi>
    80004910:	892a                	mv	s2,a0
    80004912:	00a05563          	blez	a0,8000491c <fileread+0x56>
      f->off += r;
    80004916:	509c                	lw	a5,32(s1)
    80004918:	9fa9                	addw	a5,a5,a0
    8000491a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000491c:	6c88                	ld	a0,24(s1)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	092080e7          	jalr	146(ra) # 800039b0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004926:	854a                	mv	a0,s2
    80004928:	70a2                	ld	ra,40(sp)
    8000492a:	7402                	ld	s0,32(sp)
    8000492c:	64e2                	ld	s1,24(sp)
    8000492e:	6942                	ld	s2,16(sp)
    80004930:	69a2                	ld	s3,8(sp)
    80004932:	6145                	addi	sp,sp,48
    80004934:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004936:	6908                	ld	a0,16(a0)
    80004938:	00000097          	auipc	ra,0x0
    8000493c:	3c0080e7          	jalr	960(ra) # 80004cf8 <piperead>
    80004940:	892a                	mv	s2,a0
    80004942:	b7d5                	j	80004926 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004944:	02451783          	lh	a5,36(a0)
    80004948:	03079693          	slli	a3,a5,0x30
    8000494c:	92c1                	srli	a3,a3,0x30
    8000494e:	4725                	li	a4,9
    80004950:	02d76863          	bltu	a4,a3,80004980 <fileread+0xba>
    80004954:	0792                	slli	a5,a5,0x4
    80004956:	0001d717          	auipc	a4,0x1d
    8000495a:	1f270713          	addi	a4,a4,498 # 80021b48 <devsw>
    8000495e:	97ba                	add	a5,a5,a4
    80004960:	639c                	ld	a5,0(a5)
    80004962:	c38d                	beqz	a5,80004984 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004964:	4505                	li	a0,1
    80004966:	9782                	jalr	a5
    80004968:	892a                	mv	s2,a0
    8000496a:	bf75                	j	80004926 <fileread+0x60>
    panic("fileread");
    8000496c:	00004517          	auipc	a0,0x4
    80004970:	d3c50513          	addi	a0,a0,-708 # 800086a8 <syscalls+0x260>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	bb6080e7          	jalr	-1098(ra) # 8000052a <panic>
    return -1;
    8000497c:	597d                	li	s2,-1
    8000497e:	b765                	j	80004926 <fileread+0x60>
      return -1;
    80004980:	597d                	li	s2,-1
    80004982:	b755                	j	80004926 <fileread+0x60>
    80004984:	597d                	li	s2,-1
    80004986:	b745                	j	80004926 <fileread+0x60>

0000000080004988 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004988:	715d                	addi	sp,sp,-80
    8000498a:	e486                	sd	ra,72(sp)
    8000498c:	e0a2                	sd	s0,64(sp)
    8000498e:	fc26                	sd	s1,56(sp)
    80004990:	f84a                	sd	s2,48(sp)
    80004992:	f44e                	sd	s3,40(sp)
    80004994:	f052                	sd	s4,32(sp)
    80004996:	ec56                	sd	s5,24(sp)
    80004998:	e85a                	sd	s6,16(sp)
    8000499a:	e45e                	sd	s7,8(sp)
    8000499c:	e062                	sd	s8,0(sp)
    8000499e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049a0:	00954783          	lbu	a5,9(a0)
    800049a4:	10078663          	beqz	a5,80004ab0 <filewrite+0x128>
    800049a8:	892a                	mv	s2,a0
    800049aa:	8aae                	mv	s5,a1
    800049ac:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ae:	411c                	lw	a5,0(a0)
    800049b0:	4705                	li	a4,1
    800049b2:	02e78263          	beq	a5,a4,800049d6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049b6:	470d                	li	a4,3
    800049b8:	02e78663          	beq	a5,a4,800049e4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049bc:	4709                	li	a4,2
    800049be:	0ee79163          	bne	a5,a4,80004aa0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049c2:	0ac05d63          	blez	a2,80004a7c <filewrite+0xf4>
    int i = 0;
    800049c6:	4981                	li	s3,0
    800049c8:	6b05                	lui	s6,0x1
    800049ca:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049ce:	6b85                	lui	s7,0x1
    800049d0:	c00b8b9b          	addiw	s7,s7,-1024
    800049d4:	a861                	j	80004a6c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049d6:	6908                	ld	a0,16(a0)
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	22e080e7          	jalr	558(ra) # 80004c06 <pipewrite>
    800049e0:	8a2a                	mv	s4,a0
    800049e2:	a045                	j	80004a82 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049e4:	02451783          	lh	a5,36(a0)
    800049e8:	03079693          	slli	a3,a5,0x30
    800049ec:	92c1                	srli	a3,a3,0x30
    800049ee:	4725                	li	a4,9
    800049f0:	0cd76263          	bltu	a4,a3,80004ab4 <filewrite+0x12c>
    800049f4:	0792                	slli	a5,a5,0x4
    800049f6:	0001d717          	auipc	a4,0x1d
    800049fa:	15270713          	addi	a4,a4,338 # 80021b48 <devsw>
    800049fe:	97ba                	add	a5,a5,a4
    80004a00:	679c                	ld	a5,8(a5)
    80004a02:	cbdd                	beqz	a5,80004ab8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a04:	4505                	li	a0,1
    80004a06:	9782                	jalr	a5
    80004a08:	8a2a                	mv	s4,a0
    80004a0a:	a8a5                	j	80004a82 <filewrite+0xfa>
    80004a0c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	8b0080e7          	jalr	-1872(ra) # 800042c0 <begin_op>
      ilock(f->ip);
    80004a18:	01893503          	ld	a0,24(s2)
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	ed2080e7          	jalr	-302(ra) # 800038ee <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a24:	8762                	mv	a4,s8
    80004a26:	02092683          	lw	a3,32(s2)
    80004a2a:	01598633          	add	a2,s3,s5
    80004a2e:	4585                	li	a1,1
    80004a30:	01893503          	ld	a0,24(s2)
    80004a34:	fffff097          	auipc	ra,0xfffff
    80004a38:	266080e7          	jalr	614(ra) # 80003c9a <writei>
    80004a3c:	84aa                	mv	s1,a0
    80004a3e:	00a05763          	blez	a0,80004a4c <filewrite+0xc4>
        f->off += r;
    80004a42:	02092783          	lw	a5,32(s2)
    80004a46:	9fa9                	addw	a5,a5,a0
    80004a48:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a4c:	01893503          	ld	a0,24(s2)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	f60080e7          	jalr	-160(ra) # 800039b0 <iunlock>
      end_op();
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	8e8080e7          	jalr	-1816(ra) # 80004340 <end_op>

      if(r != n1){
    80004a60:	009c1f63          	bne	s8,s1,80004a7e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a64:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a68:	0149db63          	bge	s3,s4,80004a7e <filewrite+0xf6>
      int n1 = n - i;
    80004a6c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a70:	84be                	mv	s1,a5
    80004a72:	2781                	sext.w	a5,a5
    80004a74:	f8fb5ce3          	bge	s6,a5,80004a0c <filewrite+0x84>
    80004a78:	84de                	mv	s1,s7
    80004a7a:	bf49                	j	80004a0c <filewrite+0x84>
    int i = 0;
    80004a7c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a7e:	013a1f63          	bne	s4,s3,80004a9c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a82:	8552                	mv	a0,s4
    80004a84:	60a6                	ld	ra,72(sp)
    80004a86:	6406                	ld	s0,64(sp)
    80004a88:	74e2                	ld	s1,56(sp)
    80004a8a:	7942                	ld	s2,48(sp)
    80004a8c:	79a2                	ld	s3,40(sp)
    80004a8e:	7a02                	ld	s4,32(sp)
    80004a90:	6ae2                	ld	s5,24(sp)
    80004a92:	6b42                	ld	s6,16(sp)
    80004a94:	6ba2                	ld	s7,8(sp)
    80004a96:	6c02                	ld	s8,0(sp)
    80004a98:	6161                	addi	sp,sp,80
    80004a9a:	8082                	ret
    ret = (i == n ? n : -1);
    80004a9c:	5a7d                	li	s4,-1
    80004a9e:	b7d5                	j	80004a82 <filewrite+0xfa>
    panic("filewrite");
    80004aa0:	00004517          	auipc	a0,0x4
    80004aa4:	c1850513          	addi	a0,a0,-1000 # 800086b8 <syscalls+0x270>
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	a82080e7          	jalr	-1406(ra) # 8000052a <panic>
    return -1;
    80004ab0:	5a7d                	li	s4,-1
    80004ab2:	bfc1                	j	80004a82 <filewrite+0xfa>
      return -1;
    80004ab4:	5a7d                	li	s4,-1
    80004ab6:	b7f1                	j	80004a82 <filewrite+0xfa>
    80004ab8:	5a7d                	li	s4,-1
    80004aba:	b7e1                	j	80004a82 <filewrite+0xfa>

0000000080004abc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004abc:	7179                	addi	sp,sp,-48
    80004abe:	f406                	sd	ra,40(sp)
    80004ac0:	f022                	sd	s0,32(sp)
    80004ac2:	ec26                	sd	s1,24(sp)
    80004ac4:	e84a                	sd	s2,16(sp)
    80004ac6:	e44e                	sd	s3,8(sp)
    80004ac8:	e052                	sd	s4,0(sp)
    80004aca:	1800                	addi	s0,sp,48
    80004acc:	84aa                	mv	s1,a0
    80004ace:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ad0:	0005b023          	sd	zero,0(a1)
    80004ad4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	bf8080e7          	jalr	-1032(ra) # 800046d0 <filealloc>
    80004ae0:	e088                	sd	a0,0(s1)
    80004ae2:	c551                	beqz	a0,80004b6e <pipealloc+0xb2>
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	bec080e7          	jalr	-1044(ra) # 800046d0 <filealloc>
    80004aec:	00aa3023          	sd	a0,0(s4)
    80004af0:	c92d                	beqz	a0,80004b62 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	fe0080e7          	jalr	-32(ra) # 80000ad2 <kalloc>
    80004afa:	892a                	mv	s2,a0
    80004afc:	c125                	beqz	a0,80004b5c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004afe:	4985                	li	s3,1
    80004b00:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b04:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b08:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b0c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b10:	00004597          	auipc	a1,0x4
    80004b14:	bb858593          	addi	a1,a1,-1096 # 800086c8 <syscalls+0x280>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	01a080e7          	jalr	26(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004b20:	609c                	ld	a5,0(s1)
    80004b22:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b26:	609c                	ld	a5,0(s1)
    80004b28:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b2c:	609c                	ld	a5,0(s1)
    80004b2e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b32:	609c                	ld	a5,0(s1)
    80004b34:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b38:	000a3783          	ld	a5,0(s4)
    80004b3c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b40:	000a3783          	ld	a5,0(s4)
    80004b44:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b48:	000a3783          	ld	a5,0(s4)
    80004b4c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b50:	000a3783          	ld	a5,0(s4)
    80004b54:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b58:	4501                	li	a0,0
    80004b5a:	a025                	j	80004b82 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b5c:	6088                	ld	a0,0(s1)
    80004b5e:	e501                	bnez	a0,80004b66 <pipealloc+0xaa>
    80004b60:	a039                	j	80004b6e <pipealloc+0xb2>
    80004b62:	6088                	ld	a0,0(s1)
    80004b64:	c51d                	beqz	a0,80004b92 <pipealloc+0xd6>
    fileclose(*f0);
    80004b66:	00000097          	auipc	ra,0x0
    80004b6a:	c26080e7          	jalr	-986(ra) # 8000478c <fileclose>
  if(*f1)
    80004b6e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b72:	557d                	li	a0,-1
  if(*f1)
    80004b74:	c799                	beqz	a5,80004b82 <pipealloc+0xc6>
    fileclose(*f1);
    80004b76:	853e                	mv	a0,a5
    80004b78:	00000097          	auipc	ra,0x0
    80004b7c:	c14080e7          	jalr	-1004(ra) # 8000478c <fileclose>
  return -1;
    80004b80:	557d                	li	a0,-1
}
    80004b82:	70a2                	ld	ra,40(sp)
    80004b84:	7402                	ld	s0,32(sp)
    80004b86:	64e2                	ld	s1,24(sp)
    80004b88:	6942                	ld	s2,16(sp)
    80004b8a:	69a2                	ld	s3,8(sp)
    80004b8c:	6a02                	ld	s4,0(sp)
    80004b8e:	6145                	addi	sp,sp,48
    80004b90:	8082                	ret
  return -1;
    80004b92:	557d                	li	a0,-1
    80004b94:	b7fd                	j	80004b82 <pipealloc+0xc6>

0000000080004b96 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b96:	1101                	addi	sp,sp,-32
    80004b98:	ec06                	sd	ra,24(sp)
    80004b9a:	e822                	sd	s0,16(sp)
    80004b9c:	e426                	sd	s1,8(sp)
    80004b9e:	e04a                	sd	s2,0(sp)
    80004ba0:	1000                	addi	s0,sp,32
    80004ba2:	84aa                	mv	s1,a0
    80004ba4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	01c080e7          	jalr	28(ra) # 80000bc2 <acquire>
  if(writable){
    80004bae:	02090d63          	beqz	s2,80004be8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bb2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bb6:	21848513          	addi	a0,s1,536
    80004bba:	ffffe097          	auipc	ra,0xffffe
    80004bbe:	888080e7          	jalr	-1912(ra) # 80002442 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bc2:	2204b783          	ld	a5,544(s1)
    80004bc6:	eb95                	bnez	a5,80004bfa <pipeclose+0x64>
    release(&pi->lock);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	0ac080e7          	jalr	172(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	e02080e7          	jalr	-510(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004bdc:	60e2                	ld	ra,24(sp)
    80004bde:	6442                	ld	s0,16(sp)
    80004be0:	64a2                	ld	s1,8(sp)
    80004be2:	6902                	ld	s2,0(sp)
    80004be4:	6105                	addi	sp,sp,32
    80004be6:	8082                	ret
    pi->readopen = 0;
    80004be8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bec:	21c48513          	addi	a0,s1,540
    80004bf0:	ffffe097          	auipc	ra,0xffffe
    80004bf4:	852080e7          	jalr	-1966(ra) # 80002442 <wakeup>
    80004bf8:	b7e9                	j	80004bc2 <pipeclose+0x2c>
    release(&pi->lock);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	07a080e7          	jalr	122(ra) # 80000c76 <release>
}
    80004c04:	bfe1                	j	80004bdc <pipeclose+0x46>

0000000080004c06 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c06:	711d                	addi	sp,sp,-96
    80004c08:	ec86                	sd	ra,88(sp)
    80004c0a:	e8a2                	sd	s0,80(sp)
    80004c0c:	e4a6                	sd	s1,72(sp)
    80004c0e:	e0ca                	sd	s2,64(sp)
    80004c10:	fc4e                	sd	s3,56(sp)
    80004c12:	f852                	sd	s4,48(sp)
    80004c14:	f456                	sd	s5,40(sp)
    80004c16:	f05a                	sd	s6,32(sp)
    80004c18:	ec5e                	sd	s7,24(sp)
    80004c1a:	e862                	sd	s8,16(sp)
    80004c1c:	1080                	addi	s0,sp,96
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	8aae                	mv	s5,a1
    80004c22:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	e8c080e7          	jalr	-372(ra) # 80001ab0 <myproc>
    80004c2c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	f92080e7          	jalr	-110(ra) # 80000bc2 <acquire>
  while(i < n){
    80004c38:	0b405363          	blez	s4,80004cde <pipewrite+0xd8>
  int i = 0;
    80004c3c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c3e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c40:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c44:	21c48b93          	addi	s7,s1,540
    80004c48:	a089                	j	80004c8a <pipewrite+0x84>
      release(&pi->lock);
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	02a080e7          	jalr	42(ra) # 80000c76 <release>
      return -1;
    80004c54:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c56:	854a                	mv	a0,s2
    80004c58:	60e6                	ld	ra,88(sp)
    80004c5a:	6446                	ld	s0,80(sp)
    80004c5c:	64a6                	ld	s1,72(sp)
    80004c5e:	6906                	ld	s2,64(sp)
    80004c60:	79e2                	ld	s3,56(sp)
    80004c62:	7a42                	ld	s4,48(sp)
    80004c64:	7aa2                	ld	s5,40(sp)
    80004c66:	7b02                	ld	s6,32(sp)
    80004c68:	6be2                	ld	s7,24(sp)
    80004c6a:	6c42                	ld	s8,16(sp)
    80004c6c:	6125                	addi	sp,sp,96
    80004c6e:	8082                	ret
      wakeup(&pi->nread);
    80004c70:	8562                	mv	a0,s8
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	7d0080e7          	jalr	2000(ra) # 80002442 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c7a:	85a6                	mv	a1,s1
    80004c7c:	855e                	mv	a0,s7
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	638080e7          	jalr	1592(ra) # 800022b6 <sleep>
  while(i < n){
    80004c86:	05495d63          	bge	s2,s4,80004ce0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004c8a:	2204a783          	lw	a5,544(s1)
    80004c8e:	dfd5                	beqz	a5,80004c4a <pipewrite+0x44>
    80004c90:	0289a783          	lw	a5,40(s3)
    80004c94:	fbdd                	bnez	a5,80004c4a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c96:	2184a783          	lw	a5,536(s1)
    80004c9a:	21c4a703          	lw	a4,540(s1)
    80004c9e:	2007879b          	addiw	a5,a5,512
    80004ca2:	fcf707e3          	beq	a4,a5,80004c70 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ca6:	4685                	li	a3,1
    80004ca8:	01590633          	add	a2,s2,s5
    80004cac:	faf40593          	addi	a1,s0,-81
    80004cb0:	0509b503          	ld	a0,80(s3)
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	a16080e7          	jalr	-1514(ra) # 800016ca <copyin>
    80004cbc:	03650263          	beq	a0,s6,80004ce0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cc0:	21c4a783          	lw	a5,540(s1)
    80004cc4:	0017871b          	addiw	a4,a5,1
    80004cc8:	20e4ae23          	sw	a4,540(s1)
    80004ccc:	1ff7f793          	andi	a5,a5,511
    80004cd0:	97a6                	add	a5,a5,s1
    80004cd2:	faf44703          	lbu	a4,-81(s0)
    80004cd6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cda:	2905                	addiw	s2,s2,1
    80004cdc:	b76d                	j	80004c86 <pipewrite+0x80>
  int i = 0;
    80004cde:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ce0:	21848513          	addi	a0,s1,536
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	75e080e7          	jalr	1886(ra) # 80002442 <wakeup>
  release(&pi->lock);
    80004cec:	8526                	mv	a0,s1
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	f88080e7          	jalr	-120(ra) # 80000c76 <release>
  return i;
    80004cf6:	b785                	j	80004c56 <pipewrite+0x50>

0000000080004cf8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cf8:	715d                	addi	sp,sp,-80
    80004cfa:	e486                	sd	ra,72(sp)
    80004cfc:	e0a2                	sd	s0,64(sp)
    80004cfe:	fc26                	sd	s1,56(sp)
    80004d00:	f84a                	sd	s2,48(sp)
    80004d02:	f44e                	sd	s3,40(sp)
    80004d04:	f052                	sd	s4,32(sp)
    80004d06:	ec56                	sd	s5,24(sp)
    80004d08:	e85a                	sd	s6,16(sp)
    80004d0a:	0880                	addi	s0,sp,80
    80004d0c:	84aa                	mv	s1,a0
    80004d0e:	892e                	mv	s2,a1
    80004d10:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	d9e080e7          	jalr	-610(ra) # 80001ab0 <myproc>
    80004d1a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	ea4080e7          	jalr	-348(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d26:	2184a703          	lw	a4,536(s1)
    80004d2a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d2e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d32:	02f71463          	bne	a4,a5,80004d5a <piperead+0x62>
    80004d36:	2244a783          	lw	a5,548(s1)
    80004d3a:	c385                	beqz	a5,80004d5a <piperead+0x62>
    if(pr->killed){
    80004d3c:	028a2783          	lw	a5,40(s4)
    80004d40:	ebc1                	bnez	a5,80004dd0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d42:	85a6                	mv	a1,s1
    80004d44:	854e                	mv	a0,s3
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	570080e7          	jalr	1392(ra) # 800022b6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d4e:	2184a703          	lw	a4,536(s1)
    80004d52:	21c4a783          	lw	a5,540(s1)
    80004d56:	fef700e3          	beq	a4,a5,80004d36 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d5a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d5e:	05505363          	blez	s5,80004da4 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004d62:	2184a783          	lw	a5,536(s1)
    80004d66:	21c4a703          	lw	a4,540(s1)
    80004d6a:	02f70d63          	beq	a4,a5,80004da4 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d6e:	0017871b          	addiw	a4,a5,1
    80004d72:	20e4ac23          	sw	a4,536(s1)
    80004d76:	1ff7f793          	andi	a5,a5,511
    80004d7a:	97a6                	add	a5,a5,s1
    80004d7c:	0187c783          	lbu	a5,24(a5)
    80004d80:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d84:	4685                	li	a3,1
    80004d86:	fbf40613          	addi	a2,s0,-65
    80004d8a:	85ca                	mv	a1,s2
    80004d8c:	050a3503          	ld	a0,80(s4)
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	8ae080e7          	jalr	-1874(ra) # 8000163e <copyout>
    80004d98:	01650663          	beq	a0,s6,80004da4 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d9c:	2985                	addiw	s3,s3,1
    80004d9e:	0905                	addi	s2,s2,1
    80004da0:	fd3a91e3          	bne	s5,s3,80004d62 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004da4:	21c48513          	addi	a0,s1,540
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	69a080e7          	jalr	1690(ra) # 80002442 <wakeup>
  release(&pi->lock);
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	ec4080e7          	jalr	-316(ra) # 80000c76 <release>
  return i;
}
    80004dba:	854e                	mv	a0,s3
    80004dbc:	60a6                	ld	ra,72(sp)
    80004dbe:	6406                	ld	s0,64(sp)
    80004dc0:	74e2                	ld	s1,56(sp)
    80004dc2:	7942                	ld	s2,48(sp)
    80004dc4:	79a2                	ld	s3,40(sp)
    80004dc6:	7a02                	ld	s4,32(sp)
    80004dc8:	6ae2                	ld	s5,24(sp)
    80004dca:	6b42                	ld	s6,16(sp)
    80004dcc:	6161                	addi	sp,sp,80
    80004dce:	8082                	ret
      release(&pi->lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	ea4080e7          	jalr	-348(ra) # 80000c76 <release>
      return -1;
    80004dda:	59fd                	li	s3,-1
    80004ddc:	bff9                	j	80004dba <piperead+0xc2>

0000000080004dde <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dde:	de010113          	addi	sp,sp,-544
    80004de2:	20113c23          	sd	ra,536(sp)
    80004de6:	20813823          	sd	s0,528(sp)
    80004dea:	20913423          	sd	s1,520(sp)
    80004dee:	21213023          	sd	s2,512(sp)
    80004df2:	ffce                	sd	s3,504(sp)
    80004df4:	fbd2                	sd	s4,496(sp)
    80004df6:	f7d6                	sd	s5,488(sp)
    80004df8:	f3da                	sd	s6,480(sp)
    80004dfa:	efde                	sd	s7,472(sp)
    80004dfc:	ebe2                	sd	s8,464(sp)
    80004dfe:	e7e6                	sd	s9,456(sp)
    80004e00:	e3ea                	sd	s10,448(sp)
    80004e02:	ff6e                	sd	s11,440(sp)
    80004e04:	1400                	addi	s0,sp,544
    80004e06:	892a                	mv	s2,a0
    80004e08:	dea43423          	sd	a0,-536(s0)
    80004e0c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	ca0080e7          	jalr	-864(ra) # 80001ab0 <myproc>
    80004e18:	84aa                	mv	s1,a0

  begin_op();
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	4a6080e7          	jalr	1190(ra) # 800042c0 <begin_op>

  if((ip = namei(path)) == 0){
    80004e22:	854a                	mv	a0,s2
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	280080e7          	jalr	640(ra) # 800040a4 <namei>
    80004e2c:	c93d                	beqz	a0,80004ea2 <exec+0xc4>
    80004e2e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	abe080e7          	jalr	-1346(ra) # 800038ee <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e38:	04000713          	li	a4,64
    80004e3c:	4681                	li	a3,0
    80004e3e:	e4840613          	addi	a2,s0,-440
    80004e42:	4581                	li	a1,0
    80004e44:	8556                	mv	a0,s5
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	d5c080e7          	jalr	-676(ra) # 80003ba2 <readi>
    80004e4e:	04000793          	li	a5,64
    80004e52:	00f51a63          	bne	a0,a5,80004e66 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e56:	e4842703          	lw	a4,-440(s0)
    80004e5a:	464c47b7          	lui	a5,0x464c4
    80004e5e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e62:	04f70663          	beq	a4,a5,80004eae <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e66:	8556                	mv	a0,s5
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	ce8080e7          	jalr	-792(ra) # 80003b50 <iunlockput>
    end_op();
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	4d0080e7          	jalr	1232(ra) # 80004340 <end_op>
  }
  return -1;
    80004e78:	557d                	li	a0,-1
}
    80004e7a:	21813083          	ld	ra,536(sp)
    80004e7e:	21013403          	ld	s0,528(sp)
    80004e82:	20813483          	ld	s1,520(sp)
    80004e86:	20013903          	ld	s2,512(sp)
    80004e8a:	79fe                	ld	s3,504(sp)
    80004e8c:	7a5e                	ld	s4,496(sp)
    80004e8e:	7abe                	ld	s5,488(sp)
    80004e90:	7b1e                	ld	s6,480(sp)
    80004e92:	6bfe                	ld	s7,472(sp)
    80004e94:	6c5e                	ld	s8,464(sp)
    80004e96:	6cbe                	ld	s9,456(sp)
    80004e98:	6d1e                	ld	s10,448(sp)
    80004e9a:	7dfa                	ld	s11,440(sp)
    80004e9c:	22010113          	addi	sp,sp,544
    80004ea0:	8082                	ret
    end_op();
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	49e080e7          	jalr	1182(ra) # 80004340 <end_op>
    return -1;
    80004eaa:	557d                	li	a0,-1
    80004eac:	b7f9                	j	80004e7a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eae:	8526                	mv	a0,s1
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	cc6080e7          	jalr	-826(ra) # 80001b76 <proc_pagetable>
    80004eb8:	8b2a                	mv	s6,a0
    80004eba:	d555                	beqz	a0,80004e66 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ebc:	e6842783          	lw	a5,-408(s0)
    80004ec0:	e8045703          	lhu	a4,-384(s0)
    80004ec4:	c735                	beqz	a4,80004f30 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ec6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ecc:	6a05                	lui	s4,0x1
    80004ece:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ed2:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004ed6:	6d85                	lui	s11,0x1
    80004ed8:	7d7d                	lui	s10,0xfffff
    80004eda:	ac1d                	j	80005110 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004edc:	00003517          	auipc	a0,0x3
    80004ee0:	7f450513          	addi	a0,a0,2036 # 800086d0 <syscalls+0x288>
    80004ee4:	ffffb097          	auipc	ra,0xffffb
    80004ee8:	646080e7          	jalr	1606(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eec:	874a                	mv	a4,s2
    80004eee:	009c86bb          	addw	a3,s9,s1
    80004ef2:	4581                	li	a1,0
    80004ef4:	8556                	mv	a0,s5
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	cac080e7          	jalr	-852(ra) # 80003ba2 <readi>
    80004efe:	2501                	sext.w	a0,a0
    80004f00:	1aa91863          	bne	s2,a0,800050b0 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f04:	009d84bb          	addw	s1,s11,s1
    80004f08:	013d09bb          	addw	s3,s10,s3
    80004f0c:	1f74f263          	bgeu	s1,s7,800050f0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004f10:	02049593          	slli	a1,s1,0x20
    80004f14:	9181                	srli	a1,a1,0x20
    80004f16:	95e2                	add	a1,a1,s8
    80004f18:	855a                	mv	a0,s6
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	132080e7          	jalr	306(ra) # 8000104c <walkaddr>
    80004f22:	862a                	mv	a2,a0
    if(pa == 0)
    80004f24:	dd45                	beqz	a0,80004edc <exec+0xfe>
      n = PGSIZE;
    80004f26:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f28:	fd49f2e3          	bgeu	s3,s4,80004eec <exec+0x10e>
      n = sz - i;
    80004f2c:	894e                	mv	s2,s3
    80004f2e:	bf7d                	j	80004eec <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f30:	4481                	li	s1,0
  iunlockput(ip);
    80004f32:	8556                	mv	a0,s5
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	c1c080e7          	jalr	-996(ra) # 80003b50 <iunlockput>
  end_op();
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	404080e7          	jalr	1028(ra) # 80004340 <end_op>
  p = myproc();
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	b6c080e7          	jalr	-1172(ra) # 80001ab0 <myproc>
    80004f4c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f4e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f52:	6785                	lui	a5,0x1
    80004f54:	17fd                	addi	a5,a5,-1
    80004f56:	94be                	add	s1,s1,a5
    80004f58:	77fd                	lui	a5,0xfffff
    80004f5a:	8fe5                	and	a5,a5,s1
    80004f5c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f60:	6609                	lui	a2,0x2
    80004f62:	963e                	add	a2,a2,a5
    80004f64:	85be                	mv	a1,a5
    80004f66:	855a                	mv	a0,s6
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	486080e7          	jalr	1158(ra) # 800013ee <uvmalloc>
    80004f70:	8c2a                	mv	s8,a0
  ip = 0;
    80004f72:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f74:	12050e63          	beqz	a0,800050b0 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f78:	75f9                	lui	a1,0xffffe
    80004f7a:	95aa                	add	a1,a1,a0
    80004f7c:	855a                	mv	a0,s6
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	68e080e7          	jalr	1678(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004f86:	7afd                	lui	s5,0xfffff
    80004f88:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f8a:	df043783          	ld	a5,-528(s0)
    80004f8e:	6388                	ld	a0,0(a5)
    80004f90:	c925                	beqz	a0,80005000 <exec+0x222>
    80004f92:	e8840993          	addi	s3,s0,-376
    80004f96:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f9a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f9c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	ea4080e7          	jalr	-348(ra) # 80000e42 <strlen>
    80004fa6:	0015079b          	addiw	a5,a0,1
    80004faa:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fae:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fb2:	13596363          	bltu	s2,s5,800050d8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fb6:	df043d83          	ld	s11,-528(s0)
    80004fba:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fbe:	8552                	mv	a0,s4
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	e82080e7          	jalr	-382(ra) # 80000e42 <strlen>
    80004fc8:	0015069b          	addiw	a3,a0,1
    80004fcc:	8652                	mv	a2,s4
    80004fce:	85ca                	mv	a1,s2
    80004fd0:	855a                	mv	a0,s6
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	66c080e7          	jalr	1644(ra) # 8000163e <copyout>
    80004fda:	10054363          	bltz	a0,800050e0 <exec+0x302>
    ustack[argc] = sp;
    80004fde:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fe2:	0485                	addi	s1,s1,1
    80004fe4:	008d8793          	addi	a5,s11,8
    80004fe8:	def43823          	sd	a5,-528(s0)
    80004fec:	008db503          	ld	a0,8(s11)
    80004ff0:	c911                	beqz	a0,80005004 <exec+0x226>
    if(argc >= MAXARG)
    80004ff2:	09a1                	addi	s3,s3,8
    80004ff4:	fb3c95e3          	bne	s9,s3,80004f9e <exec+0x1c0>
  sz = sz1;
    80004ff8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ffc:	4a81                	li	s5,0
    80004ffe:	a84d                	j	800050b0 <exec+0x2d2>
  sp = sz;
    80005000:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005002:	4481                	li	s1,0
  ustack[argc] = 0;
    80005004:	00349793          	slli	a5,s1,0x3
    80005008:	f9040713          	addi	a4,s0,-112
    8000500c:	97ba                	add	a5,a5,a4
    8000500e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005012:	00148693          	addi	a3,s1,1
    80005016:	068e                	slli	a3,a3,0x3
    80005018:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000501c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005020:	01597663          	bgeu	s2,s5,8000502c <exec+0x24e>
  sz = sz1;
    80005024:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005028:	4a81                	li	s5,0
    8000502a:	a059                	j	800050b0 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000502c:	e8840613          	addi	a2,s0,-376
    80005030:	85ca                	mv	a1,s2
    80005032:	855a                	mv	a0,s6
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	60a080e7          	jalr	1546(ra) # 8000163e <copyout>
    8000503c:	0a054663          	bltz	a0,800050e8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005040:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005044:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005048:	de843783          	ld	a5,-536(s0)
    8000504c:	0007c703          	lbu	a4,0(a5)
    80005050:	cf11                	beqz	a4,8000506c <exec+0x28e>
    80005052:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005054:	02f00693          	li	a3,47
    80005058:	a039                	j	80005066 <exec+0x288>
      last = s+1;
    8000505a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000505e:	0785                	addi	a5,a5,1
    80005060:	fff7c703          	lbu	a4,-1(a5)
    80005064:	c701                	beqz	a4,8000506c <exec+0x28e>
    if(*s == '/')
    80005066:	fed71ce3          	bne	a4,a3,8000505e <exec+0x280>
    8000506a:	bfc5                	j	8000505a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000506c:	4641                	li	a2,16
    8000506e:	de843583          	ld	a1,-536(s0)
    80005072:	158b8513          	addi	a0,s7,344
    80005076:	ffffc097          	auipc	ra,0xffffc
    8000507a:	d9a080e7          	jalr	-614(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    8000507e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005082:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005086:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000508a:	058bb783          	ld	a5,88(s7)
    8000508e:	e6043703          	ld	a4,-416(s0)
    80005092:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005094:	058bb783          	ld	a5,88(s7)
    80005098:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000509c:	85ea                	mv	a1,s10
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	b74080e7          	jalr	-1164(ra) # 80001c12 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050a6:	0004851b          	sext.w	a0,s1
    800050aa:	bbc1                	j	80004e7a <exec+0x9c>
    800050ac:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050b0:	df843583          	ld	a1,-520(s0)
    800050b4:	855a                	mv	a0,s6
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	b5c080e7          	jalr	-1188(ra) # 80001c12 <proc_freepagetable>
  if(ip){
    800050be:	da0a94e3          	bnez	s5,80004e66 <exec+0x88>
  return -1;
    800050c2:	557d                	li	a0,-1
    800050c4:	bb5d                	j	80004e7a <exec+0x9c>
    800050c6:	de943c23          	sd	s1,-520(s0)
    800050ca:	b7dd                	j	800050b0 <exec+0x2d2>
    800050cc:	de943c23          	sd	s1,-520(s0)
    800050d0:	b7c5                	j	800050b0 <exec+0x2d2>
    800050d2:	de943c23          	sd	s1,-520(s0)
    800050d6:	bfe9                	j	800050b0 <exec+0x2d2>
  sz = sz1;
    800050d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050dc:	4a81                	li	s5,0
    800050de:	bfc9                	j	800050b0 <exec+0x2d2>
  sz = sz1;
    800050e0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050e4:	4a81                	li	s5,0
    800050e6:	b7e9                	j	800050b0 <exec+0x2d2>
  sz = sz1;
    800050e8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ec:	4a81                	li	s5,0
    800050ee:	b7c9                	j	800050b0 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050f0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050f4:	e0843783          	ld	a5,-504(s0)
    800050f8:	0017869b          	addiw	a3,a5,1
    800050fc:	e0d43423          	sd	a3,-504(s0)
    80005100:	e0043783          	ld	a5,-512(s0)
    80005104:	0387879b          	addiw	a5,a5,56
    80005108:	e8045703          	lhu	a4,-384(s0)
    8000510c:	e2e6d3e3          	bge	a3,a4,80004f32 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005110:	2781                	sext.w	a5,a5
    80005112:	e0f43023          	sd	a5,-512(s0)
    80005116:	03800713          	li	a4,56
    8000511a:	86be                	mv	a3,a5
    8000511c:	e1040613          	addi	a2,s0,-496
    80005120:	4581                	li	a1,0
    80005122:	8556                	mv	a0,s5
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	a7e080e7          	jalr	-1410(ra) # 80003ba2 <readi>
    8000512c:	03800793          	li	a5,56
    80005130:	f6f51ee3          	bne	a0,a5,800050ac <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005134:	e1042783          	lw	a5,-496(s0)
    80005138:	4705                	li	a4,1
    8000513a:	fae79de3          	bne	a5,a4,800050f4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000513e:	e3843603          	ld	a2,-456(s0)
    80005142:	e3043783          	ld	a5,-464(s0)
    80005146:	f8f660e3          	bltu	a2,a5,800050c6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000514a:	e2043783          	ld	a5,-480(s0)
    8000514e:	963e                	add	a2,a2,a5
    80005150:	f6f66ee3          	bltu	a2,a5,800050cc <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005154:	85a6                	mv	a1,s1
    80005156:	855a                	mv	a0,s6
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	296080e7          	jalr	662(ra) # 800013ee <uvmalloc>
    80005160:	dea43c23          	sd	a0,-520(s0)
    80005164:	d53d                	beqz	a0,800050d2 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005166:	e2043c03          	ld	s8,-480(s0)
    8000516a:	de043783          	ld	a5,-544(s0)
    8000516e:	00fc77b3          	and	a5,s8,a5
    80005172:	ff9d                	bnez	a5,800050b0 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005174:	e1842c83          	lw	s9,-488(s0)
    80005178:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000517c:	f60b8ae3          	beqz	s7,800050f0 <exec+0x312>
    80005180:	89de                	mv	s3,s7
    80005182:	4481                	li	s1,0
    80005184:	b371                	j	80004f10 <exec+0x132>

0000000080005186 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005186:	7179                	addi	sp,sp,-48
    80005188:	f406                	sd	ra,40(sp)
    8000518a:	f022                	sd	s0,32(sp)
    8000518c:	ec26                	sd	s1,24(sp)
    8000518e:	e84a                	sd	s2,16(sp)
    80005190:	1800                	addi	s0,sp,48
    80005192:	892e                	mv	s2,a1
    80005194:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005196:	fdc40593          	addi	a1,s0,-36
    8000519a:	ffffe097          	auipc	ra,0xffffe
    8000519e:	b68080e7          	jalr	-1176(ra) # 80002d02 <argint>
    800051a2:	04054063          	bltz	a0,800051e2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051a6:	fdc42703          	lw	a4,-36(s0)
    800051aa:	47bd                	li	a5,15
    800051ac:	02e7ed63          	bltu	a5,a4,800051e6 <argfd+0x60>
    800051b0:	ffffd097          	auipc	ra,0xffffd
    800051b4:	900080e7          	jalr	-1792(ra) # 80001ab0 <myproc>
    800051b8:	fdc42703          	lw	a4,-36(s0)
    800051bc:	01a70793          	addi	a5,a4,26
    800051c0:	078e                	slli	a5,a5,0x3
    800051c2:	953e                	add	a0,a0,a5
    800051c4:	611c                	ld	a5,0(a0)
    800051c6:	c395                	beqz	a5,800051ea <argfd+0x64>
    return -1;
  if(pfd)
    800051c8:	00090463          	beqz	s2,800051d0 <argfd+0x4a>
    *pfd = fd;
    800051cc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051d0:	4501                	li	a0,0
  if(pf)
    800051d2:	c091                	beqz	s1,800051d6 <argfd+0x50>
    *pf = f;
    800051d4:	e09c                	sd	a5,0(s1)
}
    800051d6:	70a2                	ld	ra,40(sp)
    800051d8:	7402                	ld	s0,32(sp)
    800051da:	64e2                	ld	s1,24(sp)
    800051dc:	6942                	ld	s2,16(sp)
    800051de:	6145                	addi	sp,sp,48
    800051e0:	8082                	ret
    return -1;
    800051e2:	557d                	li	a0,-1
    800051e4:	bfcd                	j	800051d6 <argfd+0x50>
    return -1;
    800051e6:	557d                	li	a0,-1
    800051e8:	b7fd                	j	800051d6 <argfd+0x50>
    800051ea:	557d                	li	a0,-1
    800051ec:	b7ed                	j	800051d6 <argfd+0x50>

00000000800051ee <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051ee:	1101                	addi	sp,sp,-32
    800051f0:	ec06                	sd	ra,24(sp)
    800051f2:	e822                	sd	s0,16(sp)
    800051f4:	e426                	sd	s1,8(sp)
    800051f6:	1000                	addi	s0,sp,32
    800051f8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051fa:	ffffd097          	auipc	ra,0xffffd
    800051fe:	8b6080e7          	jalr	-1866(ra) # 80001ab0 <myproc>
    80005202:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005204:	0d050793          	addi	a5,a0,208
    80005208:	4501                	li	a0,0
    8000520a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000520c:	6398                	ld	a4,0(a5)
    8000520e:	cb19                	beqz	a4,80005224 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005210:	2505                	addiw	a0,a0,1
    80005212:	07a1                	addi	a5,a5,8
    80005214:	fed51ce3          	bne	a0,a3,8000520c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005218:	557d                	li	a0,-1
}
    8000521a:	60e2                	ld	ra,24(sp)
    8000521c:	6442                	ld	s0,16(sp)
    8000521e:	64a2                	ld	s1,8(sp)
    80005220:	6105                	addi	sp,sp,32
    80005222:	8082                	ret
      p->ofile[fd] = f;
    80005224:	01a50793          	addi	a5,a0,26
    80005228:	078e                	slli	a5,a5,0x3
    8000522a:	963e                	add	a2,a2,a5
    8000522c:	e204                	sd	s1,0(a2)
      return fd;
    8000522e:	b7f5                	j	8000521a <fdalloc+0x2c>

0000000080005230 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005230:	715d                	addi	sp,sp,-80
    80005232:	e486                	sd	ra,72(sp)
    80005234:	e0a2                	sd	s0,64(sp)
    80005236:	fc26                	sd	s1,56(sp)
    80005238:	f84a                	sd	s2,48(sp)
    8000523a:	f44e                	sd	s3,40(sp)
    8000523c:	f052                	sd	s4,32(sp)
    8000523e:	ec56                	sd	s5,24(sp)
    80005240:	0880                	addi	s0,sp,80
    80005242:	89ae                	mv	s3,a1
    80005244:	8ab2                	mv	s5,a2
    80005246:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005248:	fb040593          	addi	a1,s0,-80
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	e76080e7          	jalr	-394(ra) # 800040c2 <nameiparent>
    80005254:	892a                	mv	s2,a0
    80005256:	12050e63          	beqz	a0,80005392 <create+0x162>
    return 0;

  ilock(dp);
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	694080e7          	jalr	1684(ra) # 800038ee <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005262:	4601                	li	a2,0
    80005264:	fb040593          	addi	a1,s0,-80
    80005268:	854a                	mv	a0,s2
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	b68080e7          	jalr	-1176(ra) # 80003dd2 <dirlookup>
    80005272:	84aa                	mv	s1,a0
    80005274:	c921                	beqz	a0,800052c4 <create+0x94>
    iunlockput(dp);
    80005276:	854a                	mv	a0,s2
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	8d8080e7          	jalr	-1832(ra) # 80003b50 <iunlockput>
    ilock(ip);
    80005280:	8526                	mv	a0,s1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	66c080e7          	jalr	1644(ra) # 800038ee <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000528a:	2981                	sext.w	s3,s3
    8000528c:	4789                	li	a5,2
    8000528e:	02f99463          	bne	s3,a5,800052b6 <create+0x86>
    80005292:	0444d783          	lhu	a5,68(s1)
    80005296:	37f9                	addiw	a5,a5,-2
    80005298:	17c2                	slli	a5,a5,0x30
    8000529a:	93c1                	srli	a5,a5,0x30
    8000529c:	4705                	li	a4,1
    8000529e:	00f76c63          	bltu	a4,a5,800052b6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052a2:	8526                	mv	a0,s1
    800052a4:	60a6                	ld	ra,72(sp)
    800052a6:	6406                	ld	s0,64(sp)
    800052a8:	74e2                	ld	s1,56(sp)
    800052aa:	7942                	ld	s2,48(sp)
    800052ac:	79a2                	ld	s3,40(sp)
    800052ae:	7a02                	ld	s4,32(sp)
    800052b0:	6ae2                	ld	s5,24(sp)
    800052b2:	6161                	addi	sp,sp,80
    800052b4:	8082                	ret
    iunlockput(ip);
    800052b6:	8526                	mv	a0,s1
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	898080e7          	jalr	-1896(ra) # 80003b50 <iunlockput>
    return 0;
    800052c0:	4481                	li	s1,0
    800052c2:	b7c5                	j	800052a2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052c4:	85ce                	mv	a1,s3
    800052c6:	00092503          	lw	a0,0(s2)
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	48c080e7          	jalr	1164(ra) # 80003756 <ialloc>
    800052d2:	84aa                	mv	s1,a0
    800052d4:	c521                	beqz	a0,8000531c <create+0xec>
  ilock(ip);
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	618080e7          	jalr	1560(ra) # 800038ee <ilock>
  ip->major = major;
    800052de:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052e2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052e6:	4a05                	li	s4,1
    800052e8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800052ec:	8526                	mv	a0,s1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	536080e7          	jalr	1334(ra) # 80003824 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052f6:	2981                	sext.w	s3,s3
    800052f8:	03498a63          	beq	s3,s4,8000532c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800052fc:	40d0                	lw	a2,4(s1)
    800052fe:	fb040593          	addi	a1,s0,-80
    80005302:	854a                	mv	a0,s2
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	cde080e7          	jalr	-802(ra) # 80003fe2 <dirlink>
    8000530c:	06054b63          	bltz	a0,80005382 <create+0x152>
  iunlockput(dp);
    80005310:	854a                	mv	a0,s2
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	83e080e7          	jalr	-1986(ra) # 80003b50 <iunlockput>
  return ip;
    8000531a:	b761                	j	800052a2 <create+0x72>
    panic("create: ialloc");
    8000531c:	00003517          	auipc	a0,0x3
    80005320:	3d450513          	addi	a0,a0,980 # 800086f0 <syscalls+0x2a8>
    80005324:	ffffb097          	auipc	ra,0xffffb
    80005328:	206080e7          	jalr	518(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000532c:	04a95783          	lhu	a5,74(s2)
    80005330:	2785                	addiw	a5,a5,1
    80005332:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005336:	854a                	mv	a0,s2
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	4ec080e7          	jalr	1260(ra) # 80003824 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005340:	40d0                	lw	a2,4(s1)
    80005342:	00003597          	auipc	a1,0x3
    80005346:	3be58593          	addi	a1,a1,958 # 80008700 <syscalls+0x2b8>
    8000534a:	8526                	mv	a0,s1
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	c96080e7          	jalr	-874(ra) # 80003fe2 <dirlink>
    80005354:	00054f63          	bltz	a0,80005372 <create+0x142>
    80005358:	00492603          	lw	a2,4(s2)
    8000535c:	00003597          	auipc	a1,0x3
    80005360:	3ac58593          	addi	a1,a1,940 # 80008708 <syscalls+0x2c0>
    80005364:	8526                	mv	a0,s1
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	c7c080e7          	jalr	-900(ra) # 80003fe2 <dirlink>
    8000536e:	f80557e3          	bgez	a0,800052fc <create+0xcc>
      panic("create dots");
    80005372:	00003517          	auipc	a0,0x3
    80005376:	39e50513          	addi	a0,a0,926 # 80008710 <syscalls+0x2c8>
    8000537a:	ffffb097          	auipc	ra,0xffffb
    8000537e:	1b0080e7          	jalr	432(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005382:	00003517          	auipc	a0,0x3
    80005386:	39e50513          	addi	a0,a0,926 # 80008720 <syscalls+0x2d8>
    8000538a:	ffffb097          	auipc	ra,0xffffb
    8000538e:	1a0080e7          	jalr	416(ra) # 8000052a <panic>
    return 0;
    80005392:	84aa                	mv	s1,a0
    80005394:	b739                	j	800052a2 <create+0x72>

0000000080005396 <sys_dup>:
{
    80005396:	7179                	addi	sp,sp,-48
    80005398:	f406                	sd	ra,40(sp)
    8000539a:	f022                	sd	s0,32(sp)
    8000539c:	ec26                	sd	s1,24(sp)
    8000539e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053a0:	fd840613          	addi	a2,s0,-40
    800053a4:	4581                	li	a1,0
    800053a6:	4501                	li	a0,0
    800053a8:	00000097          	auipc	ra,0x0
    800053ac:	dde080e7          	jalr	-546(ra) # 80005186 <argfd>
    return -1;
    800053b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053b2:	02054363          	bltz	a0,800053d8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053b6:	fd843503          	ld	a0,-40(s0)
    800053ba:	00000097          	auipc	ra,0x0
    800053be:	e34080e7          	jalr	-460(ra) # 800051ee <fdalloc>
    800053c2:	84aa                	mv	s1,a0
    return -1;
    800053c4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053c6:	00054963          	bltz	a0,800053d8 <sys_dup+0x42>
  filedup(f);
    800053ca:	fd843503          	ld	a0,-40(s0)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	36c080e7          	jalr	876(ra) # 8000473a <filedup>
  return fd;
    800053d6:	87a6                	mv	a5,s1
}
    800053d8:	853e                	mv	a0,a5
    800053da:	70a2                	ld	ra,40(sp)
    800053dc:	7402                	ld	s0,32(sp)
    800053de:	64e2                	ld	s1,24(sp)
    800053e0:	6145                	addi	sp,sp,48
    800053e2:	8082                	ret

00000000800053e4 <sys_read>:
{
    800053e4:	7179                	addi	sp,sp,-48
    800053e6:	f406                	sd	ra,40(sp)
    800053e8:	f022                	sd	s0,32(sp)
    800053ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ec:	fe840613          	addi	a2,s0,-24
    800053f0:	4581                	li	a1,0
    800053f2:	4501                	li	a0,0
    800053f4:	00000097          	auipc	ra,0x0
    800053f8:	d92080e7          	jalr	-622(ra) # 80005186 <argfd>
    return -1;
    800053fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fe:	04054163          	bltz	a0,80005440 <sys_read+0x5c>
    80005402:	fe440593          	addi	a1,s0,-28
    80005406:	4509                	li	a0,2
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	8fa080e7          	jalr	-1798(ra) # 80002d02 <argint>
    return -1;
    80005410:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005412:	02054763          	bltz	a0,80005440 <sys_read+0x5c>
    80005416:	fd840593          	addi	a1,s0,-40
    8000541a:	4505                	li	a0,1
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	908080e7          	jalr	-1784(ra) # 80002d24 <argaddr>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	00054d63          	bltz	a0,80005440 <sys_read+0x5c>
  return fileread(f, p, n);
    8000542a:	fe442603          	lw	a2,-28(s0)
    8000542e:	fd843583          	ld	a1,-40(s0)
    80005432:	fe843503          	ld	a0,-24(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	490080e7          	jalr	1168(ra) # 800048c6 <fileread>
    8000543e:	87aa                	mv	a5,a0
}
    80005440:	853e                	mv	a0,a5
    80005442:	70a2                	ld	ra,40(sp)
    80005444:	7402                	ld	s0,32(sp)
    80005446:	6145                	addi	sp,sp,48
    80005448:	8082                	ret

000000008000544a <sys_write>:
{
    8000544a:	7179                	addi	sp,sp,-48
    8000544c:	f406                	sd	ra,40(sp)
    8000544e:	f022                	sd	s0,32(sp)
    80005450:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005452:	fe840613          	addi	a2,s0,-24
    80005456:	4581                	li	a1,0
    80005458:	4501                	li	a0,0
    8000545a:	00000097          	auipc	ra,0x0
    8000545e:	d2c080e7          	jalr	-724(ra) # 80005186 <argfd>
    return -1;
    80005462:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005464:	04054163          	bltz	a0,800054a6 <sys_write+0x5c>
    80005468:	fe440593          	addi	a1,s0,-28
    8000546c:	4509                	li	a0,2
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	894080e7          	jalr	-1900(ra) # 80002d02 <argint>
    return -1;
    80005476:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005478:	02054763          	bltz	a0,800054a6 <sys_write+0x5c>
    8000547c:	fd840593          	addi	a1,s0,-40
    80005480:	4505                	li	a0,1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	8a2080e7          	jalr	-1886(ra) # 80002d24 <argaddr>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548c:	00054d63          	bltz	a0,800054a6 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005490:	fe442603          	lw	a2,-28(s0)
    80005494:	fd843583          	ld	a1,-40(s0)
    80005498:	fe843503          	ld	a0,-24(s0)
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	4ec080e7          	jalr	1260(ra) # 80004988 <filewrite>
    800054a4:	87aa                	mv	a5,a0
}
    800054a6:	853e                	mv	a0,a5
    800054a8:	70a2                	ld	ra,40(sp)
    800054aa:	7402                	ld	s0,32(sp)
    800054ac:	6145                	addi	sp,sp,48
    800054ae:	8082                	ret

00000000800054b0 <sys_close>:
{
    800054b0:	1101                	addi	sp,sp,-32
    800054b2:	ec06                	sd	ra,24(sp)
    800054b4:	e822                	sd	s0,16(sp)
    800054b6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054b8:	fe040613          	addi	a2,s0,-32
    800054bc:	fec40593          	addi	a1,s0,-20
    800054c0:	4501                	li	a0,0
    800054c2:	00000097          	auipc	ra,0x0
    800054c6:	cc4080e7          	jalr	-828(ra) # 80005186 <argfd>
    return -1;
    800054ca:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054cc:	02054463          	bltz	a0,800054f4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054d0:	ffffc097          	auipc	ra,0xffffc
    800054d4:	5e0080e7          	jalr	1504(ra) # 80001ab0 <myproc>
    800054d8:	fec42783          	lw	a5,-20(s0)
    800054dc:	07e9                	addi	a5,a5,26
    800054de:	078e                	slli	a5,a5,0x3
    800054e0:	97aa                	add	a5,a5,a0
    800054e2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054e6:	fe043503          	ld	a0,-32(s0)
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	2a2080e7          	jalr	674(ra) # 8000478c <fileclose>
  return 0;
    800054f2:	4781                	li	a5,0
}
    800054f4:	853e                	mv	a0,a5
    800054f6:	60e2                	ld	ra,24(sp)
    800054f8:	6442                	ld	s0,16(sp)
    800054fa:	6105                	addi	sp,sp,32
    800054fc:	8082                	ret

00000000800054fe <sys_fstat>:
{
    800054fe:	1101                	addi	sp,sp,-32
    80005500:	ec06                	sd	ra,24(sp)
    80005502:	e822                	sd	s0,16(sp)
    80005504:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005506:	fe840613          	addi	a2,s0,-24
    8000550a:	4581                	li	a1,0
    8000550c:	4501                	li	a0,0
    8000550e:	00000097          	auipc	ra,0x0
    80005512:	c78080e7          	jalr	-904(ra) # 80005186 <argfd>
    return -1;
    80005516:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005518:	02054563          	bltz	a0,80005542 <sys_fstat+0x44>
    8000551c:	fe040593          	addi	a1,s0,-32
    80005520:	4505                	li	a0,1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	802080e7          	jalr	-2046(ra) # 80002d24 <argaddr>
    return -1;
    8000552a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000552c:	00054b63          	bltz	a0,80005542 <sys_fstat+0x44>
  return filestat(f, st);
    80005530:	fe043583          	ld	a1,-32(s0)
    80005534:	fe843503          	ld	a0,-24(s0)
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	31c080e7          	jalr	796(ra) # 80004854 <filestat>
    80005540:	87aa                	mv	a5,a0
}
    80005542:	853e                	mv	a0,a5
    80005544:	60e2                	ld	ra,24(sp)
    80005546:	6442                	ld	s0,16(sp)
    80005548:	6105                	addi	sp,sp,32
    8000554a:	8082                	ret

000000008000554c <sys_link>:
{
    8000554c:	7169                	addi	sp,sp,-304
    8000554e:	f606                	sd	ra,296(sp)
    80005550:	f222                	sd	s0,288(sp)
    80005552:	ee26                	sd	s1,280(sp)
    80005554:	ea4a                	sd	s2,272(sp)
    80005556:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005558:	08000613          	li	a2,128
    8000555c:	ed040593          	addi	a1,s0,-304
    80005560:	4501                	li	a0,0
    80005562:	ffffd097          	auipc	ra,0xffffd
    80005566:	7e4080e7          	jalr	2020(ra) # 80002d46 <argstr>
    return -1;
    8000556a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000556c:	10054e63          	bltz	a0,80005688 <sys_link+0x13c>
    80005570:	08000613          	li	a2,128
    80005574:	f5040593          	addi	a1,s0,-176
    80005578:	4505                	li	a0,1
    8000557a:	ffffd097          	auipc	ra,0xffffd
    8000557e:	7cc080e7          	jalr	1996(ra) # 80002d46 <argstr>
    return -1;
    80005582:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005584:	10054263          	bltz	a0,80005688 <sys_link+0x13c>
  begin_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	d38080e7          	jalr	-712(ra) # 800042c0 <begin_op>
  if((ip = namei(old)) == 0){
    80005590:	ed040513          	addi	a0,s0,-304
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	b10080e7          	jalr	-1264(ra) # 800040a4 <namei>
    8000559c:	84aa                	mv	s1,a0
    8000559e:	c551                	beqz	a0,8000562a <sys_link+0xde>
  ilock(ip);
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	34e080e7          	jalr	846(ra) # 800038ee <ilock>
  if(ip->type == T_DIR){
    800055a8:	04449703          	lh	a4,68(s1)
    800055ac:	4785                	li	a5,1
    800055ae:	08f70463          	beq	a4,a5,80005636 <sys_link+0xea>
  ip->nlink++;
    800055b2:	04a4d783          	lhu	a5,74(s1)
    800055b6:	2785                	addiw	a5,a5,1
    800055b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055bc:	8526                	mv	a0,s1
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	266080e7          	jalr	614(ra) # 80003824 <iupdate>
  iunlock(ip);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	3e8080e7          	jalr	1000(ra) # 800039b0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055d0:	fd040593          	addi	a1,s0,-48
    800055d4:	f5040513          	addi	a0,s0,-176
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	aea080e7          	jalr	-1302(ra) # 800040c2 <nameiparent>
    800055e0:	892a                	mv	s2,a0
    800055e2:	c935                	beqz	a0,80005656 <sys_link+0x10a>
  ilock(dp);
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	30a080e7          	jalr	778(ra) # 800038ee <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055ec:	00092703          	lw	a4,0(s2)
    800055f0:	409c                	lw	a5,0(s1)
    800055f2:	04f71d63          	bne	a4,a5,8000564c <sys_link+0x100>
    800055f6:	40d0                	lw	a2,4(s1)
    800055f8:	fd040593          	addi	a1,s0,-48
    800055fc:	854a                	mv	a0,s2
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	9e4080e7          	jalr	-1564(ra) # 80003fe2 <dirlink>
    80005606:	04054363          	bltz	a0,8000564c <sys_link+0x100>
  iunlockput(dp);
    8000560a:	854a                	mv	a0,s2
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	544080e7          	jalr	1348(ra) # 80003b50 <iunlockput>
  iput(ip);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	492080e7          	jalr	1170(ra) # 80003aa8 <iput>
  end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	d22080e7          	jalr	-734(ra) # 80004340 <end_op>
  return 0;
    80005626:	4781                	li	a5,0
    80005628:	a085                	j	80005688 <sys_link+0x13c>
    end_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	d16080e7          	jalr	-746(ra) # 80004340 <end_op>
    return -1;
    80005632:	57fd                	li	a5,-1
    80005634:	a891                	j	80005688 <sys_link+0x13c>
    iunlockput(ip);
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	518080e7          	jalr	1304(ra) # 80003b50 <iunlockput>
    end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	d00080e7          	jalr	-768(ra) # 80004340 <end_op>
    return -1;
    80005648:	57fd                	li	a5,-1
    8000564a:	a83d                	j	80005688 <sys_link+0x13c>
    iunlockput(dp);
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	502080e7          	jalr	1282(ra) # 80003b50 <iunlockput>
  ilock(ip);
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	296080e7          	jalr	662(ra) # 800038ee <ilock>
  ip->nlink--;
    80005660:	04a4d783          	lhu	a5,74(s1)
    80005664:	37fd                	addiw	a5,a5,-1
    80005666:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	1b8080e7          	jalr	440(ra) # 80003824 <iupdate>
  iunlockput(ip);
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	4da080e7          	jalr	1242(ra) # 80003b50 <iunlockput>
  end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	cc2080e7          	jalr	-830(ra) # 80004340 <end_op>
  return -1;
    80005686:	57fd                	li	a5,-1
}
    80005688:	853e                	mv	a0,a5
    8000568a:	70b2                	ld	ra,296(sp)
    8000568c:	7412                	ld	s0,288(sp)
    8000568e:	64f2                	ld	s1,280(sp)
    80005690:	6952                	ld	s2,272(sp)
    80005692:	6155                	addi	sp,sp,304
    80005694:	8082                	ret

0000000080005696 <sys_unlink>:
{
    80005696:	7151                	addi	sp,sp,-240
    80005698:	f586                	sd	ra,232(sp)
    8000569a:	f1a2                	sd	s0,224(sp)
    8000569c:	eda6                	sd	s1,216(sp)
    8000569e:	e9ca                	sd	s2,208(sp)
    800056a0:	e5ce                	sd	s3,200(sp)
    800056a2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056a4:	08000613          	li	a2,128
    800056a8:	f3040593          	addi	a1,s0,-208
    800056ac:	4501                	li	a0,0
    800056ae:	ffffd097          	auipc	ra,0xffffd
    800056b2:	698080e7          	jalr	1688(ra) # 80002d46 <argstr>
    800056b6:	18054163          	bltz	a0,80005838 <sys_unlink+0x1a2>
  begin_op();
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	c06080e7          	jalr	-1018(ra) # 800042c0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056c2:	fb040593          	addi	a1,s0,-80
    800056c6:	f3040513          	addi	a0,s0,-208
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	9f8080e7          	jalr	-1544(ra) # 800040c2 <nameiparent>
    800056d2:	84aa                	mv	s1,a0
    800056d4:	c979                	beqz	a0,800057aa <sys_unlink+0x114>
  ilock(dp);
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	218080e7          	jalr	536(ra) # 800038ee <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056de:	00003597          	auipc	a1,0x3
    800056e2:	02258593          	addi	a1,a1,34 # 80008700 <syscalls+0x2b8>
    800056e6:	fb040513          	addi	a0,s0,-80
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	6ce080e7          	jalr	1742(ra) # 80003db8 <namecmp>
    800056f2:	14050a63          	beqz	a0,80005846 <sys_unlink+0x1b0>
    800056f6:	00003597          	auipc	a1,0x3
    800056fa:	01258593          	addi	a1,a1,18 # 80008708 <syscalls+0x2c0>
    800056fe:	fb040513          	addi	a0,s0,-80
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	6b6080e7          	jalr	1718(ra) # 80003db8 <namecmp>
    8000570a:	12050e63          	beqz	a0,80005846 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000570e:	f2c40613          	addi	a2,s0,-212
    80005712:	fb040593          	addi	a1,s0,-80
    80005716:	8526                	mv	a0,s1
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	6ba080e7          	jalr	1722(ra) # 80003dd2 <dirlookup>
    80005720:	892a                	mv	s2,a0
    80005722:	12050263          	beqz	a0,80005846 <sys_unlink+0x1b0>
  ilock(ip);
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	1c8080e7          	jalr	456(ra) # 800038ee <ilock>
  if(ip->nlink < 1)
    8000572e:	04a91783          	lh	a5,74(s2)
    80005732:	08f05263          	blez	a5,800057b6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005736:	04491703          	lh	a4,68(s2)
    8000573a:	4785                	li	a5,1
    8000573c:	08f70563          	beq	a4,a5,800057c6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005740:	4641                	li	a2,16
    80005742:	4581                	li	a1,0
    80005744:	fc040513          	addi	a0,s0,-64
    80005748:	ffffb097          	auipc	ra,0xffffb
    8000574c:	576080e7          	jalr	1398(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005750:	4741                	li	a4,16
    80005752:	f2c42683          	lw	a3,-212(s0)
    80005756:	fc040613          	addi	a2,s0,-64
    8000575a:	4581                	li	a1,0
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	53c080e7          	jalr	1340(ra) # 80003c9a <writei>
    80005766:	47c1                	li	a5,16
    80005768:	0af51563          	bne	a0,a5,80005812 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000576c:	04491703          	lh	a4,68(s2)
    80005770:	4785                	li	a5,1
    80005772:	0af70863          	beq	a4,a5,80005822 <sys_unlink+0x18c>
  iunlockput(dp);
    80005776:	8526                	mv	a0,s1
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	3d8080e7          	jalr	984(ra) # 80003b50 <iunlockput>
  ip->nlink--;
    80005780:	04a95783          	lhu	a5,74(s2)
    80005784:	37fd                	addiw	a5,a5,-1
    80005786:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000578a:	854a                	mv	a0,s2
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	098080e7          	jalr	152(ra) # 80003824 <iupdate>
  iunlockput(ip);
    80005794:	854a                	mv	a0,s2
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	3ba080e7          	jalr	954(ra) # 80003b50 <iunlockput>
  end_op();
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	ba2080e7          	jalr	-1118(ra) # 80004340 <end_op>
  return 0;
    800057a6:	4501                	li	a0,0
    800057a8:	a84d                	j	8000585a <sys_unlink+0x1c4>
    end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	b96080e7          	jalr	-1130(ra) # 80004340 <end_op>
    return -1;
    800057b2:	557d                	li	a0,-1
    800057b4:	a05d                	j	8000585a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057b6:	00003517          	auipc	a0,0x3
    800057ba:	f7a50513          	addi	a0,a0,-134 # 80008730 <syscalls+0x2e8>
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	d6c080e7          	jalr	-660(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057c6:	04c92703          	lw	a4,76(s2)
    800057ca:	02000793          	li	a5,32
    800057ce:	f6e7f9e3          	bgeu	a5,a4,80005740 <sys_unlink+0xaa>
    800057d2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057d6:	4741                	li	a4,16
    800057d8:	86ce                	mv	a3,s3
    800057da:	f1840613          	addi	a2,s0,-232
    800057de:	4581                	li	a1,0
    800057e0:	854a                	mv	a0,s2
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	3c0080e7          	jalr	960(ra) # 80003ba2 <readi>
    800057ea:	47c1                	li	a5,16
    800057ec:	00f51b63          	bne	a0,a5,80005802 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057f0:	f1845783          	lhu	a5,-232(s0)
    800057f4:	e7a1                	bnez	a5,8000583c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057f6:	29c1                	addiw	s3,s3,16
    800057f8:	04c92783          	lw	a5,76(s2)
    800057fc:	fcf9ede3          	bltu	s3,a5,800057d6 <sys_unlink+0x140>
    80005800:	b781                	j	80005740 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005802:	00003517          	auipc	a0,0x3
    80005806:	f4650513          	addi	a0,a0,-186 # 80008748 <syscalls+0x300>
    8000580a:	ffffb097          	auipc	ra,0xffffb
    8000580e:	d20080e7          	jalr	-736(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005812:	00003517          	auipc	a0,0x3
    80005816:	f4e50513          	addi	a0,a0,-178 # 80008760 <syscalls+0x318>
    8000581a:	ffffb097          	auipc	ra,0xffffb
    8000581e:	d10080e7          	jalr	-752(ra) # 8000052a <panic>
    dp->nlink--;
    80005822:	04a4d783          	lhu	a5,74(s1)
    80005826:	37fd                	addiw	a5,a5,-1
    80005828:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	ff6080e7          	jalr	-10(ra) # 80003824 <iupdate>
    80005836:	b781                	j	80005776 <sys_unlink+0xe0>
    return -1;
    80005838:	557d                	li	a0,-1
    8000583a:	a005                	j	8000585a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000583c:	854a                	mv	a0,s2
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	312080e7          	jalr	786(ra) # 80003b50 <iunlockput>
  iunlockput(dp);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	308080e7          	jalr	776(ra) # 80003b50 <iunlockput>
  end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	af0080e7          	jalr	-1296(ra) # 80004340 <end_op>
  return -1;
    80005858:	557d                	li	a0,-1
}
    8000585a:	70ae                	ld	ra,232(sp)
    8000585c:	740e                	ld	s0,224(sp)
    8000585e:	64ee                	ld	s1,216(sp)
    80005860:	694e                	ld	s2,208(sp)
    80005862:	69ae                	ld	s3,200(sp)
    80005864:	616d                	addi	sp,sp,240
    80005866:	8082                	ret

0000000080005868 <sys_open>:

uint64
sys_open(void)
{
    80005868:	7131                	addi	sp,sp,-192
    8000586a:	fd06                	sd	ra,184(sp)
    8000586c:	f922                	sd	s0,176(sp)
    8000586e:	f526                	sd	s1,168(sp)
    80005870:	f14a                	sd	s2,160(sp)
    80005872:	ed4e                	sd	s3,152(sp)
    80005874:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005876:	08000613          	li	a2,128
    8000587a:	f5040593          	addi	a1,s0,-176
    8000587e:	4501                	li	a0,0
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	4c6080e7          	jalr	1222(ra) # 80002d46 <argstr>
    return -1;
    80005888:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000588a:	0c054163          	bltz	a0,8000594c <sys_open+0xe4>
    8000588e:	f4c40593          	addi	a1,s0,-180
    80005892:	4505                	li	a0,1
    80005894:	ffffd097          	auipc	ra,0xffffd
    80005898:	46e080e7          	jalr	1134(ra) # 80002d02 <argint>
    8000589c:	0a054863          	bltz	a0,8000594c <sys_open+0xe4>

  begin_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	a20080e7          	jalr	-1504(ra) # 800042c0 <begin_op>

  if(omode & O_CREATE){
    800058a8:	f4c42783          	lw	a5,-180(s0)
    800058ac:	2007f793          	andi	a5,a5,512
    800058b0:	cbdd                	beqz	a5,80005966 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058b2:	4681                	li	a3,0
    800058b4:	4601                	li	a2,0
    800058b6:	4589                	li	a1,2
    800058b8:	f5040513          	addi	a0,s0,-176
    800058bc:	00000097          	auipc	ra,0x0
    800058c0:	974080e7          	jalr	-1676(ra) # 80005230 <create>
    800058c4:	892a                	mv	s2,a0
    if(ip == 0){
    800058c6:	c959                	beqz	a0,8000595c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058c8:	04491703          	lh	a4,68(s2)
    800058cc:	478d                	li	a5,3
    800058ce:	00f71763          	bne	a4,a5,800058dc <sys_open+0x74>
    800058d2:	04695703          	lhu	a4,70(s2)
    800058d6:	47a5                	li	a5,9
    800058d8:	0ce7ec63          	bltu	a5,a4,800059b0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	df4080e7          	jalr	-524(ra) # 800046d0 <filealloc>
    800058e4:	89aa                	mv	s3,a0
    800058e6:	10050263          	beqz	a0,800059ea <sys_open+0x182>
    800058ea:	00000097          	auipc	ra,0x0
    800058ee:	904080e7          	jalr	-1788(ra) # 800051ee <fdalloc>
    800058f2:	84aa                	mv	s1,a0
    800058f4:	0e054663          	bltz	a0,800059e0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058f8:	04491703          	lh	a4,68(s2)
    800058fc:	478d                	li	a5,3
    800058fe:	0cf70463          	beq	a4,a5,800059c6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005902:	4789                	li	a5,2
    80005904:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005908:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000590c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005910:	f4c42783          	lw	a5,-180(s0)
    80005914:	0017c713          	xori	a4,a5,1
    80005918:	8b05                	andi	a4,a4,1
    8000591a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000591e:	0037f713          	andi	a4,a5,3
    80005922:	00e03733          	snez	a4,a4
    80005926:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000592a:	4007f793          	andi	a5,a5,1024
    8000592e:	c791                	beqz	a5,8000593a <sys_open+0xd2>
    80005930:	04491703          	lh	a4,68(s2)
    80005934:	4789                	li	a5,2
    80005936:	08f70f63          	beq	a4,a5,800059d4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000593a:	854a                	mv	a0,s2
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	074080e7          	jalr	116(ra) # 800039b0 <iunlock>
  end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	9fc080e7          	jalr	-1540(ra) # 80004340 <end_op>

  return fd;
}
    8000594c:	8526                	mv	a0,s1
    8000594e:	70ea                	ld	ra,184(sp)
    80005950:	744a                	ld	s0,176(sp)
    80005952:	74aa                	ld	s1,168(sp)
    80005954:	790a                	ld	s2,160(sp)
    80005956:	69ea                	ld	s3,152(sp)
    80005958:	6129                	addi	sp,sp,192
    8000595a:	8082                	ret
      end_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	9e4080e7          	jalr	-1564(ra) # 80004340 <end_op>
      return -1;
    80005964:	b7e5                	j	8000594c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005966:	f5040513          	addi	a0,s0,-176
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	73a080e7          	jalr	1850(ra) # 800040a4 <namei>
    80005972:	892a                	mv	s2,a0
    80005974:	c905                	beqz	a0,800059a4 <sys_open+0x13c>
    ilock(ip);
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	f78080e7          	jalr	-136(ra) # 800038ee <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000597e:	04491703          	lh	a4,68(s2)
    80005982:	4785                	li	a5,1
    80005984:	f4f712e3          	bne	a4,a5,800058c8 <sys_open+0x60>
    80005988:	f4c42783          	lw	a5,-180(s0)
    8000598c:	dba1                	beqz	a5,800058dc <sys_open+0x74>
      iunlockput(ip);
    8000598e:	854a                	mv	a0,s2
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	1c0080e7          	jalr	448(ra) # 80003b50 <iunlockput>
      end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	9a8080e7          	jalr	-1624(ra) # 80004340 <end_op>
      return -1;
    800059a0:	54fd                	li	s1,-1
    800059a2:	b76d                	j	8000594c <sys_open+0xe4>
      end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	99c080e7          	jalr	-1636(ra) # 80004340 <end_op>
      return -1;
    800059ac:	54fd                	li	s1,-1
    800059ae:	bf79                	j	8000594c <sys_open+0xe4>
    iunlockput(ip);
    800059b0:	854a                	mv	a0,s2
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	19e080e7          	jalr	414(ra) # 80003b50 <iunlockput>
    end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	986080e7          	jalr	-1658(ra) # 80004340 <end_op>
    return -1;
    800059c2:	54fd                	li	s1,-1
    800059c4:	b761                	j	8000594c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059c6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059ca:	04691783          	lh	a5,70(s2)
    800059ce:	02f99223          	sh	a5,36(s3)
    800059d2:	bf2d                	j	8000590c <sys_open+0xa4>
    itrunc(ip);
    800059d4:	854a                	mv	a0,s2
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	026080e7          	jalr	38(ra) # 800039fc <itrunc>
    800059de:	bfb1                	j	8000593a <sys_open+0xd2>
      fileclose(f);
    800059e0:	854e                	mv	a0,s3
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	daa080e7          	jalr	-598(ra) # 8000478c <fileclose>
    iunlockput(ip);
    800059ea:	854a                	mv	a0,s2
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	164080e7          	jalr	356(ra) # 80003b50 <iunlockput>
    end_op();
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	94c080e7          	jalr	-1716(ra) # 80004340 <end_op>
    return -1;
    800059fc:	54fd                	li	s1,-1
    800059fe:	b7b9                	j	8000594c <sys_open+0xe4>

0000000080005a00 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a00:	7175                	addi	sp,sp,-144
    80005a02:	e506                	sd	ra,136(sp)
    80005a04:	e122                	sd	s0,128(sp)
    80005a06:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	8b8080e7          	jalr	-1864(ra) # 800042c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a10:	08000613          	li	a2,128
    80005a14:	f7040593          	addi	a1,s0,-144
    80005a18:	4501                	li	a0,0
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	32c080e7          	jalr	812(ra) # 80002d46 <argstr>
    80005a22:	02054963          	bltz	a0,80005a54 <sys_mkdir+0x54>
    80005a26:	4681                	li	a3,0
    80005a28:	4601                	li	a2,0
    80005a2a:	4585                	li	a1,1
    80005a2c:	f7040513          	addi	a0,s0,-144
    80005a30:	00000097          	auipc	ra,0x0
    80005a34:	800080e7          	jalr	-2048(ra) # 80005230 <create>
    80005a38:	cd11                	beqz	a0,80005a54 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	116080e7          	jalr	278(ra) # 80003b50 <iunlockput>
  end_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	8fe080e7          	jalr	-1794(ra) # 80004340 <end_op>
  return 0;
    80005a4a:	4501                	li	a0,0
}
    80005a4c:	60aa                	ld	ra,136(sp)
    80005a4e:	640a                	ld	s0,128(sp)
    80005a50:	6149                	addi	sp,sp,144
    80005a52:	8082                	ret
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	8ec080e7          	jalr	-1812(ra) # 80004340 <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
    80005a5e:	b7fd                	j	80005a4c <sys_mkdir+0x4c>

0000000080005a60 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a60:	7135                	addi	sp,sp,-160
    80005a62:	ed06                	sd	ra,152(sp)
    80005a64:	e922                	sd	s0,144(sp)
    80005a66:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	858080e7          	jalr	-1960(ra) # 800042c0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a70:	08000613          	li	a2,128
    80005a74:	f7040593          	addi	a1,s0,-144
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	2cc080e7          	jalr	716(ra) # 80002d46 <argstr>
    80005a82:	04054a63          	bltz	a0,80005ad6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a86:	f6c40593          	addi	a1,s0,-148
    80005a8a:	4505                	li	a0,1
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	276080e7          	jalr	630(ra) # 80002d02 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a94:	04054163          	bltz	a0,80005ad6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a98:	f6840593          	addi	a1,s0,-152
    80005a9c:	4509                	li	a0,2
    80005a9e:	ffffd097          	auipc	ra,0xffffd
    80005aa2:	264080e7          	jalr	612(ra) # 80002d02 <argint>
     argint(1, &major) < 0 ||
    80005aa6:	02054863          	bltz	a0,80005ad6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005aaa:	f6841683          	lh	a3,-152(s0)
    80005aae:	f6c41603          	lh	a2,-148(s0)
    80005ab2:	458d                	li	a1,3
    80005ab4:	f7040513          	addi	a0,s0,-144
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	778080e7          	jalr	1912(ra) # 80005230 <create>
     argint(2, &minor) < 0 ||
    80005ac0:	c919                	beqz	a0,80005ad6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	08e080e7          	jalr	142(ra) # 80003b50 <iunlockput>
  end_op();
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	876080e7          	jalr	-1930(ra) # 80004340 <end_op>
  return 0;
    80005ad2:	4501                	li	a0,0
    80005ad4:	a031                	j	80005ae0 <sys_mknod+0x80>
    end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	86a080e7          	jalr	-1942(ra) # 80004340 <end_op>
    return -1;
    80005ade:	557d                	li	a0,-1
}
    80005ae0:	60ea                	ld	ra,152(sp)
    80005ae2:	644a                	ld	s0,144(sp)
    80005ae4:	610d                	addi	sp,sp,160
    80005ae6:	8082                	ret

0000000080005ae8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ae8:	7135                	addi	sp,sp,-160
    80005aea:	ed06                	sd	ra,152(sp)
    80005aec:	e922                	sd	s0,144(sp)
    80005aee:	e526                	sd	s1,136(sp)
    80005af0:	e14a                	sd	s2,128(sp)
    80005af2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005af4:	ffffc097          	auipc	ra,0xffffc
    80005af8:	fbc080e7          	jalr	-68(ra) # 80001ab0 <myproc>
    80005afc:	892a                	mv	s2,a0
  
  begin_op();
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	7c2080e7          	jalr	1986(ra) # 800042c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b06:	08000613          	li	a2,128
    80005b0a:	f6040593          	addi	a1,s0,-160
    80005b0e:	4501                	li	a0,0
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	236080e7          	jalr	566(ra) # 80002d46 <argstr>
    80005b18:	04054b63          	bltz	a0,80005b6e <sys_chdir+0x86>
    80005b1c:	f6040513          	addi	a0,s0,-160
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	584080e7          	jalr	1412(ra) # 800040a4 <namei>
    80005b28:	84aa                	mv	s1,a0
    80005b2a:	c131                	beqz	a0,80005b6e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	dc2080e7          	jalr	-574(ra) # 800038ee <ilock>
  if(ip->type != T_DIR){
    80005b34:	04449703          	lh	a4,68(s1)
    80005b38:	4785                	li	a5,1
    80005b3a:	04f71063          	bne	a4,a5,80005b7a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	e70080e7          	jalr	-400(ra) # 800039b0 <iunlock>
  iput(p->cwd);
    80005b48:	15093503          	ld	a0,336(s2)
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	f5c080e7          	jalr	-164(ra) # 80003aa8 <iput>
  end_op();
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	7ec080e7          	jalr	2028(ra) # 80004340 <end_op>
  p->cwd = ip;
    80005b5c:	14993823          	sd	s1,336(s2)
  return 0;
    80005b60:	4501                	li	a0,0
}
    80005b62:	60ea                	ld	ra,152(sp)
    80005b64:	644a                	ld	s0,144(sp)
    80005b66:	64aa                	ld	s1,136(sp)
    80005b68:	690a                	ld	s2,128(sp)
    80005b6a:	610d                	addi	sp,sp,160
    80005b6c:	8082                	ret
    end_op();
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	7d2080e7          	jalr	2002(ra) # 80004340 <end_op>
    return -1;
    80005b76:	557d                	li	a0,-1
    80005b78:	b7ed                	j	80005b62 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	fd4080e7          	jalr	-44(ra) # 80003b50 <iunlockput>
    end_op();
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	7bc080e7          	jalr	1980(ra) # 80004340 <end_op>
    return -1;
    80005b8c:	557d                	li	a0,-1
    80005b8e:	bfd1                	j	80005b62 <sys_chdir+0x7a>

0000000080005b90 <sys_exec>:

uint64
sys_exec(void)
{
    80005b90:	7145                	addi	sp,sp,-464
    80005b92:	e786                	sd	ra,456(sp)
    80005b94:	e3a2                	sd	s0,448(sp)
    80005b96:	ff26                	sd	s1,440(sp)
    80005b98:	fb4a                	sd	s2,432(sp)
    80005b9a:	f74e                	sd	s3,424(sp)
    80005b9c:	f352                	sd	s4,416(sp)
    80005b9e:	ef56                	sd	s5,408(sp)
    80005ba0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ba2:	08000613          	li	a2,128
    80005ba6:	f4040593          	addi	a1,s0,-192
    80005baa:	4501                	li	a0,0
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	19a080e7          	jalr	410(ra) # 80002d46 <argstr>
    return -1;
    80005bb4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bb6:	0c054a63          	bltz	a0,80005c8a <sys_exec+0xfa>
    80005bba:	e3840593          	addi	a1,s0,-456
    80005bbe:	4505                	li	a0,1
    80005bc0:	ffffd097          	auipc	ra,0xffffd
    80005bc4:	164080e7          	jalr	356(ra) # 80002d24 <argaddr>
    80005bc8:	0c054163          	bltz	a0,80005c8a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bcc:	10000613          	li	a2,256
    80005bd0:	4581                	li	a1,0
    80005bd2:	e4040513          	addi	a0,s0,-448
    80005bd6:	ffffb097          	auipc	ra,0xffffb
    80005bda:	0e8080e7          	jalr	232(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bde:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005be2:	89a6                	mv	s3,s1
    80005be4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005be6:	02000a13          	li	s4,32
    80005bea:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bee:	00391793          	slli	a5,s2,0x3
    80005bf2:	e3040593          	addi	a1,s0,-464
    80005bf6:	e3843503          	ld	a0,-456(s0)
    80005bfa:	953e                	add	a0,a0,a5
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	06c080e7          	jalr	108(ra) # 80002c68 <fetchaddr>
    80005c04:	02054a63          	bltz	a0,80005c38 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c08:	e3043783          	ld	a5,-464(s0)
    80005c0c:	c3b9                	beqz	a5,80005c52 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c0e:	ffffb097          	auipc	ra,0xffffb
    80005c12:	ec4080e7          	jalr	-316(ra) # 80000ad2 <kalloc>
    80005c16:	85aa                	mv	a1,a0
    80005c18:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c1c:	cd11                	beqz	a0,80005c38 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c1e:	6605                	lui	a2,0x1
    80005c20:	e3043503          	ld	a0,-464(s0)
    80005c24:	ffffd097          	auipc	ra,0xffffd
    80005c28:	096080e7          	jalr	150(ra) # 80002cba <fetchstr>
    80005c2c:	00054663          	bltz	a0,80005c38 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c30:	0905                	addi	s2,s2,1
    80005c32:	09a1                	addi	s3,s3,8
    80005c34:	fb491be3          	bne	s2,s4,80005bea <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c38:	10048913          	addi	s2,s1,256
    80005c3c:	6088                	ld	a0,0(s1)
    80005c3e:	c529                	beqz	a0,80005c88 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c40:	ffffb097          	auipc	ra,0xffffb
    80005c44:	d96080e7          	jalr	-618(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c48:	04a1                	addi	s1,s1,8
    80005c4a:	ff2499e3          	bne	s1,s2,80005c3c <sys_exec+0xac>
  return -1;
    80005c4e:	597d                	li	s2,-1
    80005c50:	a82d                	j	80005c8a <sys_exec+0xfa>
      argv[i] = 0;
    80005c52:	0a8e                	slli	s5,s5,0x3
    80005c54:	fc040793          	addi	a5,s0,-64
    80005c58:	9abe                	add	s5,s5,a5
    80005c5a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005c5e:	e4040593          	addi	a1,s0,-448
    80005c62:	f4040513          	addi	a0,s0,-192
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	178080e7          	jalr	376(ra) # 80004dde <exec>
    80005c6e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c70:	10048993          	addi	s3,s1,256
    80005c74:	6088                	ld	a0,0(s1)
    80005c76:	c911                	beqz	a0,80005c8a <sys_exec+0xfa>
    kfree(argv[i]);
    80005c78:	ffffb097          	auipc	ra,0xffffb
    80005c7c:	d5e080e7          	jalr	-674(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c80:	04a1                	addi	s1,s1,8
    80005c82:	ff3499e3          	bne	s1,s3,80005c74 <sys_exec+0xe4>
    80005c86:	a011                	j	80005c8a <sys_exec+0xfa>
  return -1;
    80005c88:	597d                	li	s2,-1
}
    80005c8a:	854a                	mv	a0,s2
    80005c8c:	60be                	ld	ra,456(sp)
    80005c8e:	641e                	ld	s0,448(sp)
    80005c90:	74fa                	ld	s1,440(sp)
    80005c92:	795a                	ld	s2,432(sp)
    80005c94:	79ba                	ld	s3,424(sp)
    80005c96:	7a1a                	ld	s4,416(sp)
    80005c98:	6afa                	ld	s5,408(sp)
    80005c9a:	6179                	addi	sp,sp,464
    80005c9c:	8082                	ret

0000000080005c9e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c9e:	7139                	addi	sp,sp,-64
    80005ca0:	fc06                	sd	ra,56(sp)
    80005ca2:	f822                	sd	s0,48(sp)
    80005ca4:	f426                	sd	s1,40(sp)
    80005ca6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	e08080e7          	jalr	-504(ra) # 80001ab0 <myproc>
    80005cb0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cb2:	fd840593          	addi	a1,s0,-40
    80005cb6:	4501                	li	a0,0
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	06c080e7          	jalr	108(ra) # 80002d24 <argaddr>
    return -1;
    80005cc0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cc2:	0e054063          	bltz	a0,80005da2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cc6:	fc840593          	addi	a1,s0,-56
    80005cca:	fd040513          	addi	a0,s0,-48
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	dee080e7          	jalr	-530(ra) # 80004abc <pipealloc>
    return -1;
    80005cd6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cd8:	0c054563          	bltz	a0,80005da2 <sys_pipe+0x104>
  fd0 = -1;
    80005cdc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ce0:	fd043503          	ld	a0,-48(s0)
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	50a080e7          	jalr	1290(ra) # 800051ee <fdalloc>
    80005cec:	fca42223          	sw	a0,-60(s0)
    80005cf0:	08054c63          	bltz	a0,80005d88 <sys_pipe+0xea>
    80005cf4:	fc843503          	ld	a0,-56(s0)
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	4f6080e7          	jalr	1270(ra) # 800051ee <fdalloc>
    80005d00:	fca42023          	sw	a0,-64(s0)
    80005d04:	06054863          	bltz	a0,80005d74 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d08:	4691                	li	a3,4
    80005d0a:	fc440613          	addi	a2,s0,-60
    80005d0e:	fd843583          	ld	a1,-40(s0)
    80005d12:	68a8                	ld	a0,80(s1)
    80005d14:	ffffc097          	auipc	ra,0xffffc
    80005d18:	92a080e7          	jalr	-1750(ra) # 8000163e <copyout>
    80005d1c:	02054063          	bltz	a0,80005d3c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d20:	4691                	li	a3,4
    80005d22:	fc040613          	addi	a2,s0,-64
    80005d26:	fd843583          	ld	a1,-40(s0)
    80005d2a:	0591                	addi	a1,a1,4
    80005d2c:	68a8                	ld	a0,80(s1)
    80005d2e:	ffffc097          	auipc	ra,0xffffc
    80005d32:	910080e7          	jalr	-1776(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d36:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d38:	06055563          	bgez	a0,80005da2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d3c:	fc442783          	lw	a5,-60(s0)
    80005d40:	07e9                	addi	a5,a5,26
    80005d42:	078e                	slli	a5,a5,0x3
    80005d44:	97a6                	add	a5,a5,s1
    80005d46:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d4a:	fc042503          	lw	a0,-64(s0)
    80005d4e:	0569                	addi	a0,a0,26
    80005d50:	050e                	slli	a0,a0,0x3
    80005d52:	9526                	add	a0,a0,s1
    80005d54:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d58:	fd043503          	ld	a0,-48(s0)
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	a30080e7          	jalr	-1488(ra) # 8000478c <fileclose>
    fileclose(wf);
    80005d64:	fc843503          	ld	a0,-56(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	a24080e7          	jalr	-1500(ra) # 8000478c <fileclose>
    return -1;
    80005d70:	57fd                	li	a5,-1
    80005d72:	a805                	j	80005da2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d74:	fc442783          	lw	a5,-60(s0)
    80005d78:	0007c863          	bltz	a5,80005d88 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d7c:	01a78513          	addi	a0,a5,26
    80005d80:	050e                	slli	a0,a0,0x3
    80005d82:	9526                	add	a0,a0,s1
    80005d84:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d88:	fd043503          	ld	a0,-48(s0)
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	a00080e7          	jalr	-1536(ra) # 8000478c <fileclose>
    fileclose(wf);
    80005d94:	fc843503          	ld	a0,-56(s0)
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	9f4080e7          	jalr	-1548(ra) # 8000478c <fileclose>
    return -1;
    80005da0:	57fd                	li	a5,-1
}
    80005da2:	853e                	mv	a0,a5
    80005da4:	70e2                	ld	ra,56(sp)
    80005da6:	7442                	ld	s0,48(sp)
    80005da8:	74a2                	ld	s1,40(sp)
    80005daa:	6121                	addi	sp,sp,64
    80005dac:	8082                	ret
	...

0000000080005db0 <kernelvec>:
    80005db0:	7111                	addi	sp,sp,-256
    80005db2:	e006                	sd	ra,0(sp)
    80005db4:	e40a                	sd	sp,8(sp)
    80005db6:	e80e                	sd	gp,16(sp)
    80005db8:	ec12                	sd	tp,24(sp)
    80005dba:	f016                	sd	t0,32(sp)
    80005dbc:	f41a                	sd	t1,40(sp)
    80005dbe:	f81e                	sd	t2,48(sp)
    80005dc0:	fc22                	sd	s0,56(sp)
    80005dc2:	e0a6                	sd	s1,64(sp)
    80005dc4:	e4aa                	sd	a0,72(sp)
    80005dc6:	e8ae                	sd	a1,80(sp)
    80005dc8:	ecb2                	sd	a2,88(sp)
    80005dca:	f0b6                	sd	a3,96(sp)
    80005dcc:	f4ba                	sd	a4,104(sp)
    80005dce:	f8be                	sd	a5,112(sp)
    80005dd0:	fcc2                	sd	a6,120(sp)
    80005dd2:	e146                	sd	a7,128(sp)
    80005dd4:	e54a                	sd	s2,136(sp)
    80005dd6:	e94e                	sd	s3,144(sp)
    80005dd8:	ed52                	sd	s4,152(sp)
    80005dda:	f156                	sd	s5,160(sp)
    80005ddc:	f55a                	sd	s6,168(sp)
    80005dde:	f95e                	sd	s7,176(sp)
    80005de0:	fd62                	sd	s8,184(sp)
    80005de2:	e1e6                	sd	s9,192(sp)
    80005de4:	e5ea                	sd	s10,200(sp)
    80005de6:	e9ee                	sd	s11,208(sp)
    80005de8:	edf2                	sd	t3,216(sp)
    80005dea:	f1f6                	sd	t4,224(sp)
    80005dec:	f5fa                	sd	t5,232(sp)
    80005dee:	f9fe                	sd	t6,240(sp)
    80005df0:	d45fc0ef          	jal	ra,80002b34 <kerneltrap>
    80005df4:	6082                	ld	ra,0(sp)
    80005df6:	6122                	ld	sp,8(sp)
    80005df8:	61c2                	ld	gp,16(sp)
    80005dfa:	7282                	ld	t0,32(sp)
    80005dfc:	7322                	ld	t1,40(sp)
    80005dfe:	73c2                	ld	t2,48(sp)
    80005e00:	7462                	ld	s0,56(sp)
    80005e02:	6486                	ld	s1,64(sp)
    80005e04:	6526                	ld	a0,72(sp)
    80005e06:	65c6                	ld	a1,80(sp)
    80005e08:	6666                	ld	a2,88(sp)
    80005e0a:	7686                	ld	a3,96(sp)
    80005e0c:	7726                	ld	a4,104(sp)
    80005e0e:	77c6                	ld	a5,112(sp)
    80005e10:	7866                	ld	a6,120(sp)
    80005e12:	688a                	ld	a7,128(sp)
    80005e14:	692a                	ld	s2,136(sp)
    80005e16:	69ca                	ld	s3,144(sp)
    80005e18:	6a6a                	ld	s4,152(sp)
    80005e1a:	7a8a                	ld	s5,160(sp)
    80005e1c:	7b2a                	ld	s6,168(sp)
    80005e1e:	7bca                	ld	s7,176(sp)
    80005e20:	7c6a                	ld	s8,184(sp)
    80005e22:	6c8e                	ld	s9,192(sp)
    80005e24:	6d2e                	ld	s10,200(sp)
    80005e26:	6dce                	ld	s11,208(sp)
    80005e28:	6e6e                	ld	t3,216(sp)
    80005e2a:	7e8e                	ld	t4,224(sp)
    80005e2c:	7f2e                	ld	t5,232(sp)
    80005e2e:	7fce                	ld	t6,240(sp)
    80005e30:	6111                	addi	sp,sp,256
    80005e32:	10200073          	sret
    80005e36:	00000013          	nop
    80005e3a:	00000013          	nop
    80005e3e:	0001                	nop

0000000080005e40 <timervec>:
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	e10c                	sd	a1,0(a0)
    80005e46:	e510                	sd	a2,8(a0)
    80005e48:	e914                	sd	a3,16(a0)
    80005e4a:	6d0c                	ld	a1,24(a0)
    80005e4c:	7110                	ld	a2,32(a0)
    80005e4e:	6194                	ld	a3,0(a1)
    80005e50:	96b2                	add	a3,a3,a2
    80005e52:	e194                	sd	a3,0(a1)
    80005e54:	4589                	li	a1,2
    80005e56:	14459073          	csrw	sip,a1
    80005e5a:	6914                	ld	a3,16(a0)
    80005e5c:	6510                	ld	a2,8(a0)
    80005e5e:	610c                	ld	a1,0(a0)
    80005e60:	34051573          	csrrw	a0,mscratch,a0
    80005e64:	30200073          	mret
	...

0000000080005e6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e6a:	1141                	addi	sp,sp,-16
    80005e6c:	e422                	sd	s0,8(sp)
    80005e6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e70:	0c0007b7          	lui	a5,0xc000
    80005e74:	4705                	li	a4,1
    80005e76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e78:	c3d8                	sw	a4,4(a5)
}
    80005e7a:	6422                	ld	s0,8(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret

0000000080005e80 <plicinithart>:

void
plicinithart(void)
{
    80005e80:	1141                	addi	sp,sp,-16
    80005e82:	e406                	sd	ra,8(sp)
    80005e84:	e022                	sd	s0,0(sp)
    80005e86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	bfc080e7          	jalr	-1028(ra) # 80001a84 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e90:	0085171b          	slliw	a4,a0,0x8
    80005e94:	0c0027b7          	lui	a5,0xc002
    80005e98:	97ba                	add	a5,a5,a4
    80005e9a:	40200713          	li	a4,1026
    80005e9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ea2:	00d5151b          	slliw	a0,a0,0xd
    80005ea6:	0c2017b7          	lui	a5,0xc201
    80005eaa:	953e                	add	a0,a0,a5
    80005eac:	00052023          	sw	zero,0(a0)
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret

0000000080005eb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005eb8:	1141                	addi	sp,sp,-16
    80005eba:	e406                	sd	ra,8(sp)
    80005ebc:	e022                	sd	s0,0(sp)
    80005ebe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	bc4080e7          	jalr	-1084(ra) # 80001a84 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ec8:	00d5179b          	slliw	a5,a0,0xd
    80005ecc:	0c201537          	lui	a0,0xc201
    80005ed0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ed2:	4148                	lw	a0,4(a0)
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret

0000000080005edc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	e426                	sd	s1,8(sp)
    80005ee4:	1000                	addi	s0,sp,32
    80005ee6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	b9c080e7          	jalr	-1124(ra) # 80001a84 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ef0:	00d5151b          	slliw	a0,a0,0xd
    80005ef4:	0c2017b7          	lui	a5,0xc201
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	c3c4                	sw	s1,4(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret

0000000080005f06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f06:	1141                	addi	sp,sp,-16
    80005f08:	e406                	sd	ra,8(sp)
    80005f0a:	e022                	sd	s0,0(sp)
    80005f0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f0e:	479d                	li	a5,7
    80005f10:	06a7c963          	blt	a5,a0,80005f82 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f14:	0001d797          	auipc	a5,0x1d
    80005f18:	0ec78793          	addi	a5,a5,236 # 80023000 <disk>
    80005f1c:	00a78733          	add	a4,a5,a0
    80005f20:	6789                	lui	a5,0x2
    80005f22:	97ba                	add	a5,a5,a4
    80005f24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f28:	e7ad                	bnez	a5,80005f92 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f2a:	00451793          	slli	a5,a0,0x4
    80005f2e:	0001f717          	auipc	a4,0x1f
    80005f32:	0d270713          	addi	a4,a4,210 # 80025000 <disk+0x2000>
    80005f36:	6314                	ld	a3,0(a4)
    80005f38:	96be                	add	a3,a3,a5
    80005f3a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f3e:	6314                	ld	a3,0(a4)
    80005f40:	96be                	add	a3,a3,a5
    80005f42:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f46:	6314                	ld	a3,0(a4)
    80005f48:	96be                	add	a3,a3,a5
    80005f4a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f4e:	6318                	ld	a4,0(a4)
    80005f50:	97ba                	add	a5,a5,a4
    80005f52:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f56:	0001d797          	auipc	a5,0x1d
    80005f5a:	0aa78793          	addi	a5,a5,170 # 80023000 <disk>
    80005f5e:	97aa                	add	a5,a5,a0
    80005f60:	6509                	lui	a0,0x2
    80005f62:	953e                	add	a0,a0,a5
    80005f64:	4785                	li	a5,1
    80005f66:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f6a:	0001f517          	auipc	a0,0x1f
    80005f6e:	0ae50513          	addi	a0,a0,174 # 80025018 <disk+0x2018>
    80005f72:	ffffc097          	auipc	ra,0xffffc
    80005f76:	4d0080e7          	jalr	1232(ra) # 80002442 <wakeup>
}
    80005f7a:	60a2                	ld	ra,8(sp)
    80005f7c:	6402                	ld	s0,0(sp)
    80005f7e:	0141                	addi	sp,sp,16
    80005f80:	8082                	ret
    panic("free_desc 1");
    80005f82:	00002517          	auipc	a0,0x2
    80005f86:	7ee50513          	addi	a0,a0,2030 # 80008770 <syscalls+0x328>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5a0080e7          	jalr	1440(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005f92:	00002517          	auipc	a0,0x2
    80005f96:	7ee50513          	addi	a0,a0,2030 # 80008780 <syscalls+0x338>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	590080e7          	jalr	1424(ra) # 8000052a <panic>

0000000080005fa2 <virtio_disk_init>:
{
    80005fa2:	1101                	addi	sp,sp,-32
    80005fa4:	ec06                	sd	ra,24(sp)
    80005fa6:	e822                	sd	s0,16(sp)
    80005fa8:	e426                	sd	s1,8(sp)
    80005faa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fac:	00002597          	auipc	a1,0x2
    80005fb0:	7e458593          	addi	a1,a1,2020 # 80008790 <syscalls+0x348>
    80005fb4:	0001f517          	auipc	a0,0x1f
    80005fb8:	17450513          	addi	a0,a0,372 # 80025128 <disk+0x2128>
    80005fbc:	ffffb097          	auipc	ra,0xffffb
    80005fc0:	b76080e7          	jalr	-1162(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc4:	100017b7          	lui	a5,0x10001
    80005fc8:	4398                	lw	a4,0(a5)
    80005fca:	2701                	sext.w	a4,a4
    80005fcc:	747277b7          	lui	a5,0x74727
    80005fd0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fd4:	0ef71163          	bne	a4,a5,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fd8:	100017b7          	lui	a5,0x10001
    80005fdc:	43dc                	lw	a5,4(a5)
    80005fde:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fe0:	4705                	li	a4,1
    80005fe2:	0ce79a63          	bne	a5,a4,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fe6:	100017b7          	lui	a5,0x10001
    80005fea:	479c                	lw	a5,8(a5)
    80005fec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fee:	4709                	li	a4,2
    80005ff0:	0ce79363          	bne	a5,a4,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ff4:	100017b7          	lui	a5,0x10001
    80005ff8:	47d8                	lw	a4,12(a5)
    80005ffa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ffc:	554d47b7          	lui	a5,0x554d4
    80006000:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006004:	0af71963          	bne	a4,a5,800060b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	100017b7          	lui	a5,0x10001
    8000600c:	4705                	li	a4,1
    8000600e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006010:	470d                	li	a4,3
    80006012:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006014:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006016:	c7ffe737          	lui	a4,0xc7ffe
    8000601a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000601e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006020:	2701                	sext.w	a4,a4
    80006022:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006024:	472d                	li	a4,11
    80006026:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006028:	473d                	li	a4,15
    8000602a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000602c:	6705                	lui	a4,0x1
    8000602e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006030:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006034:	5bdc                	lw	a5,52(a5)
    80006036:	2781                	sext.w	a5,a5
  if(max == 0)
    80006038:	c7d9                	beqz	a5,800060c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000603a:	471d                	li	a4,7
    8000603c:	08f77d63          	bgeu	a4,a5,800060d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006040:	100014b7          	lui	s1,0x10001
    80006044:	47a1                	li	a5,8
    80006046:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006048:	6609                	lui	a2,0x2
    8000604a:	4581                	li	a1,0
    8000604c:	0001d517          	auipc	a0,0x1d
    80006050:	fb450513          	addi	a0,a0,-76 # 80023000 <disk>
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	c6a080e7          	jalr	-918(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000605c:	0001d717          	auipc	a4,0x1d
    80006060:	fa470713          	addi	a4,a4,-92 # 80023000 <disk>
    80006064:	00c75793          	srli	a5,a4,0xc
    80006068:	2781                	sext.w	a5,a5
    8000606a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000606c:	0001f797          	auipc	a5,0x1f
    80006070:	f9478793          	addi	a5,a5,-108 # 80025000 <disk+0x2000>
    80006074:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006076:	0001d717          	auipc	a4,0x1d
    8000607a:	00a70713          	addi	a4,a4,10 # 80023080 <disk+0x80>
    8000607e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006080:	0001e717          	auipc	a4,0x1e
    80006084:	f8070713          	addi	a4,a4,-128 # 80024000 <disk+0x1000>
    80006088:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000608a:	4705                	li	a4,1
    8000608c:	00e78c23          	sb	a4,24(a5)
    80006090:	00e78ca3          	sb	a4,25(a5)
    80006094:	00e78d23          	sb	a4,26(a5)
    80006098:	00e78da3          	sb	a4,27(a5)
    8000609c:	00e78e23          	sb	a4,28(a5)
    800060a0:	00e78ea3          	sb	a4,29(a5)
    800060a4:	00e78f23          	sb	a4,30(a5)
    800060a8:	00e78fa3          	sb	a4,31(a5)
}
    800060ac:	60e2                	ld	ra,24(sp)
    800060ae:	6442                	ld	s0,16(sp)
    800060b0:	64a2                	ld	s1,8(sp)
    800060b2:	6105                	addi	sp,sp,32
    800060b4:	8082                	ret
    panic("could not find virtio disk");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	6ea50513          	addi	a0,a0,1770 # 800087a0 <syscalls+0x358>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	46c080e7          	jalr	1132(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800060c6:	00002517          	auipc	a0,0x2
    800060ca:	6fa50513          	addi	a0,a0,1786 # 800087c0 <syscalls+0x378>
    800060ce:	ffffa097          	auipc	ra,0xffffa
    800060d2:	45c080e7          	jalr	1116(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800060d6:	00002517          	auipc	a0,0x2
    800060da:	70a50513          	addi	a0,a0,1802 # 800087e0 <syscalls+0x398>
    800060de:	ffffa097          	auipc	ra,0xffffa
    800060e2:	44c080e7          	jalr	1100(ra) # 8000052a <panic>

00000000800060e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060e6:	7119                	addi	sp,sp,-128
    800060e8:	fc86                	sd	ra,120(sp)
    800060ea:	f8a2                	sd	s0,112(sp)
    800060ec:	f4a6                	sd	s1,104(sp)
    800060ee:	f0ca                	sd	s2,96(sp)
    800060f0:	ecce                	sd	s3,88(sp)
    800060f2:	e8d2                	sd	s4,80(sp)
    800060f4:	e4d6                	sd	s5,72(sp)
    800060f6:	e0da                	sd	s6,64(sp)
    800060f8:	fc5e                	sd	s7,56(sp)
    800060fa:	f862                	sd	s8,48(sp)
    800060fc:	f466                	sd	s9,40(sp)
    800060fe:	f06a                	sd	s10,32(sp)
    80006100:	ec6e                	sd	s11,24(sp)
    80006102:	0100                	addi	s0,sp,128
    80006104:	8aaa                	mv	s5,a0
    80006106:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006108:	00c52c83          	lw	s9,12(a0)
    8000610c:	001c9c9b          	slliw	s9,s9,0x1
    80006110:	1c82                	slli	s9,s9,0x20
    80006112:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006116:	0001f517          	auipc	a0,0x1f
    8000611a:	01250513          	addi	a0,a0,18 # 80025128 <disk+0x2128>
    8000611e:	ffffb097          	auipc	ra,0xffffb
    80006122:	aa4080e7          	jalr	-1372(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006126:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006128:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000612a:	0001dc17          	auipc	s8,0x1d
    8000612e:	ed6c0c13          	addi	s8,s8,-298 # 80023000 <disk>
    80006132:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006134:	4b0d                	li	s6,3
    80006136:	a0ad                	j	800061a0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006138:	00fc0733          	add	a4,s8,a5
    8000613c:	975e                	add	a4,a4,s7
    8000613e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006142:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006144:	0207c563          	bltz	a5,8000616e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006148:	2905                	addiw	s2,s2,1
    8000614a:	0611                	addi	a2,a2,4
    8000614c:	19690d63          	beq	s2,s6,800062e6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006150:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006152:	0001f717          	auipc	a4,0x1f
    80006156:	ec670713          	addi	a4,a4,-314 # 80025018 <disk+0x2018>
    8000615a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000615c:	00074683          	lbu	a3,0(a4)
    80006160:	fee1                	bnez	a3,80006138 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006162:	2785                	addiw	a5,a5,1
    80006164:	0705                	addi	a4,a4,1
    80006166:	fe979be3          	bne	a5,s1,8000615c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000616a:	57fd                	li	a5,-1
    8000616c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000616e:	01205d63          	blez	s2,80006188 <virtio_disk_rw+0xa2>
    80006172:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006174:	000a2503          	lw	a0,0(s4)
    80006178:	00000097          	auipc	ra,0x0
    8000617c:	d8e080e7          	jalr	-626(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006180:	2d85                	addiw	s11,s11,1
    80006182:	0a11                	addi	s4,s4,4
    80006184:	ffb918e3          	bne	s2,s11,80006174 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006188:	0001f597          	auipc	a1,0x1f
    8000618c:	fa058593          	addi	a1,a1,-96 # 80025128 <disk+0x2128>
    80006190:	0001f517          	auipc	a0,0x1f
    80006194:	e8850513          	addi	a0,a0,-376 # 80025018 <disk+0x2018>
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	11e080e7          	jalr	286(ra) # 800022b6 <sleep>
  for(int i = 0; i < 3; i++){
    800061a0:	f8040a13          	addi	s4,s0,-128
{
    800061a4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061a6:	894e                	mv	s2,s3
    800061a8:	b765                	j	80006150 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061aa:	0001f697          	auipc	a3,0x1f
    800061ae:	e566b683          	ld	a3,-426(a3) # 80025000 <disk+0x2000>
    800061b2:	96ba                	add	a3,a3,a4
    800061b4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061b8:	0001d817          	auipc	a6,0x1d
    800061bc:	e4880813          	addi	a6,a6,-440 # 80023000 <disk>
    800061c0:	0001f697          	auipc	a3,0x1f
    800061c4:	e4068693          	addi	a3,a3,-448 # 80025000 <disk+0x2000>
    800061c8:	6290                	ld	a2,0(a3)
    800061ca:	963a                	add	a2,a2,a4
    800061cc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800061d0:	0015e593          	ori	a1,a1,1
    800061d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800061d8:	f8842603          	lw	a2,-120(s0)
    800061dc:	628c                	ld	a1,0(a3)
    800061de:	972e                	add	a4,a4,a1
    800061e0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061e4:	20050593          	addi	a1,a0,512
    800061e8:	0592                	slli	a1,a1,0x4
    800061ea:	95c2                	add	a1,a1,a6
    800061ec:	577d                	li	a4,-1
    800061ee:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061f2:	00461713          	slli	a4,a2,0x4
    800061f6:	6290                	ld	a2,0(a3)
    800061f8:	963a                	add	a2,a2,a4
    800061fa:	03078793          	addi	a5,a5,48
    800061fe:	97c2                	add	a5,a5,a6
    80006200:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006202:	629c                	ld	a5,0(a3)
    80006204:	97ba                	add	a5,a5,a4
    80006206:	4605                	li	a2,1
    80006208:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000620a:	629c                	ld	a5,0(a3)
    8000620c:	97ba                	add	a5,a5,a4
    8000620e:	4809                	li	a6,2
    80006210:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006214:	629c                	ld	a5,0(a3)
    80006216:	973e                	add	a4,a4,a5
    80006218:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000621c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006220:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006224:	6698                	ld	a4,8(a3)
    80006226:	00275783          	lhu	a5,2(a4)
    8000622a:	8b9d                	andi	a5,a5,7
    8000622c:	0786                	slli	a5,a5,0x1
    8000622e:	97ba                	add	a5,a5,a4
    80006230:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006234:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006238:	6698                	ld	a4,8(a3)
    8000623a:	00275783          	lhu	a5,2(a4)
    8000623e:	2785                	addiw	a5,a5,1
    80006240:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006244:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006248:	100017b7          	lui	a5,0x10001
    8000624c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006250:	004aa783          	lw	a5,4(s5)
    80006254:	02c79163          	bne	a5,a2,80006276 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006258:	0001f917          	auipc	s2,0x1f
    8000625c:	ed090913          	addi	s2,s2,-304 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006260:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006262:	85ca                	mv	a1,s2
    80006264:	8556                	mv	a0,s5
    80006266:	ffffc097          	auipc	ra,0xffffc
    8000626a:	050080e7          	jalr	80(ra) # 800022b6 <sleep>
  while(b->disk == 1) {
    8000626e:	004aa783          	lw	a5,4(s5)
    80006272:	fe9788e3          	beq	a5,s1,80006262 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006276:	f8042903          	lw	s2,-128(s0)
    8000627a:	20090793          	addi	a5,s2,512
    8000627e:	00479713          	slli	a4,a5,0x4
    80006282:	0001d797          	auipc	a5,0x1d
    80006286:	d7e78793          	addi	a5,a5,-642 # 80023000 <disk>
    8000628a:	97ba                	add	a5,a5,a4
    8000628c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006290:	0001f997          	auipc	s3,0x1f
    80006294:	d7098993          	addi	s3,s3,-656 # 80025000 <disk+0x2000>
    80006298:	00491713          	slli	a4,s2,0x4
    8000629c:	0009b783          	ld	a5,0(s3)
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062a6:	854a                	mv	a0,s2
    800062a8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062ac:	00000097          	auipc	ra,0x0
    800062b0:	c5a080e7          	jalr	-934(ra) # 80005f06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062b4:	8885                	andi	s1,s1,1
    800062b6:	f0ed                	bnez	s1,80006298 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062b8:	0001f517          	auipc	a0,0x1f
    800062bc:	e7050513          	addi	a0,a0,-400 # 80025128 <disk+0x2128>
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	9b6080e7          	jalr	-1610(ra) # 80000c76 <release>
}
    800062c8:	70e6                	ld	ra,120(sp)
    800062ca:	7446                	ld	s0,112(sp)
    800062cc:	74a6                	ld	s1,104(sp)
    800062ce:	7906                	ld	s2,96(sp)
    800062d0:	69e6                	ld	s3,88(sp)
    800062d2:	6a46                	ld	s4,80(sp)
    800062d4:	6aa6                	ld	s5,72(sp)
    800062d6:	6b06                	ld	s6,64(sp)
    800062d8:	7be2                	ld	s7,56(sp)
    800062da:	7c42                	ld	s8,48(sp)
    800062dc:	7ca2                	ld	s9,40(sp)
    800062de:	7d02                	ld	s10,32(sp)
    800062e0:	6de2                	ld	s11,24(sp)
    800062e2:	6109                	addi	sp,sp,128
    800062e4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062e6:	f8042503          	lw	a0,-128(s0)
    800062ea:	20050793          	addi	a5,a0,512
    800062ee:	0792                	slli	a5,a5,0x4
  if(write)
    800062f0:	0001d817          	auipc	a6,0x1d
    800062f4:	d1080813          	addi	a6,a6,-752 # 80023000 <disk>
    800062f8:	00f80733          	add	a4,a6,a5
    800062fc:	01a036b3          	snez	a3,s10
    80006300:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006304:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006308:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000630c:	7679                	lui	a2,0xffffe
    8000630e:	963e                	add	a2,a2,a5
    80006310:	0001f697          	auipc	a3,0x1f
    80006314:	cf068693          	addi	a3,a3,-784 # 80025000 <disk+0x2000>
    80006318:	6298                	ld	a4,0(a3)
    8000631a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000631c:	0a878593          	addi	a1,a5,168
    80006320:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006322:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006324:	6298                	ld	a4,0(a3)
    80006326:	9732                	add	a4,a4,a2
    80006328:	45c1                	li	a1,16
    8000632a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000632c:	6298                	ld	a4,0(a3)
    8000632e:	9732                	add	a4,a4,a2
    80006330:	4585                	li	a1,1
    80006332:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006336:	f8442703          	lw	a4,-124(s0)
    8000633a:	628c                	ld	a1,0(a3)
    8000633c:	962e                	add	a2,a2,a1
    8000633e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006342:	0712                	slli	a4,a4,0x4
    80006344:	6290                	ld	a2,0(a3)
    80006346:	963a                	add	a2,a2,a4
    80006348:	058a8593          	addi	a1,s5,88
    8000634c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000634e:	6294                	ld	a3,0(a3)
    80006350:	96ba                	add	a3,a3,a4
    80006352:	40000613          	li	a2,1024
    80006356:	c690                	sw	a2,8(a3)
  if(write)
    80006358:	e40d19e3          	bnez	s10,800061aa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000635c:	0001f697          	auipc	a3,0x1f
    80006360:	ca46b683          	ld	a3,-860(a3) # 80025000 <disk+0x2000>
    80006364:	96ba                	add	a3,a3,a4
    80006366:	4609                	li	a2,2
    80006368:	00c69623          	sh	a2,12(a3)
    8000636c:	b5b1                	j	800061b8 <virtio_disk_rw+0xd2>

000000008000636e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000636e:	1101                	addi	sp,sp,-32
    80006370:	ec06                	sd	ra,24(sp)
    80006372:	e822                	sd	s0,16(sp)
    80006374:	e426                	sd	s1,8(sp)
    80006376:	e04a                	sd	s2,0(sp)
    80006378:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000637a:	0001f517          	auipc	a0,0x1f
    8000637e:	dae50513          	addi	a0,a0,-594 # 80025128 <disk+0x2128>
    80006382:	ffffb097          	auipc	ra,0xffffb
    80006386:	840080e7          	jalr	-1984(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000638a:	10001737          	lui	a4,0x10001
    8000638e:	533c                	lw	a5,96(a4)
    80006390:	8b8d                	andi	a5,a5,3
    80006392:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006394:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006398:	0001f797          	auipc	a5,0x1f
    8000639c:	c6878793          	addi	a5,a5,-920 # 80025000 <disk+0x2000>
    800063a0:	6b94                	ld	a3,16(a5)
    800063a2:	0207d703          	lhu	a4,32(a5)
    800063a6:	0026d783          	lhu	a5,2(a3)
    800063aa:	06f70163          	beq	a4,a5,8000640c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ae:	0001d917          	auipc	s2,0x1d
    800063b2:	c5290913          	addi	s2,s2,-942 # 80023000 <disk>
    800063b6:	0001f497          	auipc	s1,0x1f
    800063ba:	c4a48493          	addi	s1,s1,-950 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063be:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063c2:	6898                	ld	a4,16(s1)
    800063c4:	0204d783          	lhu	a5,32(s1)
    800063c8:	8b9d                	andi	a5,a5,7
    800063ca:	078e                	slli	a5,a5,0x3
    800063cc:	97ba                	add	a5,a5,a4
    800063ce:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063d0:	20078713          	addi	a4,a5,512
    800063d4:	0712                	slli	a4,a4,0x4
    800063d6:	974a                	add	a4,a4,s2
    800063d8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063dc:	e731                	bnez	a4,80006428 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063de:	20078793          	addi	a5,a5,512
    800063e2:	0792                	slli	a5,a5,0x4
    800063e4:	97ca                	add	a5,a5,s2
    800063e6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063e8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063ec:	ffffc097          	auipc	ra,0xffffc
    800063f0:	056080e7          	jalr	86(ra) # 80002442 <wakeup>

    disk.used_idx += 1;
    800063f4:	0204d783          	lhu	a5,32(s1)
    800063f8:	2785                	addiw	a5,a5,1
    800063fa:	17c2                	slli	a5,a5,0x30
    800063fc:	93c1                	srli	a5,a5,0x30
    800063fe:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006402:	6898                	ld	a4,16(s1)
    80006404:	00275703          	lhu	a4,2(a4)
    80006408:	faf71be3          	bne	a4,a5,800063be <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000640c:	0001f517          	auipc	a0,0x1f
    80006410:	d1c50513          	addi	a0,a0,-740 # 80025128 <disk+0x2128>
    80006414:	ffffb097          	auipc	ra,0xffffb
    80006418:	862080e7          	jalr	-1950(ra) # 80000c76 <release>
}
    8000641c:	60e2                	ld	ra,24(sp)
    8000641e:	6442                	ld	s0,16(sp)
    80006420:	64a2                	ld	s1,8(sp)
    80006422:	6902                	ld	s2,0(sp)
    80006424:	6105                	addi	sp,sp,32
    80006426:	8082                	ret
      panic("virtio_disk_intr status");
    80006428:	00002517          	auipc	a0,0x2
    8000642c:	3d850513          	addi	a0,a0,984 # 80008800 <syscalls+0x3b8>
    80006430:	ffffa097          	auipc	ra,0xffffa
    80006434:	0fa080e7          	jalr	250(ra) # 8000052a <panic>
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
