//+------------------------------------------------------------------+
//|                                              PositionExtras.mqh  |
//|  PositionExtras.mqh - Modiriat-e ezafe-ye position-ha              |
//|  [v1.20] Trailing Stop (sabet / ATR / candle), Breakeven-e          |
//|  mostaghel, khorooj-e zamani, bastan-e hame-ye moamele-ha dar jom'e |
//|  Hame ba tanzimat-e Group 4c va 11 kontrol mishan                   |
//|  (default = ghair-faal)                                             |
//+------------------------------------------------------------------+
#property strict

#ifndef __MAGICKEYS_POSITIONEXTRAS_MQH__
#define __MAGICKEYS_POSITIONEXTRAS_MQH__

#include <Trade\Trade.mqh>
#include "Settings.mqh"
#include "Dynamic.mqh"

class CPositionExtras
  {
private:
   string   m_symbol;
   CTrade   m_trade;
   double   m_pip;
   double   m_point;
   int      m_digits;
   datetime m_lastFridayTry;
   datetime m_lastErr;

   bool IsMine(const long magic, const bool includeManual)
     {
      return (magic == (long)MKMagic(1) || magic == (long)MKMagic(2) || (includeManual && magic == 0));
     }

   //--- kam-tarin fasele-ye mojaz-e SL az gheimat (Stops Level / Freeze Level-e broker)
   double MinStopDistance()
     {
      long stops  = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      long freeze = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      return (double)MathMax(stops, freeze) * m_point;
     }

   void LogError(const string what, const ulong ticket)
     {
      if(TimeCurrent() - m_lastErr < 5)
         return;
      m_lastErr = TimeCurrent();
      Print("PositionExtras: khata dar ", what, " (ticket ", ticket, ") - ", m_trade.ResultRetcodeDescription());
     }

   //--- SL-e pishnahadi-ye trailing baraye ye position (0 = nadarim)
   double TrailCandidate(const ENUM_POSITION_TYPE type, const double bid, const double ask)
     {
      bool buy = (type == POSITION_TYPE_BUY);

      if(InpTrailMode == TRAIL_FIXED)
        {
         double dist = MathMax(1, InpTrailDistancePips) * m_pip;
         return buy ? bid - dist : ask + dist;
        }

      if(InpTrailMode == TRAIL_ATR)
        {
         bool   ok;
         double atr = MKAtrPips(ok);
         if(!ok)
            return 0.0;

         double dist = atr * InpTrailAtrMult * m_pip;
         return buy ? bid - dist : ask + dist;
        }

      if(InpTrailMode == TRAIL_CANDLE)
        {
         int count = MathMax(1, InpTrailCandleCount);
         double arr[];
         ArraySetAsSeries(arr, true);
         double offset = MathMax(0.0, InpTrailCandleOffsetPips) * m_pip;

         if(buy)
           {
            if(CopyLow(m_symbol, MKAnalysisTf(), 1, count, arr) < count)
               return 0.0;
            return arr[ArrayMinimum(arr, 0, count)] - offset;
           }

         if(CopyHigh(m_symbol, MKAnalysisTf(), 1, count, arr) < count)
            return 0.0;
         return arr[ArrayMaximum(arr, 0, count)] + offset;
        }

      return 0.0;
     }

public:
   CPositionExtras()
     {
      m_pip           = 0.0;
      m_point         = 0.0;
      m_digits        = 0;
      m_lastFridayTry = 0;
      m_lastErr       = 0;
     }

   void Init(const string symbol)
     {
      m_symbol = symbol;
      m_pip    = MKPipSize(symbol);
      m_point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
      m_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

      m_trade.SetExpertMagicNumber(MKMagic(0));
      m_trade.SetDeviationInPoints((ulong)MathMax(0, InpDeviationPoints));
      m_trade.SetTypeFillingBySymbol(symbol);
     }

   //+------------------------------------------------------------------+
   //| Har tick: trailing, breakeven-e mostaghel, khorooj-e zamani       |
   //+------------------------------------------------------------------+
   void Manage(const bool includeManual)
     {
      bool wantTrail = (InpTrailMode != TRAIL_OFF);
      bool wantBe    = (InpAutoBreakEvenPips > 0.0);
      bool wantTime  = (InpTimeExitHours > 0);

      if(!wantTrail && !wantBe && !wantTime)
         return;

      if(m_pip <= 0.0)
         return;

      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      if(bid <= 0.0 || ask <= 0.0)
         return;

      double minDist = MinStopDistance();

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         long magic = PositionGetInteger(POSITION_MAGIC);
         if(!IsMine(magic, includeManual))
            continue;

         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         bool   buy    = (type == POSITION_TYPE_BUY);
         double open   = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl     = PositionGetDouble(POSITION_SL);
         double tp     = PositionGetDouble(POSITION_TP);
         double price  = buy ? bid : ask;
         double profitPips = (buy ? (price - open) : (open - price)) / m_pip;

         //--- khorooj-e zamani
         if(wantTime)
           {
            datetime opened = (datetime)PositionGetInteger(POSITION_TIME);
            if(TimeCurrent() - opened >= (datetime)(InpTimeExitHours * 3600) &&
               (!InpTimeExitOnlyLosing || profitPips <= 0.0))
              {
               if(m_trade.PositionClose(ticket))
                  Print("PositionExtras: position ", ticket, " ba'd az ", InpTimeExitHours, " saat baste shod (khorooj-e zamani, sood ",
                        DoubleToString(profitPips, 1), " pip).");
               else
                  LogError("khorooj-e zamani", ticket);
               continue;
              }
           }

         double newSL = 0.0;

         //--- Breakeven-e mostaghel
         if(wantBe && profitPips >= InpAutoBreakEvenPips)
           {
            double be = MKBreakEvenPrice(type, open, m_pip, m_digits);
            bool better = (sl <= 0.0) || (buy ? be > sl : be < sl);
            bool valid  = buy ? (be < bid - minDist) : (be > ask + minDist);
            if(better && valid)
               newSL = be;
           }

         //--- Trailing
         if(wantTrail && profitPips >= InpTrailStartPips &&
            (InpTrailApplyTo == TRAILAPPLY_ALL || magic != (long)MKMagic(1)))
           {
            double cand = TrailCandidate(type, bid, ask);
            if(cand > 0.0)
              {
               cand = NormalizeDouble(cand, m_digits);

               if(InpTrailNeverBelowEntry && (buy ? cand < open : cand > open))
                  cand = 0.0;

               double step = MathMax(0.0, InpTrailStepPips) * m_pip;
               double base = (newSL > 0.0) ? newSL : sl;
               bool   better = (base <= 0.0) || (buy ? cand > base + step : cand < base - step);
               bool   valid  = buy ? (cand < bid - minDist) : (cand > ask + minDist);

               if(cand > 0.0 && better && valid)
                  newSL = cand;
              }
           }

         if(newSL > 0.0)
           {
            newSL = NormalizeDouble(newSL, m_digits);
            if(!m_trade.PositionModify(ticket, newSL, tp))
               LogError("jabeja-i-e SL (trailing/breakeven)", ticket);
           }
        }
     }

   //+------------------------------------------------------------------+
   //| Jom'e dar saat-e InpFridayCloseTime hame-ye moamele-haye EA baste |
   //| mishan (hadeaksar yek talash dar daghighe)                         |
   //+------------------------------------------------------------------+
   int FridayClose(const bool includeManual)
     {
      if(!InpFridayCloseAll)
         return 0;

      MqlDateTime dt;
      TimeToStruct(MKBasisTime(), dt);

      if(dt.day_of_week != 5)
         return 0;

      int nowMin = dt.hour * 60 + dt.min;
      if(nowMin < MKParseHHMM(InpFridayCloseTime, 1320))
         return 0;

      datetime now = TimeCurrent();
      if(m_lastFridayTry != 0 && (now - m_lastFridayTry) < 60)
         return 0;
      m_lastFridayTry = now;

      int closed = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         if(!IsMine(PositionGetInteger(POSITION_MAGIC), includeManual))
            continue;

         if(m_trade.PositionClose(ticket))
            closed++;
         else
            LogError("bastan-e jom'e", ticket);
        }

      if(closed > 0)
         Print("PositionExtras: jom'e - ", closed, " position baste shod (", InpFridayCloseTime, ").");

      return closed;
     }
  };

#endif // __MAGICKEYS_POSITIONEXTRAS_MQH__
//+------------------------------------------------------------------+
