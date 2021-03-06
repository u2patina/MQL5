//LibMQL4.mqh for MQL5
//MQL5用MQL4互換ライブラリ

/*
#property copyright "Copyright (c) 2019, Toyolab FX"
#property link      "http://forex.toyolab.com/"
#property version   "210.110"
*/

//４本値バッファサイズ
#ifndef MY_BUFFER_SIZE
   #define MY_BUFFER_SIZE 1000
#endif
#ifndef MY_OPEN_SIZE
   #define MY_OPEN_SIZE MY_BUFFER_SIZE
#endif
#ifndef MY_LOW_SIZE
   #define MY_LOW_SIZE MY_BUFFER_SIZE
#endif
#ifndef MY_HIGH_SIZE
   #define MY_HIGH_SIZE MY_BUFFER_SIZE
#endif
#ifndef MY_CLOSE_SIZE
   #define MY_CLOSE_SIZE MY_BUFFER_SIZE
#endif
#ifndef MY_TIME_SIZE
   #define MY_TIME_SIZE MY_BUFFER_SIZE
#endif
#ifndef MY_VOLUME_SIZE
   #define MY_VOLUME_SIZE MY_BUFFER_SIZE
#endif

//for Indicator functions
#define MODE_MAIN 0
#define MODE_SIGNAL 1
#define MODE_UPPER 1
#define MODE_LOWER 2
#define MODE_PLUSDI 1
#define MODE_MINUSDI 2
#define MODE_GATORJAW 0
#define MODE_GATORTEETH 1
#define MODE_GATORLIPS 2
#define MODE_TENKANSEN 0
#define MODE_KIJUNSEN 1
#define MODE_SENKOUSPANA 2
#define MODE_SENKOUSPANB 3
#define MODE_CHIKOUSPAN 4

//iCustom()をiMyCustom()に転送
#define iCustom iMyCustom

//テクニカル指標のパラメータ値の組み合わせの最大数
#ifndef MAX_IND
   #define MAX_IND 8
#endif

//MQL4互換定義済み配列
double Bid, Ask, Open[], Low[], High[], Close[];
datetime Time[];
long Volume[];

//MQL4互換定義済み配列の更新
bool RefreshRates()
{
   //Bid・Askの更新
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return false;
   Bid = tick.bid;
   Ask = tick.ask;

   if(MY_OPEN_SIZE > 0)
   {
      if(!ArrayIsSeries(Open)) ArraySetAsSeries(Open, true);
      if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, MY_OPEN_SIZE, Open) < 0) return false;
   }
   if(MY_LOW_SIZE > 0)
   {
      if(!ArrayIsSeries(Low)) ArraySetAsSeries(Low, true);
      if(CopyLow(_Symbol, PERIOD_CURRENT, 0, MY_LOW_SIZE, Low) < 0) return false;
   }
   if(MY_HIGH_SIZE > 0)
   {
      if(!ArrayIsSeries(High)) ArraySetAsSeries(High, true);
      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, MY_HIGH_SIZE, High) < 0) return false;
   }
   if(MY_CLOSE_SIZE > 0)
   {
      if(!ArrayIsSeries(Close)) ArraySetAsSeries(Close, true);
      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, MY_CLOSE_SIZE, Close) < 0) return false;
   }
   if(MY_TIME_SIZE > 0)
   {
      if(!ArrayIsSeries(Time)) ArraySetAsSeries(Time, true);
      if(CopyTime(_Symbol, PERIOD_CURRENT, 0, MY_TIME_SIZE, Time) < 0) return false;
   }
   if(MY_VOLUME_SIZE > 0)
   {
      if(!ArrayIsSeries(Volume)) ArraySetAsSeries(Volume, true);
      if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, MY_VOLUME_SIZE, Volume) < 0) return false;
   }
   return true;
}

//サーバー時刻の年
int Year()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.year;
}

//サーバー時刻の月
int Month()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.mon;
}

//サーバー時刻の日
int Day()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.day;
}

//サーバー時刻の時
int Hour()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.hour;
}

//サーバー時刻の分
int Minute()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.min;
}

//サーバー時刻の秒
int Seconds()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.sec;
}

//サーバー時刻の曜日
int DayOfWeek()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.day_of_week;
}

//サーバー時刻の通し日
int DayOfYear()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return dt.day_of_year;
}

//指定時刻の年
int TimeYear(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.year;
}

//指定時刻の月
int TimeMonth(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.mon;
}

//指定時刻の日
int TimeDay(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.day;
}

//指定時刻の時
int TimeHour(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.hour;
}

//指定時刻の分
int TimeMinute(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.min;
}

//指定時刻の秒
int TimeSeconds(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.sec;
}

//指定時刻の曜日
int TimeDayOfWeek(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.day_of_week;
}

//指定時刻の通し日
int TimeDayOfYear(datetime val)
{
   MqlDateTime dt;
   TimeToStruct(val, dt);
   return dt.day_of_year;
}

//エラー処理したテクニカル指標値
double CheckValue(int i, string name, int handle, int mode, int shift)
{
   if(i >= MAX_IND) //指標数エラー
   {
      Print("CheckInd : ", name, " の指標数が ", MAX_IND, " を超えました");
      if(MQLInfoInteger(MQL_PROGRAM_TYPE) == PROGRAM_EXPERT) ExpertRemove();
      return EMPTY_VALUE;
   }

   double buf[1];
   if(CopyBuffer(handle, mode, shift, 1, buf) < 0)
   {
      //Print(name, "の計算がされていません");
      return EMPTY_VALUE;
   }
   return buf[0];
}

//ACオシレータ
double iAC(string symbol,
           ENUM_TIMEFRAMES timeframe,
           int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];

   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {   
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]) break;
      }
      else
      {
         handle[i] = iAC(symbol, timeframe);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         break;
      }
   }
   return CheckValue(i, "iAC", handle[i], 0, shift);
}

//A/D
double iAD(string symbol,
           ENUM_TIMEFRAMES timeframe,
           int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];

   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {   
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]) break;
      }
      else
      {
         handle[i] = iAD(symbol, timeframe, VOLUME_TICK);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         break;
      }
   }
   return CheckValue(i, "iAD", handle[i], 0, shift);
}

//ADX
double iADX(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int period,
            ENUM_APPLIED_PRICE applied_price,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]) break;
      }
      else
      {
         handle[i] = iADX(symbol, timeframe, period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         break;
      }
   }
   return CheckValue(i, "iADX", handle[i], mode, shift);
}

//アリゲーター
double iAlligator(string symbol,
                  ENUM_TIMEFRAMES timeframe,
                  int jaw_period,
                  int jaw_shift,
                  int teeth_period,
                  int teeth_shift,
                  int lips_period,
                  int lips_shift,
                  ENUM_MA_METHOD ma_method,
                  ENUM_APPLIED_PRICE applied_price,
                  int mode,
                  int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _jaw_period[MAX_IND];
   static int _jaw_shift[MAX_IND];
   static int _teeth_period[MAX_IND];
   static int _teeth_shift[MAX_IND];
   static int _lips_period[MAX_IND];
   static int _lips_shift[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && jaw_period == _jaw_period[i]
         && jaw_shift == _jaw_shift[i]
         && teeth_period == _teeth_period[i]
         && teeth_shift == _teeth_shift[i]
         && lips_period == _lips_period[i]
         && lips_shift == _lips_shift[i]
         && ma_method == _ma_method[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iAlligator(symbol, timeframe, jaw_period, jaw_shift, teeth_period, teeth_shift, lips_period, lips_shift, ma_method, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _jaw_period[i] = jaw_period;
         _jaw_shift[i] = jaw_shift;
         _teeth_period[i] = teeth_period;
         _teeth_shift[i] = teeth_shift;
         _lips_period[i] = lips_period;
         _lips_shift[i] = lips_shift;
         _ma_method[i] = ma_method;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iAlligator", handle[i], mode, shift);
}

//オーサムオシレーター
double iAO(string symbol,
           ENUM_TIMEFRAMES timeframe,
           int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];

   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {   
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]) break;
      }
      else
      {
         handle[i] = iAO(symbol, timeframe);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         break;
      }
   }
   return CheckValue(i, "iAO", handle[i], 0, shift);
}

//ATR
double iATR(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int ma_period,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]) break;
      }
      else
      {
         handle[i] = iATR(symbol, timeframe, ma_period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         break;
      }
   }
   return CheckValue(i, "iATR", handle[i], 0, shift);
}

//ベアパワー
double iBearsPower(string symbol,
                   ENUM_TIMEFRAMES timeframe,
                   int period,
                   ENUM_APPLIED_PRICE applied_price,
                   int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]) break;
      }
      else
      {
         handle[i] = iBearsPower(symbol, timeframe, period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         break;
      }
   }
   return CheckValue(i, "iBearsPower", handle[i], 0, shift);
} 

//ボリンジャーバンド
double iBands(string symbol,
              ENUM_TIMEFRAMES timeframe,
              int period,
              double deviation,
              int bands_shift,
              ENUM_APPLIED_PRICE applied_price,
              int mode,
              int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   static double _deviation[MAX_IND];
   static int _bands_shift[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]
         && deviation == _deviation[i]
         && bands_shift == _bands_shift[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iBands(symbol, timeframe, period, bands_shift, deviation, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         _deviation[i] = deviation;
         _bands_shift[i] = bands_shift;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iBands", handle[i], mode, shift);
}

//ブルパワー
double iBullsPower(string symbol,
                   ENUM_TIMEFRAMES timeframe,
                   int period,
                   ENUM_APPLIED_PRICE applied_price,
                   int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]) break;
      }
      else
      {
         handle[i] = iBullsPower(symbol, timeframe, period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         break;
      }
   }
   return CheckValue(i, "iBullsPower", handle[i], 0, shift);
} 

//CCI
double iCCI(string symbol,
                   ENUM_TIMEFRAMES timeframe,
                   int period,
                   ENUM_APPLIED_PRICE applied_price,
                   int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iCCI(symbol, timeframe, period, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iCCI", handle[i], 0, shift);
} 

//デマーカー
double iDeMarker(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int ma_period,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]) break;
      }
      else
      {
         handle[i] = iDeMarker(symbol, timeframe, ma_period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         break;
      }
   }
   return CheckValue(i, "iDeMarker", handle[i], 0, shift);
}

//エンベロープ
double iEnvelopes(string symbol,
                  ENUM_TIMEFRAMES timeframe,
                  int ma_period,
                  ENUM_MA_METHOD ma_method,
                  int ma_shift,
                  ENUM_APPLIED_PRICE applied_price,
                  double deviation,
                  int mode,
                  int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   static int _ma_shift[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   static double _deviation[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]
         && ma_method == _ma_method[i]
         && ma_shift == _ma_shift[i]
         && applied_price == _applied_price[i]
         && deviation == _deviation[i]) break;
      }
      else
      {
         handle[i] = iEnvelopes(symbol, timeframe, ma_period, ma_shift, ma_method, applied_price, deviation);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         _ma_method[i] = ma_method;
         _ma_shift[i] = ma_shift;
         _applied_price[i] = applied_price;
         _deviation[i] = deviation;
         break;
      }
   }
   return CheckValue(i, "iEnvelopes", handle[i], mode-1, shift);  //MODE_UPPER=1, MODE_LOWER=2
}

//勢力指数
double iForce(string symbol,
           ENUM_TIMEFRAMES timeframe,
           int period,
           ENUM_MA_METHOD ma_method,
           ENUM_APPLIED_PRICE applied_price,
           int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]
         && ma_method == _ma_method[i]) break;
      }
      else
      {
         handle[i] = iForce(symbol, timeframe, period, ma_method, VOLUME_TICK);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         _ma_method[i] = ma_method;
         break;
      }
   }
   return CheckValue(i, "iForce", handle[i], 0, shift);
}

//フラクタル
double iFractals(string symbol,
                 ENUM_TIMEFRAMES timeframe,
                 int mode,
                 int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];

   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {   
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]) break;
      }
      else
      {
         handle[i] = iFractals(symbol, timeframe);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         break;
      }
   }
   return CheckValue(i, "iFractals", handle[i], mode-1, shift); //MODE_UPPER=1, MODE_LOWER=2
}

//ゲーターオシレーター
double iGator(string symbol,
              ENUM_TIMEFRAMES timeframe,
              int jaw_period,
              int jaw_shift,
              int teeth_period,
              int teeth_shift,
              int lips_period,
              int lips_shift,
              ENUM_MA_METHOD ma_method,
              ENUM_APPLIED_PRICE applied_price,
              int mode,
              int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _jaw_period[MAX_IND];
   static int _jaw_shift[MAX_IND];
   static int _teeth_period[MAX_IND];
   static int _teeth_shift[MAX_IND];
   static int _lips_period[MAX_IND];
   static int _lips_shift[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && jaw_period == _jaw_period[i]
         && jaw_shift == _jaw_shift[i]
         && teeth_period == _teeth_period[i]
         && teeth_shift == _teeth_shift[i]
         && lips_period == _lips_period[i]
         && lips_shift == _lips_shift[i]
         && ma_method == _ma_method[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iGator(symbol, timeframe, jaw_period, jaw_shift, teeth_period, teeth_shift, lips_period, lips_shift, ma_method, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _jaw_period[i] = jaw_period;
         _jaw_shift[i] = jaw_shift;
         _teeth_period[i] = teeth_period;
         _teeth_shift[i] = teeth_shift;
         _lips_period[i] = lips_period;
         _lips_shift[i] = lips_shift;
         _ma_method[i] = ma_method;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iGator", handle[i], (mode-1)*2, shift); //MODE_UPPER=1, MODE_LOWER=2
}

//一目均衡表
double iIchimoku(string symbol,
                 ENUM_TIMEFRAMES timeframe,
                 int tenkan_sen,
                 int kijun_sen,
                 int senkou_span_b,
                 int mode,
                 int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _tenkan_sen[MAX_IND];
   static int _kijun_sen[MAX_IND];
   static int _senkou_span_b[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && tenkan_sen == _tenkan_sen[i]
         && kijun_sen == _kijun_sen[i]
         && senkou_span_b == _senkou_span_b[i]) break;
      }
      else
      {
         handle[i] = iIchimoku(symbol, timeframe, tenkan_sen, kijun_sen, senkou_span_b);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _tenkan_sen[i] = tenkan_sen;
         _kijun_sen[i] = kijun_sen;
         _senkou_span_b[i] = senkou_span_b;
         break;
      }
   }
   return CheckValue(i, "iIchimoku", handle[i], mode, shift);
}

//BWMFI
double iBWMFI(string symbol,
              ENUM_TIMEFRAMES timeframe,
              int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];

   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {   
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]) break;
      }
      else
      {
         handle[i] = iBWMFI(symbol, timeframe, VOLUME_TICK);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         break;
      }
   }
   return CheckValue(i, "iBWMFI", handle[i], 0, shift);
}

//モメンタム
double iMomentum(string symbol,
                 ENUM_TIMEFRAMES timeframe,
                 int period,
                 ENUM_APPLIED_PRICE applied_price,
                 int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iMomentum(symbol, timeframe, period, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iMomentum", handle[i], 0, shift);
}

//MFI
double iMFI(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int period,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];

   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {   
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]) break;
      }
      else
      {
         handle[i] = iMFI(symbol, timeframe, period, VOLUME_TICK);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         break;
      }
   }
   return CheckValue(i, "iMFI", handle[i], 0, shift);
}

//移動平均
double iMA(string symbol,
           ENUM_TIMEFRAMES timeframe,
           int period,
           int ma_shift,
           ENUM_MA_METHOD ma_method,
           ENUM_APPLIED_PRICE applied_price,
           int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   static int _ma_shift[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]
         && ma_shift == _ma_shift[i]
         && ma_method == _ma_method[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iMA(symbol, timeframe, period, ma_shift, ma_method, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         _ma_shift[i] = ma_shift;
         _ma_method[i] = ma_method;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iMA", handle[i], 0, shift);
}

//移動平均オシレーター
double iOsMA(string symbol,
             ENUM_TIMEFRAMES timeframe,
             int fast_ema_period,
             int slow_ema_period,
             int signal_period,
             ENUM_APPLIED_PRICE applied_price,
             int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _fast_ema_period[MAX_IND];
   static int _slow_ema_period[MAX_IND];
   static int _signal_period[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && fast_ema_period == _fast_ema_period[i]
         && slow_ema_period == _slow_ema_period[i]
         && signal_period == _signal_period[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iOsMA(symbol, timeframe, fast_ema_period, slow_ema_period, signal_period, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _fast_ema_period[i] = fast_ema_period;
         _slow_ema_period[i] = slow_ema_period;
         _signal_period[i] = signal_period;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iOsMA", handle[i], 0, shift);
}

//MACD
double iMACD(string symbol,
             ENUM_TIMEFRAMES timeframe,
             int fast_ema_period,
             int slow_ema_period,
             int signal_period,
             ENUM_APPLIED_PRICE applied_price,
             int mode,
             int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _fast_ema_period[MAX_IND];
   static int _slow_ema_period[MAX_IND];
   static int _signal_period[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && fast_ema_period == _fast_ema_period[i]
         && slow_ema_period == _slow_ema_period[i]
         && signal_period == _signal_period[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iMACD(symbol, timeframe, fast_ema_period, slow_ema_period, signal_period, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _fast_ema_period[i] = fast_ema_period;
         _slow_ema_period[i] = slow_ema_period;
         _signal_period[i] = signal_period;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iMACD", handle[i], mode, shift);
}

//オンバランスボリューム
double iOBV(string symbol,
            ENUM_TIMEFRAMES timeframe,
            ENUM_APPLIED_PRICE applied_price,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];

   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {   
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]) break;
      }
      else
      {
         handle[i] = iOBV(symbol, timeframe, VOLUME_TICK);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         break;
      }
   }
   return CheckValue(i, "iOBV", handle[i], 0, shift);
}

//パラボリックSAR
double iSAR(string symbol,
            ENUM_TIMEFRAMES timeframe,
            double step,
            double maximum,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static double _step[MAX_IND];
   static double _maximum[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && step == _step[i]
         && maximum == _maximum[i]) break;
      }
      else
      {
         handle[i] = iSAR(symbol, timeframe, step, maximum);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _step[i] = step;
         _maximum[i] = maximum;
         break;
      }
   }
   return CheckValue(i, "iSAR", handle[i], 0, shift);
}

//RSI
double iRSI(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int period,
            ENUM_APPLIED_PRICE applied_price,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iRSI(symbol, timeframe, period, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iRSI", handle[i], 0, shift);
}

//相対活力指数
double iRVI(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int period,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]) break;
      }
      else
      {
         handle[i] = iRVI(symbol, timeframe, period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         break;
      }
   }
   return CheckValue(i, "iRVI", handle[i], mode, shift);
}

//標準偏差
double iStdDev(string symbol,
               ENUM_TIMEFRAMES timeframe,
               int period,
               int ma_shift,
               ENUM_MA_METHOD ma_method,
               ENUM_APPLIED_PRICE applied_price,
               int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   static int _ma_shift[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]
         && ma_shift == _ma_shift[i]
         && ma_method == _ma_method[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iStdDev(symbol, timeframe, period, ma_shift, ma_method, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         _ma_shift[i] = ma_shift;
         _ma_method[i] = ma_method;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iStdDev", handle[i], 0, shift);
}

//ストキャスティックス
double iStochastic(string symbol,
                   ENUM_TIMEFRAMES timeframe,
                   int Kperiod,
                   int Dperiod,
                   int slowing,
                   ENUM_MA_METHOD ma_method,
                   ENUM_STO_PRICE price_field,
                   int mode,
                   int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _Kperiod[MAX_IND];
   static int _Dperiod[MAX_IND];
   static int _slowing[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   static ENUM_STO_PRICE _price_field[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && Kperiod == _Kperiod[i]
         && Dperiod == _Dperiod[i]
         && slowing == _slowing[i]
         && ma_method == _ma_method[i]
         && price_field == _price_field[i]) break;
      }
      else
      {
         handle[i] = iStochastic(symbol, timeframe, Kperiod, Dperiod, slowing, ma_method, price_field);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _Kperiod[i] = Kperiod;
         _Dperiod[i] = Dperiod;
         _slowing[i] = slowing;
         _ma_method[i] = ma_method;
         _price_field[i] = price_field;
         break;
      }
   }
   return CheckValue(i, "iStochastic", handle[i], mode, shift);
}

//ウィリアムパーセントレンジ
double iWPR(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int ma_period,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]) break;
      }
      else
      {
         handle[i] = iWPR(symbol, timeframe, ma_period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         break;
      }
   }
   return CheckValue(i, "iWPR", handle[i], 0, shift);
}

//AMA
double iAMA(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int ama_period,
            int fast_period,
            int slow_period,
            int ama_shift,
            ENUM_APPLIED_PRICE applied_price,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ama_period[MAX_IND];
   static int _fast_period[MAX_IND];
   static int _slow_period[MAX_IND];
   static int _ama_shift[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ama_period == _ama_period[i]
         && fast_period == _fast_period[i]
         && slow_period == _slow_period[i]
         && ama_shift == _ama_shift[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iAMA(symbol, timeframe, ama_period, fast_period, slow_period, ama_shift, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ama_period[i] = ama_period;
         _fast_period[i] = fast_period;
         _slow_period[i] = slow_period;
         _ama_shift[i] = ama_shift;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iAMA", handle[i], 0, shift);
}

//DEMA
double iDEMA(string symbol,
             ENUM_TIMEFRAMES timeframe,
             int ma_period,
             int ma_shift,
             ENUM_APPLIED_PRICE applied_price,
             int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   static int _ma_shift[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]
         && ma_shift == _ma_shift[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iDEMA(symbol, timeframe, ma_period, ma_shift, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         _ma_shift[i] = ma_shift;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iDEMA", handle[i], 0, shift);
}

//TEMA
double iTEMA(string symbol,
             ENUM_TIMEFRAMES timeframe,
             int ma_period,
             int ma_shift,
             ENUM_APPLIED_PRICE applied_price,
             int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   static int _ma_shift[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]
         && ma_shift == _ma_shift[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iTEMA(symbol, timeframe, ma_period, ma_shift, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         _ma_shift[i] = ma_shift;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iTEMA", handle[i], 0, shift);
}

//FrAMA
double iFrAMA(string symbol,
              ENUM_TIMEFRAMES timeframe,
              int ma_period,
              int ma_shift,
              ENUM_APPLIED_PRICE applied_price,
              int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   static int _ma_shift[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]
         && ma_shift == _ma_shift[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iFrAMA(symbol, timeframe, ma_period, ma_shift, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         _ma_shift[i] = ma_shift;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iFrAMA", handle[i], 0, shift);
}

//VIDyA
double iVIDyA(string symbol,
              ENUM_TIMEFRAMES timeframe,
              int cmo_period,
              int ma_period,
              int ma_shift,
              ENUM_APPLIED_PRICE applied_price,
              int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _cmo_period[MAX_IND];
   static int _ma_period[MAX_IND];
   static int _ma_shift[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && cmo_period == _cmo_period[i]
         && ma_period == _ma_period[i]
         && ma_shift == _ma_shift[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iVIDyA(symbol, timeframe, cmo_period, ma_period, ma_shift, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _cmo_period[i] = cmo_period;
         _ma_period[i] = ma_period;
         _ma_shift[i] = ma_shift;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iVIDyA", handle[i], 0, shift);
}

//ADXWilder
double iADXWilder(string symbol,
            ENUM_TIMEFRAMES timeframe,
            int period,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _period[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && period == _period[i]) break;
      }
      else
      {
         handle[i] = iADXWilder(symbol, timeframe, period);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _period[i] = period;
         break;
      }
   }
   return CheckValue(i, "iADXWilder", handle[i], mode, shift);
}

//TriX
double iTriX(string symbol,
             ENUM_TIMEFRAMES timeframe,
             int ma_period,
             ENUM_APPLIED_PRICE applied_price,
             int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _ma_period[MAX_IND];
   static ENUM_APPLIED_PRICE _applied_price[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && ma_period == _ma_period[i]
         && applied_price == _applied_price[i]) break;
      }
      else
      {
         handle[i] = iTriX(symbol, timeframe, ma_period, applied_price);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _ma_period[i] = ma_period;
         _applied_price[i] = applied_price;
         break;
      }
   }
   return CheckValue(i, "iTriX", handle[i], 0, shift);
}

//チャイキンオシレーター
double iChaikin(string symbol,
             ENUM_TIMEFRAMES timeframe,
             int fast_ma_period,
             int slow_ma_period,
             ENUM_MA_METHOD ma_method,
             int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static int _fast_ma_period[MAX_IND];
   static int _slow_ma_period[MAX_IND];
   static ENUM_MA_METHOD _ma_method[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && fast_ma_period == _fast_ma_period[i]
         && slow_ma_period == _slow_ma_period[i]
         && ma_method == _ma_method[i]) break;
      }
      else
      {
         handle[i] = iChaikin(symbol, timeframe, fast_ma_period, slow_ma_period, ma_method, VOLUME_TICK);
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _fast_ma_period[i] = fast_ma_period;
         _slow_ma_period[i] = slow_ma_period;
         _ma_method[i] = ma_method;
         break;
      }
   }
   return CheckValue(i, "iChaikin", handle[i], 0, shift);
}

//カスタム指標 no param
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 1 param
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 2 params
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            double param1,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   static double _param1[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]
         && param1 == _param1[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0, param1);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         _param1[i] = param1;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 3 params
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            double param1,
            double param2,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   static double _param1[MAX_IND];
   static double _param2[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]
         && param1 == _param1[i]
         && param2 == _param2[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0, param1, param2);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         _param1[i] = param1;
         _param2[i] = param2;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 4 params
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            double param1,
            double param2,
            double param3,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   static double _param1[MAX_IND];
   static double _param2[MAX_IND];
   static double _param3[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]
         && param1 == _param1[i]
         && param2 == _param2[i]
         && param3 == _param3[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0, param1, param2, param3);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         _param1[i] = param1;
         _param2[i] = param2;
         _param3[i] = param3;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 5 params
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            double param1,
            double param2,
            double param3,
            double param4,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   static double _param1[MAX_IND];
   static double _param2[MAX_IND];
   static double _param3[MAX_IND];
   static double _param4[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]
         && param1 == _param1[i]
         && param2 == _param2[i]
         && param3 == _param3[i]
         && param4 == _param4[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0, param1, param2, param3, param4);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         _param1[i] = param1;
         _param2[i] = param2;
         _param3[i] = param3;
         _param4[i] = param4;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 6 params
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            double param1,
            double param2,
            double param3,
            double param4,
            double param5,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   static double _param1[MAX_IND];
   static double _param2[MAX_IND];
   static double _param3[MAX_IND];
   static double _param4[MAX_IND];
   static double _param5[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]
         && param1 == _param1[i]
         && param2 == _param2[i]
         && param3 == _param3[i]
         && param4 == _param4[i]
         && param5 == _param5[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0, param1, param2, param3, param4, param5);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         _param1[i] = param1;
         _param2[i] = param2;
         _param3[i] = param3;
         _param4[i] = param4;
         _param5[i] = param5;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 7 params
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            double param1,
            double param2,
            double param3,
            double param4,
            double param5,
            double param6,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   static double _param1[MAX_IND];
   static double _param2[MAX_IND];
   static double _param3[MAX_IND];
   static double _param4[MAX_IND];
   static double _param5[MAX_IND];
   static double _param6[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]
         && param1 == _param1[i]
         && param2 == _param2[i]
         && param3 == _param3[i]
         && param4 == _param4[i]
         && param5 == _param5[i]
         && param6 == _param6[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0, param1, param2, param3, param4, param5, param6);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         _param1[i] = param1;
         _param2[i] = param2;
         _param3[i] = param3;
         _param4[i] = param4;
         _param5[i] = param5;
         _param6[i] = param6;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}

//カスタム指標 8 params
double iMyCustom(string symbol,
            ENUM_TIMEFRAMES timeframe,
            string name,
            double param0,
            double param1,
            double param2,
            double param3,
            double param4,
            double param5,
            double param6,
            double param7,
            int mode,
            int shift)
{
   static int handle[MAX_IND];
   static string _symbol[MAX_IND];
   static ENUM_TIMEFRAMES _timeframe[MAX_IND];
   static string _name[MAX_IND];
   static double _param0[MAX_IND];
   static double _param1[MAX_IND];
   static double _param2[MAX_IND];
   static double _param3[MAX_IND];
   static double _param4[MAX_IND];
   static double _param5[MAX_IND];
   static double _param6[MAX_IND];
   static double _param7[MAX_IND];
   
   if(symbol == NULL) symbol = _Symbol;
   if(timeframe == 0) timeframe = _Period;
   int i;
   for(i=0; i<MAX_IND; i++)
   {
      if(handle[i] > 0)
      {
         if(symbol == _symbol[i]
         && timeframe == _timeframe[i]
         && name == _name[i]
         && param0 == _param0[i]
         && param1 == _param1[i]
         && param2 == _param2[i]
         && param3 == _param3[i]
         && param4 == _param4[i]
         && param5 == _param5[i]
         && param6 == _param6[i]
         && param7 == _param7[i]) break;
      }
      else
      {
         #undef iCustom
         handle[i] = iCustom(symbol, timeframe, name, param0, param1, param2, param3, param4, param5, param6, param7);
         #define iCustom iMyCustom
         _symbol[i] = symbol;
         _timeframe[i] = timeframe;
         _name[i] = name;
         _param0[i] = param0;
         _param1[i] = param1;
         _param2[i] = param2;
         _param3[i] = param3;
         _param4[i] = param4;
         _param5[i] = param5;
         _param6[i] = param6;
         _param7[i] = param7;
         break;
      }
   }
   return CheckValue(i, "iCustom", handle[i], mode, shift);
}
