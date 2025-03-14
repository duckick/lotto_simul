import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import '../controllers/lotto_ticket_controller.dart';
import '../widgets/mini_lotto_ticket_widget.dart';

// 날아가는 아이콘 애니메이션 위젯
class FloatingIconAnimation extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Offset startPosition;
  final Function? onComplete;

  const FloatingIconAnimation({
    Key? key,
    required this.icon,
    required this.color,
    this.size = 24.0,
    required this.startPosition,
    this.onComplete,
  }) : super(key: key);

  @override
  State<FloatingIconAnimation> createState() => _FloatingIconAnimationState();
}

class _FloatingIconAnimationState extends State<FloatingIconAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 애니메이션이 끝나면 콜백 호출
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    });

    // 불투명도 애니메이션 (1.0 -> 0.0)
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    // 크기 애니메이션 (1.0 -> 1.5)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // 랜덤 방향으로 날아가는 위치 애니메이션
    final random = math.Random();
    final endOffset = Offset(
      random.nextDouble() * 1.2 - 0.6, // -0.6 ~ 0.6
      -1.0 - random.nextDouble() * 0.5, // -1.0 ~ -1.5 (위쪽으로)
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    // 애니메이션 시작
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx + _positionAnimation.value.dx * 40,
          top: widget.startPosition.dy + _positionAnimation.value.dy * 40,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                widget.icon,
                color: widget.color,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}

/////////////////////////////////

// 눌림 효과가 있는 버튼 위젯
class PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scaleDownTo;
  final Duration duration;

  const PressableButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.scaleDownTo = 0.95,
    this.duration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDownTo : 1.0,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}

/////////////////////////////////////////////////////////////

class PlayPage extends StatefulWidget {
  const PlayPage({Key? key}) : super(key: key);

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage>
    with SingleTickerProviderStateMixin {
  final List<FloatingIconAnimation> _floatingIcons = [];
  final GlobalKey _purchaseButtonKey = GlobalKey();

  // 이전 날짜를 저장할 변수 추가
  DateTime? _previousDate;

  @override
  void initState() {
    super.initState();
    _previousDate = Get.find<LottoTicketController>().currentDate.value;
  }

  // 구매하기 버튼의 위치를 얻는 메서드
  Offset _getPurchaseButtonPosition() {
    final renderBox =
        _purchaseButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    // 버튼 중앙 위치 계산
    return Offset(buttonPosition.dx + renderBox.size.width / 2,
        buttonPosition.dy + renderBox.size.height / 2);
  }

  // 날아가는 아이콘 추가 메서드
  void _addFloatingIcons(int count) {
    if (count <= 0) return;

    final startPos = _getPurchaseButtonPosition();

    // 아이콘 여러개 생성
    for (int i = 0; i < count; i++) {
      // 약간의 딜레이를 둬서 순차적으로 나타나게 함
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (!mounted) return;

        setState(() {
          _floatingIcons.add(
            FloatingIconAnimation(
              icon: Icons.attach_money,
              color: Colors.green,
              size: 30.0,
              startPosition: startPos,
              onComplete: () {
                if (mounted) {
                  setState(() {
                    _floatingIcons.removeAt(0);
                  });
                }
              },
            ),
          );
        });
      });
    }
  }

  String _getKoreanWeekday(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  // 로또 볼 위젯
  Widget _buildLottoBall(int number, bool isBonus, {double size = 32}) {
    Color ballColor;

    if (number <= 10) {
      ballColor = Colors.yellow.shade600;
    } else if (number <= 20) {
      ballColor = Colors.blue.shade600;
    } else if (number <= 30) {
      ballColor = Colors.red.shade600;
    } else if (number <= 40) {
      ballColor = Colors.grey.shade700;
    } else {
      ballColor = Colors.green.shade600;
    }

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: ballColor,
        shape: BoxShape.circle,
        border: isBonus ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }

  // 등수별 색상
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.orange.shade700;
      case 3:
        return Colors.amber.shade700;
      case 4:
        return Colors.green.shade700;
      case 5:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // 티켓 수에 따른 아이콘 개수 계산 함수 추가
  int _calculateIconCount(int ticketCount) {
    if (ticketCount <= 4) return 1;
    if (ticketCount <= 8) return 2;
    if (ticketCount <= 12) return 3;
    if (ticketCount <= 16) return 4;
    return 5; // 20장 이하 (최대)
  }

  // 커스텀 슬라이드 애니메이션 위젯
  Widget _buildSlidingGridView(LottoTicketController controller) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 새 위젯이 들어올 때는 오른쪽에서, 나갈 때는 왼쪽으로
        final inAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));

        final outAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0.0),
        ).animate(CurvedAnimation(
          parent: ReverseAnimation(animation),
          curve: Curves.easeOut,
        ));

        if (child.key ==
            ValueKey<String>(controller.currentDate.value.toString())) {
          // 새 위젯이 들어올 때
          return ClipRect(
            child: SlideTransition(
              position: inAnimation,
              child: child,
            ),
          );
        } else {
          // 기존 위젯이 나갈 때
          return ClipRect(
            child: SlideTransition(
              position: outAnimation,
              child: child,
            ),
          );
        }
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
          alignment: Alignment.center,
        );
      },
      child: Container(
        key: ValueKey<String>(controller.currentDate.value.toString()),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: controller.tickets.length,
          itemBuilder: (context, index) {
            return MiniLottoTicketWidget(index: index);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LottoTicketController>();

    // 날짜 저장 (날짜 변경 감지용)
    _previousDate = controller.currentDate.value;

    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 버튼을 누르면 StartPage로 이동
        Get.offAllNamed('/');
        return false; // 기본 뒤로가기 동작 방지
      },
      child: Stack(
        children: [
          Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue.shade200,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() {
                          final date = controller.currentDate.value;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat('yyyy년 MM월 dd일').format(date)} (${_getKoreanWeekday(date)})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              //일반회차
                              // Text(
                              //   controller.getCurrentRoundString(),
                              //   style: TextStyle(
                              //     fontSize: 12,
                              //     color: Colors.grey,
                              //   ),
                              // ),
                            ],
                          );
                        }),
                        Row(
                          children: [
                            // 통계 버튼
                            PressableButton(
                              onPressed: () => controller.goToStatsPage(),
                              scaleDownTo: 0.9,
                              child: Icon(
                                Icons.bar_chart,
                                color: Colors.black54,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 보유금액
                            Obx(() => AnimatedFlipCounter(
                                  value: controller.seedMoney.value,
                                  prefix: '₩',
                                  thousandSeparator: ',',
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 상단 요약 정보
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final totalAmount = controller.tickets
                                .fold(0, (sum, ticket) => sum + ticket.amount);
                            return Container(
                              height: 65, // 56 + 9 = 65픽셀로 높이 증가
                              child: Card(
                                margin: EdgeInsets.zero,
                                elevation: 0, // 그림자 제거
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(4), // 각진 모서리
                                  side: BorderSide(
                                    color: Colors.blue.shade100,
                                    width: 1,
                                  ),
                                ),
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(11.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('총 구매금액',
                                          style: TextStyle(fontSize: 12)),
                                      Text(
                                        '₩${NumberFormat('#,###').format(totalAmount)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() {
                            return PressableButton(
                              onPressed: () {
                                controller.addNewTicket();
                              },
                              child: Container(
                                height: 65, // 56 + 9 = 65픽셀로 높이 증가
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0, // 그림자 제거
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(4), // 각진 모서리
                                    side: BorderSide(
                                      color: Colors.green.shade100,
                                      width: 1,
                                    ),
                                  ),
                                  color: Colors.green.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(11.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('총 티켓수',
                                                style: TextStyle(fontSize: 12)),
                                            Text(
                                              '${controller.tickets.length}장',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // 로또 추가 아이콘 표시
                                        Icon(
                                          Icons.add_circle,
                                          color: Colors.green.shade700,
                                          size: 28,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  // 미니 로또 티켓 그리드(미니로또 위젯 배치됨)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Obx(() {
                        if (controller.tickets.isEmpty) {
                          return const Center(
                            child: Text('로또 티켓이 없습니다. + 버튼을 눌러 티켓을 추가하세요.'),
                          );
                        }

                        // 슬라이드 애니메이션 위젯 사용
                        return _buildSlidingGridView(controller);
                      }),
                    ),
                  ),

                  // 하단 버튼 영역
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      // 그림자 제거
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PressableButton(
                            onPressed: () {
                              // 이미 스낵바가 표시 중인지 확인
                              if (Get.isSnackbarOpen) {
                                return; // 이미 스낵바가 열려있으면 추가 스낵바를 표시하지 않음
                              }

                              // 다이얼로그 없이 바로 모든 티켓의 빈 칸을 자동으로 채우기
                              for (int ticketIndex = 0;
                                  ticketIndex < controller.tickets.length;
                                  ticketIndex++) {
                                final ticket = controller.tickets[ticketIndex];
                                for (final row in ticket.lottoRows) {
                                  // 빈 칸이면 자동 생성
                                  if (!row.numbers.any((num) => num > 0)) {
                                    controller.generateAutoNumbers(
                                      ticketIndex: ticketIndex,
                                      rowName: row.rowName,
                                    );
                                  }
                                }
                              }
                            },
                            child: OutlinedButton.icon(
                              onPressed:
                                  null, // 실제 onPressed는 PressableButton에서 처리
                              icon: const Icon(Icons.flash_on),
                              label: const Text('일괄 자동'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                disabledForegroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.black26),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() {
                            // 추첨일(토요일) 여부 확인
                            final isDrawDay = controller.isDrawDay.value;
                            // 구매 완료 여부 확인
                            final isPurchaseCompleted =
                                controller.purchaseCompleted.value;

                            // 총 구매금액 계산
                            final totalAmount = controller.tickets
                                .fold(0, (sum, ticket) => sum + ticket.amount);

                            // 총 구매금액이 0보다 크면 구매하기, 아니면 넘어가기
                            final canPurchase = totalAmount > 0;

                            // 항상 구매하기 또는 넘어가기 버튼만 표시 (결과 확인 버튼 제거)
                            return PressableButton(
                              onPressed: () {
                                // 이미 스낵바가 표시 중인지 확인
                                if (Get.isSnackbarOpen) {
                                  return; // 이미 스낵바가 열려있으면 추가 스낵바를 표시하지 않음
                                }

                                if (canPurchase) {
                                  // 구매하는 경우 애니메이션 효과 추가
                                  final ticketCount = controller.tickets.length;
                                  // 티켓 수에 따라 애니메이션 아이콘 개수 조절
                                  _addFloatingIcons(
                                      _calculateIconCount(ticketCount));

                                  // 구매 시도
                                  controller.tryPurchaseTickets();
                                  // 성공 여부는 tryPurchaseTickets 메소드 내에서 처리함
                                } else {
                                  // 총 구매금액이 0일 때는 다음 날로 넘어가기
                                  // 토요일(추첨일)인지와 이미 다이얼로그가 표시 중인지 확인
                                  final isDrawDay = controller.isDrawDay.value;
                                  final isDialogAlreadyShown =
                                      controller.shouldShowResult.value;

                                  if (isDrawDay && isDialogAlreadyShown) {
                                    // 이미 다이얼로그가 표시 중이라면 다음 날로 직접 이동
                                    controller.actuallyMoveToNextDay();
                                  } else {
                                    // 그 외의 경우는 일반적인 다음 날로 이동
                                    controller.moveToNextDay();
                                  }

                                  // 스낵바 주석 처리
                                  /*
                                  Get.snackbar(
                                    '다음 날로 이동',
                                    '다음 날로 이동했습니다.',
                                    backgroundColor: Colors.blue.shade100,
                                    borderRadius: 4, // 각진 모서리
                                    duration: const Duration(milliseconds: 300),
                                    animationDuration:
                                        const Duration(milliseconds: 0),
                                    snackPosition: SnackPosition.TOP,
                                    margin: const EdgeInsets.all(8),
                                  );
                                  */
                                }
                              },
                              child: ElevatedButton.icon(
                                key: canPurchase
                                    ? _purchaseButtonKey
                                    : null, // 구매 버튼에만 키 추가
                                onPressed:
                                    null, // 실제 onPressed는 PressableButton에서 처리
                                icon: Icon(canPurchase
                                    ? Icons.shopping_cart
                                    : Icons.arrow_forward),
                                label: Text(canPurchase ? '구매하기' : '넘어가기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      canPurchase ? Colors.blue : Colors.amber,
                                  disabledBackgroundColor:
                                      canPurchase ? Colors.blue : Colors.amber,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white,
                                  elevation: 0, // 그림자 제거
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(4), // 각진 모서리
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 날아가는 아이콘 애니메이션 표시
          ..._floatingIcons,
        ],
      ),
    );
  }
}
