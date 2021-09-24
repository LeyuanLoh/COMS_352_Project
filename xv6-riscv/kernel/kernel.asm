
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	85013103          	ld	sp,-1968(sp) # 80008850 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	ffe70713          	addi	a4,a4,-2 # 80009050 <timer_scratch>
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
    80000068:	b8c78793          	addi	a5,a5,-1140 # 80005bf0 <timervec>
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
    80000122:	356080e7          	jalr	854(ra) # 80002474 <either_copyin>
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
    80000180:	01450513          	addi	a0,a0,20 # 80011190 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	00448493          	addi	s1,s1,4 # 80011190 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	09490913          	addi	s2,s2,148 # 80011228 <cons+0x98>
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
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7cc080e7          	jalr	1996(ra) # 8000197e <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	eb8080e7          	jalr	-328(ra) # 8000207a <sleep>
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
    80000202:	220080e7          	jalr	544(ra) # 8000241e <either_copyout>
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
    80000216:	f7e50513          	addi	a0,a0,-130 # 80011190 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f6850513          	addi	a0,a0,-152 # 80011190 <cons>
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
    80000262:	fcf72523          	sw	a5,-54(a4) # 80011228 <cons+0x98>
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
    800002bc:	ed850513          	addi	a0,a0,-296 # 80011190 <cons>
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
    800002e2:	1ec080e7          	jalr	492(ra) # 800024ca <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	eaa50513          	addi	a0,a0,-342 # 80011190 <cons>
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
    8000030e:	e8670713          	addi	a4,a4,-378 # 80011190 <cons>
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
    80000338:	e5c78793          	addi	a5,a5,-420 # 80011190 <cons>
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
    80000366:	ec67a783          	lw	a5,-314(a5) # 80011228 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e1a70713          	addi	a4,a4,-486 # 80011190 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	e0a48493          	addi	s1,s1,-502 # 80011190 <cons>
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
    800003c6:	dce70713          	addi	a4,a4,-562 # 80011190 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72c23          	sw	a5,-424(a4) # 80011230 <cons+0xa0>
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
    80000402:	d9278793          	addi	a5,a5,-622 # 80011190 <cons>
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
    80000426:	e0c7a523          	sw	a2,-502(a5) # 8001122c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dfe50513          	addi	a0,a0,-514 # 80011228 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	dd4080e7          	jalr	-556(ra) # 80002206 <wakeup>
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
    80000450:	d4450513          	addi	a0,a0,-700 # 80011190 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	4c478793          	addi	a5,a5,1220 # 80021928 <devsw>
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
    8000053a:	d007ad23          	sw	zero,-742(a5) # 80011250 <pr+0x18>
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
    800005aa:	caadad83          	lw	s11,-854(s11) # 80011250 <pr+0x18>
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
    800005e8:	c5450513          	addi	a0,a0,-940 # 80011238 <pr>
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
    80000746:	af650513          	addi	a0,a0,-1290 # 80011238 <pr>
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
    80000762:	ada48493          	addi	s1,s1,-1318 # 80011238 <pr>
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
    800007c2:	a9a50513          	addi	a0,a0,-1382 # 80011258 <uart_tx_lock>
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
    80000850:	a0ca0a13          	addi	s4,s4,-1524 # 80011258 <uart_tx_lock>
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
    80000882:	988080e7          	jalr	-1656(ra) # 80002206 <wakeup>
    
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
    800008be:	99e50513          	addi	a0,a0,-1634 # 80011258 <uart_tx_lock>
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
    800008f2:	96a98993          	addi	s3,s3,-1686 # 80011258 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	770080e7          	jalr	1904(ra) # 8000207a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	93848493          	addi	s1,s1,-1736 # 80011258 <uart_tx_lock>
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
    800009ac:	8b048493          	addi	s1,s1,-1872 # 80011258 <uart_tx_lock>
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
    80000a0e:	88690913          	addi	s2,s2,-1914 # 80011290 <kmem>
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
    80000aaa:	7ea50513          	addi	a0,a0,2026 # 80011290 <kmem>
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
    80000ae0:	7b448493          	addi	s1,s1,1972 # 80011290 <kmem>
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
    80000af8:	79c50513          	addi	a0,a0,1948 # 80011290 <kmem>
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
    80000b24:	77050513          	addi	a0,a0,1904 # 80011290 <kmem>
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
    80000b60:	e06080e7          	jalr	-506(ra) # 80001962 <mycpu>
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
    80000b92:	dd4080e7          	jalr	-556(ra) # 80001962 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dc8080e7          	jalr	-568(ra) # 80001962 <mycpu>
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
    80000bb6:	db0080e7          	jalr	-592(ra) # 80001962 <mycpu>
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
    80000bf6:	d70080e7          	jalr	-656(ra) # 80001962 <mycpu>
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
    80000c22:	d44080e7          	jalr	-700(ra) # 80001962 <mycpu>
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
    80000e78:	ade080e7          	jalr	-1314(ra) # 80001952 <cpuid>
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
    80000e94:	ac2080e7          	jalr	-1342(ra) # 80001952 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	79a080e7          	jalr	1946(ra) # 8000264c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	d76080e7          	jalr	-650(ra) # 80005c30 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fd2080e7          	jalr	-46(ra) # 80001e94 <scheduler>
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
    80000f26:	980080e7          	jalr	-1664(ra) # 800018a2 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	6fa080e7          	jalr	1786(ra) # 80002624 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	71a080e7          	jalr	1818(ra) # 8000264c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	ce0080e7          	jalr	-800(ra) # 80005c1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	cee080e7          	jalr	-786(ra) # 80005c30 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	ebe080e7          	jalr	-322(ra) # 80002e08 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	54e080e7          	jalr	1358(ra) # 800034a0 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	4f8080e7          	jalr	1272(ra) # 80004452 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	df0080e7          	jalr	-528(ra) # 80005d52 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	cf4080e7          	jalr	-780(ra) # 80001c5e <userinit>
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
    80001210:	600080e7          	jalr	1536(ra) # 8000180c <proc_mapstacks>
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

000000008000180c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000180c:	7139                	addi	sp,sp,-64
    8000180e:	fc06                	sd	ra,56(sp)
    80001810:	f822                	sd	s0,48(sp)
    80001812:	f426                	sd	s1,40(sp)
    80001814:	f04a                	sd	s2,32(sp)
    80001816:	ec4e                	sd	s3,24(sp)
    80001818:	e852                	sd	s4,16(sp)
    8000181a:	e456                	sd	s5,8(sp)
    8000181c:	e05a                	sd	s6,0(sp)
    8000181e:	0080                	addi	s0,sp,64
    80001820:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001822:	00010497          	auipc	s1,0x10
    80001826:	ebe48493          	addi	s1,s1,-322 # 800116e0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000182a:	8b26                	mv	s6,s1
    8000182c:	00006a97          	auipc	s5,0x6
    80001830:	7d4a8a93          	addi	s5,s5,2004 # 80008000 <etext>
    80001834:	04000937          	lui	s2,0x4000
    80001838:	197d                	addi	s2,s2,-1
    8000183a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000183c:	00016a17          	auipc	s4,0x16
    80001840:	ea4a0a13          	addi	s4,s4,-348 # 800176e0 <tickslock>
    char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
    if (pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	859d                	srai	a1,a1,0x7
    80001856:	000ab783          	ld	a5,0(s5)
    8000185a:	02f585b3          	mul	a1,a1,a5
    8000185e:	2585                	addiw	a1,a1,1
    80001860:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001864:	4719                	li	a4,6
    80001866:	6685                	lui	a3,0x1
    80001868:	40b905b3          	sub	a1,s2,a1
    8000186c:	854e                	mv	a0,s3
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	8ae080e7          	jalr	-1874(ra) # 8000111c <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001876:	18048493          	addi	s1,s1,384
    8000187a:	fd4495e3          	bne	s1,s4,80001844 <proc_mapstacks+0x38>
  }
}
    8000187e:	70e2                	ld	ra,56(sp)
    80001880:	7442                	ld	s0,48(sp)
    80001882:	74a2                	ld	s1,40(sp)
    80001884:	7902                	ld	s2,32(sp)
    80001886:	69e2                	ld	s3,24(sp)
    80001888:	6a42                	ld	s4,16(sp)
    8000188a:	6aa2                	ld	s5,8(sp)
    8000188c:	6b02                	ld	s6,0(sp)
    8000188e:	6121                	addi	sp,sp,64
    80001890:	8082                	ret
      panic("kalloc");
    80001892:	00007517          	auipc	a0,0x7
    80001896:	92e50513          	addi	a0,a0,-1746 # 800081c0 <digits+0x180>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	c90080e7          	jalr	-880(ra) # 8000052a <panic>

00000000800018a2 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018a2:	7139                	addi	sp,sp,-64
    800018a4:	fc06                	sd	ra,56(sp)
    800018a6:	f822                	sd	s0,48(sp)
    800018a8:	f426                	sd	s1,40(sp)
    800018aa:	f04a                	sd	s2,32(sp)
    800018ac:	ec4e                	sd	s3,24(sp)
    800018ae:	e852                	sd	s4,16(sp)
    800018b0:	e456                	sd	s5,8(sp)
    800018b2:	e05a                	sd	s6,0(sp)
    800018b4:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018b6:	00007597          	auipc	a1,0x7
    800018ba:	91258593          	addi	a1,a1,-1774 # 800081c8 <digits+0x188>
    800018be:	00010517          	auipc	a0,0x10
    800018c2:	9f250513          	addi	a0,a0,-1550 # 800112b0 <pid_lock>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	26c080e7          	jalr	620(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	90258593          	addi	a1,a1,-1790 # 800081d0 <digits+0x190>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9f250513          	addi	a0,a0,-1550 # 800112c8 <wait_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	254080e7          	jalr	596(ra) # 80000b32 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800018e6:	00010497          	auipc	s1,0x10
    800018ea:	dfa48493          	addi	s1,s1,-518 # 800116e0 <proc>
  {
    initlock(&p->lock, "proc");
    800018ee:	00007b17          	auipc	s6,0x7
    800018f2:	8f2b0b13          	addi	s6,s6,-1806 # 800081e0 <digits+0x1a0>
    p->kstack = KSTACK((int)(p - proc));
    800018f6:	8aa6                	mv	s5,s1
    800018f8:	00006a17          	auipc	s4,0x6
    800018fc:	708a0a13          	addi	s4,s4,1800 # 80008000 <etext>
    80001900:	04000937          	lui	s2,0x4000
    80001904:	197d                	addi	s2,s2,-1
    80001906:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001908:	00016997          	auipc	s3,0x16
    8000190c:	dd898993          	addi	s3,s3,-552 # 800176e0 <tickslock>
    initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	879d                	srai	a5,a5,0x7
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001936:	18048493          	addi	s1,s1,384
    8000193a:	fd349be3          	bne	s1,s3,80001910 <procinit+0x6e>
  }
}
    8000193e:	70e2                	ld	ra,56(sp)
    80001940:	7442                	ld	s0,48(sp)
    80001942:	74a2                	ld	s1,40(sp)
    80001944:	7902                	ld	s2,32(sp)
    80001946:	69e2                	ld	s3,24(sp)
    80001948:	6a42                	ld	s4,16(sp)
    8000194a:	6aa2                	ld	s5,8(sp)
    8000194c:	6b02                	ld	s6,0(sp)
    8000194e:	6121                	addi	sp,sp,64
    80001950:	8082                	ret

0000000080001952 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001952:	1141                	addi	sp,sp,-16
    80001954:	e422                	sd	s0,8(sp)
    80001956:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001958:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000195a:	2501                	sext.w	a0,a0
    8000195c:	6422                	ld	s0,8(sp)
    8000195e:	0141                	addi	sp,sp,16
    80001960:	8082                	ret

0000000080001962 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001962:	1141                	addi	sp,sp,-16
    80001964:	e422                	sd	s0,8(sp)
    80001966:	0800                	addi	s0,sp,16
    80001968:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000196a:	2781                	sext.w	a5,a5
    8000196c:	079e                	slli	a5,a5,0x7
  return c;
}
    8000196e:	00010517          	auipc	a0,0x10
    80001972:	97250513          	addi	a0,a0,-1678 # 800112e0 <cpus>
    80001976:	953e                	add	a0,a0,a5
    80001978:	6422                	ld	s0,8(sp)
    8000197a:	0141                	addi	sp,sp,16
    8000197c:	8082                	ret

000000008000197e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    8000197e:	1101                	addi	sp,sp,-32
    80001980:	ec06                	sd	ra,24(sp)
    80001982:	e822                	sd	s0,16(sp)
    80001984:	e426                	sd	s1,8(sp)
    80001986:	1000                	addi	s0,sp,32
  push_off();
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1ee080e7          	jalr	494(ra) # 80000b76 <push_off>
    80001990:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
    80001996:	00010717          	auipc	a4,0x10
    8000199a:	91a70713          	addi	a4,a4,-1766 # 800112b0 <pid_lock>
    8000199e:	97ba                	add	a5,a5,a4
    800019a0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	274080e7          	jalr	628(ra) # 80000c16 <pop_off>
  return p;
}
    800019aa:	8526                	mv	a0,s1
    800019ac:	60e2                	ld	ra,24(sp)
    800019ae:	6442                	ld	s0,16(sp)
    800019b0:	64a2                	ld	s1,8(sp)
    800019b2:	6105                	addi	sp,sp,32
    800019b4:	8082                	ret

00000000800019b6 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e406                	sd	ra,8(sp)
    800019ba:	e022                	sd	s0,0(sp)
    800019bc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	fc0080e7          	jalr	-64(ra) # 8000197e <myproc>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	2b0080e7          	jalr	688(ra) # 80000c76 <release>

  if (first)
    800019ce:	00007797          	auipc	a5,0x7
    800019d2:	e327a783          	lw	a5,-462(a5) # 80008800 <first.1>
    800019d6:	eb89                	bnez	a5,800019e8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019d8:	00001097          	auipc	ra,0x1
    800019dc:	c8c080e7          	jalr	-884(ra) # 80002664 <usertrapret>
}
    800019e0:	60a2                	ld	ra,8(sp)
    800019e2:	6402                	ld	s0,0(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret
    first = 0;
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	e007ac23          	sw	zero,-488(a5) # 80008800 <first.1>
    fsinit(ROOTDEV);
    800019f0:	4505                	li	a0,1
    800019f2:	00002097          	auipc	ra,0x2
    800019f6:	a2e080e7          	jalr	-1490(ra) # 80003420 <fsinit>
    800019fa:	bff9                	j	800019d8 <forkret+0x22>

00000000800019fc <allocpid>:
{
    800019fc:	1101                	addi	sp,sp,-32
    800019fe:	ec06                	sd	ra,24(sp)
    80001a00:	e822                	sd	s0,16(sp)
    80001a02:	e426                	sd	s1,8(sp)
    80001a04:	e04a                	sd	s2,0(sp)
    80001a06:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a08:	00010917          	auipc	s2,0x10
    80001a0c:	8a890913          	addi	s2,s2,-1880 # 800112b0 <pid_lock>
    80001a10:	854a                	mv	a0,s2
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	1b0080e7          	jalr	432(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	dea78793          	addi	a5,a5,-534 # 80008804 <nextpid>
    80001a22:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a24:	0014871b          	addiw	a4,s1,1
    80001a28:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a2a:	854a                	mv	a0,s2
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	24a080e7          	jalr	586(ra) # 80000c76 <release>
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6902                	ld	s2,0(sp)
    80001a3e:	6105                	addi	sp,sp,32
    80001a40:	8082                	ret

0000000080001a42 <proc_pagetable>:
{
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	e04a                	sd	s2,0(sp)
    80001a4c:	1000                	addi	s0,sp,32
    80001a4e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	8b6080e7          	jalr	-1866(ra) # 80001306 <uvmcreate>
    80001a58:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a5a:	c121                	beqz	a0,80001a9a <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a5c:	4729                	li	a4,10
    80001a5e:	00005697          	auipc	a3,0x5
    80001a62:	5a268693          	addi	a3,a3,1442 # 80007000 <_trampoline>
    80001a66:	6605                	lui	a2,0x1
    80001a68:	040005b7          	lui	a1,0x4000
    80001a6c:	15fd                	addi	a1,a1,-1
    80001a6e:	05b2                	slli	a1,a1,0xc
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	61e080e7          	jalr	1566(ra) # 8000108e <mappages>
    80001a78:	02054863          	bltz	a0,80001aa8 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a7c:	4719                	li	a4,6
    80001a7e:	05893683          	ld	a3,88(s2)
    80001a82:	6605                	lui	a2,0x1
    80001a84:	020005b7          	lui	a1,0x2000
    80001a88:	15fd                	addi	a1,a1,-1
    80001a8a:	05b6                	slli	a1,a1,0xd
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	600080e7          	jalr	1536(ra) # 8000108e <mappages>
    80001a96:	02054163          	bltz	a0,80001ab8 <proc_pagetable+0x76>
}
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	60e2                	ld	ra,24(sp)
    80001a9e:	6442                	ld	s0,16(sp)
    80001aa0:	64a2                	ld	s1,8(sp)
    80001aa2:	6902                	ld	s2,0(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret
    uvmfree(pagetable, 0);
    80001aa8:	4581                	li	a1,0
    80001aaa:	8526                	mv	a0,s1
    80001aac:	00000097          	auipc	ra,0x0
    80001ab0:	a56080e7          	jalr	-1450(ra) # 80001502 <uvmfree>
    return 0;
    80001ab4:	4481                	li	s1,0
    80001ab6:	b7d5                	j	80001a9a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ab8:	4681                	li	a3,0
    80001aba:	4605                	li	a2,1
    80001abc:	040005b7          	lui	a1,0x4000
    80001ac0:	15fd                	addi	a1,a1,-1
    80001ac2:	05b2                	slli	a1,a1,0xc
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	77c080e7          	jalr	1916(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ace:	4581                	li	a1,0
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	a30080e7          	jalr	-1488(ra) # 80001502 <uvmfree>
    return 0;
    80001ada:	4481                	li	s1,0
    80001adc:	bf7d                	j	80001a9a <proc_pagetable+0x58>

0000000080001ade <proc_freepagetable>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	e04a                	sd	s2,0(sp)
    80001ae8:	1000                	addi	s0,sp,32
    80001aea:	84aa                	mv	s1,a0
    80001aec:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	748080e7          	jalr	1864(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	020005b7          	lui	a1,0x2000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b6                	slli	a1,a1,0xd
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	732080e7          	jalr	1842(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b18:	85ca                	mv	a1,s2
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	9e6080e7          	jalr	-1562(ra) # 80001502 <uvmfree>
}
    80001b24:	60e2                	ld	ra,24(sp)
    80001b26:	6442                	ld	s0,16(sp)
    80001b28:	64a2                	ld	s1,8(sp)
    80001b2a:	6902                	ld	s2,0(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <freeproc>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b3c:	6d28                	ld	a0,88(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b48:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b4c:	68a8                	ld	a0,80(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b50:	64ac                	ld	a1,72(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
  p->pagetable = 0;
    80001b5a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b5e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
  p->ticks = 0; //Leyuan & Lee
    80001b66:	1604a423          	sw	zero,360(s1)
  p->parent = 0;
    80001b6a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b6e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b72:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b76:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b7a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b7e:	0004ac23          	sw	zero,24(s1)
}
    80001b82:	60e2                	ld	ra,24(sp)
    80001b84:	6442                	ld	s0,16(sp)
    80001b86:	64a2                	ld	s1,8(sp)
    80001b88:	6105                	addi	sp,sp,32
    80001b8a:	8082                	ret

0000000080001b8c <allocproc>:
{
    80001b8c:	1101                	addi	sp,sp,-32
    80001b8e:	ec06                	sd	ra,24(sp)
    80001b90:	e822                	sd	s0,16(sp)
    80001b92:	e426                	sd	s1,8(sp)
    80001b94:	e04a                	sd	s2,0(sp)
    80001b96:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001b98:	00010497          	auipc	s1,0x10
    80001b9c:	b4848493          	addi	s1,s1,-1208 # 800116e0 <proc>
    80001ba0:	00016917          	auipc	s2,0x16
    80001ba4:	b4090913          	addi	s2,s2,-1216 # 800176e0 <tickslock>
    acquire(&p->lock);
    80001ba8:	8526                	mv	a0,s1
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	018080e7          	jalr	24(ra) # 80000bc2 <acquire>
    if (p->state == UNUSED)
    80001bb2:	4c9c                	lw	a5,24(s1)
    80001bb4:	cf81                	beqz	a5,80001bcc <allocproc+0x40>
      release(&p->lock);
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	0be080e7          	jalr	190(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc0:	18048493          	addi	s1,s1,384
    80001bc4:	ff2492e3          	bne	s1,s2,80001ba8 <allocproc+0x1c>
  return 0;
    80001bc8:	4481                	li	s1,0
    80001bca:	a899                	j	80001c20 <allocproc+0x94>
  p->pid = allocpid();
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	e30080e7          	jalr	-464(ra) # 800019fc <allocpid>
    80001bd4:	d888                	sw	a0,48(s1)
  p->ticks = 0; //Leyuan & Lee
    80001bd6:	1604a423          	sw	zero,360(s1)
  p->state = USED;
    80001bda:	4785                	li	a5,1
    80001bdc:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	ef4080e7          	jalr	-268(ra) # 80000ad2 <kalloc>
    80001be6:	892a                	mv	s2,a0
    80001be8:	eca8                	sd	a0,88(s1)
    80001bea:	c131                	beqz	a0,80001c2e <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001bec:	8526                	mv	a0,s1
    80001bee:	00000097          	auipc	ra,0x0
    80001bf2:	e54080e7          	jalr	-428(ra) # 80001a42 <proc_pagetable>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001bfa:	c531                	beqz	a0,80001c46 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001bfc:	07000613          	li	a2,112
    80001c00:	4581                	li	a1,0
    80001c02:	06048513          	addi	a0,s1,96
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	0b8080e7          	jalr	184(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c0e:	00000797          	auipc	a5,0x0
    80001c12:	da878793          	addi	a5,a5,-600 # 800019b6 <forkret>
    80001c16:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c18:	60bc                	ld	a5,64(s1)
    80001c1a:	6705                	lui	a4,0x1
    80001c1c:	97ba                	add	a5,a5,a4
    80001c1e:	f4bc                	sd	a5,104(s1)
}
    80001c20:	8526                	mv	a0,s1
    80001c22:	60e2                	ld	ra,24(sp)
    80001c24:	6442                	ld	s0,16(sp)
    80001c26:	64a2                	ld	s1,8(sp)
    80001c28:	6902                	ld	s2,0(sp)
    80001c2a:	6105                	addi	sp,sp,32
    80001c2c:	8082                	ret
    freeproc(p);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	f00080e7          	jalr	-256(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	03c080e7          	jalr	60(ra) # 80000c76 <release>
    return 0;
    80001c42:	84ca                	mv	s1,s2
    80001c44:	bff1                	j	80001c20 <allocproc+0x94>
    freeproc(p);
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	ee8080e7          	jalr	-280(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	024080e7          	jalr	36(ra) # 80000c76 <release>
    return 0;
    80001c5a:	84ca                	mv	s1,s2
    80001c5c:	b7d1                	j	80001c20 <allocproc+0x94>

0000000080001c5e <userinit>:
{
    80001c5e:	1101                	addi	sp,sp,-32
    80001c60:	ec06                	sd	ra,24(sp)
    80001c62:	e822                	sd	s0,16(sp)
    80001c64:	e426                	sd	s1,8(sp)
    80001c66:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	f24080e7          	jalr	-220(ra) # 80001b8c <allocproc>
    80001c70:	84aa                	mv	s1,a0
  initproc = p;
    80001c72:	00007797          	auipc	a5,0x7
    80001c76:	3aa7bb23          	sd	a0,950(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c7a:	03400613          	li	a2,52
    80001c7e:	00007597          	auipc	a1,0x7
    80001c82:	b9258593          	addi	a1,a1,-1134 # 80008810 <initcode>
    80001c86:	6928                	ld	a0,80(a0)
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	6ac080e7          	jalr	1708(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001c90:	6785                	lui	a5,0x1
    80001c92:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001c94:	6cb8                	ld	a4,88(s1)
    80001c96:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001c9a:	6cb8                	ld	a4,88(s1)
    80001c9c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001c9e:	4641                	li	a2,16
    80001ca0:	00006597          	auipc	a1,0x6
    80001ca4:	54858593          	addi	a1,a1,1352 # 800081e8 <digits+0x1a8>
    80001ca8:	15848513          	addi	a0,s1,344
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	164080e7          	jalr	356(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cb4:	00006517          	auipc	a0,0x6
    80001cb8:	54450513          	addi	a0,a0,1348 # 800081f8 <digits+0x1b8>
    80001cbc:	00002097          	auipc	ra,0x2
    80001cc0:	192080e7          	jalr	402(ra) # 80003e4e <namei>
    80001cc4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cc8:	478d                	li	a5,3
    80001cca:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	fa8080e7          	jalr	-88(ra) # 80000c76 <release>
}
    80001cd6:	60e2                	ld	ra,24(sp)
    80001cd8:	6442                	ld	s0,16(sp)
    80001cda:	64a2                	ld	s1,8(sp)
    80001cdc:	6105                	addi	sp,sp,32
    80001cde:	8082                	ret

0000000080001ce0 <growproc>:
{
    80001ce0:	1101                	addi	sp,sp,-32
    80001ce2:	ec06                	sd	ra,24(sp)
    80001ce4:	e822                	sd	s0,16(sp)
    80001ce6:	e426                	sd	s1,8(sp)
    80001ce8:	e04a                	sd	s2,0(sp)
    80001cea:	1000                	addi	s0,sp,32
    80001cec:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	c90080e7          	jalr	-880(ra) # 8000197e <myproc>
    80001cf6:	892a                	mv	s2,a0
  sz = p->sz;
    80001cf8:	652c                	ld	a1,72(a0)
    80001cfa:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001cfe:	00904f63          	bgtz	s1,80001d1c <growproc+0x3c>
  else if (n < 0)
    80001d02:	0204cc63          	bltz	s1,80001d3a <growproc+0x5a>
  p->sz = sz;
    80001d06:	1602                	slli	a2,a2,0x20
    80001d08:	9201                	srli	a2,a2,0x20
    80001d0a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d0e:	4501                	li	a0,0
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6902                	ld	s2,0(sp)
    80001d18:	6105                	addi	sp,sp,32
    80001d1a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d1c:	9e25                	addw	a2,a2,s1
    80001d1e:	1602                	slli	a2,a2,0x20
    80001d20:	9201                	srli	a2,a2,0x20
    80001d22:	1582                	slli	a1,a1,0x20
    80001d24:	9181                	srli	a1,a1,0x20
    80001d26:	6928                	ld	a0,80(a0)
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	6c6080e7          	jalr	1734(ra) # 800013ee <uvmalloc>
    80001d30:	0005061b          	sext.w	a2,a0
    80001d34:	fa69                	bnez	a2,80001d06 <growproc+0x26>
      return -1;
    80001d36:	557d                	li	a0,-1
    80001d38:	bfe1                	j	80001d10 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d3a:	9e25                	addw	a2,a2,s1
    80001d3c:	1602                	slli	a2,a2,0x20
    80001d3e:	9201                	srli	a2,a2,0x20
    80001d40:	1582                	slli	a1,a1,0x20
    80001d42:	9181                	srli	a1,a1,0x20
    80001d44:	6928                	ld	a0,80(a0)
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	660080e7          	jalr	1632(ra) # 800013a6 <uvmdealloc>
    80001d4e:	0005061b          	sext.w	a2,a0
    80001d52:	bf55                	j	80001d06 <growproc+0x26>

0000000080001d54 <fork>:
{
    80001d54:	7139                	addi	sp,sp,-64
    80001d56:	fc06                	sd	ra,56(sp)
    80001d58:	f822                	sd	s0,48(sp)
    80001d5a:	f426                	sd	s1,40(sp)
    80001d5c:	f04a                	sd	s2,32(sp)
    80001d5e:	ec4e                	sd	s3,24(sp)
    80001d60:	e852                	sd	s4,16(sp)
    80001d62:	e456                	sd	s5,8(sp)
    80001d64:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	c18080e7          	jalr	-1000(ra) # 8000197e <myproc>
    80001d6e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	e1c080e7          	jalr	-484(ra) # 80001b8c <allocproc>
    80001d78:	10050c63          	beqz	a0,80001e90 <fork+0x13c>
    80001d7c:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d7e:	048ab603          	ld	a2,72(s5)
    80001d82:	692c                	ld	a1,80(a0)
    80001d84:	050ab503          	ld	a0,80(s5)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	7b2080e7          	jalr	1970(ra) # 8000153a <uvmcopy>
    80001d90:	04054863          	bltz	a0,80001de0 <fork+0x8c>
  np->sz = p->sz;
    80001d94:	048ab783          	ld	a5,72(s5)
    80001d98:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001d9c:	058ab683          	ld	a3,88(s5)
    80001da0:	87b6                	mv	a5,a3
    80001da2:	058a3703          	ld	a4,88(s4)
    80001da6:	12068693          	addi	a3,a3,288
    80001daa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dae:	6788                	ld	a0,8(a5)
    80001db0:	6b8c                	ld	a1,16(a5)
    80001db2:	6f90                	ld	a2,24(a5)
    80001db4:	01073023          	sd	a6,0(a4)
    80001db8:	e708                	sd	a0,8(a4)
    80001dba:	eb0c                	sd	a1,16(a4)
    80001dbc:	ef10                	sd	a2,24(a4)
    80001dbe:	02078793          	addi	a5,a5,32
    80001dc2:	02070713          	addi	a4,a4,32
    80001dc6:	fed792e3          	bne	a5,a3,80001daa <fork+0x56>
  np->trapframe->a0 = 0;
    80001dca:	058a3783          	ld	a5,88(s4)
    80001dce:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001dd2:	0d0a8493          	addi	s1,s5,208
    80001dd6:	0d0a0913          	addi	s2,s4,208
    80001dda:	150a8993          	addi	s3,s5,336
    80001dde:	a00d                	j	80001e00 <fork+0xac>
    freeproc(np);
    80001de0:	8552                	mv	a0,s4
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	d4e080e7          	jalr	-690(ra) # 80001b30 <freeproc>
    release(&np->lock);
    80001dea:	8552                	mv	a0,s4
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	e8a080e7          	jalr	-374(ra) # 80000c76 <release>
    return -1;
    80001df4:	597d                	li	s2,-1
    80001df6:	a059                	j	80001e7c <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001df8:	04a1                	addi	s1,s1,8
    80001dfa:	0921                	addi	s2,s2,8
    80001dfc:	01348b63          	beq	s1,s3,80001e12 <fork+0xbe>
    if (p->ofile[i])
    80001e00:	6088                	ld	a0,0(s1)
    80001e02:	d97d                	beqz	a0,80001df8 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e04:	00002097          	auipc	ra,0x2
    80001e08:	6e0080e7          	jalr	1760(ra) # 800044e4 <filedup>
    80001e0c:	00a93023          	sd	a0,0(s2)
    80001e10:	b7e5                	j	80001df8 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e12:	150ab503          	ld	a0,336(s5)
    80001e16:	00002097          	auipc	ra,0x2
    80001e1a:	844080e7          	jalr	-1980(ra) # 8000365a <idup>
    80001e1e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e22:	4641                	li	a2,16
    80001e24:	158a8593          	addi	a1,s5,344
    80001e28:	158a0513          	addi	a0,s4,344
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	fe4080e7          	jalr	-28(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e34:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e38:	8552                	mv	a0,s4
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e3c080e7          	jalr	-452(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e42:	0000f497          	auipc	s1,0xf
    80001e46:	48648493          	addi	s1,s1,1158 # 800112c8 <wait_lock>
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	d76080e7          	jalr	-650(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e54:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e1c080e7          	jalr	-484(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e62:	8552                	mv	a0,s4
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	d5e080e7          	jalr	-674(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e6c:	478d                	li	a5,3
    80001e6e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e72:	8552                	mv	a0,s4
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e02080e7          	jalr	-510(ra) # 80000c76 <release>
}
    80001e7c:	854a                	mv	a0,s2
    80001e7e:	70e2                	ld	ra,56(sp)
    80001e80:	7442                	ld	s0,48(sp)
    80001e82:	74a2                	ld	s1,40(sp)
    80001e84:	7902                	ld	s2,32(sp)
    80001e86:	69e2                	ld	s3,24(sp)
    80001e88:	6a42                	ld	s4,16(sp)
    80001e8a:	6aa2                	ld	s5,8(sp)
    80001e8c:	6121                	addi	sp,sp,64
    80001e8e:	8082                	ret
    return -1;
    80001e90:	597d                	li	s2,-1
    80001e92:	b7ed                	j	80001e7c <fork+0x128>

0000000080001e94 <scheduler>:
{
    80001e94:	7139                	addi	sp,sp,-64
    80001e96:	fc06                	sd	ra,56(sp)
    80001e98:	f822                	sd	s0,48(sp)
    80001e9a:	f426                	sd	s1,40(sp)
    80001e9c:	f04a                	sd	s2,32(sp)
    80001e9e:	ec4e                	sd	s3,24(sp)
    80001ea0:	e852                	sd	s4,16(sp)
    80001ea2:	e456                	sd	s5,8(sp)
    80001ea4:	e05a                	sd	s6,0(sp)
    80001ea6:	0080                	addi	s0,sp,64
    80001ea8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eaa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eac:	00779a93          	slli	s5,a5,0x7
    80001eb0:	0000f717          	auipc	a4,0xf
    80001eb4:	40070713          	addi	a4,a4,1024 # 800112b0 <pid_lock>
    80001eb8:	9756                	add	a4,a4,s5
    80001eba:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	42a70713          	addi	a4,a4,1066 # 800112e8 <cpus+0x8>
    80001ec6:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ec8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eca:	4b11                	li	s6,4
        c->proc = p;
    80001ecc:	079e                	slli	a5,a5,0x7
    80001ece:	0000fa17          	auipc	s4,0xf
    80001ed2:	3e2a0a13          	addi	s4,s4,994 # 800112b0 <pid_lock>
    80001ed6:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ed8:	00016917          	auipc	s2,0x16
    80001edc:	80890913          	addi	s2,s2,-2040 # 800176e0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ee4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ee8:	10079073          	csrw	sstatus,a5
    80001eec:	0000f497          	auipc	s1,0xf
    80001ef0:	7f448493          	addi	s1,s1,2036 # 800116e0 <proc>
    80001ef4:	a811                	j	80001f08 <scheduler+0x74>
      release(&p->lock);
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	d7e080e7          	jalr	-642(ra) # 80000c76 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f00:	18048493          	addi	s1,s1,384
    80001f04:	fd248ee3          	beq	s1,s2,80001ee0 <scheduler+0x4c>
      acquire(&p->lock);
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	cb8080e7          	jalr	-840(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80001f12:	4c9c                	lw	a5,24(s1)
    80001f14:	ff3791e3          	bne	a5,s3,80001ef6 <scheduler+0x62>
        p->state = RUNNING;
    80001f18:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f1c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f20:	06048593          	addi	a1,s1,96
    80001f24:	8556                	mv	a0,s5
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	694080e7          	jalr	1684(ra) # 800025ba <swtch>
        c->proc = 0;
    80001f2e:	020a3823          	sd	zero,48(s4)
    80001f32:	b7d1                	j	80001ef6 <scheduler+0x62>

0000000080001f34 <sched>:
{
    80001f34:	7179                	addi	sp,sp,-48
    80001f36:	f406                	sd	ra,40(sp)
    80001f38:	f022                	sd	s0,32(sp)
    80001f3a:	ec26                	sd	s1,24(sp)
    80001f3c:	e84a                	sd	s2,16(sp)
    80001f3e:	e44e                	sd	s3,8(sp)
    80001f40:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	a3c080e7          	jalr	-1476(ra) # 8000197e <myproc>
    80001f4a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	bfc080e7          	jalr	-1028(ra) # 80000b48 <holding>
    80001f54:	c93d                	beqz	a0,80001fca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f56:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f58:	2781                	sext.w	a5,a5
    80001f5a:	079e                	slli	a5,a5,0x7
    80001f5c:	0000f717          	auipc	a4,0xf
    80001f60:	35470713          	addi	a4,a4,852 # 800112b0 <pid_lock>
    80001f64:	97ba                	add	a5,a5,a4
    80001f66:	0a87a703          	lw	a4,168(a5)
    80001f6a:	4785                	li	a5,1
    80001f6c:	06f71763          	bne	a4,a5,80001fda <sched+0xa6>
  if (p->state == RUNNING)
    80001f70:	4c98                	lw	a4,24(s1)
    80001f72:	4791                	li	a5,4
    80001f74:	06f70b63          	beq	a4,a5,80001fea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f78:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f7c:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f7e:	efb5                	bnez	a5,80001ffa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f80:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f82:	0000f917          	auipc	s2,0xf
    80001f86:	32e90913          	addi	s2,s2,814 # 800112b0 <pid_lock>
    80001f8a:	2781                	sext.w	a5,a5
    80001f8c:	079e                	slli	a5,a5,0x7
    80001f8e:	97ca                	add	a5,a5,s2
    80001f90:	0ac7a983          	lw	s3,172(a5)
    80001f94:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	0000f597          	auipc	a1,0xf
    80001f9e:	34e58593          	addi	a1,a1,846 # 800112e8 <cpus+0x8>
    80001fa2:	95be                	add	a1,a1,a5
    80001fa4:	06048513          	addi	a0,s1,96
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	612080e7          	jalr	1554(ra) # 800025ba <swtch>
    80001fb0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	slli	a5,a5,0x7
    80001fb6:	97ca                	add	a5,a5,s2
    80001fb8:	0b37a623          	sw	s3,172(a5)
}
    80001fbc:	70a2                	ld	ra,40(sp)
    80001fbe:	7402                	ld	s0,32(sp)
    80001fc0:	64e2                	ld	s1,24(sp)
    80001fc2:	6942                	ld	s2,16(sp)
    80001fc4:	69a2                	ld	s3,8(sp)
    80001fc6:	6145                	addi	sp,sp,48
    80001fc8:	8082                	ret
    panic("sched p->lock");
    80001fca:	00006517          	auipc	a0,0x6
    80001fce:	23650513          	addi	a0,a0,566 # 80008200 <digits+0x1c0>
    80001fd2:	ffffe097          	auipc	ra,0xffffe
    80001fd6:	558080e7          	jalr	1368(ra) # 8000052a <panic>
    panic("sched locks");
    80001fda:	00006517          	auipc	a0,0x6
    80001fde:	23650513          	addi	a0,a0,566 # 80008210 <digits+0x1d0>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	548080e7          	jalr	1352(ra) # 8000052a <panic>
    panic("sched running");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	23650513          	addi	a0,a0,566 # 80008220 <digits+0x1e0>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	538080e7          	jalr	1336(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	23650513          	addi	a0,a0,566 # 80008230 <digits+0x1f0>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	528080e7          	jalr	1320(ra) # 8000052a <panic>

000000008000200a <yield>:
{
    8000200a:	1101                	addi	sp,sp,-32
    8000200c:	ec06                	sd	ra,24(sp)
    8000200e:	e822                	sd	s0,16(sp)
    80002010:	e426                	sd	s1,8(sp)
    80002012:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	96a080e7          	jalr	-1686(ra) # 8000197e <myproc>
    8000201c:	84aa                	mv	s1,a0
  p->ticks++;
    8000201e:	16852783          	lw	a5,360(a0)
    80002022:	2785                	addiw	a5,a5,1
    80002024:	0007869b          	sext.w	a3,a5
    80002028:	16f52423          	sw	a5,360(a0)
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
    8000202c:	17853783          	ld	a5,376(a0)
    80002030:	4705                	li	a4,1
    80002032:	00e78f63          	beq	a5,a4,80002050 <yield+0x46>
    80002036:	4709                	li	a4,2
    80002038:	00e78963          	beq	a5,a4,8000204a <yield+0x40>
    8000203c:	470d                	li	a4,3
    8000203e:	02e79963          	bne	a5,a4,80002070 <yield+0x66>
    80002042:	478d                	li	a5,3
    80002044:	02d7d663          	bge	a5,a3,80002070 <yield+0x66>
    80002048:	a021                	j	80002050 <yield+0x46>
    8000204a:	4785                	li	a5,1
    8000204c:	02d7d263          	bge	a5,a3,80002070 <yield+0x66>
    acquire(&p->lock);
    80002050:	8526                	mv	a0,s1
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	b70080e7          	jalr	-1168(ra) # 80000bc2 <acquire>
    p->state = RUNNABLE;
    8000205a:	478d                	li	a5,3
    8000205c:	cc9c                	sw	a5,24(s1)
    sched();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	ed6080e7          	jalr	-298(ra) # 80001f34 <sched>
    release(&p->lock);
    80002066:	8526                	mv	a0,s1
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c0e080e7          	jalr	-1010(ra) # 80000c76 <release>
}
    80002070:	60e2                	ld	ra,24(sp)
    80002072:	6442                	ld	s0,16(sp)
    80002074:	64a2                	ld	s1,8(sp)
    80002076:	6105                	addi	sp,sp,32
    80002078:	8082                	ret

000000008000207a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000207a:	7179                	addi	sp,sp,-48
    8000207c:	f406                	sd	ra,40(sp)
    8000207e:	f022                	sd	s0,32(sp)
    80002080:	ec26                	sd	s1,24(sp)
    80002082:	e84a                	sd	s2,16(sp)
    80002084:	e44e                	sd	s3,8(sp)
    80002086:	1800                	addi	s0,sp,48
    80002088:	89aa                	mv	s3,a0
    8000208a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	8f2080e7          	jalr	-1806(ra) # 8000197e <myproc>
    80002094:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	b2c080e7          	jalr	-1236(ra) # 80000bc2 <acquire>
  release(lk);
    8000209e:	854a                	mv	a0,s2
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	bd6080e7          	jalr	-1066(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020a8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ac:	4789                	li	a5,2
    800020ae:	cc9c                	sw	a5,24(s1)

  sched();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	e84080e7          	jalr	-380(ra) # 80001f34 <sched>

  // Tidy up.
  p->chan = 0;
    800020b8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	bb8080e7          	jalr	-1096(ra) # 80000c76 <release>
  acquire(lk);
    800020c6:	854a                	mv	a0,s2
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	afa080e7          	jalr	-1286(ra) # 80000bc2 <acquire>
}
    800020d0:	70a2                	ld	ra,40(sp)
    800020d2:	7402                	ld	s0,32(sp)
    800020d4:	64e2                	ld	s1,24(sp)
    800020d6:	6942                	ld	s2,16(sp)
    800020d8:	69a2                	ld	s3,8(sp)
    800020da:	6145                	addi	sp,sp,48
    800020dc:	8082                	ret

00000000800020de <wait>:
{
    800020de:	715d                	addi	sp,sp,-80
    800020e0:	e486                	sd	ra,72(sp)
    800020e2:	e0a2                	sd	s0,64(sp)
    800020e4:	fc26                	sd	s1,56(sp)
    800020e6:	f84a                	sd	s2,48(sp)
    800020e8:	f44e                	sd	s3,40(sp)
    800020ea:	f052                	sd	s4,32(sp)
    800020ec:	ec56                	sd	s5,24(sp)
    800020ee:	e85a                	sd	s6,16(sp)
    800020f0:	e45e                	sd	s7,8(sp)
    800020f2:	e062                	sd	s8,0(sp)
    800020f4:	0880                	addi	s0,sp,80
    800020f6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	886080e7          	jalr	-1914(ra) # 8000197e <myproc>
    80002100:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002102:	0000f517          	auipc	a0,0xf
    80002106:	1c650513          	addi	a0,a0,454 # 800112c8 <wait_lock>
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	ab8080e7          	jalr	-1352(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002112:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002114:	4a15                	li	s4,5
        havekids = 1;
    80002116:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002118:	00015997          	auipc	s3,0x15
    8000211c:	5c898993          	addi	s3,s3,1480 # 800176e0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002120:	0000fc17          	auipc	s8,0xf
    80002124:	1a8c0c13          	addi	s8,s8,424 # 800112c8 <wait_lock>
    havekids = 0;
    80002128:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000212a:	0000f497          	auipc	s1,0xf
    8000212e:	5b648493          	addi	s1,s1,1462 # 800116e0 <proc>
    80002132:	a0bd                	j	800021a0 <wait+0xc2>
          pid = np->pid;
    80002134:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002138:	000b0e63          	beqz	s6,80002154 <wait+0x76>
    8000213c:	4691                	li	a3,4
    8000213e:	02c48613          	addi	a2,s1,44
    80002142:	85da                	mv	a1,s6
    80002144:	05093503          	ld	a0,80(s2)
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	4f6080e7          	jalr	1270(ra) # 8000163e <copyout>
    80002150:	02054563          	bltz	a0,8000217a <wait+0x9c>
          freeproc(np);
    80002154:	8526                	mv	a0,s1
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	9da080e7          	jalr	-1574(ra) # 80001b30 <freeproc>
          release(&np->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b16080e7          	jalr	-1258(ra) # 80000c76 <release>
          release(&wait_lock);
    80002168:	0000f517          	auipc	a0,0xf
    8000216c:	16050513          	addi	a0,a0,352 # 800112c8 <wait_lock>
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b06080e7          	jalr	-1274(ra) # 80000c76 <release>
          return pid;
    80002178:	a09d                	j	800021de <wait+0x100>
            release(&np->lock);
    8000217a:	8526                	mv	a0,s1
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	afa080e7          	jalr	-1286(ra) # 80000c76 <release>
            release(&wait_lock);
    80002184:	0000f517          	auipc	a0,0xf
    80002188:	14450513          	addi	a0,a0,324 # 800112c8 <wait_lock>
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	aea080e7          	jalr	-1302(ra) # 80000c76 <release>
            return -1;
    80002194:	59fd                	li	s3,-1
    80002196:	a0a1                	j	800021de <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002198:	18048493          	addi	s1,s1,384
    8000219c:	03348463          	beq	s1,s3,800021c4 <wait+0xe6>
      if (np->parent == p)
    800021a0:	7c9c                	ld	a5,56(s1)
    800021a2:	ff279be3          	bne	a5,s2,80002198 <wait+0xba>
        acquire(&np->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a1a080e7          	jalr	-1510(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	f94781e3          	beq	a5,s4,80002134 <wait+0x56>
        release(&np->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	abe080e7          	jalr	-1346(ra) # 80000c76 <release>
        havekids = 1;
    800021c0:	8756                	mv	a4,s5
    800021c2:	bfd9                	j	80002198 <wait+0xba>
    if (!havekids || p->killed)
    800021c4:	c701                	beqz	a4,800021cc <wait+0xee>
    800021c6:	02892783          	lw	a5,40(s2)
    800021ca:	c79d                	beqz	a5,800021f8 <wait+0x11a>
      release(&wait_lock);
    800021cc:	0000f517          	auipc	a0,0xf
    800021d0:	0fc50513          	addi	a0,a0,252 # 800112c8 <wait_lock>
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	aa2080e7          	jalr	-1374(ra) # 80000c76 <release>
      return -1;
    800021dc:	59fd                	li	s3,-1
}
    800021de:	854e                	mv	a0,s3
    800021e0:	60a6                	ld	ra,72(sp)
    800021e2:	6406                	ld	s0,64(sp)
    800021e4:	74e2                	ld	s1,56(sp)
    800021e6:	7942                	ld	s2,48(sp)
    800021e8:	79a2                	ld	s3,40(sp)
    800021ea:	7a02                	ld	s4,32(sp)
    800021ec:	6ae2                	ld	s5,24(sp)
    800021ee:	6b42                	ld	s6,16(sp)
    800021f0:	6ba2                	ld	s7,8(sp)
    800021f2:	6c02                	ld	s8,0(sp)
    800021f4:	6161                	addi	sp,sp,80
    800021f6:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800021f8:	85e2                	mv	a1,s8
    800021fa:	854a                	mv	a0,s2
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	e7e080e7          	jalr	-386(ra) # 8000207a <sleep>
    havekids = 0;
    80002204:	b715                	j	80002128 <wait+0x4a>

0000000080002206 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002206:	7139                	addi	sp,sp,-64
    80002208:	fc06                	sd	ra,56(sp)
    8000220a:	f822                	sd	s0,48(sp)
    8000220c:	f426                	sd	s1,40(sp)
    8000220e:	f04a                	sd	s2,32(sp)
    80002210:	ec4e                	sd	s3,24(sp)
    80002212:	e852                	sd	s4,16(sp)
    80002214:	e456                	sd	s5,8(sp)
    80002216:	0080                	addi	s0,sp,64
    80002218:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000221a:	0000f497          	auipc	s1,0xf
    8000221e:	4c648493          	addi	s1,s1,1222 # 800116e0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002222:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002224:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002226:	00015917          	auipc	s2,0x15
    8000222a:	4ba90913          	addi	s2,s2,1210 # 800176e0 <tickslock>
    8000222e:	a811                	j	80002242 <wakeup+0x3c>
      }
      release(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a44080e7          	jalr	-1468(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000223a:	18048493          	addi	s1,s1,384
    8000223e:	03248663          	beq	s1,s2,8000226a <wakeup+0x64>
    if (p != myproc())
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	73c080e7          	jalr	1852(ra) # 8000197e <myproc>
    8000224a:	fea488e3          	beq	s1,a0,8000223a <wakeup+0x34>
      acquire(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	972080e7          	jalr	-1678(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002258:	4c9c                	lw	a5,24(s1)
    8000225a:	fd379be3          	bne	a5,s3,80002230 <wakeup+0x2a>
    8000225e:	709c                	ld	a5,32(s1)
    80002260:	fd4798e3          	bne	a5,s4,80002230 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002264:	0154ac23          	sw	s5,24(s1)
    80002268:	b7e1                	j	80002230 <wakeup+0x2a>
    }
  }
}
    8000226a:	70e2                	ld	ra,56(sp)
    8000226c:	7442                	ld	s0,48(sp)
    8000226e:	74a2                	ld	s1,40(sp)
    80002270:	7902                	ld	s2,32(sp)
    80002272:	69e2                	ld	s3,24(sp)
    80002274:	6a42                	ld	s4,16(sp)
    80002276:	6aa2                	ld	s5,8(sp)
    80002278:	6121                	addi	sp,sp,64
    8000227a:	8082                	ret

000000008000227c <reparent>:
{
    8000227c:	7179                	addi	sp,sp,-48
    8000227e:	f406                	sd	ra,40(sp)
    80002280:	f022                	sd	s0,32(sp)
    80002282:	ec26                	sd	s1,24(sp)
    80002284:	e84a                	sd	s2,16(sp)
    80002286:	e44e                	sd	s3,8(sp)
    80002288:	e052                	sd	s4,0(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	45248493          	addi	s1,s1,1106 # 800116e0 <proc>
      pp->parent = initproc;
    80002296:	00007a17          	auipc	s4,0x7
    8000229a:	d92a0a13          	addi	s4,s4,-622 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000229e:	00015997          	auipc	s3,0x15
    800022a2:	44298993          	addi	s3,s3,1090 # 800176e0 <tickslock>
    800022a6:	a029                	j	800022b0 <reparent+0x34>
    800022a8:	18048493          	addi	s1,s1,384
    800022ac:	01348d63          	beq	s1,s3,800022c6 <reparent+0x4a>
    if (pp->parent == p)
    800022b0:	7c9c                	ld	a5,56(s1)
    800022b2:	ff279be3          	bne	a5,s2,800022a8 <reparent+0x2c>
      pp->parent = initproc;
    800022b6:	000a3503          	ld	a0,0(s4)
    800022ba:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	f4a080e7          	jalr	-182(ra) # 80002206 <wakeup>
    800022c4:	b7d5                	j	800022a8 <reparent+0x2c>
}
    800022c6:	70a2                	ld	ra,40(sp)
    800022c8:	7402                	ld	s0,32(sp)
    800022ca:	64e2                	ld	s1,24(sp)
    800022cc:	6942                	ld	s2,16(sp)
    800022ce:	69a2                	ld	s3,8(sp)
    800022d0:	6a02                	ld	s4,0(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret

00000000800022d6 <exit>:
{
    800022d6:	7179                	addi	sp,sp,-48
    800022d8:	f406                	sd	ra,40(sp)
    800022da:	f022                	sd	s0,32(sp)
    800022dc:	ec26                	sd	s1,24(sp)
    800022de:	e84a                	sd	s2,16(sp)
    800022e0:	e44e                	sd	s3,8(sp)
    800022e2:	e052                	sd	s4,0(sp)
    800022e4:	1800                	addi	s0,sp,48
    800022e6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	696080e7          	jalr	1686(ra) # 8000197e <myproc>
    800022f0:	89aa                	mv	s3,a0
  if (p == initproc)
    800022f2:	00007797          	auipc	a5,0x7
    800022f6:	d367b783          	ld	a5,-714(a5) # 80009028 <initproc>
    800022fa:	0d050493          	addi	s1,a0,208
    800022fe:	15050913          	addi	s2,a0,336
    80002302:	02a79363          	bne	a5,a0,80002328 <exit+0x52>
    panic("init exiting");
    80002306:	00006517          	auipc	a0,0x6
    8000230a:	f4250513          	addi	a0,a0,-190 # 80008248 <digits+0x208>
    8000230e:	ffffe097          	auipc	ra,0xffffe
    80002312:	21c080e7          	jalr	540(ra) # 8000052a <panic>
      fileclose(f);
    80002316:	00002097          	auipc	ra,0x2
    8000231a:	220080e7          	jalr	544(ra) # 80004536 <fileclose>
      p->ofile[fd] = 0;
    8000231e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002322:	04a1                	addi	s1,s1,8
    80002324:	01248563          	beq	s1,s2,8000232e <exit+0x58>
    if (p->ofile[fd])
    80002328:	6088                	ld	a0,0(s1)
    8000232a:	f575                	bnez	a0,80002316 <exit+0x40>
    8000232c:	bfdd                	j	80002322 <exit+0x4c>
  begin_op();
    8000232e:	00002097          	auipc	ra,0x2
    80002332:	d3c080e7          	jalr	-708(ra) # 8000406a <begin_op>
  iput(p->cwd);
    80002336:	1509b503          	ld	a0,336(s3)
    8000233a:	00001097          	auipc	ra,0x1
    8000233e:	518080e7          	jalr	1304(ra) # 80003852 <iput>
  end_op();
    80002342:	00002097          	auipc	ra,0x2
    80002346:	da8080e7          	jalr	-600(ra) # 800040ea <end_op>
  p->cwd = 0;
    8000234a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000234e:	0000f497          	auipc	s1,0xf
    80002352:	f7a48493          	addi	s1,s1,-134 # 800112c8 <wait_lock>
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	86a080e7          	jalr	-1942(ra) # 80000bc2 <acquire>
  reparent(p);
    80002360:	854e                	mv	a0,s3
    80002362:	00000097          	auipc	ra,0x0
    80002366:	f1a080e7          	jalr	-230(ra) # 8000227c <reparent>
  wakeup(p->parent);
    8000236a:	0389b503          	ld	a0,56(s3)
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	e98080e7          	jalr	-360(ra) # 80002206 <wakeup>
  acquire(&p->lock);
    80002376:	854e                	mv	a0,s3
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	84a080e7          	jalr	-1974(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002380:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002384:	4795                	li	a5,5
    80002386:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8ea080e7          	jalr	-1814(ra) # 80000c76 <release>
  sched();
    80002394:	00000097          	auipc	ra,0x0
    80002398:	ba0080e7          	jalr	-1120(ra) # 80001f34 <sched>
  panic("zombie exit");
    8000239c:	00006517          	auipc	a0,0x6
    800023a0:	ebc50513          	addi	a0,a0,-324 # 80008258 <digits+0x218>
    800023a4:	ffffe097          	auipc	ra,0xffffe
    800023a8:	186080e7          	jalr	390(ra) # 8000052a <panic>

00000000800023ac <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023ac:	7179                	addi	sp,sp,-48
    800023ae:	f406                	sd	ra,40(sp)
    800023b0:	f022                	sd	s0,32(sp)
    800023b2:	ec26                	sd	s1,24(sp)
    800023b4:	e84a                	sd	s2,16(sp)
    800023b6:	e44e                	sd	s3,8(sp)
    800023b8:	1800                	addi	s0,sp,48
    800023ba:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023bc:	0000f497          	auipc	s1,0xf
    800023c0:	32448493          	addi	s1,s1,804 # 800116e0 <proc>
    800023c4:	00015997          	auipc	s3,0x15
    800023c8:	31c98993          	addi	s3,s3,796 # 800176e0 <tickslock>
  {
    acquire(&p->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	7f4080e7          	jalr	2036(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    800023d6:	589c                	lw	a5,48(s1)
    800023d8:	01278d63          	beq	a5,s2,800023f2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	898080e7          	jalr	-1896(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023e6:	18048493          	addi	s1,s1,384
    800023ea:	ff3491e3          	bne	s1,s3,800023cc <kill+0x20>
  }
  return -1;
    800023ee:	557d                	li	a0,-1
    800023f0:	a829                	j	8000240a <kill+0x5e>
      p->killed = 1;
    800023f2:	4785                	li	a5,1
    800023f4:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800023f6:	4c98                	lw	a4,24(s1)
    800023f8:	4789                	li	a5,2
    800023fa:	00f70f63          	beq	a4,a5,80002418 <kill+0x6c>
      release(&p->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	876080e7          	jalr	-1930(ra) # 80000c76 <release>
      return 0;
    80002408:	4501                	li	a0,0
}
    8000240a:	70a2                	ld	ra,40(sp)
    8000240c:	7402                	ld	s0,32(sp)
    8000240e:	64e2                	ld	s1,24(sp)
    80002410:	6942                	ld	s2,16(sp)
    80002412:	69a2                	ld	s3,8(sp)
    80002414:	6145                	addi	sp,sp,48
    80002416:	8082                	ret
        p->state = RUNNABLE;
    80002418:	478d                	li	a5,3
    8000241a:	cc9c                	sw	a5,24(s1)
    8000241c:	b7cd                	j	800023fe <kill+0x52>

000000008000241e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000241e:	7179                	addi	sp,sp,-48
    80002420:	f406                	sd	ra,40(sp)
    80002422:	f022                	sd	s0,32(sp)
    80002424:	ec26                	sd	s1,24(sp)
    80002426:	e84a                	sd	s2,16(sp)
    80002428:	e44e                	sd	s3,8(sp)
    8000242a:	e052                	sd	s4,0(sp)
    8000242c:	1800                	addi	s0,sp,48
    8000242e:	84aa                	mv	s1,a0
    80002430:	892e                	mv	s2,a1
    80002432:	89b2                	mv	s3,a2
    80002434:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	548080e7          	jalr	1352(ra) # 8000197e <myproc>
  if (user_dst)
    8000243e:	c08d                	beqz	s1,80002460 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002440:	86d2                	mv	a3,s4
    80002442:	864e                	mv	a2,s3
    80002444:	85ca                	mv	a1,s2
    80002446:	6928                	ld	a0,80(a0)
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	1f6080e7          	jalr	502(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002450:	70a2                	ld	ra,40(sp)
    80002452:	7402                	ld	s0,32(sp)
    80002454:	64e2                	ld	s1,24(sp)
    80002456:	6942                	ld	s2,16(sp)
    80002458:	69a2                	ld	s3,8(sp)
    8000245a:	6a02                	ld	s4,0(sp)
    8000245c:	6145                	addi	sp,sp,48
    8000245e:	8082                	ret
    memmove((char *)dst, src, len);
    80002460:	000a061b          	sext.w	a2,s4
    80002464:	85ce                	mv	a1,s3
    80002466:	854a                	mv	a0,s2
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	8b2080e7          	jalr	-1870(ra) # 80000d1a <memmove>
    return 0;
    80002470:	8526                	mv	a0,s1
    80002472:	bff9                	j	80002450 <either_copyout+0x32>

0000000080002474 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002474:	7179                	addi	sp,sp,-48
    80002476:	f406                	sd	ra,40(sp)
    80002478:	f022                	sd	s0,32(sp)
    8000247a:	ec26                	sd	s1,24(sp)
    8000247c:	e84a                	sd	s2,16(sp)
    8000247e:	e44e                	sd	s3,8(sp)
    80002480:	e052                	sd	s4,0(sp)
    80002482:	1800                	addi	s0,sp,48
    80002484:	892a                	mv	s2,a0
    80002486:	84ae                	mv	s1,a1
    80002488:	89b2                	mv	s3,a2
    8000248a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	4f2080e7          	jalr	1266(ra) # 8000197e <myproc>
  if (user_src)
    80002494:	c08d                	beqz	s1,800024b6 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002496:	86d2                	mv	a3,s4
    80002498:	864e                	mv	a2,s3
    8000249a:	85ca                	mv	a1,s2
    8000249c:	6928                	ld	a0,80(a0)
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	22c080e7          	jalr	556(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024a6:	70a2                	ld	ra,40(sp)
    800024a8:	7402                	ld	s0,32(sp)
    800024aa:	64e2                	ld	s1,24(sp)
    800024ac:	6942                	ld	s2,16(sp)
    800024ae:	69a2                	ld	s3,8(sp)
    800024b0:	6a02                	ld	s4,0(sp)
    800024b2:	6145                	addi	sp,sp,48
    800024b4:	8082                	ret
    memmove(dst, (char *)src, len);
    800024b6:	000a061b          	sext.w	a2,s4
    800024ba:	85ce                	mv	a1,s3
    800024bc:	854a                	mv	a0,s2
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	85c080e7          	jalr	-1956(ra) # 80000d1a <memmove>
    return 0;
    800024c6:	8526                	mv	a0,s1
    800024c8:	bff9                	j	800024a6 <either_copyin+0x32>

00000000800024ca <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800024ca:	715d                	addi	sp,sp,-80
    800024cc:	e486                	sd	ra,72(sp)
    800024ce:	e0a2                	sd	s0,64(sp)
    800024d0:	fc26                	sd	s1,56(sp)
    800024d2:	f84a                	sd	s2,48(sp)
    800024d4:	f44e                	sd	s3,40(sp)
    800024d6:	f052                	sd	s4,32(sp)
    800024d8:	ec56                	sd	s5,24(sp)
    800024da:	e85a                	sd	s6,16(sp)
    800024dc:	e45e                	sd	s7,8(sp)
    800024de:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800024e0:	00006517          	auipc	a0,0x6
    800024e4:	be850513          	addi	a0,a0,-1048 # 800080c8 <digits+0x88>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	08c080e7          	jalr	140(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800024f0:	0000f497          	auipc	s1,0xf
    800024f4:	34848493          	addi	s1,s1,840 # 80011838 <proc+0x158>
    800024f8:	00015917          	auipc	s2,0x15
    800024fc:	34090913          	addi	s2,s2,832 # 80017838 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002500:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002502:	00006997          	auipc	s3,0x6
    80002506:	d6698993          	addi	s3,s3,-666 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000250a:	00006a97          	auipc	s5,0x6
    8000250e:	d66a8a93          	addi	s5,s5,-666 # 80008270 <digits+0x230>
    printf("\n");
    80002512:	00006a17          	auipc	s4,0x6
    80002516:	bb6a0a13          	addi	s4,s4,-1098 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000251a:	00006b97          	auipc	s7,0x6
    8000251e:	d8eb8b93          	addi	s7,s7,-626 # 800082a8 <states.0>
    80002522:	a00d                	j	80002544 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002524:	ed86a583          	lw	a1,-296(a3)
    80002528:	8556                	mv	a0,s5
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	04a080e7          	jalr	74(ra) # 80000574 <printf>
    printf("\n");
    80002532:	8552                	mv	a0,s4
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	040080e7          	jalr	64(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000253c:	18048493          	addi	s1,s1,384
    80002540:	03248163          	beq	s1,s2,80002562 <procdump+0x98>
    if (p->state == UNUSED)
    80002544:	86a6                	mv	a3,s1
    80002546:	ec04a783          	lw	a5,-320(s1)
    8000254a:	dbed                	beqz	a5,8000253c <procdump+0x72>
      state = "???";
    8000254c:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254e:	fcfb6be3          	bltu	s6,a5,80002524 <procdump+0x5a>
    80002552:	1782                	slli	a5,a5,0x20
    80002554:	9381                	srli	a5,a5,0x20
    80002556:	078e                	slli	a5,a5,0x3
    80002558:	97de                	add	a5,a5,s7
    8000255a:	6390                	ld	a2,0(a5)
    8000255c:	f661                	bnez	a2,80002524 <procdump+0x5a>
      state = "???";
    8000255e:	864e                	mv	a2,s3
    80002560:	b7d1                	j	80002524 <procdump+0x5a>
  }
}
    80002562:	60a6                	ld	ra,72(sp)
    80002564:	6406                	ld	s0,64(sp)
    80002566:	74e2                	ld	s1,56(sp)
    80002568:	7942                	ld	s2,48(sp)
    8000256a:	79a2                	ld	s3,40(sp)
    8000256c:	7a02                	ld	s4,32(sp)
    8000256e:	6ae2                	ld	s5,24(sp)
    80002570:	6b42                	ld	s6,16(sp)
    80002572:	6ba2                	ld	s7,8(sp)
    80002574:	6161                	addi	sp,sp,80
    80002576:	8082                	ret

0000000080002578 <kgetpstat>:

//Leyuan & Lee
uint64 kgetpstat(struct pstat *ps)
{
    80002578:	1141                	addi	sp,sp,-16
    8000257a:	e422                	sd	s0,8(sp)
    8000257c:	0800                	addi	s0,sp,16
  for (int i = 0; i < NPROC; ++i)
    8000257e:	0000f797          	auipc	a5,0xf
    80002582:	17a78793          	addi	a5,a5,378 # 800116f8 <proc+0x18>
    80002586:	00015697          	auipc	a3,0x15
    8000258a:	17268693          	addi	a3,a3,370 # 800176f8 <bcache>
  {
    struct proc *p = proc + i;
    ps->inuse[i] = p->state == UNUSED ? 0 : 1;
    8000258e:	4398                	lw	a4,0(a5)
    80002590:	00e03733          	snez	a4,a4
    80002594:	c118                	sw	a4,0(a0)
    ps->ticks[i] = p->ticks;
    80002596:	1507a703          	lw	a4,336(a5)
    8000259a:	20e52023          	sw	a4,512(a0)
    ps->pid[i] = p->pid;
    8000259e:	4f98                	lw	a4,24(a5)
    800025a0:	10e52023          	sw	a4,256(a0)
    ps->queue[i] = 0;
    800025a4:	30052023          	sw	zero,768(a0)
  for (int i = 0; i < NPROC; ++i)
    800025a8:	18078793          	addi	a5,a5,384
    800025ac:	0511                	addi	a0,a0,4
    800025ae:	fed790e3          	bne	a5,a3,8000258e <kgetpstat+0x16>
  }
  return 0;
    800025b2:	4501                	li	a0,0
    800025b4:	6422                	ld	s0,8(sp)
    800025b6:	0141                	addi	sp,sp,16
    800025b8:	8082                	ret

00000000800025ba <swtch>:
    800025ba:	00153023          	sd	ra,0(a0)
    800025be:	00253423          	sd	sp,8(a0)
    800025c2:	e900                	sd	s0,16(a0)
    800025c4:	ed04                	sd	s1,24(a0)
    800025c6:	03253023          	sd	s2,32(a0)
    800025ca:	03353423          	sd	s3,40(a0)
    800025ce:	03453823          	sd	s4,48(a0)
    800025d2:	03553c23          	sd	s5,56(a0)
    800025d6:	05653023          	sd	s6,64(a0)
    800025da:	05753423          	sd	s7,72(a0)
    800025de:	05853823          	sd	s8,80(a0)
    800025e2:	05953c23          	sd	s9,88(a0)
    800025e6:	07a53023          	sd	s10,96(a0)
    800025ea:	07b53423          	sd	s11,104(a0)
    800025ee:	0005b083          	ld	ra,0(a1)
    800025f2:	0085b103          	ld	sp,8(a1)
    800025f6:	6980                	ld	s0,16(a1)
    800025f8:	6d84                	ld	s1,24(a1)
    800025fa:	0205b903          	ld	s2,32(a1)
    800025fe:	0285b983          	ld	s3,40(a1)
    80002602:	0305ba03          	ld	s4,48(a1)
    80002606:	0385ba83          	ld	s5,56(a1)
    8000260a:	0405bb03          	ld	s6,64(a1)
    8000260e:	0485bb83          	ld	s7,72(a1)
    80002612:	0505bc03          	ld	s8,80(a1)
    80002616:	0585bc83          	ld	s9,88(a1)
    8000261a:	0605bd03          	ld	s10,96(a1)
    8000261e:	0685bd83          	ld	s11,104(a1)
    80002622:	8082                	ret

0000000080002624 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002624:	1141                	addi	sp,sp,-16
    80002626:	e406                	sd	ra,8(sp)
    80002628:	e022                	sd	s0,0(sp)
    8000262a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000262c:	00006597          	auipc	a1,0x6
    80002630:	cac58593          	addi	a1,a1,-852 # 800082d8 <states.0+0x30>
    80002634:	00015517          	auipc	a0,0x15
    80002638:	0ac50513          	addi	a0,a0,172 # 800176e0 <tickslock>
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	4f6080e7          	jalr	1270(ra) # 80000b32 <initlock>
}
    80002644:	60a2                	ld	ra,8(sp)
    80002646:	6402                	ld	s0,0(sp)
    80002648:	0141                	addi	sp,sp,16
    8000264a:	8082                	ret

000000008000264c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000264c:	1141                	addi	sp,sp,-16
    8000264e:	e422                	sd	s0,8(sp)
    80002650:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002652:	00003797          	auipc	a5,0x3
    80002656:	50e78793          	addi	a5,a5,1294 # 80005b60 <kernelvec>
    8000265a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000265e:	6422                	ld	s0,8(sp)
    80002660:	0141                	addi	sp,sp,16
    80002662:	8082                	ret

0000000080002664 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002664:	1141                	addi	sp,sp,-16
    80002666:	e406                	sd	ra,8(sp)
    80002668:	e022                	sd	s0,0(sp)
    8000266a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	312080e7          	jalr	786(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002674:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002678:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000267a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000267e:	00005617          	auipc	a2,0x5
    80002682:	98260613          	addi	a2,a2,-1662 # 80007000 <_trampoline>
    80002686:	00005697          	auipc	a3,0x5
    8000268a:	97a68693          	addi	a3,a3,-1670 # 80007000 <_trampoline>
    8000268e:	8e91                	sub	a3,a3,a2
    80002690:	040007b7          	lui	a5,0x4000
    80002694:	17fd                	addi	a5,a5,-1
    80002696:	07b2                	slli	a5,a5,0xc
    80002698:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000269a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000269e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026a0:	180026f3          	csrr	a3,satp
    800026a4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026a6:	6d38                	ld	a4,88(a0)
    800026a8:	6134                	ld	a3,64(a0)
    800026aa:	6585                	lui	a1,0x1
    800026ac:	96ae                	add	a3,a3,a1
    800026ae:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026b0:	6d38                	ld	a4,88(a0)
    800026b2:	00000697          	auipc	a3,0x0
    800026b6:	13868693          	addi	a3,a3,312 # 800027ea <usertrap>
    800026ba:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026bc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026be:	8692                	mv	a3,tp
    800026c0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026c6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026ca:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ce:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026d2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026d4:	6f18                	ld	a4,24(a4)
    800026d6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026da:	692c                	ld	a1,80(a0)
    800026dc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026de:	00005717          	auipc	a4,0x5
    800026e2:	9b270713          	addi	a4,a4,-1614 # 80007090 <userret>
    800026e6:	8f11                	sub	a4,a4,a2
    800026e8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026ea:	577d                	li	a4,-1
    800026ec:	177e                	slli	a4,a4,0x3f
    800026ee:	8dd9                	or	a1,a1,a4
    800026f0:	02000537          	lui	a0,0x2000
    800026f4:	157d                	addi	a0,a0,-1
    800026f6:	0536                	slli	a0,a0,0xd
    800026f8:	9782                	jalr	a5
}
    800026fa:	60a2                	ld	ra,8(sp)
    800026fc:	6402                	ld	s0,0(sp)
    800026fe:	0141                	addi	sp,sp,16
    80002700:	8082                	ret

0000000080002702 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002702:	1101                	addi	sp,sp,-32
    80002704:	ec06                	sd	ra,24(sp)
    80002706:	e822                	sd	s0,16(sp)
    80002708:	e426                	sd	s1,8(sp)
    8000270a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000270c:	00015497          	auipc	s1,0x15
    80002710:	fd448493          	addi	s1,s1,-44 # 800176e0 <tickslock>
    80002714:	8526                	mv	a0,s1
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	4ac080e7          	jalr	1196(ra) # 80000bc2 <acquire>
  ticks++;
    8000271e:	00007517          	auipc	a0,0x7
    80002722:	92250513          	addi	a0,a0,-1758 # 80009040 <ticks>
    80002726:	411c                	lw	a5,0(a0)
    80002728:	2785                	addiw	a5,a5,1
    8000272a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000272c:	00000097          	auipc	ra,0x0
    80002730:	ada080e7          	jalr	-1318(ra) # 80002206 <wakeup>
  release(&tickslock);
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	540080e7          	jalr	1344(ra) # 80000c76 <release>
}
    8000273e:	60e2                	ld	ra,24(sp)
    80002740:	6442                	ld	s0,16(sp)
    80002742:	64a2                	ld	s1,8(sp)
    80002744:	6105                	addi	sp,sp,32
    80002746:	8082                	ret

0000000080002748 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002748:	1101                	addi	sp,sp,-32
    8000274a:	ec06                	sd	ra,24(sp)
    8000274c:	e822                	sd	s0,16(sp)
    8000274e:	e426                	sd	s1,8(sp)
    80002750:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002752:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002756:	00074d63          	bltz	a4,80002770 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000275a:	57fd                	li	a5,-1
    8000275c:	17fe                	slli	a5,a5,0x3f
    8000275e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002760:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002762:	06f70363          	beq	a4,a5,800027c8 <devintr+0x80>
  }
}
    80002766:	60e2                	ld	ra,24(sp)
    80002768:	6442                	ld	s0,16(sp)
    8000276a:	64a2                	ld	s1,8(sp)
    8000276c:	6105                	addi	sp,sp,32
    8000276e:	8082                	ret
     (scause & 0xff) == 9){
    80002770:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002774:	46a5                	li	a3,9
    80002776:	fed792e3          	bne	a5,a3,8000275a <devintr+0x12>
    int irq = plic_claim();
    8000277a:	00003097          	auipc	ra,0x3
    8000277e:	4ee080e7          	jalr	1262(ra) # 80005c68 <plic_claim>
    80002782:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002784:	47a9                	li	a5,10
    80002786:	02f50763          	beq	a0,a5,800027b4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000278a:	4785                	li	a5,1
    8000278c:	02f50963          	beq	a0,a5,800027be <devintr+0x76>
    return 1;
    80002790:	4505                	li	a0,1
    } else if(irq){
    80002792:	d8f1                	beqz	s1,80002766 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002794:	85a6                	mv	a1,s1
    80002796:	00006517          	auipc	a0,0x6
    8000279a:	b4a50513          	addi	a0,a0,-1206 # 800082e0 <states.0+0x38>
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	dd6080e7          	jalr	-554(ra) # 80000574 <printf>
      plic_complete(irq);
    800027a6:	8526                	mv	a0,s1
    800027a8:	00003097          	auipc	ra,0x3
    800027ac:	4e4080e7          	jalr	1252(ra) # 80005c8c <plic_complete>
    return 1;
    800027b0:	4505                	li	a0,1
    800027b2:	bf55                	j	80002766 <devintr+0x1e>
      uartintr();
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	1d2080e7          	jalr	466(ra) # 80000986 <uartintr>
    800027bc:	b7ed                	j	800027a6 <devintr+0x5e>
      virtio_disk_intr();
    800027be:	00004097          	auipc	ra,0x4
    800027c2:	960080e7          	jalr	-1696(ra) # 8000611e <virtio_disk_intr>
    800027c6:	b7c5                	j	800027a6 <devintr+0x5e>
    if(cpuid() == 0){
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	18a080e7          	jalr	394(ra) # 80001952 <cpuid>
    800027d0:	c901                	beqz	a0,800027e0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027d2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027d6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027d8:	14479073          	csrw	sip,a5
    return 2;
    800027dc:	4509                	li	a0,2
    800027de:	b761                	j	80002766 <devintr+0x1e>
      clockintr();
    800027e0:	00000097          	auipc	ra,0x0
    800027e4:	f22080e7          	jalr	-222(ra) # 80002702 <clockintr>
    800027e8:	b7ed                	j	800027d2 <devintr+0x8a>

00000000800027ea <usertrap>:
{
    800027ea:	1101                	addi	sp,sp,-32
    800027ec:	ec06                	sd	ra,24(sp)
    800027ee:	e822                	sd	s0,16(sp)
    800027f0:	e426                	sd	s1,8(sp)
    800027f2:	e04a                	sd	s2,0(sp)
    800027f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027fa:	1007f793          	andi	a5,a5,256
    800027fe:	e3ad                	bnez	a5,80002860 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002800:	00003797          	auipc	a5,0x3
    80002804:	36078793          	addi	a5,a5,864 # 80005b60 <kernelvec>
    80002808:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	172080e7          	jalr	370(ra) # 8000197e <myproc>
    80002814:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002816:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002818:	14102773          	csrr	a4,sepc
    8000281c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000281e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002822:	47a1                	li	a5,8
    80002824:	04f71c63          	bne	a4,a5,8000287c <usertrap+0x92>
    if(p->killed)
    80002828:	551c                	lw	a5,40(a0)
    8000282a:	e3b9                	bnez	a5,80002870 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000282c:	6cb8                	ld	a4,88(s1)
    8000282e:	6f1c                	ld	a5,24(a4)
    80002830:	0791                	addi	a5,a5,4
    80002832:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002834:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002838:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000283c:	10079073          	csrw	sstatus,a5
    syscall();
    80002840:	00000097          	auipc	ra,0x0
    80002844:	2e0080e7          	jalr	736(ra) # 80002b20 <syscall>
  if(p->killed)
    80002848:	549c                	lw	a5,40(s1)
    8000284a:	ebc1                	bnez	a5,800028da <usertrap+0xf0>
  usertrapret();
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	e18080e7          	jalr	-488(ra) # 80002664 <usertrapret>
}
    80002854:	60e2                	ld	ra,24(sp)
    80002856:	6442                	ld	s0,16(sp)
    80002858:	64a2                	ld	s1,8(sp)
    8000285a:	6902                	ld	s2,0(sp)
    8000285c:	6105                	addi	sp,sp,32
    8000285e:	8082                	ret
    panic("usertrap: not from user mode");
    80002860:	00006517          	auipc	a0,0x6
    80002864:	aa050513          	addi	a0,a0,-1376 # 80008300 <states.0+0x58>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	cc2080e7          	jalr	-830(ra) # 8000052a <panic>
      exit(-1);
    80002870:	557d                	li	a0,-1
    80002872:	00000097          	auipc	ra,0x0
    80002876:	a64080e7          	jalr	-1436(ra) # 800022d6 <exit>
    8000287a:	bf4d                	j	8000282c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	ecc080e7          	jalr	-308(ra) # 80002748 <devintr>
    80002884:	892a                	mv	s2,a0
    80002886:	c501                	beqz	a0,8000288e <usertrap+0xa4>
  if(p->killed)
    80002888:	549c                	lw	a5,40(s1)
    8000288a:	c3a1                	beqz	a5,800028ca <usertrap+0xe0>
    8000288c:	a815                	j	800028c0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002892:	5890                	lw	a2,48(s1)
    80002894:	00006517          	auipc	a0,0x6
    80002898:	a8c50513          	addi	a0,a0,-1396 # 80008320 <states.0+0x78>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	cd8080e7          	jalr	-808(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028a8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ac:	00006517          	auipc	a0,0x6
    800028b0:	aa450513          	addi	a0,a0,-1372 # 80008350 <states.0+0xa8>
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	cc0080e7          	jalr	-832(ra) # 80000574 <printf>
    p->killed = 1;
    800028bc:	4785                	li	a5,1
    800028be:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028c0:	557d                	li	a0,-1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	a14080e7          	jalr	-1516(ra) # 800022d6 <exit>
  if(which_dev == 2)
    800028ca:	4789                	li	a5,2
    800028cc:	f8f910e3          	bne	s2,a5,8000284c <usertrap+0x62>
    yield();
    800028d0:	fffff097          	auipc	ra,0xfffff
    800028d4:	73a080e7          	jalr	1850(ra) # 8000200a <yield>
    800028d8:	bf95                	j	8000284c <usertrap+0x62>
  int which_dev = 0;
    800028da:	4901                	li	s2,0
    800028dc:	b7d5                	j	800028c0 <usertrap+0xd6>

00000000800028de <kerneltrap>:
{
    800028de:	7179                	addi	sp,sp,-48
    800028e0:	f406                	sd	ra,40(sp)
    800028e2:	f022                	sd	s0,32(sp)
    800028e4:	ec26                	sd	s1,24(sp)
    800028e6:	e84a                	sd	s2,16(sp)
    800028e8:	e44e                	sd	s3,8(sp)
    800028ea:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028f8:	1004f793          	andi	a5,s1,256
    800028fc:	cb85                	beqz	a5,8000292c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002902:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002904:	ef85                	bnez	a5,8000293c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	e42080e7          	jalr	-446(ra) # 80002748 <devintr>
    8000290e:	cd1d                	beqz	a0,8000294c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002910:	4789                	li	a5,2
    80002912:	06f50a63          	beq	a0,a5,80002986 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002916:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000291a:	10049073          	csrw	sstatus,s1
}
    8000291e:	70a2                	ld	ra,40(sp)
    80002920:	7402                	ld	s0,32(sp)
    80002922:	64e2                	ld	s1,24(sp)
    80002924:	6942                	ld	s2,16(sp)
    80002926:	69a2                	ld	s3,8(sp)
    80002928:	6145                	addi	sp,sp,48
    8000292a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	a4450513          	addi	a0,a0,-1468 # 80008370 <states.0+0xc8>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	bf6080e7          	jalr	-1034(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a5c50513          	addi	a0,a0,-1444 # 80008398 <states.0+0xf0>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	be6080e7          	jalr	-1050(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000294c:	85ce                	mv	a1,s3
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	a6a50513          	addi	a0,a0,-1430 # 800083b8 <states.0+0x110>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	c1e080e7          	jalr	-994(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002962:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	a6250513          	addi	a0,a0,-1438 # 800083c8 <states.0+0x120>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c06080e7          	jalr	-1018(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	a6a50513          	addi	a0,a0,-1430 # 800083e0 <states.0+0x138>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	bac080e7          	jalr	-1108(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	ff8080e7          	jalr	-8(ra) # 8000197e <myproc>
    8000298e:	d541                	beqz	a0,80002916 <kerneltrap+0x38>
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	fee080e7          	jalr	-18(ra) # 8000197e <myproc>
    80002998:	4d18                	lw	a4,24(a0)
    8000299a:	4791                	li	a5,4
    8000299c:	f6f71de3          	bne	a4,a5,80002916 <kerneltrap+0x38>
    yield();
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	66a080e7          	jalr	1642(ra) # 8000200a <yield>
    800029a8:	b7bd                	j	80002916 <kerneltrap+0x38>

00000000800029aa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029aa:	1101                	addi	sp,sp,-32
    800029ac:	ec06                	sd	ra,24(sp)
    800029ae:	e822                	sd	s0,16(sp)
    800029b0:	e426                	sd	s1,8(sp)
    800029b2:	1000                	addi	s0,sp,32
    800029b4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	fc8080e7          	jalr	-56(ra) # 8000197e <myproc>
  switch (n) {
    800029be:	4795                	li	a5,5
    800029c0:	0497e163          	bltu	a5,s1,80002a02 <argraw+0x58>
    800029c4:	048a                	slli	s1,s1,0x2
    800029c6:	00006717          	auipc	a4,0x6
    800029ca:	a5270713          	addi	a4,a4,-1454 # 80008418 <states.0+0x170>
    800029ce:	94ba                	add	s1,s1,a4
    800029d0:	409c                	lw	a5,0(s1)
    800029d2:	97ba                	add	a5,a5,a4
    800029d4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029d6:	6d3c                	ld	a5,88(a0)
    800029d8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029da:	60e2                	ld	ra,24(sp)
    800029dc:	6442                	ld	s0,16(sp)
    800029de:	64a2                	ld	s1,8(sp)
    800029e0:	6105                	addi	sp,sp,32
    800029e2:	8082                	ret
    return p->trapframe->a1;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	7fa8                	ld	a0,120(a5)
    800029e8:	bfcd                	j	800029da <argraw+0x30>
    return p->trapframe->a2;
    800029ea:	6d3c                	ld	a5,88(a0)
    800029ec:	63c8                	ld	a0,128(a5)
    800029ee:	b7f5                	j	800029da <argraw+0x30>
    return p->trapframe->a3;
    800029f0:	6d3c                	ld	a5,88(a0)
    800029f2:	67c8                	ld	a0,136(a5)
    800029f4:	b7dd                	j	800029da <argraw+0x30>
    return p->trapframe->a4;
    800029f6:	6d3c                	ld	a5,88(a0)
    800029f8:	6bc8                	ld	a0,144(a5)
    800029fa:	b7c5                	j	800029da <argraw+0x30>
    return p->trapframe->a5;
    800029fc:	6d3c                	ld	a5,88(a0)
    800029fe:	6fc8                	ld	a0,152(a5)
    80002a00:	bfe9                	j	800029da <argraw+0x30>
  panic("argraw");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	9ee50513          	addi	a0,a0,-1554 # 800083f0 <states.0+0x148>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b20080e7          	jalr	-1248(ra) # 8000052a <panic>

0000000080002a12 <fetchaddr>:
{
    80002a12:	1101                	addi	sp,sp,-32
    80002a14:	ec06                	sd	ra,24(sp)
    80002a16:	e822                	sd	s0,16(sp)
    80002a18:	e426                	sd	s1,8(sp)
    80002a1a:	e04a                	sd	s2,0(sp)
    80002a1c:	1000                	addi	s0,sp,32
    80002a1e:	84aa                	mv	s1,a0
    80002a20:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	f5c080e7          	jalr	-164(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a2a:	653c                	ld	a5,72(a0)
    80002a2c:	02f4f863          	bgeu	s1,a5,80002a5c <fetchaddr+0x4a>
    80002a30:	00848713          	addi	a4,s1,8
    80002a34:	02e7e663          	bltu	a5,a4,80002a60 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a38:	46a1                	li	a3,8
    80002a3a:	8626                	mv	a2,s1
    80002a3c:	85ca                	mv	a1,s2
    80002a3e:	6928                	ld	a0,80(a0)
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	c8a080e7          	jalr	-886(ra) # 800016ca <copyin>
    80002a48:	00a03533          	snez	a0,a0
    80002a4c:	40a00533          	neg	a0,a0
}
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6902                	ld	s2,0(sp)
    80002a58:	6105                	addi	sp,sp,32
    80002a5a:	8082                	ret
    return -1;
    80002a5c:	557d                	li	a0,-1
    80002a5e:	bfcd                	j	80002a50 <fetchaddr+0x3e>
    80002a60:	557d                	li	a0,-1
    80002a62:	b7fd                	j	80002a50 <fetchaddr+0x3e>

0000000080002a64 <fetchstr>:
{
    80002a64:	7179                	addi	sp,sp,-48
    80002a66:	f406                	sd	ra,40(sp)
    80002a68:	f022                	sd	s0,32(sp)
    80002a6a:	ec26                	sd	s1,24(sp)
    80002a6c:	e84a                	sd	s2,16(sp)
    80002a6e:	e44e                	sd	s3,8(sp)
    80002a70:	1800                	addi	s0,sp,48
    80002a72:	892a                	mv	s2,a0
    80002a74:	84ae                	mv	s1,a1
    80002a76:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f06080e7          	jalr	-250(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a80:	86ce                	mv	a3,s3
    80002a82:	864a                	mv	a2,s2
    80002a84:	85a6                	mv	a1,s1
    80002a86:	6928                	ld	a0,80(a0)
    80002a88:	fffff097          	auipc	ra,0xfffff
    80002a8c:	cd0080e7          	jalr	-816(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002a90:	00054763          	bltz	a0,80002a9e <fetchstr+0x3a>
  return strlen(buf);
    80002a94:	8526                	mv	a0,s1
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	3ac080e7          	jalr	940(ra) # 80000e42 <strlen>
}
    80002a9e:	70a2                	ld	ra,40(sp)
    80002aa0:	7402                	ld	s0,32(sp)
    80002aa2:	64e2                	ld	s1,24(sp)
    80002aa4:	6942                	ld	s2,16(sp)
    80002aa6:	69a2                	ld	s3,8(sp)
    80002aa8:	6145                	addi	sp,sp,48
    80002aaa:	8082                	ret

0000000080002aac <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002aac:	1101                	addi	sp,sp,-32
    80002aae:	ec06                	sd	ra,24(sp)
    80002ab0:	e822                	sd	s0,16(sp)
    80002ab2:	e426                	sd	s1,8(sp)
    80002ab4:	1000                	addi	s0,sp,32
    80002ab6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	ef2080e7          	jalr	-270(ra) # 800029aa <argraw>
    80002ac0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ac2:	4501                	li	a0,0
    80002ac4:	60e2                	ld	ra,24(sp)
    80002ac6:	6442                	ld	s0,16(sp)
    80002ac8:	64a2                	ld	s1,8(sp)
    80002aca:	6105                	addi	sp,sp,32
    80002acc:	8082                	ret

0000000080002ace <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ace:	1101                	addi	sp,sp,-32
    80002ad0:	ec06                	sd	ra,24(sp)
    80002ad2:	e822                	sd	s0,16(sp)
    80002ad4:	e426                	sd	s1,8(sp)
    80002ad6:	1000                	addi	s0,sp,32
    80002ad8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	ed0080e7          	jalr	-304(ra) # 800029aa <argraw>
    80002ae2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ae4:	4501                	li	a0,0
    80002ae6:	60e2                	ld	ra,24(sp)
    80002ae8:	6442                	ld	s0,16(sp)
    80002aea:	64a2                	ld	s1,8(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret

0000000080002af0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002af0:	1101                	addi	sp,sp,-32
    80002af2:	ec06                	sd	ra,24(sp)
    80002af4:	e822                	sd	s0,16(sp)
    80002af6:	e426                	sd	s1,8(sp)
    80002af8:	e04a                	sd	s2,0(sp)
    80002afa:	1000                	addi	s0,sp,32
    80002afc:	84ae                	mv	s1,a1
    80002afe:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	eaa080e7          	jalr	-342(ra) # 800029aa <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b08:	864a                	mv	a2,s2
    80002b0a:	85a6                	mv	a1,s1
    80002b0c:	00000097          	auipc	ra,0x0
    80002b10:	f58080e7          	jalr	-168(ra) # 80002a64 <fetchstr>
}
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6902                	ld	s2,0(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret

0000000080002b20 <syscall>:

};

void
syscall(void)
{
    80002b20:	1101                	addi	sp,sp,-32
    80002b22:	ec06                	sd	ra,24(sp)
    80002b24:	e822                	sd	s0,16(sp)
    80002b26:	e426                	sd	s1,8(sp)
    80002b28:	e04a                	sd	s2,0(sp)
    80002b2a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	e52080e7          	jalr	-430(ra) # 8000197e <myproc>
    80002b34:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b36:	05853903          	ld	s2,88(a0)
    80002b3a:	0a893783          	ld	a5,168(s2)
    80002b3e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b42:	37fd                	addiw	a5,a5,-1
    80002b44:	4755                	li	a4,21
    80002b46:	00f76f63          	bltu	a4,a5,80002b64 <syscall+0x44>
    80002b4a:	00369713          	slli	a4,a3,0x3
    80002b4e:	00006797          	auipc	a5,0x6
    80002b52:	8e278793          	addi	a5,a5,-1822 # 80008430 <syscalls>
    80002b56:	97ba                	add	a5,a5,a4
    80002b58:	639c                	ld	a5,0(a5)
    80002b5a:	c789                	beqz	a5,80002b64 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b5c:	9782                	jalr	a5
    80002b5e:	06a93823          	sd	a0,112(s2)
    80002b62:	a839                	j	80002b80 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b64:	15848613          	addi	a2,s1,344
    80002b68:	588c                	lw	a1,48(s1)
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	88e50513          	addi	a0,a0,-1906 # 800083f8 <states.0+0x150>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	a02080e7          	jalr	-1534(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b7a:	6cbc                	ld	a5,88(s1)
    80002b7c:	577d                	li	a4,-1
    80002b7e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b80:	60e2                	ld	ra,24(sp)
    80002b82:	6442                	ld	s0,16(sp)
    80002b84:	64a2                	ld	s1,8(sp)
    80002b86:	6902                	ld	s2,0(sp)
    80002b88:	6105                	addi	sp,sp,32
    80002b8a:	8082                	ret

0000000080002b8c <sys_exit>:
#include "proc.h"
#include "pstat.h"

uint64
sys_exit(void)
{
    80002b8c:	1101                	addi	sp,sp,-32
    80002b8e:	ec06                	sd	ra,24(sp)
    80002b90:	e822                	sd	s0,16(sp)
    80002b92:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b94:	fec40593          	addi	a1,s0,-20
    80002b98:	4501                	li	a0,0
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	f12080e7          	jalr	-238(ra) # 80002aac <argint>
    return -1;
    80002ba2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ba4:	00054963          	bltz	a0,80002bb6 <sys_exit+0x2a>
  exit(n);
    80002ba8:	fec42503          	lw	a0,-20(s0)
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	72a080e7          	jalr	1834(ra) # 800022d6 <exit>
  return 0;  // not reached
    80002bb4:	4781                	li	a5,0
}
    80002bb6:	853e                	mv	a0,a5
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret

0000000080002bc0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bc0:	1141                	addi	sp,sp,-16
    80002bc2:	e406                	sd	ra,8(sp)
    80002bc4:	e022                	sd	s0,0(sp)
    80002bc6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	db6080e7          	jalr	-586(ra) # 8000197e <myproc>
}
    80002bd0:	5908                	lw	a0,48(a0)
    80002bd2:	60a2                	ld	ra,8(sp)
    80002bd4:	6402                	ld	s0,0(sp)
    80002bd6:	0141                	addi	sp,sp,16
    80002bd8:	8082                	ret

0000000080002bda <sys_fork>:

uint64
sys_fork(void)
{
    80002bda:	1141                	addi	sp,sp,-16
    80002bdc:	e406                	sd	ra,8(sp)
    80002bde:	e022                	sd	s0,0(sp)
    80002be0:	0800                	addi	s0,sp,16
  return fork();
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	172080e7          	jalr	370(ra) # 80001d54 <fork>
}
    80002bea:	60a2                	ld	ra,8(sp)
    80002bec:	6402                	ld	s0,0(sp)
    80002bee:	0141                	addi	sp,sp,16
    80002bf0:	8082                	ret

0000000080002bf2 <sys_wait>:

uint64
sys_wait(void)
{
    80002bf2:	1101                	addi	sp,sp,-32
    80002bf4:	ec06                	sd	ra,24(sp)
    80002bf6:	e822                	sd	s0,16(sp)
    80002bf8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bfa:	fe840593          	addi	a1,s0,-24
    80002bfe:	4501                	li	a0,0
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	ece080e7          	jalr	-306(ra) # 80002ace <argaddr>
    80002c08:	87aa                	mv	a5,a0
    return -1;
    80002c0a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c0c:	0007c863          	bltz	a5,80002c1c <sys_wait+0x2a>
  return wait(p);
    80002c10:	fe843503          	ld	a0,-24(s0)
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	4ca080e7          	jalr	1226(ra) # 800020de <wait>
}
    80002c1c:	60e2                	ld	ra,24(sp)
    80002c1e:	6442                	ld	s0,16(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c24:	7179                	addi	sp,sp,-48
    80002c26:	f406                	sd	ra,40(sp)
    80002c28:	f022                	sd	s0,32(sp)
    80002c2a:	ec26                	sd	s1,24(sp)
    80002c2c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c2e:	fdc40593          	addi	a1,s0,-36
    80002c32:	4501                	li	a0,0
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	e78080e7          	jalr	-392(ra) # 80002aac <argint>
    return -1;
    80002c3c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c3e:	00054f63          	bltz	a0,80002c5c <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	d3c080e7          	jalr	-708(ra) # 8000197e <myproc>
    80002c4a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c4c:	fdc42503          	lw	a0,-36(s0)
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	090080e7          	jalr	144(ra) # 80001ce0 <growproc>
    80002c58:	00054863          	bltz	a0,80002c68 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c5c:	8526                	mv	a0,s1
    80002c5e:	70a2                	ld	ra,40(sp)
    80002c60:	7402                	ld	s0,32(sp)
    80002c62:	64e2                	ld	s1,24(sp)
    80002c64:	6145                	addi	sp,sp,48
    80002c66:	8082                	ret
    return -1;
    80002c68:	54fd                	li	s1,-1
    80002c6a:	bfcd                	j	80002c5c <sys_sbrk+0x38>

0000000080002c6c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c6c:	7139                	addi	sp,sp,-64
    80002c6e:	fc06                	sd	ra,56(sp)
    80002c70:	f822                	sd	s0,48(sp)
    80002c72:	f426                	sd	s1,40(sp)
    80002c74:	f04a                	sd	s2,32(sp)
    80002c76:	ec4e                	sd	s3,24(sp)
    80002c78:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c7a:	fcc40593          	addi	a1,s0,-52
    80002c7e:	4501                	li	a0,0
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	e2c080e7          	jalr	-468(ra) # 80002aac <argint>
    return -1;
    80002c88:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c8a:	06054563          	bltz	a0,80002cf4 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c8e:	00015517          	auipc	a0,0x15
    80002c92:	a5250513          	addi	a0,a0,-1454 # 800176e0 <tickslock>
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	f2c080e7          	jalr	-212(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002c9e:	00006917          	auipc	s2,0x6
    80002ca2:	3a292903          	lw	s2,930(s2) # 80009040 <ticks>
  while(ticks - ticks0 < n){
    80002ca6:	fcc42783          	lw	a5,-52(s0)
    80002caa:	cf85                	beqz	a5,80002ce2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cac:	00015997          	auipc	s3,0x15
    80002cb0:	a3498993          	addi	s3,s3,-1484 # 800176e0 <tickslock>
    80002cb4:	00006497          	auipc	s1,0x6
    80002cb8:	38c48493          	addi	s1,s1,908 # 80009040 <ticks>
    if(myproc()->killed){
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	cc2080e7          	jalr	-830(ra) # 8000197e <myproc>
    80002cc4:	551c                	lw	a5,40(a0)
    80002cc6:	ef9d                	bnez	a5,80002d04 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cc8:	85ce                	mv	a1,s3
    80002cca:	8526                	mv	a0,s1
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	3ae080e7          	jalr	942(ra) # 8000207a <sleep>
  while(ticks - ticks0 < n){
    80002cd4:	409c                	lw	a5,0(s1)
    80002cd6:	412787bb          	subw	a5,a5,s2
    80002cda:	fcc42703          	lw	a4,-52(s0)
    80002cde:	fce7efe3          	bltu	a5,a4,80002cbc <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ce2:	00015517          	auipc	a0,0x15
    80002ce6:	9fe50513          	addi	a0,a0,-1538 # 800176e0 <tickslock>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	f8c080e7          	jalr	-116(ra) # 80000c76 <release>
  return 0;
    80002cf2:	4781                	li	a5,0
}
    80002cf4:	853e                	mv	a0,a5
    80002cf6:	70e2                	ld	ra,56(sp)
    80002cf8:	7442                	ld	s0,48(sp)
    80002cfa:	74a2                	ld	s1,40(sp)
    80002cfc:	7902                	ld	s2,32(sp)
    80002cfe:	69e2                	ld	s3,24(sp)
    80002d00:	6121                	addi	sp,sp,64
    80002d02:	8082                	ret
      release(&tickslock);
    80002d04:	00015517          	auipc	a0,0x15
    80002d08:	9dc50513          	addi	a0,a0,-1572 # 800176e0 <tickslock>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	f6a080e7          	jalr	-150(ra) # 80000c76 <release>
      return -1;
    80002d14:	57fd                	li	a5,-1
    80002d16:	bff9                	j	80002cf4 <sys_sleep+0x88>

0000000080002d18 <sys_kill>:

uint64
sys_kill(void)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d20:	fec40593          	addi	a1,s0,-20
    80002d24:	4501                	li	a0,0
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	d86080e7          	jalr	-634(ra) # 80002aac <argint>
    80002d2e:	87aa                	mv	a5,a0
    return -1;
    80002d30:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d32:	0007c863          	bltz	a5,80002d42 <sys_kill+0x2a>
  return kill(pid);
    80002d36:	fec42503          	lw	a0,-20(s0)
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	672080e7          	jalr	1650(ra) # 800023ac <kill>
}
    80002d42:	60e2                	ld	ra,24(sp)
    80002d44:	6442                	ld	s0,16(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret

0000000080002d4a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	e426                	sd	s1,8(sp)
    80002d52:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d54:	00015517          	auipc	a0,0x15
    80002d58:	98c50513          	addi	a0,a0,-1652 # 800176e0 <tickslock>
    80002d5c:	ffffe097          	auipc	ra,0xffffe
    80002d60:	e66080e7          	jalr	-410(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002d64:	00006497          	auipc	s1,0x6
    80002d68:	2dc4a483          	lw	s1,732(s1) # 80009040 <ticks>
  release(&tickslock);
    80002d6c:	00015517          	auipc	a0,0x15
    80002d70:	97450513          	addi	a0,a0,-1676 # 800176e0 <tickslock>
    80002d74:	ffffe097          	auipc	ra,0xffffe
    80002d78:	f02080e7          	jalr	-254(ra) # 80000c76 <release>
  return xticks;
}
    80002d7c:	02049513          	slli	a0,s1,0x20
    80002d80:	9101                	srli	a0,a0,0x20
    80002d82:	60e2                	ld	ra,24(sp)
    80002d84:	6442                	ld	s0,16(sp)
    80002d86:	64a2                	ld	s1,8(sp)
    80002d88:	6105                	addi	sp,sp,32
    80002d8a:	8082                	ret

0000000080002d8c <sys_getpstat>:

// Leyuan & Lee
//Added new sys call
uint64
sys_getpstat(void)
{
    80002d8c:	bd010113          	addi	sp,sp,-1072
    80002d90:	42113423          	sd	ra,1064(sp)
    80002d94:	42813023          	sd	s0,1056(sp)
    80002d98:	40913c23          	sd	s1,1048(sp)
    80002d9c:	41213823          	sd	s2,1040(sp)
    80002da0:	43010413          	addi	s0,sp,1072
  struct proc *p = myproc();
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	bda080e7          	jalr	-1062(ra) # 8000197e <myproc>
    80002dac:	892a                	mv	s2,a0
  uint64 upstat; // user virtual address, pointing to a struct pstat
  struct pstat kpstat; // struct pstat in kernel memory

  // get system call argument
  if(argaddr(0, &upstat) < 0)
    80002dae:	fd840593          	addi	a1,s0,-40
    80002db2:	4501                	li	a0,0
    80002db4:	00000097          	auipc	ra,0x0
    80002db8:	d1a080e7          	jalr	-742(ra) # 80002ace <argaddr>
    return -1;
    80002dbc:	54fd                	li	s1,-1
  if(argaddr(0, &upstat) < 0)
    80002dbe:	02054763          	bltz	a0,80002dec <sys_getpstat+0x60>
  
 // TODO: define kernel side kgetpstat(struct pstat* ps), its purpose is to fill the values into kpstat.
  uint64 result = kgetpstat(&kpstat);
    80002dc2:	bd840513          	addi	a0,s0,-1064
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	7b2080e7          	jalr	1970(ra) # 80002578 <kgetpstat>
    80002dce:	84aa                	mv	s1,a0

  // copy pstat from kernel memory to user memory
  if(copyout(p->pagetable, upstat, (char *)&kpstat, sizeof(kpstat)) < 0)
    80002dd0:	40000693          	li	a3,1024
    80002dd4:	bd840613          	addi	a2,s0,-1064
    80002dd8:	fd843583          	ld	a1,-40(s0)
    80002ddc:	05093503          	ld	a0,80(s2)
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	85e080e7          	jalr	-1954(ra) # 8000163e <copyout>
    80002de8:	00054e63          	bltz	a0,80002e04 <sys_getpstat+0x78>
    return -1;
  return result;
    80002dec:	8526                	mv	a0,s1
    80002dee:	42813083          	ld	ra,1064(sp)
    80002df2:	42013403          	ld	s0,1056(sp)
    80002df6:	41813483          	ld	s1,1048(sp)
    80002dfa:	41013903          	ld	s2,1040(sp)
    80002dfe:	43010113          	addi	sp,sp,1072
    80002e02:	8082                	ret
    return -1;
    80002e04:	54fd                	li	s1,-1
    80002e06:	b7dd                	j	80002dec <sys_getpstat+0x60>

0000000080002e08 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e08:	7179                	addi	sp,sp,-48
    80002e0a:	f406                	sd	ra,40(sp)
    80002e0c:	f022                	sd	s0,32(sp)
    80002e0e:	ec26                	sd	s1,24(sp)
    80002e10:	e84a                	sd	s2,16(sp)
    80002e12:	e44e                	sd	s3,8(sp)
    80002e14:	e052                	sd	s4,0(sp)
    80002e16:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e18:	00005597          	auipc	a1,0x5
    80002e1c:	6d058593          	addi	a1,a1,1744 # 800084e8 <syscalls+0xb8>
    80002e20:	00015517          	auipc	a0,0x15
    80002e24:	8d850513          	addi	a0,a0,-1832 # 800176f8 <bcache>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	d0a080e7          	jalr	-758(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e30:	0001d797          	auipc	a5,0x1d
    80002e34:	8c878793          	addi	a5,a5,-1848 # 8001f6f8 <bcache+0x8000>
    80002e38:	0001d717          	auipc	a4,0x1d
    80002e3c:	b2870713          	addi	a4,a4,-1240 # 8001f960 <bcache+0x8268>
    80002e40:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e44:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e48:	00015497          	auipc	s1,0x15
    80002e4c:	8c848493          	addi	s1,s1,-1848 # 80017710 <bcache+0x18>
    b->next = bcache.head.next;
    80002e50:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e52:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e54:	00005a17          	auipc	s4,0x5
    80002e58:	69ca0a13          	addi	s4,s4,1692 # 800084f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e5c:	2b893783          	ld	a5,696(s2)
    80002e60:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e62:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e66:	85d2                	mv	a1,s4
    80002e68:	01048513          	addi	a0,s1,16
    80002e6c:	00001097          	auipc	ra,0x1
    80002e70:	4bc080e7          	jalr	1212(ra) # 80004328 <initsleeplock>
    bcache.head.next->prev = b;
    80002e74:	2b893783          	ld	a5,696(s2)
    80002e78:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e7a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e7e:	45848493          	addi	s1,s1,1112
    80002e82:	fd349de3          	bne	s1,s3,80002e5c <binit+0x54>
  }
}
    80002e86:	70a2                	ld	ra,40(sp)
    80002e88:	7402                	ld	s0,32(sp)
    80002e8a:	64e2                	ld	s1,24(sp)
    80002e8c:	6942                	ld	s2,16(sp)
    80002e8e:	69a2                	ld	s3,8(sp)
    80002e90:	6a02                	ld	s4,0(sp)
    80002e92:	6145                	addi	sp,sp,48
    80002e94:	8082                	ret

0000000080002e96 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e96:	7179                	addi	sp,sp,-48
    80002e98:	f406                	sd	ra,40(sp)
    80002e9a:	f022                	sd	s0,32(sp)
    80002e9c:	ec26                	sd	s1,24(sp)
    80002e9e:	e84a                	sd	s2,16(sp)
    80002ea0:	e44e                	sd	s3,8(sp)
    80002ea2:	1800                	addi	s0,sp,48
    80002ea4:	892a                	mv	s2,a0
    80002ea6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ea8:	00015517          	auipc	a0,0x15
    80002eac:	85050513          	addi	a0,a0,-1968 # 800176f8 <bcache>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	d12080e7          	jalr	-750(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eb8:	0001d497          	auipc	s1,0x1d
    80002ebc:	af84b483          	ld	s1,-1288(s1) # 8001f9b0 <bcache+0x82b8>
    80002ec0:	0001d797          	auipc	a5,0x1d
    80002ec4:	aa078793          	addi	a5,a5,-1376 # 8001f960 <bcache+0x8268>
    80002ec8:	02f48f63          	beq	s1,a5,80002f06 <bread+0x70>
    80002ecc:	873e                	mv	a4,a5
    80002ece:	a021                	j	80002ed6 <bread+0x40>
    80002ed0:	68a4                	ld	s1,80(s1)
    80002ed2:	02e48a63          	beq	s1,a4,80002f06 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ed6:	449c                	lw	a5,8(s1)
    80002ed8:	ff279ce3          	bne	a5,s2,80002ed0 <bread+0x3a>
    80002edc:	44dc                	lw	a5,12(s1)
    80002ede:	ff3799e3          	bne	a5,s3,80002ed0 <bread+0x3a>
      b->refcnt++;
    80002ee2:	40bc                	lw	a5,64(s1)
    80002ee4:	2785                	addiw	a5,a5,1
    80002ee6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ee8:	00015517          	auipc	a0,0x15
    80002eec:	81050513          	addi	a0,a0,-2032 # 800176f8 <bcache>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	d86080e7          	jalr	-634(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002ef8:	01048513          	addi	a0,s1,16
    80002efc:	00001097          	auipc	ra,0x1
    80002f00:	466080e7          	jalr	1126(ra) # 80004362 <acquiresleep>
      return b;
    80002f04:	a8b9                	j	80002f62 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f06:	0001d497          	auipc	s1,0x1d
    80002f0a:	aa24b483          	ld	s1,-1374(s1) # 8001f9a8 <bcache+0x82b0>
    80002f0e:	0001d797          	auipc	a5,0x1d
    80002f12:	a5278793          	addi	a5,a5,-1454 # 8001f960 <bcache+0x8268>
    80002f16:	00f48863          	beq	s1,a5,80002f26 <bread+0x90>
    80002f1a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f1c:	40bc                	lw	a5,64(s1)
    80002f1e:	cf81                	beqz	a5,80002f36 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f20:	64a4                	ld	s1,72(s1)
    80002f22:	fee49de3          	bne	s1,a4,80002f1c <bread+0x86>
  panic("bget: no buffers");
    80002f26:	00005517          	auipc	a0,0x5
    80002f2a:	5d250513          	addi	a0,a0,1490 # 800084f8 <syscalls+0xc8>
    80002f2e:	ffffd097          	auipc	ra,0xffffd
    80002f32:	5fc080e7          	jalr	1532(ra) # 8000052a <panic>
      b->dev = dev;
    80002f36:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f3a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f3e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f42:	4785                	li	a5,1
    80002f44:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f46:	00014517          	auipc	a0,0x14
    80002f4a:	7b250513          	addi	a0,a0,1970 # 800176f8 <bcache>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	d28080e7          	jalr	-728(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002f56:	01048513          	addi	a0,s1,16
    80002f5a:	00001097          	auipc	ra,0x1
    80002f5e:	408080e7          	jalr	1032(ra) # 80004362 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f62:	409c                	lw	a5,0(s1)
    80002f64:	cb89                	beqz	a5,80002f76 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f66:	8526                	mv	a0,s1
    80002f68:	70a2                	ld	ra,40(sp)
    80002f6a:	7402                	ld	s0,32(sp)
    80002f6c:	64e2                	ld	s1,24(sp)
    80002f6e:	6942                	ld	s2,16(sp)
    80002f70:	69a2                	ld	s3,8(sp)
    80002f72:	6145                	addi	sp,sp,48
    80002f74:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f76:	4581                	li	a1,0
    80002f78:	8526                	mv	a0,s1
    80002f7a:	00003097          	auipc	ra,0x3
    80002f7e:	f1c080e7          	jalr	-228(ra) # 80005e96 <virtio_disk_rw>
    b->valid = 1;
    80002f82:	4785                	li	a5,1
    80002f84:	c09c                	sw	a5,0(s1)
  return b;
    80002f86:	b7c5                	j	80002f66 <bread+0xd0>

0000000080002f88 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	e426                	sd	s1,8(sp)
    80002f90:	1000                	addi	s0,sp,32
    80002f92:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f94:	0541                	addi	a0,a0,16
    80002f96:	00001097          	auipc	ra,0x1
    80002f9a:	466080e7          	jalr	1126(ra) # 800043fc <holdingsleep>
    80002f9e:	cd01                	beqz	a0,80002fb6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fa0:	4585                	li	a1,1
    80002fa2:	8526                	mv	a0,s1
    80002fa4:	00003097          	auipc	ra,0x3
    80002fa8:	ef2080e7          	jalr	-270(ra) # 80005e96 <virtio_disk_rw>
}
    80002fac:	60e2                	ld	ra,24(sp)
    80002fae:	6442                	ld	s0,16(sp)
    80002fb0:	64a2                	ld	s1,8(sp)
    80002fb2:	6105                	addi	sp,sp,32
    80002fb4:	8082                	ret
    panic("bwrite");
    80002fb6:	00005517          	auipc	a0,0x5
    80002fba:	55a50513          	addi	a0,a0,1370 # 80008510 <syscalls+0xe0>
    80002fbe:	ffffd097          	auipc	ra,0xffffd
    80002fc2:	56c080e7          	jalr	1388(ra) # 8000052a <panic>

0000000080002fc6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fc6:	1101                	addi	sp,sp,-32
    80002fc8:	ec06                	sd	ra,24(sp)
    80002fca:	e822                	sd	s0,16(sp)
    80002fcc:	e426                	sd	s1,8(sp)
    80002fce:	e04a                	sd	s2,0(sp)
    80002fd0:	1000                	addi	s0,sp,32
    80002fd2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fd4:	01050913          	addi	s2,a0,16
    80002fd8:	854a                	mv	a0,s2
    80002fda:	00001097          	auipc	ra,0x1
    80002fde:	422080e7          	jalr	1058(ra) # 800043fc <holdingsleep>
    80002fe2:	c92d                	beqz	a0,80003054 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fe4:	854a                	mv	a0,s2
    80002fe6:	00001097          	auipc	ra,0x1
    80002fea:	3d2080e7          	jalr	978(ra) # 800043b8 <releasesleep>

  acquire(&bcache.lock);
    80002fee:	00014517          	auipc	a0,0x14
    80002ff2:	70a50513          	addi	a0,a0,1802 # 800176f8 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	bcc080e7          	jalr	-1076(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002ffe:	40bc                	lw	a5,64(s1)
    80003000:	37fd                	addiw	a5,a5,-1
    80003002:	0007871b          	sext.w	a4,a5
    80003006:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003008:	eb05                	bnez	a4,80003038 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000300a:	68bc                	ld	a5,80(s1)
    8000300c:	64b8                	ld	a4,72(s1)
    8000300e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003010:	64bc                	ld	a5,72(s1)
    80003012:	68b8                	ld	a4,80(s1)
    80003014:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003016:	0001c797          	auipc	a5,0x1c
    8000301a:	6e278793          	addi	a5,a5,1762 # 8001f6f8 <bcache+0x8000>
    8000301e:	2b87b703          	ld	a4,696(a5)
    80003022:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003024:	0001d717          	auipc	a4,0x1d
    80003028:	93c70713          	addi	a4,a4,-1732 # 8001f960 <bcache+0x8268>
    8000302c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000302e:	2b87b703          	ld	a4,696(a5)
    80003032:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003034:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003038:	00014517          	auipc	a0,0x14
    8000303c:	6c050513          	addi	a0,a0,1728 # 800176f8 <bcache>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	c36080e7          	jalr	-970(ra) # 80000c76 <release>
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6902                	ld	s2,0(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret
    panic("brelse");
    80003054:	00005517          	auipc	a0,0x5
    80003058:	4c450513          	addi	a0,a0,1220 # 80008518 <syscalls+0xe8>
    8000305c:	ffffd097          	auipc	ra,0xffffd
    80003060:	4ce080e7          	jalr	1230(ra) # 8000052a <panic>

0000000080003064 <bpin>:

void
bpin(struct buf *b) {
    80003064:	1101                	addi	sp,sp,-32
    80003066:	ec06                	sd	ra,24(sp)
    80003068:	e822                	sd	s0,16(sp)
    8000306a:	e426                	sd	s1,8(sp)
    8000306c:	1000                	addi	s0,sp,32
    8000306e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	68850513          	addi	a0,a0,1672 # 800176f8 <bcache>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	b4a080e7          	jalr	-1206(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003080:	40bc                	lw	a5,64(s1)
    80003082:	2785                	addiw	a5,a5,1
    80003084:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003086:	00014517          	auipc	a0,0x14
    8000308a:	67250513          	addi	a0,a0,1650 # 800176f8 <bcache>
    8000308e:	ffffe097          	auipc	ra,0xffffe
    80003092:	be8080e7          	jalr	-1048(ra) # 80000c76 <release>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret

00000000800030a0 <bunpin>:

void
bunpin(struct buf *b) {
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ac:	00014517          	auipc	a0,0x14
    800030b0:	64c50513          	addi	a0,a0,1612 # 800176f8 <bcache>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	b0e080e7          	jalr	-1266(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800030bc:	40bc                	lw	a5,64(s1)
    800030be:	37fd                	addiw	a5,a5,-1
    800030c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030c2:	00014517          	auipc	a0,0x14
    800030c6:	63650513          	addi	a0,a0,1590 # 800176f8 <bcache>
    800030ca:	ffffe097          	auipc	ra,0xffffe
    800030ce:	bac080e7          	jalr	-1108(ra) # 80000c76 <release>
}
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	64a2                	ld	s1,8(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret

00000000800030dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030dc:	1101                	addi	sp,sp,-32
    800030de:	ec06                	sd	ra,24(sp)
    800030e0:	e822                	sd	s0,16(sp)
    800030e2:	e426                	sd	s1,8(sp)
    800030e4:	e04a                	sd	s2,0(sp)
    800030e6:	1000                	addi	s0,sp,32
    800030e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030ea:	00d5d59b          	srliw	a1,a1,0xd
    800030ee:	0001d797          	auipc	a5,0x1d
    800030f2:	ce67a783          	lw	a5,-794(a5) # 8001fdd4 <sb+0x1c>
    800030f6:	9dbd                	addw	a1,a1,a5
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	d9e080e7          	jalr	-610(ra) # 80002e96 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003100:	0074f713          	andi	a4,s1,7
    80003104:	4785                	li	a5,1
    80003106:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000310a:	14ce                	slli	s1,s1,0x33
    8000310c:	90d9                	srli	s1,s1,0x36
    8000310e:	00950733          	add	a4,a0,s1
    80003112:	05874703          	lbu	a4,88(a4)
    80003116:	00e7f6b3          	and	a3,a5,a4
    8000311a:	c69d                	beqz	a3,80003148 <bfree+0x6c>
    8000311c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000311e:	94aa                	add	s1,s1,a0
    80003120:	fff7c793          	not	a5,a5
    80003124:	8ff9                	and	a5,a5,a4
    80003126:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000312a:	00001097          	auipc	ra,0x1
    8000312e:	118080e7          	jalr	280(ra) # 80004242 <log_write>
  brelse(bp);
    80003132:	854a                	mv	a0,s2
    80003134:	00000097          	auipc	ra,0x0
    80003138:	e92080e7          	jalr	-366(ra) # 80002fc6 <brelse>
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6902                	ld	s2,0(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret
    panic("freeing free block");
    80003148:	00005517          	auipc	a0,0x5
    8000314c:	3d850513          	addi	a0,a0,984 # 80008520 <syscalls+0xf0>
    80003150:	ffffd097          	auipc	ra,0xffffd
    80003154:	3da080e7          	jalr	986(ra) # 8000052a <panic>

0000000080003158 <balloc>:
{
    80003158:	711d                	addi	sp,sp,-96
    8000315a:	ec86                	sd	ra,88(sp)
    8000315c:	e8a2                	sd	s0,80(sp)
    8000315e:	e4a6                	sd	s1,72(sp)
    80003160:	e0ca                	sd	s2,64(sp)
    80003162:	fc4e                	sd	s3,56(sp)
    80003164:	f852                	sd	s4,48(sp)
    80003166:	f456                	sd	s5,40(sp)
    80003168:	f05a                	sd	s6,32(sp)
    8000316a:	ec5e                	sd	s7,24(sp)
    8000316c:	e862                	sd	s8,16(sp)
    8000316e:	e466                	sd	s9,8(sp)
    80003170:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003172:	0001d797          	auipc	a5,0x1d
    80003176:	c4a7a783          	lw	a5,-950(a5) # 8001fdbc <sb+0x4>
    8000317a:	cbd1                	beqz	a5,8000320e <balloc+0xb6>
    8000317c:	8baa                	mv	s7,a0
    8000317e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003180:	0001db17          	auipc	s6,0x1d
    80003184:	c38b0b13          	addi	s6,s6,-968 # 8001fdb8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003188:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000318a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000318e:	6c89                	lui	s9,0x2
    80003190:	a831                	j	800031ac <balloc+0x54>
    brelse(bp);
    80003192:	854a                	mv	a0,s2
    80003194:	00000097          	auipc	ra,0x0
    80003198:	e32080e7          	jalr	-462(ra) # 80002fc6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000319c:	015c87bb          	addw	a5,s9,s5
    800031a0:	00078a9b          	sext.w	s5,a5
    800031a4:	004b2703          	lw	a4,4(s6)
    800031a8:	06eaf363          	bgeu	s5,a4,8000320e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031ac:	41fad79b          	sraiw	a5,s5,0x1f
    800031b0:	0137d79b          	srliw	a5,a5,0x13
    800031b4:	015787bb          	addw	a5,a5,s5
    800031b8:	40d7d79b          	sraiw	a5,a5,0xd
    800031bc:	01cb2583          	lw	a1,28(s6)
    800031c0:	9dbd                	addw	a1,a1,a5
    800031c2:	855e                	mv	a0,s7
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	cd2080e7          	jalr	-814(ra) # 80002e96 <bread>
    800031cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ce:	004b2503          	lw	a0,4(s6)
    800031d2:	000a849b          	sext.w	s1,s5
    800031d6:	8662                	mv	a2,s8
    800031d8:	faa4fde3          	bgeu	s1,a0,80003192 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031dc:	41f6579b          	sraiw	a5,a2,0x1f
    800031e0:	01d7d69b          	srliw	a3,a5,0x1d
    800031e4:	00c6873b          	addw	a4,a3,a2
    800031e8:	00777793          	andi	a5,a4,7
    800031ec:	9f95                	subw	a5,a5,a3
    800031ee:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031f2:	4037571b          	sraiw	a4,a4,0x3
    800031f6:	00e906b3          	add	a3,s2,a4
    800031fa:	0586c683          	lbu	a3,88(a3)
    800031fe:	00d7f5b3          	and	a1,a5,a3
    80003202:	cd91                	beqz	a1,8000321e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003204:	2605                	addiw	a2,a2,1
    80003206:	2485                	addiw	s1,s1,1
    80003208:	fd4618e3          	bne	a2,s4,800031d8 <balloc+0x80>
    8000320c:	b759                	j	80003192 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000320e:	00005517          	auipc	a0,0x5
    80003212:	32a50513          	addi	a0,a0,810 # 80008538 <syscalls+0x108>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	314080e7          	jalr	788(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000321e:	974a                	add	a4,a4,s2
    80003220:	8fd5                	or	a5,a5,a3
    80003222:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003226:	854a                	mv	a0,s2
    80003228:	00001097          	auipc	ra,0x1
    8000322c:	01a080e7          	jalr	26(ra) # 80004242 <log_write>
        brelse(bp);
    80003230:	854a                	mv	a0,s2
    80003232:	00000097          	auipc	ra,0x0
    80003236:	d94080e7          	jalr	-620(ra) # 80002fc6 <brelse>
  bp = bread(dev, bno);
    8000323a:	85a6                	mv	a1,s1
    8000323c:	855e                	mv	a0,s7
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	c58080e7          	jalr	-936(ra) # 80002e96 <bread>
    80003246:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003248:	40000613          	li	a2,1024
    8000324c:	4581                	li	a1,0
    8000324e:	05850513          	addi	a0,a0,88
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	a6c080e7          	jalr	-1428(ra) # 80000cbe <memset>
  log_write(bp);
    8000325a:	854a                	mv	a0,s2
    8000325c:	00001097          	auipc	ra,0x1
    80003260:	fe6080e7          	jalr	-26(ra) # 80004242 <log_write>
  brelse(bp);
    80003264:	854a                	mv	a0,s2
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	d60080e7          	jalr	-672(ra) # 80002fc6 <brelse>
}
    8000326e:	8526                	mv	a0,s1
    80003270:	60e6                	ld	ra,88(sp)
    80003272:	6446                	ld	s0,80(sp)
    80003274:	64a6                	ld	s1,72(sp)
    80003276:	6906                	ld	s2,64(sp)
    80003278:	79e2                	ld	s3,56(sp)
    8000327a:	7a42                	ld	s4,48(sp)
    8000327c:	7aa2                	ld	s5,40(sp)
    8000327e:	7b02                	ld	s6,32(sp)
    80003280:	6be2                	ld	s7,24(sp)
    80003282:	6c42                	ld	s8,16(sp)
    80003284:	6ca2                	ld	s9,8(sp)
    80003286:	6125                	addi	sp,sp,96
    80003288:	8082                	ret

000000008000328a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	e84a                	sd	s2,16(sp)
    80003294:	e44e                	sd	s3,8(sp)
    80003296:	e052                	sd	s4,0(sp)
    80003298:	1800                	addi	s0,sp,48
    8000329a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000329c:	47ad                	li	a5,11
    8000329e:	04b7fe63          	bgeu	a5,a1,800032fa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032a2:	ff45849b          	addiw	s1,a1,-12
    800032a6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032aa:	0ff00793          	li	a5,255
    800032ae:	0ae7e363          	bltu	a5,a4,80003354 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032b2:	08052583          	lw	a1,128(a0)
    800032b6:	c5ad                	beqz	a1,80003320 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032b8:	00092503          	lw	a0,0(s2)
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	bda080e7          	jalr	-1062(ra) # 80002e96 <bread>
    800032c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ca:	02049593          	slli	a1,s1,0x20
    800032ce:	9181                	srli	a1,a1,0x20
    800032d0:	058a                	slli	a1,a1,0x2
    800032d2:	00b784b3          	add	s1,a5,a1
    800032d6:	0004a983          	lw	s3,0(s1)
    800032da:	04098d63          	beqz	s3,80003334 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032de:	8552                	mv	a0,s4
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	ce6080e7          	jalr	-794(ra) # 80002fc6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032e8:	854e                	mv	a0,s3
    800032ea:	70a2                	ld	ra,40(sp)
    800032ec:	7402                	ld	s0,32(sp)
    800032ee:	64e2                	ld	s1,24(sp)
    800032f0:	6942                	ld	s2,16(sp)
    800032f2:	69a2                	ld	s3,8(sp)
    800032f4:	6a02                	ld	s4,0(sp)
    800032f6:	6145                	addi	sp,sp,48
    800032f8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032fa:	02059493          	slli	s1,a1,0x20
    800032fe:	9081                	srli	s1,s1,0x20
    80003300:	048a                	slli	s1,s1,0x2
    80003302:	94aa                	add	s1,s1,a0
    80003304:	0504a983          	lw	s3,80(s1)
    80003308:	fe0990e3          	bnez	s3,800032e8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000330c:	4108                	lw	a0,0(a0)
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	e4a080e7          	jalr	-438(ra) # 80003158 <balloc>
    80003316:	0005099b          	sext.w	s3,a0
    8000331a:	0534a823          	sw	s3,80(s1)
    8000331e:	b7e9                	j	800032e8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003320:	4108                	lw	a0,0(a0)
    80003322:	00000097          	auipc	ra,0x0
    80003326:	e36080e7          	jalr	-458(ra) # 80003158 <balloc>
    8000332a:	0005059b          	sext.w	a1,a0
    8000332e:	08b92023          	sw	a1,128(s2)
    80003332:	b759                	j	800032b8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003334:	00092503          	lw	a0,0(s2)
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	e20080e7          	jalr	-480(ra) # 80003158 <balloc>
    80003340:	0005099b          	sext.w	s3,a0
    80003344:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003348:	8552                	mv	a0,s4
    8000334a:	00001097          	auipc	ra,0x1
    8000334e:	ef8080e7          	jalr	-264(ra) # 80004242 <log_write>
    80003352:	b771                	j	800032de <bmap+0x54>
  panic("bmap: out of range");
    80003354:	00005517          	auipc	a0,0x5
    80003358:	1fc50513          	addi	a0,a0,508 # 80008550 <syscalls+0x120>
    8000335c:	ffffd097          	auipc	ra,0xffffd
    80003360:	1ce080e7          	jalr	462(ra) # 8000052a <panic>

0000000080003364 <iget>:
{
    80003364:	7179                	addi	sp,sp,-48
    80003366:	f406                	sd	ra,40(sp)
    80003368:	f022                	sd	s0,32(sp)
    8000336a:	ec26                	sd	s1,24(sp)
    8000336c:	e84a                	sd	s2,16(sp)
    8000336e:	e44e                	sd	s3,8(sp)
    80003370:	e052                	sd	s4,0(sp)
    80003372:	1800                	addi	s0,sp,48
    80003374:	89aa                	mv	s3,a0
    80003376:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003378:	0001d517          	auipc	a0,0x1d
    8000337c:	a6050513          	addi	a0,a0,-1440 # 8001fdd8 <itable>
    80003380:	ffffe097          	auipc	ra,0xffffe
    80003384:	842080e7          	jalr	-1982(ra) # 80000bc2 <acquire>
  empty = 0;
    80003388:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000338a:	0001d497          	auipc	s1,0x1d
    8000338e:	a6648493          	addi	s1,s1,-1434 # 8001fdf0 <itable+0x18>
    80003392:	0001e697          	auipc	a3,0x1e
    80003396:	4ee68693          	addi	a3,a3,1262 # 80021880 <log>
    8000339a:	a039                	j	800033a8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000339c:	02090b63          	beqz	s2,800033d2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033a0:	08848493          	addi	s1,s1,136
    800033a4:	02d48a63          	beq	s1,a3,800033d8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033a8:	449c                	lw	a5,8(s1)
    800033aa:	fef059e3          	blez	a5,8000339c <iget+0x38>
    800033ae:	4098                	lw	a4,0(s1)
    800033b0:	ff3716e3          	bne	a4,s3,8000339c <iget+0x38>
    800033b4:	40d8                	lw	a4,4(s1)
    800033b6:	ff4713e3          	bne	a4,s4,8000339c <iget+0x38>
      ip->ref++;
    800033ba:	2785                	addiw	a5,a5,1
    800033bc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033be:	0001d517          	auipc	a0,0x1d
    800033c2:	a1a50513          	addi	a0,a0,-1510 # 8001fdd8 <itable>
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	8b0080e7          	jalr	-1872(ra) # 80000c76 <release>
      return ip;
    800033ce:	8926                	mv	s2,s1
    800033d0:	a03d                	j	800033fe <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033d2:	f7f9                	bnez	a5,800033a0 <iget+0x3c>
    800033d4:	8926                	mv	s2,s1
    800033d6:	b7e9                	j	800033a0 <iget+0x3c>
  if(empty == 0)
    800033d8:	02090c63          	beqz	s2,80003410 <iget+0xac>
  ip->dev = dev;
    800033dc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033e0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033e4:	4785                	li	a5,1
    800033e6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033ea:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033ee:	0001d517          	auipc	a0,0x1d
    800033f2:	9ea50513          	addi	a0,a0,-1558 # 8001fdd8 <itable>
    800033f6:	ffffe097          	auipc	ra,0xffffe
    800033fa:	880080e7          	jalr	-1920(ra) # 80000c76 <release>
}
    800033fe:	854a                	mv	a0,s2
    80003400:	70a2                	ld	ra,40(sp)
    80003402:	7402                	ld	s0,32(sp)
    80003404:	64e2                	ld	s1,24(sp)
    80003406:	6942                	ld	s2,16(sp)
    80003408:	69a2                	ld	s3,8(sp)
    8000340a:	6a02                	ld	s4,0(sp)
    8000340c:	6145                	addi	sp,sp,48
    8000340e:	8082                	ret
    panic("iget: no inodes");
    80003410:	00005517          	auipc	a0,0x5
    80003414:	15850513          	addi	a0,a0,344 # 80008568 <syscalls+0x138>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	112080e7          	jalr	274(ra) # 8000052a <panic>

0000000080003420 <fsinit>:
fsinit(int dev) {
    80003420:	7179                	addi	sp,sp,-48
    80003422:	f406                	sd	ra,40(sp)
    80003424:	f022                	sd	s0,32(sp)
    80003426:	ec26                	sd	s1,24(sp)
    80003428:	e84a                	sd	s2,16(sp)
    8000342a:	e44e                	sd	s3,8(sp)
    8000342c:	1800                	addi	s0,sp,48
    8000342e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003430:	4585                	li	a1,1
    80003432:	00000097          	auipc	ra,0x0
    80003436:	a64080e7          	jalr	-1436(ra) # 80002e96 <bread>
    8000343a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000343c:	0001d997          	auipc	s3,0x1d
    80003440:	97c98993          	addi	s3,s3,-1668 # 8001fdb8 <sb>
    80003444:	02000613          	li	a2,32
    80003448:	05850593          	addi	a1,a0,88
    8000344c:	854e                	mv	a0,s3
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	8cc080e7          	jalr	-1844(ra) # 80000d1a <memmove>
  brelse(bp);
    80003456:	8526                	mv	a0,s1
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	b6e080e7          	jalr	-1170(ra) # 80002fc6 <brelse>
  if(sb.magic != FSMAGIC)
    80003460:	0009a703          	lw	a4,0(s3)
    80003464:	102037b7          	lui	a5,0x10203
    80003468:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000346c:	02f71263          	bne	a4,a5,80003490 <fsinit+0x70>
  initlog(dev, &sb);
    80003470:	0001d597          	auipc	a1,0x1d
    80003474:	94858593          	addi	a1,a1,-1720 # 8001fdb8 <sb>
    80003478:	854a                	mv	a0,s2
    8000347a:	00001097          	auipc	ra,0x1
    8000347e:	b4c080e7          	jalr	-1204(ra) # 80003fc6 <initlog>
}
    80003482:	70a2                	ld	ra,40(sp)
    80003484:	7402                	ld	s0,32(sp)
    80003486:	64e2                	ld	s1,24(sp)
    80003488:	6942                	ld	s2,16(sp)
    8000348a:	69a2                	ld	s3,8(sp)
    8000348c:	6145                	addi	sp,sp,48
    8000348e:	8082                	ret
    panic("invalid file system");
    80003490:	00005517          	auipc	a0,0x5
    80003494:	0e850513          	addi	a0,a0,232 # 80008578 <syscalls+0x148>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	092080e7          	jalr	146(ra) # 8000052a <panic>

00000000800034a0 <iinit>:
{
    800034a0:	7179                	addi	sp,sp,-48
    800034a2:	f406                	sd	ra,40(sp)
    800034a4:	f022                	sd	s0,32(sp)
    800034a6:	ec26                	sd	s1,24(sp)
    800034a8:	e84a                	sd	s2,16(sp)
    800034aa:	e44e                	sd	s3,8(sp)
    800034ac:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034ae:	00005597          	auipc	a1,0x5
    800034b2:	0e258593          	addi	a1,a1,226 # 80008590 <syscalls+0x160>
    800034b6:	0001d517          	auipc	a0,0x1d
    800034ba:	92250513          	addi	a0,a0,-1758 # 8001fdd8 <itable>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	674080e7          	jalr	1652(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034c6:	0001d497          	auipc	s1,0x1d
    800034ca:	93a48493          	addi	s1,s1,-1734 # 8001fe00 <itable+0x28>
    800034ce:	0001e997          	auipc	s3,0x1e
    800034d2:	3c298993          	addi	s3,s3,962 # 80021890 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034d6:	00005917          	auipc	s2,0x5
    800034da:	0c290913          	addi	s2,s2,194 # 80008598 <syscalls+0x168>
    800034de:	85ca                	mv	a1,s2
    800034e0:	8526                	mv	a0,s1
    800034e2:	00001097          	auipc	ra,0x1
    800034e6:	e46080e7          	jalr	-442(ra) # 80004328 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034ea:	08848493          	addi	s1,s1,136
    800034ee:	ff3498e3          	bne	s1,s3,800034de <iinit+0x3e>
}
    800034f2:	70a2                	ld	ra,40(sp)
    800034f4:	7402                	ld	s0,32(sp)
    800034f6:	64e2                	ld	s1,24(sp)
    800034f8:	6942                	ld	s2,16(sp)
    800034fa:	69a2                	ld	s3,8(sp)
    800034fc:	6145                	addi	sp,sp,48
    800034fe:	8082                	ret

0000000080003500 <ialloc>:
{
    80003500:	715d                	addi	sp,sp,-80
    80003502:	e486                	sd	ra,72(sp)
    80003504:	e0a2                	sd	s0,64(sp)
    80003506:	fc26                	sd	s1,56(sp)
    80003508:	f84a                	sd	s2,48(sp)
    8000350a:	f44e                	sd	s3,40(sp)
    8000350c:	f052                	sd	s4,32(sp)
    8000350e:	ec56                	sd	s5,24(sp)
    80003510:	e85a                	sd	s6,16(sp)
    80003512:	e45e                	sd	s7,8(sp)
    80003514:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003516:	0001d717          	auipc	a4,0x1d
    8000351a:	8ae72703          	lw	a4,-1874(a4) # 8001fdc4 <sb+0xc>
    8000351e:	4785                	li	a5,1
    80003520:	04e7fa63          	bgeu	a5,a4,80003574 <ialloc+0x74>
    80003524:	8aaa                	mv	s5,a0
    80003526:	8bae                	mv	s7,a1
    80003528:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000352a:	0001da17          	auipc	s4,0x1d
    8000352e:	88ea0a13          	addi	s4,s4,-1906 # 8001fdb8 <sb>
    80003532:	00048b1b          	sext.w	s6,s1
    80003536:	0044d793          	srli	a5,s1,0x4
    8000353a:	018a2583          	lw	a1,24(s4)
    8000353e:	9dbd                	addw	a1,a1,a5
    80003540:	8556                	mv	a0,s5
    80003542:	00000097          	auipc	ra,0x0
    80003546:	954080e7          	jalr	-1708(ra) # 80002e96 <bread>
    8000354a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000354c:	05850993          	addi	s3,a0,88
    80003550:	00f4f793          	andi	a5,s1,15
    80003554:	079a                	slli	a5,a5,0x6
    80003556:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003558:	00099783          	lh	a5,0(s3)
    8000355c:	c785                	beqz	a5,80003584 <ialloc+0x84>
    brelse(bp);
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	a68080e7          	jalr	-1432(ra) # 80002fc6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003566:	0485                	addi	s1,s1,1
    80003568:	00ca2703          	lw	a4,12(s4)
    8000356c:	0004879b          	sext.w	a5,s1
    80003570:	fce7e1e3          	bltu	a5,a4,80003532 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	02c50513          	addi	a0,a0,44 # 800085a0 <syscalls+0x170>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	fae080e7          	jalr	-82(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003584:	04000613          	li	a2,64
    80003588:	4581                	li	a1,0
    8000358a:	854e                	mv	a0,s3
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	732080e7          	jalr	1842(ra) # 80000cbe <memset>
      dip->type = type;
    80003594:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003598:	854a                	mv	a0,s2
    8000359a:	00001097          	auipc	ra,0x1
    8000359e:	ca8080e7          	jalr	-856(ra) # 80004242 <log_write>
      brelse(bp);
    800035a2:	854a                	mv	a0,s2
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	a22080e7          	jalr	-1502(ra) # 80002fc6 <brelse>
      return iget(dev, inum);
    800035ac:	85da                	mv	a1,s6
    800035ae:	8556                	mv	a0,s5
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	db4080e7          	jalr	-588(ra) # 80003364 <iget>
}
    800035b8:	60a6                	ld	ra,72(sp)
    800035ba:	6406                	ld	s0,64(sp)
    800035bc:	74e2                	ld	s1,56(sp)
    800035be:	7942                	ld	s2,48(sp)
    800035c0:	79a2                	ld	s3,40(sp)
    800035c2:	7a02                	ld	s4,32(sp)
    800035c4:	6ae2                	ld	s5,24(sp)
    800035c6:	6b42                	ld	s6,16(sp)
    800035c8:	6ba2                	ld	s7,8(sp)
    800035ca:	6161                	addi	sp,sp,80
    800035cc:	8082                	ret

00000000800035ce <iupdate>:
{
    800035ce:	1101                	addi	sp,sp,-32
    800035d0:	ec06                	sd	ra,24(sp)
    800035d2:	e822                	sd	s0,16(sp)
    800035d4:	e426                	sd	s1,8(sp)
    800035d6:	e04a                	sd	s2,0(sp)
    800035d8:	1000                	addi	s0,sp,32
    800035da:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035dc:	415c                	lw	a5,4(a0)
    800035de:	0047d79b          	srliw	a5,a5,0x4
    800035e2:	0001c597          	auipc	a1,0x1c
    800035e6:	7ee5a583          	lw	a1,2030(a1) # 8001fdd0 <sb+0x18>
    800035ea:	9dbd                	addw	a1,a1,a5
    800035ec:	4108                	lw	a0,0(a0)
    800035ee:	00000097          	auipc	ra,0x0
    800035f2:	8a8080e7          	jalr	-1880(ra) # 80002e96 <bread>
    800035f6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035f8:	05850793          	addi	a5,a0,88
    800035fc:	40c8                	lw	a0,4(s1)
    800035fe:	893d                	andi	a0,a0,15
    80003600:	051a                	slli	a0,a0,0x6
    80003602:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003604:	04449703          	lh	a4,68(s1)
    80003608:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000360c:	04649703          	lh	a4,70(s1)
    80003610:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003614:	04849703          	lh	a4,72(s1)
    80003618:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000361c:	04a49703          	lh	a4,74(s1)
    80003620:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003624:	44f8                	lw	a4,76(s1)
    80003626:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003628:	03400613          	li	a2,52
    8000362c:	05048593          	addi	a1,s1,80
    80003630:	0531                	addi	a0,a0,12
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	6e8080e7          	jalr	1768(ra) # 80000d1a <memmove>
  log_write(bp);
    8000363a:	854a                	mv	a0,s2
    8000363c:	00001097          	auipc	ra,0x1
    80003640:	c06080e7          	jalr	-1018(ra) # 80004242 <log_write>
  brelse(bp);
    80003644:	854a                	mv	a0,s2
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	980080e7          	jalr	-1664(ra) # 80002fc6 <brelse>
}
    8000364e:	60e2                	ld	ra,24(sp)
    80003650:	6442                	ld	s0,16(sp)
    80003652:	64a2                	ld	s1,8(sp)
    80003654:	6902                	ld	s2,0(sp)
    80003656:	6105                	addi	sp,sp,32
    80003658:	8082                	ret

000000008000365a <idup>:
{
    8000365a:	1101                	addi	sp,sp,-32
    8000365c:	ec06                	sd	ra,24(sp)
    8000365e:	e822                	sd	s0,16(sp)
    80003660:	e426                	sd	s1,8(sp)
    80003662:	1000                	addi	s0,sp,32
    80003664:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003666:	0001c517          	auipc	a0,0x1c
    8000366a:	77250513          	addi	a0,a0,1906 # 8001fdd8 <itable>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	554080e7          	jalr	1364(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003676:	449c                	lw	a5,8(s1)
    80003678:	2785                	addiw	a5,a5,1
    8000367a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000367c:	0001c517          	auipc	a0,0x1c
    80003680:	75c50513          	addi	a0,a0,1884 # 8001fdd8 <itable>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	5f2080e7          	jalr	1522(ra) # 80000c76 <release>
}
    8000368c:	8526                	mv	a0,s1
    8000368e:	60e2                	ld	ra,24(sp)
    80003690:	6442                	ld	s0,16(sp)
    80003692:	64a2                	ld	s1,8(sp)
    80003694:	6105                	addi	sp,sp,32
    80003696:	8082                	ret

0000000080003698 <ilock>:
{
    80003698:	1101                	addi	sp,sp,-32
    8000369a:	ec06                	sd	ra,24(sp)
    8000369c:	e822                	sd	s0,16(sp)
    8000369e:	e426                	sd	s1,8(sp)
    800036a0:	e04a                	sd	s2,0(sp)
    800036a2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036a4:	c115                	beqz	a0,800036c8 <ilock+0x30>
    800036a6:	84aa                	mv	s1,a0
    800036a8:	451c                	lw	a5,8(a0)
    800036aa:	00f05f63          	blez	a5,800036c8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036ae:	0541                	addi	a0,a0,16
    800036b0:	00001097          	auipc	ra,0x1
    800036b4:	cb2080e7          	jalr	-846(ra) # 80004362 <acquiresleep>
  if(ip->valid == 0){
    800036b8:	40bc                	lw	a5,64(s1)
    800036ba:	cf99                	beqz	a5,800036d8 <ilock+0x40>
}
    800036bc:	60e2                	ld	ra,24(sp)
    800036be:	6442                	ld	s0,16(sp)
    800036c0:	64a2                	ld	s1,8(sp)
    800036c2:	6902                	ld	s2,0(sp)
    800036c4:	6105                	addi	sp,sp,32
    800036c6:	8082                	ret
    panic("ilock");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	ef050513          	addi	a0,a0,-272 # 800085b8 <syscalls+0x188>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e5a080e7          	jalr	-422(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d8:	40dc                	lw	a5,4(s1)
    800036da:	0047d79b          	srliw	a5,a5,0x4
    800036de:	0001c597          	auipc	a1,0x1c
    800036e2:	6f25a583          	lw	a1,1778(a1) # 8001fdd0 <sb+0x18>
    800036e6:	9dbd                	addw	a1,a1,a5
    800036e8:	4088                	lw	a0,0(s1)
    800036ea:	fffff097          	auipc	ra,0xfffff
    800036ee:	7ac080e7          	jalr	1964(ra) # 80002e96 <bread>
    800036f2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f4:	05850593          	addi	a1,a0,88
    800036f8:	40dc                	lw	a5,4(s1)
    800036fa:	8bbd                	andi	a5,a5,15
    800036fc:	079a                	slli	a5,a5,0x6
    800036fe:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003700:	00059783          	lh	a5,0(a1)
    80003704:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003708:	00259783          	lh	a5,2(a1)
    8000370c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003710:	00459783          	lh	a5,4(a1)
    80003714:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003718:	00659783          	lh	a5,6(a1)
    8000371c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003720:	459c                	lw	a5,8(a1)
    80003722:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003724:	03400613          	li	a2,52
    80003728:	05b1                	addi	a1,a1,12
    8000372a:	05048513          	addi	a0,s1,80
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	5ec080e7          	jalr	1516(ra) # 80000d1a <memmove>
    brelse(bp);
    80003736:	854a                	mv	a0,s2
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	88e080e7          	jalr	-1906(ra) # 80002fc6 <brelse>
    ip->valid = 1;
    80003740:	4785                	li	a5,1
    80003742:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003744:	04449783          	lh	a5,68(s1)
    80003748:	fbb5                	bnez	a5,800036bc <ilock+0x24>
      panic("ilock: no type");
    8000374a:	00005517          	auipc	a0,0x5
    8000374e:	e7650513          	addi	a0,a0,-394 # 800085c0 <syscalls+0x190>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	dd8080e7          	jalr	-552(ra) # 8000052a <panic>

000000008000375a <iunlock>:
{
    8000375a:	1101                	addi	sp,sp,-32
    8000375c:	ec06                	sd	ra,24(sp)
    8000375e:	e822                	sd	s0,16(sp)
    80003760:	e426                	sd	s1,8(sp)
    80003762:	e04a                	sd	s2,0(sp)
    80003764:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003766:	c905                	beqz	a0,80003796 <iunlock+0x3c>
    80003768:	84aa                	mv	s1,a0
    8000376a:	01050913          	addi	s2,a0,16
    8000376e:	854a                	mv	a0,s2
    80003770:	00001097          	auipc	ra,0x1
    80003774:	c8c080e7          	jalr	-884(ra) # 800043fc <holdingsleep>
    80003778:	cd19                	beqz	a0,80003796 <iunlock+0x3c>
    8000377a:	449c                	lw	a5,8(s1)
    8000377c:	00f05d63          	blez	a5,80003796 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003780:	854a                	mv	a0,s2
    80003782:	00001097          	auipc	ra,0x1
    80003786:	c36080e7          	jalr	-970(ra) # 800043b8 <releasesleep>
}
    8000378a:	60e2                	ld	ra,24(sp)
    8000378c:	6442                	ld	s0,16(sp)
    8000378e:	64a2                	ld	s1,8(sp)
    80003790:	6902                	ld	s2,0(sp)
    80003792:	6105                	addi	sp,sp,32
    80003794:	8082                	ret
    panic("iunlock");
    80003796:	00005517          	auipc	a0,0x5
    8000379a:	e3a50513          	addi	a0,a0,-454 # 800085d0 <syscalls+0x1a0>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	d8c080e7          	jalr	-628(ra) # 8000052a <panic>

00000000800037a6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037a6:	7179                	addi	sp,sp,-48
    800037a8:	f406                	sd	ra,40(sp)
    800037aa:	f022                	sd	s0,32(sp)
    800037ac:	ec26                	sd	s1,24(sp)
    800037ae:	e84a                	sd	s2,16(sp)
    800037b0:	e44e                	sd	s3,8(sp)
    800037b2:	e052                	sd	s4,0(sp)
    800037b4:	1800                	addi	s0,sp,48
    800037b6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037b8:	05050493          	addi	s1,a0,80
    800037bc:	08050913          	addi	s2,a0,128
    800037c0:	a021                	j	800037c8 <itrunc+0x22>
    800037c2:	0491                	addi	s1,s1,4
    800037c4:	01248d63          	beq	s1,s2,800037de <itrunc+0x38>
    if(ip->addrs[i]){
    800037c8:	408c                	lw	a1,0(s1)
    800037ca:	dde5                	beqz	a1,800037c2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037cc:	0009a503          	lw	a0,0(s3)
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	90c080e7          	jalr	-1780(ra) # 800030dc <bfree>
      ip->addrs[i] = 0;
    800037d8:	0004a023          	sw	zero,0(s1)
    800037dc:	b7dd                	j	800037c2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037de:	0809a583          	lw	a1,128(s3)
    800037e2:	e185                	bnez	a1,80003802 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037e4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037e8:	854e                	mv	a0,s3
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	de4080e7          	jalr	-540(ra) # 800035ce <iupdate>
}
    800037f2:	70a2                	ld	ra,40(sp)
    800037f4:	7402                	ld	s0,32(sp)
    800037f6:	64e2                	ld	s1,24(sp)
    800037f8:	6942                	ld	s2,16(sp)
    800037fa:	69a2                	ld	s3,8(sp)
    800037fc:	6a02                	ld	s4,0(sp)
    800037fe:	6145                	addi	sp,sp,48
    80003800:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003802:	0009a503          	lw	a0,0(s3)
    80003806:	fffff097          	auipc	ra,0xfffff
    8000380a:	690080e7          	jalr	1680(ra) # 80002e96 <bread>
    8000380e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003810:	05850493          	addi	s1,a0,88
    80003814:	45850913          	addi	s2,a0,1112
    80003818:	a021                	j	80003820 <itrunc+0x7a>
    8000381a:	0491                	addi	s1,s1,4
    8000381c:	01248b63          	beq	s1,s2,80003832 <itrunc+0x8c>
      if(a[j])
    80003820:	408c                	lw	a1,0(s1)
    80003822:	dde5                	beqz	a1,8000381a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003824:	0009a503          	lw	a0,0(s3)
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	8b4080e7          	jalr	-1868(ra) # 800030dc <bfree>
    80003830:	b7ed                	j	8000381a <itrunc+0x74>
    brelse(bp);
    80003832:	8552                	mv	a0,s4
    80003834:	fffff097          	auipc	ra,0xfffff
    80003838:	792080e7          	jalr	1938(ra) # 80002fc6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000383c:	0809a583          	lw	a1,128(s3)
    80003840:	0009a503          	lw	a0,0(s3)
    80003844:	00000097          	auipc	ra,0x0
    80003848:	898080e7          	jalr	-1896(ra) # 800030dc <bfree>
    ip->addrs[NDIRECT] = 0;
    8000384c:	0809a023          	sw	zero,128(s3)
    80003850:	bf51                	j	800037e4 <itrunc+0x3e>

0000000080003852 <iput>:
{
    80003852:	1101                	addi	sp,sp,-32
    80003854:	ec06                	sd	ra,24(sp)
    80003856:	e822                	sd	s0,16(sp)
    80003858:	e426                	sd	s1,8(sp)
    8000385a:	e04a                	sd	s2,0(sp)
    8000385c:	1000                	addi	s0,sp,32
    8000385e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003860:	0001c517          	auipc	a0,0x1c
    80003864:	57850513          	addi	a0,a0,1400 # 8001fdd8 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	35a080e7          	jalr	858(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003870:	4498                	lw	a4,8(s1)
    80003872:	4785                	li	a5,1
    80003874:	02f70363          	beq	a4,a5,8000389a <iput+0x48>
  ip->ref--;
    80003878:	449c                	lw	a5,8(s1)
    8000387a:	37fd                	addiw	a5,a5,-1
    8000387c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000387e:	0001c517          	auipc	a0,0x1c
    80003882:	55a50513          	addi	a0,a0,1370 # 8001fdd8 <itable>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	3f0080e7          	jalr	1008(ra) # 80000c76 <release>
}
    8000388e:	60e2                	ld	ra,24(sp)
    80003890:	6442                	ld	s0,16(sp)
    80003892:	64a2                	ld	s1,8(sp)
    80003894:	6902                	ld	s2,0(sp)
    80003896:	6105                	addi	sp,sp,32
    80003898:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000389a:	40bc                	lw	a5,64(s1)
    8000389c:	dff1                	beqz	a5,80003878 <iput+0x26>
    8000389e:	04a49783          	lh	a5,74(s1)
    800038a2:	fbf9                	bnez	a5,80003878 <iput+0x26>
    acquiresleep(&ip->lock);
    800038a4:	01048913          	addi	s2,s1,16
    800038a8:	854a                	mv	a0,s2
    800038aa:	00001097          	auipc	ra,0x1
    800038ae:	ab8080e7          	jalr	-1352(ra) # 80004362 <acquiresleep>
    release(&itable.lock);
    800038b2:	0001c517          	auipc	a0,0x1c
    800038b6:	52650513          	addi	a0,a0,1318 # 8001fdd8 <itable>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	3bc080e7          	jalr	956(ra) # 80000c76 <release>
    itrunc(ip);
    800038c2:	8526                	mv	a0,s1
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	ee2080e7          	jalr	-286(ra) # 800037a6 <itrunc>
    ip->type = 0;
    800038cc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038d0:	8526                	mv	a0,s1
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	cfc080e7          	jalr	-772(ra) # 800035ce <iupdate>
    ip->valid = 0;
    800038da:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038de:	854a                	mv	a0,s2
    800038e0:	00001097          	auipc	ra,0x1
    800038e4:	ad8080e7          	jalr	-1320(ra) # 800043b8 <releasesleep>
    acquire(&itable.lock);
    800038e8:	0001c517          	auipc	a0,0x1c
    800038ec:	4f050513          	addi	a0,a0,1264 # 8001fdd8 <itable>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	2d2080e7          	jalr	722(ra) # 80000bc2 <acquire>
    800038f8:	b741                	j	80003878 <iput+0x26>

00000000800038fa <iunlockput>:
{
    800038fa:	1101                	addi	sp,sp,-32
    800038fc:	ec06                	sd	ra,24(sp)
    800038fe:	e822                	sd	s0,16(sp)
    80003900:	e426                	sd	s1,8(sp)
    80003902:	1000                	addi	s0,sp,32
    80003904:	84aa                	mv	s1,a0
  iunlock(ip);
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	e54080e7          	jalr	-428(ra) # 8000375a <iunlock>
  iput(ip);
    8000390e:	8526                	mv	a0,s1
    80003910:	00000097          	auipc	ra,0x0
    80003914:	f42080e7          	jalr	-190(ra) # 80003852 <iput>
}
    80003918:	60e2                	ld	ra,24(sp)
    8000391a:	6442                	ld	s0,16(sp)
    8000391c:	64a2                	ld	s1,8(sp)
    8000391e:	6105                	addi	sp,sp,32
    80003920:	8082                	ret

0000000080003922 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003922:	1141                	addi	sp,sp,-16
    80003924:	e422                	sd	s0,8(sp)
    80003926:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003928:	411c                	lw	a5,0(a0)
    8000392a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000392c:	415c                	lw	a5,4(a0)
    8000392e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003930:	04451783          	lh	a5,68(a0)
    80003934:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003938:	04a51783          	lh	a5,74(a0)
    8000393c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003940:	04c56783          	lwu	a5,76(a0)
    80003944:	e99c                	sd	a5,16(a1)
}
    80003946:	6422                	ld	s0,8(sp)
    80003948:	0141                	addi	sp,sp,16
    8000394a:	8082                	ret

000000008000394c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000394c:	457c                	lw	a5,76(a0)
    8000394e:	0ed7e963          	bltu	a5,a3,80003a40 <readi+0xf4>
{
    80003952:	7159                	addi	sp,sp,-112
    80003954:	f486                	sd	ra,104(sp)
    80003956:	f0a2                	sd	s0,96(sp)
    80003958:	eca6                	sd	s1,88(sp)
    8000395a:	e8ca                	sd	s2,80(sp)
    8000395c:	e4ce                	sd	s3,72(sp)
    8000395e:	e0d2                	sd	s4,64(sp)
    80003960:	fc56                	sd	s5,56(sp)
    80003962:	f85a                	sd	s6,48(sp)
    80003964:	f45e                	sd	s7,40(sp)
    80003966:	f062                	sd	s8,32(sp)
    80003968:	ec66                	sd	s9,24(sp)
    8000396a:	e86a                	sd	s10,16(sp)
    8000396c:	e46e                	sd	s11,8(sp)
    8000396e:	1880                	addi	s0,sp,112
    80003970:	8baa                	mv	s7,a0
    80003972:	8c2e                	mv	s8,a1
    80003974:	8ab2                	mv	s5,a2
    80003976:	84b6                	mv	s1,a3
    80003978:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000397a:	9f35                	addw	a4,a4,a3
    return 0;
    8000397c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000397e:	0ad76063          	bltu	a4,a3,80003a1e <readi+0xd2>
  if(off + n > ip->size)
    80003982:	00e7f463          	bgeu	a5,a4,8000398a <readi+0x3e>
    n = ip->size - off;
    80003986:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000398a:	0a0b0963          	beqz	s6,80003a3c <readi+0xf0>
    8000398e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003990:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003994:	5cfd                	li	s9,-1
    80003996:	a82d                	j	800039d0 <readi+0x84>
    80003998:	020a1d93          	slli	s11,s4,0x20
    8000399c:	020ddd93          	srli	s11,s11,0x20
    800039a0:	05890793          	addi	a5,s2,88
    800039a4:	86ee                	mv	a3,s11
    800039a6:	963e                	add	a2,a2,a5
    800039a8:	85d6                	mv	a1,s5
    800039aa:	8562                	mv	a0,s8
    800039ac:	fffff097          	auipc	ra,0xfffff
    800039b0:	a72080e7          	jalr	-1422(ra) # 8000241e <either_copyout>
    800039b4:	05950d63          	beq	a0,s9,80003a0e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039b8:	854a                	mv	a0,s2
    800039ba:	fffff097          	auipc	ra,0xfffff
    800039be:	60c080e7          	jalr	1548(ra) # 80002fc6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039c2:	013a09bb          	addw	s3,s4,s3
    800039c6:	009a04bb          	addw	s1,s4,s1
    800039ca:	9aee                	add	s5,s5,s11
    800039cc:	0569f763          	bgeu	s3,s6,80003a1a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039d0:	000ba903          	lw	s2,0(s7)
    800039d4:	00a4d59b          	srliw	a1,s1,0xa
    800039d8:	855e                	mv	a0,s7
    800039da:	00000097          	auipc	ra,0x0
    800039de:	8b0080e7          	jalr	-1872(ra) # 8000328a <bmap>
    800039e2:	0005059b          	sext.w	a1,a0
    800039e6:	854a                	mv	a0,s2
    800039e8:	fffff097          	auipc	ra,0xfffff
    800039ec:	4ae080e7          	jalr	1198(ra) # 80002e96 <bread>
    800039f0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f2:	3ff4f613          	andi	a2,s1,1023
    800039f6:	40cd07bb          	subw	a5,s10,a2
    800039fa:	413b073b          	subw	a4,s6,s3
    800039fe:	8a3e                	mv	s4,a5
    80003a00:	2781                	sext.w	a5,a5
    80003a02:	0007069b          	sext.w	a3,a4
    80003a06:	f8f6f9e3          	bgeu	a3,a5,80003998 <readi+0x4c>
    80003a0a:	8a3a                	mv	s4,a4
    80003a0c:	b771                	j	80003998 <readi+0x4c>
      brelse(bp);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	fffff097          	auipc	ra,0xfffff
    80003a14:	5b6080e7          	jalr	1462(ra) # 80002fc6 <brelse>
      tot = -1;
    80003a18:	59fd                	li	s3,-1
  }
  return tot;
    80003a1a:	0009851b          	sext.w	a0,s3
}
    80003a1e:	70a6                	ld	ra,104(sp)
    80003a20:	7406                	ld	s0,96(sp)
    80003a22:	64e6                	ld	s1,88(sp)
    80003a24:	6946                	ld	s2,80(sp)
    80003a26:	69a6                	ld	s3,72(sp)
    80003a28:	6a06                	ld	s4,64(sp)
    80003a2a:	7ae2                	ld	s5,56(sp)
    80003a2c:	7b42                	ld	s6,48(sp)
    80003a2e:	7ba2                	ld	s7,40(sp)
    80003a30:	7c02                	ld	s8,32(sp)
    80003a32:	6ce2                	ld	s9,24(sp)
    80003a34:	6d42                	ld	s10,16(sp)
    80003a36:	6da2                	ld	s11,8(sp)
    80003a38:	6165                	addi	sp,sp,112
    80003a3a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3c:	89da                	mv	s3,s6
    80003a3e:	bff1                	j	80003a1a <readi+0xce>
    return 0;
    80003a40:	4501                	li	a0,0
}
    80003a42:	8082                	ret

0000000080003a44 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a44:	457c                	lw	a5,76(a0)
    80003a46:	10d7e863          	bltu	a5,a3,80003b56 <writei+0x112>
{
    80003a4a:	7159                	addi	sp,sp,-112
    80003a4c:	f486                	sd	ra,104(sp)
    80003a4e:	f0a2                	sd	s0,96(sp)
    80003a50:	eca6                	sd	s1,88(sp)
    80003a52:	e8ca                	sd	s2,80(sp)
    80003a54:	e4ce                	sd	s3,72(sp)
    80003a56:	e0d2                	sd	s4,64(sp)
    80003a58:	fc56                	sd	s5,56(sp)
    80003a5a:	f85a                	sd	s6,48(sp)
    80003a5c:	f45e                	sd	s7,40(sp)
    80003a5e:	f062                	sd	s8,32(sp)
    80003a60:	ec66                	sd	s9,24(sp)
    80003a62:	e86a                	sd	s10,16(sp)
    80003a64:	e46e                	sd	s11,8(sp)
    80003a66:	1880                	addi	s0,sp,112
    80003a68:	8b2a                	mv	s6,a0
    80003a6a:	8c2e                	mv	s8,a1
    80003a6c:	8ab2                	mv	s5,a2
    80003a6e:	8936                	mv	s2,a3
    80003a70:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a72:	00e687bb          	addw	a5,a3,a4
    80003a76:	0ed7e263          	bltu	a5,a3,80003b5a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a7a:	00043737          	lui	a4,0x43
    80003a7e:	0ef76063          	bltu	a4,a5,80003b5e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a82:	0c0b8863          	beqz	s7,80003b52 <writei+0x10e>
    80003a86:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a88:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a8c:	5cfd                	li	s9,-1
    80003a8e:	a091                	j	80003ad2 <writei+0x8e>
    80003a90:	02099d93          	slli	s11,s3,0x20
    80003a94:	020ddd93          	srli	s11,s11,0x20
    80003a98:	05848793          	addi	a5,s1,88
    80003a9c:	86ee                	mv	a3,s11
    80003a9e:	8656                	mv	a2,s5
    80003aa0:	85e2                	mv	a1,s8
    80003aa2:	953e                	add	a0,a0,a5
    80003aa4:	fffff097          	auipc	ra,0xfffff
    80003aa8:	9d0080e7          	jalr	-1584(ra) # 80002474 <either_copyin>
    80003aac:	07950263          	beq	a0,s9,80003b10 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ab0:	8526                	mv	a0,s1
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	790080e7          	jalr	1936(ra) # 80004242 <log_write>
    brelse(bp);
    80003aba:	8526                	mv	a0,s1
    80003abc:	fffff097          	auipc	ra,0xfffff
    80003ac0:	50a080e7          	jalr	1290(ra) # 80002fc6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ac4:	01498a3b          	addw	s4,s3,s4
    80003ac8:	0129893b          	addw	s2,s3,s2
    80003acc:	9aee                	add	s5,s5,s11
    80003ace:	057a7663          	bgeu	s4,s7,80003b1a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ad2:	000b2483          	lw	s1,0(s6)
    80003ad6:	00a9559b          	srliw	a1,s2,0xa
    80003ada:	855a                	mv	a0,s6
    80003adc:	fffff097          	auipc	ra,0xfffff
    80003ae0:	7ae080e7          	jalr	1966(ra) # 8000328a <bmap>
    80003ae4:	0005059b          	sext.w	a1,a0
    80003ae8:	8526                	mv	a0,s1
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	3ac080e7          	jalr	940(ra) # 80002e96 <bread>
    80003af2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af4:	3ff97513          	andi	a0,s2,1023
    80003af8:	40ad07bb          	subw	a5,s10,a0
    80003afc:	414b873b          	subw	a4,s7,s4
    80003b00:	89be                	mv	s3,a5
    80003b02:	2781                	sext.w	a5,a5
    80003b04:	0007069b          	sext.w	a3,a4
    80003b08:	f8f6f4e3          	bgeu	a3,a5,80003a90 <writei+0x4c>
    80003b0c:	89ba                	mv	s3,a4
    80003b0e:	b749                	j	80003a90 <writei+0x4c>
      brelse(bp);
    80003b10:	8526                	mv	a0,s1
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	4b4080e7          	jalr	1204(ra) # 80002fc6 <brelse>
  }

  if(off > ip->size)
    80003b1a:	04cb2783          	lw	a5,76(s6)
    80003b1e:	0127f463          	bgeu	a5,s2,80003b26 <writei+0xe2>
    ip->size = off;
    80003b22:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b26:	855a                	mv	a0,s6
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	aa6080e7          	jalr	-1370(ra) # 800035ce <iupdate>

  return tot;
    80003b30:	000a051b          	sext.w	a0,s4
}
    80003b34:	70a6                	ld	ra,104(sp)
    80003b36:	7406                	ld	s0,96(sp)
    80003b38:	64e6                	ld	s1,88(sp)
    80003b3a:	6946                	ld	s2,80(sp)
    80003b3c:	69a6                	ld	s3,72(sp)
    80003b3e:	6a06                	ld	s4,64(sp)
    80003b40:	7ae2                	ld	s5,56(sp)
    80003b42:	7b42                	ld	s6,48(sp)
    80003b44:	7ba2                	ld	s7,40(sp)
    80003b46:	7c02                	ld	s8,32(sp)
    80003b48:	6ce2                	ld	s9,24(sp)
    80003b4a:	6d42                	ld	s10,16(sp)
    80003b4c:	6da2                	ld	s11,8(sp)
    80003b4e:	6165                	addi	sp,sp,112
    80003b50:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b52:	8a5e                	mv	s4,s7
    80003b54:	bfc9                	j	80003b26 <writei+0xe2>
    return -1;
    80003b56:	557d                	li	a0,-1
}
    80003b58:	8082                	ret
    return -1;
    80003b5a:	557d                	li	a0,-1
    80003b5c:	bfe1                	j	80003b34 <writei+0xf0>
    return -1;
    80003b5e:	557d                	li	a0,-1
    80003b60:	bfd1                	j	80003b34 <writei+0xf0>

0000000080003b62 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b62:	1141                	addi	sp,sp,-16
    80003b64:	e406                	sd	ra,8(sp)
    80003b66:	e022                	sd	s0,0(sp)
    80003b68:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b6a:	4639                	li	a2,14
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	22a080e7          	jalr	554(ra) # 80000d96 <strncmp>
}
    80003b74:	60a2                	ld	ra,8(sp)
    80003b76:	6402                	ld	s0,0(sp)
    80003b78:	0141                	addi	sp,sp,16
    80003b7a:	8082                	ret

0000000080003b7c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b7c:	7139                	addi	sp,sp,-64
    80003b7e:	fc06                	sd	ra,56(sp)
    80003b80:	f822                	sd	s0,48(sp)
    80003b82:	f426                	sd	s1,40(sp)
    80003b84:	f04a                	sd	s2,32(sp)
    80003b86:	ec4e                	sd	s3,24(sp)
    80003b88:	e852                	sd	s4,16(sp)
    80003b8a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b8c:	04451703          	lh	a4,68(a0)
    80003b90:	4785                	li	a5,1
    80003b92:	00f71a63          	bne	a4,a5,80003ba6 <dirlookup+0x2a>
    80003b96:	892a                	mv	s2,a0
    80003b98:	89ae                	mv	s3,a1
    80003b9a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b9c:	457c                	lw	a5,76(a0)
    80003b9e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ba0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ba2:	e79d                	bnez	a5,80003bd0 <dirlookup+0x54>
    80003ba4:	a8a5                	j	80003c1c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	a3250513          	addi	a0,a0,-1486 # 800085d8 <syscalls+0x1a8>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	97c080e7          	jalr	-1668(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003bb6:	00005517          	auipc	a0,0x5
    80003bba:	a3a50513          	addi	a0,a0,-1478 # 800085f0 <syscalls+0x1c0>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	96c080e7          	jalr	-1684(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc6:	24c1                	addiw	s1,s1,16
    80003bc8:	04c92783          	lw	a5,76(s2)
    80003bcc:	04f4f763          	bgeu	s1,a5,80003c1a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bd0:	4741                	li	a4,16
    80003bd2:	86a6                	mv	a3,s1
    80003bd4:	fc040613          	addi	a2,s0,-64
    80003bd8:	4581                	li	a1,0
    80003bda:	854a                	mv	a0,s2
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	d70080e7          	jalr	-656(ra) # 8000394c <readi>
    80003be4:	47c1                	li	a5,16
    80003be6:	fcf518e3          	bne	a0,a5,80003bb6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bea:	fc045783          	lhu	a5,-64(s0)
    80003bee:	dfe1                	beqz	a5,80003bc6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bf0:	fc240593          	addi	a1,s0,-62
    80003bf4:	854e                	mv	a0,s3
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	f6c080e7          	jalr	-148(ra) # 80003b62 <namecmp>
    80003bfe:	f561                	bnez	a0,80003bc6 <dirlookup+0x4a>
      if(poff)
    80003c00:	000a0463          	beqz	s4,80003c08 <dirlookup+0x8c>
        *poff = off;
    80003c04:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c08:	fc045583          	lhu	a1,-64(s0)
    80003c0c:	00092503          	lw	a0,0(s2)
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	754080e7          	jalr	1876(ra) # 80003364 <iget>
    80003c18:	a011                	j	80003c1c <dirlookup+0xa0>
  return 0;
    80003c1a:	4501                	li	a0,0
}
    80003c1c:	70e2                	ld	ra,56(sp)
    80003c1e:	7442                	ld	s0,48(sp)
    80003c20:	74a2                	ld	s1,40(sp)
    80003c22:	7902                	ld	s2,32(sp)
    80003c24:	69e2                	ld	s3,24(sp)
    80003c26:	6a42                	ld	s4,16(sp)
    80003c28:	6121                	addi	sp,sp,64
    80003c2a:	8082                	ret

0000000080003c2c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c2c:	711d                	addi	sp,sp,-96
    80003c2e:	ec86                	sd	ra,88(sp)
    80003c30:	e8a2                	sd	s0,80(sp)
    80003c32:	e4a6                	sd	s1,72(sp)
    80003c34:	e0ca                	sd	s2,64(sp)
    80003c36:	fc4e                	sd	s3,56(sp)
    80003c38:	f852                	sd	s4,48(sp)
    80003c3a:	f456                	sd	s5,40(sp)
    80003c3c:	f05a                	sd	s6,32(sp)
    80003c3e:	ec5e                	sd	s7,24(sp)
    80003c40:	e862                	sd	s8,16(sp)
    80003c42:	e466                	sd	s9,8(sp)
    80003c44:	1080                	addi	s0,sp,96
    80003c46:	84aa                	mv	s1,a0
    80003c48:	8aae                	mv	s5,a1
    80003c4a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c4c:	00054703          	lbu	a4,0(a0)
    80003c50:	02f00793          	li	a5,47
    80003c54:	02f70363          	beq	a4,a5,80003c7a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c58:	ffffe097          	auipc	ra,0xffffe
    80003c5c:	d26080e7          	jalr	-730(ra) # 8000197e <myproc>
    80003c60:	15053503          	ld	a0,336(a0)
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	9f6080e7          	jalr	-1546(ra) # 8000365a <idup>
    80003c6c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c6e:	02f00913          	li	s2,47
  len = path - s;
    80003c72:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c74:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c76:	4b85                	li	s7,1
    80003c78:	a865                	j	80003d30 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c7a:	4585                	li	a1,1
    80003c7c:	4505                	li	a0,1
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	6e6080e7          	jalr	1766(ra) # 80003364 <iget>
    80003c86:	89aa                	mv	s3,a0
    80003c88:	b7dd                	j	80003c6e <namex+0x42>
      iunlockput(ip);
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	c6e080e7          	jalr	-914(ra) # 800038fa <iunlockput>
      return 0;
    80003c94:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c96:	854e                	mv	a0,s3
    80003c98:	60e6                	ld	ra,88(sp)
    80003c9a:	6446                	ld	s0,80(sp)
    80003c9c:	64a6                	ld	s1,72(sp)
    80003c9e:	6906                	ld	s2,64(sp)
    80003ca0:	79e2                	ld	s3,56(sp)
    80003ca2:	7a42                	ld	s4,48(sp)
    80003ca4:	7aa2                	ld	s5,40(sp)
    80003ca6:	7b02                	ld	s6,32(sp)
    80003ca8:	6be2                	ld	s7,24(sp)
    80003caa:	6c42                	ld	s8,16(sp)
    80003cac:	6ca2                	ld	s9,8(sp)
    80003cae:	6125                	addi	sp,sp,96
    80003cb0:	8082                	ret
      iunlock(ip);
    80003cb2:	854e                	mv	a0,s3
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	aa6080e7          	jalr	-1370(ra) # 8000375a <iunlock>
      return ip;
    80003cbc:	bfe9                	j	80003c96 <namex+0x6a>
      iunlockput(ip);
    80003cbe:	854e                	mv	a0,s3
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	c3a080e7          	jalr	-966(ra) # 800038fa <iunlockput>
      return 0;
    80003cc8:	89e6                	mv	s3,s9
    80003cca:	b7f1                	j	80003c96 <namex+0x6a>
  len = path - s;
    80003ccc:	40b48633          	sub	a2,s1,a1
    80003cd0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003cd4:	099c5463          	bge	s8,s9,80003d5c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cd8:	4639                	li	a2,14
    80003cda:	8552                	mv	a0,s4
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	03e080e7          	jalr	62(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003ce4:	0004c783          	lbu	a5,0(s1)
    80003ce8:	01279763          	bne	a5,s2,80003cf6 <namex+0xca>
    path++;
    80003cec:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cee:	0004c783          	lbu	a5,0(s1)
    80003cf2:	ff278de3          	beq	a5,s2,80003cec <namex+0xc0>
    ilock(ip);
    80003cf6:	854e                	mv	a0,s3
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	9a0080e7          	jalr	-1632(ra) # 80003698 <ilock>
    if(ip->type != T_DIR){
    80003d00:	04499783          	lh	a5,68(s3)
    80003d04:	f97793e3          	bne	a5,s7,80003c8a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d08:	000a8563          	beqz	s5,80003d12 <namex+0xe6>
    80003d0c:	0004c783          	lbu	a5,0(s1)
    80003d10:	d3cd                	beqz	a5,80003cb2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d12:	865a                	mv	a2,s6
    80003d14:	85d2                	mv	a1,s4
    80003d16:	854e                	mv	a0,s3
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	e64080e7          	jalr	-412(ra) # 80003b7c <dirlookup>
    80003d20:	8caa                	mv	s9,a0
    80003d22:	dd51                	beqz	a0,80003cbe <namex+0x92>
    iunlockput(ip);
    80003d24:	854e                	mv	a0,s3
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	bd4080e7          	jalr	-1068(ra) # 800038fa <iunlockput>
    ip = next;
    80003d2e:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d30:	0004c783          	lbu	a5,0(s1)
    80003d34:	05279763          	bne	a5,s2,80003d82 <namex+0x156>
    path++;
    80003d38:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d3a:	0004c783          	lbu	a5,0(s1)
    80003d3e:	ff278de3          	beq	a5,s2,80003d38 <namex+0x10c>
  if(*path == 0)
    80003d42:	c79d                	beqz	a5,80003d70 <namex+0x144>
    path++;
    80003d44:	85a6                	mv	a1,s1
  len = path - s;
    80003d46:	8cda                	mv	s9,s6
    80003d48:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d4a:	01278963          	beq	a5,s2,80003d5c <namex+0x130>
    80003d4e:	dfbd                	beqz	a5,80003ccc <namex+0xa0>
    path++;
    80003d50:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d52:	0004c783          	lbu	a5,0(s1)
    80003d56:	ff279ce3          	bne	a5,s2,80003d4e <namex+0x122>
    80003d5a:	bf8d                	j	80003ccc <namex+0xa0>
    memmove(name, s, len);
    80003d5c:	2601                	sext.w	a2,a2
    80003d5e:	8552                	mv	a0,s4
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	fba080e7          	jalr	-70(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003d68:	9cd2                	add	s9,s9,s4
    80003d6a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d6e:	bf9d                	j	80003ce4 <namex+0xb8>
  if(nameiparent){
    80003d70:	f20a83e3          	beqz	s5,80003c96 <namex+0x6a>
    iput(ip);
    80003d74:	854e                	mv	a0,s3
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	adc080e7          	jalr	-1316(ra) # 80003852 <iput>
    return 0;
    80003d7e:	4981                	li	s3,0
    80003d80:	bf19                	j	80003c96 <namex+0x6a>
  if(*path == 0)
    80003d82:	d7fd                	beqz	a5,80003d70 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	85a6                	mv	a1,s1
    80003d8a:	b7d1                	j	80003d4e <namex+0x122>

0000000080003d8c <dirlink>:
{
    80003d8c:	7139                	addi	sp,sp,-64
    80003d8e:	fc06                	sd	ra,56(sp)
    80003d90:	f822                	sd	s0,48(sp)
    80003d92:	f426                	sd	s1,40(sp)
    80003d94:	f04a                	sd	s2,32(sp)
    80003d96:	ec4e                	sd	s3,24(sp)
    80003d98:	e852                	sd	s4,16(sp)
    80003d9a:	0080                	addi	s0,sp,64
    80003d9c:	892a                	mv	s2,a0
    80003d9e:	8a2e                	mv	s4,a1
    80003da0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003da2:	4601                	li	a2,0
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	dd8080e7          	jalr	-552(ra) # 80003b7c <dirlookup>
    80003dac:	e93d                	bnez	a0,80003e22 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dae:	04c92483          	lw	s1,76(s2)
    80003db2:	c49d                	beqz	s1,80003de0 <dirlink+0x54>
    80003db4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db6:	4741                	li	a4,16
    80003db8:	86a6                	mv	a3,s1
    80003dba:	fc040613          	addi	a2,s0,-64
    80003dbe:	4581                	li	a1,0
    80003dc0:	854a                	mv	a0,s2
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	b8a080e7          	jalr	-1142(ra) # 8000394c <readi>
    80003dca:	47c1                	li	a5,16
    80003dcc:	06f51163          	bne	a0,a5,80003e2e <dirlink+0xa2>
    if(de.inum == 0)
    80003dd0:	fc045783          	lhu	a5,-64(s0)
    80003dd4:	c791                	beqz	a5,80003de0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd6:	24c1                	addiw	s1,s1,16
    80003dd8:	04c92783          	lw	a5,76(s2)
    80003ddc:	fcf4ede3          	bltu	s1,a5,80003db6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003de0:	4639                	li	a2,14
    80003de2:	85d2                	mv	a1,s4
    80003de4:	fc240513          	addi	a0,s0,-62
    80003de8:	ffffd097          	auipc	ra,0xffffd
    80003dec:	fea080e7          	jalr	-22(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003df0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df4:	4741                	li	a4,16
    80003df6:	86a6                	mv	a3,s1
    80003df8:	fc040613          	addi	a2,s0,-64
    80003dfc:	4581                	li	a1,0
    80003dfe:	854a                	mv	a0,s2
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	c44080e7          	jalr	-956(ra) # 80003a44 <writei>
    80003e08:	872a                	mv	a4,a0
    80003e0a:	47c1                	li	a5,16
  return 0;
    80003e0c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0e:	02f71863          	bne	a4,a5,80003e3e <dirlink+0xb2>
}
    80003e12:	70e2                	ld	ra,56(sp)
    80003e14:	7442                	ld	s0,48(sp)
    80003e16:	74a2                	ld	s1,40(sp)
    80003e18:	7902                	ld	s2,32(sp)
    80003e1a:	69e2                	ld	s3,24(sp)
    80003e1c:	6a42                	ld	s4,16(sp)
    80003e1e:	6121                	addi	sp,sp,64
    80003e20:	8082                	ret
    iput(ip);
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	a30080e7          	jalr	-1488(ra) # 80003852 <iput>
    return -1;
    80003e2a:	557d                	li	a0,-1
    80003e2c:	b7dd                	j	80003e12 <dirlink+0x86>
      panic("dirlink read");
    80003e2e:	00004517          	auipc	a0,0x4
    80003e32:	7d250513          	addi	a0,a0,2002 # 80008600 <syscalls+0x1d0>
    80003e36:	ffffc097          	auipc	ra,0xffffc
    80003e3a:	6f4080e7          	jalr	1780(ra) # 8000052a <panic>
    panic("dirlink");
    80003e3e:	00005517          	auipc	a0,0x5
    80003e42:	8d250513          	addi	a0,a0,-1838 # 80008710 <syscalls+0x2e0>
    80003e46:	ffffc097          	auipc	ra,0xffffc
    80003e4a:	6e4080e7          	jalr	1764(ra) # 8000052a <panic>

0000000080003e4e <namei>:

struct inode*
namei(char *path)
{
    80003e4e:	1101                	addi	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e56:	fe040613          	addi	a2,s0,-32
    80003e5a:	4581                	li	a1,0
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	dd0080e7          	jalr	-560(ra) # 80003c2c <namex>
}
    80003e64:	60e2                	ld	ra,24(sp)
    80003e66:	6442                	ld	s0,16(sp)
    80003e68:	6105                	addi	sp,sp,32
    80003e6a:	8082                	ret

0000000080003e6c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e6c:	1141                	addi	sp,sp,-16
    80003e6e:	e406                	sd	ra,8(sp)
    80003e70:	e022                	sd	s0,0(sp)
    80003e72:	0800                	addi	s0,sp,16
    80003e74:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e76:	4585                	li	a1,1
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	db4080e7          	jalr	-588(ra) # 80003c2c <namex>
}
    80003e80:	60a2                	ld	ra,8(sp)
    80003e82:	6402                	ld	s0,0(sp)
    80003e84:	0141                	addi	sp,sp,16
    80003e86:	8082                	ret

0000000080003e88 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e88:	1101                	addi	sp,sp,-32
    80003e8a:	ec06                	sd	ra,24(sp)
    80003e8c:	e822                	sd	s0,16(sp)
    80003e8e:	e426                	sd	s1,8(sp)
    80003e90:	e04a                	sd	s2,0(sp)
    80003e92:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e94:	0001e917          	auipc	s2,0x1e
    80003e98:	9ec90913          	addi	s2,s2,-1556 # 80021880 <log>
    80003e9c:	01892583          	lw	a1,24(s2)
    80003ea0:	02892503          	lw	a0,40(s2)
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	ff2080e7          	jalr	-14(ra) # 80002e96 <bread>
    80003eac:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eae:	02c92683          	lw	a3,44(s2)
    80003eb2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eb4:	02d05763          	blez	a3,80003ee2 <write_head+0x5a>
    80003eb8:	0001e797          	auipc	a5,0x1e
    80003ebc:	9f878793          	addi	a5,a5,-1544 # 800218b0 <log+0x30>
    80003ec0:	05c50713          	addi	a4,a0,92
    80003ec4:	36fd                	addiw	a3,a3,-1
    80003ec6:	1682                	slli	a3,a3,0x20
    80003ec8:	9281                	srli	a3,a3,0x20
    80003eca:	068a                	slli	a3,a3,0x2
    80003ecc:	0001e617          	auipc	a2,0x1e
    80003ed0:	9e860613          	addi	a2,a2,-1560 # 800218b4 <log+0x34>
    80003ed4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ed6:	4390                	lw	a2,0(a5)
    80003ed8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003eda:	0791                	addi	a5,a5,4
    80003edc:	0711                	addi	a4,a4,4
    80003ede:	fed79ce3          	bne	a5,a3,80003ed6 <write_head+0x4e>
  }
  bwrite(buf);
    80003ee2:	8526                	mv	a0,s1
    80003ee4:	fffff097          	auipc	ra,0xfffff
    80003ee8:	0a4080e7          	jalr	164(ra) # 80002f88 <bwrite>
  brelse(buf);
    80003eec:	8526                	mv	a0,s1
    80003eee:	fffff097          	auipc	ra,0xfffff
    80003ef2:	0d8080e7          	jalr	216(ra) # 80002fc6 <brelse>
}
    80003ef6:	60e2                	ld	ra,24(sp)
    80003ef8:	6442                	ld	s0,16(sp)
    80003efa:	64a2                	ld	s1,8(sp)
    80003efc:	6902                	ld	s2,0(sp)
    80003efe:	6105                	addi	sp,sp,32
    80003f00:	8082                	ret

0000000080003f02 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f02:	0001e797          	auipc	a5,0x1e
    80003f06:	9aa7a783          	lw	a5,-1622(a5) # 800218ac <log+0x2c>
    80003f0a:	0af05d63          	blez	a5,80003fc4 <install_trans+0xc2>
{
    80003f0e:	7139                	addi	sp,sp,-64
    80003f10:	fc06                	sd	ra,56(sp)
    80003f12:	f822                	sd	s0,48(sp)
    80003f14:	f426                	sd	s1,40(sp)
    80003f16:	f04a                	sd	s2,32(sp)
    80003f18:	ec4e                	sd	s3,24(sp)
    80003f1a:	e852                	sd	s4,16(sp)
    80003f1c:	e456                	sd	s5,8(sp)
    80003f1e:	e05a                	sd	s6,0(sp)
    80003f20:	0080                	addi	s0,sp,64
    80003f22:	8b2a                	mv	s6,a0
    80003f24:	0001ea97          	auipc	s5,0x1e
    80003f28:	98ca8a93          	addi	s5,s5,-1652 # 800218b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f2c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f2e:	0001e997          	auipc	s3,0x1e
    80003f32:	95298993          	addi	s3,s3,-1710 # 80021880 <log>
    80003f36:	a00d                	j	80003f58 <install_trans+0x56>
    brelse(lbuf);
    80003f38:	854a                	mv	a0,s2
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	08c080e7          	jalr	140(ra) # 80002fc6 <brelse>
    brelse(dbuf);
    80003f42:	8526                	mv	a0,s1
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	082080e7          	jalr	130(ra) # 80002fc6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f4c:	2a05                	addiw	s4,s4,1
    80003f4e:	0a91                	addi	s5,s5,4
    80003f50:	02c9a783          	lw	a5,44(s3)
    80003f54:	04fa5e63          	bge	s4,a5,80003fb0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f58:	0189a583          	lw	a1,24(s3)
    80003f5c:	014585bb          	addw	a1,a1,s4
    80003f60:	2585                	addiw	a1,a1,1
    80003f62:	0289a503          	lw	a0,40(s3)
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	f30080e7          	jalr	-208(ra) # 80002e96 <bread>
    80003f6e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f70:	000aa583          	lw	a1,0(s5)
    80003f74:	0289a503          	lw	a0,40(s3)
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	f1e080e7          	jalr	-226(ra) # 80002e96 <bread>
    80003f80:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f82:	40000613          	li	a2,1024
    80003f86:	05890593          	addi	a1,s2,88
    80003f8a:	05850513          	addi	a0,a0,88
    80003f8e:	ffffd097          	auipc	ra,0xffffd
    80003f92:	d8c080e7          	jalr	-628(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f96:	8526                	mv	a0,s1
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	ff0080e7          	jalr	-16(ra) # 80002f88 <bwrite>
    if(recovering == 0)
    80003fa0:	f80b1ce3          	bnez	s6,80003f38 <install_trans+0x36>
      bunpin(dbuf);
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	0fa080e7          	jalr	250(ra) # 800030a0 <bunpin>
    80003fae:	b769                	j	80003f38 <install_trans+0x36>
}
    80003fb0:	70e2                	ld	ra,56(sp)
    80003fb2:	7442                	ld	s0,48(sp)
    80003fb4:	74a2                	ld	s1,40(sp)
    80003fb6:	7902                	ld	s2,32(sp)
    80003fb8:	69e2                	ld	s3,24(sp)
    80003fba:	6a42                	ld	s4,16(sp)
    80003fbc:	6aa2                	ld	s5,8(sp)
    80003fbe:	6b02                	ld	s6,0(sp)
    80003fc0:	6121                	addi	sp,sp,64
    80003fc2:	8082                	ret
    80003fc4:	8082                	ret

0000000080003fc6 <initlog>:
{
    80003fc6:	7179                	addi	sp,sp,-48
    80003fc8:	f406                	sd	ra,40(sp)
    80003fca:	f022                	sd	s0,32(sp)
    80003fcc:	ec26                	sd	s1,24(sp)
    80003fce:	e84a                	sd	s2,16(sp)
    80003fd0:	e44e                	sd	s3,8(sp)
    80003fd2:	1800                	addi	s0,sp,48
    80003fd4:	892a                	mv	s2,a0
    80003fd6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fd8:	0001e497          	auipc	s1,0x1e
    80003fdc:	8a848493          	addi	s1,s1,-1880 # 80021880 <log>
    80003fe0:	00004597          	auipc	a1,0x4
    80003fe4:	63058593          	addi	a1,a1,1584 # 80008610 <syscalls+0x1e0>
    80003fe8:	8526                	mv	a0,s1
    80003fea:	ffffd097          	auipc	ra,0xffffd
    80003fee:	b48080e7          	jalr	-1208(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80003ff2:	0149a583          	lw	a1,20(s3)
    80003ff6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003ff8:	0109a783          	lw	a5,16(s3)
    80003ffc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003ffe:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004002:	854a                	mv	a0,s2
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	e92080e7          	jalr	-366(ra) # 80002e96 <bread>
  log.lh.n = lh->n;
    8000400c:	4d34                	lw	a3,88(a0)
    8000400e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004010:	02d05563          	blez	a3,8000403a <initlog+0x74>
    80004014:	05c50793          	addi	a5,a0,92
    80004018:	0001e717          	auipc	a4,0x1e
    8000401c:	89870713          	addi	a4,a4,-1896 # 800218b0 <log+0x30>
    80004020:	36fd                	addiw	a3,a3,-1
    80004022:	1682                	slli	a3,a3,0x20
    80004024:	9281                	srli	a3,a3,0x20
    80004026:	068a                	slli	a3,a3,0x2
    80004028:	06050613          	addi	a2,a0,96
    8000402c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000402e:	4390                	lw	a2,0(a5)
    80004030:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004032:	0791                	addi	a5,a5,4
    80004034:	0711                	addi	a4,a4,4
    80004036:	fed79ce3          	bne	a5,a3,8000402e <initlog+0x68>
  brelse(buf);
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	f8c080e7          	jalr	-116(ra) # 80002fc6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004042:	4505                	li	a0,1
    80004044:	00000097          	auipc	ra,0x0
    80004048:	ebe080e7          	jalr	-322(ra) # 80003f02 <install_trans>
  log.lh.n = 0;
    8000404c:	0001e797          	auipc	a5,0x1e
    80004050:	8607a023          	sw	zero,-1952(a5) # 800218ac <log+0x2c>
  write_head(); // clear the log
    80004054:	00000097          	auipc	ra,0x0
    80004058:	e34080e7          	jalr	-460(ra) # 80003e88 <write_head>
}
    8000405c:	70a2                	ld	ra,40(sp)
    8000405e:	7402                	ld	s0,32(sp)
    80004060:	64e2                	ld	s1,24(sp)
    80004062:	6942                	ld	s2,16(sp)
    80004064:	69a2                	ld	s3,8(sp)
    80004066:	6145                	addi	sp,sp,48
    80004068:	8082                	ret

000000008000406a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000406a:	1101                	addi	sp,sp,-32
    8000406c:	ec06                	sd	ra,24(sp)
    8000406e:	e822                	sd	s0,16(sp)
    80004070:	e426                	sd	s1,8(sp)
    80004072:	e04a                	sd	s2,0(sp)
    80004074:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004076:	0001e517          	auipc	a0,0x1e
    8000407a:	80a50513          	addi	a0,a0,-2038 # 80021880 <log>
    8000407e:	ffffd097          	auipc	ra,0xffffd
    80004082:	b44080e7          	jalr	-1212(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004086:	0001d497          	auipc	s1,0x1d
    8000408a:	7fa48493          	addi	s1,s1,2042 # 80021880 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000408e:	4979                	li	s2,30
    80004090:	a039                	j	8000409e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004092:	85a6                	mv	a1,s1
    80004094:	8526                	mv	a0,s1
    80004096:	ffffe097          	auipc	ra,0xffffe
    8000409a:	fe4080e7          	jalr	-28(ra) # 8000207a <sleep>
    if(log.committing){
    8000409e:	50dc                	lw	a5,36(s1)
    800040a0:	fbed                	bnez	a5,80004092 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040a2:	509c                	lw	a5,32(s1)
    800040a4:	0017871b          	addiw	a4,a5,1
    800040a8:	0007069b          	sext.w	a3,a4
    800040ac:	0027179b          	slliw	a5,a4,0x2
    800040b0:	9fb9                	addw	a5,a5,a4
    800040b2:	0017979b          	slliw	a5,a5,0x1
    800040b6:	54d8                	lw	a4,44(s1)
    800040b8:	9fb9                	addw	a5,a5,a4
    800040ba:	00f95963          	bge	s2,a5,800040cc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040be:	85a6                	mv	a1,s1
    800040c0:	8526                	mv	a0,s1
    800040c2:	ffffe097          	auipc	ra,0xffffe
    800040c6:	fb8080e7          	jalr	-72(ra) # 8000207a <sleep>
    800040ca:	bfd1                	j	8000409e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040cc:	0001d517          	auipc	a0,0x1d
    800040d0:	7b450513          	addi	a0,a0,1972 # 80021880 <log>
    800040d4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040d6:	ffffd097          	auipc	ra,0xffffd
    800040da:	ba0080e7          	jalr	-1120(ra) # 80000c76 <release>
      break;
    }
  }
}
    800040de:	60e2                	ld	ra,24(sp)
    800040e0:	6442                	ld	s0,16(sp)
    800040e2:	64a2                	ld	s1,8(sp)
    800040e4:	6902                	ld	s2,0(sp)
    800040e6:	6105                	addi	sp,sp,32
    800040e8:	8082                	ret

00000000800040ea <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ea:	7139                	addi	sp,sp,-64
    800040ec:	fc06                	sd	ra,56(sp)
    800040ee:	f822                	sd	s0,48(sp)
    800040f0:	f426                	sd	s1,40(sp)
    800040f2:	f04a                	sd	s2,32(sp)
    800040f4:	ec4e                	sd	s3,24(sp)
    800040f6:	e852                	sd	s4,16(sp)
    800040f8:	e456                	sd	s5,8(sp)
    800040fa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040fc:	0001d497          	auipc	s1,0x1d
    80004100:	78448493          	addi	s1,s1,1924 # 80021880 <log>
    80004104:	8526                	mv	a0,s1
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	abc080e7          	jalr	-1348(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000410e:	509c                	lw	a5,32(s1)
    80004110:	37fd                	addiw	a5,a5,-1
    80004112:	0007891b          	sext.w	s2,a5
    80004116:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004118:	50dc                	lw	a5,36(s1)
    8000411a:	e7b9                	bnez	a5,80004168 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000411c:	04091e63          	bnez	s2,80004178 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004120:	0001d497          	auipc	s1,0x1d
    80004124:	76048493          	addi	s1,s1,1888 # 80021880 <log>
    80004128:	4785                	li	a5,1
    8000412a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000412c:	8526                	mv	a0,s1
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	b48080e7          	jalr	-1208(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004136:	54dc                	lw	a5,44(s1)
    80004138:	06f04763          	bgtz	a5,800041a6 <end_op+0xbc>
    acquire(&log.lock);
    8000413c:	0001d497          	auipc	s1,0x1d
    80004140:	74448493          	addi	s1,s1,1860 # 80021880 <log>
    80004144:	8526                	mv	a0,s1
    80004146:	ffffd097          	auipc	ra,0xffffd
    8000414a:	a7c080e7          	jalr	-1412(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000414e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004152:	8526                	mv	a0,s1
    80004154:	ffffe097          	auipc	ra,0xffffe
    80004158:	0b2080e7          	jalr	178(ra) # 80002206 <wakeup>
    release(&log.lock);
    8000415c:	8526                	mv	a0,s1
    8000415e:	ffffd097          	auipc	ra,0xffffd
    80004162:	b18080e7          	jalr	-1256(ra) # 80000c76 <release>
}
    80004166:	a03d                	j	80004194 <end_op+0xaa>
    panic("log.committing");
    80004168:	00004517          	auipc	a0,0x4
    8000416c:	4b050513          	addi	a0,a0,1200 # 80008618 <syscalls+0x1e8>
    80004170:	ffffc097          	auipc	ra,0xffffc
    80004174:	3ba080e7          	jalr	954(ra) # 8000052a <panic>
    wakeup(&log);
    80004178:	0001d497          	auipc	s1,0x1d
    8000417c:	70848493          	addi	s1,s1,1800 # 80021880 <log>
    80004180:	8526                	mv	a0,s1
    80004182:	ffffe097          	auipc	ra,0xffffe
    80004186:	084080e7          	jalr	132(ra) # 80002206 <wakeup>
  release(&log.lock);
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	aea080e7          	jalr	-1302(ra) # 80000c76 <release>
}
    80004194:	70e2                	ld	ra,56(sp)
    80004196:	7442                	ld	s0,48(sp)
    80004198:	74a2                	ld	s1,40(sp)
    8000419a:	7902                	ld	s2,32(sp)
    8000419c:	69e2                	ld	s3,24(sp)
    8000419e:	6a42                	ld	s4,16(sp)
    800041a0:	6aa2                	ld	s5,8(sp)
    800041a2:	6121                	addi	sp,sp,64
    800041a4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a6:	0001da97          	auipc	s5,0x1d
    800041aa:	70aa8a93          	addi	s5,s5,1802 # 800218b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041ae:	0001da17          	auipc	s4,0x1d
    800041b2:	6d2a0a13          	addi	s4,s4,1746 # 80021880 <log>
    800041b6:	018a2583          	lw	a1,24(s4)
    800041ba:	012585bb          	addw	a1,a1,s2
    800041be:	2585                	addiw	a1,a1,1
    800041c0:	028a2503          	lw	a0,40(s4)
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	cd2080e7          	jalr	-814(ra) # 80002e96 <bread>
    800041cc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041ce:	000aa583          	lw	a1,0(s5)
    800041d2:	028a2503          	lw	a0,40(s4)
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	cc0080e7          	jalr	-832(ra) # 80002e96 <bread>
    800041de:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041e0:	40000613          	li	a2,1024
    800041e4:	05850593          	addi	a1,a0,88
    800041e8:	05848513          	addi	a0,s1,88
    800041ec:	ffffd097          	auipc	ra,0xffffd
    800041f0:	b2e080e7          	jalr	-1234(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    800041f4:	8526                	mv	a0,s1
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	d92080e7          	jalr	-622(ra) # 80002f88 <bwrite>
    brelse(from);
    800041fe:	854e                	mv	a0,s3
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	dc6080e7          	jalr	-570(ra) # 80002fc6 <brelse>
    brelse(to);
    80004208:	8526                	mv	a0,s1
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	dbc080e7          	jalr	-580(ra) # 80002fc6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004212:	2905                	addiw	s2,s2,1
    80004214:	0a91                	addi	s5,s5,4
    80004216:	02ca2783          	lw	a5,44(s4)
    8000421a:	f8f94ee3          	blt	s2,a5,800041b6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	c6a080e7          	jalr	-918(ra) # 80003e88 <write_head>
    install_trans(0); // Now install writes to home locations
    80004226:	4501                	li	a0,0
    80004228:	00000097          	auipc	ra,0x0
    8000422c:	cda080e7          	jalr	-806(ra) # 80003f02 <install_trans>
    log.lh.n = 0;
    80004230:	0001d797          	auipc	a5,0x1d
    80004234:	6607ae23          	sw	zero,1660(a5) # 800218ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	c50080e7          	jalr	-944(ra) # 80003e88 <write_head>
    80004240:	bdf5                	j	8000413c <end_op+0x52>

0000000080004242 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004242:	1101                	addi	sp,sp,-32
    80004244:	ec06                	sd	ra,24(sp)
    80004246:	e822                	sd	s0,16(sp)
    80004248:	e426                	sd	s1,8(sp)
    8000424a:	e04a                	sd	s2,0(sp)
    8000424c:	1000                	addi	s0,sp,32
    8000424e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004250:	0001d917          	auipc	s2,0x1d
    80004254:	63090913          	addi	s2,s2,1584 # 80021880 <log>
    80004258:	854a                	mv	a0,s2
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	968080e7          	jalr	-1688(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004262:	02c92603          	lw	a2,44(s2)
    80004266:	47f5                	li	a5,29
    80004268:	06c7c563          	blt	a5,a2,800042d2 <log_write+0x90>
    8000426c:	0001d797          	auipc	a5,0x1d
    80004270:	6307a783          	lw	a5,1584(a5) # 8002189c <log+0x1c>
    80004274:	37fd                	addiw	a5,a5,-1
    80004276:	04f65e63          	bge	a2,a5,800042d2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000427a:	0001d797          	auipc	a5,0x1d
    8000427e:	6267a783          	lw	a5,1574(a5) # 800218a0 <log+0x20>
    80004282:	06f05063          	blez	a5,800042e2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004286:	4781                	li	a5,0
    80004288:	06c05563          	blez	a2,800042f2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000428c:	44cc                	lw	a1,12(s1)
    8000428e:	0001d717          	auipc	a4,0x1d
    80004292:	62270713          	addi	a4,a4,1570 # 800218b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004296:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004298:	4314                	lw	a3,0(a4)
    8000429a:	04b68c63          	beq	a3,a1,800042f2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000429e:	2785                	addiw	a5,a5,1
    800042a0:	0711                	addi	a4,a4,4
    800042a2:	fef61be3          	bne	a2,a5,80004298 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042a6:	0621                	addi	a2,a2,8
    800042a8:	060a                	slli	a2,a2,0x2
    800042aa:	0001d797          	auipc	a5,0x1d
    800042ae:	5d678793          	addi	a5,a5,1494 # 80021880 <log>
    800042b2:	963e                	add	a2,a2,a5
    800042b4:	44dc                	lw	a5,12(s1)
    800042b6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042b8:	8526                	mv	a0,s1
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	daa080e7          	jalr	-598(ra) # 80003064 <bpin>
    log.lh.n++;
    800042c2:	0001d717          	auipc	a4,0x1d
    800042c6:	5be70713          	addi	a4,a4,1470 # 80021880 <log>
    800042ca:	575c                	lw	a5,44(a4)
    800042cc:	2785                	addiw	a5,a5,1
    800042ce:	d75c                	sw	a5,44(a4)
    800042d0:	a835                	j	8000430c <log_write+0xca>
    panic("too big a transaction");
    800042d2:	00004517          	auipc	a0,0x4
    800042d6:	35650513          	addi	a0,a0,854 # 80008628 <syscalls+0x1f8>
    800042da:	ffffc097          	auipc	ra,0xffffc
    800042de:	250080e7          	jalr	592(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800042e2:	00004517          	auipc	a0,0x4
    800042e6:	35e50513          	addi	a0,a0,862 # 80008640 <syscalls+0x210>
    800042ea:	ffffc097          	auipc	ra,0xffffc
    800042ee:	240080e7          	jalr	576(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800042f2:	00878713          	addi	a4,a5,8
    800042f6:	00271693          	slli	a3,a4,0x2
    800042fa:	0001d717          	auipc	a4,0x1d
    800042fe:	58670713          	addi	a4,a4,1414 # 80021880 <log>
    80004302:	9736                	add	a4,a4,a3
    80004304:	44d4                	lw	a3,12(s1)
    80004306:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004308:	faf608e3          	beq	a2,a5,800042b8 <log_write+0x76>
  }
  release(&log.lock);
    8000430c:	0001d517          	auipc	a0,0x1d
    80004310:	57450513          	addi	a0,a0,1396 # 80021880 <log>
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	962080e7          	jalr	-1694(ra) # 80000c76 <release>
}
    8000431c:	60e2                	ld	ra,24(sp)
    8000431e:	6442                	ld	s0,16(sp)
    80004320:	64a2                	ld	s1,8(sp)
    80004322:	6902                	ld	s2,0(sp)
    80004324:	6105                	addi	sp,sp,32
    80004326:	8082                	ret

0000000080004328 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004328:	1101                	addi	sp,sp,-32
    8000432a:	ec06                	sd	ra,24(sp)
    8000432c:	e822                	sd	s0,16(sp)
    8000432e:	e426                	sd	s1,8(sp)
    80004330:	e04a                	sd	s2,0(sp)
    80004332:	1000                	addi	s0,sp,32
    80004334:	84aa                	mv	s1,a0
    80004336:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004338:	00004597          	auipc	a1,0x4
    8000433c:	32858593          	addi	a1,a1,808 # 80008660 <syscalls+0x230>
    80004340:	0521                	addi	a0,a0,8
    80004342:	ffffc097          	auipc	ra,0xffffc
    80004346:	7f0080e7          	jalr	2032(ra) # 80000b32 <initlock>
  lk->name = name;
    8000434a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000434e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004352:	0204a423          	sw	zero,40(s1)
}
    80004356:	60e2                	ld	ra,24(sp)
    80004358:	6442                	ld	s0,16(sp)
    8000435a:	64a2                	ld	s1,8(sp)
    8000435c:	6902                	ld	s2,0(sp)
    8000435e:	6105                	addi	sp,sp,32
    80004360:	8082                	ret

0000000080004362 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004362:	1101                	addi	sp,sp,-32
    80004364:	ec06                	sd	ra,24(sp)
    80004366:	e822                	sd	s0,16(sp)
    80004368:	e426                	sd	s1,8(sp)
    8000436a:	e04a                	sd	s2,0(sp)
    8000436c:	1000                	addi	s0,sp,32
    8000436e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004370:	00850913          	addi	s2,a0,8
    80004374:	854a                	mv	a0,s2
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	84c080e7          	jalr	-1972(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000437e:	409c                	lw	a5,0(s1)
    80004380:	cb89                	beqz	a5,80004392 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004382:	85ca                	mv	a1,s2
    80004384:	8526                	mv	a0,s1
    80004386:	ffffe097          	auipc	ra,0xffffe
    8000438a:	cf4080e7          	jalr	-780(ra) # 8000207a <sleep>
  while (lk->locked) {
    8000438e:	409c                	lw	a5,0(s1)
    80004390:	fbed                	bnez	a5,80004382 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004392:	4785                	li	a5,1
    80004394:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	5e8080e7          	jalr	1512(ra) # 8000197e <myproc>
    8000439e:	591c                	lw	a5,48(a0)
    800043a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043a2:	854a                	mv	a0,s2
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	8d2080e7          	jalr	-1838(ra) # 80000c76 <release>
}
    800043ac:	60e2                	ld	ra,24(sp)
    800043ae:	6442                	ld	s0,16(sp)
    800043b0:	64a2                	ld	s1,8(sp)
    800043b2:	6902                	ld	s2,0(sp)
    800043b4:	6105                	addi	sp,sp,32
    800043b6:	8082                	ret

00000000800043b8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043b8:	1101                	addi	sp,sp,-32
    800043ba:	ec06                	sd	ra,24(sp)
    800043bc:	e822                	sd	s0,16(sp)
    800043be:	e426                	sd	s1,8(sp)
    800043c0:	e04a                	sd	s2,0(sp)
    800043c2:	1000                	addi	s0,sp,32
    800043c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c6:	00850913          	addi	s2,a0,8
    800043ca:	854a                	mv	a0,s2
    800043cc:	ffffc097          	auipc	ra,0xffffc
    800043d0:	7f6080e7          	jalr	2038(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800043d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043d8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043dc:	8526                	mv	a0,s1
    800043de:	ffffe097          	auipc	ra,0xffffe
    800043e2:	e28080e7          	jalr	-472(ra) # 80002206 <wakeup>
  release(&lk->lk);
    800043e6:	854a                	mv	a0,s2
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	88e080e7          	jalr	-1906(ra) # 80000c76 <release>
}
    800043f0:	60e2                	ld	ra,24(sp)
    800043f2:	6442                	ld	s0,16(sp)
    800043f4:	64a2                	ld	s1,8(sp)
    800043f6:	6902                	ld	s2,0(sp)
    800043f8:	6105                	addi	sp,sp,32
    800043fa:	8082                	ret

00000000800043fc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043fc:	7179                	addi	sp,sp,-48
    800043fe:	f406                	sd	ra,40(sp)
    80004400:	f022                	sd	s0,32(sp)
    80004402:	ec26                	sd	s1,24(sp)
    80004404:	e84a                	sd	s2,16(sp)
    80004406:	e44e                	sd	s3,8(sp)
    80004408:	1800                	addi	s0,sp,48
    8000440a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000440c:	00850913          	addi	s2,a0,8
    80004410:	854a                	mv	a0,s2
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	7b0080e7          	jalr	1968(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000441a:	409c                	lw	a5,0(s1)
    8000441c:	ef99                	bnez	a5,8000443a <holdingsleep+0x3e>
    8000441e:	4481                	li	s1,0
  release(&lk->lk);
    80004420:	854a                	mv	a0,s2
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	854080e7          	jalr	-1964(ra) # 80000c76 <release>
  return r;
}
    8000442a:	8526                	mv	a0,s1
    8000442c:	70a2                	ld	ra,40(sp)
    8000442e:	7402                	ld	s0,32(sp)
    80004430:	64e2                	ld	s1,24(sp)
    80004432:	6942                	ld	s2,16(sp)
    80004434:	69a2                	ld	s3,8(sp)
    80004436:	6145                	addi	sp,sp,48
    80004438:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000443a:	0284a983          	lw	s3,40(s1)
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	540080e7          	jalr	1344(ra) # 8000197e <myproc>
    80004446:	5904                	lw	s1,48(a0)
    80004448:	413484b3          	sub	s1,s1,s3
    8000444c:	0014b493          	seqz	s1,s1
    80004450:	bfc1                	j	80004420 <holdingsleep+0x24>

0000000080004452 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004452:	1141                	addi	sp,sp,-16
    80004454:	e406                	sd	ra,8(sp)
    80004456:	e022                	sd	s0,0(sp)
    80004458:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000445a:	00004597          	auipc	a1,0x4
    8000445e:	21658593          	addi	a1,a1,534 # 80008670 <syscalls+0x240>
    80004462:	0001d517          	auipc	a0,0x1d
    80004466:	56650513          	addi	a0,a0,1382 # 800219c8 <ftable>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	6c8080e7          	jalr	1736(ra) # 80000b32 <initlock>
}
    80004472:	60a2                	ld	ra,8(sp)
    80004474:	6402                	ld	s0,0(sp)
    80004476:	0141                	addi	sp,sp,16
    80004478:	8082                	ret

000000008000447a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004484:	0001d517          	auipc	a0,0x1d
    80004488:	54450513          	addi	a0,a0,1348 # 800219c8 <ftable>
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	736080e7          	jalr	1846(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004494:	0001d497          	auipc	s1,0x1d
    80004498:	54c48493          	addi	s1,s1,1356 # 800219e0 <ftable+0x18>
    8000449c:	0001e717          	auipc	a4,0x1e
    800044a0:	4e470713          	addi	a4,a4,1252 # 80022980 <ftable+0xfb8>
    if(f->ref == 0){
    800044a4:	40dc                	lw	a5,4(s1)
    800044a6:	cf99                	beqz	a5,800044c4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044a8:	02848493          	addi	s1,s1,40
    800044ac:	fee49ce3          	bne	s1,a4,800044a4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044b0:	0001d517          	auipc	a0,0x1d
    800044b4:	51850513          	addi	a0,a0,1304 # 800219c8 <ftable>
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	7be080e7          	jalr	1982(ra) # 80000c76 <release>
  return 0;
    800044c0:	4481                	li	s1,0
    800044c2:	a819                	j	800044d8 <filealloc+0x5e>
      f->ref = 1;
    800044c4:	4785                	li	a5,1
    800044c6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044c8:	0001d517          	auipc	a0,0x1d
    800044cc:	50050513          	addi	a0,a0,1280 # 800219c8 <ftable>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	7a6080e7          	jalr	1958(ra) # 80000c76 <release>
}
    800044d8:	8526                	mv	a0,s1
    800044da:	60e2                	ld	ra,24(sp)
    800044dc:	6442                	ld	s0,16(sp)
    800044de:	64a2                	ld	s1,8(sp)
    800044e0:	6105                	addi	sp,sp,32
    800044e2:	8082                	ret

00000000800044e4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044e4:	1101                	addi	sp,sp,-32
    800044e6:	ec06                	sd	ra,24(sp)
    800044e8:	e822                	sd	s0,16(sp)
    800044ea:	e426                	sd	s1,8(sp)
    800044ec:	1000                	addi	s0,sp,32
    800044ee:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044f0:	0001d517          	auipc	a0,0x1d
    800044f4:	4d850513          	addi	a0,a0,1240 # 800219c8 <ftable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	6ca080e7          	jalr	1738(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004500:	40dc                	lw	a5,4(s1)
    80004502:	02f05263          	blez	a5,80004526 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004506:	2785                	addiw	a5,a5,1
    80004508:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	4be50513          	addi	a0,a0,1214 # 800219c8 <ftable>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	764080e7          	jalr	1892(ra) # 80000c76 <release>
  return f;
}
    8000451a:	8526                	mv	a0,s1
    8000451c:	60e2                	ld	ra,24(sp)
    8000451e:	6442                	ld	s0,16(sp)
    80004520:	64a2                	ld	s1,8(sp)
    80004522:	6105                	addi	sp,sp,32
    80004524:	8082                	ret
    panic("filedup");
    80004526:	00004517          	auipc	a0,0x4
    8000452a:	15250513          	addi	a0,a0,338 # 80008678 <syscalls+0x248>
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	ffc080e7          	jalr	-4(ra) # 8000052a <panic>

0000000080004536 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004536:	7139                	addi	sp,sp,-64
    80004538:	fc06                	sd	ra,56(sp)
    8000453a:	f822                	sd	s0,48(sp)
    8000453c:	f426                	sd	s1,40(sp)
    8000453e:	f04a                	sd	s2,32(sp)
    80004540:	ec4e                	sd	s3,24(sp)
    80004542:	e852                	sd	s4,16(sp)
    80004544:	e456                	sd	s5,8(sp)
    80004546:	0080                	addi	s0,sp,64
    80004548:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000454a:	0001d517          	auipc	a0,0x1d
    8000454e:	47e50513          	addi	a0,a0,1150 # 800219c8 <ftable>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	670080e7          	jalr	1648(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000455a:	40dc                	lw	a5,4(s1)
    8000455c:	06f05163          	blez	a5,800045be <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004560:	37fd                	addiw	a5,a5,-1
    80004562:	0007871b          	sext.w	a4,a5
    80004566:	c0dc                	sw	a5,4(s1)
    80004568:	06e04363          	bgtz	a4,800045ce <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000456c:	0004a903          	lw	s2,0(s1)
    80004570:	0094ca83          	lbu	s5,9(s1)
    80004574:	0104ba03          	ld	s4,16(s1)
    80004578:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000457c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004580:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	44450513          	addi	a0,a0,1092 # 800219c8 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	6ea080e7          	jalr	1770(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004594:	4785                	li	a5,1
    80004596:	04f90d63          	beq	s2,a5,800045f0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000459a:	3979                	addiw	s2,s2,-2
    8000459c:	4785                	li	a5,1
    8000459e:	0527e063          	bltu	a5,s2,800045de <fileclose+0xa8>
    begin_op();
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	ac8080e7          	jalr	-1336(ra) # 8000406a <begin_op>
    iput(ff.ip);
    800045aa:	854e                	mv	a0,s3
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	2a6080e7          	jalr	678(ra) # 80003852 <iput>
    end_op();
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	b36080e7          	jalr	-1226(ra) # 800040ea <end_op>
    800045bc:	a00d                	j	800045de <fileclose+0xa8>
    panic("fileclose");
    800045be:	00004517          	auipc	a0,0x4
    800045c2:	0c250513          	addi	a0,a0,194 # 80008680 <syscalls+0x250>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f64080e7          	jalr	-156(ra) # 8000052a <panic>
    release(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	3fa50513          	addi	a0,a0,1018 # 800219c8 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6a0080e7          	jalr	1696(ra) # 80000c76 <release>
  }
}
    800045de:	70e2                	ld	ra,56(sp)
    800045e0:	7442                	ld	s0,48(sp)
    800045e2:	74a2                	ld	s1,40(sp)
    800045e4:	7902                	ld	s2,32(sp)
    800045e6:	69e2                	ld	s3,24(sp)
    800045e8:	6a42                	ld	s4,16(sp)
    800045ea:	6aa2                	ld	s5,8(sp)
    800045ec:	6121                	addi	sp,sp,64
    800045ee:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045f0:	85d6                	mv	a1,s5
    800045f2:	8552                	mv	a0,s4
    800045f4:	00000097          	auipc	ra,0x0
    800045f8:	34c080e7          	jalr	844(ra) # 80004940 <pipeclose>
    800045fc:	b7cd                	j	800045de <fileclose+0xa8>

00000000800045fe <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045fe:	715d                	addi	sp,sp,-80
    80004600:	e486                	sd	ra,72(sp)
    80004602:	e0a2                	sd	s0,64(sp)
    80004604:	fc26                	sd	s1,56(sp)
    80004606:	f84a                	sd	s2,48(sp)
    80004608:	f44e                	sd	s3,40(sp)
    8000460a:	0880                	addi	s0,sp,80
    8000460c:	84aa                	mv	s1,a0
    8000460e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004610:	ffffd097          	auipc	ra,0xffffd
    80004614:	36e080e7          	jalr	878(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004618:	409c                	lw	a5,0(s1)
    8000461a:	37f9                	addiw	a5,a5,-2
    8000461c:	4705                	li	a4,1
    8000461e:	04f76763          	bltu	a4,a5,8000466c <filestat+0x6e>
    80004622:	892a                	mv	s2,a0
    ilock(f->ip);
    80004624:	6c88                	ld	a0,24(s1)
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	072080e7          	jalr	114(ra) # 80003698 <ilock>
    stati(f->ip, &st);
    8000462e:	fb840593          	addi	a1,s0,-72
    80004632:	6c88                	ld	a0,24(s1)
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	2ee080e7          	jalr	750(ra) # 80003922 <stati>
    iunlock(f->ip);
    8000463c:	6c88                	ld	a0,24(s1)
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	11c080e7          	jalr	284(ra) # 8000375a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004646:	46e1                	li	a3,24
    80004648:	fb840613          	addi	a2,s0,-72
    8000464c:	85ce                	mv	a1,s3
    8000464e:	05093503          	ld	a0,80(s2)
    80004652:	ffffd097          	auipc	ra,0xffffd
    80004656:	fec080e7          	jalr	-20(ra) # 8000163e <copyout>
    8000465a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000465e:	60a6                	ld	ra,72(sp)
    80004660:	6406                	ld	s0,64(sp)
    80004662:	74e2                	ld	s1,56(sp)
    80004664:	7942                	ld	s2,48(sp)
    80004666:	79a2                	ld	s3,40(sp)
    80004668:	6161                	addi	sp,sp,80
    8000466a:	8082                	ret
  return -1;
    8000466c:	557d                	li	a0,-1
    8000466e:	bfc5                	j	8000465e <filestat+0x60>

0000000080004670 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004670:	7179                	addi	sp,sp,-48
    80004672:	f406                	sd	ra,40(sp)
    80004674:	f022                	sd	s0,32(sp)
    80004676:	ec26                	sd	s1,24(sp)
    80004678:	e84a                	sd	s2,16(sp)
    8000467a:	e44e                	sd	s3,8(sp)
    8000467c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000467e:	00854783          	lbu	a5,8(a0)
    80004682:	c3d5                	beqz	a5,80004726 <fileread+0xb6>
    80004684:	84aa                	mv	s1,a0
    80004686:	89ae                	mv	s3,a1
    80004688:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000468a:	411c                	lw	a5,0(a0)
    8000468c:	4705                	li	a4,1
    8000468e:	04e78963          	beq	a5,a4,800046e0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004692:	470d                	li	a4,3
    80004694:	04e78d63          	beq	a5,a4,800046ee <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004698:	4709                	li	a4,2
    8000469a:	06e79e63          	bne	a5,a4,80004716 <fileread+0xa6>
    ilock(f->ip);
    8000469e:	6d08                	ld	a0,24(a0)
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	ff8080e7          	jalr	-8(ra) # 80003698 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046a8:	874a                	mv	a4,s2
    800046aa:	5094                	lw	a3,32(s1)
    800046ac:	864e                	mv	a2,s3
    800046ae:	4585                	li	a1,1
    800046b0:	6c88                	ld	a0,24(s1)
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	29a080e7          	jalr	666(ra) # 8000394c <readi>
    800046ba:	892a                	mv	s2,a0
    800046bc:	00a05563          	blez	a0,800046c6 <fileread+0x56>
      f->off += r;
    800046c0:	509c                	lw	a5,32(s1)
    800046c2:	9fa9                	addw	a5,a5,a0
    800046c4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046c6:	6c88                	ld	a0,24(s1)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	092080e7          	jalr	146(ra) # 8000375a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046d0:	854a                	mv	a0,s2
    800046d2:	70a2                	ld	ra,40(sp)
    800046d4:	7402                	ld	s0,32(sp)
    800046d6:	64e2                	ld	s1,24(sp)
    800046d8:	6942                	ld	s2,16(sp)
    800046da:	69a2                	ld	s3,8(sp)
    800046dc:	6145                	addi	sp,sp,48
    800046de:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046e0:	6908                	ld	a0,16(a0)
    800046e2:	00000097          	auipc	ra,0x0
    800046e6:	3c0080e7          	jalr	960(ra) # 80004aa2 <piperead>
    800046ea:	892a                	mv	s2,a0
    800046ec:	b7d5                	j	800046d0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046ee:	02451783          	lh	a5,36(a0)
    800046f2:	03079693          	slli	a3,a5,0x30
    800046f6:	92c1                	srli	a3,a3,0x30
    800046f8:	4725                	li	a4,9
    800046fa:	02d76863          	bltu	a4,a3,8000472a <fileread+0xba>
    800046fe:	0792                	slli	a5,a5,0x4
    80004700:	0001d717          	auipc	a4,0x1d
    80004704:	22870713          	addi	a4,a4,552 # 80021928 <devsw>
    80004708:	97ba                	add	a5,a5,a4
    8000470a:	639c                	ld	a5,0(a5)
    8000470c:	c38d                	beqz	a5,8000472e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000470e:	4505                	li	a0,1
    80004710:	9782                	jalr	a5
    80004712:	892a                	mv	s2,a0
    80004714:	bf75                	j	800046d0 <fileread+0x60>
    panic("fileread");
    80004716:	00004517          	auipc	a0,0x4
    8000471a:	f7a50513          	addi	a0,a0,-134 # 80008690 <syscalls+0x260>
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	e0c080e7          	jalr	-500(ra) # 8000052a <panic>
    return -1;
    80004726:	597d                	li	s2,-1
    80004728:	b765                	j	800046d0 <fileread+0x60>
      return -1;
    8000472a:	597d                	li	s2,-1
    8000472c:	b755                	j	800046d0 <fileread+0x60>
    8000472e:	597d                	li	s2,-1
    80004730:	b745                	j	800046d0 <fileread+0x60>

0000000080004732 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004732:	715d                	addi	sp,sp,-80
    80004734:	e486                	sd	ra,72(sp)
    80004736:	e0a2                	sd	s0,64(sp)
    80004738:	fc26                	sd	s1,56(sp)
    8000473a:	f84a                	sd	s2,48(sp)
    8000473c:	f44e                	sd	s3,40(sp)
    8000473e:	f052                	sd	s4,32(sp)
    80004740:	ec56                	sd	s5,24(sp)
    80004742:	e85a                	sd	s6,16(sp)
    80004744:	e45e                	sd	s7,8(sp)
    80004746:	e062                	sd	s8,0(sp)
    80004748:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000474a:	00954783          	lbu	a5,9(a0)
    8000474e:	10078663          	beqz	a5,8000485a <filewrite+0x128>
    80004752:	892a                	mv	s2,a0
    80004754:	8aae                	mv	s5,a1
    80004756:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004758:	411c                	lw	a5,0(a0)
    8000475a:	4705                	li	a4,1
    8000475c:	02e78263          	beq	a5,a4,80004780 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004760:	470d                	li	a4,3
    80004762:	02e78663          	beq	a5,a4,8000478e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004766:	4709                	li	a4,2
    80004768:	0ee79163          	bne	a5,a4,8000484a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000476c:	0ac05d63          	blez	a2,80004826 <filewrite+0xf4>
    int i = 0;
    80004770:	4981                	li	s3,0
    80004772:	6b05                	lui	s6,0x1
    80004774:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004778:	6b85                	lui	s7,0x1
    8000477a:	c00b8b9b          	addiw	s7,s7,-1024
    8000477e:	a861                	j	80004816 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004780:	6908                	ld	a0,16(a0)
    80004782:	00000097          	auipc	ra,0x0
    80004786:	22e080e7          	jalr	558(ra) # 800049b0 <pipewrite>
    8000478a:	8a2a                	mv	s4,a0
    8000478c:	a045                	j	8000482c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000478e:	02451783          	lh	a5,36(a0)
    80004792:	03079693          	slli	a3,a5,0x30
    80004796:	92c1                	srli	a3,a3,0x30
    80004798:	4725                	li	a4,9
    8000479a:	0cd76263          	bltu	a4,a3,8000485e <filewrite+0x12c>
    8000479e:	0792                	slli	a5,a5,0x4
    800047a0:	0001d717          	auipc	a4,0x1d
    800047a4:	18870713          	addi	a4,a4,392 # 80021928 <devsw>
    800047a8:	97ba                	add	a5,a5,a4
    800047aa:	679c                	ld	a5,8(a5)
    800047ac:	cbdd                	beqz	a5,80004862 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047ae:	4505                	li	a0,1
    800047b0:	9782                	jalr	a5
    800047b2:	8a2a                	mv	s4,a0
    800047b4:	a8a5                	j	8000482c <filewrite+0xfa>
    800047b6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	8b0080e7          	jalr	-1872(ra) # 8000406a <begin_op>
      ilock(f->ip);
    800047c2:	01893503          	ld	a0,24(s2)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	ed2080e7          	jalr	-302(ra) # 80003698 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047ce:	8762                	mv	a4,s8
    800047d0:	02092683          	lw	a3,32(s2)
    800047d4:	01598633          	add	a2,s3,s5
    800047d8:	4585                	li	a1,1
    800047da:	01893503          	ld	a0,24(s2)
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	266080e7          	jalr	614(ra) # 80003a44 <writei>
    800047e6:	84aa                	mv	s1,a0
    800047e8:	00a05763          	blez	a0,800047f6 <filewrite+0xc4>
        f->off += r;
    800047ec:	02092783          	lw	a5,32(s2)
    800047f0:	9fa9                	addw	a5,a5,a0
    800047f2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047f6:	01893503          	ld	a0,24(s2)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	f60080e7          	jalr	-160(ra) # 8000375a <iunlock>
      end_op();
    80004802:	00000097          	auipc	ra,0x0
    80004806:	8e8080e7          	jalr	-1816(ra) # 800040ea <end_op>

      if(r != n1){
    8000480a:	009c1f63          	bne	s8,s1,80004828 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000480e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004812:	0149db63          	bge	s3,s4,80004828 <filewrite+0xf6>
      int n1 = n - i;
    80004816:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000481a:	84be                	mv	s1,a5
    8000481c:	2781                	sext.w	a5,a5
    8000481e:	f8fb5ce3          	bge	s6,a5,800047b6 <filewrite+0x84>
    80004822:	84de                	mv	s1,s7
    80004824:	bf49                	j	800047b6 <filewrite+0x84>
    int i = 0;
    80004826:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004828:	013a1f63          	bne	s4,s3,80004846 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000482c:	8552                	mv	a0,s4
    8000482e:	60a6                	ld	ra,72(sp)
    80004830:	6406                	ld	s0,64(sp)
    80004832:	74e2                	ld	s1,56(sp)
    80004834:	7942                	ld	s2,48(sp)
    80004836:	79a2                	ld	s3,40(sp)
    80004838:	7a02                	ld	s4,32(sp)
    8000483a:	6ae2                	ld	s5,24(sp)
    8000483c:	6b42                	ld	s6,16(sp)
    8000483e:	6ba2                	ld	s7,8(sp)
    80004840:	6c02                	ld	s8,0(sp)
    80004842:	6161                	addi	sp,sp,80
    80004844:	8082                	ret
    ret = (i == n ? n : -1);
    80004846:	5a7d                	li	s4,-1
    80004848:	b7d5                	j	8000482c <filewrite+0xfa>
    panic("filewrite");
    8000484a:	00004517          	auipc	a0,0x4
    8000484e:	e5650513          	addi	a0,a0,-426 # 800086a0 <syscalls+0x270>
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	cd8080e7          	jalr	-808(ra) # 8000052a <panic>
    return -1;
    8000485a:	5a7d                	li	s4,-1
    8000485c:	bfc1                	j	8000482c <filewrite+0xfa>
      return -1;
    8000485e:	5a7d                	li	s4,-1
    80004860:	b7f1                	j	8000482c <filewrite+0xfa>
    80004862:	5a7d                	li	s4,-1
    80004864:	b7e1                	j	8000482c <filewrite+0xfa>

0000000080004866 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004866:	7179                	addi	sp,sp,-48
    80004868:	f406                	sd	ra,40(sp)
    8000486a:	f022                	sd	s0,32(sp)
    8000486c:	ec26                	sd	s1,24(sp)
    8000486e:	e84a                	sd	s2,16(sp)
    80004870:	e44e                	sd	s3,8(sp)
    80004872:	e052                	sd	s4,0(sp)
    80004874:	1800                	addi	s0,sp,48
    80004876:	84aa                	mv	s1,a0
    80004878:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000487a:	0005b023          	sd	zero,0(a1)
    8000487e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004882:	00000097          	auipc	ra,0x0
    80004886:	bf8080e7          	jalr	-1032(ra) # 8000447a <filealloc>
    8000488a:	e088                	sd	a0,0(s1)
    8000488c:	c551                	beqz	a0,80004918 <pipealloc+0xb2>
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	bec080e7          	jalr	-1044(ra) # 8000447a <filealloc>
    80004896:	00aa3023          	sd	a0,0(s4)
    8000489a:	c92d                	beqz	a0,8000490c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	236080e7          	jalr	566(ra) # 80000ad2 <kalloc>
    800048a4:	892a                	mv	s2,a0
    800048a6:	c125                	beqz	a0,80004906 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048a8:	4985                	li	s3,1
    800048aa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048ae:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048b2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048b6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048ba:	00004597          	auipc	a1,0x4
    800048be:	df658593          	addi	a1,a1,-522 # 800086b0 <syscalls+0x280>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	270080e7          	jalr	624(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800048ca:	609c                	ld	a5,0(s1)
    800048cc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048d0:	609c                	ld	a5,0(s1)
    800048d2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048d6:	609c                	ld	a5,0(s1)
    800048d8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048dc:	609c                	ld	a5,0(s1)
    800048de:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048e2:	000a3783          	ld	a5,0(s4)
    800048e6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048ea:	000a3783          	ld	a5,0(s4)
    800048ee:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048f2:	000a3783          	ld	a5,0(s4)
    800048f6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048fa:	000a3783          	ld	a5,0(s4)
    800048fe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004902:	4501                	li	a0,0
    80004904:	a025                	j	8000492c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004906:	6088                	ld	a0,0(s1)
    80004908:	e501                	bnez	a0,80004910 <pipealloc+0xaa>
    8000490a:	a039                	j	80004918 <pipealloc+0xb2>
    8000490c:	6088                	ld	a0,0(s1)
    8000490e:	c51d                	beqz	a0,8000493c <pipealloc+0xd6>
    fileclose(*f0);
    80004910:	00000097          	auipc	ra,0x0
    80004914:	c26080e7          	jalr	-986(ra) # 80004536 <fileclose>
  if(*f1)
    80004918:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000491c:	557d                	li	a0,-1
  if(*f1)
    8000491e:	c799                	beqz	a5,8000492c <pipealloc+0xc6>
    fileclose(*f1);
    80004920:	853e                	mv	a0,a5
    80004922:	00000097          	auipc	ra,0x0
    80004926:	c14080e7          	jalr	-1004(ra) # 80004536 <fileclose>
  return -1;
    8000492a:	557d                	li	a0,-1
}
    8000492c:	70a2                	ld	ra,40(sp)
    8000492e:	7402                	ld	s0,32(sp)
    80004930:	64e2                	ld	s1,24(sp)
    80004932:	6942                	ld	s2,16(sp)
    80004934:	69a2                	ld	s3,8(sp)
    80004936:	6a02                	ld	s4,0(sp)
    80004938:	6145                	addi	sp,sp,48
    8000493a:	8082                	ret
  return -1;
    8000493c:	557d                	li	a0,-1
    8000493e:	b7fd                	j	8000492c <pipealloc+0xc6>

0000000080004940 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004940:	1101                	addi	sp,sp,-32
    80004942:	ec06                	sd	ra,24(sp)
    80004944:	e822                	sd	s0,16(sp)
    80004946:	e426                	sd	s1,8(sp)
    80004948:	e04a                	sd	s2,0(sp)
    8000494a:	1000                	addi	s0,sp,32
    8000494c:	84aa                	mv	s1,a0
    8000494e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	272080e7          	jalr	626(ra) # 80000bc2 <acquire>
  if(writable){
    80004958:	02090d63          	beqz	s2,80004992 <pipeclose+0x52>
    pi->writeopen = 0;
    8000495c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004960:	21848513          	addi	a0,s1,536
    80004964:	ffffe097          	auipc	ra,0xffffe
    80004968:	8a2080e7          	jalr	-1886(ra) # 80002206 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000496c:	2204b783          	ld	a5,544(s1)
    80004970:	eb95                	bnez	a5,800049a4 <pipeclose+0x64>
    release(&pi->lock);
    80004972:	8526                	mv	a0,s1
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	302080e7          	jalr	770(ra) # 80000c76 <release>
    kfree((char*)pi);
    8000497c:	8526                	mv	a0,s1
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	058080e7          	jalr	88(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004986:	60e2                	ld	ra,24(sp)
    80004988:	6442                	ld	s0,16(sp)
    8000498a:	64a2                	ld	s1,8(sp)
    8000498c:	6902                	ld	s2,0(sp)
    8000498e:	6105                	addi	sp,sp,32
    80004990:	8082                	ret
    pi->readopen = 0;
    80004992:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004996:	21c48513          	addi	a0,s1,540
    8000499a:	ffffe097          	auipc	ra,0xffffe
    8000499e:	86c080e7          	jalr	-1940(ra) # 80002206 <wakeup>
    800049a2:	b7e9                	j	8000496c <pipeclose+0x2c>
    release(&pi->lock);
    800049a4:	8526                	mv	a0,s1
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	2d0080e7          	jalr	720(ra) # 80000c76 <release>
}
    800049ae:	bfe1                	j	80004986 <pipeclose+0x46>

00000000800049b0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049b0:	711d                	addi	sp,sp,-96
    800049b2:	ec86                	sd	ra,88(sp)
    800049b4:	e8a2                	sd	s0,80(sp)
    800049b6:	e4a6                	sd	s1,72(sp)
    800049b8:	e0ca                	sd	s2,64(sp)
    800049ba:	fc4e                	sd	s3,56(sp)
    800049bc:	f852                	sd	s4,48(sp)
    800049be:	f456                	sd	s5,40(sp)
    800049c0:	f05a                	sd	s6,32(sp)
    800049c2:	ec5e                	sd	s7,24(sp)
    800049c4:	e862                	sd	s8,16(sp)
    800049c6:	1080                	addi	s0,sp,96
    800049c8:	84aa                	mv	s1,a0
    800049ca:	8aae                	mv	s5,a1
    800049cc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049ce:	ffffd097          	auipc	ra,0xffffd
    800049d2:	fb0080e7          	jalr	-80(ra) # 8000197e <myproc>
    800049d6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049d8:	8526                	mv	a0,s1
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	1e8080e7          	jalr	488(ra) # 80000bc2 <acquire>
  while(i < n){
    800049e2:	0b405363          	blez	s4,80004a88 <pipewrite+0xd8>
  int i = 0;
    800049e6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049e8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049ea:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049ee:	21c48b93          	addi	s7,s1,540
    800049f2:	a089                	j	80004a34 <pipewrite+0x84>
      release(&pi->lock);
    800049f4:	8526                	mv	a0,s1
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	280080e7          	jalr	640(ra) # 80000c76 <release>
      return -1;
    800049fe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a00:	854a                	mv	a0,s2
    80004a02:	60e6                	ld	ra,88(sp)
    80004a04:	6446                	ld	s0,80(sp)
    80004a06:	64a6                	ld	s1,72(sp)
    80004a08:	6906                	ld	s2,64(sp)
    80004a0a:	79e2                	ld	s3,56(sp)
    80004a0c:	7a42                	ld	s4,48(sp)
    80004a0e:	7aa2                	ld	s5,40(sp)
    80004a10:	7b02                	ld	s6,32(sp)
    80004a12:	6be2                	ld	s7,24(sp)
    80004a14:	6c42                	ld	s8,16(sp)
    80004a16:	6125                	addi	sp,sp,96
    80004a18:	8082                	ret
      wakeup(&pi->nread);
    80004a1a:	8562                	mv	a0,s8
    80004a1c:	ffffd097          	auipc	ra,0xffffd
    80004a20:	7ea080e7          	jalr	2026(ra) # 80002206 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a24:	85a6                	mv	a1,s1
    80004a26:	855e                	mv	a0,s7
    80004a28:	ffffd097          	auipc	ra,0xffffd
    80004a2c:	652080e7          	jalr	1618(ra) # 8000207a <sleep>
  while(i < n){
    80004a30:	05495d63          	bge	s2,s4,80004a8a <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004a34:	2204a783          	lw	a5,544(s1)
    80004a38:	dfd5                	beqz	a5,800049f4 <pipewrite+0x44>
    80004a3a:	0289a783          	lw	a5,40(s3)
    80004a3e:	fbdd                	bnez	a5,800049f4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a40:	2184a783          	lw	a5,536(s1)
    80004a44:	21c4a703          	lw	a4,540(s1)
    80004a48:	2007879b          	addiw	a5,a5,512
    80004a4c:	fcf707e3          	beq	a4,a5,80004a1a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a50:	4685                	li	a3,1
    80004a52:	01590633          	add	a2,s2,s5
    80004a56:	faf40593          	addi	a1,s0,-81
    80004a5a:	0509b503          	ld	a0,80(s3)
    80004a5e:	ffffd097          	auipc	ra,0xffffd
    80004a62:	c6c080e7          	jalr	-916(ra) # 800016ca <copyin>
    80004a66:	03650263          	beq	a0,s6,80004a8a <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a6a:	21c4a783          	lw	a5,540(s1)
    80004a6e:	0017871b          	addiw	a4,a5,1
    80004a72:	20e4ae23          	sw	a4,540(s1)
    80004a76:	1ff7f793          	andi	a5,a5,511
    80004a7a:	97a6                	add	a5,a5,s1
    80004a7c:	faf44703          	lbu	a4,-81(s0)
    80004a80:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a84:	2905                	addiw	s2,s2,1
    80004a86:	b76d                	j	80004a30 <pipewrite+0x80>
  int i = 0;
    80004a88:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a8a:	21848513          	addi	a0,s1,536
    80004a8e:	ffffd097          	auipc	ra,0xffffd
    80004a92:	778080e7          	jalr	1912(ra) # 80002206 <wakeup>
  release(&pi->lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	1de080e7          	jalr	478(ra) # 80000c76 <release>
  return i;
    80004aa0:	b785                	j	80004a00 <pipewrite+0x50>

0000000080004aa2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aa2:	715d                	addi	sp,sp,-80
    80004aa4:	e486                	sd	ra,72(sp)
    80004aa6:	e0a2                	sd	s0,64(sp)
    80004aa8:	fc26                	sd	s1,56(sp)
    80004aaa:	f84a                	sd	s2,48(sp)
    80004aac:	f44e                	sd	s3,40(sp)
    80004aae:	f052                	sd	s4,32(sp)
    80004ab0:	ec56                	sd	s5,24(sp)
    80004ab2:	e85a                	sd	s6,16(sp)
    80004ab4:	0880                	addi	s0,sp,80
    80004ab6:	84aa                	mv	s1,a0
    80004ab8:	892e                	mv	s2,a1
    80004aba:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004abc:	ffffd097          	auipc	ra,0xffffd
    80004ac0:	ec2080e7          	jalr	-318(ra) # 8000197e <myproc>
    80004ac4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	0fa080e7          	jalr	250(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ad0:	2184a703          	lw	a4,536(s1)
    80004ad4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ad8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004adc:	02f71463          	bne	a4,a5,80004b04 <piperead+0x62>
    80004ae0:	2244a783          	lw	a5,548(s1)
    80004ae4:	c385                	beqz	a5,80004b04 <piperead+0x62>
    if(pr->killed){
    80004ae6:	028a2783          	lw	a5,40(s4)
    80004aea:	ebc1                	bnez	a5,80004b7a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aec:	85a6                	mv	a1,s1
    80004aee:	854e                	mv	a0,s3
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	58a080e7          	jalr	1418(ra) # 8000207a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004af8:	2184a703          	lw	a4,536(s1)
    80004afc:	21c4a783          	lw	a5,540(s1)
    80004b00:	fef700e3          	beq	a4,a5,80004ae0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b04:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b06:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b08:	05505363          	blez	s5,80004b4e <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b0c:	2184a783          	lw	a5,536(s1)
    80004b10:	21c4a703          	lw	a4,540(s1)
    80004b14:	02f70d63          	beq	a4,a5,80004b4e <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b18:	0017871b          	addiw	a4,a5,1
    80004b1c:	20e4ac23          	sw	a4,536(s1)
    80004b20:	1ff7f793          	andi	a5,a5,511
    80004b24:	97a6                	add	a5,a5,s1
    80004b26:	0187c783          	lbu	a5,24(a5)
    80004b2a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b2e:	4685                	li	a3,1
    80004b30:	fbf40613          	addi	a2,s0,-65
    80004b34:	85ca                	mv	a1,s2
    80004b36:	050a3503          	ld	a0,80(s4)
    80004b3a:	ffffd097          	auipc	ra,0xffffd
    80004b3e:	b04080e7          	jalr	-1276(ra) # 8000163e <copyout>
    80004b42:	01650663          	beq	a0,s6,80004b4e <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b46:	2985                	addiw	s3,s3,1
    80004b48:	0905                	addi	s2,s2,1
    80004b4a:	fd3a91e3          	bne	s5,s3,80004b0c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b4e:	21c48513          	addi	a0,s1,540
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	6b4080e7          	jalr	1716(ra) # 80002206 <wakeup>
  release(&pi->lock);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	11a080e7          	jalr	282(ra) # 80000c76 <release>
  return i;
}
    80004b64:	854e                	mv	a0,s3
    80004b66:	60a6                	ld	ra,72(sp)
    80004b68:	6406                	ld	s0,64(sp)
    80004b6a:	74e2                	ld	s1,56(sp)
    80004b6c:	7942                	ld	s2,48(sp)
    80004b6e:	79a2                	ld	s3,40(sp)
    80004b70:	7a02                	ld	s4,32(sp)
    80004b72:	6ae2                	ld	s5,24(sp)
    80004b74:	6b42                	ld	s6,16(sp)
    80004b76:	6161                	addi	sp,sp,80
    80004b78:	8082                	ret
      release(&pi->lock);
    80004b7a:	8526                	mv	a0,s1
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	0fa080e7          	jalr	250(ra) # 80000c76 <release>
      return -1;
    80004b84:	59fd                	li	s3,-1
    80004b86:	bff9                	j	80004b64 <piperead+0xc2>

0000000080004b88 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b88:	de010113          	addi	sp,sp,-544
    80004b8c:	20113c23          	sd	ra,536(sp)
    80004b90:	20813823          	sd	s0,528(sp)
    80004b94:	20913423          	sd	s1,520(sp)
    80004b98:	21213023          	sd	s2,512(sp)
    80004b9c:	ffce                	sd	s3,504(sp)
    80004b9e:	fbd2                	sd	s4,496(sp)
    80004ba0:	f7d6                	sd	s5,488(sp)
    80004ba2:	f3da                	sd	s6,480(sp)
    80004ba4:	efde                	sd	s7,472(sp)
    80004ba6:	ebe2                	sd	s8,464(sp)
    80004ba8:	e7e6                	sd	s9,456(sp)
    80004baa:	e3ea                	sd	s10,448(sp)
    80004bac:	ff6e                	sd	s11,440(sp)
    80004bae:	1400                	addi	s0,sp,544
    80004bb0:	892a                	mv	s2,a0
    80004bb2:	dea43423          	sd	a0,-536(s0)
    80004bb6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	dc4080e7          	jalr	-572(ra) # 8000197e <myproc>
    80004bc2:	84aa                	mv	s1,a0

  begin_op();
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	4a6080e7          	jalr	1190(ra) # 8000406a <begin_op>

  if((ip = namei(path)) == 0){
    80004bcc:	854a                	mv	a0,s2
    80004bce:	fffff097          	auipc	ra,0xfffff
    80004bd2:	280080e7          	jalr	640(ra) # 80003e4e <namei>
    80004bd6:	c93d                	beqz	a0,80004c4c <exec+0xc4>
    80004bd8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	abe080e7          	jalr	-1346(ra) # 80003698 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004be2:	04000713          	li	a4,64
    80004be6:	4681                	li	a3,0
    80004be8:	e4840613          	addi	a2,s0,-440
    80004bec:	4581                	li	a1,0
    80004bee:	8556                	mv	a0,s5
    80004bf0:	fffff097          	auipc	ra,0xfffff
    80004bf4:	d5c080e7          	jalr	-676(ra) # 8000394c <readi>
    80004bf8:	04000793          	li	a5,64
    80004bfc:	00f51a63          	bne	a0,a5,80004c10 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c00:	e4842703          	lw	a4,-440(s0)
    80004c04:	464c47b7          	lui	a5,0x464c4
    80004c08:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c0c:	04f70663          	beq	a4,a5,80004c58 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c10:	8556                	mv	a0,s5
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	ce8080e7          	jalr	-792(ra) # 800038fa <iunlockput>
    end_op();
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	4d0080e7          	jalr	1232(ra) # 800040ea <end_op>
  }
  return -1;
    80004c22:	557d                	li	a0,-1
}
    80004c24:	21813083          	ld	ra,536(sp)
    80004c28:	21013403          	ld	s0,528(sp)
    80004c2c:	20813483          	ld	s1,520(sp)
    80004c30:	20013903          	ld	s2,512(sp)
    80004c34:	79fe                	ld	s3,504(sp)
    80004c36:	7a5e                	ld	s4,496(sp)
    80004c38:	7abe                	ld	s5,488(sp)
    80004c3a:	7b1e                	ld	s6,480(sp)
    80004c3c:	6bfe                	ld	s7,472(sp)
    80004c3e:	6c5e                	ld	s8,464(sp)
    80004c40:	6cbe                	ld	s9,456(sp)
    80004c42:	6d1e                	ld	s10,448(sp)
    80004c44:	7dfa                	ld	s11,440(sp)
    80004c46:	22010113          	addi	sp,sp,544
    80004c4a:	8082                	ret
    end_op();
    80004c4c:	fffff097          	auipc	ra,0xfffff
    80004c50:	49e080e7          	jalr	1182(ra) # 800040ea <end_op>
    return -1;
    80004c54:	557d                	li	a0,-1
    80004c56:	b7f9                	j	80004c24 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	de8080e7          	jalr	-536(ra) # 80001a42 <proc_pagetable>
    80004c62:	8b2a                	mv	s6,a0
    80004c64:	d555                	beqz	a0,80004c10 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c66:	e6842783          	lw	a5,-408(s0)
    80004c6a:	e8045703          	lhu	a4,-384(s0)
    80004c6e:	c735                	beqz	a4,80004cda <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c70:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c72:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004c76:	6a05                	lui	s4,0x1
    80004c78:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004c7c:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004c80:	6d85                	lui	s11,0x1
    80004c82:	7d7d                	lui	s10,0xfffff
    80004c84:	ac1d                	j	80004eba <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c86:	00004517          	auipc	a0,0x4
    80004c8a:	a3250513          	addi	a0,a0,-1486 # 800086b8 <syscalls+0x288>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	89c080e7          	jalr	-1892(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c96:	874a                	mv	a4,s2
    80004c98:	009c86bb          	addw	a3,s9,s1
    80004c9c:	4581                	li	a1,0
    80004c9e:	8556                	mv	a0,s5
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	cac080e7          	jalr	-852(ra) # 8000394c <readi>
    80004ca8:	2501                	sext.w	a0,a0
    80004caa:	1aa91863          	bne	s2,a0,80004e5a <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004cae:	009d84bb          	addw	s1,s11,s1
    80004cb2:	013d09bb          	addw	s3,s10,s3
    80004cb6:	1f74f263          	bgeu	s1,s7,80004e9a <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004cba:	02049593          	slli	a1,s1,0x20
    80004cbe:	9181                	srli	a1,a1,0x20
    80004cc0:	95e2                	add	a1,a1,s8
    80004cc2:	855a                	mv	a0,s6
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	388080e7          	jalr	904(ra) # 8000104c <walkaddr>
    80004ccc:	862a                	mv	a2,a0
    if(pa == 0)
    80004cce:	dd45                	beqz	a0,80004c86 <exec+0xfe>
      n = PGSIZE;
    80004cd0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004cd2:	fd49f2e3          	bgeu	s3,s4,80004c96 <exec+0x10e>
      n = sz - i;
    80004cd6:	894e                	mv	s2,s3
    80004cd8:	bf7d                	j	80004c96 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cda:	4481                	li	s1,0
  iunlockput(ip);
    80004cdc:	8556                	mv	a0,s5
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	c1c080e7          	jalr	-996(ra) # 800038fa <iunlockput>
  end_op();
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	404080e7          	jalr	1028(ra) # 800040ea <end_op>
  p = myproc();
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	c90080e7          	jalr	-880(ra) # 8000197e <myproc>
    80004cf6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004cf8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cfc:	6785                	lui	a5,0x1
    80004cfe:	17fd                	addi	a5,a5,-1
    80004d00:	94be                	add	s1,s1,a5
    80004d02:	77fd                	lui	a5,0xfffff
    80004d04:	8fe5                	and	a5,a5,s1
    80004d06:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d0a:	6609                	lui	a2,0x2
    80004d0c:	963e                	add	a2,a2,a5
    80004d0e:	85be                	mv	a1,a5
    80004d10:	855a                	mv	a0,s6
    80004d12:	ffffc097          	auipc	ra,0xffffc
    80004d16:	6dc080e7          	jalr	1756(ra) # 800013ee <uvmalloc>
    80004d1a:	8c2a                	mv	s8,a0
  ip = 0;
    80004d1c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d1e:	12050e63          	beqz	a0,80004e5a <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d22:	75f9                	lui	a1,0xffffe
    80004d24:	95aa                	add	a1,a1,a0
    80004d26:	855a                	mv	a0,s6
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	8e4080e7          	jalr	-1820(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004d30:	7afd                	lui	s5,0xfffff
    80004d32:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d34:	df043783          	ld	a5,-528(s0)
    80004d38:	6388                	ld	a0,0(a5)
    80004d3a:	c925                	beqz	a0,80004daa <exec+0x222>
    80004d3c:	e8840993          	addi	s3,s0,-376
    80004d40:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d44:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d46:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	0fa080e7          	jalr	250(ra) # 80000e42 <strlen>
    80004d50:	0015079b          	addiw	a5,a0,1
    80004d54:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d58:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d5c:	13596363          	bltu	s2,s5,80004e82 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d60:	df043d83          	ld	s11,-528(s0)
    80004d64:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d68:	8552                	mv	a0,s4
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	0d8080e7          	jalr	216(ra) # 80000e42 <strlen>
    80004d72:	0015069b          	addiw	a3,a0,1
    80004d76:	8652                	mv	a2,s4
    80004d78:	85ca                	mv	a1,s2
    80004d7a:	855a                	mv	a0,s6
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	8c2080e7          	jalr	-1854(ra) # 8000163e <copyout>
    80004d84:	10054363          	bltz	a0,80004e8a <exec+0x302>
    ustack[argc] = sp;
    80004d88:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d8c:	0485                	addi	s1,s1,1
    80004d8e:	008d8793          	addi	a5,s11,8
    80004d92:	def43823          	sd	a5,-528(s0)
    80004d96:	008db503          	ld	a0,8(s11)
    80004d9a:	c911                	beqz	a0,80004dae <exec+0x226>
    if(argc >= MAXARG)
    80004d9c:	09a1                	addi	s3,s3,8
    80004d9e:	fb3c95e3          	bne	s9,s3,80004d48 <exec+0x1c0>
  sz = sz1;
    80004da2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004da6:	4a81                	li	s5,0
    80004da8:	a84d                	j	80004e5a <exec+0x2d2>
  sp = sz;
    80004daa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dac:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dae:	00349793          	slli	a5,s1,0x3
    80004db2:	f9040713          	addi	a4,s0,-112
    80004db6:	97ba                	add	a5,a5,a4
    80004db8:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004dbc:	00148693          	addi	a3,s1,1
    80004dc0:	068e                	slli	a3,a3,0x3
    80004dc2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dc6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004dca:	01597663          	bgeu	s2,s5,80004dd6 <exec+0x24e>
  sz = sz1;
    80004dce:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dd2:	4a81                	li	s5,0
    80004dd4:	a059                	j	80004e5a <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dd6:	e8840613          	addi	a2,s0,-376
    80004dda:	85ca                	mv	a1,s2
    80004ddc:	855a                	mv	a0,s6
    80004dde:	ffffd097          	auipc	ra,0xffffd
    80004de2:	860080e7          	jalr	-1952(ra) # 8000163e <copyout>
    80004de6:	0a054663          	bltz	a0,80004e92 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004dea:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004dee:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004df2:	de843783          	ld	a5,-536(s0)
    80004df6:	0007c703          	lbu	a4,0(a5)
    80004dfa:	cf11                	beqz	a4,80004e16 <exec+0x28e>
    80004dfc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dfe:	02f00693          	li	a3,47
    80004e02:	a039                	j	80004e10 <exec+0x288>
      last = s+1;
    80004e04:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e08:	0785                	addi	a5,a5,1
    80004e0a:	fff7c703          	lbu	a4,-1(a5)
    80004e0e:	c701                	beqz	a4,80004e16 <exec+0x28e>
    if(*s == '/')
    80004e10:	fed71ce3          	bne	a4,a3,80004e08 <exec+0x280>
    80004e14:	bfc5                	j	80004e04 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e16:	4641                	li	a2,16
    80004e18:	de843583          	ld	a1,-536(s0)
    80004e1c:	158b8513          	addi	a0,s7,344
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	ff0080e7          	jalr	-16(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e28:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e2c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e30:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e34:	058bb783          	ld	a5,88(s7)
    80004e38:	e6043703          	ld	a4,-416(s0)
    80004e3c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e3e:	058bb783          	ld	a5,88(s7)
    80004e42:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e46:	85ea                	mv	a1,s10
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	c96080e7          	jalr	-874(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e50:	0004851b          	sext.w	a0,s1
    80004e54:	bbc1                	j	80004c24 <exec+0x9c>
    80004e56:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e5a:	df843583          	ld	a1,-520(s0)
    80004e5e:	855a                	mv	a0,s6
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	c7e080e7          	jalr	-898(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80004e68:	da0a94e3          	bnez	s5,80004c10 <exec+0x88>
  return -1;
    80004e6c:	557d                	li	a0,-1
    80004e6e:	bb5d                	j	80004c24 <exec+0x9c>
    80004e70:	de943c23          	sd	s1,-520(s0)
    80004e74:	b7dd                	j	80004e5a <exec+0x2d2>
    80004e76:	de943c23          	sd	s1,-520(s0)
    80004e7a:	b7c5                	j	80004e5a <exec+0x2d2>
    80004e7c:	de943c23          	sd	s1,-520(s0)
    80004e80:	bfe9                	j	80004e5a <exec+0x2d2>
  sz = sz1;
    80004e82:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e86:	4a81                	li	s5,0
    80004e88:	bfc9                	j	80004e5a <exec+0x2d2>
  sz = sz1;
    80004e8a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e8e:	4a81                	li	s5,0
    80004e90:	b7e9                	j	80004e5a <exec+0x2d2>
  sz = sz1;
    80004e92:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e96:	4a81                	li	s5,0
    80004e98:	b7c9                	j	80004e5a <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e9a:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e9e:	e0843783          	ld	a5,-504(s0)
    80004ea2:	0017869b          	addiw	a3,a5,1
    80004ea6:	e0d43423          	sd	a3,-504(s0)
    80004eaa:	e0043783          	ld	a5,-512(s0)
    80004eae:	0387879b          	addiw	a5,a5,56
    80004eb2:	e8045703          	lhu	a4,-384(s0)
    80004eb6:	e2e6d3e3          	bge	a3,a4,80004cdc <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004eba:	2781                	sext.w	a5,a5
    80004ebc:	e0f43023          	sd	a5,-512(s0)
    80004ec0:	03800713          	li	a4,56
    80004ec4:	86be                	mv	a3,a5
    80004ec6:	e1040613          	addi	a2,s0,-496
    80004eca:	4581                	li	a1,0
    80004ecc:	8556                	mv	a0,s5
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	a7e080e7          	jalr	-1410(ra) # 8000394c <readi>
    80004ed6:	03800793          	li	a5,56
    80004eda:	f6f51ee3          	bne	a0,a5,80004e56 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004ede:	e1042783          	lw	a5,-496(s0)
    80004ee2:	4705                	li	a4,1
    80004ee4:	fae79de3          	bne	a5,a4,80004e9e <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004ee8:	e3843603          	ld	a2,-456(s0)
    80004eec:	e3043783          	ld	a5,-464(s0)
    80004ef0:	f8f660e3          	bltu	a2,a5,80004e70 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ef4:	e2043783          	ld	a5,-480(s0)
    80004ef8:	963e                	add	a2,a2,a5
    80004efa:	f6f66ee3          	bltu	a2,a5,80004e76 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004efe:	85a6                	mv	a1,s1
    80004f00:	855a                	mv	a0,s6
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	4ec080e7          	jalr	1260(ra) # 800013ee <uvmalloc>
    80004f0a:	dea43c23          	sd	a0,-520(s0)
    80004f0e:	d53d                	beqz	a0,80004e7c <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f10:	e2043c03          	ld	s8,-480(s0)
    80004f14:	de043783          	ld	a5,-544(s0)
    80004f18:	00fc77b3          	and	a5,s8,a5
    80004f1c:	ff9d                	bnez	a5,80004e5a <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f1e:	e1842c83          	lw	s9,-488(s0)
    80004f22:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f26:	f60b8ae3          	beqz	s7,80004e9a <exec+0x312>
    80004f2a:	89de                	mv	s3,s7
    80004f2c:	4481                	li	s1,0
    80004f2e:	b371                	j	80004cba <exec+0x132>

0000000080004f30 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f30:	7179                	addi	sp,sp,-48
    80004f32:	f406                	sd	ra,40(sp)
    80004f34:	f022                	sd	s0,32(sp)
    80004f36:	ec26                	sd	s1,24(sp)
    80004f38:	e84a                	sd	s2,16(sp)
    80004f3a:	1800                	addi	s0,sp,48
    80004f3c:	892e                	mv	s2,a1
    80004f3e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f40:	fdc40593          	addi	a1,s0,-36
    80004f44:	ffffe097          	auipc	ra,0xffffe
    80004f48:	b68080e7          	jalr	-1176(ra) # 80002aac <argint>
    80004f4c:	04054063          	bltz	a0,80004f8c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f50:	fdc42703          	lw	a4,-36(s0)
    80004f54:	47bd                	li	a5,15
    80004f56:	02e7ed63          	bltu	a5,a4,80004f90 <argfd+0x60>
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	a24080e7          	jalr	-1500(ra) # 8000197e <myproc>
    80004f62:	fdc42703          	lw	a4,-36(s0)
    80004f66:	01a70793          	addi	a5,a4,26
    80004f6a:	078e                	slli	a5,a5,0x3
    80004f6c:	953e                	add	a0,a0,a5
    80004f6e:	611c                	ld	a5,0(a0)
    80004f70:	c395                	beqz	a5,80004f94 <argfd+0x64>
    return -1;
  if(pfd)
    80004f72:	00090463          	beqz	s2,80004f7a <argfd+0x4a>
    *pfd = fd;
    80004f76:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f7a:	4501                	li	a0,0
  if(pf)
    80004f7c:	c091                	beqz	s1,80004f80 <argfd+0x50>
    *pf = f;
    80004f7e:	e09c                	sd	a5,0(s1)
}
    80004f80:	70a2                	ld	ra,40(sp)
    80004f82:	7402                	ld	s0,32(sp)
    80004f84:	64e2                	ld	s1,24(sp)
    80004f86:	6942                	ld	s2,16(sp)
    80004f88:	6145                	addi	sp,sp,48
    80004f8a:	8082                	ret
    return -1;
    80004f8c:	557d                	li	a0,-1
    80004f8e:	bfcd                	j	80004f80 <argfd+0x50>
    return -1;
    80004f90:	557d                	li	a0,-1
    80004f92:	b7fd                	j	80004f80 <argfd+0x50>
    80004f94:	557d                	li	a0,-1
    80004f96:	b7ed                	j	80004f80 <argfd+0x50>

0000000080004f98 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f98:	1101                	addi	sp,sp,-32
    80004f9a:	ec06                	sd	ra,24(sp)
    80004f9c:	e822                	sd	s0,16(sp)
    80004f9e:	e426                	sd	s1,8(sp)
    80004fa0:	1000                	addi	s0,sp,32
    80004fa2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fa4:	ffffd097          	auipc	ra,0xffffd
    80004fa8:	9da080e7          	jalr	-1574(ra) # 8000197e <myproc>
    80004fac:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fae:	0d050793          	addi	a5,a0,208
    80004fb2:	4501                	li	a0,0
    80004fb4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fb6:	6398                	ld	a4,0(a5)
    80004fb8:	cb19                	beqz	a4,80004fce <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fba:	2505                	addiw	a0,a0,1
    80004fbc:	07a1                	addi	a5,a5,8
    80004fbe:	fed51ce3          	bne	a0,a3,80004fb6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fc2:	557d                	li	a0,-1
}
    80004fc4:	60e2                	ld	ra,24(sp)
    80004fc6:	6442                	ld	s0,16(sp)
    80004fc8:	64a2                	ld	s1,8(sp)
    80004fca:	6105                	addi	sp,sp,32
    80004fcc:	8082                	ret
      p->ofile[fd] = f;
    80004fce:	01a50793          	addi	a5,a0,26
    80004fd2:	078e                	slli	a5,a5,0x3
    80004fd4:	963e                	add	a2,a2,a5
    80004fd6:	e204                	sd	s1,0(a2)
      return fd;
    80004fd8:	b7f5                	j	80004fc4 <fdalloc+0x2c>

0000000080004fda <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fda:	715d                	addi	sp,sp,-80
    80004fdc:	e486                	sd	ra,72(sp)
    80004fde:	e0a2                	sd	s0,64(sp)
    80004fe0:	fc26                	sd	s1,56(sp)
    80004fe2:	f84a                	sd	s2,48(sp)
    80004fe4:	f44e                	sd	s3,40(sp)
    80004fe6:	f052                	sd	s4,32(sp)
    80004fe8:	ec56                	sd	s5,24(sp)
    80004fea:	0880                	addi	s0,sp,80
    80004fec:	89ae                	mv	s3,a1
    80004fee:	8ab2                	mv	s5,a2
    80004ff0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004ff2:	fb040593          	addi	a1,s0,-80
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	e76080e7          	jalr	-394(ra) # 80003e6c <nameiparent>
    80004ffe:	892a                	mv	s2,a0
    80005000:	12050e63          	beqz	a0,8000513c <create+0x162>
    return 0;

  ilock(dp);
    80005004:	ffffe097          	auipc	ra,0xffffe
    80005008:	694080e7          	jalr	1684(ra) # 80003698 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000500c:	4601                	li	a2,0
    8000500e:	fb040593          	addi	a1,s0,-80
    80005012:	854a                	mv	a0,s2
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	b68080e7          	jalr	-1176(ra) # 80003b7c <dirlookup>
    8000501c:	84aa                	mv	s1,a0
    8000501e:	c921                	beqz	a0,8000506e <create+0x94>
    iunlockput(dp);
    80005020:	854a                	mv	a0,s2
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	8d8080e7          	jalr	-1832(ra) # 800038fa <iunlockput>
    ilock(ip);
    8000502a:	8526                	mv	a0,s1
    8000502c:	ffffe097          	auipc	ra,0xffffe
    80005030:	66c080e7          	jalr	1644(ra) # 80003698 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005034:	2981                	sext.w	s3,s3
    80005036:	4789                	li	a5,2
    80005038:	02f99463          	bne	s3,a5,80005060 <create+0x86>
    8000503c:	0444d783          	lhu	a5,68(s1)
    80005040:	37f9                	addiw	a5,a5,-2
    80005042:	17c2                	slli	a5,a5,0x30
    80005044:	93c1                	srli	a5,a5,0x30
    80005046:	4705                	li	a4,1
    80005048:	00f76c63          	bltu	a4,a5,80005060 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000504c:	8526                	mv	a0,s1
    8000504e:	60a6                	ld	ra,72(sp)
    80005050:	6406                	ld	s0,64(sp)
    80005052:	74e2                	ld	s1,56(sp)
    80005054:	7942                	ld	s2,48(sp)
    80005056:	79a2                	ld	s3,40(sp)
    80005058:	7a02                	ld	s4,32(sp)
    8000505a:	6ae2                	ld	s5,24(sp)
    8000505c:	6161                	addi	sp,sp,80
    8000505e:	8082                	ret
    iunlockput(ip);
    80005060:	8526                	mv	a0,s1
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	898080e7          	jalr	-1896(ra) # 800038fa <iunlockput>
    return 0;
    8000506a:	4481                	li	s1,0
    8000506c:	b7c5                	j	8000504c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000506e:	85ce                	mv	a1,s3
    80005070:	00092503          	lw	a0,0(s2)
    80005074:	ffffe097          	auipc	ra,0xffffe
    80005078:	48c080e7          	jalr	1164(ra) # 80003500 <ialloc>
    8000507c:	84aa                	mv	s1,a0
    8000507e:	c521                	beqz	a0,800050c6 <create+0xec>
  ilock(ip);
    80005080:	ffffe097          	auipc	ra,0xffffe
    80005084:	618080e7          	jalr	1560(ra) # 80003698 <ilock>
  ip->major = major;
    80005088:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000508c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005090:	4a05                	li	s4,1
    80005092:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	536080e7          	jalr	1334(ra) # 800035ce <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050a0:	2981                	sext.w	s3,s3
    800050a2:	03498a63          	beq	s3,s4,800050d6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800050a6:	40d0                	lw	a2,4(s1)
    800050a8:	fb040593          	addi	a1,s0,-80
    800050ac:	854a                	mv	a0,s2
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	cde080e7          	jalr	-802(ra) # 80003d8c <dirlink>
    800050b6:	06054b63          	bltz	a0,8000512c <create+0x152>
  iunlockput(dp);
    800050ba:	854a                	mv	a0,s2
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	83e080e7          	jalr	-1986(ra) # 800038fa <iunlockput>
  return ip;
    800050c4:	b761                	j	8000504c <create+0x72>
    panic("create: ialloc");
    800050c6:	00003517          	auipc	a0,0x3
    800050ca:	61250513          	addi	a0,a0,1554 # 800086d8 <syscalls+0x2a8>
    800050ce:	ffffb097          	auipc	ra,0xffffb
    800050d2:	45c080e7          	jalr	1116(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800050d6:	04a95783          	lhu	a5,74(s2)
    800050da:	2785                	addiw	a5,a5,1
    800050dc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800050e0:	854a                	mv	a0,s2
    800050e2:	ffffe097          	auipc	ra,0xffffe
    800050e6:	4ec080e7          	jalr	1260(ra) # 800035ce <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050ea:	40d0                	lw	a2,4(s1)
    800050ec:	00003597          	auipc	a1,0x3
    800050f0:	5fc58593          	addi	a1,a1,1532 # 800086e8 <syscalls+0x2b8>
    800050f4:	8526                	mv	a0,s1
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	c96080e7          	jalr	-874(ra) # 80003d8c <dirlink>
    800050fe:	00054f63          	bltz	a0,8000511c <create+0x142>
    80005102:	00492603          	lw	a2,4(s2)
    80005106:	00003597          	auipc	a1,0x3
    8000510a:	5ea58593          	addi	a1,a1,1514 # 800086f0 <syscalls+0x2c0>
    8000510e:	8526                	mv	a0,s1
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	c7c080e7          	jalr	-900(ra) # 80003d8c <dirlink>
    80005118:	f80557e3          	bgez	a0,800050a6 <create+0xcc>
      panic("create dots");
    8000511c:	00003517          	auipc	a0,0x3
    80005120:	5dc50513          	addi	a0,a0,1500 # 800086f8 <syscalls+0x2c8>
    80005124:	ffffb097          	auipc	ra,0xffffb
    80005128:	406080e7          	jalr	1030(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000512c:	00003517          	auipc	a0,0x3
    80005130:	5dc50513          	addi	a0,a0,1500 # 80008708 <syscalls+0x2d8>
    80005134:	ffffb097          	auipc	ra,0xffffb
    80005138:	3f6080e7          	jalr	1014(ra) # 8000052a <panic>
    return 0;
    8000513c:	84aa                	mv	s1,a0
    8000513e:	b739                	j	8000504c <create+0x72>

0000000080005140 <sys_dup>:
{
    80005140:	7179                	addi	sp,sp,-48
    80005142:	f406                	sd	ra,40(sp)
    80005144:	f022                	sd	s0,32(sp)
    80005146:	ec26                	sd	s1,24(sp)
    80005148:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000514a:	fd840613          	addi	a2,s0,-40
    8000514e:	4581                	li	a1,0
    80005150:	4501                	li	a0,0
    80005152:	00000097          	auipc	ra,0x0
    80005156:	dde080e7          	jalr	-546(ra) # 80004f30 <argfd>
    return -1;
    8000515a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000515c:	02054363          	bltz	a0,80005182 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005160:	fd843503          	ld	a0,-40(s0)
    80005164:	00000097          	auipc	ra,0x0
    80005168:	e34080e7          	jalr	-460(ra) # 80004f98 <fdalloc>
    8000516c:	84aa                	mv	s1,a0
    return -1;
    8000516e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005170:	00054963          	bltz	a0,80005182 <sys_dup+0x42>
  filedup(f);
    80005174:	fd843503          	ld	a0,-40(s0)
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	36c080e7          	jalr	876(ra) # 800044e4 <filedup>
  return fd;
    80005180:	87a6                	mv	a5,s1
}
    80005182:	853e                	mv	a0,a5
    80005184:	70a2                	ld	ra,40(sp)
    80005186:	7402                	ld	s0,32(sp)
    80005188:	64e2                	ld	s1,24(sp)
    8000518a:	6145                	addi	sp,sp,48
    8000518c:	8082                	ret

000000008000518e <sys_read>:
{
    8000518e:	7179                	addi	sp,sp,-48
    80005190:	f406                	sd	ra,40(sp)
    80005192:	f022                	sd	s0,32(sp)
    80005194:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005196:	fe840613          	addi	a2,s0,-24
    8000519a:	4581                	li	a1,0
    8000519c:	4501                	li	a0,0
    8000519e:	00000097          	auipc	ra,0x0
    800051a2:	d92080e7          	jalr	-622(ra) # 80004f30 <argfd>
    return -1;
    800051a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a8:	04054163          	bltz	a0,800051ea <sys_read+0x5c>
    800051ac:	fe440593          	addi	a1,s0,-28
    800051b0:	4509                	li	a0,2
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	8fa080e7          	jalr	-1798(ra) # 80002aac <argint>
    return -1;
    800051ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051bc:	02054763          	bltz	a0,800051ea <sys_read+0x5c>
    800051c0:	fd840593          	addi	a1,s0,-40
    800051c4:	4505                	li	a0,1
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	908080e7          	jalr	-1784(ra) # 80002ace <argaddr>
    return -1;
    800051ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d0:	00054d63          	bltz	a0,800051ea <sys_read+0x5c>
  return fileread(f, p, n);
    800051d4:	fe442603          	lw	a2,-28(s0)
    800051d8:	fd843583          	ld	a1,-40(s0)
    800051dc:	fe843503          	ld	a0,-24(s0)
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	490080e7          	jalr	1168(ra) # 80004670 <fileread>
    800051e8:	87aa                	mv	a5,a0
}
    800051ea:	853e                	mv	a0,a5
    800051ec:	70a2                	ld	ra,40(sp)
    800051ee:	7402                	ld	s0,32(sp)
    800051f0:	6145                	addi	sp,sp,48
    800051f2:	8082                	ret

00000000800051f4 <sys_write>:
{
    800051f4:	7179                	addi	sp,sp,-48
    800051f6:	f406                	sd	ra,40(sp)
    800051f8:	f022                	sd	s0,32(sp)
    800051fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fc:	fe840613          	addi	a2,s0,-24
    80005200:	4581                	li	a1,0
    80005202:	4501                	li	a0,0
    80005204:	00000097          	auipc	ra,0x0
    80005208:	d2c080e7          	jalr	-724(ra) # 80004f30 <argfd>
    return -1;
    8000520c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000520e:	04054163          	bltz	a0,80005250 <sys_write+0x5c>
    80005212:	fe440593          	addi	a1,s0,-28
    80005216:	4509                	li	a0,2
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	894080e7          	jalr	-1900(ra) # 80002aac <argint>
    return -1;
    80005220:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005222:	02054763          	bltz	a0,80005250 <sys_write+0x5c>
    80005226:	fd840593          	addi	a1,s0,-40
    8000522a:	4505                	li	a0,1
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	8a2080e7          	jalr	-1886(ra) # 80002ace <argaddr>
    return -1;
    80005234:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005236:	00054d63          	bltz	a0,80005250 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000523a:	fe442603          	lw	a2,-28(s0)
    8000523e:	fd843583          	ld	a1,-40(s0)
    80005242:	fe843503          	ld	a0,-24(s0)
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	4ec080e7          	jalr	1260(ra) # 80004732 <filewrite>
    8000524e:	87aa                	mv	a5,a0
}
    80005250:	853e                	mv	a0,a5
    80005252:	70a2                	ld	ra,40(sp)
    80005254:	7402                	ld	s0,32(sp)
    80005256:	6145                	addi	sp,sp,48
    80005258:	8082                	ret

000000008000525a <sys_close>:
{
    8000525a:	1101                	addi	sp,sp,-32
    8000525c:	ec06                	sd	ra,24(sp)
    8000525e:	e822                	sd	s0,16(sp)
    80005260:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005262:	fe040613          	addi	a2,s0,-32
    80005266:	fec40593          	addi	a1,s0,-20
    8000526a:	4501                	li	a0,0
    8000526c:	00000097          	auipc	ra,0x0
    80005270:	cc4080e7          	jalr	-828(ra) # 80004f30 <argfd>
    return -1;
    80005274:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005276:	02054463          	bltz	a0,8000529e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	704080e7          	jalr	1796(ra) # 8000197e <myproc>
    80005282:	fec42783          	lw	a5,-20(s0)
    80005286:	07e9                	addi	a5,a5,26
    80005288:	078e                	slli	a5,a5,0x3
    8000528a:	97aa                	add	a5,a5,a0
    8000528c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005290:	fe043503          	ld	a0,-32(s0)
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	2a2080e7          	jalr	674(ra) # 80004536 <fileclose>
  return 0;
    8000529c:	4781                	li	a5,0
}
    8000529e:	853e                	mv	a0,a5
    800052a0:	60e2                	ld	ra,24(sp)
    800052a2:	6442                	ld	s0,16(sp)
    800052a4:	6105                	addi	sp,sp,32
    800052a6:	8082                	ret

00000000800052a8 <sys_fstat>:
{
    800052a8:	1101                	addi	sp,sp,-32
    800052aa:	ec06                	sd	ra,24(sp)
    800052ac:	e822                	sd	s0,16(sp)
    800052ae:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052b0:	fe840613          	addi	a2,s0,-24
    800052b4:	4581                	li	a1,0
    800052b6:	4501                	li	a0,0
    800052b8:	00000097          	auipc	ra,0x0
    800052bc:	c78080e7          	jalr	-904(ra) # 80004f30 <argfd>
    return -1;
    800052c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052c2:	02054563          	bltz	a0,800052ec <sys_fstat+0x44>
    800052c6:	fe040593          	addi	a1,s0,-32
    800052ca:	4505                	li	a0,1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	802080e7          	jalr	-2046(ra) # 80002ace <argaddr>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052d6:	00054b63          	bltz	a0,800052ec <sys_fstat+0x44>
  return filestat(f, st);
    800052da:	fe043583          	ld	a1,-32(s0)
    800052de:	fe843503          	ld	a0,-24(s0)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	31c080e7          	jalr	796(ra) # 800045fe <filestat>
    800052ea:	87aa                	mv	a5,a0
}
    800052ec:	853e                	mv	a0,a5
    800052ee:	60e2                	ld	ra,24(sp)
    800052f0:	6442                	ld	s0,16(sp)
    800052f2:	6105                	addi	sp,sp,32
    800052f4:	8082                	ret

00000000800052f6 <sys_link>:
{
    800052f6:	7169                	addi	sp,sp,-304
    800052f8:	f606                	sd	ra,296(sp)
    800052fa:	f222                	sd	s0,288(sp)
    800052fc:	ee26                	sd	s1,280(sp)
    800052fe:	ea4a                	sd	s2,272(sp)
    80005300:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005302:	08000613          	li	a2,128
    80005306:	ed040593          	addi	a1,s0,-304
    8000530a:	4501                	li	a0,0
    8000530c:	ffffd097          	auipc	ra,0xffffd
    80005310:	7e4080e7          	jalr	2020(ra) # 80002af0 <argstr>
    return -1;
    80005314:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005316:	10054e63          	bltz	a0,80005432 <sys_link+0x13c>
    8000531a:	08000613          	li	a2,128
    8000531e:	f5040593          	addi	a1,s0,-176
    80005322:	4505                	li	a0,1
    80005324:	ffffd097          	auipc	ra,0xffffd
    80005328:	7cc080e7          	jalr	1996(ra) # 80002af0 <argstr>
    return -1;
    8000532c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000532e:	10054263          	bltz	a0,80005432 <sys_link+0x13c>
  begin_op();
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	d38080e7          	jalr	-712(ra) # 8000406a <begin_op>
  if((ip = namei(old)) == 0){
    8000533a:	ed040513          	addi	a0,s0,-304
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	b10080e7          	jalr	-1264(ra) # 80003e4e <namei>
    80005346:	84aa                	mv	s1,a0
    80005348:	c551                	beqz	a0,800053d4 <sys_link+0xde>
  ilock(ip);
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	34e080e7          	jalr	846(ra) # 80003698 <ilock>
  if(ip->type == T_DIR){
    80005352:	04449703          	lh	a4,68(s1)
    80005356:	4785                	li	a5,1
    80005358:	08f70463          	beq	a4,a5,800053e0 <sys_link+0xea>
  ip->nlink++;
    8000535c:	04a4d783          	lhu	a5,74(s1)
    80005360:	2785                	addiw	a5,a5,1
    80005362:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005366:	8526                	mv	a0,s1
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	266080e7          	jalr	614(ra) # 800035ce <iupdate>
  iunlock(ip);
    80005370:	8526                	mv	a0,s1
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	3e8080e7          	jalr	1000(ra) # 8000375a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000537a:	fd040593          	addi	a1,s0,-48
    8000537e:	f5040513          	addi	a0,s0,-176
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	aea080e7          	jalr	-1302(ra) # 80003e6c <nameiparent>
    8000538a:	892a                	mv	s2,a0
    8000538c:	c935                	beqz	a0,80005400 <sys_link+0x10a>
  ilock(dp);
    8000538e:	ffffe097          	auipc	ra,0xffffe
    80005392:	30a080e7          	jalr	778(ra) # 80003698 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005396:	00092703          	lw	a4,0(s2)
    8000539a:	409c                	lw	a5,0(s1)
    8000539c:	04f71d63          	bne	a4,a5,800053f6 <sys_link+0x100>
    800053a0:	40d0                	lw	a2,4(s1)
    800053a2:	fd040593          	addi	a1,s0,-48
    800053a6:	854a                	mv	a0,s2
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	9e4080e7          	jalr	-1564(ra) # 80003d8c <dirlink>
    800053b0:	04054363          	bltz	a0,800053f6 <sys_link+0x100>
  iunlockput(dp);
    800053b4:	854a                	mv	a0,s2
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	544080e7          	jalr	1348(ra) # 800038fa <iunlockput>
  iput(ip);
    800053be:	8526                	mv	a0,s1
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	492080e7          	jalr	1170(ra) # 80003852 <iput>
  end_op();
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	d22080e7          	jalr	-734(ra) # 800040ea <end_op>
  return 0;
    800053d0:	4781                	li	a5,0
    800053d2:	a085                	j	80005432 <sys_link+0x13c>
    end_op();
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	d16080e7          	jalr	-746(ra) # 800040ea <end_op>
    return -1;
    800053dc:	57fd                	li	a5,-1
    800053de:	a891                	j	80005432 <sys_link+0x13c>
    iunlockput(ip);
    800053e0:	8526                	mv	a0,s1
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	518080e7          	jalr	1304(ra) # 800038fa <iunlockput>
    end_op();
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	d00080e7          	jalr	-768(ra) # 800040ea <end_op>
    return -1;
    800053f2:	57fd                	li	a5,-1
    800053f4:	a83d                	j	80005432 <sys_link+0x13c>
    iunlockput(dp);
    800053f6:	854a                	mv	a0,s2
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	502080e7          	jalr	1282(ra) # 800038fa <iunlockput>
  ilock(ip);
    80005400:	8526                	mv	a0,s1
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	296080e7          	jalr	662(ra) # 80003698 <ilock>
  ip->nlink--;
    8000540a:	04a4d783          	lhu	a5,74(s1)
    8000540e:	37fd                	addiw	a5,a5,-1
    80005410:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005414:	8526                	mv	a0,s1
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	1b8080e7          	jalr	440(ra) # 800035ce <iupdate>
  iunlockput(ip);
    8000541e:	8526                	mv	a0,s1
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	4da080e7          	jalr	1242(ra) # 800038fa <iunlockput>
  end_op();
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	cc2080e7          	jalr	-830(ra) # 800040ea <end_op>
  return -1;
    80005430:	57fd                	li	a5,-1
}
    80005432:	853e                	mv	a0,a5
    80005434:	70b2                	ld	ra,296(sp)
    80005436:	7412                	ld	s0,288(sp)
    80005438:	64f2                	ld	s1,280(sp)
    8000543a:	6952                	ld	s2,272(sp)
    8000543c:	6155                	addi	sp,sp,304
    8000543e:	8082                	ret

0000000080005440 <sys_unlink>:
{
    80005440:	7151                	addi	sp,sp,-240
    80005442:	f586                	sd	ra,232(sp)
    80005444:	f1a2                	sd	s0,224(sp)
    80005446:	eda6                	sd	s1,216(sp)
    80005448:	e9ca                	sd	s2,208(sp)
    8000544a:	e5ce                	sd	s3,200(sp)
    8000544c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000544e:	08000613          	li	a2,128
    80005452:	f3040593          	addi	a1,s0,-208
    80005456:	4501                	li	a0,0
    80005458:	ffffd097          	auipc	ra,0xffffd
    8000545c:	698080e7          	jalr	1688(ra) # 80002af0 <argstr>
    80005460:	18054163          	bltz	a0,800055e2 <sys_unlink+0x1a2>
  begin_op();
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	c06080e7          	jalr	-1018(ra) # 8000406a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000546c:	fb040593          	addi	a1,s0,-80
    80005470:	f3040513          	addi	a0,s0,-208
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	9f8080e7          	jalr	-1544(ra) # 80003e6c <nameiparent>
    8000547c:	84aa                	mv	s1,a0
    8000547e:	c979                	beqz	a0,80005554 <sys_unlink+0x114>
  ilock(dp);
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	218080e7          	jalr	536(ra) # 80003698 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005488:	00003597          	auipc	a1,0x3
    8000548c:	26058593          	addi	a1,a1,608 # 800086e8 <syscalls+0x2b8>
    80005490:	fb040513          	addi	a0,s0,-80
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	6ce080e7          	jalr	1742(ra) # 80003b62 <namecmp>
    8000549c:	14050a63          	beqz	a0,800055f0 <sys_unlink+0x1b0>
    800054a0:	00003597          	auipc	a1,0x3
    800054a4:	25058593          	addi	a1,a1,592 # 800086f0 <syscalls+0x2c0>
    800054a8:	fb040513          	addi	a0,s0,-80
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	6b6080e7          	jalr	1718(ra) # 80003b62 <namecmp>
    800054b4:	12050e63          	beqz	a0,800055f0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054b8:	f2c40613          	addi	a2,s0,-212
    800054bc:	fb040593          	addi	a1,s0,-80
    800054c0:	8526                	mv	a0,s1
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	6ba080e7          	jalr	1722(ra) # 80003b7c <dirlookup>
    800054ca:	892a                	mv	s2,a0
    800054cc:	12050263          	beqz	a0,800055f0 <sys_unlink+0x1b0>
  ilock(ip);
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	1c8080e7          	jalr	456(ra) # 80003698 <ilock>
  if(ip->nlink < 1)
    800054d8:	04a91783          	lh	a5,74(s2)
    800054dc:	08f05263          	blez	a5,80005560 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054e0:	04491703          	lh	a4,68(s2)
    800054e4:	4785                	li	a5,1
    800054e6:	08f70563          	beq	a4,a5,80005570 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054ea:	4641                	li	a2,16
    800054ec:	4581                	li	a1,0
    800054ee:	fc040513          	addi	a0,s0,-64
    800054f2:	ffffb097          	auipc	ra,0xffffb
    800054f6:	7cc080e7          	jalr	1996(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054fa:	4741                	li	a4,16
    800054fc:	f2c42683          	lw	a3,-212(s0)
    80005500:	fc040613          	addi	a2,s0,-64
    80005504:	4581                	li	a1,0
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	53c080e7          	jalr	1340(ra) # 80003a44 <writei>
    80005510:	47c1                	li	a5,16
    80005512:	0af51563          	bne	a0,a5,800055bc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005516:	04491703          	lh	a4,68(s2)
    8000551a:	4785                	li	a5,1
    8000551c:	0af70863          	beq	a4,a5,800055cc <sys_unlink+0x18c>
  iunlockput(dp);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	3d8080e7          	jalr	984(ra) # 800038fa <iunlockput>
  ip->nlink--;
    8000552a:	04a95783          	lhu	a5,74(s2)
    8000552e:	37fd                	addiw	a5,a5,-1
    80005530:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005534:	854a                	mv	a0,s2
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	098080e7          	jalr	152(ra) # 800035ce <iupdate>
  iunlockput(ip);
    8000553e:	854a                	mv	a0,s2
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	3ba080e7          	jalr	954(ra) # 800038fa <iunlockput>
  end_op();
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	ba2080e7          	jalr	-1118(ra) # 800040ea <end_op>
  return 0;
    80005550:	4501                	li	a0,0
    80005552:	a84d                	j	80005604 <sys_unlink+0x1c4>
    end_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	b96080e7          	jalr	-1130(ra) # 800040ea <end_op>
    return -1;
    8000555c:	557d                	li	a0,-1
    8000555e:	a05d                	j	80005604 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005560:	00003517          	auipc	a0,0x3
    80005564:	1b850513          	addi	a0,a0,440 # 80008718 <syscalls+0x2e8>
    80005568:	ffffb097          	auipc	ra,0xffffb
    8000556c:	fc2080e7          	jalr	-62(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005570:	04c92703          	lw	a4,76(s2)
    80005574:	02000793          	li	a5,32
    80005578:	f6e7f9e3          	bgeu	a5,a4,800054ea <sys_unlink+0xaa>
    8000557c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005580:	4741                	li	a4,16
    80005582:	86ce                	mv	a3,s3
    80005584:	f1840613          	addi	a2,s0,-232
    80005588:	4581                	li	a1,0
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	3c0080e7          	jalr	960(ra) # 8000394c <readi>
    80005594:	47c1                	li	a5,16
    80005596:	00f51b63          	bne	a0,a5,800055ac <sys_unlink+0x16c>
    if(de.inum != 0)
    8000559a:	f1845783          	lhu	a5,-232(s0)
    8000559e:	e7a1                	bnez	a5,800055e6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055a0:	29c1                	addiw	s3,s3,16
    800055a2:	04c92783          	lw	a5,76(s2)
    800055a6:	fcf9ede3          	bltu	s3,a5,80005580 <sys_unlink+0x140>
    800055aa:	b781                	j	800054ea <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055ac:	00003517          	auipc	a0,0x3
    800055b0:	18450513          	addi	a0,a0,388 # 80008730 <syscalls+0x300>
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	f76080e7          	jalr	-138(ra) # 8000052a <panic>
    panic("unlink: writei");
    800055bc:	00003517          	auipc	a0,0x3
    800055c0:	18c50513          	addi	a0,a0,396 # 80008748 <syscalls+0x318>
    800055c4:	ffffb097          	auipc	ra,0xffffb
    800055c8:	f66080e7          	jalr	-154(ra) # 8000052a <panic>
    dp->nlink--;
    800055cc:	04a4d783          	lhu	a5,74(s1)
    800055d0:	37fd                	addiw	a5,a5,-1
    800055d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	ff6080e7          	jalr	-10(ra) # 800035ce <iupdate>
    800055e0:	b781                	j	80005520 <sys_unlink+0xe0>
    return -1;
    800055e2:	557d                	li	a0,-1
    800055e4:	a005                	j	80005604 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055e6:	854a                	mv	a0,s2
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	312080e7          	jalr	786(ra) # 800038fa <iunlockput>
  iunlockput(dp);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	308080e7          	jalr	776(ra) # 800038fa <iunlockput>
  end_op();
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	af0080e7          	jalr	-1296(ra) # 800040ea <end_op>
  return -1;
    80005602:	557d                	li	a0,-1
}
    80005604:	70ae                	ld	ra,232(sp)
    80005606:	740e                	ld	s0,224(sp)
    80005608:	64ee                	ld	s1,216(sp)
    8000560a:	694e                	ld	s2,208(sp)
    8000560c:	69ae                	ld	s3,200(sp)
    8000560e:	616d                	addi	sp,sp,240
    80005610:	8082                	ret

0000000080005612 <sys_open>:

uint64
sys_open(void)
{
    80005612:	7131                	addi	sp,sp,-192
    80005614:	fd06                	sd	ra,184(sp)
    80005616:	f922                	sd	s0,176(sp)
    80005618:	f526                	sd	s1,168(sp)
    8000561a:	f14a                	sd	s2,160(sp)
    8000561c:	ed4e                	sd	s3,152(sp)
    8000561e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005620:	08000613          	li	a2,128
    80005624:	f5040593          	addi	a1,s0,-176
    80005628:	4501                	li	a0,0
    8000562a:	ffffd097          	auipc	ra,0xffffd
    8000562e:	4c6080e7          	jalr	1222(ra) # 80002af0 <argstr>
    return -1;
    80005632:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005634:	0c054163          	bltz	a0,800056f6 <sys_open+0xe4>
    80005638:	f4c40593          	addi	a1,s0,-180
    8000563c:	4505                	li	a0,1
    8000563e:	ffffd097          	auipc	ra,0xffffd
    80005642:	46e080e7          	jalr	1134(ra) # 80002aac <argint>
    80005646:	0a054863          	bltz	a0,800056f6 <sys_open+0xe4>

  begin_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	a20080e7          	jalr	-1504(ra) # 8000406a <begin_op>

  if(omode & O_CREATE){
    80005652:	f4c42783          	lw	a5,-180(s0)
    80005656:	2007f793          	andi	a5,a5,512
    8000565a:	cbdd                	beqz	a5,80005710 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000565c:	4681                	li	a3,0
    8000565e:	4601                	li	a2,0
    80005660:	4589                	li	a1,2
    80005662:	f5040513          	addi	a0,s0,-176
    80005666:	00000097          	auipc	ra,0x0
    8000566a:	974080e7          	jalr	-1676(ra) # 80004fda <create>
    8000566e:	892a                	mv	s2,a0
    if(ip == 0){
    80005670:	c959                	beqz	a0,80005706 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005672:	04491703          	lh	a4,68(s2)
    80005676:	478d                	li	a5,3
    80005678:	00f71763          	bne	a4,a5,80005686 <sys_open+0x74>
    8000567c:	04695703          	lhu	a4,70(s2)
    80005680:	47a5                	li	a5,9
    80005682:	0ce7ec63          	bltu	a5,a4,8000575a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	df4080e7          	jalr	-524(ra) # 8000447a <filealloc>
    8000568e:	89aa                	mv	s3,a0
    80005690:	10050263          	beqz	a0,80005794 <sys_open+0x182>
    80005694:	00000097          	auipc	ra,0x0
    80005698:	904080e7          	jalr	-1788(ra) # 80004f98 <fdalloc>
    8000569c:	84aa                	mv	s1,a0
    8000569e:	0e054663          	bltz	a0,8000578a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056a2:	04491703          	lh	a4,68(s2)
    800056a6:	478d                	li	a5,3
    800056a8:	0cf70463          	beq	a4,a5,80005770 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056ac:	4789                	li	a5,2
    800056ae:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056b2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056b6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056ba:	f4c42783          	lw	a5,-180(s0)
    800056be:	0017c713          	xori	a4,a5,1
    800056c2:	8b05                	andi	a4,a4,1
    800056c4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056c8:	0037f713          	andi	a4,a5,3
    800056cc:	00e03733          	snez	a4,a4
    800056d0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056d4:	4007f793          	andi	a5,a5,1024
    800056d8:	c791                	beqz	a5,800056e4 <sys_open+0xd2>
    800056da:	04491703          	lh	a4,68(s2)
    800056de:	4789                	li	a5,2
    800056e0:	08f70f63          	beq	a4,a5,8000577e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056e4:	854a                	mv	a0,s2
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	074080e7          	jalr	116(ra) # 8000375a <iunlock>
  end_op();
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	9fc080e7          	jalr	-1540(ra) # 800040ea <end_op>

  return fd;
}
    800056f6:	8526                	mv	a0,s1
    800056f8:	70ea                	ld	ra,184(sp)
    800056fa:	744a                	ld	s0,176(sp)
    800056fc:	74aa                	ld	s1,168(sp)
    800056fe:	790a                	ld	s2,160(sp)
    80005700:	69ea                	ld	s3,152(sp)
    80005702:	6129                	addi	sp,sp,192
    80005704:	8082                	ret
      end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	9e4080e7          	jalr	-1564(ra) # 800040ea <end_op>
      return -1;
    8000570e:	b7e5                	j	800056f6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005710:	f5040513          	addi	a0,s0,-176
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	73a080e7          	jalr	1850(ra) # 80003e4e <namei>
    8000571c:	892a                	mv	s2,a0
    8000571e:	c905                	beqz	a0,8000574e <sys_open+0x13c>
    ilock(ip);
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	f78080e7          	jalr	-136(ra) # 80003698 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005728:	04491703          	lh	a4,68(s2)
    8000572c:	4785                	li	a5,1
    8000572e:	f4f712e3          	bne	a4,a5,80005672 <sys_open+0x60>
    80005732:	f4c42783          	lw	a5,-180(s0)
    80005736:	dba1                	beqz	a5,80005686 <sys_open+0x74>
      iunlockput(ip);
    80005738:	854a                	mv	a0,s2
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	1c0080e7          	jalr	448(ra) # 800038fa <iunlockput>
      end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	9a8080e7          	jalr	-1624(ra) # 800040ea <end_op>
      return -1;
    8000574a:	54fd                	li	s1,-1
    8000574c:	b76d                	j	800056f6 <sys_open+0xe4>
      end_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	99c080e7          	jalr	-1636(ra) # 800040ea <end_op>
      return -1;
    80005756:	54fd                	li	s1,-1
    80005758:	bf79                	j	800056f6 <sys_open+0xe4>
    iunlockput(ip);
    8000575a:	854a                	mv	a0,s2
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	19e080e7          	jalr	414(ra) # 800038fa <iunlockput>
    end_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	986080e7          	jalr	-1658(ra) # 800040ea <end_op>
    return -1;
    8000576c:	54fd                	li	s1,-1
    8000576e:	b761                	j	800056f6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005770:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005774:	04691783          	lh	a5,70(s2)
    80005778:	02f99223          	sh	a5,36(s3)
    8000577c:	bf2d                	j	800056b6 <sys_open+0xa4>
    itrunc(ip);
    8000577e:	854a                	mv	a0,s2
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	026080e7          	jalr	38(ra) # 800037a6 <itrunc>
    80005788:	bfb1                	j	800056e4 <sys_open+0xd2>
      fileclose(f);
    8000578a:	854e                	mv	a0,s3
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	daa080e7          	jalr	-598(ra) # 80004536 <fileclose>
    iunlockput(ip);
    80005794:	854a                	mv	a0,s2
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	164080e7          	jalr	356(ra) # 800038fa <iunlockput>
    end_op();
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	94c080e7          	jalr	-1716(ra) # 800040ea <end_op>
    return -1;
    800057a6:	54fd                	li	s1,-1
    800057a8:	b7b9                	j	800056f6 <sys_open+0xe4>

00000000800057aa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057aa:	7175                	addi	sp,sp,-144
    800057ac:	e506                	sd	ra,136(sp)
    800057ae:	e122                	sd	s0,128(sp)
    800057b0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	8b8080e7          	jalr	-1864(ra) # 8000406a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057ba:	08000613          	li	a2,128
    800057be:	f7040593          	addi	a1,s0,-144
    800057c2:	4501                	li	a0,0
    800057c4:	ffffd097          	auipc	ra,0xffffd
    800057c8:	32c080e7          	jalr	812(ra) # 80002af0 <argstr>
    800057cc:	02054963          	bltz	a0,800057fe <sys_mkdir+0x54>
    800057d0:	4681                	li	a3,0
    800057d2:	4601                	li	a2,0
    800057d4:	4585                	li	a1,1
    800057d6:	f7040513          	addi	a0,s0,-144
    800057da:	00000097          	auipc	ra,0x0
    800057de:	800080e7          	jalr	-2048(ra) # 80004fda <create>
    800057e2:	cd11                	beqz	a0,800057fe <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	116080e7          	jalr	278(ra) # 800038fa <iunlockput>
  end_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	8fe080e7          	jalr	-1794(ra) # 800040ea <end_op>
  return 0;
    800057f4:	4501                	li	a0,0
}
    800057f6:	60aa                	ld	ra,136(sp)
    800057f8:	640a                	ld	s0,128(sp)
    800057fa:	6149                	addi	sp,sp,144
    800057fc:	8082                	ret
    end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	8ec080e7          	jalr	-1812(ra) # 800040ea <end_op>
    return -1;
    80005806:	557d                	li	a0,-1
    80005808:	b7fd                	j	800057f6 <sys_mkdir+0x4c>

000000008000580a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000580a:	7135                	addi	sp,sp,-160
    8000580c:	ed06                	sd	ra,152(sp)
    8000580e:	e922                	sd	s0,144(sp)
    80005810:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	858080e7          	jalr	-1960(ra) # 8000406a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000581a:	08000613          	li	a2,128
    8000581e:	f7040593          	addi	a1,s0,-144
    80005822:	4501                	li	a0,0
    80005824:	ffffd097          	auipc	ra,0xffffd
    80005828:	2cc080e7          	jalr	716(ra) # 80002af0 <argstr>
    8000582c:	04054a63          	bltz	a0,80005880 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005830:	f6c40593          	addi	a1,s0,-148
    80005834:	4505                	li	a0,1
    80005836:	ffffd097          	auipc	ra,0xffffd
    8000583a:	276080e7          	jalr	630(ra) # 80002aac <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000583e:	04054163          	bltz	a0,80005880 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005842:	f6840593          	addi	a1,s0,-152
    80005846:	4509                	li	a0,2
    80005848:	ffffd097          	auipc	ra,0xffffd
    8000584c:	264080e7          	jalr	612(ra) # 80002aac <argint>
     argint(1, &major) < 0 ||
    80005850:	02054863          	bltz	a0,80005880 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005854:	f6841683          	lh	a3,-152(s0)
    80005858:	f6c41603          	lh	a2,-148(s0)
    8000585c:	458d                	li	a1,3
    8000585e:	f7040513          	addi	a0,s0,-144
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	778080e7          	jalr	1912(ra) # 80004fda <create>
     argint(2, &minor) < 0 ||
    8000586a:	c919                	beqz	a0,80005880 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	08e080e7          	jalr	142(ra) # 800038fa <iunlockput>
  end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	876080e7          	jalr	-1930(ra) # 800040ea <end_op>
  return 0;
    8000587c:	4501                	li	a0,0
    8000587e:	a031                	j	8000588a <sys_mknod+0x80>
    end_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	86a080e7          	jalr	-1942(ra) # 800040ea <end_op>
    return -1;
    80005888:	557d                	li	a0,-1
}
    8000588a:	60ea                	ld	ra,152(sp)
    8000588c:	644a                	ld	s0,144(sp)
    8000588e:	610d                	addi	sp,sp,160
    80005890:	8082                	ret

0000000080005892 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005892:	7135                	addi	sp,sp,-160
    80005894:	ed06                	sd	ra,152(sp)
    80005896:	e922                	sd	s0,144(sp)
    80005898:	e526                	sd	s1,136(sp)
    8000589a:	e14a                	sd	s2,128(sp)
    8000589c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000589e:	ffffc097          	auipc	ra,0xffffc
    800058a2:	0e0080e7          	jalr	224(ra) # 8000197e <myproc>
    800058a6:	892a                	mv	s2,a0
  
  begin_op();
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	7c2080e7          	jalr	1986(ra) # 8000406a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058b0:	08000613          	li	a2,128
    800058b4:	f6040593          	addi	a1,s0,-160
    800058b8:	4501                	li	a0,0
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	236080e7          	jalr	566(ra) # 80002af0 <argstr>
    800058c2:	04054b63          	bltz	a0,80005918 <sys_chdir+0x86>
    800058c6:	f6040513          	addi	a0,s0,-160
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	584080e7          	jalr	1412(ra) # 80003e4e <namei>
    800058d2:	84aa                	mv	s1,a0
    800058d4:	c131                	beqz	a0,80005918 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	dc2080e7          	jalr	-574(ra) # 80003698 <ilock>
  if(ip->type != T_DIR){
    800058de:	04449703          	lh	a4,68(s1)
    800058e2:	4785                	li	a5,1
    800058e4:	04f71063          	bne	a4,a5,80005924 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	e70080e7          	jalr	-400(ra) # 8000375a <iunlock>
  iput(p->cwd);
    800058f2:	15093503          	ld	a0,336(s2)
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	f5c080e7          	jalr	-164(ra) # 80003852 <iput>
  end_op();
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	7ec080e7          	jalr	2028(ra) # 800040ea <end_op>
  p->cwd = ip;
    80005906:	14993823          	sd	s1,336(s2)
  return 0;
    8000590a:	4501                	li	a0,0
}
    8000590c:	60ea                	ld	ra,152(sp)
    8000590e:	644a                	ld	s0,144(sp)
    80005910:	64aa                	ld	s1,136(sp)
    80005912:	690a                	ld	s2,128(sp)
    80005914:	610d                	addi	sp,sp,160
    80005916:	8082                	ret
    end_op();
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	7d2080e7          	jalr	2002(ra) # 800040ea <end_op>
    return -1;
    80005920:	557d                	li	a0,-1
    80005922:	b7ed                	j	8000590c <sys_chdir+0x7a>
    iunlockput(ip);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	fd4080e7          	jalr	-44(ra) # 800038fa <iunlockput>
    end_op();
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	7bc080e7          	jalr	1980(ra) # 800040ea <end_op>
    return -1;
    80005936:	557d                	li	a0,-1
    80005938:	bfd1                	j	8000590c <sys_chdir+0x7a>

000000008000593a <sys_exec>:

uint64
sys_exec(void)
{
    8000593a:	7145                	addi	sp,sp,-464
    8000593c:	e786                	sd	ra,456(sp)
    8000593e:	e3a2                	sd	s0,448(sp)
    80005940:	ff26                	sd	s1,440(sp)
    80005942:	fb4a                	sd	s2,432(sp)
    80005944:	f74e                	sd	s3,424(sp)
    80005946:	f352                	sd	s4,416(sp)
    80005948:	ef56                	sd	s5,408(sp)
    8000594a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000594c:	08000613          	li	a2,128
    80005950:	f4040593          	addi	a1,s0,-192
    80005954:	4501                	li	a0,0
    80005956:	ffffd097          	auipc	ra,0xffffd
    8000595a:	19a080e7          	jalr	410(ra) # 80002af0 <argstr>
    return -1;
    8000595e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005960:	0c054a63          	bltz	a0,80005a34 <sys_exec+0xfa>
    80005964:	e3840593          	addi	a1,s0,-456
    80005968:	4505                	li	a0,1
    8000596a:	ffffd097          	auipc	ra,0xffffd
    8000596e:	164080e7          	jalr	356(ra) # 80002ace <argaddr>
    80005972:	0c054163          	bltz	a0,80005a34 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005976:	10000613          	li	a2,256
    8000597a:	4581                	li	a1,0
    8000597c:	e4040513          	addi	a0,s0,-448
    80005980:	ffffb097          	auipc	ra,0xffffb
    80005984:	33e080e7          	jalr	830(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005988:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000598c:	89a6                	mv	s3,s1
    8000598e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005990:	02000a13          	li	s4,32
    80005994:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005998:	00391793          	slli	a5,s2,0x3
    8000599c:	e3040593          	addi	a1,s0,-464
    800059a0:	e3843503          	ld	a0,-456(s0)
    800059a4:	953e                	add	a0,a0,a5
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	06c080e7          	jalr	108(ra) # 80002a12 <fetchaddr>
    800059ae:	02054a63          	bltz	a0,800059e2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059b2:	e3043783          	ld	a5,-464(s0)
    800059b6:	c3b9                	beqz	a5,800059fc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059b8:	ffffb097          	auipc	ra,0xffffb
    800059bc:	11a080e7          	jalr	282(ra) # 80000ad2 <kalloc>
    800059c0:	85aa                	mv	a1,a0
    800059c2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059c6:	cd11                	beqz	a0,800059e2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059c8:	6605                	lui	a2,0x1
    800059ca:	e3043503          	ld	a0,-464(s0)
    800059ce:	ffffd097          	auipc	ra,0xffffd
    800059d2:	096080e7          	jalr	150(ra) # 80002a64 <fetchstr>
    800059d6:	00054663          	bltz	a0,800059e2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800059da:	0905                	addi	s2,s2,1
    800059dc:	09a1                	addi	s3,s3,8
    800059de:	fb491be3          	bne	s2,s4,80005994 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059e2:	10048913          	addi	s2,s1,256
    800059e6:	6088                	ld	a0,0(s1)
    800059e8:	c529                	beqz	a0,80005a32 <sys_exec+0xf8>
    kfree(argv[i]);
    800059ea:	ffffb097          	auipc	ra,0xffffb
    800059ee:	fec080e7          	jalr	-20(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059f2:	04a1                	addi	s1,s1,8
    800059f4:	ff2499e3          	bne	s1,s2,800059e6 <sys_exec+0xac>
  return -1;
    800059f8:	597d                	li	s2,-1
    800059fa:	a82d                	j	80005a34 <sys_exec+0xfa>
      argv[i] = 0;
    800059fc:	0a8e                	slli	s5,s5,0x3
    800059fe:	fc040793          	addi	a5,s0,-64
    80005a02:	9abe                	add	s5,s5,a5
    80005a04:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005a08:	e4040593          	addi	a1,s0,-448
    80005a0c:	f4040513          	addi	a0,s0,-192
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	178080e7          	jalr	376(ra) # 80004b88 <exec>
    80005a18:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a1a:	10048993          	addi	s3,s1,256
    80005a1e:	6088                	ld	a0,0(s1)
    80005a20:	c911                	beqz	a0,80005a34 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	fb4080e7          	jalr	-76(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a2a:	04a1                	addi	s1,s1,8
    80005a2c:	ff3499e3          	bne	s1,s3,80005a1e <sys_exec+0xe4>
    80005a30:	a011                	j	80005a34 <sys_exec+0xfa>
  return -1;
    80005a32:	597d                	li	s2,-1
}
    80005a34:	854a                	mv	a0,s2
    80005a36:	60be                	ld	ra,456(sp)
    80005a38:	641e                	ld	s0,448(sp)
    80005a3a:	74fa                	ld	s1,440(sp)
    80005a3c:	795a                	ld	s2,432(sp)
    80005a3e:	79ba                	ld	s3,424(sp)
    80005a40:	7a1a                	ld	s4,416(sp)
    80005a42:	6afa                	ld	s5,408(sp)
    80005a44:	6179                	addi	sp,sp,464
    80005a46:	8082                	ret

0000000080005a48 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a48:	7139                	addi	sp,sp,-64
    80005a4a:	fc06                	sd	ra,56(sp)
    80005a4c:	f822                	sd	s0,48(sp)
    80005a4e:	f426                	sd	s1,40(sp)
    80005a50:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a52:	ffffc097          	auipc	ra,0xffffc
    80005a56:	f2c080e7          	jalr	-212(ra) # 8000197e <myproc>
    80005a5a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a5c:	fd840593          	addi	a1,s0,-40
    80005a60:	4501                	li	a0,0
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	06c080e7          	jalr	108(ra) # 80002ace <argaddr>
    return -1;
    80005a6a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a6c:	0e054063          	bltz	a0,80005b4c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a70:	fc840593          	addi	a1,s0,-56
    80005a74:	fd040513          	addi	a0,s0,-48
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	dee080e7          	jalr	-530(ra) # 80004866 <pipealloc>
    return -1;
    80005a80:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a82:	0c054563          	bltz	a0,80005b4c <sys_pipe+0x104>
  fd0 = -1;
    80005a86:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a8a:	fd043503          	ld	a0,-48(s0)
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	50a080e7          	jalr	1290(ra) # 80004f98 <fdalloc>
    80005a96:	fca42223          	sw	a0,-60(s0)
    80005a9a:	08054c63          	bltz	a0,80005b32 <sys_pipe+0xea>
    80005a9e:	fc843503          	ld	a0,-56(s0)
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	4f6080e7          	jalr	1270(ra) # 80004f98 <fdalloc>
    80005aaa:	fca42023          	sw	a0,-64(s0)
    80005aae:	06054863          	bltz	a0,80005b1e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ab2:	4691                	li	a3,4
    80005ab4:	fc440613          	addi	a2,s0,-60
    80005ab8:	fd843583          	ld	a1,-40(s0)
    80005abc:	68a8                	ld	a0,80(s1)
    80005abe:	ffffc097          	auipc	ra,0xffffc
    80005ac2:	b80080e7          	jalr	-1152(ra) # 8000163e <copyout>
    80005ac6:	02054063          	bltz	a0,80005ae6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005aca:	4691                	li	a3,4
    80005acc:	fc040613          	addi	a2,s0,-64
    80005ad0:	fd843583          	ld	a1,-40(s0)
    80005ad4:	0591                	addi	a1,a1,4
    80005ad6:	68a8                	ld	a0,80(s1)
    80005ad8:	ffffc097          	auipc	ra,0xffffc
    80005adc:	b66080e7          	jalr	-1178(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ae0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ae2:	06055563          	bgez	a0,80005b4c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ae6:	fc442783          	lw	a5,-60(s0)
    80005aea:	07e9                	addi	a5,a5,26
    80005aec:	078e                	slli	a5,a5,0x3
    80005aee:	97a6                	add	a5,a5,s1
    80005af0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005af4:	fc042503          	lw	a0,-64(s0)
    80005af8:	0569                	addi	a0,a0,26
    80005afa:	050e                	slli	a0,a0,0x3
    80005afc:	9526                	add	a0,a0,s1
    80005afe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b02:	fd043503          	ld	a0,-48(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	a30080e7          	jalr	-1488(ra) # 80004536 <fileclose>
    fileclose(wf);
    80005b0e:	fc843503          	ld	a0,-56(s0)
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	a24080e7          	jalr	-1500(ra) # 80004536 <fileclose>
    return -1;
    80005b1a:	57fd                	li	a5,-1
    80005b1c:	a805                	j	80005b4c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b1e:	fc442783          	lw	a5,-60(s0)
    80005b22:	0007c863          	bltz	a5,80005b32 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b26:	01a78513          	addi	a0,a5,26
    80005b2a:	050e                	slli	a0,a0,0x3
    80005b2c:	9526                	add	a0,a0,s1
    80005b2e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b32:	fd043503          	ld	a0,-48(s0)
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	a00080e7          	jalr	-1536(ra) # 80004536 <fileclose>
    fileclose(wf);
    80005b3e:	fc843503          	ld	a0,-56(s0)
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	9f4080e7          	jalr	-1548(ra) # 80004536 <fileclose>
    return -1;
    80005b4a:	57fd                	li	a5,-1
}
    80005b4c:	853e                	mv	a0,a5
    80005b4e:	70e2                	ld	ra,56(sp)
    80005b50:	7442                	ld	s0,48(sp)
    80005b52:	74a2                	ld	s1,40(sp)
    80005b54:	6121                	addi	sp,sp,64
    80005b56:	8082                	ret
	...

0000000080005b60 <kernelvec>:
    80005b60:	7111                	addi	sp,sp,-256
    80005b62:	e006                	sd	ra,0(sp)
    80005b64:	e40a                	sd	sp,8(sp)
    80005b66:	e80e                	sd	gp,16(sp)
    80005b68:	ec12                	sd	tp,24(sp)
    80005b6a:	f016                	sd	t0,32(sp)
    80005b6c:	f41a                	sd	t1,40(sp)
    80005b6e:	f81e                	sd	t2,48(sp)
    80005b70:	fc22                	sd	s0,56(sp)
    80005b72:	e0a6                	sd	s1,64(sp)
    80005b74:	e4aa                	sd	a0,72(sp)
    80005b76:	e8ae                	sd	a1,80(sp)
    80005b78:	ecb2                	sd	a2,88(sp)
    80005b7a:	f0b6                	sd	a3,96(sp)
    80005b7c:	f4ba                	sd	a4,104(sp)
    80005b7e:	f8be                	sd	a5,112(sp)
    80005b80:	fcc2                	sd	a6,120(sp)
    80005b82:	e146                	sd	a7,128(sp)
    80005b84:	e54a                	sd	s2,136(sp)
    80005b86:	e94e                	sd	s3,144(sp)
    80005b88:	ed52                	sd	s4,152(sp)
    80005b8a:	f156                	sd	s5,160(sp)
    80005b8c:	f55a                	sd	s6,168(sp)
    80005b8e:	f95e                	sd	s7,176(sp)
    80005b90:	fd62                	sd	s8,184(sp)
    80005b92:	e1e6                	sd	s9,192(sp)
    80005b94:	e5ea                	sd	s10,200(sp)
    80005b96:	e9ee                	sd	s11,208(sp)
    80005b98:	edf2                	sd	t3,216(sp)
    80005b9a:	f1f6                	sd	t4,224(sp)
    80005b9c:	f5fa                	sd	t5,232(sp)
    80005b9e:	f9fe                	sd	t6,240(sp)
    80005ba0:	d3ffc0ef          	jal	ra,800028de <kerneltrap>
    80005ba4:	6082                	ld	ra,0(sp)
    80005ba6:	6122                	ld	sp,8(sp)
    80005ba8:	61c2                	ld	gp,16(sp)
    80005baa:	7282                	ld	t0,32(sp)
    80005bac:	7322                	ld	t1,40(sp)
    80005bae:	73c2                	ld	t2,48(sp)
    80005bb0:	7462                	ld	s0,56(sp)
    80005bb2:	6486                	ld	s1,64(sp)
    80005bb4:	6526                	ld	a0,72(sp)
    80005bb6:	65c6                	ld	a1,80(sp)
    80005bb8:	6666                	ld	a2,88(sp)
    80005bba:	7686                	ld	a3,96(sp)
    80005bbc:	7726                	ld	a4,104(sp)
    80005bbe:	77c6                	ld	a5,112(sp)
    80005bc0:	7866                	ld	a6,120(sp)
    80005bc2:	688a                	ld	a7,128(sp)
    80005bc4:	692a                	ld	s2,136(sp)
    80005bc6:	69ca                	ld	s3,144(sp)
    80005bc8:	6a6a                	ld	s4,152(sp)
    80005bca:	7a8a                	ld	s5,160(sp)
    80005bcc:	7b2a                	ld	s6,168(sp)
    80005bce:	7bca                	ld	s7,176(sp)
    80005bd0:	7c6a                	ld	s8,184(sp)
    80005bd2:	6c8e                	ld	s9,192(sp)
    80005bd4:	6d2e                	ld	s10,200(sp)
    80005bd6:	6dce                	ld	s11,208(sp)
    80005bd8:	6e6e                	ld	t3,216(sp)
    80005bda:	7e8e                	ld	t4,224(sp)
    80005bdc:	7f2e                	ld	t5,232(sp)
    80005bde:	7fce                	ld	t6,240(sp)
    80005be0:	6111                	addi	sp,sp,256
    80005be2:	10200073          	sret
    80005be6:	00000013          	nop
    80005bea:	00000013          	nop
    80005bee:	0001                	nop

0000000080005bf0 <timervec>:
    80005bf0:	34051573          	csrrw	a0,mscratch,a0
    80005bf4:	e10c                	sd	a1,0(a0)
    80005bf6:	e510                	sd	a2,8(a0)
    80005bf8:	e914                	sd	a3,16(a0)
    80005bfa:	6d0c                	ld	a1,24(a0)
    80005bfc:	7110                	ld	a2,32(a0)
    80005bfe:	6194                	ld	a3,0(a1)
    80005c00:	96b2                	add	a3,a3,a2
    80005c02:	e194                	sd	a3,0(a1)
    80005c04:	4589                	li	a1,2
    80005c06:	14459073          	csrw	sip,a1
    80005c0a:	6914                	ld	a3,16(a0)
    80005c0c:	6510                	ld	a2,8(a0)
    80005c0e:	610c                	ld	a1,0(a0)
    80005c10:	34051573          	csrrw	a0,mscratch,a0
    80005c14:	30200073          	mret
	...

0000000080005c1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c1a:	1141                	addi	sp,sp,-16
    80005c1c:	e422                	sd	s0,8(sp)
    80005c1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c20:	0c0007b7          	lui	a5,0xc000
    80005c24:	4705                	li	a4,1
    80005c26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c28:	c3d8                	sw	a4,4(a5)
}
    80005c2a:	6422                	ld	s0,8(sp)
    80005c2c:	0141                	addi	sp,sp,16
    80005c2e:	8082                	ret

0000000080005c30 <plicinithart>:

void
plicinithart(void)
{
    80005c30:	1141                	addi	sp,sp,-16
    80005c32:	e406                	sd	ra,8(sp)
    80005c34:	e022                	sd	s0,0(sp)
    80005c36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c38:	ffffc097          	auipc	ra,0xffffc
    80005c3c:	d1a080e7          	jalr	-742(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c40:	0085171b          	slliw	a4,a0,0x8
    80005c44:	0c0027b7          	lui	a5,0xc002
    80005c48:	97ba                	add	a5,a5,a4
    80005c4a:	40200713          	li	a4,1026
    80005c4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c52:	00d5151b          	slliw	a0,a0,0xd
    80005c56:	0c2017b7          	lui	a5,0xc201
    80005c5a:	953e                	add	a0,a0,a5
    80005c5c:	00052023          	sw	zero,0(a0)
}
    80005c60:	60a2                	ld	ra,8(sp)
    80005c62:	6402                	ld	s0,0(sp)
    80005c64:	0141                	addi	sp,sp,16
    80005c66:	8082                	ret

0000000080005c68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c68:	1141                	addi	sp,sp,-16
    80005c6a:	e406                	sd	ra,8(sp)
    80005c6c:	e022                	sd	s0,0(sp)
    80005c6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c70:	ffffc097          	auipc	ra,0xffffc
    80005c74:	ce2080e7          	jalr	-798(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c78:	00d5179b          	slliw	a5,a0,0xd
    80005c7c:	0c201537          	lui	a0,0xc201
    80005c80:	953e                	add	a0,a0,a5
  return irq;
}
    80005c82:	4148                	lw	a0,4(a0)
    80005c84:	60a2                	ld	ra,8(sp)
    80005c86:	6402                	ld	s0,0(sp)
    80005c88:	0141                	addi	sp,sp,16
    80005c8a:	8082                	ret

0000000080005c8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c8c:	1101                	addi	sp,sp,-32
    80005c8e:	ec06                	sd	ra,24(sp)
    80005c90:	e822                	sd	s0,16(sp)
    80005c92:	e426                	sd	s1,8(sp)
    80005c94:	1000                	addi	s0,sp,32
    80005c96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	cba080e7          	jalr	-838(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ca0:	00d5151b          	slliw	a0,a0,0xd
    80005ca4:	0c2017b7          	lui	a5,0xc201
    80005ca8:	97aa                	add	a5,a5,a0
    80005caa:	c3c4                	sw	s1,4(a5)
}
    80005cac:	60e2                	ld	ra,24(sp)
    80005cae:	6442                	ld	s0,16(sp)
    80005cb0:	64a2                	ld	s1,8(sp)
    80005cb2:	6105                	addi	sp,sp,32
    80005cb4:	8082                	ret

0000000080005cb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cb6:	1141                	addi	sp,sp,-16
    80005cb8:	e406                	sd	ra,8(sp)
    80005cba:	e022                	sd	s0,0(sp)
    80005cbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cbe:	479d                	li	a5,7
    80005cc0:	06a7c963          	blt	a5,a0,80005d32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005cc4:	0001d797          	auipc	a5,0x1d
    80005cc8:	33c78793          	addi	a5,a5,828 # 80023000 <disk>
    80005ccc:	00a78733          	add	a4,a5,a0
    80005cd0:	6789                	lui	a5,0x2
    80005cd2:	97ba                	add	a5,a5,a4
    80005cd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005cd8:	e7ad                	bnez	a5,80005d42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cda:	00451793          	slli	a5,a0,0x4
    80005cde:	0001f717          	auipc	a4,0x1f
    80005ce2:	32270713          	addi	a4,a4,802 # 80025000 <disk+0x2000>
    80005ce6:	6314                	ld	a3,0(a4)
    80005ce8:	96be                	add	a3,a3,a5
    80005cea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005cee:	6314                	ld	a3,0(a4)
    80005cf0:	96be                	add	a3,a3,a5
    80005cf2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005cf6:	6314                	ld	a3,0(a4)
    80005cf8:	96be                	add	a3,a3,a5
    80005cfa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cfe:	6318                	ld	a4,0(a4)
    80005d00:	97ba                	add	a5,a5,a4
    80005d02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d06:	0001d797          	auipc	a5,0x1d
    80005d0a:	2fa78793          	addi	a5,a5,762 # 80023000 <disk>
    80005d0e:	97aa                	add	a5,a5,a0
    80005d10:	6509                	lui	a0,0x2
    80005d12:	953e                	add	a0,a0,a5
    80005d14:	4785                	li	a5,1
    80005d16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d1a:	0001f517          	auipc	a0,0x1f
    80005d1e:	2fe50513          	addi	a0,a0,766 # 80025018 <disk+0x2018>
    80005d22:	ffffc097          	auipc	ra,0xffffc
    80005d26:	4e4080e7          	jalr	1252(ra) # 80002206 <wakeup>
}
    80005d2a:	60a2                	ld	ra,8(sp)
    80005d2c:	6402                	ld	s0,0(sp)
    80005d2e:	0141                	addi	sp,sp,16
    80005d30:	8082                	ret
    panic("free_desc 1");
    80005d32:	00003517          	auipc	a0,0x3
    80005d36:	a2650513          	addi	a0,a0,-1498 # 80008758 <syscalls+0x328>
    80005d3a:	ffffa097          	auipc	ra,0xffffa
    80005d3e:	7f0080e7          	jalr	2032(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005d42:	00003517          	auipc	a0,0x3
    80005d46:	a2650513          	addi	a0,a0,-1498 # 80008768 <syscalls+0x338>
    80005d4a:	ffffa097          	auipc	ra,0xffffa
    80005d4e:	7e0080e7          	jalr	2016(ra) # 8000052a <panic>

0000000080005d52 <virtio_disk_init>:
{
    80005d52:	1101                	addi	sp,sp,-32
    80005d54:	ec06                	sd	ra,24(sp)
    80005d56:	e822                	sd	s0,16(sp)
    80005d58:	e426                	sd	s1,8(sp)
    80005d5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d5c:	00003597          	auipc	a1,0x3
    80005d60:	a1c58593          	addi	a1,a1,-1508 # 80008778 <syscalls+0x348>
    80005d64:	0001f517          	auipc	a0,0x1f
    80005d68:	3c450513          	addi	a0,a0,964 # 80025128 <disk+0x2128>
    80005d6c:	ffffb097          	auipc	ra,0xffffb
    80005d70:	dc6080e7          	jalr	-570(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d74:	100017b7          	lui	a5,0x10001
    80005d78:	4398                	lw	a4,0(a5)
    80005d7a:	2701                	sext.w	a4,a4
    80005d7c:	747277b7          	lui	a5,0x74727
    80005d80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d84:	0ef71163          	bne	a4,a5,80005e66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d88:	100017b7          	lui	a5,0x10001
    80005d8c:	43dc                	lw	a5,4(a5)
    80005d8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d90:	4705                	li	a4,1
    80005d92:	0ce79a63          	bne	a5,a4,80005e66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d96:	100017b7          	lui	a5,0x10001
    80005d9a:	479c                	lw	a5,8(a5)
    80005d9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d9e:	4709                	li	a4,2
    80005da0:	0ce79363          	bne	a5,a4,80005e66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005da4:	100017b7          	lui	a5,0x10001
    80005da8:	47d8                	lw	a4,12(a5)
    80005daa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dac:	554d47b7          	lui	a5,0x554d4
    80005db0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005db4:	0af71963          	bne	a4,a5,80005e66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005db8:	100017b7          	lui	a5,0x10001
    80005dbc:	4705                	li	a4,1
    80005dbe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc0:	470d                	li	a4,3
    80005dc2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dc4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dc6:	c7ffe737          	lui	a4,0xc7ffe
    80005dca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dd0:	2701                	sext.w	a4,a4
    80005dd2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dd4:	472d                	li	a4,11
    80005dd6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dd8:	473d                	li	a4,15
    80005dda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ddc:	6705                	lui	a4,0x1
    80005dde:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005de0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005de4:	5bdc                	lw	a5,52(a5)
    80005de6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005de8:	c7d9                	beqz	a5,80005e76 <virtio_disk_init+0x124>
  if(max < NUM)
    80005dea:	471d                	li	a4,7
    80005dec:	08f77d63          	bgeu	a4,a5,80005e86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005df0:	100014b7          	lui	s1,0x10001
    80005df4:	47a1                	li	a5,8
    80005df6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005df8:	6609                	lui	a2,0x2
    80005dfa:	4581                	li	a1,0
    80005dfc:	0001d517          	auipc	a0,0x1d
    80005e00:	20450513          	addi	a0,a0,516 # 80023000 <disk>
    80005e04:	ffffb097          	auipc	ra,0xffffb
    80005e08:	eba080e7          	jalr	-326(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e0c:	0001d717          	auipc	a4,0x1d
    80005e10:	1f470713          	addi	a4,a4,500 # 80023000 <disk>
    80005e14:	00c75793          	srli	a5,a4,0xc
    80005e18:	2781                	sext.w	a5,a5
    80005e1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e1c:	0001f797          	auipc	a5,0x1f
    80005e20:	1e478793          	addi	a5,a5,484 # 80025000 <disk+0x2000>
    80005e24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e26:	0001d717          	auipc	a4,0x1d
    80005e2a:	25a70713          	addi	a4,a4,602 # 80023080 <disk+0x80>
    80005e2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e30:	0001e717          	auipc	a4,0x1e
    80005e34:	1d070713          	addi	a4,a4,464 # 80024000 <disk+0x1000>
    80005e38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e3a:	4705                	li	a4,1
    80005e3c:	00e78c23          	sb	a4,24(a5)
    80005e40:	00e78ca3          	sb	a4,25(a5)
    80005e44:	00e78d23          	sb	a4,26(a5)
    80005e48:	00e78da3          	sb	a4,27(a5)
    80005e4c:	00e78e23          	sb	a4,28(a5)
    80005e50:	00e78ea3          	sb	a4,29(a5)
    80005e54:	00e78f23          	sb	a4,30(a5)
    80005e58:	00e78fa3          	sb	a4,31(a5)
}
    80005e5c:	60e2                	ld	ra,24(sp)
    80005e5e:	6442                	ld	s0,16(sp)
    80005e60:	64a2                	ld	s1,8(sp)
    80005e62:	6105                	addi	sp,sp,32
    80005e64:	8082                	ret
    panic("could not find virtio disk");
    80005e66:	00003517          	auipc	a0,0x3
    80005e6a:	92250513          	addi	a0,a0,-1758 # 80008788 <syscalls+0x358>
    80005e6e:	ffffa097          	auipc	ra,0xffffa
    80005e72:	6bc080e7          	jalr	1724(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005e76:	00003517          	auipc	a0,0x3
    80005e7a:	93250513          	addi	a0,a0,-1742 # 800087a8 <syscalls+0x378>
    80005e7e:	ffffa097          	auipc	ra,0xffffa
    80005e82:	6ac080e7          	jalr	1708(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005e86:	00003517          	auipc	a0,0x3
    80005e8a:	94250513          	addi	a0,a0,-1726 # 800087c8 <syscalls+0x398>
    80005e8e:	ffffa097          	auipc	ra,0xffffa
    80005e92:	69c080e7          	jalr	1692(ra) # 8000052a <panic>

0000000080005e96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e96:	7119                	addi	sp,sp,-128
    80005e98:	fc86                	sd	ra,120(sp)
    80005e9a:	f8a2                	sd	s0,112(sp)
    80005e9c:	f4a6                	sd	s1,104(sp)
    80005e9e:	f0ca                	sd	s2,96(sp)
    80005ea0:	ecce                	sd	s3,88(sp)
    80005ea2:	e8d2                	sd	s4,80(sp)
    80005ea4:	e4d6                	sd	s5,72(sp)
    80005ea6:	e0da                	sd	s6,64(sp)
    80005ea8:	fc5e                	sd	s7,56(sp)
    80005eaa:	f862                	sd	s8,48(sp)
    80005eac:	f466                	sd	s9,40(sp)
    80005eae:	f06a                	sd	s10,32(sp)
    80005eb0:	ec6e                	sd	s11,24(sp)
    80005eb2:	0100                	addi	s0,sp,128
    80005eb4:	8aaa                	mv	s5,a0
    80005eb6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005eb8:	00c52c83          	lw	s9,12(a0)
    80005ebc:	001c9c9b          	slliw	s9,s9,0x1
    80005ec0:	1c82                	slli	s9,s9,0x20
    80005ec2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ec6:	0001f517          	auipc	a0,0x1f
    80005eca:	26250513          	addi	a0,a0,610 # 80025128 <disk+0x2128>
    80005ece:	ffffb097          	auipc	ra,0xffffb
    80005ed2:	cf4080e7          	jalr	-780(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005ed6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ed8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005eda:	0001dc17          	auipc	s8,0x1d
    80005ede:	126c0c13          	addi	s8,s8,294 # 80023000 <disk>
    80005ee2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005ee4:	4b0d                	li	s6,3
    80005ee6:	a0ad                	j	80005f50 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005ee8:	00fc0733          	add	a4,s8,a5
    80005eec:	975e                	add	a4,a4,s7
    80005eee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ef2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005ef4:	0207c563          	bltz	a5,80005f1e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ef8:	2905                	addiw	s2,s2,1
    80005efa:	0611                	addi	a2,a2,4
    80005efc:	19690d63          	beq	s2,s6,80006096 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f00:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f02:	0001f717          	auipc	a4,0x1f
    80005f06:	11670713          	addi	a4,a4,278 # 80025018 <disk+0x2018>
    80005f0a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f0c:	00074683          	lbu	a3,0(a4)
    80005f10:	fee1                	bnez	a3,80005ee8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f12:	2785                	addiw	a5,a5,1
    80005f14:	0705                	addi	a4,a4,1
    80005f16:	fe979be3          	bne	a5,s1,80005f0c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f1a:	57fd                	li	a5,-1
    80005f1c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f1e:	01205d63          	blez	s2,80005f38 <virtio_disk_rw+0xa2>
    80005f22:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f24:	000a2503          	lw	a0,0(s4)
    80005f28:	00000097          	auipc	ra,0x0
    80005f2c:	d8e080e7          	jalr	-626(ra) # 80005cb6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f30:	2d85                	addiw	s11,s11,1
    80005f32:	0a11                	addi	s4,s4,4
    80005f34:	ffb918e3          	bne	s2,s11,80005f24 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f38:	0001f597          	auipc	a1,0x1f
    80005f3c:	1f058593          	addi	a1,a1,496 # 80025128 <disk+0x2128>
    80005f40:	0001f517          	auipc	a0,0x1f
    80005f44:	0d850513          	addi	a0,a0,216 # 80025018 <disk+0x2018>
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	132080e7          	jalr	306(ra) # 8000207a <sleep>
  for(int i = 0; i < 3; i++){
    80005f50:	f8040a13          	addi	s4,s0,-128
{
    80005f54:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f56:	894e                	mv	s2,s3
    80005f58:	b765                	j	80005f00 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f5a:	0001f697          	auipc	a3,0x1f
    80005f5e:	0a66b683          	ld	a3,166(a3) # 80025000 <disk+0x2000>
    80005f62:	96ba                	add	a3,a3,a4
    80005f64:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f68:	0001d817          	auipc	a6,0x1d
    80005f6c:	09880813          	addi	a6,a6,152 # 80023000 <disk>
    80005f70:	0001f697          	auipc	a3,0x1f
    80005f74:	09068693          	addi	a3,a3,144 # 80025000 <disk+0x2000>
    80005f78:	6290                	ld	a2,0(a3)
    80005f7a:	963a                	add	a2,a2,a4
    80005f7c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005f80:	0015e593          	ori	a1,a1,1
    80005f84:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005f88:	f8842603          	lw	a2,-120(s0)
    80005f8c:	628c                	ld	a1,0(a3)
    80005f8e:	972e                	add	a4,a4,a1
    80005f90:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f94:	20050593          	addi	a1,a0,512
    80005f98:	0592                	slli	a1,a1,0x4
    80005f9a:	95c2                	add	a1,a1,a6
    80005f9c:	577d                	li	a4,-1
    80005f9e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fa2:	00461713          	slli	a4,a2,0x4
    80005fa6:	6290                	ld	a2,0(a3)
    80005fa8:	963a                	add	a2,a2,a4
    80005faa:	03078793          	addi	a5,a5,48
    80005fae:	97c2                	add	a5,a5,a6
    80005fb0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005fb2:	629c                	ld	a5,0(a3)
    80005fb4:	97ba                	add	a5,a5,a4
    80005fb6:	4605                	li	a2,1
    80005fb8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fba:	629c                	ld	a5,0(a3)
    80005fbc:	97ba                	add	a5,a5,a4
    80005fbe:	4809                	li	a6,2
    80005fc0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005fc4:	629c                	ld	a5,0(a3)
    80005fc6:	973e                	add	a4,a4,a5
    80005fc8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fcc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005fd0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fd4:	6698                	ld	a4,8(a3)
    80005fd6:	00275783          	lhu	a5,2(a4)
    80005fda:	8b9d                	andi	a5,a5,7
    80005fdc:	0786                	slli	a5,a5,0x1
    80005fde:	97ba                	add	a5,a5,a4
    80005fe0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80005fe4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005fe8:	6698                	ld	a4,8(a3)
    80005fea:	00275783          	lhu	a5,2(a4)
    80005fee:	2785                	addiw	a5,a5,1
    80005ff0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005ff4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005ff8:	100017b7          	lui	a5,0x10001
    80005ffc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006000:	004aa783          	lw	a5,4(s5)
    80006004:	02c79163          	bne	a5,a2,80006026 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006008:	0001f917          	auipc	s2,0x1f
    8000600c:	12090913          	addi	s2,s2,288 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006010:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006012:	85ca                	mv	a1,s2
    80006014:	8556                	mv	a0,s5
    80006016:	ffffc097          	auipc	ra,0xffffc
    8000601a:	064080e7          	jalr	100(ra) # 8000207a <sleep>
  while(b->disk == 1) {
    8000601e:	004aa783          	lw	a5,4(s5)
    80006022:	fe9788e3          	beq	a5,s1,80006012 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006026:	f8042903          	lw	s2,-128(s0)
    8000602a:	20090793          	addi	a5,s2,512
    8000602e:	00479713          	slli	a4,a5,0x4
    80006032:	0001d797          	auipc	a5,0x1d
    80006036:	fce78793          	addi	a5,a5,-50 # 80023000 <disk>
    8000603a:	97ba                	add	a5,a5,a4
    8000603c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006040:	0001f997          	auipc	s3,0x1f
    80006044:	fc098993          	addi	s3,s3,-64 # 80025000 <disk+0x2000>
    80006048:	00491713          	slli	a4,s2,0x4
    8000604c:	0009b783          	ld	a5,0(s3)
    80006050:	97ba                	add	a5,a5,a4
    80006052:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006056:	854a                	mv	a0,s2
    80006058:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000605c:	00000097          	auipc	ra,0x0
    80006060:	c5a080e7          	jalr	-934(ra) # 80005cb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006064:	8885                	andi	s1,s1,1
    80006066:	f0ed                	bnez	s1,80006048 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006068:	0001f517          	auipc	a0,0x1f
    8000606c:	0c050513          	addi	a0,a0,192 # 80025128 <disk+0x2128>
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	c06080e7          	jalr	-1018(ra) # 80000c76 <release>
}
    80006078:	70e6                	ld	ra,120(sp)
    8000607a:	7446                	ld	s0,112(sp)
    8000607c:	74a6                	ld	s1,104(sp)
    8000607e:	7906                	ld	s2,96(sp)
    80006080:	69e6                	ld	s3,88(sp)
    80006082:	6a46                	ld	s4,80(sp)
    80006084:	6aa6                	ld	s5,72(sp)
    80006086:	6b06                	ld	s6,64(sp)
    80006088:	7be2                	ld	s7,56(sp)
    8000608a:	7c42                	ld	s8,48(sp)
    8000608c:	7ca2                	ld	s9,40(sp)
    8000608e:	7d02                	ld	s10,32(sp)
    80006090:	6de2                	ld	s11,24(sp)
    80006092:	6109                	addi	sp,sp,128
    80006094:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006096:	f8042503          	lw	a0,-128(s0)
    8000609a:	20050793          	addi	a5,a0,512
    8000609e:	0792                	slli	a5,a5,0x4
  if(write)
    800060a0:	0001d817          	auipc	a6,0x1d
    800060a4:	f6080813          	addi	a6,a6,-160 # 80023000 <disk>
    800060a8:	00f80733          	add	a4,a6,a5
    800060ac:	01a036b3          	snez	a3,s10
    800060b0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800060b4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060b8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060bc:	7679                	lui	a2,0xffffe
    800060be:	963e                	add	a2,a2,a5
    800060c0:	0001f697          	auipc	a3,0x1f
    800060c4:	f4068693          	addi	a3,a3,-192 # 80025000 <disk+0x2000>
    800060c8:	6298                	ld	a4,0(a3)
    800060ca:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060cc:	0a878593          	addi	a1,a5,168
    800060d0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060d2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060d4:	6298                	ld	a4,0(a3)
    800060d6:	9732                	add	a4,a4,a2
    800060d8:	45c1                	li	a1,16
    800060da:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060dc:	6298                	ld	a4,0(a3)
    800060de:	9732                	add	a4,a4,a2
    800060e0:	4585                	li	a1,1
    800060e2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060e6:	f8442703          	lw	a4,-124(s0)
    800060ea:	628c                	ld	a1,0(a3)
    800060ec:	962e                	add	a2,a2,a1
    800060ee:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800060f2:	0712                	slli	a4,a4,0x4
    800060f4:	6290                	ld	a2,0(a3)
    800060f6:	963a                	add	a2,a2,a4
    800060f8:	058a8593          	addi	a1,s5,88
    800060fc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060fe:	6294                	ld	a3,0(a3)
    80006100:	96ba                	add	a3,a3,a4
    80006102:	40000613          	li	a2,1024
    80006106:	c690                	sw	a2,8(a3)
  if(write)
    80006108:	e40d19e3          	bnez	s10,80005f5a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000610c:	0001f697          	auipc	a3,0x1f
    80006110:	ef46b683          	ld	a3,-268(a3) # 80025000 <disk+0x2000>
    80006114:	96ba                	add	a3,a3,a4
    80006116:	4609                	li	a2,2
    80006118:	00c69623          	sh	a2,12(a3)
    8000611c:	b5b1                	j	80005f68 <virtio_disk_rw+0xd2>

000000008000611e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000611e:	1101                	addi	sp,sp,-32
    80006120:	ec06                	sd	ra,24(sp)
    80006122:	e822                	sd	s0,16(sp)
    80006124:	e426                	sd	s1,8(sp)
    80006126:	e04a                	sd	s2,0(sp)
    80006128:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000612a:	0001f517          	auipc	a0,0x1f
    8000612e:	ffe50513          	addi	a0,a0,-2 # 80025128 <disk+0x2128>
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	a90080e7          	jalr	-1392(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000613a:	10001737          	lui	a4,0x10001
    8000613e:	533c                	lw	a5,96(a4)
    80006140:	8b8d                	andi	a5,a5,3
    80006142:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006144:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006148:	0001f797          	auipc	a5,0x1f
    8000614c:	eb878793          	addi	a5,a5,-328 # 80025000 <disk+0x2000>
    80006150:	6b94                	ld	a3,16(a5)
    80006152:	0207d703          	lhu	a4,32(a5)
    80006156:	0026d783          	lhu	a5,2(a3)
    8000615a:	06f70163          	beq	a4,a5,800061bc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000615e:	0001d917          	auipc	s2,0x1d
    80006162:	ea290913          	addi	s2,s2,-350 # 80023000 <disk>
    80006166:	0001f497          	auipc	s1,0x1f
    8000616a:	e9a48493          	addi	s1,s1,-358 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000616e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006172:	6898                	ld	a4,16(s1)
    80006174:	0204d783          	lhu	a5,32(s1)
    80006178:	8b9d                	andi	a5,a5,7
    8000617a:	078e                	slli	a5,a5,0x3
    8000617c:	97ba                	add	a5,a5,a4
    8000617e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006180:	20078713          	addi	a4,a5,512
    80006184:	0712                	slli	a4,a4,0x4
    80006186:	974a                	add	a4,a4,s2
    80006188:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000618c:	e731                	bnez	a4,800061d8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000618e:	20078793          	addi	a5,a5,512
    80006192:	0792                	slli	a5,a5,0x4
    80006194:	97ca                	add	a5,a5,s2
    80006196:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006198:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000619c:	ffffc097          	auipc	ra,0xffffc
    800061a0:	06a080e7          	jalr	106(ra) # 80002206 <wakeup>

    disk.used_idx += 1;
    800061a4:	0204d783          	lhu	a5,32(s1)
    800061a8:	2785                	addiw	a5,a5,1
    800061aa:	17c2                	slli	a5,a5,0x30
    800061ac:	93c1                	srli	a5,a5,0x30
    800061ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061b2:	6898                	ld	a4,16(s1)
    800061b4:	00275703          	lhu	a4,2(a4)
    800061b8:	faf71be3          	bne	a4,a5,8000616e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061bc:	0001f517          	auipc	a0,0x1f
    800061c0:	f6c50513          	addi	a0,a0,-148 # 80025128 <disk+0x2128>
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	ab2080e7          	jalr	-1358(ra) # 80000c76 <release>
}
    800061cc:	60e2                	ld	ra,24(sp)
    800061ce:	6442                	ld	s0,16(sp)
    800061d0:	64a2                	ld	s1,8(sp)
    800061d2:	6902                	ld	s2,0(sp)
    800061d4:	6105                	addi	sp,sp,32
    800061d6:	8082                	ret
      panic("virtio_disk_intr status");
    800061d8:	00002517          	auipc	a0,0x2
    800061dc:	61050513          	addi	a0,a0,1552 # 800087e8 <syscalls+0x3b8>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	34a080e7          	jalr	842(ra) # 8000052a <panic>
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
