//+------------------------------------------------------------------+
//|                                                  ZoneManager.mqh |
//|  ZoneManager.mqh - Noghat/Manategh-e Vorud (Entry Zones)          |
//|                                                                    |
//|  Mantegh:                                                         |
//|  1) Har zone ye JAHAT dare: BUY (faghat signal-e Kharid) ya SELL  |
//|     (faghat signal-e Forush). Zone-e Kharid hargez signal-e       |
//|     Forush nemide va bar aks                                       |
//|  2) Vaghti gheimat vared-e zone beshe, module shoroe be rasad-e   |
//|     candle-ha mikone - az candle-i ke gheimat tooosh vared shode  |
//|  3) Candle-e tayidiye bayad in sharayet ro dashte bashe:           |
//|      a) pattern-e Doji/Pinbar/Engulfing ba jahat-e zone yeki bashe |
//|      b) candle be zone bokhore                                     |
//|      c) candle "afghar"-e harekat bashe: dar zone-e Sell bala-    |
//|         tarin candle-e ba'd az vorud (ya ba tolerance-e kam        |
//|         hamsath-e oon), dar zone-e Buy paiin-tarin candle          |
//|  4) Zone faghat baraye avalin bazdid mo'tabare: age ye candle      |
//|     biroon-e zone baste beshe (gheimat az zone kharej shode) va    |
//|     ba'd gheimat doobare be zone bargarde, zone namotabar mishe    |
//|  5) Age InpZoneMaxConfirmCandles candle bedoone tayidiye bogzare,  |
//|     zone namotabar mishe                                           |
//|  6) Zone-ha ro mishe tak-be-tak virayesh (UpdateZone/              |
//|     UpdateZoneRange) ya pak kard (RemoveZone); virayesh vaziat-e  |
//|     zone ro sefr mikone                                             |
//|  7) Chand zone hamzaman mitoonan faal bashan; har kodoom mostaghel |
//|                                                                    |
//|  Vabastegi: az CCandleAnalyzer baraye tashkhis-e candle estefade   |
//|  mikone, va az EntryConfirmation.mqh faghat baraye estefade-ye     |
//|  moshtarak-e enum-e signal (ENUM_ENTRY_SIGNAL)                     |
//+------------------------------------------------------------------+
#property strict

#include "Settings.mqh"
#include "EntryConfirmation.mqh"

//--- jahat-e zone: zone-e Kharid faghat signal-e Buy, zone-e Forush faghat signal-e Sell mide
enum ENUM_ZONE_DIRECTION
  {
   ZONE_BUY,    // zone-e Kharid
   ZONE_SELL    // zone-e Forush
  };

//--- vaziat-e zone (baraye namayesh dar Panel)
enum ENUM_ZONE_STATE
  {
   ZONE_STATE_WAITING,    // gheimat hanooz be zone naresideh
   ZONE_STATE_ARMED,      // gheimat vared shode, montazer-e candle-e tayidiye
   ZONE_STATE_TRIGGERED,  // tayidiye peida shod va signal sader shod
   ZONE_STATE_INVALID     // namotabar (bargasht ba'd az kharej shodan ya zaman-e tayidiye tamoom shod)
  };

//+------------------------------------------------------------------+
//| Sakhtar-e ye noghte/mantaghe-ye vorud                             |
//+------------------------------------------------------------------+
struct SEntryZone
  {
   double   priceLow;           // kaf-e mantaghe (baraye noghte-ye taki = adad manha tolerance)
   double   priceHigh;          // saghf-e mantaghe (baraye noghte-ye taki = adad be'lave tolerance)
   string   label;              // esm-e zone baraye log
   ENUM_ZONE_DIRECTION direction; // Buy ya Sell
   bool     isSingle;           // aya be soorat-e adad-e taki vared shode (na baze)?
   double   rawPrice;           // adad-e taki-e vared-shode (faghat vaghti isSingle = true)
   bool     priceReached;       // aya gheimat vared-e zone shode (avalin bazdid)?
   bool     priceExited;        // aya ba'd az vorud, ye candle biroon-e zone baste shode?
   bool     invalid;            // aya zone namotabar shode?
   bool     triggered;          // aya candle-e tayidiye peida shode va signal sader shode?
   bool     consumed;           // aya signal tavassot-e EA-ye asli masraf shode?
   ENUM_ENTRY_SIGNAL signal;    // jahat-e signal-e sader-shode
   datetime entryCandleTime;    // zaman-e baz shodan-e candle-i ke gheimat tooosh vared-e zone shode
   datetime lastCheckedCandle;  // akharin candle-i ke baraye in zone check shode
   datetime scanFrom;           // [v1.19] avalin candle-i ke range-e (High/Low)-esh baraye lams-e zone hesab mishe (candle-e sakhte shodan/virayesh-e zone)
   int      candlesSinceArmed;  // chand candle ba'd az vorud check shode
   double   confirmHigh;        // High-e candle-e tayidiye (baraye TradeManager)
   double   confirmLow;         // Low-e candle-e tayidiye (baraye TradeManager)
  };

//+------------------------------------------------------------------+
//| Class Modiriat-e Noghat/Manategh-e Vorud                          |
//+------------------------------------------------------------------+
class CZoneManager
  {
private:
   CCandleAnalyzer m_candleAnalyzer;
   string          m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   int             m_digits;
   double          m_pipSize;
   int             m_zoneSeq;
   SEntryZone      m_zones[];
   bool            m_loading;   // [v1.11] dar hin-e bargozari az file: zakhire-ye tekrari nakon
   bool            m_dirty;     // [v1.11] vaziat-e ye zone avaz shode (tayid / namotabar) - akhar-e CheckZones zakhire mishe

public:
   void Init(string symbol, ENUM_TIMEFRAMES timeframe)
     {
      m_symbol    = symbol;
      m_timeframe = timeframe;
      m_candleAnalyzer.Init(symbol, timeframe);

      m_digits  = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      m_pipSize = MKPipSize(m_symbol);

      m_zoneSeq = 0;
      m_loading = false;
      m_dirty   = false;
      ArrayResize(m_zones, 0);
     }

   //+------------------------------------------------------------------+
   //| Ezafe kardan-e ye noghte-ye tak-adadi (masalan 4321 dar Gold).   |
   //| Be tor-e khodkar ye tolerance-e koochik dorash dar nazar gerefte  |
   //| mishe chon residan-e daghigh-e gheimat be ye adad-e sahih         |
   //| taghriban gheyre-momken ast                                       |
   //+------------------------------------------------------------------+
   void AddZone(double price, ENUM_ZONE_DIRECTION direction, string label = "")
     {
      double tolerance = InpZoneTolerancePips * m_pipSize;
      AddZoneInternal(price - tolerance, price + tolerance, direction, label, true, price);
     }

   //+------------------------------------------------------------------+
   //| Ezafe kardan-e ye mantaghe/baze-ye gheimati (masalan 4334 ta      |
   //| 4336)                                                              |
   //+------------------------------------------------------------------+
   void AddZoneRange(double priceLow, double priceHigh, ENUM_ZONE_DIRECTION direction, string label = "")
     {
      AddZoneInternal(priceLow, priceHigh, direction, label, false, 0.0);
     }

   //+------------------------------------------------------------------+
   //| Virayesh-e ye zone-e mojood (jahatesh avaz nemishe). Vaziat-e     |
   //| zone kamelan sefr mishe (mesl-e ye zone-e jadid)                  |
   //+------------------------------------------------------------------+
   bool UpdateZone(int index, double price)
     {
      if(index < 0 || index >= ArraySize(m_zones))
         return false;

      double tolerance = InpZoneTolerancePips * m_pipSize;
      ApplyZoneValues(index, price - tolerance, price + tolerance, true, price);
      return true;
     }

   bool UpdateZoneRange(int index, double priceLow, double priceHigh)
     {
      if(index < 0 || index >= ArraySize(m_zones))
         return false;

      ApplyZoneValues(index, priceLow, priceHigh, false, 0.0);
      return true;
     }

   //+------------------------------------------------------------------+
   //| Pak kardan-e ye zone (index-e zone-haye ba'd-esh yeki kam mishe)  |
   //+------------------------------------------------------------------+
   bool RemoveZone(int index)
     {
      int n = ArraySize(m_zones);
      if(index < 0 || index >= n)
         return false;

      string removedLabel = m_zones[index].label;

      for(int k = index; k < n - 1; k++)
         m_zones[k] = m_zones[k + 1];

      ArrayResize(m_zones, n - 1);

      Print("ZoneManager: zone [", removedLabel, "] pak shod.");
      SaveZones();
      return true;
     }

   //+------------------------------------------------------------------+
   //| Pak kardan-e hame-ye zone-ha                                      |
   //+------------------------------------------------------------------+
   void ClearZones()
     {
      ArrayResize(m_zones, 0);
      Print("ZoneManager: hameye zone-ha pak shodan.");
      SaveZones();
     }

   //+------------------------------------------------------------------+
   //| [v1.11] Zakhire/bargozari-ye zone-ha dar file (MQL5/Files). Ghablan|
   //| zone-haye ezafe-shode ba panel ba avaz-e timeframe / restart /     |
   //| compile az bein miraftan (faghat vorudi-haye EA bargozari mishod). |
   //| Vaziat-e tayid-shode / namotabar ham zakhire mishe ta zone-i ke    |
   //| ghablan moamele dade dobare moamele nade. Dar Strategy Tester     |
   //| zakhire/bargozari anjam nemishe.                                    |
   //| Format-e har khat (#MKZ2): jahat|isSingle|low|high|raw|vaziat|     |
   //|   armed|exited|entryTime|lastChecked|candles|timeframe|label        |
   //| (vaziat: 0 = jari, 1 = namotabar, 2 = tayid-shode)                  |
   //| [v1.17] vaziat-e "montazer-e tayidiye" (armed) ham zakhire mishe:   |
   //| ba restart / avaz-e timeframe zone-i ke gheimat vared-eshe va       |
   //| montazer-e candle-e tayidiye bood, dobare az avval shoroe nemishe.  |
   //| File-haye ghadimi (#MKZ1) hanooz khoonde mishan                      |
   //+------------------------------------------------------------------+
   bool PersistenceEnabled()
     {
      return (MQLInfoInteger(MQL_TESTER) == 0 && MQLInfoInteger(MQL_OPTIMIZATION) == 0);
     }

   string StorageName()
     {
      return "MagicKeysEA_Zones_" + m_symbol + ".txt";
     }

   void SaveZones()
     {
      if(m_loading || !PersistenceEnabled())
         return;

      int h = FileOpen(StorageName(), FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(h == INVALID_HANDLE)
        {
         Print("ZoneManager: khata dar zakhire-ye zone-ha (", StorageName(), ") - code: ", GetLastError());
         return;
        }

      FileWriteString(h, "#MKZ2\r\n");

      for(int i = 0; i < ArraySize(m_zones); i++)
        {
         int st = m_zones[i].triggered ? 2 : (m_zones[i].invalid ? 1 : 0);

         //--- [v1.17] faghat zone-e hanooz-jari-ye ke gheimat vared-eshe (montazer-e tayidiye) "armed" zakhire mishe
         bool armed = (st == 0 && m_zones[i].priceReached);

         string line = IntegerToString((int)m_zones[i].direction) + "|" +
                       (m_zones[i].isSingle ? "1" : "0") + "|" +
                       DoubleToString(m_zones[i].priceLow, 8) + "|" +
                       DoubleToString(m_zones[i].priceHigh, 8) + "|" +
                       DoubleToString(m_zones[i].rawPrice, 8) + "|" +
                       IntegerToString(st) + "|" +
                       (armed ? "1" : "0") + "|" +
                       ((armed && m_zones[i].priceExited) ? "1" : "0") + "|" +
                       IntegerToString(armed ? (long)m_zones[i].entryCandleTime : (long)0) + "|" +
                       IntegerToString(armed ? (long)m_zones[i].lastCheckedCandle : (long)0) + "|" +
                       IntegerToString(armed ? m_zones[i].candlesSinceArmed : 0) + "|" +
                       IntegerToString((int)ResolvedTimeframe()) + "|" +
                       m_zones[i].label;

         FileWriteString(h, line + "\r\n");
        }

      FileClose(h);
     }

   //--- true = file-e zakhire vojood dasht va bargozari shod (hata age 0 zone dashte bashe); false = file nabood
   bool LoadZones()
     {
      if(!PersistenceEnabled() || !FileIsExist(StorageName()))
         return false;

      int h = FileOpen(StorageName(), FILE_READ | FILE_TXT | FILE_ANSI);
      if(h == INVALID_HANDLE)
        {
         Print("ZoneManager: khata dar khoondan-e file-e zone-ha (", StorageName(), ") - code: ", GetLastError());
         return false;
        }

      m_loading = true;
      bool headerOk = false;
      int  loaded   = 0;
      int  version  = 1;   // [v1.17] 1 = #MKZ1 (ghadimi), 2 = #MKZ2 (ba vaziat-e armed)

      while(!FileIsEnding(h))
        {
         string line = FileReadString(h);
         StringTrimLeft(line);
         StringTrimRight(line);

         if(StringLen(line) == 0)
            continue;

         if(line == "#MKZ1" || line == "#MKZ2")
           {
            headerOk = true;
            version  = (line == "#MKZ2") ? 2 : 1;
            continue;
           }

         if(!headerOk)
            continue;

         int need = (version >= 2) ? 13 : 7;   // [v1.17]
         string p[];
         if(StringSplit(line, '|', p) < need)
            continue;

         ENUM_ZONE_DIRECTION dir = ((int)StringToInteger(p[0]) == (int)ZONE_SELL) ? ZONE_SELL : ZONE_BUY;
         bool   single = ((int)StringToInteger(p[1]) == 1);
         double low    = StringToDouble(p[2]);
         double high   = StringToDouble(p[3]);
         double raw    = StringToDouble(p[4]);
         int    st     = (int)StringToInteger(p[5]);

         if(low <= 0.0 || high <= 0.0)
            continue;

         string zoneLabel = (version >= 2) ? p[12] : p[6];
         AddZoneInternal(low, high, dir, zoneLabel, single, raw);

         int n = ArraySize(m_zones) - 1;
         if(st == 2)
           {
            m_zones[n].triggered = true;
            m_zones[n].consumed  = true;   // ghablan masraf shode - dobare moamele nadeh
            m_zones[n].signal    = (dir == ZONE_BUY) ? ENTRY_BUY : ENTRY_SELL;
           }
         else if(st == 1)
            m_zones[n].invalid = true;
         else if(version >= 2 && (int)StringToInteger(p[6]) == 1)
            RestoreArmedState(n, ((int)StringToInteger(p[7]) == 1), (datetime)StringToInteger(p[8]),
                              (datetime)StringToInteger(p[9]), (int)StringToInteger(p[10]), (int)StringToInteger(p[11]));

         loaded++;
        }

      FileClose(h);
      m_loading = false;

      if(!headerOk)
         return false;

      //--- [v1.17] shomare-ye zone-e jadid bayad az bozorg-tarin shomare-ye mojood bishtar bashe (na faghat tedad-e zone-ha),
      //--- vagarna ba'd az pak kardan-e ye zone-e vasati va restart momkene esm-e tekrari (masalan do ta Buy-3) sakhte beshe
      int maxSeq = ArraySize(m_zones);
      for(int z = 0; z < ArraySize(m_zones); z++)
         maxSeq = MathMax(maxSeq, LabelSuffix(m_zones[z].label));
      m_zoneSeq = maxSeq;

      Print("ZoneManager: ", loaded, " zone az file-e zakhire bargozari shod (", StorageName(), ").");
      return true;
     }

   int Count()
     {
      return ArraySize(m_zones);
     }

   //+------------------------------------------------------------------+
   //| Khoondan-e ye "aks-e lahzeie" (snapshot) az vaziat-e ye zone bar  |
   //| asas-e index - baraye namayesh dar Panel.mqh. Age index na-      |
   //| motabar bashe false bar migardoone                                |
   //+------------------------------------------------------------------+
   bool GetZoneSnapshot(int index, double &priceLow, double &priceHigh, string &label,
                        ENUM_ZONE_DIRECTION &direction, ENUM_ZONE_STATE &state)
     {
      if(index < 0 || index >= ArraySize(m_zones))
         return false;

      priceLow  = m_zones[index].priceLow;
      priceHigh = m_zones[index].priceHigh;
      label     = m_zones[index].label;
      direction = m_zones[index].direction;

      if(m_zones[index].triggered)
         state = ZONE_STATE_TRIGGERED;
      else if(m_zones[index].invalid)
         state = ZONE_STATE_INVALID;
      else if(m_zones[index].priceReached)
         state = ZONE_STATE_ARMED;
      else
         state = ZONE_STATE_WAITING;

      return true;
     }

   //+------------------------------------------------------------------+
   //| Matn-e zone be hamoon shekli ke karbar vared karde (masalan       |
   //| "4321" ya "4334-4336") - baraye virayesh dar Panel                |
   //+------------------------------------------------------------------+
   string GetZoneText(int index)
     {
      if(index < 0 || index >= ArraySize(m_zones))
         return "";

      if(m_zones[index].isSingle)
         return DoubleToString(m_zones[index].rawPrice, m_digits);

      return DoubleToString(m_zones[index].priceLow, m_digits) + "-" + DoubleToString(m_zones[index].priceHigh, m_digits);
     }

   //+------------------------------------------------------------------+
   //| Bayad har tick az OnTick-e asli-e EA seda zade beshe.            |
   //| Baraye har zone-e hanooz-mo'tabar:                                 |
   //| 1) Age gheimat ghablan vared shode, akharin candle-e baste-shode  |
   //|    ro baraye tayidiye check mikone (faghat candle-haye az candle-e|
   //|    vorud be ba'd)                                                  |
   //| 2) Mogheiat-e lahzeie gheimat ro check mikone: avalin vorud ro    |
   //|    sabt mikone; age ba'd az kharej shodan (candle-e baste-shode   |
   //|    biroon-e zone) gheimat doobare vared beshe, zone namotabar mishe|
   //+------------------------------------------------------------------+
   void CheckZones()
     {
      //--- candle-ha bar asas-e Bid keshide mishan, pas vorud/bazgasht ham bar asas-e Bid check mishe
      //--- (ta spread baese-ye bazgasht-e kazeb nashe)
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);

      //--- [v1.19] zaman-e candle-e jari va akharin candle-e baste-shode (baraye lams az rooye range-e candle)
      datetime bar0Time    = CurrentBarTime();
      datetime candle1Time = iTime(m_symbol, m_timeframe, 1);

      for(int i = 0; i < ArraySize(m_zones); i++)
        {
         if(m_zones[i].triggered || m_zones[i].invalid)
            continue;

         //--- 1) candle-e baste-shode (faghat vaghti gheimat ghablan vared-e zone shode).
         //--- in ghabl az barresi-ye gheimat-e in tick anjam mishe, ta candle-i ke ghabl az
         //--- bazgasht-e gheimat baste shode, ba bazgasht-e in tick namotabar nashe
         if(m_zones[i].priceReached)
           {
            EvaluateClosedCandle(m_zones[i]);

            if(m_zones[i].triggered || m_zones[i].invalid)
               continue;
           }

         //--- 2) mogheiat-e lahzeie gheimat (bid dakhel-e zone)
         bool insideNow = (bid >= m_zones[i].priceLow && bid <= m_zones[i].priceHigh);

         if(!m_zones[i].priceReached)
           {
            //--- [v1.19] lams-e zone: (1) Bid alan dakhel-e zone ast, ya (2) range-e candle-e jari zone ro poshonde, ya
            //--- (3) range-e candle-e baste-shode-ye ghabli (az zaman-e sakhte shodan-e zone be ba'd) zone ro poshonde
            //--- (2) va (3) baraye vaghti-e ke gheimat bein-e tick-ha az rooye zone parid va tick-e dakhel-e zone nadidim
            datetime entryBar = 0;
            string   how      = "";

            if(insideNow)
               entryBar = bar0Time;
            else if(BarTouchesZone(m_zones[i], 0))
              {
               entryBar = bar0Time;
               how      = " (az rooye range-e candle-e jari: gheimat bein-e tick-ha az zone parid)";
              }
            else if(candle1Time > 0 && candle1Time >= m_zones[i].scanFrom && BarTouchesZone(m_zones[i], 1))
              {
               entryBar = candle1Time;
               how      = " (az rooye range-e candle-e ghabli-ye baste-shode: gheimat bein-e tick-ha az zone parid)";
              }

            if(entryBar > 0)
              {
               m_zones[i].priceReached      = true;
               m_zones[i].priceExited       = false;
               m_zones[i].entryCandleTime   = entryBar;
               m_zones[i].lastCheckedCandle = 0;
               m_zones[i].candlesSinceArmed = 0;
               m_dirty                      = true;   // [v1.17] vaziat-e armed zakhire beshe

               Print("ZoneManager: gheimat vared-e zone-e ", DirectionText(m_zones[i].direction),
                     " [", m_zones[i].label, "] shod", how, ". Rasad-e candle-haye tayidiye shoroe shod.");

               //--- candle-e vorud ghablan baste shode: hamin alan baraye tayidiye barresi mishe
               if(entryBar < bar0Time)
                  EvaluateClosedCandle(m_zones[i]);
              }
           }
         else if(m_zones[i].priceExited && insideNow)
           {
            m_zones[i].invalid = true;
            m_dirty = true;
            Print("ZoneManager: gheimat az zone [", m_zones[i].label,
                  "] kharej shode bood va doobare bargasht - zone namotabar shod.");
           }
        }

      //--- [v1.11] vaziat-e zone-ha (tayid / namotabar) ham zakhire mishe ta ba restart dobare ejra nashan
      if(m_dirty)
        {
         m_dirty = false;
         SaveZones();
        }
     }

   //+------------------------------------------------------------------+
   //| Gereftan-e avalin signal-e trigger-shode-i ke hanooz masraf       |
   //| nashode (tavassot-e EA-ye asli). Ba'd az farakhani, oon zone      |
   //| consumed alamat mikhore ta doobare bargarde nashe. High/Low-e     |
   //| candle-e tayidiye ham bar-gardoonde mishe (baraye SL va sath-e    |
   //| vorud-e marhale-i dar candle-haye bozorg)                          |
   //+------------------------------------------------------------------+
   bool GetNextTriggeredSignal(ENUM_ENTRY_SIGNAL &signal, int &zoneIndex, string &zoneLabel,
                               double &candleHigh, double &candleLow)
     {
      for(int i = 0; i < ArraySize(m_zones); i++)
        {
         if(m_zones[i].triggered && !m_zones[i].consumed)
           {
            signal     = m_zones[i].signal;
            zoneIndex  = i;
            zoneLabel  = m_zones[i].label;
            candleHigh = m_zones[i].confirmHigh;
            candleLow  = m_zones[i].confirmLow;
            m_zones[i].consumed = true;
            return true;
           }
        }
      return false;
     }

private:
   string DirectionText(ENUM_ZONE_DIRECTION direction)
     {
      return (direction == ZONE_BUY) ? "Buy" : "Sell";
     }

   //--- [v1.19] zaman-e baz shodan-e candle-e jari (age iTime nadad, zaman-e server)
   datetime CurrentBarTime()
     {
      datetime t = iTime(m_symbol, m_timeframe, 0);
      return (t > 0) ? t : TimeCurrent();
     }

   //+------------------------------------------------------------------+
   //| [v1.19] Aya range-e (High/Low) candle-e shift zone ro lams karde? |
   //| Dalil: ghablan faghat vaghti Bid dar lahze-ye tick dakhel-e zone    |
   //| bood zone fa'al mishod. Rooye zone-e barik (masalan tak-adadi ba   |
   //| tolerance-e kam) va harekat-e tond (candle-haye bozorg) gheimat     |
   //| mitoone bein-e do tick az rooye zone beporre (ya EA ye tick ro      |
   //| nabine) va hich tick-i dakhel-e zone nayofte, dar halike High/Low-e |
   //| candle zone ro poshonde. Spread ham mesl-e TryConfirm dar nazar    |
   //| gerefte mishe (candle-ha bar asas-e Bid hastan)                     |
   //+------------------------------------------------------------------+
   bool BarTouchesZone(const SEntryZone &zone, const int shift)
     {
      if(!InpZoneUseCandleRangeTouch)
         return false;

      double hi = iHigh(m_symbol, m_timeframe, shift);
      double lo = iLow(m_symbol, m_timeframe, shift);
      if(hi <= 0.0 || lo <= 0.0)
         return false;

      double spread = SymbolInfoDouble(m_symbol, SYMBOL_ASK) - SymbolInfoDouble(m_symbol, SYMBOL_BID);
      if(spread < 0.0)
         spread = 0.0;

      return (hi >= zone.priceLow - spread && lo <= zone.priceHigh + spread);
     }

   //--- [v1.19] khoolase-ye yek candle baraye log: gheimat-ha, range (pip) va darsad-e badaneh / sayeh-ha
   string CandleDesc(const SCandleInfo &c)
     {
      double rangePips = (m_pipSize > 0.0) ? c.totalRange / m_pipSize : 0.0;
      double body      = (c.totalRange > 0.0) ? c.bodySize  / c.totalRange * 100.0 : 0.0;
      double upper     = (c.totalRange > 0.0) ? c.upperWick / c.totalRange * 100.0 : 0.0;
      double lower     = (c.totalRange > 0.0) ? c.lowerWick / c.totalRange * 100.0 : 0.0;

      return "O=" + DoubleToString(c.open, m_digits) + " H=" + DoubleToString(c.high, m_digits) +
             " L=" + DoubleToString(c.low, m_digits) + " C=" + DoubleToString(c.close, m_digits) +
             " | range " + DoubleToString(rangePips, 1) + " pip | badaneh " + DoubleToString(body, 0) +
             "% sayeh-ye bala " + DoubleToString(upper, 0) + "% sayeh-ye paiin " + DoubleToString(lower, 0) + "%";
     }

   //--- [v1.19] matn-e natije-ye Pinbar / Engulfing baraye log (+1 soodi, -1 nozooli, 0 nadarad)
   string PatternSideText(const int v, const bool enabled)
     {
      string s = (v > 0) ? "Soodi" : ((v < 0) ? "Nozooli" : "nadarad");
      return enabled ? s : (s + " (dar tanzimat ghair-faal)");
     }

   //--- [v1.17] timeframe-e vaghei (age InpTimeframe = PERIOD_CURRENT, timeframe-e chart)
   ENUM_TIMEFRAMES ResolvedTimeframe()
     {
      return (m_timeframe == PERIOD_CURRENT) ? (ENUM_TIMEFRAMES)_Period : m_timeframe;
     }

   //--- [v1.17] aya zone-i ba in esm vojood dare?
   bool LabelExists(const string label)
     {
      for(int i = 0; i < ArraySize(m_zones); i++)
         if(m_zones[i].label == label)
            return true;
      return false;
     }

   //--- [v1.17] adad-e akhar-e esm ("Buy-3" -> 3). age khat-e tireh ya adad nabood 0
   int LabelSuffix(const string label)
     {
      int pos  = -1;
      int from = 0;

      while(true)
        {
         int p = StringFind(label, "-", from);
         if(p < 0)
            break;
         pos  = p;
         from = p + 1;
        }

      if(pos < 0)
         return 0;

      return (int)StringToInteger(StringSubstr(label, pos + 1));
     }

   //+------------------------------------------------------------------+
   //| [v1.17] Bargardandan-e vaziat-e "montazer-e tayidiye" (armed) az    |
   //| file. Faghat vaghti bargardoone mishe ke:                          |
   //|  - timeframe hamoon timeframe-e zamane zakhire bashe              |
   //|  - candle-e vorud hanooz dar history peida beshe                  |
   //|  - moddat-e tayidiye (InpZoneMaxConfirmCandles) dar zamani ke EA   |
   //|    khamoosh bood tamoom nashode bashe (vagarna zone namotabar mishe|
   //|    - hamoon natije-ei ke age EA roshan bood migereft)               |
   //| Dar gheir-e in sooratha zone mesl-e ghabl "montazer-e gheimat"    |
   //| mimoone (raftar-e v1.16)                                            |
   //+------------------------------------------------------------------+
   void RestoreArmedState(const int index, const bool exited, const datetime entryTime,
                          const datetime lastChecked, const int candles, const int savedTimeframe)
     {
      if(index < 0 || index >= ArraySize(m_zones))
         return;

      if(entryTime <= 0 || savedTimeframe != (int)ResolvedTimeframe())
         return;

      int entryShift = iBarShift(m_symbol, m_timeframe, entryTime, false);
      if(entryShift < 0)
        {
         Print("ZoneManager: vaziat-e armed-e zone [", m_zones[index].label,
               "] bargozari nashod (history hanooz amade nist) - zone montazer-e gheimat mimoone.");
         return;
        }

      //--- chand candle az candle-e vorud gozashte (0 = hamoon candle-e jari) - ghanoon-e InpZoneMaxConfirmCandles
      if(entryShift > InpZoneMaxConfirmCandles)
        {
         m_zones[index].invalid = true;
         m_dirty                = true;
         Print("ZoneManager: zone [", m_zones[index].label, "] ghabl az restart montazer-e tayidiye bood, vali dar zamani ke EA ",
               "khamoosh bood bishtar az ", InpZoneMaxConfirmCandles, " candle gozasht - namotabar shod.");
         return;
        }

      m_zones[index].priceReached      = true;
      m_zones[index].priceExited       = exited;
      m_zones[index].entryCandleTime   = entryTime;
      m_zones[index].lastCheckedCandle = lastChecked;
      //--- candle-hayi ke dar khamooshi-ye EA baste shodan ham dar moddat-e tayidiye hesab mishan
      m_zones[index].candlesSinceArmed = MathMax(candles, entryShift - 1);

      Print("ZoneManager: vaziat-e zone [", m_zones[index].label, "] az file bargashit: gheimat ghablan vared shode bood, ",
            "montazer-e candle-e tayidiye (", m_zones[index].candlesSinceArmed, " az ", InpZoneMaxConfirmCandles, " candle gozashte).");
     }

   //+------------------------------------------------------------------+
   //| Sefr kardan-e vaziat-e ye zone (baraye zone-e jadid ya virayesh) |
   //+------------------------------------------------------------------+
   void ResetZoneState(SEntryZone &zone)
     {
      zone.priceReached      = false;
      zone.priceExited       = false;
      zone.invalid           = false;
      zone.triggered         = false;
      zone.consumed          = false;
      zone.signal            = ENTRY_NONE;
      zone.entryCandleTime   = 0;
      zone.lastCheckedCandle = 0;
      zone.scanFrom          = CurrentBarTime();   // [v1.19]
      zone.candlesSinceArmed = 0;
      zone.confirmHigh       = 0.0;
      zone.confirmLow        = 0.0;
     }

   void AddZoneInternal(double priceLow, double priceHigh, ENUM_ZONE_DIRECTION direction,
                        string label, bool isSingle, double rawPrice)
     {
      if(priceLow > priceHigh)
        {
         double tmp = priceLow;
         priceLow   = priceHigh;
         priceHigh  = tmp;
        }

      m_zoneSeq++;

      //--- [v1.17] esm-e khodkar: age ghablan hamin esm vojood dasht (masalan ba'd az restart), shomare ro jolo mibarim
      string finalLabel = label;
      if(finalLabel == "")
        {
         finalLabel = DirectionText(direction) + "-" + IntegerToString(m_zoneSeq);
         while(LabelExists(finalLabel))
           {
            m_zoneSeq++;
            finalLabel = DirectionText(direction) + "-" + IntegerToString(m_zoneSeq);
           }
        }

      int n = ArraySize(m_zones);
      ArrayResize(m_zones, n + 1);

      m_zones[n].priceLow  = priceLow;
      m_zones[n].priceHigh = priceHigh;
      m_zones[n].label     = finalLabel;
      m_zones[n].direction = direction;
      m_zones[n].isSingle  = isSingle;
      m_zones[n].rawPrice  = rawPrice;
      ResetZoneState(m_zones[n]);

      Print("ZoneManager: zone-e jadid-e ", DirectionText(direction), " ezafe shod [", m_zones[n].label,
            "] mahdoode: ", DoubleToString(priceLow, m_digits), " ta ", DoubleToString(priceHigh, m_digits));

      SaveZones();
     }

   void ApplyZoneValues(int index, double priceLow, double priceHigh, bool isSingle, double rawPrice)
     {
      if(priceLow > priceHigh)
        {
         double tmp = priceLow;
         priceLow   = priceHigh;
         priceHigh  = tmp;
        }

      m_zones[index].priceLow  = priceLow;
      m_zones[index].priceHigh = priceHigh;
      m_zones[index].isSingle  = isSingle;
      m_zones[index].rawPrice  = rawPrice;
      ResetZoneState(m_zones[index]);

      Print("ZoneManager: zone [", m_zones[index].label, "] virayesh shod: ",
            DoubleToString(priceLow, m_digits), " ta ", DoubleToString(priceHigh, m_digits));

      SaveZones();
     }

   //+------------------------------------------------------------------+
   //| Barresi-ye akharin candle-e baste-shode baraye ye zone-e vared-   |
   //| shode. Har candle faghat yek bar barresi mishe.                   |
   //|  - age tayidiye bood: zone trigger mishe                           |
   //|  - age nabood va candle biroon-e zone baste shode: gheimat az     |
   //|    zone kharej shode (priceExited)                                 |
   //|  - age InpZoneMaxConfirmCandles candle gozashte: zone namotabar   |
   //+------------------------------------------------------------------+
   void EvaluateClosedCandle(SEntryZone &zone)
     {
      SCandleInfo candle;
      if(!m_candleAnalyzer.GetCandle(1, candle)) // akharin candle-e baste-shode
         return;

      //--- candle-haye ghabl az candle-i ke gheimat tooosh vared-e zone shode mohem nistan
      if(candle.time < zone.entryCandleTime)
         return;

      //--- in candle ghablan baraye hamin zone check shode
      if(candle.time == zone.lastCheckedCandle)
         return;
      zone.lastCheckedCandle = candle.time;
      zone.candlesSinceArmed++;
      m_dirty = true;   // [v1.17] shomarande-ye candle-ha ham zakhire mishe (hadeaksar yek bar dar har candle)

      if(TryConfirm(zone, candle))
         return;

      //--- age candle biroon-e zone baste shode, yani gheimat az zone kharej shode
      if(!zone.priceExited && (candle.close < zone.priceLow || candle.close > zone.priceHigh))
        {
         zone.priceExited = true;
         Print("ZoneManager: candle biroon-e zone [", zone.label,
               "] baste shod - agar gheimat doobare be zone bargarde, zone namotabar mishe.");
        }

      if(zone.candlesSinceArmed >= InpZoneMaxConfirmCandles)
        {
         zone.invalid = true;
         m_dirty      = true;
         Print("ZoneManager: zone [", zone.label, "] ba'd az ", InpZoneMaxConfirmCandles,
               " candle hich tayidiye-i nagereft - namotabar shod.");
        }
     }

   //+------------------------------------------------------------------+
   //| Aya in candle tayidiye-ye motabar baraye zone hast? Sharayet:     |
   //|  1) pattern (Doji/Pinbar/Engulfing) ba jahat-e zone yeki bashe    |
   //|  2) candle be zone bokhore                                         |
   //|  3) candle afghar-e harekat bashe (bala-tarin dar Sell /          |
   //|     paiin-tarin dar Buy nesbat be candle-haye ba'd az vorud)      |
   //+------------------------------------------------------------------+
   bool TryConfirm(SEntryZone &zone, const SCandleInfo &candle)
     {
      ENUM_ENTRY_SIGNAL wanted = (zone.direction == ZONE_BUY) ? ENTRY_BUY : ENTRY_SELL;
      ENUM_ENTRY_SIGNAL signal = DetectCandleSignal(wanted);

      //--- [v1.19] har ghazavat ba adad-e candle va dalil-e dagigh log mishe ta moshakhas beshe chera tayidiye gerefte nashod
      string head = "ZoneManager [ghazavat]: zone-e " + DirectionText(zone.direction) + " [" + zone.label + "] | candle " +
                    TimeToString(candle.time, TIME_DATE | TIME_MINUTES) + " | " + CandleDesc(candle) + " -> ";

      if(signal == ENTRY_NONE)
        {
         int  pin  = m_candleAnalyzer.DetectPinbar(1);
         int  eng  = m_candleAnalyzer.DetectEngulfing(1);
         bool doji = (m_candleAnalyzer.DetectPattern(1) == PATTERN_DOJI);

         Print(head, "tayidiye-ye motabar nist | Pinbar: ", PatternSideText(pin, InpZoneUsePinbarConfirmation),
               " | Engulfing: ", PatternSideText(eng, InpZoneUseEngulfingConfirmation),
               " | Doji: ", (doji ? (InpZoneUseDojiConfirmation ? "bale" : "bale (dar tanzimat ghair-faal)") : "kheir"),
               " | zone-e ", DirectionText(zone.direction), " faghat tayidiye-ye ", (wanted == ENTRY_BUY ? "Kharid" : "Forush"), " ghabul mikone");
         return false;
        }

      string signalText = (signal == ENTRY_BUY ? "Kharid (Buy)" : "Forush (Sell)");

      //--- [v1.20] hadeaghal/hadeaksar range-e candle-e tayidiye
      double confirmRangePips = (m_pipSize > 0.0) ? (candle.high - candle.low) / m_pipSize : 0.0;
      if(InpConfirmMinRangePips > 0.0 && confirmRangePips < InpConfirmMinRangePips)
        {
         Print(head, "tayidiye (", signalText, ") peida shod vali range-e candle (", DoubleToString(confirmRangePips, 1),
               " pip) kamtar az InpConfirmMinRangePips (", DoubleToString(InpConfirmMinRangePips, 1), ") ast - radd shod.");
         return false;
        }
      if(InpConfirmMaxRangePips > 0.0 && confirmRangePips > InpConfirmMaxRangePips)
        {
         Print(head, "tayidiye (", signalText, ") peida shod vali range-e candle (", DoubleToString(confirmRangePips, 1),
               " pip) bishtar az InpConfirmMaxRangePips (", DoubleToString(InpConfirmMaxRangePips, 1), ") ast - radd shod.");
         return false;
        }

      //--- [v1.20] candle bayad dar jahat-e zone baste shode bashe
      if(InpConfirmRequireCloseDirection)
        {
         bool wrongClose = (signal == ENTRY_BUY) ? (candle.close < candle.open) : (candle.close > candle.open);
         if(wrongClose)
           {
            Print(head, "tayidiye (", signalText, ") peida shod vali candle dar jahat-e zone baste nashode (Open=",
                  DoubleToString(candle.open, m_digits), " Close=", DoubleToString(candle.close, m_digits), ") - radd shod.");
            return false;
           }
        }

      //--- candle bayad be zone bokhore (spread ham dar nazar gerefte mishe, chon candle-ha bar asas-e Bid hastan)
      double spread = SymbolInfoDouble(m_symbol, SYMBOL_ASK) - SymbolInfoDouble(m_symbol, SYMBOL_BID);
      if(candle.high < zone.priceLow - spread || candle.low > zone.priceHigh + spread)
        {
         Print(head, "tayidiye (", signalText, ") peida shod vali candle be zone nakhorde (zone: ",
               DoubleToString(zone.priceLow, m_digits), " ta ", DoubleToString(zone.priceHigh, m_digits), ") - radd shod.");
         return false;
        }

      //--- candle bayad afghar-e harekat bashe (na ye candle-e paiin-tar/bala-tar az candle-haye ghabl)
      double refExtreme = 0.0;
      if(!IsExtremeCandle(zone, candle, refExtreme))
        {
         bool sell = (zone.direction == ZONE_SELL);
         Print(head, "tayidiye (", signalText, ") peida shod vali candle ", (sell ? "bala-tarin" : "paiin-tarin"),
               " candle-e ba'd az vorud be zone nist: ", (sell ? "High" : "Low"), "-e in candle = ",
               DoubleToString(sell ? candle.high : candle.low, m_digits), " | ", (sell ? "bala-tarin High" : "paiin-tarin Low"),
               "-e candle-haye ghabli = ", DoubleToString(refExtreme, m_digits),
               " | tolerance = ", DoubleToString(InpConfirmExtremeTolerancePips * m_pipSize, m_digits),
               " (", DoubleToString(InpConfirmExtremeTolerancePips, 1), " pip) - radd shod.");
         return false;
        }

      zone.triggered   = true;
      m_dirty          = true;
      zone.signal      = signal;
      zone.confirmHigh = candle.high;
      zone.confirmLow  = candle.low;

      Print(head, "TAYIDIYE PEIDA SHOD | Signal: ", signalText,
            " | range-e candle: ", DoubleToString((candle.high - candle.low) / m_pipSize, 1), " pip");
      return true;
     }

   //+------------------------------------------------------------------+
   //| Aya akharin candle-e baste-shode (shift 1) tayidiye-i ba jahat-e  |
   //| zone hast? (wanted = ENTRY_BUY baraye zone-e Kharid, ENTRY_SELL   |
   //| baraye zone-e Forush)                                              |
   //|  - Pinbar / Engulfing: jahat az khod-e pattern miyad va bayad ba  |
   //|    jahat-e zone yeki bashe                                          |
   //|  - Doji: jahat az khod-e zone miyad (doji dar afghar-e zone-e     |
   //|    Sell = Forush, dar afghar-e zone-e Buy = Kharid)                |
   //+------------------------------------------------------------------+
   ENUM_ENTRY_SIGNAL DetectCandleSignal(ENUM_ENTRY_SIGNAL wanted)
     {
      bool buy = (wanted == ENTRY_BUY);

      //--- [v1.20] algoo-haye mojaz: tanzim-e koli AND tanzim-e jodagane-ye zone-e Kharid / Forush
      bool usePin    = InpZoneUsePinbarConfirmation    && (buy ? InpBuyZoneAllowPinbar    : InpSellZoneAllowPinbar);
      bool useEngulf = InpZoneUseEngulfingConfirmation && (buy ? InpBuyZoneAllowEngulfing : InpSellZoneAllowEngulfing);
      bool useDoji   = InpZoneUseDojiConfirmation      && (buy ? InpBuyZoneAllowDoji      : InpSellZoneAllowDoji);

      int hits = 0;

      //--- [Bug Fix v1.11] Hammer / Shooting Star ham Pinbar hesab mishan
      if(usePin)
        {
         int pin = m_candleAnalyzer.DetectPinbar(1);
         if((buy && pin > 0) || (!buy && pin < 0))
            hits++;
        }

      if(useEngulf)
        {
         int engulf = m_candleAnalyzer.DetectEngulfing(1);
         if((buy && engulf > 0) || (!buy && engulf < 0))
            hits++;
        }

      if(useDoji && m_candleAnalyzer.DetectPattern(1) == PATTERN_DOJI && DojiSideOk(wanted))
         hits++;

      //--- [v1.20] tedad-e algoo-ye hamzaman-e lazem (1 = yeki kafie = raftar-e ghabli)
      int need = MathMax(1, MathMin(3, InpZoneRequirePatternCount));

      return (hits >= need) ? wanted : ENTRY_NONE;
     }

   //+------------------------------------------------------------------+
   //| [v1.20] Age InpDojiMatchZoneSide roshan bashe: Dragonfly faghat   |
   //| baraye zone-e Kharid va Gravestone faghat baraye zone-e Forush    |
   //+------------------------------------------------------------------+
   bool DojiSideOk(ENUM_ENTRY_SIGNAL wanted)
     {
      if(!InpDojiMatchZoneSide)
         return true;

      ENUM_DOJI_TYPE type = m_candleAnalyzer.DojiTypeAt(1);

      if(type == DOJI_DRAGONFLY)
         return (wanted == ENTRY_BUY);
      if(type == DOJI_GRAVESTONE)
         return (wanted == ENTRY_SELL);

      return true;
     }

   //+------------------------------------------------------------------+
   //| Aya candle-e tayidiye (shift 1) afghar-e harekat hast? Candle-    |
   //| haye moghayese: az candle-e vorud (shift-e entryCandleTime) ta    |
   //| candle-e ghabl az tayidiye (shift 2).                              |
   //|  - zone-e Sell: High-e tayidiye >= bala-tarin High - tolerance    |
   //|  - zone-e Buy : Low-e tayidiye <= paiin-tarin Low + tolerance     |
   //| Age tayidiye khod-e candle-e vorud bashe, candle-e ghabli nist va |
   //| hamishe true bar migardoone                                        |
   //+------------------------------------------------------------------+
   bool IsExtremeCandle(const SEntryZone &zone, const SCandleInfo &candle, double &refExtreme)
     {
      refExtreme = 0.0;   // [v1.19] adad-e moghayese baraye log

      int entryShift = iBarShift(m_symbol, m_timeframe, zone.entryCandleTime, false);

      if(entryShift < 2)
         return true;

      int    count = entryShift - 1;   // shift-haye 2 ta entryShift
      double tol   = InpConfirmExtremeTolerancePips * m_pipSize;

      if(zone.direction == ZONE_SELL)
        {
         double highs[];
         if(CopyHigh(m_symbol, m_timeframe, 2, count, highs) < 1)
            return true;

         double maxHigh = highs[ArrayMaximum(highs)];
         refExtreme = maxHigh;
         return (candle.high >= maxHigh - tol);
        }

      double lows[];
      if(CopyLow(m_symbol, m_timeframe, 2, count, lows) < 1)
         return true;

      double minLow = lows[ArrayMinimum(lows)];
      refExtreme = minLow;
      return (candle.low <= minLow + tol);
     }
  };
//+------------------------------------------------------------------+
