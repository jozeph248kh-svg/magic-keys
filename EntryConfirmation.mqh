//+------------------------------------------------------------------+
//|                                           EntryConfirmation.mqh  |
//|  EntryConfirmation.mqh - Tayidiye va Vorud be Moamele              |
//|  Vazife: barresi-ye pattern-haye candle-i-e tayid-konande (Doji,   |
//|          Pinbar, Engulfing) rooye akharin candle-ye baste-shode va tasmim-    |
//|          giri baraye vorud be moamele                              |
//|                                                                    |
//|  Vabastegi: in module az CCandleAnalyzer baraye tashkhis-e candle  |
//|  estefade mikone                                                   |
//+------------------------------------------------------------------+
#property strict

#include "Settings.mqh"
#include "CandleAnalyzer.mqh"

//--- Natije-ye nahaii-e tasmim-e vorud
enum ENUM_ENTRY_SIGNAL
  {
   ENTRY_NONE,   // hich tayidiye-i peida nashod - vared nasho
   ENTRY_BUY,    // tayidiye-ye kharid peida shod
   ENTRY_SELL    // tayidiye-ye forush peida shod
  };

//+------------------------------------------------------------------+
//| Class Tayidiye va Vorud be Moamele                                |
//+------------------------------------------------------------------+
class CEntryConfirmation
  {
private:
   CCandleAnalyzer m_candleAnalyzer;
   string          m_symbol;
   ENUM_TIMEFRAMES m_timeframe;

   //--- jelogiri az vorud-e tekrari rooye ye candle-ye tekrari
   datetime        m_lastSignalCandleTime;

public:
   void Init(string symbol, ENUM_TIMEFRAMES timeframe)
     {
      m_symbol    = symbol;
      m_timeframe = timeframe;
      m_candleAnalyzer.Init(symbol, timeframe);
      m_lastSignalCandleTime = 0;
     }

   //+------------------------------------------------------------------+
   //| Barresi-ye akharin candle-ye baste-shode (shift = 1) va          |
   //| bargashtan-e signal-e vorud.                                      |
   //| Tavajoh: shift 0 candle-ye dar hale tashkile va hanooz baste      |
   //|          nashode, pas hamishe az shift = 1 baraye tasmimgiri     |
   //|          estefade mikonim                                         |
   //+------------------------------------------------------------------+
   ENUM_ENTRY_SIGNAL CheckConfirmation()
     {
      SCandleInfo candle;
      if(!m_candleAnalyzer.GetCandle(1, candle))
         return ENTRY_NONE;

      //--- jelogiri az sodoor-e signal-e tekrari rooye hamoon candle-ye ghabli
      if(candle.time == m_lastSignalCandleTime)
         return ENTRY_NONE;

      ENUM_CANDLE_PATTERN pattern = m_candleAnalyzer.DetectPattern(1);

      ENUM_ENTRY_SIGNAL signal = ENTRY_NONE;

      //--- Tayidiye bar asas-e Doji: jahat-e vorud ro az candle-ye ghabl az Doji (trend-e ghabli) tashkhis midim
      if(InpUseDojiConfirmation && pattern == PATTERN_DOJI)
        {
         signal = GetTrendDirectionFromPriorCandles(2);
        }

      //--- Tayidiye bar asas-e Pinbar
      if(signal == ENTRY_NONE && InpUsePinbarConfirmation)
        {
         //--- [v1.11] Hammer/Shooting Star ham Pinbar hastan (DetectPinbar mostaghel az DetectPattern check mikone)
         int pin = m_candleAnalyzer.DetectPinbar(1);
         if(pin > 0)
            signal = ENTRY_BUY;
         else if(pin < 0)
            signal = ENTRY_SELL;
        }

      //--- Tayidiye bar asas-e Engulfing (jahat az khod-e pattern miyad: soodi = Kharid, nozooli = Forush)
      if(signal == ENTRY_NONE && InpUseEngulfingConfirmation)
        {
         int engulf = m_candleAnalyzer.DetectEngulfing(1);
         if(engulf > 0)
            signal = ENTRY_BUY;
         else if(engulf < 0)
            signal = ENTRY_SELL;
        }

      if(signal != ENTRY_NONE)
         m_lastSignalCandleTime = candle.time;

      return signal;
     }

   //+------------------------------------------------------------------+
   //| Tashkhis-e jahat-e trend az chand candle-ye ghabl (baraye        |
   //| tasmimgiri-ye jahat ba'd az Doji) - sadeh: bar asas-e jahat-e     |
   //| candle-ye moshakhas-shode ba shift                                |
   //+------------------------------------------------------------------+
   ENUM_ENTRY_SIGNAL GetTrendDirectionFromPriorCandles(int shift)
     {
      SCandleInfo prior;
      if(!m_candleAnalyzer.GetCandle(shift, prior))
         return ENTRY_NONE;

      if(prior.direction == CANDLE_BULLISH)
         return ENTRY_BUY;
      if(prior.direction == CANDLE_BEARISH)
         return ENTRY_SELL;

      return ENTRY_NONE;
     }

   //+------------------------------------------------------------------+
   //| Tabdil-e signal be reshte (baraye log ya panel)                   |
   //+------------------------------------------------------------------+
   string SignalToString(ENUM_ENTRY_SIGNAL signal)
     {
      switch(signal)
        {
         case ENTRY_BUY:  return "Kharid (Buy)";
         case ENTRY_SELL: return "Forush (Sell)";
         default:         return "Bedoone Signal";
        }
     }
  };
//+------------------------------------------------------------------+
