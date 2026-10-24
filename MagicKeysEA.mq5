//+------------------------------------------------------------------+
//|                                                MagicKeysEA.mq5   |
//|  MagicKeysEA.mq5 - File-e Asli-e Robot - hame-ye module-ha ro be   |
//|  ham vasl mikone va ejrash mikone                                  |
//|                                                                    |
//|  Jarian-e kar:                                                    |
//|  1) Har tick, ZoneManager zone-haye Kharid (InpBuyZoneLevels) va   |
//|     Forush (InpSellZoneLevels) ro rasad mikone. Zone-e Kharid      |
//|     faghat signal-e Buy, zone-e Forush faghat signal-e Sell mide   |
//|  2) Vaghti gheimat vared-e ye zone beshe va candle-ye tayidiye      |
//|     (Doji/Pinbar/Engulfing) shekl begire - be sharte inke afghar-e |
//|     harekat bashe (bala-tarin dar Sell / paiin-tarin dar Buy) va    |
//|     zone hanooz mo'tabar bashe (gheimat kharej va bargashte nabashe)|
//|     - signal sader mishe                                            |
//|  3) RiskManager bar asas-e darsad-e risk az balance, hajm-e kol ro  |
//|     hesab mikone                                                   |
//|  4) TradeManager oon hajm ro nesf karde va do moamele-ye palle-i    |
//|     baz mikone. Age candle-e tayidiye bozorg bashe (bishtar az      |
//|     InpBigCandlePips): SL poshte candle mishe, faghat nesbati az    |
//|     hajm fori baz mishe va baghi vaghti gheimat be vasat-e candle   |
//|     bargasht (candle-e ba'd) baz mishe                               |
//|  5) Har tick, TradeManager.Monitor() vaziat-e do moamele ro         |
//|     modiriat mikone (freeze-e SL ba'd az Target 1, nime-basti +    |
//|     risk-free-e Moamele 2)                                         |
//|  [v1.20] Tanzimat-e pishrafte: tarif-e Pinbar/Doji/Engulfing, SL ba  |
//|     ATR, trailing/breakeven/khorooj-e zamani, filter-haye zaman/     |
//|     session/khabar/nosan/rovand, mohafez-e hesab, Push/Email, log-e  |
//|     CSV, rang-haye panel, OnTester (README ro bebin)                 |
//|  [v1.19] Lams-e zone az rooye range-e candle (na faghat tick),      |
//|     log-e ghazavat-e tayidiye ba adad, hefz-e halat-e panel,        |
//|     log-e vahed-e pip va halat dar shoroe                           |
//|  [v1.18] Tayemar-e candle (mesl-e TradingView) baraye hame-ye       |
//|     timeframe-ha + tag-e kenar-e gheimat (CandleTimer.mqh)           |
//|  [v1.17] Talash-e mojaddad-e signal (InpSignalRetrySeconds)         |
//|     zakhire-ye vaziat-e zone-haye montazer-e tayidiye, faghat       |
//|     yek chart baraye har symbol, Risk-Free-e Moamele 2 az gheimat-e |
//|     vorud-e khodesh                                                  |
//|  [v1.16] Halat-e dasti: do position-e hamjahat = joft-moamele       |
//|     (modiriat-e automatic/nim-automatic) - InpManualAutoPair        |
//|  [v1.15] Log-e vorud: High/Low-e candle-e mabna + formul-e SL       |
//|  [v1.14] Ba'd az target-e Moamele 1, SL-e Moamele 2 = 200 pip az   |
//|     vorud (zarar-e kol sefr) - InpTrade2SlAfterTrade1Pips          |
//|  [v1.13] Chart ba'd az bi-harakati khodkar be akharin candle      |
//|     bar-migarde (OnTimer + CHART_AUTOSCROLL)                       |
//|  [v1.12] Soghf-e risk, hadd-e zarar-e roozane, hadd-e joft-e baz,  |
//|     retry-e Moamele 2, CLOSE ALL faghat-e EA, radif-haye panel,    |
//|     halat-e pishfarz = NIM-AUTO (README ro bebin)                  |
//|  [v1.11] Bug-fix: round-e hajm (ashar), partial-close-e tekrari,    |
//|     Pinbar-e Hammer/Shooting Star, zakhire-ye zone-ha, check-e      |
//|     Hedging, slippage/filling, InpPointsPerPip (README ro bebin)     |
//|  [v1.10] Panel ba DPI/rezolution-e safhe hamahang mishe, ba grip-e |
//|     payin-rast ba mouse bozorg/kochik mishe va hamishe kamel       |
//|     too-ye chart mimoone (jash va andazash hafeze mishe)           |
//|  [v1.09] SL-e hoshmand: SL = InpSplitStopLossPips pip pas az       |
//|     candle-e tayidiye (Buy: zir-e Low, Sell: bala-ye High) - na   |
//|     az noghte-ye vorud. Hajm bar asas-e fasele-ye vaghei-e SL      |
//|  [v1.08] Ba avaz-e timeframe / restart / compile, joft-moamele-    |
//|     haye baz dobare dar peygiri gharar migiran (TradeManager)      |
//|  5b) Se halat-e kar (se dokme-ye bala-ye panel):                  |
//|     AUTO: EA ba tayidiye khodash vared mishe                       |
//|     NIM-AUTO: EA vared nemishe va faghat Alert mide; ba dokme-     |
//|       haye BUY/SELL-e panel vared mishi va EA hajm, SL va TP-ha ro |
//|       mizare (age signal-e hamjahat-e mo'tabar bashe, ghavanin-e   |
//|       candle-e bozorg ham ejra mishe)                               |
//|     DASTI: ba dokme-haye khod-e MetaTrader (hajm-e khodet) vared   |
//|       mishi; EA position-e jadid (magic = 0) ro jazb mikone, SL/TP |
//|       ro age nazashte bashi mizare va khorooj-e marhale-i ham      |
//|       mikone                                                        |
//|  6) Panel.mqh ye panel-e rooye chart mikeshe: do bakhsh-e Kharid/   |
//|     Forush, ezafe/virayesh/pak kardan-e tak-be-tak-e zone-ha,       |
//|     dokme-ye CLOSE ALL, va namayesh-e har zone be soorat-e          |
//|     mostatil-e por-rang rooye chart                                 |
//|                                                                    |
//|  Niazmand-e Hesab-e Hedging (be dalil-e baz shodan-e do position-e |
//|  mostaghel)                                                        |
//+------------------------------------------------------------------+
#property copyright "MagicKeysEA"
#property version   "1.20"
#property strict

#include "Settings.mqh"
#include "RiskManager.mqh"
#include "CandleAnalyzer.mqh"
#include "EntryConfirmation.mqh"
#include "TradeManager.mqh"
#include "ZoneManager.mqh"
#include "Panel.mqh"
#include "CandleTimer.mqh"
#include "Dynamic.mqh"          // [v1.20] ATR / SL pooya
#include "Notifier.mqh"         // [v1.20] Alert/Push/Email + log-e CSV
#include "Filters.mqh"          // [v1.20] filter-haye zaman/khabar/nosan/rovand
#include "AccountGuard.mqh"     // [v1.20] mohafez-e hesab
#include "PositionExtras.mqh"   // [v1.20] trailing / breakeven / khorooj-e zamani

input group "=== General Settings ==="
input ENUM_TIMEFRAMES InpTimeframe  = PERIOD_CURRENT; // Timeframe-i ke candle-ha rooyesh tahlil va tayidiye check mishan
input string           InpBuyZoneLevels  = "";          // Noghat/manategh-e KHARID (faghat signal-e Buy); ba comma joda kon. Mesal: 4321,4334-4336
input string           InpSellZoneLevels = "";          // Noghat/manategh-e FOROUSH (faghat signal-e Sell); ba comma joda kon. Mesal: 4350,4360-4362

//--- namooneh-ye sarasari az har module
CRiskManager       g_riskManager;
CTradeManager      g_tradeManager;
CZoneManager       g_zoneManager;
CCandleTimer       g_candleTimer;         // [v1.18] tayemar-e candle (jadval-e timeframe-ha + tag-e kenar-e gheimat)
CPanel             g_panel;               // panel-e rooye chart baraye ezafe/pak kardan-e zone-ha + namayesh-e vaziat
CTradeFilters      g_filters;             // [v1.20] filter-haye vorud
CAccountGuard      g_guard;               // [v1.20] mohafez-e hesab
CPositionExtras    g_extras;              // [v1.20] trailing / breakeven / khorooj-e zamani

int    g_digits;
double g_pipSize;

//--- signal-e tayid-shode dar halat-e nim-automatic ke montazer-e dokme-ye BUY/SELL-e karbar-e
struct SArmedSignal
  {
   bool              active;
   ENUM_ENTRY_SIGNAL signal;
   string            label;     // esm-e zone
   double            high;      // High-e candle-e tayidiye
   double            low;       // Low-e candle-e tayidiye
   datetime          barTime;   // candle-e jari dar lahze-ye arm shodan
  };

SArmedSignal g_armed;

//--- [v1.17] natije-ye ProcessEntrySignal: DONE = kar tamoom (vorud baz shod ya ba ghanoon-e sabet radd shod),
//--- RETRY = khata-ye mowaghati (ertebat, spread, requote, bazar baste...) va mishe dobare talash kard
enum ENUM_ENTRY_RESULT
  {
   ENTRY_RESULT_DONE,
   ENTRY_RESULT_RETRY
  };

//--- [v1.17] signal-e tayid-shode-i ke vorudesh be dalil-e mowaghati anjam nashode va montazer-e talash-e mojaddad ast (faghat halat-e AUTO)
struct SPendingSignal
  {
   bool              active;
   ENUM_ENTRY_SIGNAL signal;
   string            label;
   double            high;        // High-e candle-e tayidiye
   double            low;         // Low-e candle-e tayidiye
   uint              startTick;   // GetTickCount-e avalin talash
   uint              lastTry;     // GetTickCount-e akharin talash
   int               attempts;    // tedad-e talash-ha ta alan
  };

SPendingSignal g_pending[];

uint g_lastStorageTouch = 0;   // [v1.19] GetTickCount-e akharin bar ke halat/jaye panel dobare zakhire shod
uint         g_lastManualTick = 0;   // baraye jelogiri az double-click rooye BUY/SELL
datetime     g_lastInfoUpdate = 0;   // throttle-e be-rooz resani-e khat-haye etela'at-e panel
uint          g_lastUserActivity = 0;          // [v1.13] akharin harakat-e karbar rooye chart (GetTickCount)
ENUM_EA_MODE g_lastMode       = EAMODE_AUTO;   // akharin halat-e shenakhte-shode (baraye tashkhis-e avaz-e halat)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- [v1.11] EA do position-e mostaghel rooye ye symbol baz mikone; dar hesab-e Netting ba ham edgham mishan
   //--- va mantegh-e Moamele 1/2 kar nemikone - pas be jaye ejra-ye eshtebah, EA ro start nemikonim
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      string msg = "MagicKeysEA: hesab Hedging nist (Netting/Exchange). Baraye in EA hesab-e Hedging lazem ast - EA start nashod.";
      Print(msg);
      Alert(msg);
      return(INIT_FAILED);
     }

   if(InpRiskPercent <= 0.0 || InpRiskPercent > 100.0)
     {
      Print("MagicKeysEA: InpRiskPercent bayad bein-e 0 ta 100 bashe (fe'li: ", DoubleToString(InpRiskPercent, 2), ")");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- [v1.17] faghat yek chart baraye har symbol: zone-ha, halat va joft-haye baz moshtarek-e symbol hastan va
   //--- do EA rooye yek symbol mitoonan ham-zaman yek joft ro modiriat konan (mathalan nime-basti-e dobare)
   if(!ClaimInstance())
     {
      string dupMsg = "MagicKeysEA: rooye " + _Symbol + " ghablan yek chart-e digeh in EA ro dare. Har symbol faghat yek chart mitoone EA dashte bashe - "
                      "EA-ye in chart start nashod (EA ro az chart-e dovom bardar; ya InpAllowSecondInstance = true - pishnahad nemishe).";
      Print(dupMsg);
      Alert(dupMsg);
      return(INIT_FAILED);
     }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      Print("MagicKeysEA: hoshdar - Algo Trading baraye in EA khamooshe (dokme-ye Algo Trading ya tick-e 'Allow Algo Trading' dar tab-e Common) - EA moamele baz nemikone.");

   g_riskManager.Init(_Symbol);
   g_tradeManager.Init(_Symbol);
   g_zoneManager.Init(_Symbol, InpTimeframe);

   //--- [v1.20] ATR, filter-ha, mohafez-e hesab va modiriat-e ezafe
   MKDynamicInit(_Symbol, InpTimeframe);
   g_filters.Init(_Symbol);
   g_guard.Init(_Symbol);
   g_extras.Init(_Symbol);

   g_armed.active   = false;
   g_lastManualTick = 0;
   g_lastInfoUpdate = 0;
   ArrayResize(g_pending, 0);   // [v1.17]

   g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_pipSize = MKPipSize(_Symbol);

   //--- [v1.11] zone-haye zakhire-shode (ezafe/virayesh-shode ba panel) ba restart / avaz-e timeframe bargozari mishan;
   //--- vorudi-haye InpBuy/SellZoneLevels faghat vaghti file-e zakhire nist (ya InpResetZonesFromInputs = true) khoonde mishan
   bool zonesFromFile = (!InpResetZonesFromInputs && g_zoneManager.LoadZones());

   if(!zonesFromFile)
     {
      ParseAndLoadZones(InpBuyZoneLevels, ZONE_BUY);
      ParseAndLoadZones(InpSellZoneLevels, ZONE_SELL);

      if(g_zoneManager.Count() > 0)
         g_zoneManager.SaveZones();
     }
   else if(StringLen(InpBuyZoneLevels) + StringLen(InpSellZoneLevels) > 0)
      Print("MagicKeysEA: zone-ha az file-e zakhire bargozari shodan; InpBuyZoneLevels/InpSellZoneLevels nadide gerefte shod (baraye khoondan az vorudi InpResetZonesFromInputs ro true kon).");

   Print("MagicKeysEA: rah-andazi shod | Symbol: ", _Symbol,
         " | Timeframe: ", EnumToString(InpTimeframe),
         " | Tedad-e zone-haye bargozari-shode: ", g_zoneManager.Count());

   //--- [v1.19] vahed-e pip: hame-ye tolerance-ha, SL va hadd-e candle-e bozorg ba hamin vahed hesab mishan (baraye tala/index InpPointsPerPip ro check kon)
   Print("MagicKeysEA: 1 pip = ", DoubleToString(g_pipSize, g_digits), " (vahed-e gheimat) | tolerance-e zone-e tak-adadi = +-",
         DoubleToString(InpZoneTolerancePips * g_pipSize, g_digits), " | tolerance-e extreme = ",
         DoubleToString(InpConfirmExtremeTolerancePips * g_pipSize, g_digits), " | SL = ",
         DoubleToString(MKSlBufferPips() * g_pipSize, g_digits), " | candle-e bozorg > ",
         DoubleToString(MKBigCandlePips() * g_pipSize, g_digits));

   //--- panel-e rooye chart: baraye ezafe/pak kardan-e zone bedoone niaz
   //--- be baz kardan-e Properties/Inputs, va namayesh-e vaziat-e har zone
   g_panel.SetZoneManager(GetPointer(g_zoneManager));
   g_panel.SetTradeManager(GetPointer(g_tradeManager));
   g_panel.Create(_Symbol);

   //--- halat az GlobalVariable bargozari shode; restart/avaz-e timeframe "avaz-e halat" hesab nemishe
   g_lastMode = g_panel.GetMode();

   //--- [v1.19] halat-e feli dar log (ghablan age zakhire-ye halat az bein mirafte, bedoone khabar NIM-AUTOMATIC mishod
   //--- va EA ba tayidiye faghat hoshdar midad va vared nemishod)
   if(g_lastMode == EAMODE_AUTO)
      Print("MagicKeysEA: halat = AUTOMATIC (EA ba tayidiye khodash vared mishe).");
   else
      Print("MagicKeysEA: hoshdar - halat = ", ModeName(g_lastMode), (g_panel.ModeWasRestored() ? "" : " (zakhire-ye halat peida nashod, halat-e pishfarz)"),
            ": EA ba tayidiye vared-e moamele nemishe; baraye vorud-e khodkar dokme-ye AUTO-ye panel ro bezan.");

   //--- [v1.18] tayemar-e candle (mesl-e TradingView): jadval-e timeframe-ha + tag-e kenar-e gheimat
   g_candleTimer.Init(0);

   //--- [v1.13] timer baraye bargardandan-e chart be akharin candle va [v1.18] tayemar-e candle (dar Tester ghair-faal)
   g_lastUserActivity = GetTickCount();
   if((InpChartAutoFollow || InpTimerEnable) && MQLInfoInteger(MQL_TESTER) == 0)
      EventSetTimer(1);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_candleTimer.Destroy();   // [v1.18]
   g_filters.Deinit();        // [v1.20]
   MKDynamicDeinit();         // [v1.20]

   //--- [v1.17] age start nashod (masalan chart-e dovom-e hamin symbol), panel ham sakhte nashode
   if(reason != REASON_INITFAILED)
      g_panel.Destroy();

   //--- ba bardashtan-e EA ya bastan-e chart, mohafez-e "yek EA rooye har symbol" azad mishe
   if(reason == REASON_REMOVE || reason == REASON_CHARTCLOSE)
      ReleaseInstance();

   Print("MagicKeysEA: motevaghef shod. Dalil: ", reason);
  }

//+------------------------------------------------------------------+
//| Chart event function - click-e dokme-ha va vorud-e edit box-e     |
//| panel ro be Panel.mqh forward mikone                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   //--- [v1.13] harakat-e karbar (mouse / click / keyboard) - zaman-e bi-harakati ro reset mikone.
   //--- CHARTEVENT_CHART_CHANGE ro ghasdan hesab nemikonim chon scroll-e khodkar-e chart ham un ro tolid mikone
   if(id == CHARTEVENT_MOUSE_MOVE || id == CHARTEVENT_CLICK || id == CHARTEVENT_OBJECT_CLICK || id == CHARTEVENT_KEYDOWN)
      g_lastUserActivity = GetTickCount();

   //--- [v1.18] ba taghir-e andaze/mahdoode-ye chart (zoom, scroll, resize) jaye jadval va tag-e tayemar dobare hesab mishe
   if(id == CHARTEVENT_CHART_CHANGE)
      g_candleTimer.Layout();

   g_panel.HandleEvent(id, lparam, dparam, sparam);

   //--- agar ba click-e dokme-haye bala-ye panel halat avaz shode bashe
   SyncMode();

   //--- vorud-e dasti (halat-e nim-automatic): darkhast-e dokme-ye BUY/SELL-e panel
   int request = g_panel.PopManualRequest();
   if(request != 0)
      ExecuteManualEntry(request > 0 ? ENTRY_BUY : ENTRY_SELL);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| [v1.13] Har 1 sanie: age karbar InpChartFollowIdleSec sanie harakati |
//| nadashte bashe, Auto Scroll ro roshan mikone va age akharin candle   |
//| az safhe kharej shode bashe chart ro be akharin candle mibare        |
//+------------------------------------------------------------------+
void OnTimer()
  {
   //--- [v1.18] tayemar-e candle har sanie roz-resani mishe
   g_candleTimer.Update();
   KeepStorageAlive();   // [v1.19]

   if(!InpChartAutoFollow)
      return;

   uint idleMs = (uint)MathMax(5, InpChartFollowIdleSec) * 1000;
   if(GetTickCount() - g_lastUserActivity < idleMs)
      return;

   if(ChartGetInteger(0, CHART_AUTOSCROLL) == 0)
      ChartSetInteger(0, CHART_AUTOSCROLL, true);

   //--- shift-e rast-tarin candle-e dide-shode; 0 = candle-e jari. > 0 yani candle-haye jadid kharej az safhe-and
   long firstVisible = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
   long visibleBars  = ChartGetInteger(0, CHART_VISIBLE_BARS);
   long rightmost    = firstVisible - visibleBars + 1;

   if(rightmost > 0)
      ChartNavigate(0, CHART_END, 0);
  }

void OnTick()
  {
   SyncMode();

   //--- [v1.20] mohafez-e hesab: ghole-ye equity va afat (age lazem bashe hame-ye moamele-ha baste mishan)
   bool ddCloseAll = false;
   g_guard.OnTick(ddCloseAll);
   if(ddCloseAll)
     {
      int closedByGuard = g_tradeManager.CloseAllPositions();
      MKNotify(NOTIFY_GUARD, "afat-e equity az hadd gozasht - " + IntegerToString(closedByGuard) + " position baste shod va vorud-e jadid motevaghef ast.");
     }

   //--- [v1.18] tag-e tayemar-e kenar-e gheimat ba gheimat harekat mikone
   g_candleTimer.UpdateTag();

   //--- [v1.19] halat/jaye panel dar GlobalVariable (hadeaksar yek bar dar saat) zendeh negah dashte mishe
   KeepStorageAlive();

   //--- 1) rasad-e noghat/manategh-e vorud
   g_zoneManager.CheckZones();

   //--- 2) process-e hame-ye signal-haye tayid-shode-i ke hanooz masraf nashodan
   ENUM_ENTRY_SIGNAL signal;
   int    zoneIndex;
   string zoneLabel;
   double candleHigh, candleLow;

   while(g_zoneManager.GetNextTriggeredSignal(signal, zoneIndex, zoneLabel, candleHigh, candleLow))
     {
      if(signal == ENTRY_NONE)
         continue;

      //--- [v1.19] ba'd az tayidiye mashkhas bashe EA dar che halati bood (AUTO = vared mishe, baghie = faghat hoshdar)
      Print("MagicKeysEA: tayidiye az zone [", zoneLabel, "] (", (signal == ENTRY_BUY ? "Kharid" : "Forush"),
            ") dar halat-e ", ModeName(g_panel.GetMode()), " dariaft shod.");

      //--- halat-e nim-automatic va dasti: EA vared nemishe, faghat signal ro "arm" mikone va hoshdar mide
      if(g_panel.GetMode() == EAMODE_AUTO)
        {
         //--- [v1.17] khata-ye mowaghati (spread, ertebat, requote...): signal soukhte nemishe, mishe dobare talash kard
         if(ProcessEntrySignal(signal, zoneLabel, candleHigh, candleLow, true) == ENTRY_RESULT_RETRY)
            QueueSignalRetry(signal, zoneLabel, candleHigh, candleLow);
        }
      else
         ArmSemiAutoSignal(signal, zoneLabel, candleHigh, candleLow);
     }

   //--- [v1.17] signal-haye montazer-e talash-e mojaddad (hadeaksar yek talash dar sanie baraye har signal)
   ProcessPendingSignals();

   //--- halat-e dasti: position-haye jadid-e dasti ro jazb kon (SL/TP bezar)
   if(g_panel.GetMode() == EAMODE_MANUAL)
      AdoptManualEntries();

   //--- 3) modiriat-e moamele-haye baz (freeze-e SL ba'd az Target 1, nime-basti va risk-free-e Moamele 2)
   g_tradeManager.Monitor();

   //--- [v1.20] trailing / breakeven-e mostaghel / khorooj-e zamani / bastan-e jom'e
   bool includeManualExtras = (g_panel.GetMode() == EAMODE_MANUAL && InpExtrasIncludeManual);
   g_extras.Manage(includeManualExtras);
   if(g_extras.FridayClose(includeManualExtras) > 0)
      g_tradeManager.ClearAddOns();

   //--- 4) be-rooz kardan-e panel (khodesh dakheli throttle dare, har tick vaghean redraw nemikone)
   UpdatePanelInfo();
   g_panel.Refresh();
  }

//+------------------------------------------------------------------+
//| Trade transaction: dar halat-e Dasti, vaghti ye deal ezafe shod    |
//| (position-e jadid) fori jazbesh mikonim ta SL/TP bi-ta'khir        |
//| gozashte beshe (har tick ham be onvan-e poshtiban check mishe)     |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   bool manualMode = (g_panel.GetMode() == EAMODE_MANUAL);

   //--- [v1.20] log-e CSV va notification-e baz/baste shodan-e moamele
   MKHandleDeal(trans.deal, manualMode);

   if(manualMode)
      AdoptManualEntries();
  }

//+------------------------------------------------------------------+
//| Tashkhis-e avaz-e halat (ba dokme-haye bala-ye panel). Vaghti     |
//| halat-e Dasti roshan mishe, zaman-e hamin lahze be TradeManager    |
//| dade mishe: faghat position-haye dasti-ye ba'd az in zaman jazb    |
//| mishan (position-haye ghadimi dast nakhorde mimoonan)              |
//+------------------------------------------------------------------+
void SyncMode()
  {
   ENUM_EA_MODE mode = g_panel.GetMode();
   if(mode == g_lastMode)
      return;

   g_lastMode = mode;

   if(mode == EAMODE_MANUAL)
      g_tradeManager.SetManualSince(TimeTradeServer());
  }

//+------------------------------------------------------------------+
//| Halat-e Dasti: position-haye jadid-e dasti ro jazb mikone (SL/TP  |
//| mizare, khorooj-e marhale-i ro shoroe mikone). SL-e hoshmand:      |
//| InpSplitStopLossPips pas az candle-e marja' - candle-e tayidiye-ye |
//| signal-e armed-e hamjahat (age mo'tabar bashe) vagarna akharin     |
//| candle-e baste-shode. Vorud-e marhale-i dar in halat nist, chon    |
//| hajm ba khod-e karbare                                              |
//+------------------------------------------------------------------+
void AdoptManualEntries()
  {
   double high = 0.0;
   double low  = 0.0;
   bool   fromSignalBuy  = false;
   bool   fromSignalSell = false;

   double buySL  = 0.0;
   double sellSL = 0.0;

   if(GetStopReferenceCandle(POSITION_TYPE_BUY, high, low, fromSignalBuy))
      buySL = SmartStopPrice(POSITION_TYPE_BUY, high, low);

   if(GetStopReferenceCandle(POSITION_TYPE_SELL, high, low, fromSignalSell))
      sellSL = SmartStopPrice(POSITION_TYPE_SELL, high, low);

   //--- [v1.20] SL-e candle-e vorud (InpUseEntryCandleStop): age InpEntryCandleStopOnlyNoSignal roshan bashe faghat bedoon-e signal
   bool buyEntryRule  = InpUseEntryCandleStop && !(InpEntryCandleStopOnlyNoSignal && fromSignalBuy);
   bool sellEntryRule = InpUseEntryCandleStop && !(InpEntryCandleStopOnlyNoSignal && fromSignalSell);

   bool armedValid = IsArmedSignalValid();
   int  mask       = g_tradeManager.AdoptManualPositions(buySL, sellSL, buyEntryRule, sellEntryRule);

   //--- signal-e armed masraf shod (position-i hamjahat ba oon jazb shod)
   if(armedValid && mask != 0)
     {
      int armedBit = (g_armed.signal == ENTRY_BUY) ? 1 : 2;
      if((mask & armedBit) != 0)
         g_armed.active = false;
     }
  }

//+------------------------------------------------------------------+
//| SL-e hoshmand: InpSplitStopLossPips pip pas az candle-e marja'     |
//| (Buy: paiin-tar az Low-e candle, Sell: bala-tar az High-e candle)  |
//+------------------------------------------------------------------+
double SmartStopPrice(ENUM_POSITION_TYPE direction, double candleHigh, double candleLow)
  {
   double distance = MKSlBufferPips() * g_pipSize;
   double price    = (direction == POSITION_TYPE_BUY) ? (candleLow - distance) : (candleHigh + distance);

   return NormalizeDouble(price, g_digits);
  }

//+------------------------------------------------------------------+
//| Candle-e marja' baraye SL-e hoshmand:                              |
//|  - age signal-e armed-e mo'tabar-e hamjahat vojood dare: candle-e  |
//|    tayidiye-ye oon (fromSignal = true)                              |
//|  - vagarna akharin candle-e baste-shode (shift 1)                  |
//+------------------------------------------------------------------+
bool GetStopReferenceCandle(ENUM_POSITION_TYPE direction, double &high, double &low, bool &fromSignal)
  {
   fromSignal = false;
   high       = 0.0;
   low        = 0.0;

   if(IsArmedSignalValid())
     {
      ENUM_POSITION_TYPE armedDir = (g_armed.signal == ENTRY_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

      if(armedDir == direction && g_armed.high > g_armed.low)
        {
         high       = g_armed.high;
         low        = g_armed.low;
         fromSignal = true;
         return true;
        }
     }

   high = iHigh(_Symbol, InpTimeframe, 1);
   low  = iLow(_Symbol, InpTimeframe, 1);

   return (high > 0.0 && low > 0.0 && high >= low);
  }

//+------------------------------------------------------------------+
//| Barname-ye ye vorud: SL-e hoshmand (slPrice; 0 = ghabel-e estefade |
//| nist va SL-e sabet az noghte-ye vorud estefade mishe), hajm-e      |
//| risk-mabna (lot) va fasele-ye vaghei-e SL (slPips).                |
//| Hajm bar asas-e fasele-ye vaghei-e gheimat-e vorud ta SL hesab     |
//| mishe, pas ba SL khordan, zarar hamoon InpRiskPercent mimoone      |
//| (candle-e bozorg-tar = SL-e door-tar = hajm-e kamtar)               |
//+------------------------------------------------------------------+
void PlanEntry(ENUM_POSITION_TYPE direction, double candleHigh, double candleLow,
               double &slPrice, double &lot, double &slPips, bool verbose = true)
  {
   double entryRef = (direction == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                       : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minDist  = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   slPrice = 0.0;

   if(candleHigh > candleLow && candleLow > 0.0)
     {
      double smart = SmartStopPrice(direction, candleHigh, candleLow);
      double gap   = (direction == POSITION_TYPE_BUY) ? (entryRef - smart) : (smart - entryRef);

      if(gap > 0.0 && gap > minDist)
         slPrice = smart;
     }

   //--- [v1.20] nim-automatic / dasti: SL-e candle-e vorud (age candle-e ghabli ghabl az gheimat-e vorud bood)
   if(InpUseEntryCandleStop && g_panel.GetMode() != EAMODE_AUTO)
     {
      double refHigh, refLow;
      bool   fromSig = false;
      GetStopReferenceCandle(direction, refHigh, refLow, fromSig);

      if(!(InpEntryCandleStopOnlyNoSignal && fromSig))
        {
         double ruleSL = MKEntryCandleStop(_Symbol, direction, entryRef, TimeCurrent());
         if(ruleSL > 0.0)
           {
            double ruleGap = (direction == POSITION_TYPE_BUY) ? (entryRef - ruleSL) : (ruleSL - entryRef);
            if(ruleGap > 0.0 && ruleGap > minDist)
              {
               slPrice = ruleSL;
               if(verbose)
                  Print("MagicKeysEA: SL-e candle-e vorud estefade shod (candle-e ghabli ghabl az gheimat-e vorud ast) | SL=",
                        DoubleToString(ruleSL, g_digits));
              }
           }
        }
     }

   int stopPoints;
   if(slPrice > 0.0)
     {
      stopPoints = (int)MathMax(1.0, MathRound(MathAbs(entryRef - slPrice) / _Point));
      slPips     = (g_pipSize > 0.0) ? MathAbs(entryRef - slPrice) / g_pipSize : 0.0;
     }
   else
     {
      slPips     = MKSlBufferPips();
      stopPoints = PipsToPoints((int)MathRound(slPips));
     }

   lot = g_riskManager.CalculateLotSize(stopPoints, verbose);
  }

//+------------------------------------------------------------------+
//| Pish-namayesh-e yek jahat baraye panel: "BUY 0.04 (SL 412p)"       |
//+------------------------------------------------------------------+
string PreviewEntry(ENUM_POSITION_TYPE direction)
  {
   double high = 0.0;
   double low  = 0.0;
   bool   fromSignal = false;

   if(!GetStopReferenceCandle(direction, high, low, fromSignal))
     {
      high = 0.0;
      low  = 0.0;
     }

   double slPrice, lot, slPips;
   PlanEntry(direction, high, low, slPrice, lot, slPips, false);

   return (direction == POSITION_TYPE_BUY ? "BUY " : "SELL ") + DoubleToString(lot, 2) +
          " (SL " + DoubleToString(slPips, 0) + "p)";
  }

//+------------------------------------------------------------------+
//| Aya signal-e armed (halat-e nim-automatic va dasti) hanooz        |
//| mo'tabare?                                                         |
//| Mo'tabar ta InpSemiAutoSignalValidCandles candle ba'd az candle-i |
//| ke signal dar oon arm shode                                        |
//+------------------------------------------------------------------+
bool IsArmedSignalValid()
  {
   if(!g_armed.active)
      return false;

   int sec = PeriodSeconds(InpTimeframe);
   if(sec <= 0)
      sec = 60;

   datetime curBar = iTime(_Symbol, InpTimeframe, 0);
   if(curBar == 0)
      curBar = TimeCurrent();

   long maxAge = (long)sec * (long)MathMax(1, InpSemiAutoSignalValidCandles);
   return (((long)curBar - (long)g_armed.barTime) < maxAge);
  }

//+------------------------------------------------------------------+
//| Halat-e nim-automatic: tayidiye peida shod - EA vared nemishe,    |
//| signal ro zakhire mikone (ta dokme-ye BUY/SELL az context-e       |
//| candle-e tayidiye estefade kone) va Alert mide                     |
//+------------------------------------------------------------------+
void ArmSemiAutoSignal(ENUM_ENTRY_SIGNAL signal, string zoneLabel, double candleHigh, double candleLow)
  {
   g_armed.active  = true;
   g_armed.signal  = signal;
   g_armed.label   = zoneLabel;
   g_armed.high    = candleHigh;
   g_armed.low     = candleLow;
   g_armed.barTime = iTime(_Symbol, InpTimeframe, 0);
   if(g_armed.barTime == 0)
      g_armed.barTime = TimeCurrent();

   double rangePips = (g_pipSize > 0.0) ? (candleHigh - candleLow) / g_pipSize : 0.0;
   double bigLimit  = MKBigCandlePips();
   bool   big       = (bigLimit > 0.0 && rangePips > bigLimit);
   string dirName   = (signal == ENTRY_BUY) ? "KHARID (BUY)" : "FOROUSH (SELL)";
   string btnName   = (signal == ENTRY_BUY) ? "BUY" : "SELL";
   bool   manualMode = (g_panel.GetMode() == EAMODE_MANUAL);

   string tag    = manualMode ? "DASTI" : "NIM-AUTOMATIC";
   string action = manualMode ? ("ba dokme-ye " + btnName + "-e MetaTrader vared sho (EA SL/TP ro mizare)")
                              : ("dokme-ye " + btnName + " ro bezan");

   string msg = "MagicKeysEA [" + tag + "]: tayidiye " + dirName + " az zone [" + zoneLabel + "] | range-e candle: " +
                DoubleToString(rangePips, 1) + " pip" + (big ? " (BOZORG)" : "") +
                " | " + action + " (ta " + IntegerToString(MathMax(1, InpSemiAutoSignalValidCandles)) +
                " candle mo'tabare)";

   Print(msg);
   if(InpSemiAutoAlert)
      MKNotify(NOTIFY_SIGNAL, msg);
  }

//+------------------------------------------------------------------+
//| Vorud-e dasti (dokme-ye BUY/SELL-e panel, faghat halat-e nim-     |
//| automatic). EA hajm, SL va TP-ha ro khodesh mizare:                |
//|  - age signal-e armed-e mo'tabar-e hamjahat vojood dashte bashe:   |
//|    ProcessEntrySignal ba hamoon context (candle-e tayidiye) ejra   |
//|    mishe, yani ghavanin-e candle-e bozorg ham eAmal mishe          |
//|  - vagarna: SL-e hoshmand pas az akharin candle-e baste-shode       |
//|    (candle-e tayidiye nist, pas vorud-e marhale-i anjam nemishe)    |
//| Modiriat-e baad az vorud (freeze-e SL, nime-basti, risk-free,      |
//| vorud-e marhale-i) mesl-e halat-e automatic tavassot-e             |
//| TradeManager.Monitor() anjam mishe                                  |
//+------------------------------------------------------------------+
void ExecuteManualEntry(ENUM_ENTRY_SIGNAL signal)
  {
   if(g_panel.GetMode() != EAMODE_SEMI)
      return;

   //--- mohafez dar barabar-e double-click: dar fasele-ye kamtar az 2 sanie dobare vared nemishe
   uint now = GetTickCount();
   if(g_lastManualTick != 0 && (now - g_lastManualTick) < 2000)
     {
      Print("MagicKeysEA: dokme-ye vorud-e dasti dar fasele-ye kamtar az 2 sanie dobare zade shod - radd shod.");
      return;
     }
   g_lastManualTick = now;

   string dirName = (signal == ENTRY_BUY) ? "BUY" : "SELL";

   if(g_armed.active && !IsArmedSignalValid())
     {
      Print("MagicKeysEA: signal-e armed-e zone [", g_armed.label, "] montaghi shode bood va pak shod.");
      g_armed.active = false;
     }

   if(g_armed.active && g_armed.signal == signal)
     {
      string label = g_armed.label;
      double high  = g_armed.high;
      double low   = g_armed.low;
      g_armed.active = false;

      Print("MagicKeysEA: vorud-e dasti ", dirName, " ba context-e signal-e zone [", label, "]");
      if(ProcessEntrySignal(signal, label, high, low, true) == ENTRY_RESULT_RETRY)
        {
         //--- [v1.17] khata-ye mowaghati: signal hanooz mo'tabare, karbar mitoone dobare dokme ro bezane
         g_armed.active   = true;
         g_lastManualTick = 0;
         Print("MagicKeysEA: vorud anjam nashod (khata-ye mowaghati) - signal-e zone [", label, "] hanooz mo'tabare, dobare dokme ro bezan.");
        }
      return;
     }

   if(g_armed.active)
      Print("MagicKeysEA: signal-e armed jahat-e mokhalef-e ", dirName, " dare - nadide gerefte shod.");

   //--- bedoone signal: akharin candle-e baste-shode marja'-e SL-e hoshmand mishe (vorud-e marhale-i nadarim)
   ENUM_POSITION_TYPE direction = (signal == ENTRY_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   double refHigh = 0.0;
   double refLow  = 0.0;
   bool   fromSignal = false;

   if(!GetStopReferenceCandle(direction, refHigh, refLow, fromSignal))
     {
      refHigh = 0.0;
      refLow  = 0.0;
     }

   Print("MagicKeysEA: vorud-e dasti ", dirName, " bedoone signal-e hamjahat - SL pas az akharin candle-e baste-shode.");
   ProcessEntrySignal(signal, "Manual", refHigh, refLow, false);
  }

//+------------------------------------------------------------------+
//| Do khat-e etela'at-e panel (hadeaksar yek bar dar sanie):          |
//|  1) hajm-e mohasebe-shode (be hamrah-e do nime), SL va TP-ha       |
//|  2) vaziat-e halat/signal                                           |
//| (hajm-e namayesh-dade-shode hamoon hajm-i ast ke dokme-ye BUY/SELL |
//| ya vorud-e automatic baz mikone - na hajm-e dokme-ye khod-e        |
//| MetaTrader)                                                         |
//+------------------------------------------------------------------+
void UpdatePanelInfo()
  {
   datetime now = TimeCurrent();
   if(now == g_lastInfoUpdate)
      return;
   g_lastInfoUpdate = now;

   ENUM_EA_MODE mode = g_panel.GetMode();

   string line1;
   if(mode == EAMODE_MANUAL)
     {
      //--- dar halat-e Dasti hajm ba karbare; EA faghat SL/TP mizare
      line1 = "SL: " + DoubleToString(MKSlBufferPips(), 0) + " pip pas az candle | TP " +
              DoubleToString(InpTrade2TakeProfitPips, 0) + " pip" + (InpManualStagedExit ? " | marhale-i" : "");
     }
   else
     {
      //--- hajm va fasele-ye SL baraye har do jahat (bar asas-e candle-e signal-e faal ya akharin candle)
      line1 = PreviewEntry(POSITION_TYPE_BUY) + " | " + PreviewEntry(POSITION_TYPE_SELL);
     }

   string line2;
   if(mode == EAMODE_AUTO)
      line2 = (ArraySize(g_pending) > 0)
              ? ("Automatic: " + IntegerToString(ArraySize(g_pending)) + " signal dar hal-e talash-e mojaddad")
              : "Automatic: EA ba tayidiye khodash vared mishe";
   else if(IsArmedSignalValid())
      line2 = "Signal: " + (g_armed.signal == ENTRY_BUY ? "BUY" : "SELL") + " [" + g_armed.label + "] - " +
              (mode == EAMODE_MANUAL ? "ba MetaTrader vared sho" : "montazer-e dokme-ye to");
   else if(mode == EAMODE_MANUAL)
     {
      int tracked = g_tradeManager.ManualTrackedCount();
      line2 = (tracked > 0) ? ("Dasti: " + IntegerToString(tracked) + " position dar peygiri")
                            : "Dasti: montazer-e vorud-e to";
     }
   else
      line2 = "Nim-automatic: signal-e faal nadarim";

   //--- [v1.20] age filter ya mohafez-e hesab vorud-e jadid ro mamnoo karde, dalilesh dar khat-e 2 neshoon dade mishe
   string blockReason;
   if(!g_guard.Allow(blockReason))
      line2 = "[BLOK] " + StringSubstr(blockReason, 0, 55);
   else if(!g_filters.GeneralAllowed(blockReason))
      line2 = "[FILTER] " + StringSubstr(blockReason, 0, 52);

   g_panel.SetInfo(line1, line2);
  }

//+------------------------------------------------------------------+
//| Process kardan-e ye signal-e tayid-shode (ya vorud-e dasti-ye     |
//| nim-automatic).                                                     |
//|                                                                    |
//| SL-e hoshmand: SL = InpSplitStopLossPips pip pas az candle-e       |
//| tayidiye (Buy: paiin-tar az Low-e candle, Sell: bala-tar az High-e |
//| candle) - na fasele-ye sabet az noghte-ye vorud. Hajm bar asas-e   |
//| fasele-ye vaghei-e vorud ta SL hesab mishe, pas risk-e SL hamishe  |
//| hamoon InpRiskPercent mimoone (candle-e bozorg-tar = hajm-e kamtar)|
//|  - confirmed = true (candle-e tayidiye-ye vaghei): age range-e     |
//|    candle bishtar az InpBigCandlePips bashe, vorud marhale-i anjam |
//|    mishe: faghat InpBigCandleFirstEntryPercent-e hajm fori baz     |
//|    mishe va baghie ba hamoon SL vaghti gheimat dar candle(-haye)   |
//|    ba'd be sath-e bargasht (pishfarz vasat-e candle) resid baz     |
//|    mishe - vorud az gheimat-e behtar, pas zarar-e ehtemali kamtar  |
//|  - confirmed = false (vorud-e dasti bedoone signal): candle faghat |
//|    marja'-e SL-e; vorud-e marhale-i anjam nemishe                  |
//|  - age candle-i dar dastres nabashe: SL-e sabet az noghte-ye vorud  |
//+------------------------------------------------------------------+
//--- [v1.17] bar migardoone: ENTRY_RESULT_RETRY = vorud be dalil-e mowaghati anjam nashod (mishe dobare talash kard),
//--- ENTRY_RESULT_DONE = kar tamoom (vorud baz shod, ya ba ghanoon-e sabet mesl-e hadd-e zarar-e roozane radd shod)
ENUM_ENTRY_RESULT ProcessEntrySignal(ENUM_ENTRY_SIGNAL signal, string zoneLabel, double candleHigh, double candleLow, bool confirmed)
  {
   ENUM_POSITION_TYPE direction = (signal == ENTRY_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

   //--- [v1.17] mawane-e mowaghati: ertebat ba server ghate, Algo Trading khamooshe, ya symbol dar in jahat moamele nemishe
   if(!TerminalInfoInteger(TERMINAL_CONNECTED) || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
      !MQLInfoInteger(MQL_TRADE_ALLOWED) || !SymbolAllowsDirection(direction))
     {
      Print("MagicKeysEA: vorud az zone [", zoneLabel, "] anjam nashod - ertebat ba server ghat ast, ya Algo Trading khamooshe, ",
            "ya symbol dar in jahat moamele nemishe.");
      return ENTRY_RESULT_RETRY;
     }

   //--- [v1.11] filtr-e spread: age spread az hadd-e mojaz bishtar bood vorud radd mishe
   if(InpMaxSpreadPoints > 0)
     {
      long spreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(spreadPoints > InpMaxSpreadPoints)
        {
         Print("MagicKeysEA: vorud az zone [", zoneLabel, "] radd shod - spread (", spreadPoints,
               " point) bishtar az InpMaxSpreadPoints (", InpMaxSpreadPoints, ") ast.");
         return ENTRY_RESULT_RETRY;   // [v1.17] spread mowaghati-e: mishe dobare talash kard
        }
     }

   //--- [v1.12] hadd-e joft-moamele-ye baz
   if(InpMaxOpenPairs > 0 && g_tradeManager.OpenPairCount() >= InpMaxOpenPairs)
     {
      Print("MagicKeysEA: vorud az zone [", zoneLabel, "] radd shod - tedad-e joft-moamele-ye baz (",
            g_tradeManager.OpenPairCount(), ") be InpMaxOpenPairs (", InpMaxOpenPairs, ") resideh.");
      return ENTRY_RESULT_DONE;
     }

   //--- [v1.12] hadd-e zarar-e roozane
   if(InpMaxDailyLossPercent > 0.0)
     {
      double lossPct = TodayLossPercent();
      if(lossPct >= InpMaxDailyLossPercent)
        {
         string lossMsg = "MagicKeysEA: vorud az zone [" + zoneLabel + "] radd shod - zarar-e emrooz " +
                          DoubleToString(lossPct, 2) + "% (hadd: " + DoubleToString(InpMaxDailyLossPercent, 2) + "%)";
         Print(lossMsg);
         MKNotify(NOTIFY_GUARD, lossMsg);
         return ENTRY_RESULT_DONE;
        }
     }

   //--- [v1.20] mohafez-e hesab (zarar-e hafteghi, zarar-e motevali, tedad-e vorud, fasele-ye zamani, afat-e equity, Margin Level)
   string guardReason;
   if(!g_guard.Allow(guardReason))
     {
      string guardMsg = "MagicKeysEA: vorud az zone [" + zoneLabel + "] radd shod - mohafez-e hesab: " + guardReason;
      Print(guardMsg);
      MKNotify(NOTIFY_GUARD, guardMsg);
      return ENTRY_RESULT_DONE;
     }

   double slPrice, lot, slPips;
   PlanEntry(direction, candleHigh, candleLow, slPrice, lot, slPips);

   //--- [v1.20] filter-haye zaman / session / khabar / nosan / rovand / spread-e nesbi
   string filterReason;
   ENUM_FILTER_RESULT filterResult = g_filters.Check(direction, slPips, filterReason);
   if(filterResult != FILTER_PASS)
     {
      bool enforceFilters = (g_panel.GetMode() == EAMODE_AUTO || InpFiltersApplyToSemiAuto);

      if(!enforceFilters)
        {
         if(InpLogFilterRejects)
            Print("MagicKeysEA: hoshdar - filter [", filterReason, "] faal ast (dar halat-e dasti/nim-automatic faghat hoshdar, vorud edame peida mikone).");
        }
      else
        {
         string filterMsg = "MagicKeysEA: vorud az zone [" + zoneLabel + "] radd shod - filter: " + filterReason;
         if(InpLogFilterRejects)
            Print(filterMsg);

         if(filterResult == FILTER_RETRY)
            return ENTRY_RESULT_RETRY;

         MKNotify(NOTIFY_GUARD, filterMsg);
         return ENTRY_RESULT_DONE;
        }
     }

   //--- [v1.12] soghf-e risk-e vaghei: age hajm be dalil-e hadeaghal-lot-e broker bala round shode va risk bishtar az hadd-e mojaz shode, vared nemishim
   if(InpMaxRiskMultiplier > 0.0)
     {
      double halfLot  = g_riskManager.NormalizeVolume(lot / 2.0);
      double realRisk = g_riskManager.RiskPercentForLot(halfLot * 2.0);
      double allowed  = InpRiskPercent * InpMaxRiskMultiplier;

      if(realRisk > allowed)
        {
         string riskMsg = "MagicKeysEA: vorud az zone [" + zoneLabel + "] radd shod - risk-e vaghei " +
                          DoubleToString(realRisk, 2) + "% bishtar az hadd-e mojaz (" + DoubleToString(allowed, 2) +
                          "%) ast (hajm be dalil-e hadeaghal-lot-e broker bala round shode; SL door ya hesab koochik).";
         Print(riskMsg);
         MKNotify(NOTIFY_GUARD, riskMsg);
         return ENTRY_RESULT_DONE;
        }
     }

   double candleRangePips = (g_pipSize > 0.0 && candleHigh > candleLow) ? (candleHigh - candleLow) / g_pipSize : 0.0;
   double bigCandleLimit  = MKBigCandlePips();
   bool   bigCandle       = (confirmed && bigCandleLimit > 0.0 && candleRangePips > bigCandleLimit);

   Print("MagicKeysEA: vorud-e ", (signal == ENTRY_BUY ? "Kharid" : "Forush"),
         " az zone [", zoneLabel, "] | hajm-e kol-e mohasebe-shode: ", DoubleToString(lot, 2),
         " | SL=", (slPrice > 0.0 ? DoubleToString(slPrice, g_digits) : "sabet"),
         " (", DoubleToString(slPips, 1), " pip az vorud)",
         (candleHigh > candleLow
          ? (" | candle-e mabna: High=" + DoubleToString(candleHigh, g_digits) + " Low=" + DoubleToString(candleLow, g_digits) +
             " -> SL = " + (direction == POSITION_TYPE_BUY ? "Low - " : "High + ") + DoubleToString(MKSlBufferPips(), 0) + " pip")
          : " | candle-e mabna nadarad (SL-e sabet az vorud)"),
         (candleHigh > candleLow ? (" | range-e candle: " + DoubleToString(candleRangePips, 1) + " pip") : ""),
         (bigCandle ? " (BOZORG)" : ""));

   //--- candle-e mamooli (ya vorud-e dasti): hamoon hajm-e kol, ba SL-e hoshmand
   if(!bigCandle)
     {
      if(!g_tradeManager.OpenTradePair(direction, lot, slPrice))
        {
         Print("MagicKeysEA: khata dar baz kardan-e moamele baraye zone [", zoneLabel, "]");
         return g_tradeManager.LastOpenFailureRetryable() ? ENTRY_RESULT_RETRY : ENTRY_RESULT_DONE;   // [v1.17]
        }
      return ENTRY_RESULT_DONE;
     }

   //--- candle-e bozorg: vorud-e marhale-i (SL hamoon SL-e hoshmand-e poshte candle)
   //--- har vorud (ye joft-moamele) hadeaghal 2 * hadeaghal-lot-e broker mikhad (do position-e mostaghel)
   double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double minPair = 2.0 * volMin;

   double firstPct = MathMax(0.0, MathMin(InpBigCandleFirstEntryPercent, 100.0));
   double firstLot = g_riskManager.NormalizeVolume(lot * firstPct / 100.0);

   if(firstLot < minPair)
      firstLot = minPair;
   if(firstLot > lot)
      firstLot = lot;

   double restLot = NormalizeDouble(lot - firstLot, 2);
   bool   hasAddOn = (restLot >= minPair - 0.0000001);

   if(!hasAddOn && firstLot < lot)
      Print("MagicKeysEA: hoshdar - hajm-e baghimande (", DoubleToString(restLot, 2),
            ") kamtar az hadeaghal-e mojaz-e yek joft-moamele (", DoubleToString(minPair, 2),
            ") ast; vorud-e marhale-i-e dovom anjam nemishe.");

   if(!g_tradeManager.OpenTradePair(direction, firstLot, slPrice))
     {
      Print("MagicKeysEA: khata dar baz kardan-e moamele baraye zone [", zoneLabel, "]");
      return g_tradeManager.LastOpenFailureRetryable() ? ENTRY_RESULT_RETRY : ENTRY_RESULT_DONE;   // [v1.17]
     }

   if(!hasAddOn)
      return ENTRY_RESULT_DONE;

   //--- sath-e bargasht: darsadi az range-e candle az donbale-ye candle (Sell: az Low be bala, Buy: az High be paiin)
   double retrace = MathMax(0.0, MathMin(InpBigCandleRetracePercent, 100.0)) / 100.0;
   double range   = candleHigh - candleLow;
   double level   = (direction == POSITION_TYPE_SELL) ? (candleLow + range * retrace)
                                                       : (candleHigh - range * retrace);

   g_tradeManager.RegisterAddOn(direction, restLot, level, slPrice, InpTimeframe, InpBigCandleWaitCandles, zoneLabel);
   return ENTRY_RESULT_DONE;
  }

//+------------------------------------------------------------------+
//| [v1.20] Meyar-e sefareshi baraye Strategy Tester / Optimization:  |
//| Profit Factor x Recovery Factor, ba jarime baraye tedad-e kam-e    |
//| moamele (kamtar az 100 moamele nesbat-e jazr-e tedad)             |
//+------------------------------------------------------------------+
double OnTester()
  {
   double trades = TesterStatistics(STAT_TRADES);
   double profit = TesterStatistics(STAT_PROFIT);
   double pf     = TesterStatistics(STAT_PROFIT_FACTOR);
   double rf     = TesterStatistics(STAT_RECOVERY_FACTOR);

   if(trades < 10.0 || profit <= 0.0)
      return 0.0;

   return pf * rf * MathMin(1.0, MathSqrt(trades / 100.0));
  }

//+------------------------------------------------------------------+
//| [v1.19] Esm-e halat baraye log                                    |
//+------------------------------------------------------------------+
string ModeName(const ENUM_EA_MODE mode)
  {
   if(mode == EAMODE_AUTO)
      return "AUTOMATIC";
   if(mode == EAMODE_SEMI)
      return "NIM-AUTOMATIC";
   return "DASTI";
  }

//+------------------------------------------------------------------+
//| [v1.19] Halat va jaye panel dar GlobalVariable-haye terminal       |
//| zakhire mishan va terminal GlobalVariable-i ke 4 hafte dastresi    |
//| nashode ro pak mikone. Ghablan faghat vaghti halat avaz mishod     |
//| neveshte mishod; yani ba EA-ye tolani + restart-e ba'di halat      |
//| bedoone khabar be NIM-AUTOMATIC bar migasht (EA tayidiye ro ham     |
//| neshoon midad vali vared nemishod). Hala hadeaksar yek bar dar saat |
//| dobare neveshte mishe                                               |
//+------------------------------------------------------------------+
void KeepStorageAlive()
  {
   uint now = GetTickCount();
   if(g_lastStorageTouch != 0 && (now - g_lastStorageTouch) < (uint)3600000)
      return;

   g_lastStorageTouch = now;
   g_panel.TouchStorage();
  }

//+------------------------------------------------------------------+
//| [v1.17] Aya in symbol mojaz ast dar jahat-e dade-shode moamele   |
//| beshe? (broker-haye ba halat-e LongOnly / ShortOnly / CloseOnly)  |
//+------------------------------------------------------------------+
bool SymbolAllowsDirection(ENUM_POSITION_TYPE direction)
  {
   ENUM_SYMBOL_TRADE_MODE mode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);

   if(mode == SYMBOL_TRADE_MODE_FULL)
      return true;
   if(mode == SYMBOL_TRADE_MODE_LONGONLY)
      return (direction == POSITION_TYPE_BUY);
   if(mode == SYMBOL_TRADE_MODE_SHORTONLY)
      return (direction == POSITION_TYPE_SELL);

   return false;   // moamele gheir-faal ya faghat bastan
  }

//+------------------------------------------------------------------+
//| [v1.17] Signal-e tayid-shode-i ke vorudesh be dalil-e mowaghati   |
//| anjam nashod ro dar saf mizare. Zone ghablan masraf shode (hich    |
//| zone-i dobare signal nemide) - in saf faghat hamoon signal ro      |
//| ta InpSignalRetrySeconds sanie har 1 sanie dobare emtehan mikone.  |
//| 0 = ghair-faal: signal soukhte mishe (raftar-e ghabli)             |
//| Saf dar hafeze-st: ba restart/avaz-e timeframe az beyn mire.       |
//+------------------------------------------------------------------+
void QueueSignalRetry(ENUM_ENTRY_SIGNAL signal, string label, double high, double low)
  {
   if(InpSignalRetrySeconds <= 0)
     {
      Print("MagicKeysEA: vorud az zone [", label, "] anjam nashod va InpSignalRetrySeconds = 0 ast - signal soukhte shod.");
      return;
     }

   int n = ArraySize(g_pending);
   ArrayResize(g_pending, n + 1);

   g_pending[n].active    = true;
   g_pending[n].signal    = signal;
   g_pending[n].label     = label;
   g_pending[n].high      = high;
   g_pending[n].low       = low;
   g_pending[n].startTick = GetTickCount();
   g_pending[n].lastTry   = g_pending[n].startTick;
   g_pending[n].attempts  = 1;

   Print("MagicKeysEA: vorud az zone [", label, "] be dalil-e mowaghati anjam nashod - ta ", InpSignalRetrySeconds,
         " sanie har 1 sanie dobare talash mishe.");
  }

//+------------------------------------------------------------------+
//| [v1.17] Har tick: signal-haye montazer ro dobare emtehan kon      |
//| (hadeaksar yek bar dar sanie baraye har signal). Signal vaghti az |
//| saf kharej mishe ke vorud baz shod, ba ghanoon-e sabet radd shod  |
//| (mesl-e zarar-e roozane), ya moddat tamoom shod.                   |
//+------------------------------------------------------------------+
void ProcessPendingSignals()
  {
   int n = ArraySize(g_pending);
   if(n == 0)
      return;

   //--- karbar halat ro az AUTO avaz karde: EA digeh khodesh vared nemishe
   if(g_panel.GetMode() != EAMODE_AUTO)
     {
      Print("MagicKeysEA: halat az Automatic avaz shod - ", n, " signal-e montazer-e talash-e mojaddad laghv shod.");
      ArrayResize(g_pending, 0);
      return;
     }

   uint now = GetTickCount();

   for(int i = 0; i < n; i++)
     {
      if(!g_pending[i].active)
         continue;

      //--- moddat-e talash tamoom shod
      if((now - g_pending[i].startTick) > (uint)InpSignalRetrySeconds * 1000)
        {
         g_pending[i].active = false;
         Print("MagicKeysEA: signal-e zone [", g_pending[i].label, "] ba'd az ", InpSignalRetrySeconds,
               " sanie talash vared nashod - laghv shod.");
         continue;
        }

      //--- hadeaksar yek talash dar sanie
      if((now - g_pending[i].lastTry) < 1000)
         continue;

      g_pending[i].lastTry = now;
      g_pending[i].attempts++;

      Print("MagicKeysEA: talash-e ", g_pending[i].attempts, " baraye signal-e zone [", g_pending[i].label, "]");

      if(ProcessEntrySignal(g_pending[i].signal, g_pending[i].label, g_pending[i].high, g_pending[i].low, true) == ENTRY_RESULT_DONE)
         g_pending[i].active = false;
     }

   //--- signal-haye tamoom-shode ro az saf pak kon
   int activeCount = 0;
   for(int i = 0; i < n; i++)
      if(g_pending[i].active)
         activeCount++;

   if(activeCount == n)
      return;

   SPendingSignal kept[];
   ArrayResize(kept, activeCount);

   int k = 0;
   for(int i = 0; i < n; i++)
     {
      if(g_pending[i].active)
        {
         kept[k] = g_pending[i];
         k++;
        }
     }

   ArrayResize(g_pending, activeCount);
   for(int i = 0; i < activeCount; i++)
      g_pending[i] = kept[i];
  }

//+------------------------------------------------------------------+
//| [v1.17] Mohafez-e "yek EA rooye har symbol"                        |
//| Har chart ye kod-e kootah az ChartID dare (ChartID bozorg-tar az    |
//| dagighiat-e double ast, pas bagh-imande-ye 1000000007 zakhire mishe)|
//| Kod-e chart-e sahib dar GlobalVariable "MKEA_Inst_<symbol>" mimoone.|
//| Chart-e jadid faghat vaghti jelosh gerefte mishe ke chart-e sahib   |
//| hanooz baz bashe va hamin EA rooyesh bashe. Dar Strategy Tester      |
//| ya ba InpAllowSecondInstance = true bi-asar ast.                    |
//+------------------------------------------------------------------+
double InstanceCode()
  {
   return (double)(ChartID() % 1000000007);
  }

string InstanceKey()
  {
   return "MKEA_Inst_" + _Symbol;
  }

bool ClaimInstance()
  {
   if(InpAllowSecondInstance || MQLInfoInteger(MQL_TESTER) != 0 || MQLInfoInteger(MQL_OPTIMIZATION) != 0)
      return true;

   long   myId   = ChartID();
   double myCode = InstanceCode();
   string myName = MQLInfoString(MQL_PROGRAM_NAME);
   string key    = InstanceKey();

   if(GlobalVariableCheck(key))
     {
      double owner = GlobalVariableGet(key);

      if(owner != myCode)
        {
         //--- aya chart-e sahib hanooz baz ast va hamin EA rooyesh ast?
         long id = ChartFirst();
         while(id >= 0)
           {
            if(id != myId && (double)(id % 1000000007) == owner &&
               ChartSymbol(id) == _Symbol && ChartGetString(id, CHART_EXPERT_NAME) == myName)
               return false;

            id = ChartNext(id);
           }
        }
     }

   GlobalVariableSet(key, myCode);
   return true;
  }

void ReleaseInstance()
  {
   if(MQLInfoInteger(MQL_TESTER) != 0 || MQLInfoInteger(MQL_OPTIMIZATION) != 0)
      return;

   string key = InstanceKey();
   if(GlobalVariableCheck(key) && GlobalVariableGet(key) == InstanceCode())
      GlobalVariableDel(key);
  }

//+------------------------------------------------------------------+
//| [v1.12] Zarar-e emrooz (baste-shode + shenavar, kol-e hesab) be     |
//| darsad-e balance-e aval-e rooz (zaman-e server). 0 = sood ya zarar  |
//| nakarde                                                              |
//+------------------------------------------------------------------+
double TodayLossPercent()
  {
   datetime now      = TimeCurrent();
   datetime dayStart = now - (now % 86400);

   double closed = 0.0;
   if(HistorySelect(dayStart, now + 60))
     {
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;

         ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
            continue;

         closed += HistoryDealGetDouble(ticket, DEAL_COMMISSION) + HistoryDealGetDouble(ticket, DEAL_FEE);

         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY || entry == DEAL_ENTRY_INOUT)
            closed += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP);
        }
     }

   double pnl          = closed + AccountInfoDouble(ACCOUNT_PROFIT);
   double startBalance = AccountInfoDouble(ACCOUNT_BALANCE) - closed;

   if(pnl >= 0.0 || startBalance <= 0.0)
      return 0.0;

   return -pnl / startBalance * 100.0;
  }

//+------------------------------------------------------------------+
//| Tabdil-e pip be point bar asas-e tedad-e raghm-e a'shar-e symbol   |
//| (dar broker-haye 5/3 raghami har pip = 10 point)                  |
//+------------------------------------------------------------------+
int PipsToPoints(int pips)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0 || g_pipSize <= 0.0)
      return pips;

   return (int)MathRound(pips * g_pipSize / point);
  }

//+------------------------------------------------------------------+
//| Khoondan-e reshte-ye vorudi (InpBuyZoneLevels ya InpSellZoneLevels)|
//| va bargozari-ye noghat/manategh dar ZoneManager ba jahat-e dade-   |
//| shode. Format: ba comma joda mishan; har bakhsh ya ye adad-e taki-e|
//| ya ye baze-ye ba khat-tireh beinesh ast                             |
//| Mesal: "4321,4334-4336,4350.5"                                     |
//|  -> Zone 1: noghte-ye taki 4321                                    |
//|  -> Zone 2: baze-ye 4334 ta 4336                                   |
//|  -> Zone 3: noghte-ye taki 4350.5                                  |
//|                                                                     |
//|  [Bug Fix]: har adad-e parse-shode bayad > 0 bashe; token-haye     |
//|  na-motabar (masalan ye typo ke adad nist) digeh ye zone-e ghalat  |
//|  rooye gheimat-e 0 nemisazan - faghat radd mishan va ye hoshdar    |
//|  Print mishe                                                        |
//|                                                                     |
//|  Ye rah-e digeh baraye ezafe kardan-e zone (bedoone larzesh dadan  |
//|  be in vorudi-ha), estefade az panel-e rooye chart-e (Panel.mqh)   |
//|  ast - har do vorudi ro mishe khali gozasht va faghat az panel     |
//|  zone ezafe kard                                                    |
//+------------------------------------------------------------------+
void ParseAndLoadZones(string levelsText, ENUM_ZONE_DIRECTION direction)
  {
   string dirText = (direction == ZONE_BUY) ? "Buy" : "Sell";

   if(StringLen(levelsText) == 0)
      return;

   string parts[];
   int count = StringSplit(levelsText, ',', parts);

   for(int i = 0; i < count; i++)
     {
      string token = parts[i];
      StringTrimLeft(token);
      StringTrimRight(token);

      if(StringLen(token) == 0)
         continue;

      string label = dirText + "-" + IntegerToString(i + 1);

      string rangeParts[];
      int rangeCount = StringSplit(token, '-', rangeParts);

      if(rangeCount == 2)
        {
         double low  = StringToDouble(rangeParts[0]);
         double high = StringToDouble(rangeParts[1]);

         if(low <= 0 || high <= 0)
           {
            Print("MagicKeysEA: token-e na-motabar radd shod (", dirText, "): '", token, "' (adad-e sahih peida nashod)");
            continue;
           }

         g_zoneManager.AddZoneRange(low, high, direction, label);
        }
      else
        {
         double price = StringToDouble(token);

         if(price <= 0)
           {
            Print("MagicKeysEA: token-e na-motabar radd shod (", dirText, "): '", token, "' (adad-e sahih peida nashod)");
            continue;
           }

         g_zoneManager.AddZone(price, direction, label);
        }
     }
  }
//+------------------------------------------------------------------+
