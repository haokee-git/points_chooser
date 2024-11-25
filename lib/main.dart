import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    minimumSize: Size(640, 360),
    title: '分数选择器',
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '分数选择器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
              color: Color.fromARGB(255, 64, 64, 64),
              fontSize: 20,
              fontFamily: 'PingFang SC'),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int counter = 0;
  final TextEditingController counterController = TextEditingController();
  List<int> randomNumbers = [];
  bool choose = true;
  int selectedBullet = 2;
  bool useRussia = false;
  bool useLine = false;
  String resultText = '总分数：无';
  Color appBarBackgroundColor = const Color.fromARGB(255, 232, 223, 238);
  String orignalPoint = '原始得分：无';
  String russia = '俄罗斯转盘得分：无';
  String resultLine = '宇宙射线得分：无';
  bool calculate = true;

  // Convert number to Roman numeral
  String roman(int number) {
    if (number < 1 || number > 3999) {
      return "Invalid number";
    }

    List<int> values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    List<String> numerals = [
      "M",
      "CM",
      "D",
      "CD",
      "C",
      "XC",
      "L",
      "XL",
      "X",
      "IX",
      "V",
      "IV",
      "I"
    ];

    String result = "";
    for (int i = 0; i < values.length; i++) {
      while (number >= values[i]) {
        number -= values[i];
        result += numerals[i];
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    counterController.text = counter.toString();
  }

  // Increment counter
  void incrementCounter() {
    setState(() {
      counter++;
      counterController.text = counter.toString();
    });
  }

  // Decrement counter
  void decrementCounter() {
    if (counter == 0) {
      return;
    }
    setState(() {
      counter--;
      counterController.text = counter.toString();
    });
  }

  // Generate random numbers
  void generateRandomNumbers() async {
    if (!choose) {
      return;
    }
    setState(() {
      choose = false;
    });
    var randomList =
        List<int>.generate(counter, (index) => Random().nextInt(10) + 1);
    int sum = 0;
    setState(() {
      resultText = '总分数：无';
    });
    for (int i = 0; i < randomList.length; i++) {
      List<int> list = [];
      for (int j = 0; j <= i; j++) {
        list.add(randomList[j]);
      }
      sum += randomList[i];
      setState(() {
        orignalPoint = '原始得分：$sum';
        randomNumbers = list;
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }
    choose = true;
  }

  void onPanStart(details) {
    windowManager.startDragging();
  }

  void onMinimize() {
    windowManager.minimize();
  }

  void onMaximize() {
    windowManager.isMaximized().then((isMaximized) {
      if (isMaximized) {
        windowManager.unmaximize();
      } else {
        windowManager.maximize();
      }
    });
  }

  void onClose() {
    windowManager.close();
  }

  void onSwitchChanged(bool value) {
    setState(() {
      useRussia = value;
    });
  }

  void onBulletTap(int index) {
    setState(() {
      selectedBullet = index;
    });
  }

  void onLeftArrowPressed() {
    setState(() {
      if (selectedBullet > 0) {
        selectedBullet--;
      }
    });
  }

  void onRightArrowPressed() {
    setState(() {
      if (selectedBullet < 4) {
        selectedBullet++;
      }
    });
  }

  void onSettlePressed() async {
    int sum = randomNumbers.fold(0, (a, b) => a + b);
    if (sum == 0) {
      setState(() {
        resultText = '总分数：无';
      });
      return;
    }
    if (!calculate) {
      return;
    }
    setState(() {
      calculate = false;
    });
    int extra = 0;
    if (useRussia) {
      int bullet = Random().nextInt(5);
      if (bullet == 0 || bullet == 4) {
        setState(() {
          appBarBackgroundColor = Colors.black;
          resultText = '总分数: 0';
          russia = '俄罗斯转盘得分：${-sum}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('你被子弹击中'),
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        for (double i = 0; i <= 1; i += 0.01) {
          setState(() {
            appBarBackgroundColor = Color.lerp(
                Colors.black, const Color.fromARGB(255, 232, 223, 238), i)!;
          });
          await Future.delayed(const Duration(milliseconds: 10));
        }
        await Future.delayed(const Duration(seconds: 1));
        extra = -sum;
        sum = 0;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                '你被空包弹击中，万幸',
                style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
              ),
              backgroundColor: Color.fromARGB(255, 232, 223, 238),
              duration: Duration(seconds: 1)),
        );
        await Future.delayed(const Duration(seconds: 1));
        extra = sum;
        sum *= 2;
      }
    }
    setState(() {
      russia = '俄罗斯转盘得分：${extra != 0 ? extra : '无'}';
    });
    int line = 0;
    if (useLine) {
      if (Random().nextInt(10) == 0) {
        line = -sum;
        sum = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('你被宇宙射线击中'),
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        for (double i = 0; i <= 1; i += 0.01) {
          setState(() {
            appBarBackgroundColor = Color.lerp(
                Colors.black, const Color.fromARGB(255, 232, 223, 238), i)!;
          });
          await Future.delayed(const Duration(milliseconds: 10));
        }
        await Future.delayed(const Duration(seconds: 1));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                '你未被宇宙射线击中，万幸',
                style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
              ),
              backgroundColor: Color.fromARGB(255, 232, 223, 238),
              duration: Duration(seconds: 1)),
        );
        await Future.delayed(const Duration(seconds: 1));
        line = Random().nextInt(5) + 1;
        sum += line;
      }
    }
    setState(() {
      calculate = true;
      resultText = '总分数：$sum';
      resultLine = '宇宙射线得分：${line != 0 ? line : '无'}';
    });
  }

  ListTile buildItem(BuildContext context, int index) {
    int x = randomNumbers[index];
    String prefix;
    Color color = Colors.black;
    Row row;
    String msg = '';
    if (x <= 5) {
      prefix = '三星：';
      color = Colors.blue;
      row = const Row(children: [
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18)
      ]);
      msg = '三星：I 至 V 分';
    } else if (x <= 9) {
      prefix = '四星：';
      color = Colors.purple;
      row = const Row(children: [
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18)
      ]);
      msg = '四星：VI 至 IX 分';
    } else {
      prefix = '五星：';
      color = const Color.fromARGB(255, 214, 193, 0);
      row = const Row(children: [
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18),
        Icon(Icons.star, color: Color.fromARGB(255, 243, 219, 0), size: 18)
      ]);
      msg = '五星：X 分';
    }
    return ListTile(
      title: Row(
        children: [
          Tooltip(
            message: msg,
            waitDuration: const Duration(milliseconds: 500),
            child: row,
          ),
          const Spacer(),
          Tooltip(
            message: msg,
            waitDuration: const Duration(milliseconds: 500),
            child: Text(prefix, style: TextStyle(color: color)),
          ),
          Tooltip(
            message: '$x 分',
            waitDuration: const Duration(milliseconds: 500),
            child: Text(roman(x)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 0.5),
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: GestureDetector(
            onPanStart: onPanStart,
            child: AppBar(
              title: const Text('分数选择器'),
              backgroundColor: appBarBackgroundColor,
              actions: [
                Tooltip(
                  message: '最小化窗口',
                  waitDuration: const Duration(milliseconds: 500),
                  child: IconButton(
                    icon: const Icon(Icons.remove, color: Colors.blue),
                    onPressed: onMinimize,
                  ),
                ),
                Tooltip(
                  message: '最大化/正常显示窗口',
                  waitDuration: const Duration(milliseconds: 500),
                  child: IconButton(
                    icon: const Icon(Icons.crop_square, color: Colors.blue),
                    onPressed: onMaximize,
                  ),
                ),
                Tooltip(
                  message: '关闭窗口',
                  waitDuration: const Duration(milliseconds: 500),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.blue),
                    onPressed: onClose,
                  ),
                )
              ],
            ),
          ),
        ),
        body: Row(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('抽选次数: '),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: '减少抽取次数',
                          waitDuration: const Duration(milliseconds: 500),
                          child: IconButton(
                            icon: const Icon(Icons.remove, color: Colors.blue),
                            onPressed: decrementCounter,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$counter',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: '增大抽取次数',
                          waitDuration: const Duration(milliseconds: 500),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: incrementCounter,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Tooltip(
                      message: '以规定次数开始抽取',
                      waitDuration: const Duration(milliseconds: 500),
                      child: ElevatedButton.icon(
                        onPressed: generateRandomNumbers,
                        icon: const Icon(Icons.handshake, color: Colors.blue),
                        label: const Text('抽取',
                            style: TextStyle(color: Colors.blue)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue[100],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 300,
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 252, 240, 255),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemExtent: 35.0,
                          itemCount: randomNumbers.length,
                          itemBuilder: buildItem),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gavel, color: Colors.blue, size: 18),
                        const SizedBox(width: 5),
                        const Text("俄罗斯轮盘赌"),
                        Transform.scale(
                          scale: 0.6,
                          child: Tooltip(
                            message: '五个中有两个是子弹，三个是空包弹，碰到子弹分数清零，碰到空包弹分数翻倍',
                            waitDuration: const Duration(milliseconds: 500),
                            child: Switch(
                              value: useRussia,
                              onChanged: onSwitchChanged,
                              activeColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => onBulletTap(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            width: selectedBullet == index ? 20.0 : 15.0,
                            height: selectedBullet == index ? 20.0 : 15.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedBullet == index
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: '选择上一颗弹药',
                          waitDuration: const Duration(milliseconds: 500),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_left),
                            onPressed: onLeftArrowPressed,
                          ),
                        ),
                        Tooltip(
                          message: '选择下一颗弹药',
                          waitDuration: const Duration(milliseconds: 500),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_right),
                            onPressed: onRightArrowPressed,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 5),
                        const Text("启用宇宙射线"),
                        Transform.scale(
                          scale: 0.6,
                          child: Tooltip(
                            message: '启用宇宙射线会有一定概率失去所有分数，但是除次之外均会增加额外的随机分数',
                            waitDuration: const Duration(milliseconds: 500),
                            child: Switch(
                              value:
                                  useLine, // You might want to create a new variable for this switch
                              onChanged: (bool value) {
                                setState(() {
                                  useLine =
                                      value; // Update the variable accordingly
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Tooltip(
                      message: '在原始得分的基础上给定附加游戏进行计算',
                      waitDuration: const Duration(milliseconds: 500),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment, color: Colors.blue),
                        label: const Text('结算',
                            style: TextStyle(color: Colors.blue)),
                        onPressed: onSettlePressed,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue[100]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(orignalPoint),
                    const SizedBox(height: 5),
                    Text(russia),
                    const SizedBox(height: 5),
                    Text(resultLine),
                    const SizedBox(height: 5),
                    Text(resultText)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
