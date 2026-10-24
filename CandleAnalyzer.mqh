//+------------------------------------------------------------------+
//|                                              CandleAnalyzer.mqh  |
//|  CandleAnalyzer.mqh - Tashkhis va Shenasaii-e Candle-ha            |
//|  Vazife: khoondan-e etelaat-e OHLC-e har candle va tashkhis-e      |
//|          noe/pattern-e oon (soodi/nozooli, Doji, Pinbar/Hammer,    |
//|          Engulfing, ...)                                           |
//+------------------------------------------------------------------+
#property strict

#include "Settings.mqh"   // InpDojiBodyRatio va InpMarubozuWickRatio markazi az inja miyan

//--- Anvae candle az nazar-e jahat
enum ENUM_CANDLE_DIRECTION
  {
   CANDLE_BULLISH,   // soodi (sabz) - Close > Open
   CANDLE_BEARISH,   // nozooli (ghermez) - Close < Open
   CANDLE_DOJI       // khonsa - Close taghriban barabar Open
  };

//--- Pattern-haye tak-candle-i shenakhte-shode
enum ENUM_CANDLE_PATTERN
  {
   PATTERN_NONE,             // hich pattern-i tashkhis dade nashod
   PATTERN_DOJI,             // Doji
   PATTERN_HAMMER,           // Hammer (sayeh-ye paiin boland, badaneh koochik bala) - signal-e bargasht-e soodi
   PATTERN_INVERTED_HAMMER,  // Hammer-e ma'kus (sayeh-ye bala boland)
   PATTERN_SHOOTING_STAR,    // Shooting Star - signal-e bargasht-e nozooli
   PATTERN_HANGING_MAN,      // Hanging Man
   PATTERN_MARUBOZU_BULL,    // Marubozu-ye soodi (bedoone sayeh, por-ghodrat)
   PATTERN_MARUBOZU_BEAR,    // Marubozu-ye nozooli
   PATTERN_ENGULFING_BULL,   // Engulfing-e soodi (niaz be candle-ye ghabli)
   PATTERN_ENGULFING_BEAR,   // Engulfing-e nozooli (niaz be candle-ye ghabli)
   PATTERN_PINBAR_BULL,      // Pinbar-e soodi
   PATTERN_PINBAR_BEAR       // Pinbar-e nozooli
  };

//--- Sakhtar-e etelaat-e kamel-e ye candle
struct SCandleInfo
  {
   datetime time;
   double   open;
   double   high;
   double   low;
   double   close;
   double   bodySize;      // andaze-ye badaneh = |Close - Open|
   double   upperWick;     // andaze-ye sayeh-ye bala
   double   lowerWick;     // andaze-ye sayeh-ye paiin
   double   totalRange;    // kolle range-e candle = High - Low
   ENUM_CANDLE_DIRECTION direction;
  };

//+------------------------------------------------------------------+
//| Class Tahlil va Tashkhis-e Candle                                 |
//+------------------------------------------------------------------+
class CCandleAnalyzer
  {
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframe;

public:
   void Init(string symbol, ENUM_TIMEFRAMES timeframe)
     {
      m_symbol    = symbol;
      m_timeframe = timeframe;
      //--- nesbat-haye tashkhis-e Doji/Marubozu digeh inja hardcode nistan,
      //--- mostaghiman az Settings.mqh (InpDojiBodyRatio, InpMarubozuWickRatio) khoonde mishan
     }

   //+------------------------------------------------------------------+
   //| Khoondan-e etelaat-e kamel-e ye candle bar asas-e shift          |
   //| (0 = candle-ye fe'li dar hale tashkil) (1 = akharin candle-ye    |
   //| baste-shode)                                                      |
   //+------------------------------------------------------------------+
   bool GetCandle(int shift, SCandleInfo &info)
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);

      if(CopyRates(m_symbol, m_timeframe, shift, 1, rates) < 1)
        {
         Print("CandleAnalyzer: khata dar khoondan-e candle-ye shomare ", shift, " - ", GetLastError());
         return false;
        }

      info.time   = rates[0].time;
      info.open   = rates[0].open;
      info.high   = rates[0].high;
      info.low    = rates[0].low;
      info.close  = rates[0].close;

      info.bodySize   = MathAbs(info.close - info.open);
      info.totalRange = info.high - info.low;

      if(info.close >= info.open)
        {
         info.upperWick = info.high - info.close;
         info.lowerWick = info.open - info.low;
        }
      else
        {
         info.upperWick = info.high - info.open;
         info.lowerWick = info.close - info.low;
        }

      info.direction = GetDirection(info);

      return true;
     }

   //+------------------------------------------------------------------+
   //| Tashkhis-e jahat-e candle (soodi/nozooli/doji)                    |
   //+------------------------------------------------------------------+
   ENUM_CANDLE_DIRECTION GetDirection(const SCandleInfo &info)
     {
      if(info.totalRange <= 0)
         return CANDLE_DOJI;

      double bodyRatio = info.bodySize / info.totalRange;

      if(bodyRatio <= InpDojiBodyRatio)
         return CANDLE_DOJI;

      return (info.close > info.open) ? CANDLE_BULLISH : CANDLE_BEARISH;
     }

   //+------------------------------------------------------------------+
   //| [v1.20] Range-e candle be pip                                      |
   //+------------------------------------------------------------------+
   double RangePips(const SCandleInfo &c)
     {
      double pip = MKPipSize(m_symbol);
      return (pip > 0.0) ? c.totalRange / pip : 0.0;
     }

   //+------------------------------------------------------------------+
   //| [v1.20] Noe-e Doji (faghat baraye candle-i ke direction = DOJI)    |
   //+------------------------------------------------------------------+
   ENUM_DOJI_TYPE DojiSubtype(const SCandleInfo &c)
     {
      if(c.totalRange <= 0.0)
         return DOJI_STANDARD;

      double upper = c.upperWick / c.totalRange;
      double lower = c.lowerWick / c.totalRange;

      bool upperShort = (upper <= InpDojiShortWickRatio);
      bool lowerShort = (lower <= InpDojiShortWickRatio);
      bool upperLong  = (upper >= InpDojiLongWickRatio);
      bool lowerLong  = (lower >= InpDojiLongWickRatio);

      if(upperShort && lowerLong)
         return DOJI_DRAGONFLY;
      if(lowerShort && upperLong)
         return DOJI_GRAVESTONE;
      if(upperLong && lowerLong)
         return DOJI_LONGLEGGED;

      return DOJI_STANDARD;
     }

   //+------------------------------------------------------------------+
   //| [v1.20] Aya in candle (ba direction = DOJI) ba tanzimat-e Doji     |
   //| (range-e hadeaghal, noe-e Doji) ghabul hast?                       |
   //+------------------------------------------------------------------+
   bool DojiAccepted(const SCandleInfo &c)
     {
      if(c.totalRange <= 0.0)
         return false;

      if(InpDojiMinRangePips > 0.0 && RangePips(c) < InpDojiMinRangePips)
         return false;

      if(InpDojiTypeFilter != DOJI_ANY && DojiSubtype(c) != InpDojiTypeFilter)
         return false;

      return true;
     }

   //+------------------------------------------------------------------+
   //| [v1.20] Noe-e Doji-ye candle-e shift; DOJI_ANY = Doji nist ya      |
   //| ba tanzimat ghabul nist                                            |
   //+------------------------------------------------------------------+
   ENUM_DOJI_TYPE DojiTypeAt(int shift)
     {
      SCandleInfo c;
      if(!GetCandle(shift, c) || c.direction != CANDLE_DOJI || !DojiAccepted(c))
         return DOJI_ANY;

      return DojiSubtype(c);
     }

   //+------------------------------------------------------------------+
   //| [v1.20] Shart-haye ezafi-e Engulfing (InpEngulf*)                  |
   //+------------------------------------------------------------------+
   bool EngulfExtraOk(const SCandleInfo &cur, const SCandleInfo &prev)
     {
      if(InpEngulfMinBodyMult > 0.0 && cur.bodySize < prev.bodySize * InpEngulfMinBodyMult)
         return false;

      if(InpEngulfMinBodyPercent > 0.0 && cur.totalRange > 0.0 &&
         (cur.bodySize / cur.totalRange) < InpEngulfMinBodyPercent)
         return false;

      double pip = MKPipSize(m_symbol);
      if(InpEngulfMinBodyPips > 0.0 && pip > 0.0 && (cur.bodySize / pip) < InpEngulfMinBodyPips)
         return false;

      if(InpEngulfFullRange && (cur.high < prev.high || cur.low > prev.low))
         return false;

      return true;
     }

   //+------------------------------------------------------------------+
   //| [v1.20] Shekl-e Pinbar: sayeh-ye asli (mainWick) ba tanzimat       |
   //+------------------------------------------------------------------+
   bool PinShape(const double mainWick, const double oppWick, const SCandleInfo &c)
     {
      if(c.totalRange <= 0.0)
         return false;

      bool ratioRule  = (mainWick / c.totalRange >= InpPinWickRatio);
      bool hammerRule = (InpPinUseHammerShape &&
                         mainWick >= c.bodySize * InpPinWickToBodyRatio &&
                         oppWick <= c.bodySize * InpPinOppWickToBodyRatio);

      if(!ratioRule && !hammerRule)
         return false;

      if(oppWick / c.totalRange > InpPinOppWickMaxRatio)
         return false;

      if(c.bodySize / c.totalRange > InpPinBodyMaxRatio)
         return false;

      return true;
     }

   //+------------------------------------------------------------------+
   //| Tashkhis-e pattern-e candle bar asas-e shift - baraye pattern-   |
   //| haye do-candle-i ham candle-ye ghabli (shift+1) ro mikhoone       |
   //+------------------------------------------------------------------+
   ENUM_CANDLE_PATTERN DetectPattern(int shift)
     {
      SCandleInfo cur, prev;

      if(!GetCandle(shift, cur))
         return PATTERN_NONE;

      if(cur.totalRange <= 0)
         return PATTERN_NONE;

      //--- Doji [v1.20: ba tanzimat-e noe/range]
      if(cur.direction == CANDLE_DOJI)
         return DojiAccepted(cur) ? PATTERN_DOJI : PATTERN_NONE;

      double bodyRatio  = cur.bodySize / cur.totalRange;
      double upperRatio = cur.upperWick / cur.totalRange;
      double lowerRatio = cur.lowerWick / cur.totalRange;

      //--- Marubozu (taghriban bedoone sayeh)
      if(upperRatio <= InpMarubozuWickRatio && lowerRatio <= InpMarubozuWickRatio)
         return (cur.direction == CANDLE_BULLISH) ? PATTERN_MARUBOZU_BULL : PATTERN_MARUBOZU_BEAR;

      //--- Hammer / Hanging Man: sayeh-ye paiin boland (hadeaghal 2 barabar-e badaneh), sayeh-ye bala koochik
      if(cur.lowerWick >= cur.bodySize * 2.0 && cur.upperWick <= cur.bodySize * 0.5)
         return (cur.direction == CANDLE_BULLISH) ? PATTERN_HAMMER : PATTERN_HANGING_MAN;

      //--- Shooting Star / Inverted Hammer: sayeh-ye bala boland, sayeh-ye paiin koochik
      if(cur.upperWick >= cur.bodySize * 2.0 && cur.lowerWick <= cur.bodySize * 0.5)
         return (cur.direction == CANDLE_BEARISH) ? PATTERN_SHOOTING_STAR : PATTERN_INVERTED_HAMMER;

      //--- Pinbar (nesghe-ye koli-tar: ye sayeh hadeaghal 60% kolle range bashe)
      if(lowerRatio >= InpPinWickRatio)
         return PATTERN_PINBAR_BULL;
      if(upperRatio >= InpPinWickRatio)
         return PATTERN_PINBAR_BEAR;

      //--- Pattern-haye do-candle-i: niaz be candle-ye ghabli
      if(GetCandle(shift + 1, prev))
        {
         //--- Engulfing-e soodi: candle-ye ghabli nozooli, candle-ye fe'li soodi va badanesh candle-ye ghabli ro kamel mipooshoone
         if(prev.direction == CANDLE_BEARISH && cur.direction == CANDLE_BULLISH &&
            cur.open <= prev.close && cur.close >= prev.open && EngulfExtraOk(cur, prev))
            return PATTERN_ENGULFING_BULL;

         //--- Engulfing-e nozooli: candle-ye ghabli soodi, candle-ye fe'li nozooli va badanesh candle-ye ghabli ro kamel mipooshoone
         if(prev.direction == CANDLE_BULLISH && cur.direction == CANDLE_BEARISH &&
            cur.open >= prev.close && cur.close <= prev.open && EngulfExtraOk(cur, prev))
            return PATTERN_ENGULFING_BEAR;
        }

      return PATTERN_NONE;
     }

   //+------------------------------------------------------------------+
   //| Tashkhis-e Engulfing rooye candle-ye shift (mostaghel az          |
   //| DetectPattern).                                                    |
   //| Dalil: dar DetectPattern, check-haye Marubozu/Hammer/Pinbar ghabl |
   //| az Engulfing miyan va ye candle-e engulfing-e ghavi (masalan ba   |
   //| sayeh-ye boland ya bedoone sayeh) ghabl az residan be Engulfing   |
   //| ba'zi vaght be onvan-e pattern-e digeh shenakhte mishe. In tabe'  |
   //| faghat be shart-e Engulfing negah mikone.                          |
   //|   +1 = Engulfing-e Soodi (signal-e Kharid)                         |
   //|   -1 = Engulfing-e Nozooli (signal-e Forush)                       |
   //|    0 = Engulfing nist                                              |
   //+------------------------------------------------------------------+
   int DetectEngulfing(int shift)
     {
      SCandleInfo cur, prev;

      if(!GetCandle(shift, cur) || !GetCandle(shift + 1, prev))
         return 0;

      if(cur.totalRange <= 0 || prev.totalRange <= 0)
         return 0;

      //--- Engulfing-e soodi: candle-ye ghabli nozooli, candle-ye fe'li soodi va badanesh badaneh-ye ghabli ro kamel mipooshoone
      if(prev.direction == CANDLE_BEARISH && cur.direction == CANDLE_BULLISH &&
         cur.open <= prev.close && cur.close >= prev.open && EngulfExtraOk(cur, prev))
         return 1;

      //--- Engulfing-e nozooli: candle-ye ghabli soodi, candle-ye fe'li nozooli va badanesh badaneh-ye ghabli ro kamel mipooshoone
      if(prev.direction == CANDLE_BULLISH && cur.direction == CANDLE_BEARISH &&
         cur.open >= prev.close && cur.close <= prev.open && EngulfExtraOk(cur, prev))
         return -1;

      return 0;
     }

   //+------------------------------------------------------------------+
   //| [v1.11] Tashkhis-e Pinbar rooye candle-ye shift (mostaghel az     |
   //| DetectPattern).                                                    |
   //| Dalil: dar DetectPattern, shekl-haye Hammer / Hanging Man /       |
   //| Shooting Star / Inverted Hammer ghabl az Pinbar check mishan va   |
   //| be onvan-e pattern-e joda bar-gardoonde mishan, dar natije        |
   //| Pinbar-haye "tamiz" (sayeh-ye boland + badaneh-ye koochik) hargez |
   //| be onvan-e Pinbar shenakhte nemishodan va tayidiye nemidadan.     |
   //| Jahat az rooye sayeh miad (na rang-e candle):                      |
   //|   +1 = Pinbar-e soodi (sayeh-ye paiin-e boland)                   |
   //|   -1 = Pinbar-e nozooli (sayeh-ye bala-ye boland)                 |
   //|    0 = Pinbar nist                                                 |
   //+------------------------------------------------------------------+
   int DetectPinbar(int shift)
     {
      SCandleInfo cur;
      if(!GetCandle(shift, cur) || cur.totalRange <= 0)
         return 0;

      //--- [v1.20] hadeaghal/hadeaksar range-e candle (pip)
      double rangePips = RangePips(cur);
      if(InpPinMinRangePips > 0.0 && rangePips < InpPinMinRangePips)
         return 0;
      if(InpPinMaxRangePips > 0.0 && rangePips > InpPinMaxRangePips)
         return 0;

      //--- sayeh-ye paiin-e boland (soodi) ya sayeh-ye bala-ye boland (nozooli), ba tanzimat-e InpPin*
      int dir = 0;
      if(PinShape(cur.lowerWick, cur.upperWick, cur))
         dir = 1;
      else if(PinShape(cur.upperWick, cur.lowerWick, cur))
         dir = -1;

      if(dir == 0)
         return 0;

      //--- [v1.20] mahal-e badaneh: dar sevom-e door az sayeh
      if(InpPinBodyPosition == PINPOS_FAR_THIRD)
        {
         double bodyLow  = MathMin(cur.open, cur.close);
         double bodyHigh = MathMax(cur.open, cur.close);

         if(dir > 0 && bodyLow < cur.low + cur.totalRange * 2.0 / 3.0)
            return 0;
         if(dir < 0 && bodyHigh > cur.low + cur.totalRange / 3.0)
            return 0;
        }

      //--- [v1.20] rang-e candle ham-jahat ba Pinbar
      if(InpPinCandleColor == PINCOL_WITH_DIRECTION)
        {
         if(dir > 0 && cur.close <= cur.open)
            return 0;
         if(dir < 0 && cur.close >= cur.open)
            return 0;
        }

      //--- [v1.20] sayeh bayad Low/High-e candle-e ghabli ro jaroo karde bashe
      if(InpPinMustSweepPrev)
        {
         SCandleInfo prev;
         if(!GetCandle(shift + 1, prev))
            return 0;

         if(dir > 0 && cur.low >= prev.low)
            return 0;
         if(dir < 0 && cur.high <= prev.high)
            return 0;
        }

      return dir;
     }

   //+------------------------------------------------------------------+
   //| Tabdil-e enum-e jahat-e candle be reshte (baraye log ya panel)   |
   //+------------------------------------------------------------------+
   string DirectionToString(ENUM_CANDLE_DIRECTION dir)
     {
      switch(dir)
        {
         case CANDLE_BULLISH: return "Soodi (Bullish)";
         case CANDLE_BEARISH: return "Nozooli (Bearish)";
         case CANDLE_DOJI:    return "Doji";
        }
      return "Na-moshakhas";
     }

   //+------------------------------------------------------------------+
   //| Tabdil-e enum-e pattern be reshte (baraye log ya panel)           |
   //+------------------------------------------------------------------+
   string PatternToString(ENUM_CANDLE_PATTERN pattern)
     {
      switch(pattern)
        {
         case PATTERN_DOJI:            return "Doji";
         case PATTERN_HAMMER:          return "Hammer";
         case PATTERN_INVERTED_HAMMER: return "Inverted Hammer";
         case PATTERN_SHOOTING_STAR:   return "Shooting Star";
         case PATTERN_HANGING_MAN:     return "Hanging Man";
         case PATTERN_MARUBOZU_BULL:   return "Marubozu Soodi";
         case PATTERN_MARUBOZU_BEAR:   return "Marubozu Nozooli";
         case PATTERN_ENGULFING_BULL:  return "Engulfing Soodi";
         case PATTERN_ENGULFING_BEAR:  return "Engulfing Nozooli";
         case PATTERN_PINBAR_BULL:     return "Pinbar Soodi";
         case PATTERN_PINBAR_BEAR:     return "Pinbar Nozooli";
         default:                      return "Bedoone Pattern";
        }
     }
  };
//+------------------------------------------------------------------+
