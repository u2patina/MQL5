//LibEA.mqh
//MQL4/MQL5共通EAライブラリ
//u2

#property copyright "Copyright (c) 2019, Toyolab FX"
#property link      "http://forex.toyolab.com/"
#property version   "210.322"

//同時にオープン可能なポジションの最大数を指定する定数です。１以上の整数値を設定します。デフォルトで「10」と定義してあります。この値を変えるには、ライブラリをインクルードする前に「#define」で定義し直します。
//豊嶋久道.メタトレーダー４＆５共通ライブラリによるＥＡ開発入門(Kindleの位置No.2261-2264).TandYResearchInstitute.Kindle版.
#ifndef POSITIONS
   #define POSITIONS 10  //最大ポジション数
#endif

//同一の通貨ペアのチャートを複数開き、それぞれ異なるEAを実行させる際に、各EAを区別するために指定する数値です。１以上の整数値を設定します。この基本マジックナンバーと最大ポジション数「POSITIONS」から各ポジションを区別するためのマジックナンバーが「MAGIC×POSITIONS」から「(MAGIC+1)×POSITIONS-1」まで割り振られます。
//MAGIC=5」「POSITIONS=10」の場合、各ポジションのマジックナンバーは、それぞれ、50,51,52,53,54,55,56,57,58,59となります。
//豊嶋久道.メタトレーダー４＆５共通ライブラリによるＥＡ開発入門(Kindleの位置No.2267-2272).TandYResearchInstitute.Kindle版.
#ifndef MAGIC
   sinput int MAGIC = 1;  //MAGIC(基本マジックナンバー)
#endif

#ifndef SlippagePips
   sinput double SlippagePips = 1;   //SlippagePips(許容スリッページpips)
#endif


#ifndef UseOrderComment
   //マジックナンバーをコメントに変換
   string MagicToComment(long magic){return IntegerToString(magic);}
#endif

long MagicNumber[POSITIONS] = {0};  //ポジションごとのマジックナンバー
string TradeSymbol[POSITIONS];      //取引シンボル
double PipPoint = _Point*10;        //1pipの値
ulong Slippage = (ulong)(SlippagePips*10); //許容スリッページpoint
double _PipPoint[POSITIONS];		//ポジションごとの1pipの値
ulong _TickTime = 0; //ティックタイム

#ifdef __MQL4__
   #property strict
   #include "LibOrder4.mqh"   //MQL4用オーダー関連ライブラリ
   #ifdef UseMT5TF
      #include "LibTF5.mqh"   //MT5のタイムフレームを使用（オプション）
   #endif
#endif

#ifdef __MQL5__
   #include "LibOrder5.mqh"   //MQL5用オーダー関連ライブラリ（ヘッジングモードのみ）
#endif

//ティック時実行関数
void OnTick()
{
   _TickTime = GetMicrosecondCount();  //isNewBar()のためティックタイム更新 
   if(UpdatePosition()) Tick();
}

//ポジションの更新
bool UpdatePosition()
{
   RefreshRates();
   static bool first_call = true;
   if(MagicNumber[0] == 0)
   {
      if(first_call) //１回目の呼び出しを無視する
      {
         first_call = false;
         return true;
      }
      else if(!InitPosition()) return false; //ポジションの初期化
   }
   return true;
}

//ポジションの初期化
bool InitPosition(int magic=0)
{
#ifdef __MQL5__
   //ヘッジングモードのチェック
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   {
      Print("ヘッジ口座で実行してください");
      return false;
   }
#endif

   //マジックナンバー・取引シンボルの設定
   if(POSITIONS <= 0)
   {
      Print("最大ポジション数(POSITIONS)には１以上の整数値を設定してください");
      return false;
   }
   if(magic == 0) magic = MAGIC;
   if(magic <= 0)
   {
      Print("基本マジックナンバー(MAGIC)には１以上の整数値を設定してください");
      return false;
   }

   //定義済み変数の調整
   if(_Digits == 0 || _Digits == 2 || _Digits == 4)
   {
      Slippage = (ulong)SlippagePips;
      PipPoint = _Point;
   }

   //ポジションの初期化
   for(int i=0; i<POSITIONS; i++)
   {
      MagicNumber[i] = magic*POSITIONS+i;
      TradeSymbol[i] = _Symbol;
      _PipPoint[i] = PipPoint;
   }

   return true;
}

// 基本マジックナンバーの自動生成
//チャート の 順番 に 1, 2, 3, …と 互いに 重複 し ない 数値 を 返し ます。「 symbol」 を 省略 し た「 場合、 オープン し た すべて の チャート において、 チャート 順 の 数値 を 返し ます。
//豊嶋 久道. メタトレーダー４＆５共通ライブラリによるＥＡ開発入門 (Kindle の位置No.2313-2314). T and Y Research Institute. Kindle 版. 
int GetUniqueMagic(string symbol="")
{
   //シンボル不一致の場合0を返す
   if(StringSubstr(_Symbol, 0, StringLen(symbol)) != symbol) return 0;

   int ret = 1;   //基本マジックナンバー初期値
   long chartID = ChartFirst();  //チャートID
   
   while(chartID >= 0)
   {
      if(chartID == ChartID()) break;
      if(StringSubstr(ChartSymbol(chartID), 0, StringLen(symbol)) == symbol) ret++;
      chartID = ChartNext(chartID);
   }
   return ret;
}

//新規バーのチェック
//通貨 ペア「 symbol」、 タイム フレーム「 tf」 で 指定 し た チャート において、 新規 バー が 生成 さ れ た とき に「 true」 を 返し ます。 それ 以外 では「 false」 を 返し ます。
//豊嶋 久道. メタトレーダー４＆５共通ライブラリによるＥＡ開発入門 (Kindle の位置No.2323-2325). T and Y Research Institute. Kindle 版. 
bool isNewBar(string symbol, ENUM_TIMEFRAMES tf)
{
   static datetime time = 0;  //バーの時刻
   static ulong ticktime = 0; //ティックタイム
   static bool ret = false;
   if(iTime(symbol, tf, 0) != time) //新規バーのティック
   {
      time = iTime(symbol, tf, 0);
      ticktime = _TickTime;
      ret = true;
   }
   else if(ticktime != _TickTime) ret = false;  //新規バー以外のティック
   return ret;
}

//ポジション番号のチェック
bool CheckPosID(int pos_id)
{
   if(pos_id >= POSITIONS) //pos_idエラー　POSITIONS=最大ポジション数を超えていたらエラー
   {
      Print("CheckPosID : pos_id(", pos_id, ")>=POSITIONS(", POSITIONS, ")");
      return false;
   }
   if(MagicNumber[pos_id] == 0) return false; //ポジションがないときはエラー
   return true;
}

//+------------------------------------------------------------------+
//|【関数】シグナルによる成行注文                                             
//|                                                                  
//|【引数】 IN OUT  引数名             説明                               
//|        --------------------------------------------------------- 
//|         ○      sig_entry       仕掛けシグナル　　買いシグナルを「1」、売りシグナルを「-1」、シグナルなし0                       
//|         ○      sig_exit        手仕舞いシグナル 買いシグナルを「1」、売りシグナルを「-1」、シグナルなし0                    
//|         ○      lots           　売買ロット数                             
//|         ○      pos_id=0        ポジション番号　省略 可能 で 省略 時 は pos_ id = 0 を 指定
//|【戻値】チケット番号（エラーの場合は、-1）                                      
//|                                                                  
//|【備考】△：既定値あり                                                    
//+------------------------------------------------------------------+
//シグナルによる成行注文
//「pos_ id」 で 指定 し た ポジション 番号 で、 仕掛け シグナル に従って 成 行 注文 を 送信 する 関数 です。 手仕舞い シグナル により ポジション を 決済 する 機能 も 含ん で い ます。 仕掛け シグナル、 手仕舞い シグナル は 便宜上、 買い シグナル を「 1」、 売り シグナル を「- 1」 と し て い ます が、 実際 には「 1 以上」 で あれ ば、 買い シグナル、「- 1 以下」 で あれ ば、 売り シグナル と みなし ます。
// ただし、 仕掛け シグナル と 手仕舞い シグナル の 符号 が 逆 の 場合、 注文 は 送信 さ れ ませ ん。 また、 ポジション 保有 時 に 仕掛け シグナル と 手仕舞い シグナル の 符号 が 逆 の 場合、 決済 処理 は 行わ れ ませ ん。 これ は、 買い ポジション の ある とき に 仕掛け シグナル が 買い、 かつ 手仕舞い
//手仕舞い シグナル が 売り の とき に、 買い ポジション を 決済 し て、 すぐ に また 買い ポジション が できる のを 防ぐ ため です。 売り ポジション が ある とき に 仕掛け シグナル が 売り、 かつ 手仕舞い シグナル が 買い の とき も 同様 に、 売り ポジション を 決済 し て、 すぐ に また 売り ポジション が できる のを 防ぐ ため に 決済 処理 は 行わ れ ませ ん。
//豊嶋 久道. メタトレーダー４＆５共通ライブラリによるＥＡ開発入門 (Kindle の位置No.2337-2344). T and Y Research Institute. Kindle 版. 
void MyOrderSendMarket(int sig_entry, int sig_exit, double lots, int pos_id=0)
{
   //同時シグナル
   if(sig_entry + sig_exit == 0) return;
   //ポジション決済
   MyOrderCloseMarket(sig_entry, sig_exit, pos_id);
   //買い注文
   if(sig_entry > 0) MyOrderSend(OP_BUY, lots, 0, pos_id);
   //売り注文
   if(sig_entry < 0) MyOrderSend(OP_SELL, lots, 0, pos_id);
}

//シグナルによる待機注文
//「pos_ id」 で 指定 し た ポジション 番号 で、 仕掛け シグナル に従って 待機 注文 を 送信 する 関数 です。 「limit_ pips」 が プラス の 場合、 指値注文、 マイナス の 場合、 逆指値 注文 となり ます。 待機 注文 の 有効 時間 は「 pend_ min」 により 分 単位 で 指定 し ます。 手仕舞い シグナル により ポジション を 決済 する 機能 も 含ん で い ます。 仕掛け シグナル、 手仕舞い シグナル は 便宜上、
//買い シグナル を「 1」、 売り シグナル を「- 1」 と し て い ます が、 実際 には「 1 以上」 で あれ ば、 買い シグナル、「- 1 以下」 で あれ ば、 売り シグナル と みなし ます。 ただし、 仕掛け シグナル と 手仕舞い シグナル の 符号 が 逆 の 場合、 注文 は 送信 さ れ ませ ん。
//豊嶋 久道. メタトレーダー４＆５共通ライブラリによるＥＡ開発入門 (Kindle の位置No.2362-2366). T and Y Research Institute. Kindle 版. 
void MyOrderSendPending(int sig_entry, int sig_exit, double lots, double limit_pips, int pend_min=0, int pos_id=0)
{
   //有効期限チェック
   if(isOrderExpired(pend_min, pos_id)) MyOrderDelete(pos_id);
   //同時シグナル
   if(sig_entry + sig_exit == 0) return;
   //ポジション決済
   MyOrderCloseMarket(sig_entry, sig_exit, pos_id);
   //注文キャンセル
   if(MyOrderPendingLots(pos_id)*sig_exit < 0) MyOrderDelete(pos_id);
   //待機注文
   if(limit_pips > 0)
   {
      //指値買い注文
      if(sig_entry > 0) MyOrderSend(OP_BUYLIMIT, lots, Ask-PipsToPrice(limit_pips, pos_id), pos_id);
      //指値売り注文
      if(sig_entry < 0) MyOrderSend(OP_SELLLIMIT, lots, Bid+PipsToPrice(limit_pips, pos_id), pos_id);
   }
   else if(limit_pips < 0)
   {
      //逆指値買い注文
      if(sig_entry > 0) MyOrderSend(OP_BUYSTOP, lots, Ask-PipsToPrice(limit_pips, pos_id), pos_id);
      //逆指値売り注文
      if(sig_entry < 0) MyOrderSend(OP_SELLSTOP, lots, Bid+PipsToPrice(limit_pips, pos_id), pos_id);
   }
   //有効期限セット
   if(MyOrderPendingLots(pos_id) != 0 && pend_min > 0) MyOrderSetExpiration(MyOrderOpenTime(pos_id), 0, pend_min, pos_id);
}

//+------------------------------------------------------------------+
//|【関数】シグナルによるポジション決済                                             
//|                                                                  
//|【引数】 IN OUT  引数名             説明                               
//|        --------------------------------------------------------- 
//|         ○      sig_entry       仕掛けシグナル　　買いシグナルを「1」、売りシグナルを「-1」、シグナルなし0                       
//|         ○      sig_exit        手仕舞いシグナル 買いシグナルを「1」、売りシグナルを「-1」、シグナルなし0                    
//|         ○      lots           　売買ロット数                             
//|         ○      pos_id=0        ポジション番号　省略 可能 で 省略 時 は pos_ id = 0 を 指定
//|【戻値】なし                                      
//|                                                                  
//|【備考】                                                   
//+------------------------------------------------------------------+
//シグナルによるポジション決済
void MyOrderCloseMarket(int sig_entry, int sig_exit, int pos_id=0)
{
   //同時シグナル
   if(sig_entry + sig_exit == 0) return;
   //決済注文
   if(MyOrderCloseSignal(pos_id)*sig_exit > 0) MyOrderClose(pos_id);
}

//ポジション決済シグナル
int MyOrderCloseSignal(int pos_id=0)
{
   int ret = 0; //シグナルの初期化
   double pos = MyOrderOpenLots(pos_id); //オープンポジションのロット数（符号付）を取得
   if(pos > 0) ret = -1;   //買いポジションの決済に必要となるのは（売りシグナル）
   if(pos < 0) ret = 1;   //売りポジションの決済に必要となるのは（買いシグナル）
   return ret;
}

//オープンポジションのロット数（符号付）を取得
double MyOrderOpenLots(int pos_id=0)
{
   double lots = 0;
   int type = MyOrderType(pos_id);
   double newlots = MyOrderLots(pos_id); 
   if(type == OP_BUY) lots = newlots;   //買いポジションはプラス
   if(type == OP_SELL) lots = -newlots; //売りポジションはマイナス
   return lots;
}

//待機注文のロット数（符号付）の取得
double MyOrderPendingLots(int pos_id=0)
{
   double lots = 0;
   int type = MyOrderType(pos_id);
   double newlots = MyOrderLots(pos_id); 
   if(type == OP_BUYLIMIT || type == OP_BUYSTOP) lots = newlots;   //買い注文はプラス
   if(type == OP_SELLLIMIT || type == OP_SELLSTOP) lots = -newlots; //売り注文はマイナス
   return lots;
}

//ポジション・注文の一定利益となる決済価格の取得
double MyOrderShiftPrice(double sftpips, int pos_id=0) 
{
   double price = 0;
   int type = MyOrderType(pos_id);
   //買いポジション
   if(type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP)
   {
      price = MyOrderOpenPrice(pos_id) + PipsToPrice(sftpips, pos_id);
   }
   //売りポジション
   if(type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP)
   {
      price = MyOrderOpenPrice(pos_id) - PipsToPrice(sftpips, pos_id);
   }
   return price;
}

//ポジション・注文の一定価格における損益(pips)の取得
double MyOrderShiftPips(double price, int pos_id=0)
{
   double sft = 0;
   int type = MyOrderType(pos_id);
   //買いポジション
   if(type == OP_BUY || type == OP_BUYLIMIT || type == OP_BUYSTOP)
   {
      sft = price - MyOrderOpenPrice(pos_id);
   }
   //売りポジション
   if(type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP)
   {
      sft = MyOrderOpenPrice(pos_id) - price;
   }
   return PriceToPips(sft, pos_id); //pips値に変換
}

//売買ロット数の正規化
double NormalizeLots(double lots)
{
   //最小ロット数
   double lots_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   //最大ロット数
   double lots_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   //ロット数刻み幅
   double lots_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   //ロット数の小数点以下の桁数
   int lots_digits = (int)MathLog10(1.0/lots_step);
   lots = NormalizeDouble(lots, lots_digits); //ロット数の正規化
   if(lots < lots_min) lots = lots_min; //最小ロット数を下回った場合
   if(lots > lots_max) lots = lots_max; //最大ロット数を上回った場合
   return lots;
}

//待機注文の有効期限のチェック
bool PendingOrderExpiration(int min, int pos_id=0){return isOrderExpired(min, pos_id);}//obsolete
bool isOrderExpired(int min, int pos_id=0)
{
   //待機注文でない場合
   if(MyOrderPendingLots(pos_id) == 0) return false;
   datetime expiration = MyOrderExpiration(pos_id);
   if(expiration == 0 || min > 0) expiration = MyOrderOpenTime(pos_id) + min*60;
   //有効期限を過ぎた場合
   if(TimeCurrent() > expiration) return true;
   return false;  //有効期限内
}

//シグナル待機フィルタ
int WaitSignal(int signal, int min, int pos_id=0)
{
   int ret = 0; //シグナルの初期化
   if(MyOrderOpenLots(pos_id) != 0 //オープンポジションがある場合
      //待機時間が経過した場合
      && TimeCurrent() >= MyOrderOpenTime(pos_id) + min*60)
         ret = signal;

   return ret; //シグナルの出力
}

//取引シンボルの選択
bool MyOrderSelectSymbol(string symbol, int pos_id=0)
{
   if(TradeSymbol[pos_id] != symbol)
   {
      MqlTick tick;
      if(!SymbolInfoTick(symbol, tick))
      {
         Print("MyOrderSelectSymbol : ", symbol, " not exist");
         return false;
      }
      if(MyOrderType(pos_id) != OP_NONE)
      {
         Print("MyOrderSelectSymbol : ", pos_id, " 番のポジションあるいはオーダーがあります");
         return false;
      }
      TradeSymbol[pos_id] = symbol;
      _PipPoint[pos_id] = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      if(digits == 3 || digits == 5) _PipPoint[pos_id] *= 10;
   }
   return true;
}

//損切り・利食い注文のセット
void MyOrderSetSLTP(double slpips, double tppips, int pos_id=0)
{
   if(MyOrderType(pos_id) == OP_NONE) return; //ポジション・注文がない場合
   double slprice=0, tpprice=0; 
   if(slpips != 0) slprice = MyOrderShiftPrice(-slpips, pos_id);
   if(tppips != 0) tpprice = MyOrderShiftPrice(tppips, pos_id);
   MyOrderModify(0, slprice, tpprice, pos_id);
}

//トレイリングストップのセット
void SetTrailingStop(double tspips, bool profit_flag, int pos_id=0)
{
   if(MyOrderOpenLots(pos_id) == 0) return; //オープンポジションがない場合
   double profit = MyOrderProfitPips(pos_id) - tspips;
   double sl = MyOrderStopLoss(pos_id);
   if(profit_flag)
   {
         if(profit >= 0 && (sl == 0 || profit > MyOrderShiftPips(sl, pos_id)))
         MyOrderModify(0, MyOrderShiftPrice(profit, pos_id), 0, pos_id);
   }
   else
   {
      if(sl == 0 || profit > MyOrderShiftPips(sl, pos_id))
         MyOrderModify(0, MyOrderShiftPrice(profit, pos_id), 0, pos_id);
   }
}
//トレイリングストップのセット
void TateneSetTrailingStop( bool profit_flag, int pos_id)
{
//   if(MyOrderOpenLots(pos_id) == 0) return; //オープンポジションがない場合は以下不要
   if(MyOrderOpenLots(pos_id) == 0)
   {
      if(pos_id == 0){
         maxpips0 = 0;
         minpips0 = 0;
         return;
      }
      if(pos_id == 1){
         maxpips1 = 0;
         minpips1 = 0;
         return;
      }
      if(pos_id == 2){
         maxpips2 = 0;
         minpips2 = 0;
         return;
      }
      if(pos_id == 3){
         maxpips3 = 0;
         minpips3 = 0;
         return;
      }
      if(pos_id == 4){
         maxpips4 = 0;
         minpips4 = 0;
         return;
      }
      if(pos_id == 5){
         maxpips5 = 0;
         minpips5     = 0;
         return;
      }
   } else {
         profitpips = (int)MyOrderProfitPips(pos_id);
   //最大含み損及び含み益の計算
         if(pos_id == 0){
            maxpips0 = MathMax( maxpips0,profitpips );
            minpips0 = MathMin( minpips0,profitpips );
         }
         if(pos_id == 1){
            maxpips1 = MathMax( maxpips1,profitpips );
            minpips1 = MathMin( minpips1,profitpips );
         }
         if(pos_id == 2){
            maxpips2 = MathMax( maxpips2,profitpips );
            minpips2 = MathMin( minpips2,profitpips );
         }
         if(pos_id == 3){
            maxpips3 = MathMax( maxpips3,profitpips );
            minpips3 = MathMin( minpips3,profitpips );
         }
         if(pos_id == 4){
            maxpips4 = MathMax( maxpips4,profitpips );
            minpips4 = MathMin( minpips4,profitpips );
         }
         if(pos_id == 5){
            maxpips5 = MathMax( maxpips5,profitpips );
            minpips5 = MathMin( minpips5,profitpips );
         }

         if( profitpips >= TPpips || profitpips <= -SLpips ) MyOrderClose(pos_id);  //含み益が、TPpipsを超えるか、含み損がSLpipsを割ると決済
         double profit = profitpips - TSpips;
         double sl = MyOrderStopLoss(pos_id);
         double tp = MyOrderTakeProfit(pos_id);
         double op = MyOrderOpenPrice(pos_id);
         if( profit >= 0 )
         {
            //if(profit >= 0 && (sl == 0 || profit > MyOrderShiftPips(sl, pos_id)))    // トレーリングストップ値幅以上かつ、ストップロスが０か、損切り値幅を超えている場合。
            if(profit >= 0 && sl == 0 )                                                // トレーリングストップ値幅以上かつ、ストップロスが０か、損切り値幅を超えている場合。
               MyOrderModify(0, MyOrderShiftPrice(profit, pos_id), 0, pos_id);         //　ストップロスをトレーリングストップ値幅に変更
            if(profit >= 0 && sl != 0 )                                                // トレーリングストップ値幅以上かつ、ストップロスが０か、損切り値幅を超えている場合。
               MyOrderModify(0, MyOrderShiftPrice(profit, pos_id), 0, pos_id);         //　ストップロスをトレーリングストップ値幅に変更
         }
         else
         {
         if( tp == 0 && MyOrderProfitPips(pos_id) < ( nigepips * -1))            // takeprofit=0かつ含み損がnigeropipsよりさらにしたまわった場合、
            MyOrderModify( 0, 0,op, pos_id);                                     // takeprofitを建値に変更
            //bool MyOrderModify(double price, double sl, double tp, int pos_id=0)
         }
   }
}

//pipsから値幅に変換
double PipsToPrice(double pips, int pos_id=0)
{
   if(_PipPoint[pos_id] != 0) return pips*_PipPoint[pos_id];
   else return pips*PipPoint;
}

//値幅からpipsに変換
double PriceToPips(double price, int pos_id=0)
{
   if(_PipPoint[pos_id] != 0) return price/_PipPoint[pos_id];
   else return price/PipPoint;
}

//一定期間の最高値
#define Highest HighestPrice //obsolete
double HighestPrice(string symbol, ENUM_TIMEFRAMES tf, int type, int period, int shift)
{
   int idx = iHighest(symbol, tf, (ENUM_SERIESMODE)type, period, shift);
   switch(type)
   {
      case MODE_OPEN:
         return iOpen(symbol, tf, idx);
      case MODE_HIGH:
         return iHigh(symbol, tf, idx);
      case MODE_LOW:
         return iLow(symbol, tf, idx);
      case MODE_CLOSE:
         return iClose(symbol, tf, idx);
   }
   return 0;
}

//一定期間の最安値
#define Lowest LowestPrice //obsolete
double LowestPrice(string symbol, ENUM_TIMEFRAMES tf, int type, int period, int shift)
{
   int idx = iLowest(symbol, tf, (ENUM_SERIESMODE)type, period, shift);
   switch(type)
   {
      case MODE_OPEN:
         return iOpen(symbol, tf, idx);
      case MODE_HIGH:
         return iHigh(symbol, tf, idx);
      case MODE_LOW:
         return iLow(symbol, tf, idx);
      case MODE_CLOSE:
         return iClose(symbol, tf, idx);
   }
   return 0;
}

//ポジション情報の表示
void MyOrderPrint(int pos_id=0)
{
   //ロット数の刻み幅
   double lots_step = SymbolInfoDouble(TradeSymbol[pos_id], SYMBOL_VOLUME_STEP);
   //ロット数の小数点以下桁数
   int lots_digits = (int)MathLog10(1.0/lots_step);
   string stype[] = {"buy", "sell", "buy limit", "sell limit",
                     "buy stop", "sell stop"};
   string s = "MyPos[";
   s = s + IntegerToString(pos_id) + "] ";  //ポジション番号
   if(MyOrderType(pos_id) == OP_NONE) s = s + "No position";
   else
   {
      s = s + "#"
            + IntegerToString(MyOrderTicket(pos_id)) //チケット番号
            + " ["
            + TimeToString(MyOrderOpenTime(pos_id)) //売買日時
            + "] "
            + stype[MyOrderType(pos_id)]  //注文タイプ
            + " "
            + DoubleToString(MyOrderLots(pos_id), lots_digits) //ロット数
            + " "
            + TradeSymbol[pos_id] //通貨ペア
            + " at " 
            + DoubleToString(MyOrderOpenPrice(pos_id), _Digits); //売買価格
      //損切り価格
      if(MyOrderStopLoss(pos_id) != 0) s = s + " sl "
         + DoubleToString(MyOrderStopLoss(pos_id), _Digits);
      //利食い価格
      if(MyOrderTakeProfit(pos_id) != 0) s = s + " tp " 
         + DoubleToString(MyOrderTakeProfit(pos_id), _Digits);
      s = s + " magic " + IntegerToString(MagicNumber[pos_id]); //マジックナンバー
   }
   Print(s); //出力
}

//DateTime秒数
#define DT_MIN      60 //１分
#define DT_HOUR   3600 //１時間
#define DT_DAY   86400 //１日
#define DT_WEEK 604800 //１週間

//isDayOfWeek()定数
#define DT_SUN 0x81 //日
#define DT_MON 0x82 //月
#define DT_TUE 0x84 //火
#define DT_WED 0x88 //水
#define DT_THU 0x90 //木
#define DT_FRI 0xA0 //金
#define DT_SAT 0xC0 //土
#define DT_BIZ 0xBE //平日

//本日の指定した時刻のdatetime型
datetime Today(int hour=0, int min=0, int sec=0)
{
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.hour = hour;
   dt.min = min;
   dt.sec = sec;
   return StructToTime(dt);
}

//今週の指定した曜日・時刻のdatetime型（日：DT_SUN/0 月：DT_MON/1 ・・・ 金：DT_FRI/5 土：DT_SAT/6）
datetime ThisWeek(int day_week=0, int hour=0, int min=0, int sec=0)
{
   int dt_week[7] = {DT_SUN,DT_MON,DT_TUE,DT_WED,DT_THU,DT_FRI,DT_SAT};
   if(day_week > 7)
   {
      for(int i=0; i<7; i++) if(day_week == dt_week[i]) {day_week = i; break;}
   }
   MqlDateTime dt;
   TimeCurrent(dt);
   return Today(hour, min, sec)+(day_week-dt.day_of_week)*DT_DAY;
}

//今月の指定した日・時刻のdatetime型
datetime ThisMonth(int day=1, int hour=0, int min=0, int sec=0)
{
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.day = day;
   dt.hour = hour;
   dt.min = min;
   dt.sec = sec;
   return StructToTime(dt);
}

//今年の指定した月日・時刻のdatetime型
datetime ThisYear(int month=1, int day=1, int hour=0, int min=0, int sec=0)
{
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.mon = month;
   dt.day = day;
   dt.hour = hour;
   dt.min = min;
   dt.sec = sec;
   return StructToTime(dt);
}

//datetime型範囲による判別
bool isDatetimeRange(datetime dt_from, datetime dt_to)
{
   if(dt_from < dt_to && TimeCurrent() >= dt_from && TimeCurrent() < dt_to) return true;
   if(dt_from > dt_to && (TimeCurrent() >= dt_from || TimeCurrent() < dt_to)) return true;
   return false;
}

//時刻による判別
bool isTimeAt(int hour, int min)
{
   datetime dt = Today(hour, min);
   return isDatetimeRange(dt, dt+DT_MIN);
}

//日付による判別
bool isDateOn(int month, int day)
{
   datetime dt = ThisYear(month, day);
   return isDatetimeRange(dt, dt+DT_DAY);
}

//時刻範囲による判別
bool isTimeRange(int hour_from, int min_from, int hour_to, int min_to)
{
   datetime dt_from = Today(hour_from, min_from);
   datetime dt_to = Today(hour_to, min_to);
   return isDatetimeRange(dt_from, dt_to);
}

//日付範囲による判別
bool isDateRange(int month_from, int day_from, int month_to, int day_to)
{
   datetime dt_from = ThisYear(month_from, day_from);
   datetime dt_to = ThisYear(month_to, day_to);
   return isDatetimeRange(dt_from, dt_to+DT_DAY);
}

//曜日による判別
bool isDayOfWeek(int day_week)
{
   uchar dt_week[7] = {DT_SUN,DT_MON,DT_TUE,DT_WED,DT_THU,DT_FRI,DT_SAT};
   if(((uchar)day_week & dt_week[DayOfWeek()] & 0x7F) != 0) return true;
   return false;
}
