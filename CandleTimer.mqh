//+------------------------------------------------------------------+
//|                                                CandleTimer.mqh  |
//|  [v1.18] Tayemar-e candle (mesl-e TradingView): zaman-e baghi-    |
//|  mande ta baste shodan-e candle baraye hame-ye timeframe-ha.      |
//|                                                                  |
//|  1) Jadval-e timeframe-ha (InpTimerFrames) dar yek goosheh-ye     |
//|     chart; satr-e timeframe-e chart ba rang-e digeh neshoon dade  |
//|     mishe.                                                        |
//|  2) Tag-e kochik kenar-e gheimat-e jari (InpTimerPriceTag) ke      |
//|     tayemar-e timeframe-e chart ro neshoon mide (mesl-e            |
//|     TradingView).                                                 |
//|                                                                  |
//|  Faghat object-haye chart (OBJ_LABEL / OBJ_RECTANGLE_LABEL) mikeshe|
//|  va be moamele-ha, zone-ha va baghie-ye EA kari nadare.            |
//+------------------------------------------------------------------+
#ifndef __MAGICKEYS_CANDLETIMER_MQH__
#define __MAGICKEYS_CANDLETIMER_MQH__

#include "Settings.mqh"

#define MKCT_PREFIX    "MKCT_"
#define MKCT_MAX_ROWS  24

class CCandleTimer
  {
private:
   long            m_chartId;
   bool            m_active;
   ENUM_TIMEFRAMES m_frames[MKCT_MAX_ROWS];   // timeframe-haye jadval
   int             m_count;                   // tedad-e satr-ha
   double          m_dpiScale;                // 1.0 = 96 DPI
   int             m_timeWidth;               // tedad-e character-haye sotoon-e zaman
   int             m_tagW;                    // arz-e feli-ye tag (pixel)
   bool            m_tagShown;                // aya tag alan namayesh dade mishe?

public:
                     CCandleTimer()
     {
      m_chartId   = 0;
      m_active    = false;
      m_count     = 0;
      m_dpiScale  = 1.0;
      m_timeWidth = 8;
      m_tagW      = 0;
      m_tagShown  = true;
     }

   //+------------------------------------------------------------------+
   //| Sakhtan-e object-ha va namayesh-e avalie. false = ghair-faal      |
   //| (InpTimerEnable = false, Strategy Tester, ya hich timeframe-e     |
   //| motabari dar InpTimerFrames nabood)                               |
   //+------------------------------------------------------------------+
   bool Init(const long chartId)
     {
      m_chartId = chartId;
      Destroy();   // object-haye ba'ghi-mande az ejra-ye ghabli (age bashe) pak mishan

      if(!InpTimerEnable)
         return false;

      //--- dar Strategy Tester timer/object-ha lazem nistan
      if(MQLInfoInteger(MQL_TESTER) != 0)
         return false;

      m_count = ParseFrames(InpTimerFrames);
      if(m_count <= 0 && !InpTimerPriceTag)
        {
         Print("CandleTimer: hich timeframe-e motabari dar InpTimerFrames nist - tayemar kar nemikone.");
         return false;
        }

      int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
      if(dpi <= 0)
         dpi = 96;
      m_dpiScale = MathMax(0.75, MathMin(dpi / 96.0, 3.0));

      //--- arz-e sotoon-e zaman: hafte ta "6d 23:59:59" va mah ta "30d 23:59:59" mitoone beshe
      m_timeWidth = 8;
      for(int i = 0; i < m_count; i++)
        {
         if(m_frames[i] == PERIOD_MN1)
            m_timeWidth = MathMax(m_timeWidth, 12);
         else if(m_frames[i] == PERIOD_W1)
            m_timeWidth = MathMax(m_timeWidth, 11);
        }

      CreateObjects();
      m_active = true;

      Layout();
      Update();
      return true;
     }

   void Destroy()
     {
      ObjectsDeleteAll(m_chartId, MKCT_PREFIX);
      m_active   = false;
      m_count    = 0;
      m_tagShown = true;
     }

   //+------------------------------------------------------------------+
   //| Har 1 sanie (OnTimer): matn va rang-e hame-ye satr-ha va tag      |
   //+------------------------------------------------------------------+
   void Update()
     {
      if(!m_active)
         return;

      datetime        now     = TimeTradeServer() + InpTimerOffsetSec;
      color           fg      = (color)ChartGetInteger(m_chartId, CHART_COLOR_FOREGROUND);
      ENUM_TIMEFRAMES chartTf = (ENUM_TIMEFRAMES)_Period;

      for(int i = 0; i < m_count; i++)
        {
         ENUM_TIMEFRAMES tf        = m_frames[i];
         long            remaining = Remaining(tf, now);
         bool            isCurrent = (tf == chartTf);

         //--- satr-e timeframe-e chart ba "<" moshakhas mishe (rang tanha kafi nist)
         string text = PadRight(FrameName(tf), 4) + PadLeft(FormatRemaining(remaining), m_timeWidth);
         if(isCurrent)
            text += " <";

         color clr = fg;
         if(IsWarn(tf, remaining))
            clr = InpTimerWarnColor;
         else if(isCurrent)
            clr = InpTimerCurrentColor;

         string name = RowName(i);
         ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
         ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clr);
        }

      if(InpTimerPriceTag)
        {
         long   remaining = Remaining(chartTf, now);
         string text      = FormatRemaining(remaining);

         color bg = clrSeaGreen;   // candle-e jari sa'ody
         if(iClose(_Symbol, chartTf, 0) < iOpen(_Symbol, chartTf, 0))
            bg = clrFireBrick;     // candle-e jari nozooli
         if(IsWarn(chartTf, remaining))
            bg = InpTimerWarnColor;

         m_tagW = StringLen(text) * CharWidth() + 2 * Pad();

         string rect = MKCT_PREFIX + "TagBG";
         string lbl  = MKCT_PREFIX + "TagText";

         ObjectSetString(m_chartId, lbl, OBJPROP_TEXT, text);
         ObjectSetInteger(m_chartId, rect, OBJPROP_BGCOLOR, bg);
         ObjectSetInteger(m_chartId, rect, OBJPROP_COLOR, bg);
         ObjectSetInteger(m_chartId, rect, OBJPROP_XSIZE, m_tagW);
         ObjectSetInteger(m_chartId, rect, OBJPROP_YSIZE, RowHeight());
        }

      UpdateTag();
      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Jaye tag-e kenar-e gheimat (har tick va ba har taghir-e chart).   |
   //| Gheimat-e jari ro ba ChartTimePriceToXY be pixel tabdil mikone;   |
   //| age gheimat biroon az mahdoode-ye did-e chart bood tag makhfi mishe|
   //+------------------------------------------------------------------+
   void UpdateTag()
     {
      if(!m_active || !InpTimerPriceTag)
         return;

      long cw = ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
      long ch = ChartGetInteger(m_chartId, CHART_HEIGHT_IN_PIXELS);
      if(cw <= 0 || ch <= 0 || m_tagW <= 0)
         return;

      double   price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      datetime t0    = iTime(_Symbol, (ENUM_TIMEFRAMES)_Period, 0);

      int x = 0;
      int y = 0;
      bool ok = (price > 0.0 && t0 > 0 && ChartTimePriceToXY(m_chartId, 0, t0, price, x, y));

      int tagH = RowHeight();
      int tx   = (int)cw - m_tagW - 1;
      int ty   = y + 2;   // ye kam paeen-tar az khat-e gheimat

      if(!ok || tx < 0 || ty < 0 || ty > (int)ch - tagH)
        {
         SetTagShown(false);
         return;
        }

      SetTagShown(true);

      string rect = MKCT_PREFIX + "TagBG";
      string lbl  = MKCT_PREFIX + "TagText";

      ObjectSetInteger(m_chartId, rect, OBJPROP_XDISTANCE, tx);
      ObjectSetInteger(m_chartId, rect, OBJPROP_YDISTANCE, ty);
      ObjectSetInteger(m_chartId, lbl, OBJPROP_XDISTANCE, tx + Pad());
      ObjectSetInteger(m_chartId, lbl, OBJPROP_YDISTANCE, ty + TextDy());
     }

   //+------------------------------------------------------------------+
   //| Jaye jadval (ba taghir-e andaze-ye chart): goosheh va fasele-ha ro |
   //| az InpTimerCorner / InpTimerX / InpTimerY mikhoone                 |
   //+------------------------------------------------------------------+
   void Layout()
     {
      if(!m_active)
         return;

      long cw = ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
      long ch = ChartGetInteger(m_chartId, CHART_HEIGHT_IN_PIXELS);
      if(cw <= 0 || ch <= 0)
         return;

      if(m_count > 0)
        {
         int pad   = Pad();
         int rowH  = RowHeight();
         int chars = 4 + m_timeWidth + 2;   // esm + zaman + " <"
         int boxW  = chars * CharWidth() + 2 * pad;
         int boxH  = m_count * rowH + 2 * pad;

         bool left  = (InpTimerCorner == CORNER_LEFT_UPPER || InpTimerCorner == CORNER_LEFT_LOWER);
         bool upper = (InpTimerCorner == CORNER_LEFT_UPPER || InpTimerCorner == CORNER_RIGHT_UPPER);

         int x = left  ? InpTimerX : (int)cw - boxW - InpTimerX;
         int y = upper ? InpTimerY : (int)ch - boxH - InpTimerY;

         if(x < 0)
            x = 0;
         if(y < 0)
            y = 0;

         if(InpTimerShowBackground)
           {
            string bg = MKCT_PREFIX + "BG";
            ObjectSetInteger(m_chartId, bg, OBJPROP_XDISTANCE, x);
            ObjectSetInteger(m_chartId, bg, OBJPROP_YDISTANCE, y);
            ObjectSetInteger(m_chartId, bg, OBJPROP_XSIZE, boxW);
            ObjectSetInteger(m_chartId, bg, OBJPROP_YSIZE, boxH);
           }

         for(int i = 0; i < m_count; i++)
           {
            string name = RowName(i);
            ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x + pad);
            ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y + pad + i * rowH);
           }
        }

      UpdateTag();
      ChartRedraw(m_chartId);
     }

private:
   //--- ---------------------------------------------------------------
   //--- andaze-ha (pixel). Font-haye object ba DPI khodesh scale mishan,
   //--- vali XDISTANCE/XSIZE pixel-e vaghei-and, pas ba m_dpiScale zarb mishan
   //--- ---------------------------------------------------------------
   int FontSize()
     {
      return (int)MathMax(6, MathMin(InpTimerFontSize, 24));
     }

   int RowHeight()
     {
      return (int)MathRound(FontSize() * 1.8 * m_dpiScale);
     }

   int CharWidth()
     {
      return (int)MathRound(FontSize() * 0.76 * m_dpiScale);
     }

   int Pad()
     {
      return (int)MathRound(5.0 * m_dpiScale);
     }

   int TextDy()
     {
      return (int)MathRound(FontSize() * 0.2 * m_dpiScale);
     }

   string RowName(const int i)
     {
      return MKCT_PREFIX + "Row" + IntegerToString(i);
     }

   void CreateObjects()
     {
      if(m_count > 0)
        {
         if(InpTimerShowBackground)
           {
            color bgClr = (color)ChartGetInteger(m_chartId, CHART_COLOR_BACKGROUND);
            MakeRect(MKCT_PREFIX + "BG", bgClr, clrDimGray);
           }

         for(int i = 0; i < m_count; i++)
            MakeLabel(RowName(i), clrWhite);
        }

      if(InpTimerPriceTag)
        {
         MakeRect(MKCT_PREFIX + "TagBG", clrSeaGreen, clrSeaGreen);
         MakeLabel(MKCT_PREFIX + "TagText", clrWhite);
        }
     }

   //--- hamoon property-haye CreateRectLabel/CreateLabel-e Panel (CORNER_LEFT_UPPER, ghair-e entekhabi, makhfi)
   void MakeRect(const string name, const color bg, const color border)
     {
      ObjectCreate(m_chartId, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, bg);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, border);
      ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
     }

   void MakeLabel(const string name, const color clr)
     {
      ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetString(m_chartId, name, OBJPROP_TEXT, "");
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, FontSize());
      ObjectSetString(m_chartId, name, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
     }

   void SetTagShown(const bool shown)
     {
      if(shown == m_tagShown)
         return;

      m_tagShown = shown;

      long periods = shown ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
      ObjectSetInteger(m_chartId, MKCT_PREFIX + "TagBG", OBJPROP_TIMEFRAMES, periods);
      ObjectSetInteger(m_chartId, MKCT_PREFIX + "TagText", OBJPROP_TIMEFRAMES, periods);
     }

   //--- ---------------------------------------------------------------
   //--- matn
   //--- ---------------------------------------------------------------
   string PadRight(string s, const int width)
     {
      while(StringLen(s) < width)
         s += " ";
      return s;
     }

   string PadLeft(string s, const int width)
     {
      while(StringLen(s) < width)
         s = " " + s;
      return s;
     }

   //--- "M5", "H1", "MN1", ...
   string FrameName(const ENUM_TIMEFRAMES tf)
     {
      string s = EnumToString(tf);   // "PERIOD_M5"
      if(StringFind(s, "PERIOD_") == 0)
         s = StringSubstr(s, 7);
      return s;
     }

   //--- 04:23  |  1:05:09 -> 01:05:09  |  2d 05:12:33
   string FormatRemaining(long seconds)
     {
      if(seconds < 0)
         seconds = 0;

      long d = seconds / 86400;
      long h = (seconds % 86400) / 3600;
      long m = (seconds % 3600) / 60;
      long s = seconds % 60;

      string hms = IntegerToString(m, 2, '0') + ":" + IntegerToString(s, 2, '0');

      if(d > 0)
         return IntegerToString(d) + "d " + IntegerToString(h, 2, '0') + ":" + hms;
      if(h > 0)
         return IntegerToString(h, 2, '0') + ":" + hms;
      return hms;
     }

   //--- hoshdar: dar sanie-haye akhar-e candle (faghat timeframe-haye bozorg-tar az M1 ta M1 hamishe hoshdar nade)
   bool IsWarn(const ENUM_TIMEFRAMES tf, const long remaining)
     {
      return (InpTimerWarnSeconds > 0 && PeriodSeconds(tf) > 60 && remaining <= InpTimerWarnSeconds);
     }

   //--- ---------------------------------------------------------------
   //--- zaman-e baghi-mande ta baste shodan-e candle-e jari
   //--- ---------------------------------------------------------------
   long Remaining(const ENUM_TIMEFRAMES tf, const datetime now)
     {
      //--- mah: ta avval-e mah-e ba'd (00:00 zaman-e server)
      if(tf == PERIOD_MN1)
        {
         MqlDateTime dt;
         TimeToStruct(now, dt);

         dt.mon++;
         if(dt.mon > 12)
           {
            dt.mon = 1;
            dt.year++;
           }
         dt.day  = 1;
         dt.hour = 0;
         dt.min  = 0;
         dt.sec  = 0;

         return (long)(StructToTime(dt) - now);
        }

      //--- hafte: dar MT5 hafte az yekshanbe 00:00 (zaman-e server) shoroe mishe
      if(tf == PERIOD_W1)
        {
         MqlDateTime dt;
         TimeToStruct(now, dt);

         long dayStart  = (long)now - ((long)now % 86400);
         long weekStart = dayStart - (long)dt.day_of_week * 86400;
         return (weekStart + 7 * 86400) - (long)now;
        }

      //--- baghie (M1 ta D1): candle-ha ru-ye shabake-ye zamani-e sabet hastan. Fase-ye shabake ro az candle-e
      //--- jari-ye khod-e broker migirim ta age broker faseleh-ye ajib dasht ham dorost bashe
      int sec = PeriodSeconds(tf);
      if(sec <= 0)
         return 0;

      long     phase = 0;
      datetime t0    = iTime(_Symbol, tf, 0);
      if(t0 > 0)
         phase = (long)t0 % sec;

      long since = (((long)now - phase) % sec + sec) % sec;   // chand sanie az shoroe-e candle-e jari gozashte
      return sec - since;
     }

   //--- ---------------------------------------------------------------
   //--- "M1,M5,H1,..." -> m_frames. Tedad-e timeframe-haye motabar ro bar migardoone
   //--- ---------------------------------------------------------------
   int ParseFrames(const string list)
     {
      string parts[];
      int    n     = StringSplit(list, ',', parts);
      int    count = 0;

      for(int i = 0; i < n && count < MKCT_MAX_ROWS; i++)
        {
         ENUM_TIMEFRAMES tf = ParseFrame(parts[i]);

         if(tf == PERIOD_CURRENT)
           {
            string bad = parts[i];
            StringTrimLeft(bad);
            StringTrimRight(bad);
            if(StringLen(bad) > 0)
               Print("CandleTimer: timeframe-e na-shenakhte dar InpTimerFrames: [", bad, "]");
            continue;
           }

         bool duplicate = false;
         for(int k = 0; k < count; k++)
           {
            if(m_frames[k] == tf)
              {
               duplicate = true;
               break;
              }
           }
         if(duplicate)
            continue;

         m_frames[count] = tf;
         count++;
        }

      return count;
     }

   //--- PERIOD_CURRENT = na-shenakhte
   ENUM_TIMEFRAMES ParseFrame(string t)
     {
      StringTrimLeft(t);
      StringTrimRight(t);
      StringToUpper(t);

      if(t == "M1")
         return PERIOD_M1;
      if(t == "M2")
         return PERIOD_M2;
      if(t == "M3")
         return PERIOD_M3;
      if(t == "M4")
         return PERIOD_M4;
      if(t == "M5")
         return PERIOD_M5;
      if(t == "M6")
         return PERIOD_M6;
      if(t == "M10")
         return PERIOD_M10;
      if(t == "M12")
         return PERIOD_M12;
      if(t == "M15")
         return PERIOD_M15;
      if(t == "M20")
         return PERIOD_M20;
      if(t == "M30")
         return PERIOD_M30;
      if(t == "H1")
         return PERIOD_H1;
      if(t == "H2")
         return PERIOD_H2;
      if(t == "H3")
         return PERIOD_H3;
      if(t == "H4")
         return PERIOD_H4;
      if(t == "H6")
         return PERIOD_H6;
      if(t == "H8")
         return PERIOD_H8;
      if(t == "H12")
         return PERIOD_H12;
      if(t == "D1" || t == "D")
         return PERIOD_D1;
      if(t == "W1" || t == "W")
         return PERIOD_W1;
      if(t == "MN1" || t == "MN")
         return PERIOD_MN1;

      return PERIOD_CURRENT;
     }
  };

#endif
//+------------------------------------------------------------------+
