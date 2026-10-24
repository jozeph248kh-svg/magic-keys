//+------------------------------------------------------------------+
//|                                                    Dynamic.mqh   |
//|  Dynamic.mqh - ATR va andaze-haye pooya (SL / candle-e bozorg)     |
//|  [v1.20] SL va hadd-e candle-e bozorg ra mishe ba ATR (motenaseb   |
//|  ba nosan) tanzim kard, ya hamoon adad-e sabet-e ghabli            |
//+------------------------------------------------------------------+
#property strict

#ifndef __MAGICKEYS_DYNAMIC_MQH__
#define __MAGICKEYS_DYNAMIC_MQH__

#include "Settings.mqh"

string          g_mkSymbol      = "";
ENUM_TIMEFRAMES g_mkAnalysisTf  = PERIOD_CURRENT;   // timeframe-e tahlil-e EA (InpTimeframe) - ba OnInit set mishe
int             g_mkAtrHandle   = INVALID_HANDLE;
bool            g_mkAtrWarned   = false;

//--- timeframe-e vaghei-e tahlil-e EA
ENUM_TIMEFRAMES MKAnalysisTf()
  {
   return (g_mkAnalysisTf == PERIOD_CURRENT) ? (ENUM_TIMEFRAMES)_Period : g_mkAnalysisTf;
  }

//--- timeframe-e vaghei-e ATR (PERIOD_CURRENT = hamoon timeframe-e tahlil-e EA)
ENUM_TIMEFRAMES MKAtrTimeframe()
  {
   if(InpAtrTimeframe != PERIOD_CURRENT)
      return InpAtrTimeframe;

   return MKAnalysisTf();
  }

//--- sakht-e handle-e ATR
void MKDynamicInit(const string symbol, const ENUM_TIMEFRAMES analysisTf)
  {
   g_mkSymbol     = symbol;
   g_mkAnalysisTf = analysisTf;
   g_mkAtrWarned  = false;

   if(g_mkAtrHandle != INVALID_HANDLE)
     {
      IndicatorRelease(g_mkAtrHandle);
      g_mkAtrHandle = INVALID_HANDLE;
     }

   g_mkAtrHandle = iATR(symbol, MKAtrTimeframe(), MathMax(1, InpAtrPeriod));

   if(g_mkAtrHandle == INVALID_HANDLE)
      Print("Dynamic: sakht-e ATR ba khata mowajeh shod (", GetLastError(), ") - az adad-haye sabet estefade mishe.");
  }

void MKDynamicDeinit()
  {
   if(g_mkAtrHandle != INVALID_HANDLE)
     {
      IndicatorRelease(g_mkAtrHandle);
      g_mkAtrHandle = INVALID_HANDLE;
     }
  }

//--- ATR-e akharin candle-e baste-shode be pip (ok = false: dade amade nist)
double MKAtrPips(bool &ok)
  {
   ok = false;

   if(g_mkAtrHandle == INVALID_HANDLE || g_mkSymbol == "")
      return 0.0;

   double buf[];
   ArraySetAsSeries(buf, true);

   if(CopyBuffer(g_mkAtrHandle, 0, 1, 1, buf) < 1 || buf[0] <= 0.0)
      return 0.0;

   double pip = MKPipSize(g_mkSymbol);
   if(pip <= 0.0)
      return 0.0;

   ok = true;
   return buf[0] / pip;
  }

//--- fasele-ye SL az sayeh-ye candle (pip): sabet ya ATR
double MKSlBufferPips()
  {
   if(InpSlMode != SIZEMODE_ATR)
      return (double)InpSplitStopLossPips;

   bool   ok;
   double atr = MKAtrPips(ok);

   if(!ok)
     {
      if(!g_mkAtrWarned)
        {
         g_mkAtrWarned = true;
         Print("Dynamic: ATR dar dastres nist - mowaghatan SL-e sabet (", InpSplitStopLossPips, " pip) estefade mishe.");
        }
      return (double)InpSplitStopLossPips;
     }

   double value = atr * InpSlAtrMultiplier;

   if(InpSlMinPips > 0.0)
      value = MathMax(value, InpSlMinPips);
   if(InpSlMaxPips > 0.0)
      value = MathMin(value, InpSlMaxPips);

   return MathMax(value, 1.0);
  }

//--- hadd-e candle-e bozorg (pip): sabet ya ATR (0 = ghair-faal)
double MKBigCandlePips()
  {
   if(InpBigCandleMode != SIZEMODE_ATR)
      return (double)InpBigCandlePips;

   if(InpBigCandleAtrMult <= 0.0)
      return 0.0;

   bool   ok;
   double atr = MKAtrPips(ok);

   if(!ok)
      return (double)InpBigCandlePips;

   return atr * InpBigCandleAtrMult;
  }

//--- [v1.20] SL-e "candle-e vorud" (halat-e nim-automatic / dasti):
//--- Kharid: age Low-e candle-e ghabli bala-tar az gheimat-e vorud bood -> SL = Low-e candle-e vorud - InpEntryCandleStopPips
//--- Forush: age High-e candle-e ghabli paiin-tar az gheimat-e vorud bood -> SL = High-e candle-e vorud + InpEntryCandleStopPips
//--- "candle-e vorud" = candle-i ke zaman-e when (zaman-e vorud) dar oon bood. 0 = shart bargharar nist ya dade nist
double MKEntryCandleStop(const string symbol, const ENUM_POSITION_TYPE direction, const double entry, const datetime when)
  {
   if(!InpUseEntryCandleStop || entry <= 0.0)
      return 0.0;

   ENUM_TIMEFRAMES tf    = MKAnalysisTf();
   int             shift = iBarShift(symbol, tf, when, false);
   if(shift < 0)
      return 0.0;

   double prevLow  = iLow(symbol, tf, shift + 1);
   double prevHigh = iHigh(symbol, tf, shift + 1);
   double curLow   = iLow(symbol, tf, shift);
   double curHigh  = iHigh(symbol, tf, shift);

   if(prevLow <= 0.0 || prevHigh <= 0.0 || curLow <= 0.0 || curHigh <= 0.0)
      return 0.0;

   double pip    = MKPipSize(symbol);
   int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double dist   = (double)MathMax(0, InpEntryCandleStopPips) * pip;

   if(direction == POSITION_TYPE_BUY)
     {
      if(prevLow > entry)
         return NormalizeDouble(curLow - dist, digits);
     }
   else
     {
      if(prevHigh < entry)
         return NormalizeDouble(curHigh + dist, digits);
     }

   return 0.0;
  }

//--- ghimat-e Risk-Free: vorud + offset (Buy: bala-tar, Sell: paiin-tar)
double MKBreakEvenPrice(const ENUM_POSITION_TYPE direction, const double entry, const double pipSize, const int digits)
  {
   double offset = MathMax(0.0, InpBreakEvenOffsetPips) * pipSize;
   double price  = (direction == POSITION_TYPE_BUY) ? (entry + offset) : (entry - offset);

   return NormalizeDouble(price, digits);
  }

#endif // __MAGICKEYS_DYNAMIC_MQH__
//+------------------------------------------------------------------+
