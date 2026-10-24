//+------------------------------------------------------------------+
//|                                                       Panel.mqh  |
//|  Panel.mqh - Rabet-e Karbari-e Rooye Chart baraye Zone-ha         |
//|                                                                    |
//|  Vazife:                                                          |
//|  1) Do bakhsh-e joda: ZONE-E KHARID (Buy) va ZONE-E FOROUSH        |
//|     (Sell). Har bakhsh edit box + dokme-ye Ezafe + list-e zone-    |
//|     haye khodesh ro dare. Zone-e Kharid faghat signal-e Buy va     |
//|     zone-e Forush faghat signal-e Sell mide                        |
//|  2) Baraye har zone do dokme: "Vir" (virayesh - meghdar-e zone    |
//|     toye edit box miad, ba dokme-ye Zakhire jaygozin mishe;        |
//|     click-e dobare-ye Vir = laghv) va "X" (pak kardan)             |
//|  3) Dokme-ye Pak Kon Hame baraye khali kardan-e hameye zone-ha     |
//|  4) Dokme-ye CLOSE ALL baraye mavaghe-e ezterari: hame-ye          |
//|     position-haye baz-e in symbol ro mibande. Baraye jelogiri az   |
//|     click-e eshtebahi, click-e aval faghat "aslih" mikone va       |
//|     click-e dovom (dar 3 sanie) ejra mikone                         |
//|  4b) Se halat-e kar (se dokme-ye bala-ye panel):                   |
//|      AUTO     : EA ba tayidiye-ye zone khodash vared mishe         |
//|      NIM-AUTO : EA vared nemishe (faghat Alert); ba dokme-haye     |
//|                 BUY/SELL-e panel vared mishi va EA hajm, SL va     |
//|                 TP-ha ro mizare                                     |
//|      DASTI    : ba dokme-haye khod-e MetaTrader (hajm-e khodet)    |
//|                 vared mishi; EA position-e jadid ro jazb mikone,   |
//|                 SL/TP mizare va modiriat mikone                     |
//|      Halat dar GlobalVariable zakhire mishe (ba avaz-e timeframe/ |
//|      restart-e EA khodesh be AUTO bar nemigarde). Dokme-haye       |
//|      BUY/SELL faghat dar NIM-AUTO faal-and. Vorud-e dasti ro Panel |
//|      khodesh anjam nemide: darkhast ro sabt mikone va EA-ye asli   |
//|      (PopManualRequest) anjamesh mide                               |
//|  5) Har zone ro be soorat-e ye mostatil-e por-rang (OBJ_RECTANGLE) |
//|     posht-e candle-ha mikeshe: zone-e Kharid sabz, zone-e Forush   |
//|     ghermez; rang-e roshan-tar = gheimat vared shode, kam-rang =   |
//|     tayid shod, khakestari = namotabar                              |
//|  6) Panel shenavar-e (draggable) - az navar-e onvan (title bar)   |
//|     mishe gerefti va jash roo chart avaz kard                      |
//|  6b) Andaze-ye panel ba DPI/rezolution-e safhe hamahang mishe     |
//|     (TERMINAL_SCREEN_DPI): hame-ye andaze-ha dar "pixel-e tarrahi"|
//|     (96 DPI = 100%) neveshte shodan va ba zarib be pixel-e vaghei  |
//|     tabdil mishan. Ba grip-e goosheh-ye payin-rast ba mouse        |
//|     bozorg/kochik mishe; khodkar kamel too-ye chart mimoone (age   |
//|     chart kochik bashe panel kam mishe); andaze va jash hafeze    |
//|     mishe. Vaghti mouse rooye panele, scroll-e chart ghofl mishe.  |
//|     Dokme-ye R = bazgasht be andaze/jaye avalie                    |
//|  7) Dokme-ye Minimize - panel ro jam mikone be ye navar-e koochik  |
//|  8) Dokme-ye Close (X) - panel ro kamelan az chart pak mikone;     |
//|     baraye bargashtan, kafie EA Properties ro doobare baz/OK koni  |
//|                                                                    |
//|  Zone-ha faghat az tarigh-e ZoneManager (AddZone/AddZoneRange/     |
//|  UpdateZone/UpdateZoneRange/RemoveZone/ClearZones) taghir mikonan; |
//|  Close All faghat az tarigh-e TradeManager.CloseAllPositions()     |
//+------------------------------------------------------------------+
#property strict

#include "ZoneManager.mqh"
#include "TradeManager.mqh"

//--- halat-e kar-e EA (ba 3 dokme-ye bala-ye panel entekhab mishe)
enum ENUM_EA_MODE
  {
   EAMODE_AUTO,     // automatic: EA ba tayidiye-ye zone khodash vared mishe
   EAMODE_SEMI,     // nim-automatic: EA vared nemishe; ba dokme-haye BUY/SELL-e panel vared mishi (hajm/SL/TP ba EA)
   EAMODE_MANUAL    // dasti: ba dokme-haye khod-e MetaTrader vared mishi (hajm ba to); EA SL/TP mizare va modiriat mikone
  };

#define MKP_PREFIX     "MKP_"
#define MKP_TITLEBAR_H 20
#define MKP_ROW_H      17
#define MKP_BASE_W     290   // arz-e panel dar pixel-e tarrahi (96 DPI)

//--- rang-e mostatil-e zone bar asas-e jahat va vaziat (har kodoom ro dooset dari avaz kon)
#define MKP_BUY_WAITING   InpColBuyWaiting    // zone-e Kharid - montazer-e gheimat
#define MKP_BUY_ARMED     InpColBuyArmed    // zone-e Kharid - gheimat vared shode
#define MKP_BUY_DONE      InpColBuyDone     // zone-e Kharid - tayid shod (signal sader shode)
#define MKP_SELL_WAITING  InpColSellWaiting    // zone-e Forush - montazer-e gheimat
#define MKP_SELL_ARMED    InpColSellArmed   // zone-e Forush - gheimat vared shode
#define MKP_SELL_DONE     InpColSellDone    // zone-e Forush - tayid shod (signal sader shode)
#define MKP_ZONE_INVALID  InpColZoneInvalid     // zone-e namotabar (har do jahat)

//+------------------------------------------------------------------+
//| Class Panel-e Rooye Chart                                        |
//+------------------------------------------------------------------+
class CPanel
  {
private:
   CZoneManager  *m_zoneManager;
   CTradeManager *m_tradeManager;
   long          m_chartId;
   string        m_symbol;
   int           m_digits;
   double        m_point;
   datetime      m_lastRefresh;
   int           m_maxRows;             // tedad-e radif-haye har bakhsh (Kharid / Forush)
   int           m_x;
   int           m_yStart;
   bool          m_minimized;
   bool          m_closed;
   bool          m_dragging;
   int           m_dragOffsetX;
   int           m_dragOffsetY;
   int           m_bandsDrawn;          // tedad-e mostatil-haye zone ke ta hala rooye chart keshide shodan
   datetime      m_bandTimeLeft;        // akharin baze-ye zamani-e chap-e estefade-shode baraye mostatil-ha
   datetime      m_bandTimeRight;       // akharin baze-ye zamani-e rast-e estefade-shode baraye mostatil-ha
   bool          m_bandErrorLogged;     // ta khata-ye sakht-e mostatil har sanie log nashe
   int           m_rowMap[];            // radif -> index-e zone dar ZoneManager (-1 = radif-e khali)
   int           m_editIndex;           // index-e zone-i ke dar hale virayesh-e (-1 = hich)
   int           m_editSide;            // bakhsh-e zone-i ke dar hale virayesh-e (0 = Kharid, 1 = Forush)
   uint          m_closeAllArmedUntil;  // zaman-e payan-e "aslih" boodan-e dokme-ye Close All (GetTickCount)
   ENUM_EA_MODE  m_mode;                // halat-e fe'li: AUTO / NIM-AUTO / DASTI
   bool          m_modeRestored;        // [v1.19] aya halat az zakhire (GlobalVariable) bargozari shod (na pishfarz)?
   int           m_manualRequest;       // darkhast-e vorud-e dasti: 0 = hich, 1 = BUY, -1 = SELL
   string        m_info1;               // khat-e aval-e etela'at (hajm/SL/TP) - az EA-ye asli set mishe
   string        m_info2;               // khat-e dovom-e etela'at (signal) - az EA-ye asli set mishe
   double        m_dpiScale;            // DPI-ye safhe / 96 (1.0 = 100%)
   double        m_userScale;           // andaze-ye entekhabi-ye karbar (ba grip-e payin-rast)
   double        m_scale;               // zarib-e hendese-ye mo'asser (DPI x karbar, ba hadd-e chart)
   double        m_fontScale;           // zarib-e font (= m_scale / m_dpiScale: MetaTrader font ro khodesh ba DPI bozorg mikone)
   bool          m_resizing;            // dar hale taghir-e andaze ba grip?
   int           m_resizeOffX;
   int           m_resizeOffY;
   bool          m_prevLeftDown;        // vaziat-e ghabli-e dokme-ye chap-e mouse (baraye tashkhis-e "feshar")
   bool          m_scrollLocked;        // scroll-e chart ghofl shode?
   bool          m_origMouseScroll;     // vaziat-e avalie-ye CHART_MOUSE_SCROLL
   uint          m_lastLayoutTick;      // throttle-e relayout dar hin-e taghir-e andaze
   bool          m_positionsOnly;       // faghat mokhtasat set beshe (baraye drag)

public:
   CPanel()
     {
      m_zoneManager   = NULL;
      m_tradeManager  = NULL;
      m_mode          = EAMODE_AUTO;
      m_modeRestored  = false;
      m_manualRequest = 0;
      m_info1         = "";
      m_info2         = "";
      m_dpiScale      = 1.0;
      m_userScale     = 1.0;
      m_scale         = 1.0;
      m_fontScale     = 1.0;
      m_resizing      = false;
      m_prevLeftDown  = false;
      m_scrollLocked  = false;
      m_origMouseScroll = true;
      m_lastLayoutTick  = 0;
      m_positionsOnly   = false;
      m_x             = 10;
      m_yStart        = 20;
     }

   //+------------------------------------------------------------------+
   //| Halat-e fe'li (EA-ye asli har tick mikhoone)                      |
   //+------------------------------------------------------------------+
   ENUM_EA_MODE GetMode()
     {
      return m_mode;
     }

   //--- [v1.19] aya halat az zakhire bargozari shod? (false = zakhire peida nashod va halat pishfarz-e NIM-AUTOMATIC shod)
   bool ModeWasRestored()
     {
      return m_modeRestored;
     }

   //+------------------------------------------------------------------+
   //| [v1.19] GlobalVariable-haye terminal bad az 4 hafte bedoone       |
   //| dastresi pak mishan. Halat va jaye panel ro dobare minevisim ta    |
   //| (hata ba EA-ye khodkar-e tolani) zakhire-ye halat az bein nare va  |
   //| ba restart-e ba'di bedoone khabar be NIM-AUTOMATIC bar nagarde     |
   //+------------------------------------------------------------------+
   void TouchStorage()
     {
      SaveMode();
      SaveLayout();
     }

   bool IsSemiAuto()
     {
      return (m_mode == EAMODE_SEMI);
     }

   //+------------------------------------------------------------------+
   //| Darkhast-e vorud-e dasti ro bar migardoone va sefr mikone:        |
   //| 0 = hich, 1 = BUY, -1 = SELL (EA-ye asli ba'd az har chart event  |
   //| seda mizane va vorud ro anjam mide)                                |
   //+------------------------------------------------------------------+
   int PopManualRequest()
     {
      int request = m_manualRequest;
      m_manualRequest = 0;
      return request;
     }

   //+------------------------------------------------------------------+
   //| Do khat-e etela'at (hajm/SL/TP va vaziat-e signal) ke EA-ye asli |
   //| set mikone; ba avalin Refresh rooye panel miad                     |
   //+------------------------------------------------------------------+
   void SetInfo(string line1, string line2)
     {
      m_info1 = line1;
      m_info2 = line2;
     }

   //+------------------------------------------------------------------+
   //| Vasl kardan-e panel be ZoneManager va TradeManager-e mojood       |
   //| (bayad ghabl az Create() seda zade beshan)                        |
   //+------------------------------------------------------------------+
   void SetZoneManager(CZoneManager *zm)
     {
      m_zoneManager = zm;
     }

   void SetTradeManager(CTradeManager *tm)
     {
      m_tradeManager = tm;
     }

   //+------------------------------------------------------------------+
   //| Sakhtan-e hameye object-haye panel. Bayad dar OnInit-e asli-e EA |
   //| seda zade beshe (ba'd az SetZoneManager)                         |
   //+------------------------------------------------------------------+
   void Create(string symbol)
     {
      m_chartId      = 0;
      m_symbol       = symbol;
      m_digits       = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      m_point        = SymbolInfoDouble(symbol, SYMBOL_POINT);
      m_lastRefresh  = 0;
      m_maxRows      = MathMax(3, MathMin(12, InpPanelMaxRows));   // [v1.12] ghablan sabet 5 bood
      m_minimized    = false;
      m_closed       = false;
      m_dragging     = false;
      m_resizing     = false;
      m_prevLeftDown = false;
      m_scrollLocked = false;
      m_lastLayoutTick = 0;
      m_positionsOnly  = false;

      DetectDpi();
      LoadLayout();

      m_bandsDrawn      = 0;
      m_bandTimeLeft    = 0;
      m_bandTimeRight   = 0;
      m_bandErrorLogged = false;

      m_editIndex          = -1;
      m_editSide           = 0;
      m_closeAllArmedUntil = 0;
      m_manualRequest      = 0;
      m_mode               = LoadMode();
      ArrayResize(m_rowMap, 2 * m_maxRows);

      //--- khat-haye ghadimi-e zone (nosakhe-haye ghabli) age mande bashan pak mishan
      ObjectsDeleteAll(m_chartId, MKP_PREFIX + "ZoneRect_");

      //--- MOUSE_MOVE khamoosh-e defaulte; bayad sarih roshanesh konim ta
      //--- betoonim khodemoon jabejaii-e panel ro dasti dast begirim
      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, true);

      m_origMouseScroll = (ChartGetInteger(m_chartId, CHART_MOUSE_SCROLL) != 0);

      CreateTitleBar();
      CreateContentControls();
      LayoutAll();

      Print("Panel: DPI-ye safhe = ", (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI),
            " | zarib-e DPI = ", DoubleToString(m_dpiScale, 2),
            " | andaze-ye karbar = ", DoubleToString(m_userScale, 2),
            " | zarib-e mo'asser = ", DoubleToString(m_scale, 2),
            " | chart = ", (int)ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS), "x",
            (int)ChartGetInteger(m_chartId, CHART_HEIGHT_IN_PIXELS), " px");

      Refresh(true);
      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Pak kardan-e hameye object-haye panel. Bayad dar OnDeinit-e      |
   //| asli-e EA seda zade beshe (fargh dare ba dokme-ye Close: in-ja   |
   //| hamishe kamel pak mikone, sarf-e nazar az vaziat-e m_closed)     |
   //+------------------------------------------------------------------+
   void Destroy()
     {
      ChartSetInteger(m_chartId, CHART_EVENT_MOUSE_MOVE, false);
      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll);
      m_scrollLocked = false;
      ObjectsDeleteAll(m_chartId, MKP_PREFIX);
      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Bayad har tick az OnTick-e asli-e EA seda zade beshe. Khodesh    |
   //| dakheli throttle dare - bishtar az 1 bar dar sanie panel ro      |
   //| doobare nemikeshe (mage force=true bashe). Mostatil-haye zone    |
   //| hamishe be-rooz mishan (hata age panel minimize bashe); list-e   |
   //| vaziat faghat vaghti panel minimize nabashe be-rooz mishe        |
   //+------------------------------------------------------------------+
   void Refresh(bool force = false)
     {
      if(m_zoneManager == NULL || m_closed)
         return;

      if(!force && (TimeCurrent() - m_lastRefresh) < 1)
         return;
      m_lastRefresh = TimeCurrent();

      DrawZoneBands();

      if(!m_minimized)
         DrawStatusRows();

      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Bayad az OnChartEvent-e asli-e EA seda zade beshe                |
   //+------------------------------------------------------------------+
   void HandleEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(m_closed)
         return;

      //--- ba har taghir-e chart (scroll / zoom / taghir-e andaze) baze-ye zamani-e
      //--- mostatil-haye zone ro doobare hamtaraz mikonim ta hamishe kol-e chart ro poshesh bedan
      if(id == CHARTEVENT_CHART_CHANGE)
        {
         //--- andaze-ye chart avaz shode? panel ro ba oon hamahang kon (kochik/jabejaii dar sooratike lazem bashe)
         OnChartResized();

         if(m_zoneManager != NULL)
           {
            DrawZoneBands();
            ChartRedraw(m_chartId);
           }
         return;
        }

      //--- jabejaii-e dasti-e panel: MOUSE_MOVE ro dast migirim, chon
      //--- object-haye "anchored" (corner-based) be tanhaii dasti
      //--- keshide nemishan - baraye jabejaii, khodemoon bayad fesharde
      //--- boodan-e dokme-ye chap + harekat-e mouse ro rasad konim
      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         HandleMouseMove((int)lparam, (int)dparam, (uint)StringToInteger(sparam));
         return;
        }

      if(id != CHARTEVENT_OBJECT_CLICK)
         return;

      if(sparam == MKP_PREFIX + "BtnMin")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         ToggleMinimize();
         return;
        }

      if(sparam == MKP_PREFIX + "BtnClose")
        {
         ClosePanel();
         return;
        }

      if(sparam == MKP_PREFIX + "BtnReset")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         ResetLayout();
         return;
        }

      if(sparam == MKP_PREFIX + "Content_BtnModeAuto")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         SetMode(EAMODE_AUTO);
         return;
        }

      if(sparam == MKP_PREFIX + "Content_BtnModeSemi")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         SetMode(EAMODE_SEMI);
         return;
        }

      if(sparam == MKP_PREFIX + "Content_BtnModeManual")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         SetMode(EAMODE_MANUAL);
         return;
        }

      if(sparam == MKP_PREFIX + "Content_BtnBuy")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         OnClickManual(1);
         return;
        }

      if(sparam == MKP_PREFIX + "Content_BtnSell")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         OnClickManual(-1);
         return;
        }

      if(m_zoneManager == NULL)
         return;

      if(sparam == NameAdd(0))
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         OnClickAdd(0);
         return;
        }

      if(sparam == NameAdd(1))
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         OnClickAdd(1);
         return;
        }

      if(sparam == MKP_PREFIX + "Content_BtnClear")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         OnClickClear();
         return;
        }

      if(sparam == MKP_PREFIX + "Content_BtnCloseAll")
        {
         ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
         OnClickCloseAll();
         return;
        }

      HandleRowButton(sparam);
     }

private:
   //+------------------------------------------------------------------+
   //| Esm-e object-haye control-haye har bakhsh (side: 0 = Kharid,     |
   //| 1 = Forush) va har radif                                          |
   //+------------------------------------------------------------------+
   string NameHeader(int side)
     {
      return MKP_PREFIX + "Content_Head" + IntegerToString(side);
     }

   string NameEdit(int side)
     {
      return MKP_PREFIX + "Content_Edit" + IntegerToString(side);
     }

   string NameAdd(int side)
     {
      return MKP_PREFIX + "Content_Add" + IntegerToString(side);
     }

   string NameNote(int side)
     {
      return MKP_PREFIX + "Content_Note" + IntegerToString(side);
     }

   string NameRow(int side, int row)
     {
      return MKP_PREFIX + "Content_Row" + IntegerToString(side) + "_" + IntegerToString(row);
     }

   string NameRowEdit(int side, int row)
     {
      return MKP_PREFIX + "Content_RowEd" + IntegerToString(side) + "_" + IntegerToString(row);
     }

   string NameRowDel(int side, int row)
     {
      return MKP_PREFIX + "Content_RowDel" + IntegerToString(side) + "_" + IntegerToString(row);
     }

   //+------------------------------------------------------------------+
   //| Andaze-haye chidemane: yek bakhsh = onvan(16) + edit box(28) +    |
   //| radif-ha + yadadasht(14) + fasele(8)                              |
   //+------------------------------------------------------------------+
   int SectionHeight()
     {
      return 44 + m_maxRows * MKP_ROW_H + 14 + 8;
     }

   //--- bala-ye content: [dokme-ye halat][BUY SELL][khat-e etela'at 1][khat-e etela'at 2][CLOSE ALL][rahnama + Pak Kon]
   int TradeBlockHeight()
     {
      return 142;
     }

   //--- (pixel-e tarrahi, nesbat be goosheh-ye bala-chap-e panel)
   int SectionTop(int side)
     {
      return MKP_TITLEBAR_H + TradeBlockHeight() + side * SectionHeight();
     }

   int ContentHeight()
     {
      return TradeBlockHeight() + 2 * SectionHeight() + 18;   // 18 = fazaye grip-e payin-rast
     }

   int BaseHeight()
     {
      return MKP_TITLEBAR_H + ContentHeight();
     }

   //+------------------------------------------------------------------+
   //| Moghyas-giri: hame-ye andaze-ha dar "pixel-e tarrahi" (96 DPI =   |
   //| 100%) neveshte shodan va ba S() be pixel-e vaghei tabdil mishan.  |
   //| Font ba FS() tabdil mishe; chon MetaTrader size-e font (point) ro |
   //| khodesh ba DPI bozorg mikone, zarib-e font = zarib-e hendese /    |
   //| zarib-e DPI ast (dar gheyr-e in surat dobare bozorg mishod)       |
   //+------------------------------------------------------------------+
   int S(int v)
     {
      int r = (int)MathRound(v * m_scale);
      if(v > 0 && r < 1)
         r = 1;
      return r;
     }

   int FS(int points)
     {
      int r = (int)MathRound(points * m_fontScale);
      return (r < 6) ? 6 : r;
     }

   int PW()
     {
      return S(MKP_BASE_W);
     }

   int PH()
     {
      return m_minimized ? S(MKP_TITLEBAR_H) : S(BaseHeight());
     }

   //--- DPI-ye safhe (96 = 100%). Age terminal DPI ro nadad, 96 farz mishe
   void DetectDpi()
     {
      int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
      if(dpi <= 0)
         dpi = 96;

      m_dpiScale = MathMax(0.75, MathMin(dpi / 96.0, 3.0));
     }

   //+------------------------------------------------------------------+
   //| Zarib-e mo'asser = DPI x andaze-ye karbar, ama hadd-aksar-esh be  |
   //| andazei mahdood mishe ke panel kamel too-ye chart bejaaye (dar    |
   //| gheyr-e in surat panel kochik mishe); hadd-aghal 0.5              |
   //+------------------------------------------------------------------+
   void UpdateScale()
     {
      double s = m_dpiScale * m_userScale;

      long cw = ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
      long ch = ChartGetInteger(m_chartId, CHART_HEIGHT_IN_PIXELS);

      if(cw > 0 && ch > 0)
        {
         double fitW = ((double)cw - 8.0) / MKP_BASE_W;
         double fitH = ((double)ch - 8.0) / BaseHeight();
         s = MathMin(s, MathMin(fitW, fitH));
        }

      if(s < 0.5)
         s = 0.5;

      m_scale     = s;
      m_fontScale = s / m_dpiScale;
     }

   //--- panel ro too-ye mantaghe-ye chart negah midare (hadeaghal navar-e onvan hamishe didani)
   void ClampPosition(int &x, int &y)
     {
      long cw = ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
      long ch = ChartGetInteger(m_chartId, CHART_HEIGHT_IN_PIXELS);
      if(cw <= 0 || ch <= 0)
         return;

      int maxX = (int)cw - PW();
      int maxY = (int)ch - PH();
      if(maxX < 0)
         maxX = 0;
      if(maxY < 0)
         maxY = 0;

      if(x > maxX)
         x = maxX;
      if(y > maxY)
         y = maxY;
      if(x < 0)
         x = 0;
      if(y < 0)
         y = 0;
     }

   //--- chart andazash avaz shod: age zarib ya jaye mo'asser avaz shode bashe, doobare chideman
   void OnChartResized()
     {
      double oldScale = m_scale;
      int    oldX     = m_x;
      int    oldY     = m_yStart;

      UpdateScale();
      ClampPosition(m_x, m_yStart);

      if(MathAbs(m_scale - oldScale) > 0.004 || m_x != oldX || m_yStart != oldY)
        {
         LayoutAll();
         ChartRedraw(m_chartId);
        }
     }

   //+------------------------------------------------------------------+
   //| Zakhire/bargozari-ye jaye panel va andaze-ye karbar dar            |
   //| GlobalVariable (kelid = esm-e symbol) - ba avaz-e timeframe ya    |
   //| restart-e EA panel jash ro az dast nemide                          |
   //+------------------------------------------------------------------+
   string LayoutKey(string what)
     {
      return "MKEA_Panel" + what + "_" + m_symbol;
     }

   void LoadLayout()
     {
      m_userScale = 1.0;
      m_x         = 10;
      m_yStart    = 20;

      if(GlobalVariableCheck(LayoutKey("Scale")))
         m_userScale = MathMax(0.6, MathMin(2.5, GlobalVariableGet(LayoutKey("Scale"))));

      if(GlobalVariableCheck(LayoutKey("X")) && GlobalVariableCheck(LayoutKey("Y")))
        {
         m_x      = (int)GlobalVariableGet(LayoutKey("X"));
         m_yStart = (int)GlobalVariableGet(LayoutKey("Y"));
        }
     }

   void SaveLayout()
     {
      GlobalVariableSet(LayoutKey("Scale"), m_userScale);
      GlobalVariableSet(LayoutKey("X"), (double)m_x);
      GlobalVariableSet(LayoutKey("Y"), (double)m_yStart);
     }

   //--- dokme-ye R: bazgasht be andaze/jaye avalie
   void ResetLayout()
     {
      m_userScale = 1.0;
      m_x         = 10;
      m_yStart    = 20;
      SaveLayout();
      LayoutAll();
      ChartRedraw(m_chartId);
     }

   //--- scroll-e chart ro vaghti mouse rooye panel-e ghofl mikone (ta keshidan-e panel chart ro nakeshe)
   void UpdateScrollLock(bool lock)
     {
      if(lock == m_scrollLocked)
         return;

      m_scrollLocked = lock;
      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll && !lock);
     }

   bool IsInsidePanel(int x, int y)
     {
      return (x >= m_x && x <= m_x + PW() && y >= m_yStart && y <= m_yStart + PH());
     }

   //--- mantaghe-ye grip-e payin-rast (20 x 20 pixel-e tarrahi)
   bool IsInsideGrip(int x, int y)
     {
      if(m_minimized)
         return false;

      int gx = m_x + S(MKP_BASE_W - 20);
      int gy = m_yStart + S(BaseHeight() - 20);

      return (x >= gx && x <= m_x + PW() && y >= gy && y <= m_yStart + PH());
     }

   //+------------------------------------------------------------------+
   //| Halat dar GlobalVariable-e terminal zakhire mishe (kelid = esm-e  |
   //| symbol; 0 = AUTO, 1 = NIM-AUTO, 2 = DASTI), ta ba avaz-e timeframe|
   //| ya restart-e EA (ke OnInit doobare seda zade mishe) bedoone khabar|
   //| be halat-e AUTO bar nagarde va EA khodash vared-e moamele nashe   |
   //+------------------------------------------------------------------+
   string ModeKey()
     {
      return "MKEA_Mode_" + m_symbol;
     }

   ENUM_EA_MODE LoadMode()
     {
      string key = ModeKey();

      m_modeRestored = false;

      if(GlobalVariableCheck(key))
        {
         m_modeRestored = true;   // [v1.19]
         int v = (int)MathRound(GlobalVariableGet(key));
         if(v == 1)
            return EAMODE_SEMI;
         if(v == 2)
            return EAMODE_MANUAL;
         return EAMODE_AUTO;
        }

      //--- nosakhe-ye ghabli (1.06) faghat ye flag-e nim-automatic dasht
      string oldKey = "MKEA_SemiAuto_" + m_symbol;
      if(GlobalVariableCheck(oldKey) && GlobalVariableGet(oldKey) > 0.5)
        {
         m_modeRestored = true;   // [v1.19]
         return EAMODE_SEMI;
        }

      //--- [v1.12] avalin bar (ya vaghti zakhire-ye halat az bein rafte) nim-automatic, na AUTO - ta EA nagahani khodesh vared nashe
      return EAMODE_SEMI;
     }

   void SaveMode()
     {
      GlobalVariableSet(ModeKey(), (double)((int)m_mode));
     }

   //+------------------------------------------------------------------+
   //| Click-e yeki az se dokme-ye halat                                 |
   //+------------------------------------------------------------------+
   void SetMode(ENUM_EA_MODE mode)
     {
      if(mode == m_mode)
         return;

      m_mode = mode;
      SaveMode();

      if(mode == EAMODE_AUTO)
         Print("Panel: halat-e AUTOMATIC roshan shod - EA ba tayidiye-ye zone khodash vared-e moamele mishe.");
      else if(mode == EAMODE_SEMI)
         Print("Panel: halat-e NIM-AUTOMATIC roshan shod - EA vared nemishe (faghat hoshdar mide); ba dokme-haye BUY/SELL-e panel vared sho.");
      else
         Print("Panel: halat-e DASTI roshan shod - ba dokme-haye khod-e MetaTrader vared sho; EA SL/TP mizare va modiriat mikone.");

      UpdateTradeUi();
      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Click-e dokme-ye BUY / SELL-e panel: faghat darkhast sabt mishe   |
   //| (EA-ye asli anjamesh mide). Faghat dar halat-e NIM-AUTO faale     |
   //+------------------------------------------------------------------+
   void OnClickManual(int direction)
     {
      if(m_mode != EAMODE_SEMI)
        {
         Print("Panel: dokme-haye BUY/SELL-e panel faghat dar halat-e NIM-AUTOMATIC faal-and (dar halat-e DASTI ba dokme-haye khod-e MetaTrader vared sho).");
         return;
        }

      m_manualRequest = direction;
     }

   //+------------------------------------------------------------------+
   //| Rang-e dokme-ye halat: faal = rang-e khodesh, gheir-faal = khakestari|
   //+------------------------------------------------------------------+
   void SetModeButton(string name, bool active, color activeColor)
     {
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, active ? activeColor : C'50,50,62');
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, active ? clrWhite : clrSilver);
     }

   //+------------------------------------------------------------------+
   //| Be-rooz kardan-e se dokme-ye halat, dokme-haye BUY/SELL (rang/    |
   //| matn: faal ya gheir-faal) va do khat-e etela'at                    |
   //+------------------------------------------------------------------+
   void UpdateTradeUi()
     {
      ObjectSetString(m_chartId, MKP_PREFIX + "Content_Info1", OBJPROP_TEXT, m_info1);
      ObjectSetString(m_chartId, MKP_PREFIX + "Content_Info2", OBJPROP_TEXT, m_info2);

      SetModeButton(MKP_PREFIX + "Content_BtnModeAuto", m_mode == EAMODE_AUTO, InpColModeAuto);
      SetModeButton(MKP_PREFIX + "Content_BtnModeSemi", m_mode == EAMODE_SEMI, InpColModeSemi);
      SetModeButton(MKP_PREFIX + "Content_BtnModeManual", m_mode == EAMODE_MANUAL, InpColModeManual);

      bool   semi     = (m_mode == EAMODE_SEMI);
      string buyName  = MKP_PREFIX + "Content_BtnBuy";
      string sellName = MKP_PREFIX + "Content_BtnSell";
      ObjectSetString(m_chartId, buyName, OBJPROP_TEXT, semi ? "BUY" : "BUY (gheir-faal)");
      ObjectSetString(m_chartId, sellName, OBJPROP_TEXT, semi ? "SELL" : "SELL (gheir-faal)");
      ObjectSetInteger(m_chartId, buyName, OBJPROP_BGCOLOR, semi ? C'30,135,65' : C'55,62,56');
      ObjectSetInteger(m_chartId, sellName, OBJPROP_BGCOLOR, semi ? C'175,45,45' : C'66,56,56');
     }

   //+------------------------------------------------------------------+
   //| Click-e dokme-ye Ezafe / Zakhire-ye ye bakhsh: age dar hale      |
   //| virayesh-e hamin bakhsh bashim zone-e entekhab-shode virayesh    |
   //| mishe, vagarna zone-e jadid be hamin bakhsh ezafe mishe          |
   //+------------------------------------------------------------------+
   void OnClickAdd(int side)
     {
      string text = ObjectGetString(m_chartId, NameEdit(side), OBJPROP_TEXT);
      text = NormalizeInputText(text);
      StringTrimLeft(text);
      StringTrimRight(text);

      bool editing = (m_editIndex >= 0 && m_editSide == side);

      //--- matn-e khali: age dar hale virayesh bashim yani laghv
      if(StringLen(text) == 0)
        {
         if(editing)
           {
            CancelEdit();
            Refresh(true);
           }
         return;
        }

      double priceLow, priceHigh;
      bool   isSingle;
      if(!ParseZoneText(text, priceLow, priceHigh, isSingle))
        {
         Print("Panel: vorudi na-motabar - '", text, "' (bayad ye adad-e sahih ya ye baze-ye 'A-B' bashe)");
         ObjectSetString(m_chartId, NameEdit(side), OBJPROP_TEXT, "Adad-e Motabar Nist!");
         return;
        }

      if(editing)
        {
         if(isSingle)
            m_zoneManager.UpdateZone(m_editIndex, priceLow);
         else
            m_zoneManager.UpdateZoneRange(m_editIndex, priceLow, priceHigh);

         m_editIndex = -1;
        }
      else
        {
         ENUM_ZONE_DIRECTION direction = (side == 0) ? ZONE_BUY : ZONE_SELL;

         if(isSingle)
            m_zoneManager.AddZone(priceLow, direction);
         else
            m_zoneManager.AddZoneRange(priceLow, priceHigh, direction);
        }

      ObjectSetString(m_chartId, NameEdit(side), OBJPROP_TEXT, "");
      Refresh(true);
     }

   //+------------------------------------------------------------------+
   //| Ragham-haye farsi/arabi ro be ragham-e englisi tabdil mikone (ta |
   //| age keyboard farsi bood ham zone ghabul beshe); khat-tire-haye   |
   //| makhsoos ro ham be '-' va ashar-e arabi ro be '.' tabdil mikone  |
   //+------------------------------------------------------------------+
   string NormalizeInputText(string text)
     {
      int len = StringLen(text);

      for(int i = 0; i < len; i++)
        {
         ushort c = StringGetCharacter(text, i);

         if(c >= 0x06F0 && c <= 0x06F9)
            StringSetCharacter(text, i, (ushort)('0' + (c - 0x06F0)));
         else if(c >= 0x0660 && c <= 0x0669)
            StringSetCharacter(text, i, (ushort)('0' + (c - 0x0660)));
         else if(c == 0x066B)
            StringSetCharacter(text, i, '.');
         else if(c == 0x2013 || c == 0x2014 || c == 0x2212)
            StringSetCharacter(text, i, '-');
        }

      return text;
     }

   //+------------------------------------------------------------------+
   //| Parse-e matn-e zone (masalan "4321" ya "4334-4336"). Bar         |
   //| migardoone: true = motabar                                        |
   //+------------------------------------------------------------------+
   bool ParseZoneText(string text, double &priceLow, double &priceHigh, bool &isSingle)
     {
      string rangeParts[];
      int rangeCount = StringSplit(text, '-', rangeParts);

      if(rangeCount == 2)
        {
         priceLow  = StringToDouble(rangeParts[0]);
         priceHigh = StringToDouble(rangeParts[1]);

         if(priceLow <= 0 || priceHigh <= 0)
            return false;

         isSingle = false;
         return true;
        }

      if(rangeCount != 1)
         return false;

      priceLow  = StringToDouble(text);
      priceHigh = priceLow;

      if(priceLow <= 0)
         return false;

      isSingle = true;
      return true;
     }

   //+------------------------------------------------------------------+
   //| Click-e dokme-haye "Vir" va "X" -e radif-ha. Radif -> zone az     |
   //| rooye m_rowMap (ke har bar DrawStatusRows por mikone) peida mishe|
   //+------------------------------------------------------------------+
   void HandleRowButton(string sparam)
     {
      for(int side = 0; side < 2; side++)
        {
         for(int r = 0; r < m_maxRows; r++)
           {
            if(sparam == NameRowEdit(side, r))
              {
               ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
               OnClickRowEdit(side, r);
               return;
              }

            if(sparam == NameRowDel(side, r))
              {
               ObjectSetInteger(m_chartId, sparam, OBJPROP_STATE, false);
               OnClickRowDelete(side, r);
               return;
              }
           }
        }
     }

   //+------------------------------------------------------------------+
   //| Click-e "Vir": meghdar-e zone toye edit box-e hamoon bakhsh miad |
   //| va dokme-ye Ezafe mishe Zakhire. Click-e dobare rooye hamoon      |
   //| radif = laghv-e virayesh                                           |
   //+------------------------------------------------------------------+
   void OnClickRowEdit(int side, int row)
     {
      int zoneIndex = m_rowMap[side * m_maxRows + row];
      if(zoneIndex < 0)
         return;

      if(m_editIndex == zoneIndex)
        {
         CancelEdit();
        }
      else
        {
         //--- age dar hale virayesh-e zone-e bakhsh-e digeh boodim, edit box-e oon ro khali mikonim
         if(m_editIndex >= 0 && m_editSide != side)
            ObjectSetString(m_chartId, NameEdit(m_editSide), OBJPROP_TEXT, "");

         m_editIndex = zoneIndex;
         m_editSide  = side;
         ObjectSetString(m_chartId, NameEdit(side), OBJPROP_TEXT, m_zoneManager.GetZoneText(zoneIndex));
        }

      Refresh(true);
     }

   //+------------------------------------------------------------------+
   //| Click-e "X": pak kardan-e ye zone                                 |
   //+------------------------------------------------------------------+
   void OnClickRowDelete(int side, int row)
     {
      int zoneIndex = m_rowMap[side * m_maxRows + row];
      if(zoneIndex < 0)
         return;

      if(m_zoneManager.RemoveZone(zoneIndex))
        {
         if(m_editIndex == zoneIndex)
            CancelEdit();
         else if(m_editIndex > zoneIndex)
            m_editIndex--;
        }

      Refresh(true);
     }

   //+------------------------------------------------------------------+
   //| Laghv-e virayesh: edit box-e hamoon bakhsh khali mishe            |
   //+------------------------------------------------------------------+
   void CancelEdit()
     {
      if(m_editIndex >= 0)
         ObjectSetString(m_chartId, NameEdit(m_editSide), OBJPROP_TEXT, "");

      m_editIndex = -1;
     }

   //+------------------------------------------------------------------+
   //| Click-e dokme-ye Pak Kon Hame                                    |
   //+------------------------------------------------------------------+
   void OnClickClear()
     {
      m_zoneManager.ClearZones();
      CancelEdit();
      Refresh(true);
     }

   //+------------------------------------------------------------------+
   //| Click-e dokme-ye CLOSE ALL: click-e aval "aslih" mikone (3 sanie) |
   //| va click-e dovom hame-ye position-haye in symbol ro mibande       |
   //+------------------------------------------------------------------+
   void OnClickCloseAll()
     {
      if(m_tradeManager == NULL)
        {
         Print("Panel: CLOSE ALL - TradeManager vasl nashode.");
         return;
        }

      uint now = GetTickCount();

      if(now < m_closeAllArmedUntil)
        {
         m_closeAllArmedUntil = 0;
         Print("Panel: CLOSE ALL - bastan-e hame-ye moamele-ha shoroe shod.");
         m_tradeManager.CloseAllPositions();
        }
      else
        {
         m_closeAllArmedUntil = now + 3000;
        }

      UpdateCloseAllButton();
      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Matn/rang-e dokme-ye CLOSE ALL bar asas-e inke aslih hast ya na  |
   //+------------------------------------------------------------------+
   void UpdateCloseAllButton()
     {
      string name  = MKP_PREFIX + "Content_BtnCloseAll";
      bool   armed = (GetTickCount() < m_closeAllArmedUntil);

      ObjectSetString(m_chartId, name, OBJPROP_TEXT,
                      armed ? "MOTMAEN-I? DOOBARE BEZAN (3 sanie)" : "CLOSE ALL  (bastan-e hame-ye moamele-ha)");
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, armed ? C'210,120,0' : C'160,25,25');
     }

   //+------------------------------------------------------------------+
   //| Minimize/Restore - vaghti minimize mishe, control-haye dakheli   |
   //| (edit/dokme/list) kamelan pak mishan (chon nemishe ye object ro  |
   //| "makhfi" kard bedoone pakesh - bayad doobare besazimesh); navar-e|
   //| onvan va dokme-haye min/close hamishe bagi mimoonan               |
   //+------------------------------------------------------------------+
   void ToggleMinimize()
     {
      m_minimized = !m_minimized;

      if(m_minimized)
        {
         m_editIndex = -1;
         DestroyContentControls();
         LayoutAll();
        }
      else
        {
         CreateContentControls();
         LayoutAll();
         Refresh(true);
        }

      ObjectSetString(m_chartId, MKP_PREFIX + "BtnMin", OBJPROP_TEXT, m_minimized ? "+" : "_");
      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Close (X) - hameye object-haye panel (title bar ham jozvesh) az  |
   //| chart pak mishe. Baraye bargashtan: EA Properties ro doobare baz |
   //| kon va OK bezan - OnInit doobare seda zade mishe va Create() az  |
   //| no hameye panel ro misaze (m_closed doobare false mishe)          |
   //+------------------------------------------------------------------+
   void ClosePanel()
     {
      if(m_mode == EAMODE_SEMI)
         Print("Panel: hoshdar - panel baste shod dar halati ke halat-e NIM-AUTOMATIC roshane; EA vared-e moamele nemishe va dokme-ye BUY/SELL dar dastres nist.");
      else if(m_mode == EAMODE_MANUAL)
         Print("Panel: hoshdar - panel baste shod dar halati ke halat-e DASTI roshane; EA vared-e moamele nemishe (SL/TP-e position-haye dasti hamchenan mikhore).");

      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll);
      m_scrollLocked = false;

      ObjectsDeleteAll(m_chartId, MKP_PREFIX);
      m_closed = true;
      ChartRedraw(m_chartId);
     }

   //+------------------------------------------------------------------+
   //| Rasad-e mouse baraye jabejaii va taghir-e andaze-ye panel (age    |
   //| CHART_EVENT_MOUSE_MOVE roshan bashe - dar Create() roshanesh      |
   //| kardim). "Feshar" = taghir-e vaziat-e dokme-ye chap az bala be    |
   //| paiin:                                                              |
   //|  - feshar rooye navar-e onvan: shoroe-ye jabejaii (clamp too-ye   |
   //|    chart)                                                           |
   //|  - feshar rooye grip-e payin-rast: shoroe-ye taghir-e andaze      |
   //|    (zarib-e hame-ye panel az rooye mokhtasat-e mouse)             |
   //|  - ol kardan-e dokme: payan va zakhire-ye jaye/andaze              |
   //| Vaghti mouse rooye panele (ya dar hale drag/resize) scroll-e      |
   //| chart ghofl mishe                                                   |
   //+------------------------------------------------------------------+
   void HandleMouseMove(int mouseX, int mouseY, uint mouseFlags)
     {
      bool leftDown   = (mouseFlags & 1) != 0; // bit 0 = dokme-ye chap-e mouse fesharde-she
      bool pressedNow = (leftDown && !m_prevLeftDown);
      m_prevLeftDown  = leftDown;

      UpdateScrollLock(m_dragging || m_resizing || IsInsidePanel(mouseX, mouseY));

      if(m_dragging)
        {
         if(!leftDown)
           {
            m_dragging = false;
            SaveLayout();
            return;
           }

         int newX = mouseX - m_dragOffsetX;
         int newY = mouseY - m_dragOffsetY;
         ClampPosition(newX, newY);

         if(newX != m_x || newY != m_yStart)
           {
            m_x      = newX;
            m_yStart = newY;
            LayoutAll(false);
            ChartRedraw(m_chartId);
           }
         return;
        }

      if(m_resizing)
        {
         if(!leftDown)
           {
            m_resizing = false;

            //--- zarib-e vaghei (ba dar nazar gereftan-e hadd-e chart) zakhire mishe
            m_userScale = m_scale / m_dpiScale;
            SaveLayout();
            return;
           }

         double baseW = MKP_BASE_W * m_dpiScale;
         double baseH = BaseHeight() * m_dpiScale;
         double wr    = (mouseX + m_resizeOffX - m_x) / baseW;
         double hr    = (mouseY + m_resizeOffY - m_yStart) / baseH;
         double ns    = MathMax(0.6, MathMin(2.5, (wr + hr) / 2.0));

         uint nowTick = GetTickCount();
         if(MathAbs(ns - m_userScale) >= 0.01 && (nowTick - m_lastLayoutTick) >= 30)
           {
            m_userScale      = ns;
            m_lastLayoutTick = nowTick;
            LayoutAll();
            ChartRedraw(m_chartId);
           }
         return;
        }

      if(!pressedNow)
         return;

      if(IsInsideGrip(mouseX, mouseY))
        {
         m_resizing   = true;
         m_resizeOffX = (m_x + PW()) - mouseX;
         m_resizeOffY = (m_yStart + PH()) - mouseY;
         return;
        }

      if(IsInsideTitleBarDragZone(mouseX, mouseY))
        {
         m_dragging    = true;
         m_dragOffsetX = mouseX - m_x;
         m_dragOffsetY = mouseY - m_yStart;
        }
     }

   //+------------------------------------------------------------------+
   //| Aya (x,y) too mantaghe-ye "keshidani"-e navar-e onvan hast? Faghat|
   //| bakhsh-e chap-e navar (jaii ke matn hast) - bakhsh-e rast (dokme  |
   //| -haye Reset/Min/Close) amdan berun gozashte shode ta click        |
   //| roosh-oon dargir-e dragging nashe                                  |
   //+------------------------------------------------------------------+
   bool IsInsideTitleBarDragZone(int x, int y)
     {
      if(y < m_yStart || y > m_yStart + S(MKP_TITLEBAR_H))
         return false;

      int dragRightEdge = m_x + S(MKP_BASE_W - 66);   // faza baraye se dokme-ye Reset/Min/Close
      return (x >= m_x && x <= dragRightEdge);
     }

   //+------------------------------------------------------------------+
   //| Mohasebeye baze-ye zamani-e (chap/rast) mostatil-haye zone.       |
   //| Az ye safhe be chap-e chap-tarin candle-e ghabel-e didan ta ye    |
   //| safhe be rast-e akharin candle - ta mostatil hamishe kol-e chart  |
   //| ro poshesh bede, vali andazash motaadel bemoone. Ba har scroll/   |
   //| zoom (CHARTEVENT_CHART_CHANGE) dobare hesab mishe.                |
   //+------------------------------------------------------------------+
   void GetBandTimeSpan(datetime &timeLeft, datetime &timeRight)
     {
      string          sym       = ChartSymbol(m_chartId);
      ENUM_TIMEFRAMES tf        = (ENUM_TIMEFRAMES)ChartPeriod(m_chartId);
      int             periodSec = PeriodSeconds(tf);
      if(periodSec <= 0)
         periodSec = 60;

      int firstVisible = (int)ChartGetInteger(m_chartId, CHART_FIRST_VISIBLE_BAR);
      int widthBars    = (int)ChartGetInteger(m_chartId, CHART_WIDTH_IN_BARS);
      if(firstVisible < 0)
         firstVisible = 0;
      if(widthBars < 20)
         widthBars = 100;

      datetime tm[];

      //--- rast: zaman-e akharin candle + ye safhe be samt-e ayande
      datetime lastBarTime = TimeCurrent();
      if(CopyTime(sym, tf, 0, 1, tm) == 1)
         lastBarTime = tm[0];
      timeRight = (datetime)((long)lastBarTime + (long)periodSec * widthBars);

      //--- chap: chap-tarin candle-e ghabel-e didan + ye safhe be samt-e gozashte
      int leftIndex = firstVisible + widthBars;
      int total     = Bars(sym, tf);
      if(total > 0 && leftIndex > total - 1)
         leftIndex = total - 1;

      if(total > 0 && CopyTime(sym, tf, leftIndex, 1, tm) == 1)
         timeLeft = tm[0];
      else
         timeLeft = (datetime)((long)lastBarTime - (long)periodSec * leftIndex);

      //--- ehtiyat: hamishe bayad chap < rast bashe
      if(timeLeft >= timeRight)
         timeLeft = (datetime)((long)timeRight - (long)periodSec * 2 * widthBars);
     }

   //+------------------------------------------------------------------+
   //| Rang-e mostatil-e zone bar asas-e jahat va vaziat                 |
   //+------------------------------------------------------------------+
   color BandColor(ENUM_ZONE_DIRECTION direction, ENUM_ZONE_STATE state)
     {
      if(state == ZONE_STATE_INVALID)
         return MKP_ZONE_INVALID;

      if(direction == ZONE_BUY)
        {
         if(state == ZONE_STATE_ARMED)
            return MKP_BUY_ARMED;
         if(state == ZONE_STATE_TRIGGERED)
            return MKP_BUY_DONE;
         return MKP_BUY_WAITING;
        }

      if(state == ZONE_STATE_ARMED)
         return MKP_SELL_ARMED;
      if(state == ZONE_STATE_TRIGGERED)
         return MKP_SELL_DONE;
      return MKP_SELL_WAITING;
     }

   //+------------------------------------------------------------------+
   //| Rasm-e ye mostatil-e por-rang (OBJ_RECTANGLE) baraye har zone     |
   //| posht-e candle-ha. Age mostatil vojood nadashte bashe sakhte      |
   //| mishe, vagarna faghat baze-ye zamani/gheimat-esh be-rooz mishe    |
   //| (bedoone pak/sakht-e mojaddad - ta chesh-mak nazane). Rang bar    |
   //| asas-e jahat va vaziat-e zone set mishe. Index-e mostatil = index|
   //| -e zone; vaghti zone pak beshe, mostatil-haye ezafi pak mishan va|
   //| gheimat-e baghie ba zone-haye jadid hamtaraz mishe                |
   //+------------------------------------------------------------------+
   void DrawZoneBands()
     {
      int count = m_zoneManager.Count();

      datetime timeLeft, timeRight;
      GetBandTimeSpan(timeLeft, timeRight);
      bool timeChanged = (timeLeft != m_bandTimeLeft || timeRight != m_bandTimeRight);

      for(int i = 0; i < count; i++)
        {
         double priceLow, priceHigh;
         string label;
         ENUM_ZONE_DIRECTION direction;
         ENUM_ZONE_STATE     state;

         if(!m_zoneManager.GetZoneSnapshot(i, priceLow, priceHigh, label, direction, state))
            continue;

         color  bandColor = BandColor(direction, state);
         string name      = MKP_PREFIX + "ZoneBand_" + IntegerToString(i);

         if(ObjectFind(m_chartId, name) < 0)
           {
            if(!ObjectCreate(m_chartId, name, OBJ_RECTANGLE, 0, timeLeft, priceHigh, timeRight, priceLow))
              {
               if(!m_bandErrorLogged)
                 {
                  Print("Panel: khata dar sakhtan-e mostatil-e zone [", label, "] - code: ", GetLastError());
                  m_bandErrorLogged = true;
                 }
               continue;
              }

            ObjectSetInteger(m_chartId, name, OBJPROP_FILL, true);         // por-rang
            ObjectSetInteger(m_chartId, name, OBJPROP_BACK, true);         // posht-e candle-ha
            ObjectSetInteger(m_chartId, name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(m_chartId, name, OBJPROP_WIDTH, 1);
            ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
            ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);

            Print("Panel: mostatil-e zone sakhte shod [", label, "] | zaman: ",
                  TimeToString(timeLeft), " ta ", TimeToString(timeRight),
                  " | gheimat: ", DoubleToString(priceLow, m_digits), " ta ", DoubleToString(priceHigh, m_digits));
           }
         else
           {
            //--- gheimat-ha momkene avaz shode bashan (virayesh-e zone ya jabejaii-e index ba'd az pak kardan)
            bool priceChanged = (MathAbs(ObjectGetDouble(m_chartId, name, OBJPROP_PRICE, 0) - priceHigh) > m_point * 0.5) ||
                                (MathAbs(ObjectGetDouble(m_chartId, name, OBJPROP_PRICE, 1) - priceLow) > m_point * 0.5);

            if(timeChanged || priceChanged)
              {
               ObjectMove(m_chartId, name, 0, timeLeft, priceHigh);
               ObjectMove(m_chartId, name, 1, timeRight, priceLow);
              }
           }

         ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, bandColor);
        }

      //--- mostatil-haye ezafi (masalan ba'd az pak kardan-e zone) ro pak mikonim
      for(int k = count; k < m_bandsDrawn; k++)
         ObjectDelete(m_chartId, MKP_PREFIX + "ZoneBand_" + IntegerToString(k));

      m_bandsDrawn    = count;
      m_bandTimeLeft  = timeLeft;
      m_bandTimeRight = timeRight;
     }

   //+------------------------------------------------------------------+
   //| Be-rooz kardan-e list-e vaziat-e zone-ha rooye khod-e panel.      |
   //| Zone-ha ba jahatshoon dar do bakhsh-e joda (Kharid / Forush)      |
   //| chide mishan; m_rowMap radif -> index-e zone ro negah midare      |
   //+------------------------------------------------------------------+
   void DrawStatusRows()
     {
      int count = m_zoneManager.Count();
      int used[2] = {0, 0};

      //--- age zone-i ke dar hale virayeshe digeh vojood nadare, virayesh laghv mishe
      if(m_editIndex >= count)
         CancelEdit();

      for(int k = 0; k < ArraySize(m_rowMap); k++)
         m_rowMap[k] = -1;

      for(int zi = 0; zi < count; zi++)
        {
         double priceLow, priceHigh;
         string label;
         ENUM_ZONE_DIRECTION direction;
         ENUM_ZONE_STATE     state;

         if(!m_zoneManager.GetZoneSnapshot(zi, priceLow, priceHigh, label, direction, state))
            continue;

         int side = (direction == ZONE_BUY) ? 0 : 1;
         int r    = used[side];
         used[side]++;

         if(r < m_maxRows)
            m_rowMap[side * m_maxRows + r] = zi;
        }

      for(int side = 0; side < 2; side++)
        {
         for(int r = 0; r < m_maxRows; r++)
           {
            int    zoneIndex = m_rowMap[side * m_maxRows + r];
            string rowName   = NameRow(side, r);

            if(zoneIndex < 0)
              {
               ObjectSetString(m_chartId, rowName, OBJPROP_TEXT, "");
               SetVisible(NameRowEdit(side, r), false);
               SetVisible(NameRowDel(side, r), false);
               continue;
              }

            double priceLow, priceHigh;
            string label;
            ENUM_ZONE_DIRECTION direction;
            ENUM_ZONE_STATE     state;
            m_zoneManager.GetZoneSnapshot(zoneIndex, priceLow, priceHigh, label, direction, state);

            string stateText  = "Montazer";
            color  stateColor = clrSilver;

            if(state == ZONE_STATE_ARMED)
              {
               stateText  = "Vared";
               stateColor = clrOrange;
              }
            else if(state == ZONE_STATE_TRIGGERED)
              {
               stateText  = "Tayid";
               stateColor = clrLimeGreen;
              }
            else if(state == ZONE_STATE_INVALID)
              {
               stateText  = "Namotabar";
               stateColor = clrDimGray;
              }

            string line = IntegerToString(r + 1) + ") " + m_zoneManager.GetZoneText(zoneIndex) + "  [" + stateText + "]";
            if(zoneIndex == m_editIndex)
               line += "  *";

            ObjectSetString(m_chartId, rowName, OBJPROP_TEXT, line);
            ObjectSetInteger(m_chartId, rowName, OBJPROP_COLOR, stateColor);

            SetVisible(NameRowEdit(side, r), true);
            SetVisible(NameRowDel(side, r), true);
           }

         //--- age zone-haye bishtari az tedad-e radif-ha vojood dare
         int extra = used[side] - m_maxRows;
         ObjectSetString(m_chartId, NameNote(side), OBJPROP_TEXT,
                         extra > 0 ? ("+ " + IntegerToString(extra) + " zone-ye digeh (ba pak kardan-e balaii-ha)") : "");
        }

      UpdateEditUi();
      UpdateCloseAllButton();
      UpdateTradeUi();
     }

   //+------------------------------------------------------------------+
   //| Onvan-e har bakhsh va matn-e dokme-ye Ezafe/Zakhire bar asas-e    |
   //| inke dar hale virayesh hastim ya na                               |
   //+------------------------------------------------------------------+
   void UpdateEditUi()
     {
      for(int side = 0; side < 2; side++)
        {
         bool   editing = (m_editIndex >= 0 && m_editSide == side);
         string head    = (side == 0) ? "ZONE-E KHARID (Buy)" : "ZONE-E FOROUSH (Sell)";

         if(editing)
            head += "  -  virayesh";

         ObjectSetString(m_chartId, NameHeader(side), OBJPROP_TEXT, head);
         ObjectSetString(m_chartId, NameAdd(side), OBJPROP_TEXT, editing ? "Zakhire" : "+ Ezafe");
        }
     }

   //+------------------------------------------------------------------+
   //| Namayesh/makhfi kardan-e ye object (baraye dokme-haye radif-haye |
   //| khali) - bedoone pak kardan-e object                              |
   //+------------------------------------------------------------------+
   void SetVisible(string name, bool visible)
     {
      ObjectSetInteger(m_chartId, name, OBJPROP_TIMEFRAMES, visible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
     }

   //+------------------------------------------------------------------+
   //| Sakhtan-e navar-e onvan (title bar) + dokme-haye Reset/Minimize/ |
   //| Close. Dar in marhale faghat object-ha sakhte mishan (rang/matn);|
   //| mokhtasat, andaze va font hame dar LayoutAll set mishan           |
   //+------------------------------------------------------------------+
   void CreateTitleBar()
     {
      CreateRectLabel(MKP_PREFIX + "TitleBar", C'35,35,48', clrDimGray);
      CreateLabel(MKP_PREFIX + "TitleText", "MagicKeysEA  (bekesh = jabejaii)", clrWhite, true);
      CreateButton(MKP_PREFIX + "BtnReset", "R", clrWhite, C'60,60,72');
      CreateButton(MKP_PREFIX + "BtnMin", "_", clrWhite, C'60,60,72');
      CreateButton(MKP_PREFIX + "BtnClose", "X", clrWhite, C'120,45,45');
     }

   //+------------------------------------------------------------------+
   //| Sakhtan-e control-haye dakheli-e panel. In-ha, bar khalaf-e title |
   //| bar, ba minimize pak mishan                                        |
   //+------------------------------------------------------------------+
   void CreateContentControls()
     {
      CreateRectLabel(MKP_PREFIX + "Content_BG", C'20,20,20', clrDimGray);
      CreateLabel(MKP_PREFIX + "Content_Hint", "Format: 4321  ya  4334-4336", clrGray, false);

      //--- bala: dokme-ye halat, BUY / SELL, etela'at, CLOSE ALL
      CreateButton(MKP_PREFIX + "Content_BtnModeAuto", "AUTO", clrWhite, C'50,50,62');
      CreateButton(MKP_PREFIX + "Content_BtnModeSemi", "NIM-AUTO", clrWhite, C'50,50,62');
      CreateButton(MKP_PREFIX + "Content_BtnModeManual", "DASTI", clrWhite, C'50,50,62');
      CreateButton(MKP_PREFIX + "Content_BtnBuy", "BUY", clrWhite, C'55,62,56');
      CreateButton(MKP_PREFIX + "Content_BtnSell", "SELL", clrWhite, C'66,56,56');
      CreateLabel(MKP_PREFIX + "Content_Info1", "", clrSilver, false);
      CreateLabel(MKP_PREFIX + "Content_Info2", "", clrSilver, false);
      CreateButton(MKP_PREFIX + "Content_BtnCloseAll", "CLOSE ALL  (bastan-e hame-ye moamele-ha)", clrWhite, C'160,25,25');
      CreateButton(MKP_PREFIX + "Content_BtnClear", "Pak Kon Hame", clrWhite, C'70,50,50');

      for(int side = 0; side < 2; side++)
        {
         color headColor = (side == 0) ? clrLimeGreen : clrTomato;
         string headText = (side == 0) ? "ZONE-E KHARID (Buy)" : "ZONE-E FOROUSH (Sell)";

         CreateLabel(NameHeader(side), headText, headColor, true);
         CreateEdit(NameEdit(side), "");
         CreateButton(NameAdd(side), "+ Ezafe", clrWhite, (side == 0) ? C'35,100,55' : C'130,45,45');

         for(int r = 0; r < m_maxRows; r++)
           {
            CreateLabel(NameRow(side, r), "", clrSilver, false);
            CreateButton(NameRowEdit(side, r), "Vir", clrWhite, C'50,70,110');
            CreateButton(NameRowDel(side, r), "X", clrWhite, C'120,45,45');
           }

         CreateLabel(NameNote(side), "", clrGray, false);
        }

      //--- grip-e taghir-e andaze (goosheh-ye payin-rast): faghat zaher; mouse ro HandleMouseMove rasad mikone
      CreateRectLabel(MKP_PREFIX + "Content_Grip", C'70,70,92', clrGray);
      CreateLabel(MKP_PREFIX + "Content_GripText", "//", clrSilver, true);
     }

   void DestroyContentControls()
     {
      ObjectsDeleteAll(m_chartId, MKP_PREFIX + "Content_");
     }

   //+------------------------------------------------------------------+
   //| Chideman-e kol-e object-ha (mokhtasat + andaze + font) bar asas-e |
   //| m_x/m_yStart va zarib-e fe'li. full = false: faghat mokhtasat     |
   //| (baraye jabejaii - sari'-tar). Hame-ye adad-ha "pixel-e tarrahi"  |
   //| hastan va ba S()/FS() moghyas mishan                               |
   //+------------------------------------------------------------------+
   void LayoutAll(bool full = true)
     {
      m_positionsOnly = !full;

      if(full)
        {
         UpdateScale();
         ClampPosition(m_x, m_yStart);
        }

      //--- navar-e onvan
      Place(MKP_PREFIX + "TitleBar", 0, 0, MKP_BASE_W, MKP_TITLEBAR_H);
      Place(MKP_PREFIX + "TitleText", 8, 4, 0, 0, 8);
      Place(MKP_PREFIX + "BtnReset", MKP_BASE_W - 62, 2, 18, 16, 8);
      Place(MKP_PREFIX + "BtnMin", MKP_BASE_W - 42, 2, 20, 16, 8);
      Place(MKP_PREFIX + "BtnClose", MKP_BASE_W - 20, 2, 18, 16, 8);

      if(!m_minimized)
        {
         int cy    = MKP_TITLEBAR_H;
         int modeW = (MKP_BASE_W - 28) / 3;
         int halfW = (MKP_BASE_W - 26) / 2;

         Place(MKP_PREFIX + "Content_BG", 0, cy, MKP_BASE_W, ContentHeight());

         Place(MKP_PREFIX + "Content_BtnModeAuto", 10, cy + 6, modeW, 22, 8);
         Place(MKP_PREFIX + "Content_BtnModeSemi", 14 + modeW, cy + 6, modeW, 22, 8);
         Place(MKP_PREFIX + "Content_BtnModeManual", 18 + 2 * modeW, cy + 6, modeW, 22, 8);

         Place(MKP_PREFIX + "Content_BtnBuy", 10, cy + 34, halfW, 28, 8);
         Place(MKP_PREFIX + "Content_BtnSell", 16 + halfW, cy + 34, halfW, 28, 8);

         Place(MKP_PREFIX + "Content_Info1", 10, cy + 66, 0, 0, 8);
         Place(MKP_PREFIX + "Content_Info2", 10, cy + 80, 0, 0, 8);

         Place(MKP_PREFIX + "Content_BtnCloseAll", 10, cy + 96, MKP_BASE_W - 20, 24, 8);

         Place(MKP_PREFIX + "Content_Hint", 10, cy + 126, 0, 0, 8);
         Place(MKP_PREFIX + "Content_BtnClear", MKP_BASE_W - 110, cy + 123, 100, 17, 8);

         for(int side = 0; side < 2; side++)
           {
            int top = SectionTop(side);

            Place(NameHeader(side), 10, top, 0, 0, 8);
            Place(NameEdit(side), 10, top + 16, 172, 22, 9);
            Place(NameAdd(side), MKP_BASE_W - 100, top + 16, 90, 22, 8);

            for(int r = 0; r < m_maxRows; r++)
              {
               int y = top + 44 + r * MKP_ROW_H;

               Place(NameRow(side, r), 10, y, 0, 0, 8);
               Place(NameRowEdit(side, r), MKP_BASE_W - 68, y, 34, 15, 8);
               Place(NameRowDel(side, r), MKP_BASE_W - 32, y, 24, 15, 8);
              }

            Place(NameNote(side), 10, top + 44 + m_maxRows * MKP_ROW_H + 1, 0, 0, 8);
           }

         Place(MKP_PREFIX + "Content_Grip", MKP_BASE_W - 16, BaseHeight() - 16, 14, 14);
         Place(MKP_PREFIX + "Content_GripText", MKP_BASE_W - 14, BaseHeight() - 15, 0, 0, 7);
        }

      m_positionsOnly = false;
     }

   //+------------------------------------------------------------------+
   //| Jaygozari-e ye object: dx/dy az goosheh-ye bala-chap-e panel (pixel|
   //| -e tarrahi), dw/dh andaze (0 = taghir nade), font = size-e point   |
   //| (0 = taghir nade). Dar halat-e m_positionsOnly faghat mokhtasat   |
   //+------------------------------------------------------------------+
   void Place(string name, int dx, int dy, int dw = 0, int dh = 0, int font = 0)
     {
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_x + S(dx));
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_yStart + S(dy));

      if(m_positionsOnly)
         return;

      if(dw > 0)
         ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, S(dw));
      if(dh > 0)
         ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, S(dh));
      if(font > 0)
         ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, FS(font));
     }

   //+------------------------------------------------------------------+
   //| Helper-haye sakhtan-e object-haye "anchored" (chasbide be         |
   //| goosheh - pixel-based, na gheimat/zaman-based). Mokhtasat/andaze/ |
   //| font inja set nemishan - LayoutAll set mikone                      |
   //+------------------------------------------------------------------+
   void CreateRectLabel(string name, color bg, color border)
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

   void CreateLabel(string name, string text, color clr, bool bold)
     {
      ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, 8);
      ObjectSetString(m_chartId, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
     }

   void CreateEdit(string name, string defaultText)
     {
      ObjectCreate(m_chartId, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(m_chartId, name, OBJPROP_TEXT, defaultText);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(m_chartId, name, OBJPROP_ALIGN, ALIGN_LEFT);
      ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
     }

   void CreateButton(string name, string text, color textColor, color bg)
     {
      ObjectCreate(m_chartId, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, textColor);
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, bg);
      ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(m_chartId, name, OBJPROP_STATE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
     }
  };
//+------------------------------------------------------------------+
