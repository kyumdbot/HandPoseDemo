# Hand Pose Demo App for macOS


- 使用 AV Foundation 存取 Webcam。
- 使用 Vision framework 做手勢檢測。


## 手勢

![0](imgs/img00.png)
![1](imgs/img01.png)
![2](imgs/img02.png)
![3](imgs/img03.png)
![4](imgs/img04.png)
![5](imgs/img05.png)

## 思路說明

### Fingers 姿勢判斷：

我想到兩種方式來判斷四隻手指 (fingers) 的收放：

- 方式一：當手指節點`TIP`到手腕`Wrist`的距離 *與* 節點`DIP`到手腕`Wrist`的距離 *小於* 節點`MCP`到手腕`Wrist`的距離時，判斷為手指收起來，反之為張開。
- 方式二：比較手指各節點(`TIP`、`DIP`、`PIP`、`MCP`)到手腕`Wrist`的距離，當距離：TIPToWrist > DIPToWrist > PIPToWrist > MCPToWrist 時，手指判斷為張開，反之為收起來。

在這個 App 裡，我採用了方式一。


### Thumb 姿勢判斷：

判斷大拇指的收放，我想到的方式是：

1. 計算大拇指`TIP` (thumbTip) 到食指`MCP` (indexMCP) 的距離，與計算大拇指`TIP` (thumbTip) 到中指`MCP` (middleMCP) 的距離，然後比較這兩個距離，當 thumbTipToMiddleMCP < thumbTipToIndexMCP 時，也就是大拇指的指尖距離中指的尾端比較近時 (相對於食指尾端)，判定大拇指為收起來，反之為張開。
2. 計算大拇指`TIP` (thumbTip) 到手腕`Wrist`的距離，與計算大拇指`IP` (thumbIP) 到手腕`Wrist`的距離，然後比較這兩個距離，當 thumbTipToWrist < thumbIPToWrist 時，判定大拇指為收起來，反之為張開。

在這個 App 裡，我同時採用了`1.`、`2.`兩種方式。

## 其他

關於手指 (Fingers) 與大拇指 (Thumb) 各節點的位置與名稱，我擷取了 [Detect Body and Hand Pose with Vision](https://developer.apple.com/videos/play/wwdc2020/10653/) 這個 Session 的兩個畫面給各位參考：

![fingers](imgs/fingers.png)
![thumb](imgs/thumb.png)


想知道更多關於 iOS/macOS 手勢檢測的資訊，可參考 WWDC 2020 的影片：[Detect Body and Hand Pose with Vision](https://developer.apple.com/videos/play/wwdc2020/10653/)。


