//+------------------------------------------------------------------+
//|                                                    Filters.mqh   |
//|  Filters.mqh - Filter-haye vorud (zaman, rooz, session, khabar,    |
//|  nosan, rovand, spread)                                            |
//|  [v1.20] Hame ba tanzimat-e Group 11/12/13 kontrol mishan va        |
//|  default-ha hame ghair-faal hastan                                  |
//+------------------------------------------------------------------+
#property strict

#ifndef __MAGICKEYS_FILTERS_MQH__
#define __MAGICKEYS_FILTERS_MQH__

#include "Settings.mqh"
#include "Dynamic.mqh"

//--- natije-ye filter
enum ENUM_FILTER_RESULT
  {
   FILTER_PASS  = 0,   // vorud mojaz ast
   FILTER_BLOCK = 1,   // vorud radd mishe (dobare talash nemishe)
   FILTER_RETRY = 2    // radd-e mowaghati (masalan spread) - mishe dobare talash kard
  };

class CTradeFilters
  {
private:
   string   m_symbol;
   int      m_trendHandle;

   //--- khabar-e dasti (zaman dar mabna-ye InpFilterTimeBasis)
   datetime m_manualNews[];

   //--- khabar-e taghvim-e MT5 (zaman-e server) - cache
   datetime m_calendarNews[];
   datetime m_calendarFetched;
   bool     m_calendarWarned;

   string   m_lastReason;

   //--- zaman be saat-e mabna (daghighe az nime-shab) va rooz-e hafte
   void NowParts(int &minutes, int &dayOfWeek)
     {
      MqlDateTime dt;
      TimeToStruct(MKBasisTime(), dt);
      minutes   = dt.hour * 60 + dt.min;
      dayOfWeek = dt.day_of_week;
     }

   bool DayAllowed(const int dayOfWeek)
     {
      switch(dayOfWeek)
        {
         case 0: return InpTradeSunday;
         case 1: return InpTradeMonday;
         case 2: return InpTradeTuesday;
         case 3: return InpTradeWednesday;
         case 4: return InpTradeThursday;
         case 5: return InpTradeFriday;
         default: return false;   // shanbe: bazar baste ast
        }
     }

   bool InSession(const bool enabled, const string range, const int nowMin)
     {
      if(!enabled)
         return false;

      int a, b;
      if(!MKParseRange(range, a, b))
         return false;

      return MKInWindow(nowMin, a, b);
     }

   //--- list-e khabar-e dasti ro parse mikone: "2026.10.21 17:30; 2026.10.28 21:00"
   void ParseManualNews()
     {
      ArrayResize(m_manualNews, 0);

      string text = InpNewsManualTimes;
      StringReplace(text, ",", ";");
      StringReplace(text, "\n", ";");

      string parts[];
      int    count = StringSplit(text, ';', parts);

      for(int i = 0; i < count; i++)
        {
         StringTrimLeft(parts[i]);
         StringTrimRight(parts[i]);
         if(StringLen(parts[i]) < 10)
            continue;

         datetime t = StringToTime(parts[i]);
         if(t <= 0)
           {
            Print("Filters: zaman-e khabar ghabel-e khoondan nist: [", parts[i], "] (format: YYYY.MM.DD HH:MM)");
            continue;
           }

         int n = ArraySize(m_manualNews);
         ArrayResize(m_manualNews, n + 1);
         m_manualNews[n] = t;
        }

      if(ArraySize(m_manualNews) > 0)
         Print("Filters: ", ArraySize(m_manualNews), " zaman-e khabar-e dasti bargozari shod.");
     }

   //--- khabar-haye taghvim-e eghtesadi-ye MT5 (hadeaksar har 10 daghighe tazeh mishe)
   void RefreshCalendar()
     {
      datetime now = TimeCurrent();
      if(m_calendarFetched != 0 && (now - m_calendarFetched) < 600)
         return;

      m_calendarFetched = now;
      ArrayResize(m_calendarNews, 0);

      if(MQLInfoInteger(MQL_TESTER) != 0)
         return;   // taghvim dar Strategy Tester dar dastres nist

      string currencies[];
      string list = InpNewsCurrencies;
      StringReplace(list, ";", ",");
      StringTrimLeft(list);
      StringTrimRight(list);

      int ccount = 0;
      if(StringLen(list) > 0)
         ccount = StringSplit(list, ',', currencies);
      else
        {
         ArrayResize(currencies, 2);
         currencies[0] = SymbolInfoString(m_symbol, SYMBOL_CURRENCY_BASE);
         currencies[1] = SymbolInfoString(m_symbol, SYMBOL_CURRENCY_PROFIT);
         ccount = 2;
        }

      datetime from = now - 86400;
      datetime to   = now + 86400;

      for(int c = 0; c < ccount; c++)
        {
         StringTrimLeft(currencies[c]);
         StringTrimRight(currencies[c]);
         if(StringLen(currencies[c]) != 3)
            continue;

         MqlCalendarValue values[];
         ResetLastError();
         bool fetched = CalendarValueHistory(values, from, to, NULL, currencies[c]);
         int  got     = ArraySize(values);

         if(!fetched)
           {
            if(!m_calendarWarned)
              {
               m_calendarWarned = true;
               Print("Filters: khoondan-e taghvim-e eghtesadi ba khata mowajeh shod (", GetLastError(),
                     ") - taghvim faghat dar terminal-e vasl be server kar mikone.");
              }
            continue;
           }

         for(int i = 0; i < got; i++)
           {
            MqlCalendarEvent ev;
            if(!CalendarEventById(values[i].event_id, ev))
               continue;

            if((int)ev.importance < (int)InpNewsMinImportance)
               continue;

            int n = ArraySize(m_calendarNews);
            ArrayResize(m_calendarNews, n + 1);
            m_calendarNews[n] = values[i].time;
           }
        }
     }

   //--- aya nazdik-e khabar hastim?
   bool NearNews(string &reason)
     {
      int before = MathMax(0, InpNewsMinutesBefore) * 60;
      int after  = MathMax(0, InpNewsMinutesAfter) * 60;

      if(InpNewsSource == NEWS_MANUAL || InpNewsSource == NEWS_BOTH)
        {
         datetime nowBasis = MKBasisTime();
         for(int i = 0; i < ArraySize(m_manualNews); i++)
           {
            if(nowBasis >= m_manualNews[i] - before && nowBasis <= m_manualNews[i] + after)
              {
               reason = "nazdik-e khabar-e dasti (" + TimeToString(m_manualNews[i], TIME_DATE | TIME_MINUTES) + ")";
               return true;
              }
           }
        }

      if(InpNewsSource == NEWS_CALENDAR || InpNewsSource == NEWS_BOTH)
        {
         RefreshCalendar();

         datetime nowServer = TimeCurrent();
         for(int i = 0; i < ArraySize(m_calendarNews); i++)
           {
            if(nowServer >= m_calendarNews[i] - before && nowServer <= m_calendarNews[i] + after)
              {
               reason = "nazdik-e khabar-e taghvim (" + TimeToString(m_calendarNews[i], TIME_DATE | TIME_MINUTES) + " zaman-e server)";
               return true;
              }
           }
        }

      return false;
     }

public:
   CTradeFilters()
     {
      m_trendHandle     = INVALID_HANDLE;
      m_calendarFetched = 0;
      m_calendarWarned  = false;
      m_lastReason      = "";
     }

   void Init(const string symbol)
     {
      m_symbol = symbol;

      ParseManualNews();

      if(InpTrendMode != TREND_OFF)
        {
         m_trendHandle = iMA(symbol, InpTrendTimeframe, MathMax(1, InpTrendMaPeriod), 0, InpTrendMaMethod, PRICE_CLOSE);
         if(m_trendHandle == INVALID_HANDLE)
            Print("Filters: sakht-e Moving Average-e rovand ba khata mowajeh shod (", GetLastError(), ") - filter-e rovand kar nemikone.");
        }
     }

   void Deinit()
     {
      if(m_trendHandle != INVALID_HANDLE)
        {
         IndicatorRelease(m_trendHandle);
         m_trendHandle = INVALID_HANDLE;
        }
     }

   string LastReason()
     {
      return m_lastReason;
     }

   //+------------------------------------------------------------------+
   //| Filter-haye mostaghel az jahat (zaman, rooz, session, khabar,     |
   //| nosan). Dar surat-e radd, reason por mishe                         |
   //+------------------------------------------------------------------+
   bool GeneralAllowed(string &reason)
     {
      int nowMin, dow;
      NowParts(nowMin, dow);

      //--- rooz va saat
      if(InpUseTimeFilter)
        {
         if(!DayAllowed(dow))
           {
            reason = "rooz-e hafte mojaz nist";
            return false;
           }

         int a = MKParseHHMM(InpTradeStartTime, 0);
         int b = MKParseHHMM(InpTradeEndTime, 1439);
         if(!MKInWindow(nowMin, a, b))
           {
            reason = "kharej az saat-e mojaz (" + InpTradeStartTime + " ta " + InpTradeEndTime + ")";
            return false;
           }
        }

      //--- session
      if(InpUseSessionFilter)
        {
         bool anyEnabled = (InpSessionAsia || InpSessionLondon || InpSessionNewYork);
         if(anyEnabled &&
            !InSession(InpSessionAsia, InpSessionAsiaTime, nowMin) &&
            !InSession(InpSessionLondon, InpSessionLondonTime, nowMin) &&
            !InSession(InpSessionNewYork, InpSessionNewYorkTime, nowMin))
           {
            reason = "kharej az session-haye entekhab-shode";
            return false;
           }
        }

      //--- cut-off-e jom'e
      if(InpFridayCutoffEnable && dow == 5 && nowMin >= MKParseHHMM(InpFridayCutoffTime, 1200))
        {
         reason = "cut-off-e jom'e (" + InpFridayCutoffTime + ")";
         return false;
        }

      //--- khabar
      if(InpUseNewsFilter)
        {
         string newsReason;
         if(NearNews(newsReason))
           {
            reason = newsReason;
            return false;
           }
        }

      //--- nosan
      if(InpUseVolatilityFilter)
        {
         bool   ok;
         double atr = MKAtrPips(ok);
         if(ok)
           {
            if(InpVolMinAtrPips > 0.0 && atr < InpVolMinAtrPips)
              {
               reason = "ATR (" + DoubleToString(atr, 1) + " pip) kamtar az hadeaghal (" + DoubleToString(InpVolMinAtrPips, 1) + ")";
               return false;
              }
            if(InpVolMaxAtrPips > 0.0 && atr > InpVolMaxAtrPips)
              {
               reason = "ATR (" + DoubleToString(atr, 1) + " pip) bishtar az hadeaksar (" + DoubleToString(InpVolMaxAtrPips, 1) + ")";
               return false;
              }
           }
        }

      return true;
     }

   //+------------------------------------------------------------------+
   //| Barresi-ye kamel baraye ye vorud (jahat + fasele-ye SL be pip)    |
   //+------------------------------------------------------------------+
   ENUM_FILTER_RESULT Check(const ENUM_POSITION_TYPE direction, const double slPips, string &reason)
     {
      reason = "";

      if(!GeneralAllowed(reason))
        {
         m_lastReason = reason;
         return FILTER_BLOCK;
        }

      //--- rovand
      if(InpTrendMode != TREND_OFF && m_trendHandle != INVALID_HANDLE)
        {
         double ma[];
         ArraySetAsSeries(ma, true);
         if(CopyBuffer(m_trendHandle, 0, 1, 1, ma) >= 1 && ma[0] > 0.0)
           {
            double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
            bool   above = (price > ma[0]);
            bool   buy   = (direction == POSITION_TYPE_BUY);

            bool allowed = (InpTrendMode == TREND_WITH) ? (buy == above) : (buy != above);
            if(!allowed)
              {
               reason = StringFormat("filter-e rovand: gheimat %s Moving Average (%s) ast va jahat (%s) ba tanzim (%s) nemikhoone",
                                     (above ? "bala-ye" : "paiin-e"), DoubleToString(ma[0], (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)),
                                     (buy ? "Kharid" : "Forush"), (InpTrendMode == TREND_WITH ? "ham-jahat" : "bargasht"));
               m_lastReason = reason;
               return FILTER_BLOCK;
              }
           }
        }

      //--- spread nesbat be SL (mowaghati - mishe dobare talash kard)
      if(InpMaxSpreadPercentOfSL > 0.0 && slPips > 0.0)
        {
         double pip = MKPipSize(m_symbol);
         if(pip > 0.0)
           {
            double spreadPips = (SymbolInfoDouble(m_symbol, SYMBOL_ASK) - SymbolInfoDouble(m_symbol, SYMBOL_BID)) / pip;
            double pct        = spreadPips / slPips * 100.0;
            if(pct > InpMaxSpreadPercentOfSL)
              {
               reason = "spread (" + DoubleToString(spreadPips, 1) + " pip) = " + DoubleToString(pct, 1) + "% az SL (hadd: " +
                        DoubleToString(InpMaxSpreadPercentOfSL, 1) + "%)";
               m_lastReason = reason;
               return FILTER_RETRY;
              }
           }
        }

      m_lastReason = "";
      return FILTER_PASS;
     }
  };

#endif // __MAGICKEYS_FILTERS_MQH__
//+------------------------------------------------------------------+
