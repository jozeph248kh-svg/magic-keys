//+------------------------------------------------------------------+
//|                                                     Settings.mqh |
//|  Settings.mqh - Tanzimat Markazi (Central Settings)               |
//|                                                                    |
//|  Hameye adadhaye ghabele tanzim (risk, tashkhis candle, tayidiye  |
//|  vorud, modiriat moamele, noghat/manategh vorud) hamin ja jam      |
//|  shodan. Kafie hamin file ro baz koni ta har adadi ro khasti       |
//|  avaz koni - niazi be gashtan bein chand file mokhtalef nist.      |
//|                                                                    |
//|  In file bayad ghabl az baghie module-ha include beshe (age bad   |
//|  ham include beshe moshkeli nist, chon har module khodesh in      |
//|  file ro dar ebteda include mikone). Guard-e paiin az tarif-e      |
//|  tekrari jelogiri mikone.                                          |
//+------------------------------------------------------------------+
#ifndef __MAGICKEYS_SETTINGS_MQH__
#define __MAGICKEYS_SETTINGS_MQH__

#property strict

//+------------------------------------------------------------------+
//| [v1.20] Enum-haye jadid baraye tanzimat (dropdown dar Inputs)      |
//+------------------------------------------------------------------+
enum ENUM_PIN_BODY_POS
  {
   PINPOS_ANY = 0,        // har ja (ghair-faal)
   PINPOS_FAR_THIRD = 1   // badaneh faghat dar sevom-e door az sayeh
  };

enum ENUM_PIN_COLOR
  {
   PINCOL_ANY = 0,        // rang-e candle mohem nist
   PINCOL_WITH_DIRECTION = 1 // Pinbar-e sooudi bayad candle-e sabz, nozooli candle-e ghermez bashe
  };

enum ENUM_DOJI_TYPE
  {
   DOJI_ANY = 0,          // hame-ye anva (raftar-e ghabli)
   DOJI_STANDARD = 1,     // faghat Doji-ye ma'mooli (sayeh-haye motevazen)
   DOJI_DRAGONFLY = 2,    // faghat Dragonfly (sayeh-ye paiin-e boland)
   DOJI_GRAVESTONE = 3,   // faghat Gravestone (sayeh-ye bala-ye boland)
   DOJI_LONGLEGGED = 4    // faghat Long-legged (har do sayeh boland)
  };

enum ENUM_SIZE_MODE
  {
   SIZEMODE_FIXED = 0,    // adad-e sabet (pip)
   SIZEMODE_ATR = 1       // zarib-i az ATR (motenaseb ba nosan)
  };

enum ENUM_TRAIL_MODE
  {
   TRAIL_OFF = 0,         // ghair-faal
   TRAIL_FIXED = 1,       // fasele-ye sabet (pip) az gheimat
   TRAIL_ATR = 2,         // fasele = zarib * ATR
   TRAIL_CANDLE = 3       // poshte-e Low/High-e candle-haye ghabli
  };

enum ENUM_TRAIL_APPLY
  {
   TRAILAPPLY_ALL = 0,    // hame-ye moamele-haye EA
   TRAILAPPLY_TRADE2 = 1  // faghat Moamele 2 (va dasti-haye jazb-shode)
  };

enum ENUM_TIME_BASIS
  {
   TIMEBASIS_SERVER = 0,  // zaman-e server-e broker
   TIMEBASIS_LOCAL = 1,   // zaman-e computer
   TIMEBASIS_GMT = 2      // GMT
  };

enum ENUM_NEWS_SOURCE
  {
   NEWS_MANUAL = 0,       // list-e dasti (InpNewsManualTimes)
   NEWS_CALENDAR = 1,     // taghvim-e eghtesadi-ye MT5 (faghat live)
   NEWS_BOTH = 2          // har do
  };

enum ENUM_NEWS_IMPORTANCE
  {
   NEWSIMP_LOW = 1,       // kam be bala
   NEWSIMP_MEDIUM = 2,    // motevaset be bala
   NEWSIMP_HIGH = 3       // faghat por-ahamiat
  };

enum ENUM_TREND_MODE
  {
   TREND_OFF = 0,         // ghair-faal
   TREND_WITH = 1,        // faghat ham-jahat ba rovand
   TREND_COUNTER = 2      // faghat khelaf-e rovand (bargasht)
  };

enum ENUM_RISK_BASE
  {
   RISKBASE_BALANCE = 0,  // balance
   RISKBASE_EQUITY = 1    // equity
  };

enum ENUM_NOTIFY_KIND
  {
   NOTIFY_SIGNAL = 0,
   NOTIFY_ENTRY = 1,
   NOTIFY_CLOSE = 2,
   NOTIFY_GUARD = 3,
   NOTIFY_INFO = 4
  };

//+------------------------------------------------------------------+
//| 1) Risk Management (RiskManager.mqh)                              |
//+------------------------------------------------------------------+
input group "=== 1) Risk Management ==="
input double InpRiskPercent = 1.0;  // darsad-e risk az balance dar har moamele (masalan 1.0 = 1%)

//+------------------------------------------------------------------+
//| 2) Candle Detection (CandleAnalyzer.mqh)                          |
//+------------------------------------------------------------------+
input group "=== 2) Candle Detection ==="
input double InpDojiBodyRatio     = 0.10;  // hadeaksar nesbat-e badaneh be kolle range baraye tashkhis-e Doji (0.10 = 10%)
input double InpMarubozuWickRatio = 0.05;  // hadeaksar nesbat-e sayeh be kolle range baraye tashkhis-e Marubozu (0.05 = 5%)

//+------------------------------------------------------------------+
//| 2b) [v1.20] Tarif-e Candle-haye Tayidiye (CandleAnalyzer.mqh)      |
//|     default-ha = raftar-e ghabli (v1.19)                           |
//+------------------------------------------------------------------+
input group "=== 2b) Pinbar Definition ==="
input double InpPinWickRatio          = 0.60;  // Pinbar: hadeaghal nesbat-e sayeh-ye asli be kolle range (0.60 = 60%)
input bool   InpPinUseHammerShape     = true;  // Pinbar: shekl-e Hammer / Shooting Star ham ghabul bashe (sayeh-ye asli >= X barabar-e badaneh)
input double InpPinWickToBodyRatio    = 2.0;   // Pinbar (Hammer): hadeaghal nesbat-e sayeh-ye asli be badaneh
input double InpPinOppWickToBodyRatio = 0.5;   // Pinbar (Hammer): hadeaksar nesbat-e sayeh-ye moghabel be badaneh
input double InpPinOppWickMaxRatio    = 1.0;   // Pinbar: hadeaksar sayeh-ye moghabel be kolle range (1.0 = ghair-faal; pishnahad 0.25)
input double InpPinBodyMaxRatio       = 1.0;   // Pinbar: hadeaksar badaneh be kolle range (1.0 = ghair-faal; pishnahad 0.30)
input ENUM_PIN_BODY_POS InpPinBodyPosition = PINPOS_ANY; // Pinbar: mahal-e badaneh (sevom-e door az sayeh = Pinbar-e tamiz-tar)
input ENUM_PIN_COLOR    InpPinCandleColor  = PINCOL_ANY; // Pinbar: rang-e candle (sooudi = sabz / nozooli = ghermez)
input double InpPinMinRangePips       = 0.0;   // Pinbar: hadeaghal range-e candle (pip) - candle-haye rize rad mishan (0 = ghair-faal)
input double InpPinMaxRangePips       = 0.0;   // Pinbar: hadeaksar range-e candle (pip) - candle-haye ghool rad mishan (0 = ghair-faal)
input bool   InpPinMustSweepPrev      = false; // Pinbar: sayeh bayad Low/High-e candle-e ghabli ro jaroo karde bashe (shekar-e stop)

input group "=== 2c) Doji Definition ==="
input ENUM_DOJI_TYPE InpDojiTypeFilter = DOJI_ANY; // Doji: noe-e ghabul (hame / standard / Dragonfly / Gravestone / Long-legged)
input double InpDojiLongWickRatio     = 0.30;  // Doji: hadeaghal nesbat-e sayeh be range baraye 'sayeh-ye boland' (Dragonfly/Gravestone/Long-legged)
input double InpDojiShortWickRatio    = 0.10;  // Doji: hadeaksar nesbat-e sayeh be range baraye 'sayeh-ye kootah' (Dragonfly/Gravestone)
input double InpDojiMinRangePips      = 0.0;   // Doji: hadeaghal range-e candle (pip) ta noise-e bazar Doji hesab nashe (0 = ghair-faal)
input bool   InpDojiMatchZoneSide     = false; // Doji: Dragonfly faghat dar zone-e Kharid va Gravestone faghat dar zone-e Forush ghabul bashe

input group "=== 2d) Engulfing Definition ==="
input double InpEngulfMinBodyMult     = 0.0;   // Engulfing: badaneh-ye candle hadeaghal X barabar-e badaneh-ye candle-e ghabli (0 = ghair-faal; pishnahad 1.0)
input bool   InpEngulfFullRange       = false; // Engulfing: kol-e range (High/Low) ro bepooshoone, na faghat badaneh
input double InpEngulfMinBodyPercent  = 0.0;   // Engulfing: hadeaghal nesbat-e badaneh be range-e candle (0.5 = 50%) - candle ba sayeh-haye boland rad mishe (0 = ghair-faal)
input double InpEngulfMinBodyPips     = 0.0;   // Engulfing: hadeaghal andaze-ye badaneh (pip) (0 = ghair-faal)

//+------------------------------------------------------------------+
//| 3) General Entry Confirmation (EntryConfirmation.mqh)             |
//+------------------------------------------------------------------+
input group "=== 3) General Entry Confirmation (NOT USED by EA now) ==="
input bool InpUseDojiConfirmation   = true;  // Doji be onvane tayidiye vorud dar nazar gerefte beshe
input bool InpUsePinbarConfirmation = true;  // Pinbar be onvane tayidiye vorud dar nazar gerefte beshe
input bool InpUseEngulfingConfirmation = true;  // Engulfing (Soodi/Nozooli) be onvane tayidiye vorud dar nazar gerefte beshe

//+------------------------------------------------------------------+
//| 4) Trade Management - Split & Staging (TradeManager.mqh)          |
//+------------------------------------------------------------------+
input group "=== 4) Trade Management (Split & Staging) ==="
input int    InpSplitStopLossPips    = 200;   // SL-e hoshmand (moshtarek-e har do moamele): fasele-ye SL az sayeh-ye candle-e tayidiye (pip) - Buy: InpSplitStopLossPips paiin-tar az Low-e candle, Sell: bala-tar az High-e candle. Age candle-i dar dastres nabashe az noghte-ye vorud hesab mishe
input int    InpTrade1TakeProfitPips = 200;   // target-e Moamele 1 (pip)
input int    InpTrade2TakeProfitPips = 1000;  // target-e nahaii-e Moamele 2 (pip)
input int    InpTrade2PartialPips    = 500;   // noghte-i ke Moamele 2 nime baste va risk-free mishe (pip)
input int    InpTrade2SlAfterTrade1Pips = 200; // [v1.14] vaghti Moamele 1 be target resid va baste shod, SL-e Moamele 2 be in fasele (pip) paiin-tar (Buy) / bala-tar (Sell) az noghte-ye vorud-e khodesh miad ta age barghasht zarar-e kol sefr bashe (barabar InpTrade1TakeProfitPips bezar). Faghat SL ro nazdik-tar mikone, hargez door-tar nemikone. 0 = SL-e avalie hamoon-jaa mimoone (raftar-e ghabli)
input double InpTrade2PartialPercent = 50.0;  // darsadi az Moamele 2 ke dar noghte-ye partial baste mishe

//+------------------------------------------------------------------+
//| 4b) [v1.20] SL / Candle-e Bozorg ba ATR (Dynamic.mqh)              |
//+------------------------------------------------------------------+
input group "=== 4b) Dynamic SL / Big Candle (ATR) ==="
input int             InpAtrPeriod        = 14;               // dore-ye ATR
input ENUM_TIMEFRAMES InpAtrTimeframe     = PERIOD_CURRENT;   // timeframe-e ATR (PERIOD_CURRENT = hamoon timeframe-e tahlil-e EA)
input ENUM_SIZE_MODE  InpSlMode           = SIZEMODE_FIXED;   // fasele-ye SL az sayeh-ye candle: sabet (InpSplitStopLossPips) ya ATR
input double          InpSlAtrMultiplier  = 1.5;              // [ATR] fasele-ye SL = in zarib * ATR
input double          InpSlMinPips        = 50.0;             // [ATR] hadeaghal fasele-ye SL (pip) (0 = ghair-faal)
input double          InpSlMaxPips        = 600.0;            // [ATR] hadeaksar fasele-ye SL (pip) (0 = ghair-faal)
input ENUM_SIZE_MODE  InpBigCandleMode    = SIZEMODE_FIXED;   // hadd-e candle-e bozorg: sabet (InpBigCandlePips) ya ATR
input double          InpBigCandleAtrMult = 2.5;              // [ATR] candle-e bozorg = range bishtar az in zarib * ATR (0 = ghair-faal)
input double          InpBreakEvenOffsetPips = 0.0;           // Risk-Free: SL be vorud + in meghdar (pip) montaghel she (baraye jobran-e commission/swap)

//+------------------------------------------------------------------+
//| 4c) [v1.20] Trailing / Modiriat-e Ezafe (PositionExtras.mqh)       |
//+------------------------------------------------------------------+
input group "=== 4c) Trailing & Extra Position Management ==="
input ENUM_TRAIL_MODE  InpTrailMode        = TRAIL_OFF;        // Trailing Stop
input ENUM_TRAIL_APPLY InpTrailApplyTo     = TRAILAPPLY_ALL;   // Trailing rooye kodoom moamele-ha
input int              InpTrailStartPips   = 300;              // trailing vaghti sood be in meghdar (pip) resid shoroo mishe
input int              InpTrailDistancePips = 200;             // [Fixed] fasele-ye SL az gheimat (pip)
input double           InpTrailAtrMult     = 2.0;              // [ATR] fasele-ye SL = in zarib * ATR
input int              InpTrailCandleCount = 2;                // [Candle] SL poshte-e Low/High-e in tedad candle-e baste-shode
input double           InpTrailCandleOffsetPips = 20.0;        // [Candle] fasele-ye ezafi az Low/High (pip)
input double           InpTrailStepPips    = 10.0;             // hadeaghal bahbood-e SL baraye har bar-e jabeja-i (pip)
input bool             InpTrailNeverBelowEntry = true;         // trailing hargez SL ro ba'd az risk-free dobare be zarar nabare
input double           InpAutoBreakEvenPips = 0.0;             // Breakeven-e mostaghel: vaghti sood be in meghdar (pip) resid SL be vorud (+offset) bere (0 = ghair-faal)
input bool             InpExtrasIncludeManual = true;          // dar halat-e Dasti, position-haye jazb-shode ham trailing/breakeven/khorooj-e zamani begirand
input int              InpTimeExitHours    = 0;                // bastan-e position ba'd az in tedad saat (0 = ghair-faal)
input bool             InpTimeExitOnlyLosing = false;          // khorooj-e zamani faghat vaghti position dar zarar/sefr ast

//+------------------------------------------------------------------+
//| 4d) [v1.20] SL-e candle-e vorud (halat-e nim-automatic va dasti)   |
//+------------------------------------------------------------------+
input group "=== 4d) Entry-Candle Stop (Semi-Auto / Manual) ==="
input bool InpUseEntryCandleStop         = true;  // vaghti bedoon-e tayidiye vared mishi: Kharid -> age Low-e candle-e ghabli bala-tar az gheimat-e vorud bood, SL = paiin-tar az Low-e candle-e vorud; Forush -> barax
input int  InpEntryCandleStopPips        = 200;   // fasele-ye in SL az Low/High-e candle-e vorud (pip)
input bool InpEntryCandleStopOnlyNoSignal = false; // faghat vaghti signal-e armed-e hamjahat nadari (false = hamishe, hata ba signal)

//+------------------------------------------------------------------+
//| 5) Entry Zones (ZoneManager.mqh)                                  |
//+------------------------------------------------------------------+
input group "=== 5) Entry Zones ==="
input bool   InpZoneUseDojiConfirmation   = true;  // Doji be onvane tayidiye zone dar nazar gerefte beshe
input bool   InpZoneUsePinbarConfirmation = true;  // Pinbar be onvane tayidiye zone dar nazar gerefte beshe
input bool   InpZoneUseEngulfingConfirmation = true;  // Engulfing be onvane tayidiye zone dar nazar gerefte beshe
input double InpZoneTolerancePips         = 5.0;   // tolerance-e noghat-e tak-adadi (pip) - residan-e daghigh be ye adad-e sahih nadere
input int    InpZoneMaxConfirmCandles     = 3;     // ta chand candle (az candle-i ke gheimat tooosh vared-e zone shode) montazer-e tayidiye bemoonim; age tu in moddat tayidiye nayad, zone namotabar mishe
input double InpConfirmExtremeTolerancePips = 20.0; // tolerance-e "hamsath" (pip): candle-e tayidiye bayad bala-tarin (zone-e Sell) ya paiin-tarin (zone-e Buy) candle-e ba'd az vorud be zone bashe, ya ta in andaze ba oon fargh dashte bashe
input bool   InpZoneUseCandleRangeTouch = true;  // [v1.19] lams-e zone ro faghat az rooye tick-haye EA nagir: age range-e candle (High/Low) zone ro lams karde bashe (hata ager gheimat bein-e do tick az rooye zone-e barik parid, ya EA tick ro nadid) zone fa'al mishe. false = raftar-e ghabli (faghat tick)
input int    InpZoneRequirePatternCount = 1;   // [v1.20] tedad-e hadeaghal-e algoo-ye hamzaman baraye tayid (1 = yeki kafie, 2 = hadeaghal do algoo, 3 = har se)
input bool   InpBuyZoneAllowDoji      = true;  // [v1.20] zone-e Kharid: Doji ghabul bashe (dar kenar-e InpZoneUseDojiConfirmation)
input bool   InpBuyZoneAllowPinbar    = true;  // [v1.20] zone-e Kharid: Pinbar ghabul bashe
input bool   InpBuyZoneAllowEngulfing = true;  // [v1.20] zone-e Kharid: Engulfing ghabul bashe
input bool   InpSellZoneAllowDoji     = true;  // [v1.20] zone-e Forush: Doji ghabul bashe
input bool   InpSellZoneAllowPinbar   = true;  // [v1.20] zone-e Forush: Pinbar ghabul bashe
input bool   InpSellZoneAllowEngulfing = true; // [v1.20] zone-e Forush: Engulfing ghabul bashe
input double InpConfirmMinRangePips   = 0.0;   // [v1.20] hadeaghal range-e candle-e tayidiye (pip), baraye har se algoo (0 = ghair-faal)
input double InpConfirmMaxRangePips   = 0.0;   // [v1.20] hadeaksar range-e candle-e tayidiye (pip) (0 = ghair-faal)
input bool   InpConfirmRequireCloseDirection = false; // [v1.20] candle-e tayidiye bayad dar jahat-e zone baste beshe (Kharid: Close >= Open, Forush: Close <= Open)

//+------------------------------------------------------------------+
//| 6) Big Confirmation Candle (MagicKeysEA.mq5 + TradeManager.mqh)   |
//|    Vaghti candle-e tayidiye kheili bozorg bashe (SL-e hoshmand ham|
//|    be tabe'-e oon door mishe), vorud marhale-i anjam mishe:       |
//|    nesbati az hajm fori, baghi ba bargasht be sath-e vasat         |
//+------------------------------------------------------------------+
input group "=== 6) Big Confirmation Candle ==="
input int    InpBigCandlePips              = 200;   // age range-e candle-e tayidiye (High-Low, pip) bishtar az in bood, vorud marhale-i mishe (0 = ghair-faal)
input double InpBigCandleFirstEntryPercent = 50.0;  // darsad-e hajm-e mamooli ke fori baz mishe (baghi dar sath-e bargasht baz mishe)
input double InpBigCandleRetracePercent    = 50.0;  // sath-e vorud-e baghie-ye hajm: darsad-e range-e candle-e tayidiye az donbale-ye candle (50 = vasat-e candle)
input int    InpBigCandleWaitCandles       = 1;     // ta chand candle-e ba'd montazer-e bargasht be in sath bemoonim (1 = faghat candle-e ba'd)

//+------------------------------------------------------------------+
//| 7) Semi-Auto Mode (MagicKeysEA.mq5 + Panel.mqh)                   |
//|    Halat-e nim-automatic ro az rooye dokme-ye panel roshan/khamoosh|
//|    mikoni (vaziatesh hafeze mishe). Dar in halat EA khodash vared- |
//|    e moamele nemishe: faghat vaghti tayidiye peida shod hoshdar    |
//|    mide, va ba dokme-haye BUY/SELL-e panel vared mishi - hajm, SL, |
//|    TP-ha ro EA mizare va baghie-ye modiriat ro ham khodesh anjam   |
//|    mide                                                             |
//+------------------------------------------------------------------+
input group "=== 7) Semi-Auto Mode ==="
input bool InpSemiAutoAlert              = true;  // dar halat-e nim-automatic, vaghti tayidiye peida shod Alert (popup + seda) bede
input int  InpSemiAutoSignalValidCandles = 3;     // signal-e tayidiye ta chand candle baraye dokme-ye BUY/SELL mo'tabare (ba'd az oon vorud-e dasti mamooli mishe)

//+------------------------------------------------------------------+
//| 8) Manual Mode ("Dasti") (TradeManager.mqh + MagicKeysEA.mq5)     |
//|    Dar halat-e Dasti, ba dokme-haye khod-e MetaTrader (ba hajm-e  |
//|    khodet) vared mishi. EA position-haye dasti-ye jadid (magic=0) |
//|    ro jazb mikone: SL va TP ro age nazashte bashi mizare (SL-e    |
//|    sabet InpSplitStopLossPips, TP = InpTrade2TakeProfitPips) va   |
//|    ba in tanzim khorooj-e marhale-i ham mikone                     |
//+------------------------------------------------------------------+
input group "=== 8) Manual Mode (Dasti) ==="
input bool InpManualStagedExit = true;  // khorooj-e marhale-i rooye position-haye dasti: nime-basti dar InpTrade1TakeProfitPips + risk-free va partial dar InpTrade2PartialPips (false = faghat SL va TP-e nahaii)
input bool InpManualAutoPair = true;   // [v1.16] age karbar do position-e hamjahat ba hajm-e barabar kenar-e ham baz kard (dar InpManualPairWindowSec), EA oon-ha ro mesl-e joft-moamele-ye nim-automatic/automatic modiriat mikone: Moamele 1 dar TP1 baste mishe, SL-e Moamele 2 nazdik mishe, Moamele 2 dar InpTrade2PartialPips nime mishe va baghi be TP-e nahaii miresse (niaz be InpManualStagedExit = true)
input int  InpManualPairWindowSec = 60; // [v1.16] hadeaksar fasele-ye zamani (sanie) bein-e baz shodan-e do position-e dasti baraye in-ke "joft" hesab beshan

//+------------------------------------------------------------------+
//| 9) Execution & Safety (TradeManager.mqh + MagicKeysEA.mq5)        |
//|    [v1.11] Tanzimat-e ejra va imeni. Hame-ye default-ha tarzi     |
//|    hastan ke raftar-e ghabli ro taghir nemidan (be joz ghesmat-   |
//|    haye ke dar tozih-e har ostoone ba'd az in neveshte shode)     |
//+------------------------------------------------------------------+
input group "=== 9) Execution & Safety ==="
input int    InpMagicBase            = 0;     // magic-e payeh: Moamele 1 = payeh+1, Moamele 2 = payeh+2. Pishnahad: ye adad-e yekta (masalan 770000) ta ba EA-haye digeh/chart-haye digeh tadakhol nakone. 0 = raftar-e ghabli (magic 1 va 2)
input int    InpDeviationPoints      = 30;    // hadeaksar slippage-e mojaz (point) baraye order-haye bazar - ghablan set nashode bood
input int    InpMaxSpreadPoints      = 0;     // age spread (point) bishtar az in bood vorud radd mishe (0 = ghair-faal)
input int    InpPointsPerPip         = 0;     // chand point = 1 pip. 0 = khodkar (5/3 raghami: 10 point, baghie: 1 point). Baraye Tala (XAUUSD) ba 2 raghm: 1 pip = 0.10$ yani 10 bezar, 1 pip = 0.01$ yani 1 bezar
input double InpMaxRiskMultiplier    = 0.0;   // [v1.12] age risk-e vaghei (ba round shodan be hadeaghal-lot) bishtar az InpRiskPercent x in zarib bood vorud radd mishe (masalan 1.5). 0 = ghair-faal
input double InpMaxDailyLossPercent  = 0.0;   // [v1.12] age zarar-e emrooz (baste-shode + shenavar, kol-e hesab) az in darsad-e balance-e aval-e rooz bishtar bood, vorud-e jadid radd mishe. 0 = ghair-faal
input int    InpMaxOpenPairs         = 0;     // [v1.12] hadeaksar tedad-e joft-moamele-ye baz-e hamzaman (vorud-e marhale-i-e candle-e bozorg jozve hamoon vorud hesab mishe). 0 = ghair-faal
input bool   InpCloseAllEaOnly       = false; // [v1.12] true: dokme-ye CLOSE ALL faghat moamele-haye khod-e EA (va dasti-haye jazb-shode) ro mibande; false: hame-ye position-haye in symbol
input int    InpPanelMaxRows         = 5;     // [v1.12] tedad-e radif-e zone dar har bakhsh-e panel (3 ta 12) - bishtar = panel boland-tar
input bool   InpChartAutoFollow      = true;  // [v1.13] age chart az candle-e akhar dur shod (Auto Scroll khamoosh shode), ba'd az bi-harakati chart khodkar be akharin candle bar-migarde
input int    InpChartFollowIdleSec   = 20;    // [v1.13] chand sanie bi-harakati (mouse/keyboard rooye chart) ghabl az bargasht-e khodkar
input bool   InpResetZonesFromInputs = false; // false: zone-haye zakhire-shode (panel) ba restart/avaz-e timeframe bargozari mishan va InpBuy/SellZoneLevels faghat avalin bar estefade mishe; true: hamishe az vorudi-ha
input int    InpSignalRetrySeconds   = 60;    // [v1.17] age tayidiye peida shod ama vorud be dalil-e mowaghati anjam nashod (spread bala, ertebat ghat, requote, bazar baste...), ta chand sanie har 1 sanie dobare talash beshe (faghat halat-e AUTO). 0 = ghair-faal (raftar-e ghabli: signal soukhte mishe)
input bool   InpAllowSecondInstance  = false; // [v1.17] false: rooye har symbol faghat ye chart mitoone in EA ro dashte bashe (zone-ha, halat va joft-haye baz moshtarek-e symbol hastan); chart-e dovom ba payam-e khata start nemishe. true: in mohafez ro khamoosh mikone (pishnahad nemishe)

input group "=== 10) Candle Timer (tayemar-e candle) ==="
input bool             InpTimerEnable         = true;                 // [v1.18] namayesh-e tayemar-e candle (zaman-e baghi-mande ta baste shodan-e candle) mesl-e TradingView. Dar Strategy Tester ghair-faal
input string           InpTimerFrames         = "M1,M5,M15,M30,H1,H4,D1,W1,MN1"; // [v1.18] timeframe-haye jadval, ba comma jodaa: M1 M2 M3 M4 M5 M6 M10 M12 M15 M20 M30 H1 H2 H3 H4 H6 H8 H12 D1 W1 MN1. Khali = faghat tag-e kenar-e gheimat
input ENUM_BASE_CORNER InpTimerCorner        = CORNER_RIGHT_UPPER;   // [v1.18] goosheh-ye jadval (panel-e EA bala-chap-e)
input int              InpTimerX              = 12;                   // [v1.18] fasele az lab-e chap/rast (pixel)
input int              InpTimerY              = 28;                   // [v1.18] fasele az lab-e bala/paeen (pixel)
input int              InpTimerFontSize       = 9;                    // [v1.18] andaze-ye font (6 ta 24)
input color            InpTimerCurrentColor   = clrDodgerBlue;        // [v1.18] rang-e satr-e timeframe-e chart (ba "<" ham moshakhas mishe)
input color            InpTimerWarnColor      = clrOrangeRed;         // [v1.18] rang-e hoshdar dar sanie-haye akhar-e candle
input int              InpTimerWarnSeconds    = 10;                   // [v1.18] dar chand sanie-ye akhar-e candle rang-e hoshdar beshe (0 = ghair-faal). M1 hoshdar nemide
input bool             InpTimerShowBackground = false;                // [v1.18] zamine-ye jadval (rang-e zamine-ye chart) - ghabl az in zir-e jadval candle-ha did-e mishan
input bool             InpTimerPriceTag       = true;                 // [v1.18] tag-e kochik kenar-e gheimat-e jari ba tayemar-e timeframe-e chart (mesl-e TradingView)
input int              InpTimerOffsetSec      = 0;                    // [v1.18] tanzim-e dasti-ye zaman (sanie, mitoone manfi bashe) age tayemar ba baste shodan-e vaghei-ye candle fargh dasht

//+------------------------------------------------------------------+
//| 11) [v1.20] Filter-e Zaman / Rooz / Session (Filters.mqh)          |
//+------------------------------------------------------------------+
input group "=== 11) Filter: Time / Days / Sessions ==="
input bool            InpUseTimeFilter    = false;             // filter-e saat va rooz-haye hafte
input ENUM_TIME_BASIS InpFilterTimeBasis  = TIMEBASIS_SERVER;  // mabna-ye zaman baraye hame-ye filter-haye zamani
input string          InpTradeStartTime   = "00:00";           // shoroo-e saat-e mojaz (HH:MM) - age shoroo > payan, baze az nime-shab ham mishe
input string          InpTradeEndTime     = "23:59";           // payan-e saat-e mojaz (HH:MM)
input bool            InpTradeSunday      = true;              // moamele dar yekshanbe
input bool            InpTradeMonday      = true;              // moamele dar doshanbe
input bool            InpTradeTuesday     = true;              // moamele dar seshanbe
input bool            InpTradeWednesday   = true;              // moamele dar charshanbe
input bool            InpTradeThursday    = true;              // moamele dar panjshanbe
input bool            InpTradeFriday      = true;              // moamele dar jom'e
input bool            InpUseSessionFilter = false;             // faghat dar session-haye entekhab-shode vared besho
input bool            InpSessionAsia      = false;             // session-e Asia
input string          InpSessionAsiaTime  = "00:00-09:00";     // saat-e session-e Asia (HH:MM-HH:MM, bar asas-e mabna-ye zaman)
input bool            InpSessionLondon    = true;              // session-e London
input string          InpSessionLondonTime = "08:00-17:00";    // saat-e session-e London
input bool            InpSessionNewYork   = true;              // session-e New York
input string          InpSessionNewYorkTime = "13:00-22:00";   // saat-e session-e New York
input bool            InpFridayCutoffEnable = false;           // jom'e ba'd az saat-e zir vorud-e jadid nadashte bash
input string          InpFridayCutoffTime = "20:00";           // saat-e cut-off-e jom'e (HH:MM)
input bool            InpFridayCloseAll   = false;             // jom'e dar saat-e zir hame-ye moamele-haye EA baste beshan
input string          InpFridayCloseTime  = "22:00";           // saat-e bastan-e hame-ye moamele-ha dar jom'e (HH:MM)

//+------------------------------------------------------------------+
//| 12) [v1.20] Filter-e Khabar (Filters.mqh)                          |
//+------------------------------------------------------------------+
input group "=== 12) Filter: News ==="
input bool                 InpUseNewsFilter    = false;        // dar nazdiki-ye khabar vorud-e jadid nadashte bash
input ENUM_NEWS_SOURCE     InpNewsSource       = NEWS_MANUAL;  // manba-ye khabar
input string               InpNewsManualTimes  = "";           // list-e dasti: '2026.10.21 17:30; 2026.10.28 21:00' (ba mabna-ye zaman-e bala)
input string               InpNewsCurrencies   = "USD";        // [Calendar] arz-haye morede-nazar, ba virgool (khali = arz-haye khod-e symbol)
input ENUM_NEWS_IMPORTANCE InpNewsMinImportance = NEWSIMP_HIGH; // [Calendar] hadeaghal ahamiat-e khabar
input int                  InpNewsMinutesBefore = 15;          // chand daghighe ghabl az khabar
input int                  InpNewsMinutesAfter  = 15;          // chand daghighe ba'd az khabar

//+------------------------------------------------------------------+
//| 13) [v1.20] Filter-e Bazar: Nosan / Rovand / Spread (Filters.mqh)  |
//+------------------------------------------------------------------+
input group "=== 13) Filter: Volatility / Trend / Spread ==="
input bool            InpUseVolatilityFilter = false;          // filter-e nosan bar asas-e ATR
input double          InpVolMinAtrPips    = 0.0;               // hadeaghal ATR (pip) (0 = ghair-faal)
input double          InpVolMaxAtrPips    = 0.0;               // hadeaksar ATR (pip) (0 = ghair-faal)
input ENUM_TREND_MODE InpTrendMode        = TREND_OFF;         // filter-e rovand ba Moving Average-e timeframe-e bala-tar
input ENUM_TIMEFRAMES InpTrendTimeframe   = PERIOD_H4;         // timeframe-e Moving Average
input int             InpTrendMaPeriod    = 50;                // dore-ye Moving Average
input ENUM_MA_METHOD  InpTrendMaMethod    = MODE_EMA;          // noe-e Moving Average
input double          InpMaxSpreadPercentOfSL = 0.0;           // age spread bishtar az in darsad-e fasele-ye SL bood vorud radd (0 = ghair-faal; pishnahad 5)
input bool            InpFiltersApplyToSemiAuto = false;       // filter-ha dar halat-e nim-automatic ham ejbari bashan (false = faghat hoshdar)

//+------------------------------------------------------------------+
//| 14) [v1.20] Mohafez-e Hesab (AccountGuard.mqh + RiskManager.mqh)   |
//+------------------------------------------------------------------+
input group "=== 14) Account Protection ==="
input ENUM_RISK_BASE  InpRiskBase         = RISKBASE_BALANCE;  // darsad-e risk az balance hesab mishe ya equity
input double          InpMinTotalLot      = 0.0;               // hadeaghal hajm-e kol-e vorud (0 = hadeaghal-e broker)
input double          InpMaxTotalLot      = 0.0;               // hadeaksar hajm-e kol-e vorud (0 = bedoone sagf)
input int             InpMaxEntriesPerDay = 0;                 // hadeaksar tedad-e vorud dar rooz (0 = ghair-faal)
input double          InpMaxWeeklyLossPercent = 0.0;           // hadd-e zarar-e hafteghi (darsad-e balance-e aval-e hafte) (0 = ghair-faal)
input int             InpMaxConsecutiveLosses = 0;             // ba'd az in tedad joft-moamele-ye zarar-e motevali vorud motevaghef beshe (0 = ghair-faal)
input int             InpConsecLossPauseHours = 24;            // moddat-e tavaghof ba'd az zarar-haye motevali (saat) (0 = ta shoroo-e rooz-e ba'd)
input int             InpMinMinutesBetweenEntries = 0;         // hadeaghal fasele-ye zamani bein-e do vorud (daghighe) (0 = ghair-faal)
input double          InpMaxEquityDrawdownPercent = 0.0;       // hadd-e afat-e equity az ghole-ye khodash (darsad) (0 = ghair-faal)
input int             InpDrawdownPauseHours = 0;               // tavaghof ba'd az afat (saat) (0 = ta zamani ke InpResetGuardOnStart ya reset-e dasti)
input bool            InpDrawdownCloseAll = false;             // ba'd az afat hame-ye moamele-haye EA baste beshan
input double          InpMinMarginLevelPercent = 0.0;          // age Margin Level kamtar az in bood vorud nakon (0 = ghair-faal)
input bool            InpResetGuardOnStart = false;            // ghole-ye equity va tavaghof-haye mohafez ba start-e EA reset beshe (baad az start false konid)

//+------------------------------------------------------------------+
//| 15) [v1.20] Notification (Notifier.mqh)                            |
//+------------------------------------------------------------------+
input group "=== 15) Notifications ==="
input bool   InpNotifyPopup       = true;    // Alert (popup + seda) rooye MetaTrader
input bool   InpNotifyPush        = false;   // Push be mobile (niaz be MetaQuotes ID dar Tools > Options > Notifications)
input bool   InpNotifyEmail       = false;   // Email (niaz be tanzim-e email dar Tools > Options > Email)
input bool   InpNotifyOnSignal    = true;    // signal-e tayidiye (halat-e nim-automatic) - ba InpSemiAutoAlert ham ham-khani dare
input bool   InpNotifyOnEntry     = false;   // baz shodan-e moamele
input bool   InpNotifyOnClose     = false;   // baste shodan-e moamele (sood/zarar)
input bool   InpNotifyOnGuard     = true;    // radd shodan-e vorud tavassot-e mohafez/filter va hoshdar-haye risk

//+------------------------------------------------------------------+
//| 16) [v1.20] Log va Gozaresh (Notifier.mqh)                         |
//+------------------------------------------------------------------+
input group "=== 16) Logging ==="
input bool   InpCsvLogEnable      = true;    // zakhire-ye har deal dar file-e CSV (MQL5/Files/MagicKeysEA_<symbol>_<hesab>.csv)
input bool   InpLogFilterRejects  = true;    // dar Experts log neshoon bede chera ye vorud radd shod

//+------------------------------------------------------------------+
//| 17) [v1.20] Zahar-e Panel va Zone-ha (Panel.mqh)                   |
//+------------------------------------------------------------------+
input group "=== 17) Appearance (Zone / Panel Colors) ==="
input color  InpColBuyWaiting     = C'35,120,70';     // zone-e Kharid - montazer-e gheimat
input color  InpColBuyArmed       = C'95,195,95';     // zone-e Kharid - gheimat vared shode
input color  InpColBuyDone        = C'55,85,60';      // zone-e Kharid - tayid shod
input color  InpColSellWaiting    = C'160,55,55';     // zone-e Forush - montazer-e gheimat
input color  InpColSellArmed      = C'225,110,95';    // zone-e Forush - gheimat vared shode
input color  InpColSellDone       = C'100,60,60';     // zone-e Forush - tayid shod
input color  InpColZoneInvalid    = C'85,85,85';      // zone-e namotabar
input color  InpColModeAuto       = C'45,95,160';     // dokme-ye AUTO (faal)
input color  InpColModeSemi       = C'0,115,135';     // dokme-ye NIM-AUTO (faal)
input color  InpColModeManual     = C'160,105,20';    // dokme-ye DASTI (faal)

//+------------------------------------------------------------------+
//| Tabe'-haye komaki-e moshtarek (ghablan dar chand file tekrar      |
//| shode bood)                                                        |
//+------------------------------------------------------------------+

//--- andaze-ye 1 pip be gheimat
double MKPipSize(const string symbol)
  {
   double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   if(InpPointsPerPip > 0)
      return point * InpPointsPerPip;

   return (digits == 3 || digits == 5) ? point * 10.0 : point;
  }

//--- magic-e Moamele 1 (leg = 1) va Moamele 2 (leg = 2)
ulong MKMagic(const int leg)
  {
   return (ulong)MathMax(0, InpMagicBase) + (ulong)leg;
  }

//--- Round kardan-e hajm be gam/hadeaghal/hadeaksar-e broker. [Bug Fix v1.11]: ghablan MathFloor(volume/step)
//--- bedoone epsilon bood va ba khata-ye ashari (masalan 0.3/0.1 = 2.9999...) ye gam kam mikard
double MKNormalizeVolume(const string symbol, const double volume)
  {
   double volMin  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double volMax  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   if(volStep <= 0.0)
      return volMin;

   double steps      = MathFloor(volume / volStep + 1e-8);
   double normalized = steps * volStep;

   normalized = MathMax(normalized, volMin);
   normalized = MathMin(normalized, volMax);

   //--- tedad-e raghm-e ashar az roye gam-e hajm (0.01 -> 2, 0.001 -> 3, 0.1 -> 1)
   int    lotDigits = 0;
   double probe     = volStep;
   while(lotDigits < 8 && MathAbs(probe - MathRound(probe)) > 1e-9)
     {
      probe *= 10.0;
      lotDigits++;
     }

   return NormalizeDouble(normalized, lotDigits);
  }

//+------------------------------------------------------------------+
//| [v1.20] Tabe'-haye komaki-e jadid (filter-ha, ATR, zaman)          |
//+------------------------------------------------------------------+

//--- "HH:MM" -> daghighe az nime-shab (def agar format eshtebah bood)
int MKParseHHMM(string text, const int def)
  {
   StringTrimLeft(text);
   StringTrimRight(text);

   int pos = StringFind(text, ":");
   if(pos < 1)
      return def;

   int hh = (int)StringToInteger(StringSubstr(text, 0, pos));
   int mm = (int)StringToInteger(StringSubstr(text, pos + 1));

   if(hh < 0 || hh > 24 || mm < 0 || mm > 59)
      return def;

   return MathMin(hh * 60 + mm, 1439);
  }

//--- "HH:MM-HH:MM" -> do daghighe az nime-shab
bool MKParseRange(string text, int &startMin, int &endMin)
  {
   int pos = StringFind(text, "-");
   if(pos < 1)
      return false;

   startMin = MKParseHHMM(StringSubstr(text, 0, pos), -1);
   endMin   = MKParseHHMM(StringSubstr(text, pos + 1), -1);

   return (startMin >= 0 && endMin >= 0);
  }

//--- aya daghighe-ye jari dar baze [a, b] hast? (age a > b baze az nime-shab ubur mikone; a == b = kol-e rooz)
bool MKInWindow(const int nowMin, const int a, const int b)
  {
   if(a == b)
      return true;
   if(a < b)
      return (nowMin >= a && nowMin <= b);
   return (nowMin >= a || nowMin <= b);
  }

//--- zaman bar asas-e mabna-ye entekhab-shode (server / computer / GMT)
datetime MKBasisTime()
  {
   if(InpFilterTimeBasis == TIMEBASIS_LOCAL)
      return TimeLocal();
   if(InpFilterTimeBasis == TIMEBASIS_GMT)
      return TimeGMT();
   return TimeCurrent();
  }

//--- mabna-ye mohasebe-ye risk: balance ya equity
double MKRiskBaseAmount()
  {
   return (InpRiskBase == RISKBASE_EQUITY) ? AccountInfoDouble(ACCOUNT_EQUITY) : AccountInfoDouble(ACCOUNT_BALANCE);
  }

//--- aval-e hafte (doshanbe 00:00 be vaght-e server)
datetime MKWeekStart(const datetime now)
  {
   MqlDateTime dt;
   TimeToStruct(now, dt);
   datetime dayStart = now - (now % 86400);
   int daysSinceMonday = (dt.day_of_week + 6) % 7;
   return dayStart - (datetime)(daysSinceMonday * 86400);
  }


#endif // __MAGICKEYS_SETTINGS_MQH__
//+------------------------------------------------------------------+
