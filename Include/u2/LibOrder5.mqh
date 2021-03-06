//LibOrder5.mqh
//MQL5用オーダー関連ライブラリ
//u2
/*
#property copyright "Copyright (c) 2019, Toyolab FX"
#property link      "http://forex.toyolab.com/"
#property version   "210.110"
*/

//オーダータイプの拡張
#define ORDER_TYPE_NONE -1
#define OP_NONE ORDER_TYPE_NONE
#define OP_BUY ORDER_TYPE_BUY
#define OP_SELL ORDER_TYPE_SELL
#define OP_BUYLIMIT ORDER_TYPE_BUY_LIMIT
#define OP_SELLLIMIT ORDER_TYPE_SELL_LIMIT
#define OP_BUYSTOP ORDER_TYPE_BUY_STOP
#define OP_SELLSTOP ORDER_TYPE_SELL_STOP

//プールタイプの列挙型定数
enum ENUM_POOL_TYPE
{
   POOL_NONE,
   POOL_POSITION,
   POOL_ORDER
};

//MQL4互換ライブラリ
#include "LibMQL4.mqh"

//OrderSend()後のsleep時間（ms）
int OrderSendSleep = 5;

//Bid・Askの更新
bool RefreshPrice(double &bid, double &ask, int pos_id = -1)
{
   MqlTick tick;
   string symbol = _Symbol;
   if(pos_id >= 0) symbol = TradeSymbol[pos_id];
   if(!SymbolInfoTick(symbol, tick)) return false;
   if(tick.bid <= 0 || tick.ask <= 0) return false;
   bid = tick.bid;
   ask = tick.ask;
   return true;
}

//フィリングモードの取得
ENUM_ORDER_TYPE_FILLING OrderFilling(int i)
{
   long filling_mode = SymbolInfoInteger(TradeSymbol[i], SYMBOL_FILLING_MODE);
   if(filling_mode%2 != 0) return ORDER_FILLING_FOK;
   else if(filling_mode%4 != 0) return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
}

//注文の送信
bool MyOrderSend(ENUM_ORDER_TYPE type, double lots, double price=0, int pos_id=0)
{
   if(!CheckPosID(pos_id)) return false;  //ポジション番号のチェック

   price = NormalizeDouble(price, _Digits);
   bool ret = false;
   switch(type)
   {
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL:
         ret = OrderSendMarket(type, lots, pos_id);
         break;
      case ORDER_TYPE_BUY_STOP:
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_SELL_STOP:
      case ORDER_TYPE_SELL_LIMIT:
         ret = OrderSendPending(type, lots, price, pos_id);
         break;
      default:
         Print("MyOrderSend : Unsupported type");
         break;
   }
   return ret;
}

//成行注文
bool OrderSendMarket(ENUM_ORDER_TYPE type, double lots, int i)
{
   if(MyOrderType(i) != ORDER_TYPE_NONE) return true;
   // for no position or order
   MqlTradeRequest request={};
   MqlTradeResult result={}; 
   // refresh rate
   double bid, ask;
   RefreshPrice(bid, ask, i);

   //発注したときのインディケーターの数値を知りたい
   double BB_UPPER1 = iBands(_Symbol, PERIOD_M30, 20, InpBBDeviation, 0, PRICE_CLOSE, MODE_UPPER,1);
   double BB_LOWER1 = iBands(_Symbol, PERIOD_M30, 20, InpBBDeviation, 0, PRICE_CLOSE, MODE_LOWER,1);
   double ExtChannelRange1 = BB_UPPER1 - BB_LOWER1;
   int ExtChannelRange10 = (int)PriceToPips(ExtChannelRange1);
   double BB_UPPER2 = iBands(_Symbol, PERIOD_H1, 20, InpBBDeviation, 0, PRICE_CLOSE, MODE_UPPER,1);
   double BB_LOWER2 = iBands(_Symbol, PERIOD_H1, 20, InpBBDeviation, 0, PRICE_CLOSE, MODE_LOWER,1);
   double ExtChannelRange2 = BB_UPPER2 - BB_LOWER2;
   int ExtChannelRange20 = (int)PriceToPips(ExtChannelRange2);
   double BB_UPPER3 = iBands(_Symbol, PERIOD_H4, 20, InpBBDeviation, 0, PRICE_CLOSE, MODE_UPPER,1);
   double BB_LOWER3 = iBands(_Symbol, PERIOD_H4, 20, InpBBDeviation, 0, PRICE_CLOSE, MODE_LOWER,1);
   double ExtChannelRange3 = BB_UPPER3 - BB_LOWER3;
   int ExtChannelRange30 = (int)PriceToPips(ExtChannelRange3);

   // order request
   if(type == ORDER_TYPE_BUY) request.price = ask;
   if(type == ORDER_TYPE_SELL) request.price = bid;
   request.action = TRADE_ACTION_DEAL;
   request.symbol = TradeSymbol[i];
   request.volume = lots;
   request.deviation = Slippage;
   request.type = type;
   request.type_filling = OrderFilling(i);
   request.magic = MagicNumber[i];
   request.comment = "[注]"+MagicToComment(request.magic)+"A"+(string)ExtChannelRange10+"  B"+(string)ExtChannelRange20+"  C"+(string)ExtChannelRange30;                                                ;
   bool b = OrderSend(request,result);
   Sleep(OrderSendSleep);
   // order completed
   if(result.retcode != TRADE_RETCODE_DONE)
   {
      Print("MyOrderSendMarket : ", result.retcode, " ", RetcodeDescription(result.retcode));
      return false;
   }
   return true;
}

//待機注文
bool OrderSendPending(ENUM_ORDER_TYPE type, double lots, double price, int i)
{
   if(MyOrderType(i) != ORDER_TYPE_NONE) return true;
   // for no open position
   MqlTradeRequest request={};
   MqlTradeResult result={}; 
   // order request
   request.action = TRADE_ACTION_PENDING;
   request.symbol = TradeSymbol[i];
   request.volume = lots;
   request.type = type;
   request.price = price;
   request.type_filling = OrderFilling(i);
   request.type_time = ORDER_TIME_GTC;
   request.magic = MagicNumber[i];
   request.comment = "[in]"+MagicToComment(request.magic)+"待機";
   bool b = OrderSend(request,result);
   Sleep(OrderSendSleep);
   // order completed
   if(result.retcode != TRADE_RETCODE_DONE)
   {
      Print("MyOrderSendPending : ", result.retcode, " ", RetcodeDescription(result.retcode));
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//|【関数】ポジションの決済                                             
//|                                                                  
//|【引数】 IN OUT  引数名             説明                               
//|        --------------------------------------------------------- 
//|         ○      pos_ id　　　　　　　　ポジション番号
//|【戻値】false: ポジション 決済 失敗、 true: それ 以外                                      
//|                                                                  
//|【備考】                                                   
//+------------------------------------------------------------------+
//ポジションの決済
//ポジション番号ごとに注文状況をチェックし、オープンポジションがない場合には決済注文の送信は行いません。実際に注文を送信してエラーが発生した場合のみ「false」を返し、エラーメッセージを出力します。
//ORDER_TYPE_BUY … 買いの成行注文
//ORDER_TYPE_SELL … 売り成行注文
//ORDER_TYPE_BUY_STOP … 買いの逆指値注文（つまり、上抜けブレーク時に成行買い）
//ORDER_TYPE_SELL_STOP … 売りの逆指値注文（つまり、下抜けのブレーク時に成行売り）
//ORDER_TYPE_BUY_LIMIT … 買いの指値注文（つまり、安くなったら成行買い）
//ORDER_TYPE_SELL_LIMIT … 売りの指値注文（つまり、高くなったら成行売り）
//ORDER_TYPE_BUY_STOP_LIMIT … 買いのストップ・リミット注文（つまり、上抜けブレーク時に指値買い注文）
//ORDER_TYPE_SELL_STOP_LIMIT … 売りのストップ・リミット注文（つまり、下抜けブレーク時に指値売り注文）
//ORDER_TYPE_CLOSE_BY … 反対方向のポジションを相殺する注文
bool MyOrderClose(int pos_id=0)
{
   if(!CheckPosID(pos_id)) return false;  //ポジション番号のチェック　ポジションはあるか、最大ポジション数は超えていないか　問題なければtrueが戻り値になるが!でその逆の場合としている
   if(MyOrderOpenLots(pos_id) == 0) return true; //買いポジションはプラス 売りポジションはマイナス
   //コメント追加
   if(pos_id == 0){
      closecomment = "  B" + IntegerToString(maxpips0)+"  C"+IntegerToString(minpips0)+"  /0"; 
   }
   if(pos_id == 1){
      closecomment = "  B" + IntegerToString(maxpips1)+"  C"+IntegerToString(minpips1)+"  /1"; 
   }
   if(pos_id == 2){
      closecomment = "  B" + IntegerToString(maxpips2)+"  C"+IntegerToString(minpips2)+"  /2"; 
   }
   if(pos_id == 3){
      closecomment = "  B" + IntegerToString(maxpips3)+"  C"+IntegerToString(minpips3)+"  /3"; 
   }
   if(pos_id == 4){
      closecomment = "  B" + IntegerToString(maxpips4)+"  C"+IntegerToString(minpips4)+"  /4"; 
   }
   if(pos_id == 5){
      closecomment = "  B" + IntegerToString(maxpips5)+"  C"+IntegerToString(minpips5)+"  /"; 
   }
   // for open position
   MqlTradeRequest request={};
   MqlTradeResult result={}; 
   // refresh rate
   double bid, ask;
   RefreshPrice(bid, ask, pos_id);
   // order request
   if(MyOrderType(pos_id) == ORDER_TYPE_BUY)
   {
      request.type = ORDER_TYPE_SELL;
      request.price = bid;
   }
   if(MyOrderType(pos_id) == ORDER_TYPE_SELL)
   {
      request.type = ORDER_TYPE_BUY;
      request.price = ask;
   }
   request.action = TRADE_ACTION_DEAL;   //成行き注文をだします
   request.symbol = TradeSymbol[pos_id];
   request.deviation = Slippage;         // 最大許容スリッページ（ポイント）price 引数で指定した価格からの許容スリッページ（ポイント数）を指定します。
                                         // ブローカーの注文執行方式が、Instant execution あるいは Request execution のときのみ有効です。 
                                         // 注文後に許容スリッページ以上の価格変化があった場合、ブローカーからリクオート（約定拒否）されます。
   request.volume = MyOrderLots(pos_id);
   request.position = MyOrderTicket(pos_id);
   request.type_filling = OrderFilling(pos_id); //type売買の種類　type_filling　フィルタイプ　type_time　有効期限タイプ
       //注文時に指定したロット数（volume 引数）が一度に約定させられない場合にどう処理するかを指定します。
       //ORDER_FILLING_FOK (0) … Fill or Kill. 全約定できなければ全ロットをキャンセル。      
       //ORDER_FILLING_IOC (1) … Immediate or Cancel. できるだけ約定させ、残りをキャンセル。
       //ORDER_FILLING_RETURN (2) … Return. 取引サーバー側で全約定するまで市場に注文を出し続ける。

       //IME type_time
       //ORDER_TIME_GTC (0) … Good till canceled. 待機注文の有効期限を設定しません（明示的にキャンセルされるまで有効です）
       //ORDER_TIME_DAY (1) … 待機注文はその日の間だけ有効です。
       //ORDER_TIME_SPECIFIED (2) … 待機注文は datetime 引数で指定した日時まで有効です。
       //ORDER_TIME_SPECIFIED_DAY (3) … 待機注文は datetime 引数で指定した日が終わるまで有効です（23:59:59 あるいはその日の最終取引時刻までです）。

   request.magic = MagicNumber[pos_id];
   request.comment = "[済]"+MagicToComment(request.magic)+"A"+(string)profitpips + closecomment;
   bool b = OrderSend(request,result);
   Sleep(OrderSendSleep);
   // order completed
   if(result.retcode != TRADE_RETCODE_DONE)
   {
      Print("MyOrderClose : ", result.retcode, " ", RetcodeDescription(result.retcode));
      return false;
   }
   return true;
}

//待機注文のキャンセル
bool MyOrderDelete(int pos_id=0)
{
   if(!CheckPosID(pos_id)) return false;  //ポジション番号のチェック

   if(MyOrderOpenLots(pos_id) != 0 || MyOrderType(pos_id) == ORDER_TYPE_NONE) return true;
   // for pending order
   MqlTradeRequest request={};
   MqlTradeResult result={}; 
   // order request
   request.action = TRADE_ACTION_REMOVE;
   request.order = MyOrderTicket(pos_id);
   bool b = OrderSend(request,result);
   Sleep(OrderSendSleep);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE) return true;
   // order error
   else
   {
      Print("MyOrderDelete : ", result.retcode, " ", RetcodeDescription(result.retcode));
      return false;
   }
   return true;
}

//注文の変更
bool MyOrderModify(double price, double sl, double tp, int pos_id=0)
{
   if(!CheckPosID(pos_id)) return false;  //ポジション番号のチェック

   bool ret = true;
   price = NormalizeDouble(price, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   switch(MyOrderSelect(pos_id))
   {
   // for open position
      case POOL_POSITION:
      ret = OrderModifySLTP(sl, tp, pos_id);
      break;      

   // for pending order
      case POOL_ORDER:
      ret = OrderModifyPending(price, sl, tp, 0, pos_id);
      break;
   }
   return ret;
}

//オープンポジションの変更
bool OrderModifySLTP(double sl, double tp, int pos_id=0)
{
   if(sl == 0) sl = MyOrderStopLoss(pos_id);    //ポジションの損切り値
   if(tp == 0) tp = MyOrderTakeProfit(pos_id);  //ポジションの利食い値

   //損切り値、利食い値の変更がない場合
   if(MyOrderStopLoss(pos_id) == sl && MyOrderTakeProfit(pos_id) == tp) return true;

   MqlTradeRequest request={};
   MqlTradeResult result={};
   // order request
   request.action = TRADE_ACTION_SLTP;
   request.symbol = TradeSymbol[pos_id];
   request.position = MyOrderTicket(pos_id);
   request.sl = sl;
   request.tp = tp;
   bool b = OrderSend(request,result);
   Sleep(OrderSendSleep);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE) return true;
   // order error
   else
   {
      Print("MyOrderModifySLTP : ", result.retcode, " ", RetcodeDescription(result.retcode));
      return false;
   }
   return true;
}

//待機注文の変更
bool OrderModifyPending(double price, double sl, double tp, datetime expiration, int pos_id=0)
{
   if(price == 0) price = MyOrderOpenPrice(pos_id); //待機注文の価格
   if(sl == 0) sl = MyOrderStopLoss(pos_id);    //待機注文の損切り値
   if(tp == 0) tp = MyOrderTakeProfit(pos_id);  //待機注文の利食い値
   if(expiration == 0) expiration = MyOrderExpiration(pos_id);  //待機注文の有効期限

   //価格、損切り値、利食い値、有効期限の変更がない場合
   if(MyOrderOpenPrice(pos_id) == price
      && MyOrderStopLoss(pos_id) == sl
      && MyOrderTakeProfit(pos_id) == tp
      && MyOrderExpiration(pos_id) == expiration) return true;

   MqlTradeRequest request={};
   MqlTradeResult result={};
   // order request
   request.action = TRADE_ACTION_MODIFY;
   request.symbol = TradeSymbol[pos_id];
   request.order = MyOrderTicket(pos_id);
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   if(expiration != 0)
   {
      request.type_time = ORDER_TIME_SPECIFIED;
      request.expiration = expiration;
   }
   else request.type_time = ORDER_TIME_GTC;
   bool b = OrderSend(request,result);
   Sleep(OrderSendSleep);
   // order completed
   if(result.retcode == TRADE_RETCODE_DONE) return true;
   // order error
   else
   {
      Print("MyOrderModifyPending : ", result.retcode, " ", RetcodeDescription(result.retcode));
      return false;
   }
   return true;
}

//待機注文の有効期限のセット
void MyOrderSetExpiration(datetime dt_ref, int hour, int min, int pos_id=0)
{
   if(MyOrderSelect(pos_id) == POOL_ORDER) OrderModifyPending(0, 0, 0, (dt_ref/60+hour*60+min)*60, pos_id);
}

//ポジションの選択
ENUM_POOL_TYPE MyOrderSelect(int pos_id=0)
{
   if(!CheckPosID(pos_id)) return POOL_NONE;  //ポジション番号のチェック

   for(int i=0; i<PositionsTotal(); i++)//オープンポジション
   {
      if(PositionGetSymbol(i) == TradeSymbol[pos_id]
         && PositionGetInteger(POSITION_MAGIC) == MagicNumber[pos_id]) return POOL_POSITION; //正常終了
   }
   for(int i=0; i<OrdersTotal(); i++)//待機注文
   {
      if(OrderGetTicket(i) > 0
         && OrderGetString(ORDER_SYMBOL) == TradeSymbol[pos_id]
         && OrderGetInteger(ORDER_MAGIC) == MagicNumber[pos_id]) return POOL_ORDER; //正常終了
   }
   return POOL_NONE; //ポジション選択なし
}

//チケット番号の取得
ulong MyOrderTicket(int pos_id=0)
{
   ulong ticket = 0;
   switch(MyOrderSelect(pos_id))
   {
      case POOL_POSITION:
      ticket = PositionGetInteger(POSITION_TICKET);
      break;
      
      case POOL_ORDER:
      ticket = OrderGetInteger(ORDER_TICKET);
      break;
   }
   return ticket;
}

//ポジション・注文種別の取得
ENUM_ORDER_TYPE MyOrderType(int pos_id=0)
{
   ENUM_ORDER_TYPE type = ORDER_TYPE_NONE;
   ENUM_POSITION_TYPE ptype;
   switch(MyOrderSelect(pos_id))
   {
      case POOL_POSITION:
      ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(ptype == POSITION_TYPE_BUY) type = ORDER_TYPE_BUY;
      if(ptype == POSITION_TYPE_SELL) type = ORDER_TYPE_SELL;
      break;
      
      case POOL_ORDER:
      type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      break;
   }
   return type;
}

//ポジション・注文のロット数の取得
double MyOrderLots(int pos_id=0)
{
   double lots = 0;
   switch(MyOrderSelect(pos_id))
   {
      case POOL_POSITION:
      lots = PositionGetDouble(POSITION_VOLUME);
      break;
      
      case POOL_ORDER:
      lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
      break;
   }
   return lots;
}

//ポジションの売買価格の取得
double MyOrderOpenPrice(int pos_id=0)
{
   double price = 0;
   switch(MyOrderSelect(pos_id))
   {
      case POOL_POSITION:
      price = PositionGetDouble(POSITION_PRICE_OPEN);
      break;
      
      case POOL_ORDER:
      price = OrderGetDouble(ORDER_PRICE_OPEN);
      break;
   }
   return price;
}

//ポジションの売買時刻の取得
datetime MyOrderOpenTime(int pos_id=0)
{
   datetime opentime = 0;
   switch(MyOrderSelect(pos_id))
   {
      case POOL_POSITION:
      opentime = (datetime)PositionGetInteger(POSITION_TIME);
      break;
      
      case POOL_ORDER:
      opentime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      break;
   }
   return opentime;
}

//オープンポジションの決済価格の取得
double MyOrderClosePrice(int pos_id=0)
{
   double bid, ask;
   RefreshPrice(bid, ask, pos_id);
   ENUM_ORDER_TYPE type = MyOrderType(pos_id);
   double price = 0;
   if(type == ORDER_TYPE_BUY
     || type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP) price = bid;
   if(type == ORDER_TYPE_SELL
     || type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_SELL_STOP) price = ask;
   return price;
}

//ポジションに付加された損切り価格の取得
double MyOrderStopLoss(int pos_id=0)
{
   double sl = 0;
   switch(MyOrderSelect(pos_id))
   {
      case POOL_POSITION:
      sl = PositionGetDouble(POSITION_SL);
      break;
      
      case POOL_ORDER:
      sl = OrderGetDouble(ORDER_SL);
      break;
   }
   return sl;
}

//ポジションに付加された利食い価格の取得
double MyOrderTakeProfit(int pos_id=0)
{
   double tp = 0;
   switch(MyOrderSelect(pos_id))
   {
      case POOL_POSITION:
      tp = PositionGetDouble(POSITION_TP);
      break;
      
      case POOL_ORDER:
      tp = OrderGetDouble(ORDER_TP);
      break;
   }
   return tp;
}

//待機注文に付加された有効期限の取得
datetime MyOrderExpiration(int pos_id=0)
{
   datetime expiration = 0;
   if(MyOrderSelect(pos_id) == POOL_ORDER) expiration = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
   return expiration;
}

//オープンポジションの損益（金額）の取得
double MyOrderProfit(int pos_id=0)
{
   double profit = 0;
   if(MyOrderSelect(pos_id) == POOL_POSITION) profit = PositionGetDouble(POSITION_PROFIT);
   return profit;
}

//オープンポジションの損益（pips）の取得
double MyOrderProfitPips(int pos_id=0)
{
   double profit = 0;
   ENUM_ORDER_TYPE type = MyOrderType(pos_id);
   if(type == ORDER_TYPE_BUY) profit = MyOrderClosePrice(pos_id)
                                     - MyOrderOpenPrice(pos_id);
   if(type == ORDER_TYPE_SELL) profit = MyOrderOpenPrice(pos_id)
                                      - MyOrderClosePrice(pos_id);
   return PriceToPips(profit, pos_id);  //pips値に変換
}

//OrderSend retcode の説明
string RetcodeDescription(int retcode)
{
   switch(retcode)
   {
      case TRADE_RETCODE_REQUOTE:
           return("リクオート");
      case TRADE_RETCODE_REJECT:
           return("リクエストの拒否");
      case TRADE_RETCODE_CANCEL:
           return("トレーダーによるリクエストのキャンセル");
      case TRADE_RETCODE_PLACED:
           return("注文が出されました");
      case TRADE_RETCODE_DONE:
           return("リクエスト完了");
      case TRADE_RETCODE_DONE_PARTIAL:
           return("リクエストが一部のみ完了");
      case TRADE_RETCODE_ERROR:
           return("リクエスト処理エラー");
      case TRADE_RETCODE_TIMEOUT:
           return("リクエストが時間切れでキャンセル");
      case TRADE_RETCODE_INVALID:
           return("無効なリクエスト");
      case TRADE_RETCODE_INVALID_VOLUME:
           return("リクエスト内の無効なボリューム");
      case TRADE_RETCODE_INVALID_PRICE:
           return("リクエスト内の無効な価格");
      case TRADE_RETCODE_INVALID_STOPS:
           return("リクエスト内の無効なストップ");
      case TRADE_RETCODE_TRADE_DISABLED:
           return("取引が無効化されています");
      case TRADE_RETCODE_MARKET_CLOSED:
           return("市場が閉鎖中");
      case TRADE_RETCODE_NO_MONEY:
           return("リクエストを完了するのに資金が不充分");
      case TRADE_RETCODE_PRICE_CHANGED:
           return("価格変更");
      case TRADE_RETCODE_PRICE_OFF:
           return("リクエスト処理に必要な相場が不在");
      case TRADE_RETCODE_INVALID_EXPIRATION:
           return("リクエスト内の無効な注文有効期限");
      case TRADE_RETCODE_ORDER_CHANGED:
           return("注文状態の変化");
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
           return("頻繁過ぎるリクエスト");
      case TRADE_RETCODE_NO_CHANGES:
           return("リクエストに変更なし");
      case TRADE_RETCODE_SERVER_DISABLES_AT:
           return("サーバが自動取引を無効化");
      case TRADE_RETCODE_CLIENT_DISABLES_AT:
           return("クライアントが自動取引を無効化");
      case TRADE_RETCODE_LOCKED:
           return("リクエストが処理のためにロック中");
      case TRADE_RETCODE_FROZEN:
           return("注文やポジションが凍結");
      case TRADE_RETCODE_INVALID_FILL:
           return("無効な注文執行タイプ");
      case TRADE_RETCODE_CONNECTION:
           return("取引サーバに未接続");
      case TRADE_RETCODE_ONLY_REAL:
           return("操作は、ライブ口座のみで許可");
      case TRADE_RETCODE_LIMIT_ORDERS:
           return("待機注文の数が上限に達しました");
      case TRADE_RETCODE_LIMIT_VOLUME:
           return("注文やポジションのボリュームが上限に達しました");
      case TRADE_RETCODE_INVALID_ORDER:
           return("不正または禁止された注文の種類");
      case TRADE_RETCODE_POSITION_CLOSED:
           return("指定されたPOSITION識別子をもつポジションがすでに閉鎖");
   }
   return IntegerToString(retcode) + " Unknown Retcode";
}

//ポジション履歴の選択(out)
ulong MyHistoryOrderSelect(int shift, int pos_id=0)
{
   if(!CheckPosID(pos_id)) return 0;  //ポジション番号のチェック

   ulong ticket = 0;
   if(shift > 0) //過去のポジションの選択
   {
      HistorySelect(0, TimeCurrent());
      for(int i=HistoryDealsTotal()-1; i>=0; i--)
      {
         ticket = HistoryDealGetTicket(i);
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == TradeSymbol[pos_id]
            && HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber[pos_id]
            && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            shift--;
            if(shift <= 0) break;
         }
         else ticket = 0;
      }
   }
   return ticket;
}

//ポジション履歴の選択(in & out)
bool MyHistoryOrderSelect(int shift, ulong& in, ulong& out, int pos_id=0)
{
   if(!CheckPosID(pos_id)) return false;  //ポジション番号のチェック

   in = 0; out = 0;
   if(shift > 0) //過去のポジションの選択
   {
      HistorySelect(0, TimeCurrent());
      for(int i=HistoryDealsTotal()-1; i>=0; i--)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == TradeSymbol[pos_id]
            && HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber[pos_id])
         {   
            if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
            {
               shift--;
               if(shift <= 0) out = ticket;
            }
            if(out > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
            {
               in = ticket;
               return true;
            }
         }
      }
   }
   return false;
}

//オープンポジションの損益（pips）の取得
ENUM_ORDER_TYPE MyOrderLastType(int pos_id=0)
{
   ENUM_ORDER_TYPE type = ORDER_TYPE_NONE;
   ulong ticket = MyHistoryOrderSelect(1, pos_id);
   if(ticket > 0)
   {
      ENUM_DEAL_TYPE dtype = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
      if(dtype == DEAL_TYPE_SELL) type = ORDER_TYPE_BUY;
      if(dtype == DEAL_TYPE_BUY) type = ORDER_TYPE_SELL;
   }
   return type;
}

//前回のポジションのロット数の取得
double MyOrderLastLots(int pos_id=0)
{
   double lots = 0;
   ulong ticket = MyHistoryOrderSelect(1, pos_id);
   if(ticket > 0) lots = HistoryDealGetDouble(ticket, DEAL_VOLUME);
   return lots;
}

//前回のポジションの売買価格の取得
double MyOrderLastOpenPrice(int pos_id=0)
{
   double price = 0;
   ulong in, out;
   if(MyHistoryOrderSelect(1, in, out, pos_id)) price = HistoryDealGetDouble(in, DEAL_PRICE);
   return price;
}

//前回のポジションの売買時刻の取得
datetime MyOrderLastOpenTime(int pos_id=0)
{
   datetime opentime = 0;
   ulong in, out;
   if(MyHistoryOrderSelect(1, in, out, pos_id)) opentime = (datetime)HistoryDealGetInteger(in, DEAL_TIME);
   return opentime;   
}

//前回のポジションの決済価格の取得
double MyOrderLastClosePrice(int pos_id=0)
{
   double price = 0;
   ulong ticket = MyHistoryOrderSelect(1, pos_id);
   if(ticket > 0) price = HistoryDealGetDouble(ticket, DEAL_PRICE);
   return price;
}

//前回のポジションの決済時刻の取得
datetime MyOrderLastCloseTime(int pos_id=0)
{
   datetime closetime = 0;
   ulong ticket = MyHistoryOrderSelect(1, pos_id);
   if(ticket > 0) closetime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
   return closetime;
}

//前回のポジションの損益（金額）の取得
double MyOrderLastProfit(int pos_id=0)
{
   double profit = 0;
   ulong ticket = MyHistoryOrderSelect(1, pos_id);
   if(ticket > 0) profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
   return profit;
}

//前回のポジションの損益（pips）の取得
double MyOrderLastProfitPips(int pos_id=0)
{
   double profit = 0;
   ulong in, out;
   if(MyHistoryOrderSelect(1, in, out, pos_id))
   {
      double openprice = HistoryDealGetDouble(in, DEAL_PRICE);      
      double closeprice = HistoryDealGetDouble(out, DEAL_PRICE);      
      ENUM_DEAL_TYPE dtype = (ENUM_DEAL_TYPE)HistoryDealGetInteger(in, DEAL_TYPE);
      if(dtype == DEAL_TYPE_BUY) profit = closeprice - openprice;
      if(dtype == DEAL_TYPE_SELL) profit = openprice - closeprice;
   }
   return PriceToPips(profit, pos_id);  //pips値に変換
}

//前回までの連続損益（金額）の取得
double MyOrderConsecutiveProfit(int pos_id=0)
{
   double profit = 0;
   for(int i=1;;i++)
   {
      ulong ticket = MyHistoryOrderSelect(i, pos_id);
      if(ticket > 0)
      {
         double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(p == 0) continue;
         if(profit == 0) profit = p;
         else
         {
            if(profit * p > 0) profit += p;
            if(profit * p < 0) break;
         }
      }
      else break;
   }
   return profit;
}

//前回までの連続勝敗数の取得
int MyOrderConsecutiveWins(int pos_id=0)
{
   int wins = 0;
   for(int i=1;;i++)
   {
      ulong ticket = MyHistoryOrderSelect(i, pos_id);
      if(ticket > 0)
      {
         double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(p == 0) continue;
         if(wins == 0) wins = (p>0)?1:-1;
         else
         {
            if(wins * p > 0) wins += (p>0)?1:-1;
            if(wins * p < 0) break;
         }
      }
      else break;
   }
   return wins;
}

//過去の総損益（金額）の取得
double MyOrderTotalProfit(datetime from_date, datetime to_date, int pos_id=0)
{
   double profit = 0;
   for(int i=1;;i++)
   {
      ulong ticket = MyHistoryOrderSelect(i, pos_id);
      if(ticket > 0)
      {
         datetime t = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         if(t < from_date) break;
         if(t > to_date) continue;
         profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
         profit += HistoryDealGetDouble(ticket, DEAL_SWAP);
         profit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      }
      else break;
   }
   return profit;
}
