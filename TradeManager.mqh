//+------------------------------------------------------------------+
//|                                                TradeManager.mqh  |
//|  TradeManager.mqh - Modiriat-e Moamele (Taghsim-e Hajm + Palle-   |
//|  bandi)                                                            |
//|                                                                    |
//|  Mantegh:                                                         |
//|  1) Vaghti tayidiye-ye vorud sader shod, hajm-e kol ro nesf mikone |
//|     va do moamele-ye mostaghel ba hamoon hajm-e nesf-shode baz     |
//|     mikone (Moamele 1 va Moamele 2)                                |
//|  2) SL-e moshtarek-e har do moamele = fasele-ye moshakhas          |
//|     (pishfarz 200 pip) az noghte-ye vorud                          |
//|  3) Target-e Moamele 1 = 200 pip balaye noghte-ye vorud (baraye    |
//|     Buy)                                                            |
//|  4) Vaghti target-e Moamele 1 khord -> SL-e Moamele 2 rooye        |
//|     hamoon sath (200 pip paiin-e vorud) freeze mishe (digeh        |
//|     dastkari nemishe)                                              |
//|  5) Target-e Moamele 2 = 1000 pip. Vaghti sood-e Moamele 2 be 500  |
//|     pip resid -> nesf-e hajm-e baghimande-sh baste mishe va SL     |
//|     rooye noghte-ye vorud (Risk-Free / Breakeven) gharar migire    |
//|                                                                    |
//|  Niazmand-e Hesab-e Hedging: chon do position-e mostaghel rooye    |
//|  ye symbol baz mishe, hesab bayad Hedging bashe vagarna dar        |
//|  hesab-e Netting do moamele ba ham edgham mishan va mantegh-e      |
//|  joda az ham kar nemikone.                                         |
//|                                                                    |
//|  [Bug Fixes dar in nasxe]:                                        |
//|  - Entry-price-e VAGHEI (az POSITION_PRICE_OPEN) ba'd az por       |
//|    shodan-e Moamele 1 gerefte mishe, na ghimat-e lahzeie ghabl az  |
//|    ersal-e order (jelogiri az khataye slippage dar mohasebeye     |
//|    SL/TP)                                                          |
//|  - Age halfLot be dalile hadeaghal-lot-e broker majbooran be bala  |
//|    round beshe (va risk-e vaghei az risk-e mohasebeshode bishtar   |
//|    beshe), ye HOSHDAR-e vazeh dar log Print mishe                  |
//|  - Age ticket-e Moamele 2 baz nashe, sefr set mishe (na ye ghadime  |
//|    stale az ResultOrder ke momkene be eshtebah ye position-e       |
//|    vagheii ro neshoon bede)                                        |
//|  - Partial-close va enteghal-e SL be Breakeven digeh be ham        |
//|    vabaste nistan: age hajm baraye partial-close kafi nabashe      |
//|    (masalan hardo trade rooye hadeaghal-lot-e broker hastan), SL   |
//|    hamchenan be noghte-ye vorud montaghel mishe (mohemtarin        |
//|    ghadam-e modiriat-e risk) - digeh silent-fail nadarim            |
//|  - Pair-haye ghair-fa'al (baste shode) dar Monitor() dore-i az     |
//|    array pak mishan ta hajm-e memory dar session-haye toolani      |
//|    bi-nahayat bozorg nashe                                         |
//|                                                                    |
//|  [Update v1.05]:                                                  |
//|  - SL-e sakhtari: OpenTradePair ye SL-e motlagh (slPriceOverride)  |
//|    ham migire (baraye candle-e tayidiye-ye bozorg: SL poshte       |
//|    candle). Freeze-e SL-e Moamele 2 alan SL-e vaghei-e joft ro     |
//|    negah midare (na hamishe fasele-ye sabet az vorud)              |
//|  - Vorud-e marhale-i: RegisterAddOn baraye baz kardan-e baghie-ye  |
//|    hajm vaghti gheimat be sath-e bargasht beresad (faghat ta chand |
//|    candle-e moshakhas), Monitor() har tick check mikone            |
//|  [Update v1.08] Bazyabi-ye joft-moamele-ha: vaziat-e har joft dar  |
//|    GlobalVariable zakhire mishe; ba avaz-e timeframe / restart /   |
//|    compile-e EA, joft-haye baz dobare dar peygiri gharar migiran   |
//|    (nime-basti, risk-free va freeze-e SL edame peida mikone).       |
//|    Joft-haye bedoone zakhire (nosakhe-haye ghadimi) az rooye       |
//|    position-haye ba magic 1/2 peida mishan                           |
//|  - CloseAllPositions: hame-ye position-haye in symbol ro mibande   |
//|    va vorud-haye marhale-i-e montazer ro laghv mikone (dokme-ye    |
//|    Close All-e panel)                                               |
//+------------------------------------------------------------------+
#property strict

#include "Settings.mqh"
#include "Dynamic.mqh"   // [v1.20] SL-e ATR + offset-e Risk-Free
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Sakhtar-e negahdari-e vaziat-e ye joft-moamele (Moamele 1 +       |
//| Moamele 2)                                                         |
//+------------------------------------------------------------------+
struct STradePair
  {
   ulong              ticket1;           // ticket-e Moamele 1 (target-e nazdik)
   ulong              ticket2;           // ticket-e Moamele 2 (target-e door + partial) - 0 yani baz nashode
   double             entryPrice;        // gheimat-e vorud-e moshtarek (vaghei, az POSITION_PRICE_OPEN)
   double             slPrice;           // SL-e moshtarek-e joft (gheimat-e motlagh) - baraye freeze-e SL-e Moamele 2
   ENUM_POSITION_TYPE direction;         // jahat (kharid/forush)
   bool               trade1Closed;      // aya Moamele 1 baste shode?
   bool               trade2SlFrozen;    // aya SL-e Moamele 2 freeze shode?
   bool               trade2PartialDone; // aya SL-e Moamele 2 be noghte-ye vorud (risk-free) raft?
   bool               trade2PartialClosed; // [v1.11] aya nime-basti (partial close) anjam shode? (joda az risk-free ta dobare baste nashe)
   int                fails;             // [v1.11] tedad-e talash-haye na-movafagh-e partial-close
   bool               active;            // aya in joft hanooz dar hale peygiri-e?
  };

//--- flag-haye modiriat-e position-e dasti (SManualPos.flags)
#define MKP_MANUAL_TP1_DONE   1   // nime-basti dar TP1 tamoom shode
#define MKP_MANUAL_BE_DONE    2   // SL be noghte-ye vorud raft (risk-free)
#define MKP_MANUAL_PART_DONE  4   // partial-e InpTrade2PartialPips tamoom shode
#define MKP_MANUAL_SLT_DONE   8   // [v1.14] SL ba'd az nime-basti-e TP1 nazdik-tar shod (ya lazem nabood)
#define MKP_MANUAL_ALL_DONE   15

//+------------------------------------------------------------------+
//| Sakhtar-e peygiri-ye ye position-e dasti (halat-e Dasti): position|
//| ke karbar ba dokme-ye khod-e MetaTrader baz karde va EA oon ro    |
//| "jazb" karde (SL/TP gozashte shode va khorooj-e marhale-i ba'd    |
//| az in modiriat mishe)                                              |
//+------------------------------------------------------------------+
struct SManualPos
  {
   ulong              ticket;
   ENUM_POSITION_TYPE direction;
   double             entryPrice;
   double             initialVolume;   // hajm-e avalie (faghat baraye log va zakhire dar GlobalVariable)
   int                flags;           // MKP_MANUAL_*_DONE
   int                fails;           // tedad-e talash-haye na-movafagh (jelogiri az talash-e bi-nahayat)
  };

//+------------------------------------------------------------------+
//| Sakhtar-e ye vorud-e marhale-i-e montazer (baghie-ye hajm dar     |
//| candle-haye bozorg)                                                |
//+------------------------------------------------------------------+
struct SPendingAddOn
  {
   ENUM_POSITION_TYPE direction;     // jahat (kharid/forush)
   double             lot;           // hajm-e baghimande ke bayad baz beshe
   double             triggerPrice;  // sath-e bargasht ke ba residan be oon vorud anjam mishe
   double             slPrice;       // SL-e motlagh (hamoon SL-e vorud-e aval)
   datetime           expireTime;    // ba'd az in zaman vorud laghv mishe
   string             label;         // esm-e zone (baraye log)
   bool               active;
  };

//+------------------------------------------------------------------+
//| Class Modiriat-e Moamele                                          |
//+------------------------------------------------------------------+
class CTradeManager
  {
private:
   CTrade      m_trade;
   string      m_symbol;
   double      m_pipSize;
   int         m_digits;
   STradePair  m_pairs[];   // list-e joft-moamele-haye dar hale peygiri
   SPendingAddOn m_addOns[]; // list-e vorud-haye marhale-i-e montazer
   SManualPos  m_manual[];  // list-e position-haye dasti-ye jazb-shode (halat-e Dasti)
   datetime    m_manualSince;     // faghat position-haye dasti-ye ba'd az in zaman jazb mishan (0 = hich)
   datetime    m_lastAdoptError;  // baraye mahdood kardan-e tekrar-e log-e khata
   datetime    m_lastFreezeErr;   // [v1.14] mahdood kardan-e log-e khata-ye nazdik kardan-e SL
   uint        m_initTick;        // zaman-e Init (GetTickCount) - baraye bazyabi-ye ta'khiri
   int         m_recoveryChecks;  // tedad-e bazyabi-haye ta'khiri-ye anjam-shode (hadeaksar 2)
   uint        m_lastOpenRetcode; // [v1.17] retcode-e akharin khata-ye baz kardan-e Moamele 1 (0 = khata nabood)
   datetime    m_lastBeErr;       // [v1.17] mahdood kardan-e log-e khata-ye enteghal-e SL be noghte-ye vorud

public:
   void Init(string symbol)
     {
      m_symbol = symbol;
      m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

      //--- andaze-ye pip (Settings.mqh: MKPipSize - ghabele-e tanzim ba InpPointsPerPip)
      m_pipSize = MKPipSize(m_symbol);

      //--- [v1.11] slippage va noe-e por-shodan-e order ghablan set nashode bood (baes-e radd shodan-e order dar ba'zi broker-ha)
      m_trade.SetExpertMagicNumber(MKMagic(0));
      m_trade.SetDeviationInPoints((ulong)MathMax(0, InpDeviationPoints));
      m_trade.SetTypeFillingBySymbol(m_symbol);
      ArrayResize(m_pairs, 0);
      ArrayResize(m_addOns, 0);
      ArrayResize(m_manual, 0);
      m_lastAdoptError = 0;
      m_lastFreezeErr  = 0;
      m_lastBeErr      = 0;
      m_lastOpenRetcode = 0;

      //--- zaman-e shoroe-ye halat-e Dasti az GlobalVariable (ba restart/avaz-e timeframe az bein nemire)
      m_manualSince = 0;
      if(GlobalVariableCheck(ManualSinceKey()))
         m_manualSince = (datetime)(long)GlobalVariableGet(ManualSinceKey());

      m_initTick       = GetTickCount();
      m_recoveryChecks = 0;

      //--- joft-moamele-haye baz-e ghabli (ba avaz-e timeframe / restart / compile-e EA) dobare dar peygiri gharar migiran
      RecoverPairs();

      //--- position-haye dasti-i ke ghablan jazb shode boodan va hanooz baz hastan dobare peygiri mishan
      RecoverManualPositions();
     }

   //+------------------------------------------------------------------+
   //| [v1.17] Aya khata-ye akharin OpenTradePair (baz kardan-e Moamele 1) |
   //| mowaghati bood va talash-e mojaddad bi-khatar ast? (ertebat ghat,   |
   //| requote, bazar baste, ...). Khata-haye mobham (timeout) ya nahaii   |
   //| (hajm/stop na-motabar, na-kafi bodan-e sarmaye) false barmigardoonan|
   //+------------------------------------------------------------------+
   bool LastOpenFailureRetryable()
     {
      return IsRetryableOpenRetcode(m_lastOpenRetcode);
     }

   //+------------------------------------------------------------------+
   //| Baz kardan-e joft-moamele bar asas-e signal-e tayid-shode va     |
   //| hajm-e kol-e mohasebe-shode tavassot-e RiskManager. Hajm ro nesf |
   //| mikone va do moamele-ye mostaghel baz mikone. Age slPriceOverride|
   //| > 0 bashe (va tarafe dorost-e gheimat bashe), be jaye SL-e sabet |
   //| (InpSplitStopLossPips) hamoon gheimat-e motlagh SL mishe         |
   //+------------------------------------------------------------------+
   bool OpenTradePair(ENUM_POSITION_TYPE direction, double totalLot, double slPriceOverride = 0.0, ulong magicBase = 0)
     {
      m_lastOpenRetcode = 0;   // [v1.17]

      double halfLot = NormalizeVolume(totalLot / 2.0);
      if(halfLot <= 0)
        {
         Print("TradeManager: hajm-e nesf-shode na-motabar ast (", DoubleToString(totalLot,2), ")");
         return false;
        }

      //--- HOSHDAR-E RISK: age gerd-kardan be hadeaghal-lot-e broker baese beshe ke
      //--- majmoue-ye do half-lot az totalLot-e asli (ke bar asas InpRiskPercent
      //--- mohasebe shode) bishtar beshe, risk-e vaghei az risk-e barnamerizi-shode
      //--- BISHTAR khahad bood. In moheme ke karbar bedoonad.
      if(halfLot * 2.0 > totalLot * 1.10)
        {
         Print("TradeManager: !!! HOSHDAR-E RISK !!! halfLot (", DoubleToString(halfLot,2),
               ") be dalile hadeaghal-lot-e broker be bala round shode. Majmoue-ye vaghei-e do trade = ",
               DoubleToString(halfLot * 2.0, 2), " lot, dar hali ke bar asas ", DoubleToString(InpRiskPercent,2),
               "% risk faghat ", DoubleToString(totalLot, 2), " lot mohasebe shode bood. Risk-e vaghei-e in ",
               "setup az meghdar-e tanzim-shode dar InpRiskPercent BISHTAR ast.");
        }

      double entryPriceSnapshot = (direction == POSITION_TYPE_BUY)
                                   ? SymbolInfoDouble(m_symbol, SYMBOL_ASK)
                                   : SymbolInfoDouble(m_symbol, SYMBOL_BID);

      double slDistance  = MKSlBufferPips() * m_pipSize;
      double tp1Distance = InpTrade1TakeProfitPips * m_pipSize;
      double tp2Distance = InpTrade2TakeProfitPips * m_pipSize;

      //--- SL-e sakhtari (masalan poshte candle-e tayidiye-ye bozorg): faghat vaghti estefade
      //--- mishe ke tarafe dorost-e gheimat bashe va az hadde-aghal-e fasele-ye broker door-tar
      bool   structuralSL    = false;
      double structuralPrice = 0.0;

      if(slPriceOverride > 0.0)
        {
         double point   = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         double minDist = (double)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
         double gap     = (direction == POSITION_TYPE_BUY)
                           ? (entryPriceSnapshot - slPriceOverride)
                           : (slPriceOverride - entryPriceSnapshot);

         if(gap > 0.0 && gap > minDist)
           {
            structuralSL    = true;
            structuralPrice = NormalizeDouble(slPriceOverride, m_digits);
           }
         else
            Print("TradeManager: SL-e sakhtari (", DoubleToString(slPriceOverride, m_digits),
                  ") nesbat be gheimat-e fe'li motabar nist - SL-e sabet (", DoubleToString(MKSlBufferPips(), 0), " pip) estefade mishe.");
        }

      double slPrice, tp1Price, tp2Price;

      if(direction == POSITION_TYPE_BUY)
        {
         slPrice  = structuralSL ? structuralPrice : (entryPriceSnapshot - slDistance);
         tp1Price = entryPriceSnapshot + tp1Distance;
         tp2Price = entryPriceSnapshot + tp2Distance;
        }
      else
        {
         slPrice  = structuralSL ? structuralPrice : (entryPriceSnapshot + slDistance);
         tp1Price = entryPriceSnapshot - tp1Distance;
         tp2Price = entryPriceSnapshot - tp2Distance;
        }

      slPrice  = NormalizeDouble(slPrice, m_digits);
      tp1Price = NormalizeDouble(tp1Price, m_digits);
      tp2Price = NormalizeDouble(tp2Price, m_digits);

      m_trade.SetExpertMagicNumber(MKMagic(1) + magicBase);
      bool ok1 = (direction == POSITION_TYPE_BUY)
                 ? m_trade.Buy(halfLot, m_symbol, 0.0, slPrice, tp1Price, "MagicKeys-T1")
                 : m_trade.Sell(halfLot, m_symbol, 0.0, slPrice, tp1Price, "MagicKeys-T1");

      if(!ok1)
        {
         m_lastOpenRetcode = m_trade.ResultRetcode();   // [v1.17] baraye tasmim-e talash-e mojaddad
         Print("TradeManager: khata dar baz kardan-e Moamele 1 - ", m_trade.ResultRetcodeDescription());
         return false;
        }
      ulong ticket1 = m_trade.ResultOrder();

      //--- Entry-price-e VAGHEI ro az khod-e position migirim (na ghimat-e lahzeie ghabl
      //--- az ersal-e order), chon momkene be dalile slippage kami farghi karde bashe. In
      //--- baraye mohasebeye SL/TP-e Moamele 2 va peygiri-ye pip-haye sood-e Moamele 2
      //--- dorost-tar ast.
      double entryPrice = entryPriceSnapshot;
      if(PositionSelectByTicket(ticket1))
         entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);

      double priceDrift = MathAbs(entryPrice - entryPriceSnapshot);

      if(direction == POSITION_TYPE_BUY)
        {
         if(!structuralSL)
            slPrice = NormalizeDouble(entryPrice - slDistance, m_digits);
         tp2Price = NormalizeDouble(entryPrice + tp2Distance, m_digits);
        }
      else
        {
         if(!structuralSL)
            slPrice = NormalizeDouble(entryPrice + slDistance, m_digits);
         tp2Price = NormalizeDouble(entryPrice - tp2Distance, m_digits);
        }

      //--- Age gheimat-e vaghei-e por-shodan (fill) az gheimat-e lahzeie ghabl az ersal
      //--- kami farogh dashte (slippage), SL-e Moamele 1 ro ham ba hamin SL-e jadid ham-
      //--- taraz mikonim ta har do moamele daghighan ye SL-e moshtarek dashte bashan
      if(!structuralSL && priceDrift > m_pipSize * 0.1)
         m_trade.PositionModify(ticket1, slPrice, tp1Price);

      m_trade.SetExpertMagicNumber(MKMagic(2) + magicBase);
      //--- [v1.12] age Moamele 2 ba khata-ye mowaghati (requote / tagheir-e gheimat / reject) baz nashod, ta 3 bar talash mikonim.
      //--- khata-haye mobham (timeout / ghat-e ertebat) tekrar nemishan ta moamele-ye tekrari baz nashe
      bool ok2 = false;
      for(int attempt = 1; attempt <= 3 && !ok2; attempt++)
        {
         if(attempt > 1)
           {
            Print("TradeManager: talash-e ", attempt, " az 3 baraye Moamele 2");
            Sleep(250);
           }

         ok2 = (direction == POSITION_TYPE_BUY)
               ? m_trade.Buy(halfLot, m_symbol, 0.0, slPrice, tp2Price, "MagicKeys-T2")
               : m_trade.Sell(halfLot, m_symbol, 0.0, slPrice, tp2Price, "MagicKeys-T2");

         if(!ok2 && !IsRetryableRetcode(m_trade.ResultRetcode()))
            break;
        }

      ulong ticket2 = 0;
      if(!ok2)
         Print("TradeManager: khata dar baz kardan-e Moamele 2 - ", m_trade.ResultRetcodeDescription(),
               " - Moamele 1 baz moonde va bayad dasti modiriat beshe.");
      else
         ticket2 = m_trade.ResultOrder();

      //--- Sabt-e joft-moamele dar list-e peygiri
      int n = ArraySize(m_pairs);
      ArrayResize(m_pairs, n + 1);
      m_pairs[n].ticket1           = ticket1;
      m_pairs[n].ticket2           = ticket2;
      m_pairs[n].entryPrice        = entryPrice;
      m_pairs[n].slPrice           = slPrice;
      m_pairs[n].direction         = direction;
      m_pairs[n].trade1Closed      = false;
      m_pairs[n].trade2SlFrozen    = false;
      m_pairs[n].trade2PartialDone = false;
      m_pairs[n].trade2PartialClosed = false;
      m_pairs[n].fails             = 0;
      m_pairs[n].active            = true;

      //--- vaziat-e joft dar GlobalVariable zakhire mishe ta ba restart-e EA az dast nare
      SavePairState(m_pairs[n]);

      Print("TradeManager: joft-moamele baz shod | Vorud=", DoubleToString(entryPrice, m_digits),
            " | SL=", DoubleToString(slPrice, m_digits),
            (structuralSL ? " (poshte candle-e tayidiye)" : " (SABET az vorud - candle estefade nashod!)"),
            " | TP1=", DoubleToString(tp1Price, m_digits),
            " | TP2=", DoubleToString(tp2Price, m_digits),
            " | Hajm-e har pa=", DoubleToString(halfLot, 2));

      return true;
     }

   //+------------------------------------------------------------------+
   //| Bayad har tick az OnTick-e asli-e EA seda zade beshe. Vaziat-e   |
   //| hameye joft-moamele-haye fa'al ro barresi va modiriat mikone      |
   //+------------------------------------------------------------------+
   void Monitor()
     {
      //--- bazyabi-ye ta'khiri: age dar lahze-ye Init position-ha hanooz az server load nashode boodan
      //--- (masalan baad az baz shodan-e terminal), 3 va 6 sanie ba'd doobare talash mikonim (tekrari-ha rad mishan)
      if(m_recoveryChecks < 2 && (GetTickCount() - m_initTick) >= (uint)(3000 * (m_recoveryChecks + 1)))
        {
         m_recoveryChecks++;
         RecoverPairs();
         RecoverManualPositions();
        }

      ProcessAddOns();

      for(int i = 0; i < ArraySize(m_pairs); i++)
        {
         if(!m_pairs[i].active)
            continue;

         ManageTrade1Closure(m_pairs[i]);
         ManageTrade2PartialAndBreakeven(m_pairs[i]);

         //--- age hardo moamele baste shodan, in joft ro gheir-fa'al kon
         bool trade2StillOpen = (m_pairs[i].ticket2 != 0) && PositionSelectByTicket(m_pairs[i].ticket2);
         if(m_pairs[i].trade1Closed && !trade2StillOpen)
           {
            m_pairs[i].active = false;
            DeletePairState(m_pairs[i]);
           }
        }

      CompactInactivePairs();

      MonitorManualPositions();
     }

   //+------------------------------------------------------------------+
   //| Halat-e Dasti roshan shod: faghat position-haye dasti-i ke ba'd  |
   //| az in zaman baz beshan "jazb" mishan (position-haye ghadimi dast  |
   //| nakhorde mimoonan). Zaman dar GlobalVariable zakhire mishe        |
   //+------------------------------------------------------------------+
   void SetManualSince(datetime since)
     {
      m_manualSince = since;
      GlobalVariableSet(ManualSinceKey(), (double)(long)since);
      Print("TradeManager: halat-e Dasti - position-haye dasti-ye ba'd az ",
            TimeToString(since, TIME_DATE | TIME_SECONDS), " jazb mishan.");
     }

   int ManualTrackedCount()
     {
      return ArraySize(m_manual);
     }

   //--- [v1.12] tedad-e joft-moamele-haye fa'al (baraye InpMaxOpenPairs)
   int OpenPairCount()
     {
      int count = 0;
      for(int i = 0; i < ArraySize(m_pairs); i++)
         if(m_pairs[i].active)
            count++;
      return count;
     }

   //+------------------------------------------------------------------+
   //| Halat-e Dasti: position-haye dasti-ye jadid (magic = 0, baz-shode |
   //| ba'd az m_manualSince, hanooz jazb-nashode) ro peida mikone va    |
   //|  - age karbar SL nazashte: SL-e hoshmand (buySLPrice baraye Buy,  |
   //|    sellSLPrice baraye Sell: InpSplitStopLossPips pas az candle-e  |
   //|    marja'); age ghabel-e estefade nabashe (0 ya tarafe eshtebah-e |
   //|    gheimat) SL-e sabet InpSplitStopLossPips az noghte-ye vorud     |
   //|  - age karbar TP nazashte: TP = InpTrade2TakeProfitPips           |
   //| SL/TP-e khod-e karbar hargez taghir nemikone. Baad az mofaghiat   |
   //| position dar peygiri gharar migire (MonitorManualPositions).      |
   //| Bar migardoone mask: 1 = hadeaghal yek Buy jazb shod,             |
   //| 2 = hadeaghal yek Sell jazb shod, 0 = hichi                        |
   //+------------------------------------------------------------------+
   int AdoptManualPositions(double buySLPrice, double sellSLPrice, bool buyEntryRule = false, bool sellEntryRule = false)
     {
      if(m_manualSince == 0)
         return 0;

      int    mask       = 0;
      double slDistance = MKSlBufferPips() * m_pipSize;
      double tpDistance = InpTrade2TakeProfitPips * m_pipSize;
      double point      = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double minDist    = (double)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;

         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         //--- faghat position-haye dasti (magic = 0); position-haye khod-e EA (magic 1/2) ya EA-haye digeh dast nakhorde mimoonan
         if(PositionGetInteger(POSITION_MAGIC) != 0)
            continue;

         //--- position-haye ghabl az roshan shodan-e halat-e Dasti dast nakhorde mimoonan
         if((datetime)PositionGetInteger(POSITION_TIME) < m_manualSince)
            continue;

         if(FindManual(ticket) >= 0)
            continue;

         //--- [v1.16] position-haye ke ghablan ozv-e ye joft-e dasti shodan dobare jazb nemishan
         if(IsInActivePair(ticket))
            continue;

         ENUM_POSITION_TYPE dir = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double entry  = PositionGetDouble(POSITION_PRICE_OPEN);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double curSL  = PositionGetDouble(POSITION_SL);
         double curTP  = PositionGetDouble(POSITION_TP);
         double curPx  = PositionGetDouble(POSITION_PRICE_CURRENT);
         datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);

         //--- [v1.16] age position-e dasti-ye ghabli-e hamjahat ba hajm-e barabar (dar InpManualPairWindowSec) hast,
         //--- in do ta yek joft hesab mishan va ba hamoon mantegh-e automatic/nim-automatic modiriat mishan
         if(InpManualAutoPair && InpManualStagedExit)
           {
            int partner = FindManualPartner(ticket, dir, volume, openTime);
            if(partner >= 0)
              {
               if(ConvertManualToPair(partner, ticket))
                  mask |= (dir == POSITION_TYPE_BUY) ? 1 : 2;
               continue;   // age tabdil movafagh nashod, tick-e ba'd dobare talash mishe
              }
           }

         double newSL = curSL;
         double newTP = curTP;
         bool   usedEntryRule = false;

         if(curSL <= 0.0)
           {
            //--- pishfarz: fasele-ye sabet az noghte-ye vorud (age SL-e hoshmand ghabel-e estefade nabashe)
            double candidate = (dir == POSITION_TYPE_BUY) ? (entry - slDistance) : (entry + slDistance);

            //--- SL-e hoshmand: InpSplitStopLossPips pas az candle-e marja' (hesab-shode tavassot-e EA-ye asli)
            double smart = (dir == POSITION_TYPE_BUY) ? buySLPrice : sellSLPrice;
            if(smart > 0.0)
              {
               double gap = (dir == POSITION_TYPE_BUY) ? (curPx - smart) : (smart - curPx);
               if(gap > 0.0 && gap > minDist)
                  candidate = smart;
              }

            //--- [v1.20] SL-e candle-e vorud: age candle-e ghabli ghabl az vorud (Kharid: bala-tar / Forush: paiin-tar) bood,
            //--- SL pas az Low/High-e candle-i ke dar oon vared shodim (rooye SL-e hoshmand ghalbe mikone)
            if(dir == POSITION_TYPE_BUY ? buyEntryRule : sellEntryRule)
              {
               double ruleSL = MKEntryCandleStop(m_symbol, dir, entry, openTime);
               if(ruleSL > 0.0)
                 {
                  double ruleGap = (dir == POSITION_TYPE_BUY) ? (curPx - ruleSL) : (ruleSL - curPx);
                  if(ruleGap > 0.0 && ruleGap > minDist)
                    {
                     candidate     = ruleSL;
                     usedEntryRule = true;
                    }
                 }
              }

            newSL = NormalizeDouble(candidate, m_digits);
           }

         if(curTP <= 0.0)
            newTP = NormalizeDouble((dir == POSITION_TYPE_BUY) ? (entry + tpDistance) : (entry - tpDistance), m_digits);

         if(MathAbs(newSL - curSL) > m_pipSize * 0.01 || MathAbs(newTP - curTP) > m_pipSize * 0.01)
           {
            if(!m_trade.PositionModify(ticket, newSL, newTP))
              {
               //--- nashod: jazb nemikonim ta tick-e ba'd doobare talash beshe (log hadeaksar har 5 sanie)
               if(TimeCurrent() - m_lastAdoptError >= 5)
                 {
                  m_lastAdoptError = TimeCurrent();
                  Print("TradeManager: khata dar gozashtan-e SL/TP rooye position-e dasti ", ticket,
                        " - ", m_trade.ResultRetcodeDescription());
                 }
               continue;
              }
           }

         int n = ArraySize(m_manual);
         ArrayResize(m_manual, n + 1);
         m_manual[n].ticket        = ticket;
         m_manual[n].direction     = dir;
         m_manual[n].entryPrice    = entry;
         m_manual[n].initialVolume = volume;
         m_manual[n].flags         = 0;
         m_manual[n].fails         = 0;

         GlobalVariableSet(ManualVolKey(ticket), volume);
         GlobalVariableSet(ManualFlagKey(ticket), 0.0);

         mask |= (dir == POSITION_TYPE_BUY) ? 1 : 2;

         //--- baraye agahi: risk-e taghribi-e hajm-e dasti ba in SL
         double tickSize  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
         double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
         double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
         double riskMoney = (tickSize > 0.0) ? volume * (MathAbs(entry - newSL) / tickSize) * tickValue : 0.0;
         double riskPct   = (balance > 0.0) ? riskMoney / balance * 100.0 : 0.0;

         Print("TradeManager: position-e dasti jazb shod | ", (dir == POSITION_TYPE_BUY ? "Buy" : "Sell"),
               " ticket ", ticket, " | hajm=", DoubleToString(volume, 2),
               " | vorud=", DoubleToString(entry, m_digits),
               " | SL=", DoubleToString(newSL, m_digits),
               " | TP=", DoubleToString(newTP, m_digits),
               " | risk-e SL ~ ", DoubleToString(riskMoney, 2), " (", DoubleToString(riskPct, 2),
               "% balance; hadaf-e InpRiskPercent = ", DoubleToString(InpRiskPercent, 2), "%)",
               (usedEntryRule ? " | SL: ghanoon-e candle-e vorud" : ""),
               (InpManualStagedExit ? " | khorooj-e marhale-i faal" : " | faghat SL/TP"));
        }

      return mask;
     }

   //| triggerPrice beresad (Buy: ask paiin biad, Sell: bid bala biad)   |
   //| baz mishe - faghat ta waitCandles candle-e ba'd az candle-e       |
   //| jari (candle-i ke vorud-e aval dar oon anjam shod)                |
   //+------------------------------------------------------------------+
   void RegisterAddOn(ENUM_POSITION_TYPE direction, double lot, double triggerPrice, double slPrice,
                      ENUM_TIMEFRAMES timeframe, int waitCandles, string label)
     {
      int sec = PeriodSeconds(timeframe);
      if(sec <= 0)
         sec = 60;
      if(waitCandles < 1)
         waitCandles = 1;

      datetime barTime = iTime(m_symbol, timeframe, 0);
      if(barTime == 0)
         barTime = TimeCurrent();

      int n = ArraySize(m_addOns);
      ArrayResize(m_addOns, n + 1);

      m_addOns[n].direction    = direction;
      m_addOns[n].lot          = lot;
      m_addOns[n].triggerPrice = NormalizeDouble(triggerPrice, m_digits);
      m_addOns[n].slPrice      = slPrice;
      m_addOns[n].expireTime   = (datetime)((long)barTime + (long)sec * waitCandles);
      m_addOns[n].label        = label;
      m_addOns[n].active       = true;

      Print("TradeManager: vorud-e marhale-i sabt shod [", label, "] | hajm-e baghimande=", DoubleToString(lot, 2),
            " | sath-e vorud=", DoubleToString(m_addOns[n].triggerPrice, m_digits),
            " | SL=", DoubleToString(slPrice, m_digits),
            " | moddat: ", waitCandles, " candle (ta ", TimeToString(m_addOns[n].expireTime, TIME_DATE | TIME_MINUTES), ")");
     }

   //+------------------------------------------------------------------+
   //| Bastan-e hame-ye position-haye in symbol (har magic) va laghv-e   |
   //| vorud-haye marhale-i-e montazer. Bar migardoone: tedad-e          |
   //| position-i ke baste shod                                          |
   //+------------------------------------------------------------------+
   //--- [v1.20] vorud-haye marhale-i-e montazer (candle-e bozorg) ro laghv mikone
   void ClearAddOns()
     {
      ArrayResize(m_addOns, 0);
     }

   int CloseAllPositions()
     {
      int closed = 0;
      int failed = 0;

      ArrayResize(m_addOns, 0);

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;

         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         //--- [v1.12] InpCloseAllEaOnly: faghat moamele-haye khod-e EA va dasti-haye jazb-shode
         if(InpCloseAllEaOnly)
           {
            long magic = PositionGetInteger(POSITION_MAGIC);
            bool mine  = (magic == (long)MKMagic(1) || magic == (long)MKMagic(2) || FindManual(ticket) >= 0);
            if(!mine)
               continue;
           }

         if(m_trade.PositionClose(ticket))
            closed++;
         else
           {
            failed++;
            Print("TradeManager: khata dar bastan-e position ", ticket, " - ", m_trade.ResultRetcodeDescription());
           }
        }

      Print("TradeManager: CLOSE ALL - ", closed, " position baste shod", (failed > 0 ? (", " + IntegerToString(failed) + " ta ba khata") : ""),
            " | vorud-haye marhale-i-e montazer laghv shodan.");

      return closed;
     }

private:
   //+------------------------------------------------------------------+
   //| Zakhire-ye vaziat-e joft-moamele dar GlobalVariable-e terminal    |
   //| (kelid = "<ticket1>_<ticket2>"): SL-e joft (PS), gheimat-e vorud  |
   //| (PE) va flag-ha (PF: 1 = Moamele 1 baste shode, 2 = SL freeze     |
   //| shode, 4 = nime-basti/risk-free-e Moamele 2 anjam shode). Ba      |
   //| restart / avaz-e timeframe / compile-e EA, joft-haye baz az rooye |
   //| in-ha dobare dar peygiri gharar migiran (RecoverPairs). Faghat    |
   //| vaghti peygiri ro khodemoon baste didim (joft tamoom shod)        |
   //| pak mishan; ghabl az in dar bazyabi hargez pak nemishan, chon      |
   //| momkene position-ha hanooz az server load nashode bashan          |
   //+------------------------------------------------------------------+
   string PairKey(STradePair &pair)
     {
      return IntegerToString((long)pair.ticket1) + "_" + IntegerToString((long)pair.ticket2);
     }

   int PairFlagsValue(STradePair &pair)
     {
      int f = 0;
      if(pair.trade1Closed)
         f |= 1;
      if(pair.trade2SlFrozen)
         f |= 2;
      if(pair.trade2PartialDone)
         f |= 4;
      if(pair.trade2PartialClosed)
         f |= 8;
      return f;
     }

   void SavePairState(STradePair &pair)
     {
      string key = PairKey(pair);
      GlobalVariableSet("MKEA_PS_" + key, pair.slPrice);
      GlobalVariableSet("MKEA_PE_" + key, pair.entryPrice);
      GlobalVariableSet("MKEA_PF_" + key, (double)PairFlagsValue(pair));
     }

   void SavePairFlags(STradePair &pair)
     {
      GlobalVariableSet("MKEA_PF_" + PairKey(pair), (double)PairFlagsValue(pair));
     }

   void DeletePairState(STradePair &pair)
     {
      string key = PairKey(pair);
      GlobalVariableDel("MKEA_PS_" + key);
      GlobalVariableDel("MKEA_PE_" + key);
      GlobalVariableDel("MKEA_PF_" + key);
     }

   //--- age yek nemoone-ye digeh az EA (ya ghabl az restart) flag-i ro avaz karde bashe, hamoon ro mipazirim
   //--- (ta marhale-ha do bar anjam nashan)
   void RefreshPairFlags(STradePair &pair)
     {
      string name = "MKEA_PF_" + PairKey(pair);
      if(!GlobalVariableCheck(name))
         return;

      int f = (int)GlobalVariableGet(name);
      if((f & 1) != 0)
         pair.trade1Closed = true;
      if((f & 2) != 0)
         pair.trade2SlFrozen = true;
      if((f & 4) != 0)
         pair.trade2PartialDone = true;
      if((f & 8) != 0)
         pair.trade2PartialClosed = true;
     }

   int FindPairByTicket(ulong ticket)
     {
      if(ticket == 0)
         return -1;

      for(int i = 0; i < ArraySize(m_pairs); i++)
         if(m_pairs[i].ticket1 == ticket || m_pairs[i].ticket2 == ticket)
            return i;

      return -1;
     }

   //+------------------------------------------------------------------+
   //| Bazyabi-ye joft-moamele-haye baz: aval az rooye GlobalVariable    |
   //| (daghigh), ba'd position-haye ba magic 1/2 ke hich zakhire-i      |
   //| nadaran (masalan joft-haye bazshode ba nosakhe-haye ghadimi-e EA) |
   //+------------------------------------------------------------------+
   void RecoverPairs()
     {
      RecoverPairsFromState();
      AdoptOrphanPairs();
     }

   void RecoverPairsFromState()
     {
      for(int g = GlobalVariablesTotal() - 1; g >= 0; g--)
        {
         string name = GlobalVariableName(g);
         if(StringFind(name, "MKEA_PF_") != 0)
            continue;

         string parts[];
         if(StringSplit(StringSubstr(name, 8), '_', parts) != 2)
            continue;

         ulong t1 = (ulong)StringToInteger(parts[0]);
         ulong t2 = (ulong)StringToInteger(parts[1]);

         if(FindPairByTicket(t1) >= 0 || FindPairByTicket(t2) >= 0)
            continue;

         string key = parts[0] + "_" + parts[1];
         if(!GlobalVariableCheck("MKEA_PS_" + key) || !GlobalVariableCheck("MKEA_PE_" + key))
            continue;

         //--- kodoom pa hanooz baze va male in symbol-e?
         string             sym  = "";
         ENUM_POSITION_TYPE dir  = POSITION_TYPE_BUY;
         bool               open1 = (t1 != 0) && PositionSelectByTicket(t1);
         if(open1)
           {
            sym = PositionGetString(POSITION_SYMBOL);
            dir = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
           }

         bool open2 = (t2 != 0) && PositionSelectByTicket(t2);
         if(open2 && !open1)
           {
            sym = PositionGetString(POSITION_SYMBOL);
            dir = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
           }

         //--- hich pa-i baz nist (joft tamoom shode, ya position-ha hanooz load nashodan): GlobalVariable ro dast nemizanim
         if(!open1 && !open2)
            continue;

         if(sym != m_symbol)
            continue;

         int flags = (int)GlobalVariableGet(name);

         int n = ArraySize(m_pairs);
         ArrayResize(m_pairs, n + 1);
         m_pairs[n].ticket1           = t1;
         m_pairs[n].ticket2           = t2;
         m_pairs[n].entryPrice        = GlobalVariableGet("MKEA_PE_" + key);
         m_pairs[n].slPrice           = GlobalVariableGet("MKEA_PS_" + key);
         m_pairs[n].direction         = dir;
         m_pairs[n].trade1Closed      = ((flags & 1) != 0) || !open1;
         m_pairs[n].trade2SlFrozen    = ((flags & 2) != 0) || !open1;
         m_pairs[n].trade2PartialDone = ((flags & 4) != 0);
         //--- flag-e 4 bedoone 8 = zakhire-ye nosakhe-haye ghabli (hardo ba ham anjam mishodan) - ehtiyatan nime-basti-e tekrari nemizanim
         m_pairs[n].trade2PartialClosed = ((flags & 8) != 0) || ((flags & 4) != 0);
         m_pairs[n].fails             = 0;
         m_pairs[n].active            = true;

         SavePairFlags(m_pairs[n]);

         Print("TradeManager: joft-moamele-ye ghabli dobare dar peygiri gharar gereft | T1=", t1, " T2=", t2,
               " | ", (dir == POSITION_TYPE_BUY ? "Buy" : "Sell"),
               " | vorud=", DoubleToString(m_pairs[n].entryPrice, m_digits),
               " | SL=", DoubleToString(m_pairs[n].slPrice, m_digits),
               " | Moamele 1 ", (m_pairs[n].trade1Closed ? "baste" : "baz"),
               " | nime-basti-e Moamele 2 ", (m_pairs[n].trade2PartialDone ? "anjam shode" : "hanooz na"));
        }
     }

   //+------------------------------------------------------------------+
   //| Position-haye ba magic 1 (Moamele 1) ya 2 (Moamele 2)-e in symbol |
   //| ke dar hich joft-i nistan (masalan joft-haye bazshode ba nosakhe- |
   //| haye ghadimi-e EA ke GlobalVariable nadashtan) ro joft mikone:    |
   //| Moamele 1 ba Moamele 2-e hamjahat ke hadeaksar 10 sanie fargh-e   |
   //| zaman-e baz shodan dashte bashe; Moamele 2-e bedoone joft yani    |
   //| Moamele 1 ghablan baste shode                                      |
   //+------------------------------------------------------------------+
   void AdoptOrphanPairs()
     {
      ulong              o1[];
      datetime           ot1[];
      ENUM_POSITION_TYPE od1[];
      ulong              o2[];
      datetime           ot2[];
      ENUM_POSITION_TYPE od2[];
      int n1 = 0;
      int n2 = 0;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;

         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         long magic = PositionGetInteger(POSITION_MAGIC);
         if(magic != (long)MKMagic(1) && magic != (long)MKMagic(2))
            continue;

         if(FindPairByTicket(ticket) >= 0)
            continue;

         datetime           openTime = (datetime)PositionGetInteger(POSITION_TIME);
         ENUM_POSITION_TYPE type     = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         if(magic == (long)MKMagic(1))
           {
            ArrayResize(o1, n1 + 1);
            ArrayResize(ot1, n1 + 1);
            ArrayResize(od1, n1 + 1);
            o1[n1]  = ticket;
            ot1[n1] = openTime;
            od1[n1] = type;
            n1++;
           }
         else
           {
            ArrayResize(o2, n2 + 1);
            ArrayResize(ot2, n2 + 1);
            ArrayResize(od2, n2 + 1);
            o2[n2]  = ticket;
            ot2[n2] = openTime;
            od2[n2] = type;
            n2++;
           }
        }

      if(n1 == 0 && n2 == 0)
         return;

      bool used2[];
      ArrayResize(used2, n2);
      for(int b = 0; b < n2; b++)
         used2[b] = false;

      for(int a = 0; a < n1; a++)
        {
         int  best     = -1;
         long bestDiff = 11;

         for(int b = 0; b < n2; b++)
           {
            if(used2[b] || od2[b] != od1[a])
               continue;

            long diff = (long)ot2[b] - (long)ot1[a];
            if(diff < 0)
               diff = -diff;

            if(diff < bestDiff)
              {
               bestDiff = diff;
               best     = b;
              }
           }

         if(best >= 0)
            used2[best] = true;

         AddRecoveredPair(o1[a], (best >= 0) ? o2[best] : (ulong)0);
        }

      for(int b = 0; b < n2; b++)
         if(!used2[b])
            AddRecoveredPair(0, o2[b]);
     }

   //+------------------------------------------------------------------+
   //| Sakhtan-e ye joft az rooye position-haye zende (bedoone zakhire-  |
   //| ye ghabli). Flag-ha az rooye vaziat-e position-ha estenbat mishan:|
   //|  - Moamele 1 baz nist => baste shode (va SL-e Moamele 2 ghablan   |
   //|    freeze shode farz mishe)                                         |
   //|  - SL-e Moamele 2 rooye noghte-ye vorud ya behtar => nime-basti/  |
   //|    risk-free anjam shode                                            |
   //+------------------------------------------------------------------+
   void AddRecoveredPair(ulong ticket1, ulong ticket2)
     {
      double             entry = 0.0;
      double             sl    = 0.0;
      double             t2SL  = 0.0;
      double             entry2 = 0.0;   // [v1.17] vorud-e khod-e Moamele 2
      ENUM_POSITION_TYPE dir   = POSITION_TYPE_BUY;

      bool open1 = (ticket1 != 0) && PositionSelectByTicket(ticket1);
      if(open1)
        {
         entry = PositionGetDouble(POSITION_PRICE_OPEN);
         sl    = PositionGetDouble(POSITION_SL);
         dir   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        }

      bool open2 = (ticket2 != 0) && PositionSelectByTicket(ticket2);
      if(open2)
        {
         t2SL   = PositionGetDouble(POSITION_SL);
         entry2 = PositionGetDouble(POSITION_PRICE_OPEN);

         if(!open1)
           {
            entry = PositionGetDouble(POSITION_PRICE_OPEN);
            sl    = t2SL;
            dir   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
           }
        }

      if(!open1 && !open2)
         return;

      bool riskFree = open2 && (t2SL > 0.0) &&
                      ((dir == POSITION_TYPE_BUY) ? (t2SL >= entry2 - m_pipSize * 0.1)
                                                   : (t2SL <= entry2 + m_pipSize * 0.1));

      int n = ArraySize(m_pairs);
      ArrayResize(m_pairs, n + 1);
      m_pairs[n].ticket1           = ticket1;
      m_pairs[n].ticket2           = ticket2;
      m_pairs[n].entryPrice        = entry;
      m_pairs[n].slPrice           = sl;
      m_pairs[n].direction         = dir;
      m_pairs[n].trade1Closed      = !open1;
      m_pairs[n].trade2SlFrozen    = !open1;
      m_pairs[n].trade2PartialDone = riskFree;
      m_pairs[n].trade2PartialClosed = riskFree;
      m_pairs[n].fails             = 0;
      m_pairs[n].active            = true;

      SavePairState(m_pairs[n]);

      Print("TradeManager: joft-moamele-ye ghabli az rooye position-ha peida va dar peygiri gharar gereft | T1=", ticket1,
            " T2=", ticket2, " | ", (dir == POSITION_TYPE_BUY ? "Buy" : "Sell"),
            " | vorud=", DoubleToString(entry, m_digits),
            " | SL=", DoubleToString(sl, m_digits),
            " | Moamele 1 ", (open1 ? "baz" : "baste"),
            " | nime-basti-e Moamele 2 ", (riskFree ? "anjam shode" : "hanooz na"));
     }

   //--- kelid-haye GlobalVariable baraye halat-e Dasti
   string ManualSinceKey()
     {
      return "MKEA_ManualSince_" + m_symbol;
     }

   string ManualVolKey(ulong ticket)
     {
      return "MKEA_MPV_" + IntegerToString((long)ticket);
     }

   string ManualFlagKey(ulong ticket)
     {
      return "MKEA_MPF_" + IntegerToString((long)ticket);
     }

   int FindManual(ulong ticket)
     {
      for(int i = 0; i < ArraySize(m_manual); i++)
         if(m_manual[i].ticket == ticket)
            return i;
      return -1;
     }

   void RemoveManualAt(int index)
     {
      int n = ArraySize(m_manual);
      if(index < 0 || index >= n)
         return;

      for(int k = index; k < n - 1; k++)
         m_manual[k] = m_manual[k + 1];

      ArrayResize(m_manual, n - 1);
     }

   //+------------------------------------------------------------------+
   //| [v1.16] Tabdil-e do position-e dasti be ye joft-moamele             |
   //+------------------------------------------------------------------+

   //--- aya in ticket ozv-e ye joft-moamele-ye fa'al ast?
   bool IsInActivePair(const ulong ticket)
     {
      for(int i = 0; i < ArraySize(m_pairs); i++)
         if(m_pairs[i].active && (m_pairs[i].ticket1 == ticket || m_pairs[i].ticket2 == ticket))
            return true;
      return false;
     }

   //--- position-e dasti-ye jazb-shode-i ke hamjahat, hajm-e barabar, hanooz bedoone marhale (flags = 0) va dar
   //--- InpManualPairWindowSec sanie nazdik-e in position baz shode bashe (index dar m_manual, ya -1)
   int FindManualPartner(const ulong ticket, const ENUM_POSITION_TYPE dir, const double volume, const datetime openTime)
     {
      for(int j = 0; j < ArraySize(m_manual); j++)
        {
         if(m_manual[j].ticket == ticket || m_manual[j].direction != dir || m_manual[j].flags != 0)
            continue;

         if(!PositionSelectByTicket(m_manual[j].ticket))
            continue;

         if(MathAbs(PositionGetDouble(POSITION_VOLUME) - volume) > 1e-8)
            continue;

         double diffSec = MathAbs((double)((long)PositionGetInteger(POSITION_TIME) - (long)openTime));
         if(diffSec > (double)MathMax(1, InpManualPairWindowSec))
            continue;

         return j;
        }
      return -1;
     }

   //--- position-e ghadimi-tar = Moamele 1 (TP = InpTrade1TakeProfitPips), jadid-tar = Moamele 2 (TP = InpTrade2TakeProfitPips).
   //--- SL-e hardo hamoon SL-e Moamele 1 (SL-e hoshmand ya SL-e khod-e karbar). TP-e khod-e karbar taghir nemikone.
   //--- Bar migardoone true = tabdil anjam shod
   bool ConvertManualToPair(const int idx, const ulong ticketNew)
     {
      ulong ticketOld = m_manual[idx].ticket;

      if(!PositionSelectByTicket(ticketOld))
         return false;
      datetime timeOld  = (datetime)PositionGetInteger(POSITION_TIME);
      double   entryOld = PositionGetDouble(POSITION_PRICE_OPEN);
      double   slOld    = PositionGetDouble(POSITION_SL);
      double   tpOld    = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE dir = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(!PositionSelectByTicket(ticketNew))
         return false;
      datetime timeNew  = (datetime)PositionGetInteger(POSITION_TIME);
      double   entryNew = PositionGetDouble(POSITION_PRICE_OPEN);
      double   slNew    = PositionGetDouble(POSITION_SL);
      double   tpNew    = PositionGetDouble(POSITION_TP);

      //--- Moamele 1 = ghadimi-tar
      bool newIsFirst = (timeNew < timeOld) || (timeNew == timeOld && ticketNew < ticketOld);

      ulong t1 = newIsFirst ? ticketNew : ticketOld;
      ulong t2 = newIsFirst ? ticketOld : ticketNew;
      double e1 = newIsFirst ? entryNew : entryOld;
      double e2 = newIsFirst ? entryOld : entryNew;
      double sl1 = newIsFirst ? slNew : slOld;
      double sl2 = newIsFirst ? slOld : slNew;
      double tpCur1 = newIsFirst ? tpNew : tpOld;
      double tpCur2 = newIsFirst ? tpOld : tpNew;

      double pairSL = (sl1 > 0.0) ? sl1 : sl2;
      if(pairSL <= 0.0)
         return false;   // hich SL-i nist (nabayad etefagh biofte) - ta jazb-e jodagane

      double tp1Dist = InpTrade1TakeProfitPips * m_pipSize;
      double tp2Dist = InpTrade2TakeProfitPips * m_pipSize;

      double tp1Price = NormalizeDouble((dir == POSITION_TYPE_BUY) ? e1 + tp1Dist : e1 - tp1Dist, m_digits);
      double tp2Price = NormalizeDouble((dir == POSITION_TYPE_BUY) ? e2 + tp2Dist : e2 - tp2Dist, m_digits);

      //--- TP-e nahaii-i ke EA ghablan rooye position-e aval gozashte bood (e1 +/- InpTrade2TakeProfitPips)
      double autoFinalTP1 = NormalizeDouble((dir == POSITION_TYPE_BUY) ? e1 + tp2Dist : e1 - tp2Dist, m_digits);
      bool   tp1IsOurs    = (tpCur1 <= 0.0) || (MathAbs(tpCur1 - autoFinalTP1) <= m_pipSize);

      double newTP1 = tp1IsOurs ? tp1Price : tpCur1;      // TP-e dasti-ye karbar ro hefz mikonim
      double newTP2 = (tpCur2 <= 0.0) ? tp2Price : tpCur2;
      double newSL2 = (sl2 > 0.0) ? sl2 : pairSL;

      //--- aval Moamele 2 (age khata dad, hich chiz-e Moamele 1 taghir nakarde)
      if(MathAbs(newSL2 - sl2) > m_pipSize * 0.01 || MathAbs(newTP2 - tpCur2) > m_pipSize * 0.01)
        {
         if(!m_trade.PositionModify(t2, NormalizeDouble(newSL2, m_digits), newTP2))
           {
            if(TimeCurrent() - m_lastAdoptError >= 5)
              {
               m_lastAdoptError = TimeCurrent();
               Print("TradeManager: khata dar gozashtan-e SL/TP rooye Moamele 2-e joft-e dasti ", t2, " - ", m_trade.ResultRetcodeDescription());
              }
            return false;
           }
        }

      if(MathAbs(newTP1 - tpCur1) > m_pipSize * 0.01)
        {
         if(!m_trade.PositionModify(t1, sl1 > 0.0 ? sl1 : pairSL, newTP1))
           {
            if(TimeCurrent() - m_lastAdoptError >= 5)
              {
               m_lastAdoptError = TimeCurrent();
               Print("TradeManager: khata dar gozashtan-e TP rooye Moamele 1-e joft-e dasti ", t1, " - ", m_trade.ResultRetcodeDescription());
              }
            return false;
           }
        }

      //--- position-e ghadimi az list-e dasti kharej mishe (be jaye oon, joft peygiri mishe)
      GlobalVariableDel(ManualVolKey(ticketOld));
      GlobalVariableDel(ManualFlagKey(ticketOld));
      RemoveManualAt(idx);

      int n = ArraySize(m_pairs);
      ArrayResize(m_pairs, n + 1);
      m_pairs[n].ticket1             = t1;
      m_pairs[n].ticket2             = t2;
      m_pairs[n].entryPrice          = e1;
      m_pairs[n].slPrice             = pairSL;
      m_pairs[n].direction           = dir;
      m_pairs[n].trade1Closed        = false;
      m_pairs[n].trade2SlFrozen      = false;
      m_pairs[n].trade2PartialDone   = false;
      m_pairs[n].trade2PartialClosed = false;
      m_pairs[n].fails               = 0;
      m_pairs[n].active              = true;

      SavePairState(m_pairs[n]);

      Print("TradeManager: do position-e dasti be onvan-e joft-moamele jazb shodan | ",
            (dir == POSITION_TYPE_BUY ? "Buy" : "Sell"),
            " | Moamele 1 (", t1, ") TP=", DoubleToString(newTP1, m_digits),
            " | Moamele 2 (", t2, ") TP=", DoubleToString(newTP2, m_digits),
            " | SL=", DoubleToString(pairSL, m_digits),
            " | modiriat: mesl-e nim-automatic/automatic");

      return true;
     }

   void SaveManualFlags(SManualPos &mp)
     {
      GlobalVariableSet(ManualFlagKey(mp.ticket), (double)mp.flags);
     }

   //+------------------------------------------------------------------+
   //| Ba restart/avaz-e timeframe-e EA, position-haye dasti-i ke ghablan|
   //| jazb shode boodan (GlobalVariable-eshoon hast) va hanooz baz     |
   //| hastan ba hamoon flag-ha dobare dar peygiri gharar migiran        |
   //+------------------------------------------------------------------+
   void RecoverManualPositions()
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;

         if(PositionGetString(POSITION_SYMBOL) != m_symbol)
            continue;

         if(PositionGetInteger(POSITION_MAGIC) != 0)
            continue;

         if(!GlobalVariableCheck(ManualVolKey(ticket)) || FindManual(ticket) >= 0)
            continue;

         int n = ArraySize(m_manual);
         ArrayResize(m_manual, n + 1);
         m_manual[n].ticket        = ticket;
         m_manual[n].direction     = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         m_manual[n].entryPrice    = PositionGetDouble(POSITION_PRICE_OPEN);
         m_manual[n].initialVolume = GlobalVariableGet(ManualVolKey(ticket));
         m_manual[n].flags         = GlobalVariableCheck(ManualFlagKey(ticket)) ? (int)GlobalVariableGet(ManualFlagKey(ticket)) : 0;
         m_manual[n].fails         = 0;

         Print("TradeManager: position-e dasti-ye ghabli (ticket ", ticket, ") dobare dar peygiri gharar gereft.");
        }
     }

   //+------------------------------------------------------------------+
   //| Har tick: position-haye dasti-ye jazb-shode ro peygiri mikone.    |
   //| Position-i ke baste shode az list hazf mishe; age                 |
   //| InpManualStagedExit roshan bashe khorooj-e marhale-i anjam mishe  |
   //+------------------------------------------------------------------+
   void MonitorManualPositions()
     {
      for(int i = ArraySize(m_manual) - 1; i >= 0; i--)
        {
         if(!PositionSelectByTicket(m_manual[i].ticket))
           {
            Print("TradeManager: position-e dasti (ticket ", m_manual[i].ticket, ") baste shod - peygiri tamoom.");
            GlobalVariableDel(ManualVolKey(m_manual[i].ticket));
            GlobalVariableDel(ManualFlagKey(m_manual[i].ticket));
            RemoveManualAt(i);
            continue;
           }

         if(InpManualStagedExit)
            ManageManualExits(m_manual[i]);
        }
     }

   //+------------------------------------------------------------------+
   //| Khorooj-e marhale-i-e ye position-e dasti (hamoon sakhtar-e       |
   //| joft-moamele, ba partial-close rooye ye position):                |
   //|  1) sood >= InpTrade1TakeProfitPips: nime-ye hajm baste mishe     |
   //|     (mesl-e Moamele 1)                                              |
   //|  2) sood >= InpTrade2PartialPips: SL be noghte-ye vorud miad      |
   //|     (risk-free) va InpTrade2PartialPercent-e hajm-e baghimande    |
   //|     baste mishe (mesl-e Moamele 2). Hadaf-e nahaii hamoon TP-e    |
   //|     position-e                                                      |
   //| Har marhale faghat yek bar; ba nakafi-ye hajm faghat log mishe va |
   //| marhale-ye ba'd edame peida mikone                                  |
   //+------------------------------------------------------------------+
   void ManageManualExits(SManualPos &mp)
     {
      if((mp.flags & MKP_MANUAL_ALL_DONE) == MKP_MANUAL_ALL_DONE)
         return;

      if(!PositionSelectByTicket(mp.ticket))
         return;

      double currentPrice = (mp.direction == POSITION_TYPE_BUY)
                             ? SymbolInfoDouble(m_symbol, SYMBOL_BID)
                             : SymbolInfoDouble(m_symbol, SYMBOL_ASK);

      double profitPips = (mp.direction == POSITION_TYPE_BUY)
                           ? (currentPrice - mp.entryPrice) / m_pipSize
                           : (mp.entryPrice - currentPrice) / m_pipSize;

      double volMin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);

      //--- 1) nime-basti dar TP1
      if((mp.flags & MKP_MANUAL_TP1_DONE) == 0 && profitPips >= InpTrade1TakeProfitPips)
        {
         double currentVolume = PositionGetDouble(POSITION_VOLUME);
         double closeVolume   = NormalizeVolume(currentVolume / 2.0);
         bool   feasible      = (closeVolume >= volMin) && (closeVolume < currentVolume);

         if(!feasible)
           {
            Print("TradeManager: position-e dasti ", mp.ticket, " - hajm (", DoubleToString(currentVolume, 2),
                  " lot) baraye nime-basti dar TP1 kafi nist (hadeaghal-lot-e broker = ", DoubleToString(volMin, 2),
                  ") - in marhale rad shod.");
            mp.flags |= (MKP_MANUAL_TP1_DONE | MKP_MANUAL_SLT_DONE);   // sood-i realize nashode -> SL nazdik nemishe
            SaveManualFlags(mp);
           }
         else if(m_trade.PositionClosePartial(mp.ticket, closeVolume))
           {
            Print("TradeManager: position-e dasti ", mp.ticket, " be andaze-ye ", DoubleToString(closeVolume, 2),
                  " lot dar TP1 nime baste shod (sood ", DoubleToString(profitPips, 1), " pip)");
            mp.flags |= MKP_MANUAL_TP1_DONE;
            SaveManualFlags(mp);
           }
         else
           {
            mp.fails++;
            Print("TradeManager: khata dar nime-bastan-e position-e dasti ", mp.ticket, " - ", m_trade.ResultRetcodeDescription());
            if(mp.fails >= 5)
              {
               Print("TradeManager: talash baraye nime-basti-e TP1 motevaghef shod.");
               mp.flags |= (MKP_MANUAL_TP1_DONE | MKP_MANUAL_SLT_DONE);
               SaveManualFlags(mp);
              }
            return;
           }

         if(!PositionSelectByTicket(mp.ticket))
            return;
        }

      //--- 1b) [v1.14] ba'd az nime-basti-e movafagh-e TP1: SL be fasele-ye InpTrade2SlAfterTrade1Pips az vorud miad
      //--- (nime-ye bastesh sood-e realize-shode darad; age SL bokhore zarar-e kol sefr mishe). Ta movafagh shodan tekrar mishe
      if((mp.flags & MKP_MANUAL_TP1_DONE) != 0 && (mp.flags & MKP_MANUAL_SLT_DONE) == 0)
        {
         if(TightenStopFromEntry(mp.ticket))
           {
            mp.flags |= MKP_MANUAL_SLT_DONE;
            SaveManualFlags(mp);
           }

         if(!PositionSelectByTicket(mp.ticket))
            return;
        }

      //--- 2) risk-free + partial dar InpTrade2PartialPips
      if(profitPips < InpTrade2PartialPips)
         return;

      if((mp.flags & MKP_MANUAL_BE_DONE) == 0)
        {
         double currentSL = PositionGetDouble(POSITION_SL);
         double currentTP = PositionGetDouble(POSITION_TP);

         //--- age karbar ghablan SL ro be noghte-ye vorud ya sood bord, dast nemizanim
         bool alreadySafe = (currentSL > 0.0) &&
                            ((mp.direction == POSITION_TYPE_BUY) ? (currentSL >= mp.entryPrice) : (currentSL <= mp.entryPrice));

         if(alreadySafe)
           {
            mp.flags |= MKP_MANUAL_BE_DONE;
            SaveManualFlags(mp);
           }
         else if(m_trade.PositionModify(mp.ticket, MKBreakEvenPrice(mp.direction, mp.entryPrice, m_pipSize, m_digits), currentTP))
           {
            Print("TradeManager: SL-e position-e dasti ", mp.ticket, " rooye noghte-ye vorud (Risk-Free) gharar gereft: ",
                  DoubleToString(mp.entryPrice, m_digits));
            mp.flags |= MKP_MANUAL_BE_DONE;
            SaveManualFlags(mp);
           }
         else
           {
            mp.fails++;
            Print("TradeManager: khata dar enteghal-e SL-e position-e dasti be noghte-ye vorud - ", m_trade.ResultRetcodeDescription());
            if(mp.fails >= 5)
              {
               mp.flags |= MKP_MANUAL_BE_DONE;
               SaveManualFlags(mp);
              }
           }

         if(!PositionSelectByTicket(mp.ticket))
            return;
        }

      if((mp.flags & MKP_MANUAL_PART_DONE) == 0)
        {
         double currentVolume = PositionGetDouble(POSITION_VOLUME);
         double closeVolume   = NormalizeVolume(currentVolume * (InpTrade2PartialPercent / 100.0));
         bool   feasible      = (closeVolume >= volMin) && (closeVolume < currentVolume);

         if(!feasible)
           {
            Print("TradeManager: position-e dasti ", mp.ticket, " - hajm (", DoubleToString(currentVolume, 2),
                  " lot) baraye partial-close kafi nist - faghat SL be noghte-ye vorud montaghel shod, hajm hamoon mimoone.");
            mp.flags |= MKP_MANUAL_PART_DONE;
            SaveManualFlags(mp);
           }
         else if(m_trade.PositionClosePartial(mp.ticket, closeVolume))
           {
            Print("TradeManager: position-e dasti ", mp.ticket, " be andaze-ye ", DoubleToString(closeVolume, 2),
                  " lot nime baste shod (sood ", DoubleToString(profitPips, 1), " pip)");
            mp.flags |= MKP_MANUAL_PART_DONE;
            SaveManualFlags(mp);
           }
         else
           {
            mp.fails++;
            Print("TradeManager: khata dar partial-close-e position-e dasti ", mp.ticket, " - ", m_trade.ResultRetcodeDescription());
            if(mp.fails >= 5)
              {
               mp.flags |= MKP_MANUAL_PART_DONE;
               SaveManualFlags(mp);
              }
           }
        }
     }

   //+------------------------------------------------------------------+
   //| Har tick: vorud-haye marhale-i-e montazer ro check mikone. Age    |
   //| gheimat be sath-e bargasht resid, baghie-ye hajm baz mishe; age   |
   //| moddat tamoom shod, laghv mishe                                    |
   //+------------------------------------------------------------------+
   void ProcessAddOns()
     {
      int n = ArraySize(m_addOns);
      if(n == 0)
         return;

      double   bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double   ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      datetime now = TimeCurrent();

      for(int i = 0; i < n; i++)
        {
         if(!m_addOns[i].active)
            continue;

         if(now >= m_addOns[i].expireTime)
           {
            m_addOns[i].active = false;
            Print("TradeManager: vorud-e marhale-i-e zone [", m_addOns[i].label,
                  "] laghv shod - gheimat dar moddat-e mojaz be sath-e bargasht nareside.");
            continue;
           }

         bool reached = (m_addOns[i].direction == POSITION_TYPE_BUY)
                         ? (ask <= m_addOns[i].triggerPrice)
                         : (bid >= m_addOns[i].triggerPrice);
         if(!reached)
            continue;

         //--- ghabl az baz kardan gheyr-faal mikonim ta hich vaght do bar ejra nashe
         m_addOns[i].active = false;

         Print("TradeManager: gheimat be sath-e bargasht resid - baz kardan-e baghie-ye hajm [", m_addOns[i].label, "]");

         if(!OpenTradePair(m_addOns[i].direction, m_addOns[i].lot, m_addOns[i].slPrice))
            Print("TradeManager: khata dar baz kardan-e baghie-ye hajm-e zone [", m_addOns[i].label, "]");
        }

      //--- pak kardan-e vorud-haye gheyr-faal
      int activeCount = 0;
      for(int i = 0; i < ArraySize(m_addOns); i++)
         if(m_addOns[i].active)
            activeCount++;

      if(activeCount == ArraySize(m_addOns))
         return;

      SPendingAddOn kept[];
      ArrayResize(kept, activeCount);
      int k = 0;
      for(int i = 0; i < ArraySize(m_addOns); i++)
        {
         if(m_addOns[i].active)
           {
            kept[k] = m_addOns[i];
            k++;
           }
        }

      ArrayResize(m_addOns, activeCount);
      for(int i = 0; i < activeCount; i++)
         m_addOns[i] = kept[i];
     }

   //+------------------------------------------------------------------+
   //| Barresi-ye baste shodan-e Moamele 1 (ba target) va freeze        |
   //| kardan-e SL-e Moamele 2                                           |
   //+------------------------------------------------------------------+
   void ManageTrade1Closure(STradePair &pair)
     {
      RefreshPairFlags(pair);

      if(!pair.trade1Closed)
        {
         if(PositionSelectByTicket(pair.ticket1))
            return; // hanooz baz ast, kari lazem nist

         //--- Moamele 1 baste shode (che ba target, che ba SL)
         pair.trade1Closed = true;
         SavePairFlags(pair);
         Print("TradeManager: Moamele 1 (ticket ", pair.ticket1, ") baste shod.");
        }

      //--- [v1.14] ghablan ba'd az bastan-e Moamele 1 faghat yek bar talash mishod; age PositionModify khata midad
      //--- dige tekrar nemishod. Alan ta movafagh shodan (trade2SlFrozen) har tick tekrar mishe
      if(pair.ticket2 == 0 || pair.trade2SlFrozen)
         return; // Moamele 2 asasan baz nashode bood ya ghablan anjam shode

      //--- age Moamele 2 ghablan risk-free shode (SL rooye noghte-ye vorud), chizi baraye taghir nist
      if(pair.trade2PartialDone)
         return;

      if(!PositionSelectByTicket(pair.ticket2))
         return;

      if(InpTrade2SlAfterTrade1Pips > 0)
        {
         //--- [v1.14] SL-e Moamele 2 = InpTrade2SlAfterTrade1Pips az noghte-ye vorud-e khodesh (faghat nazdik-tar).
         //--- Sood-e Moamele 1 (nime-ye hajm * target) zarar-e in SL ro jobran mikone
         if(TightenStopFromEntry(pair.ticket2))
           {
            pair.trade2SlFrozen = true;
            SavePairFlags(pair);
           }
         return;
        }

      //--- InpTrade2SlAfterTrade1Pips = 0: raftar-e ghabli - SL-e avalie-ye joft hamoon-jaa mimoone
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      double frozenSL  = NormalizeDouble(pair.slPrice, m_digits);

      //--- [v1.20] age SL-e feli (masalan ba trailing) ghablan behtar az SL-e avalie ast, nabayad dobare dur beshe
      if(currentSL > 0.0 && ((pair.direction == POSITION_TYPE_BUY) ? (currentSL > frozenSL) : (currentSL < frozenSL)))
        {
         pair.trade2SlFrozen = true;
         SavePairFlags(pair);
         return;
        }

      if(m_trade.PositionModify(pair.ticket2, frozenSL, currentTP))
        {
         pair.trade2SlFrozen = true;
         SavePairFlags(pair);
         Print("TradeManager: SL-e Moamele 2 (ticket ", pair.ticket2, ") freeze shod rooye ",
               DoubleToString(frozenSL, m_digits));
        }
      else if(TimeCurrent() - m_lastFreezeErr >= 5)
        {
         m_lastFreezeErr = TimeCurrent();
         Print("TradeManager: khata dar freeze kardan-e SL-e Moamele 2 - ", m_trade.ResultRetcodeDescription());
        }
     }

   //+------------------------------------------------------------------+
   //| [v1.14] SL-e ye position ro be fasele-ye InpTrade2SlAfterTrade1Pips |
   //| az noghte-ye vorud-e khodesh mibare (Buy: paiin-tar, Sell: bala-tar).|
   //|  - faghat nazdik-tar mikone; age SL-e feli nazdik-tar ya barabar     |
   //|    bashe kari nemikone                                                |
   //|  - age gheimat az in SL ghablan rad shode (ya be hadd-e broker      |
   //|    nazdik ast) taghir nemide - SL-e ghabli khodesh kar mikone       |
   //| Bar migardoone true = anjam shod ya lazem nist; false = khata       |
   //| (tick-e ba'd dobare talash mishe)                                    |
   //+------------------------------------------------------------------+
   bool TightenStopFromEntry(const ulong ticket)
     {
      if(InpTrade2SlAfterTrade1Pips <= 0 || !PositionSelectByTicket(ticket))
         return true;

      ENUM_POSITION_TYPE dir = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);

      double distance = InpTrade2SlAfterTrade1Pips * m_pipSize;
      double newSL    = NormalizeDouble((dir == POSITION_TYPE_BUY) ? entry - distance : entry + distance, m_digits);

      //--- faghat nazdik-tar kardan
      if(curSL > 0.0)
        {
         if(dir == POSITION_TYPE_BUY && curSL >= newSL)
            return true;
         if(dir == POSITION_TYPE_SELL && curSL <= newSL)
            return true;
        }

      //--- SL-e jadid bayad az gheimat be andaze-ye hadeaghal-e broker door bashe
      double point   = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double minDist = (double)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
      double bid     = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ask     = SymbolInfoDouble(m_symbol, SYMBOL_ASK);

      bool priceTooClose = (dir == POSITION_TYPE_BUY) ? ((bid - newSL) <= minDist)
                                                       : ((newSL - ask) <= minDist);
      if(priceTooClose)
        {
         Print("TradeManager: SL-e jadid (", DoubleToString(newSL, m_digits), ") baraye ticket ", ticket,
               " ghabele-e gozashtan nist (gheimat be an resideh) - SL-e ghabli (", DoubleToString(curSL, m_digits), ") baghi moond.");
         return true;
        }

      if(m_trade.PositionModify(ticket, newSL, curTP))
        {
         Print("TradeManager: SL-e ticket ", ticket, " ba'd az sood-e Moamele 1 / TP1 be ", InpTrade2SlAfterTrade1Pips,
               " pip az noghte-ye vorud (", DoubleToString(newSL, m_digits), ") avaz shod.");
         return true;
        }

      if(TimeCurrent() - m_lastFreezeErr >= 5)
        {
         m_lastFreezeErr = TimeCurrent();
         Print("TradeManager: khata dar nazdik kardan-e SL-e ticket ", ticket, " - ", m_trade.ResultRetcodeDescription());
        }

      return false;
     }

   //+------------------------------------------------------------------+
   //| Barresi-ye sood-e Moamele 2 bar hasab-e pip va ejra-ye nime-     |
   //| basti + risk-free kardan. In do amal digeh be ham vabaste        |
   //| NISTAN: age hajm baraye partial-close kafi nabashe (masalan      |
   //| hardo trade rooye hadeaghal-lot-e broker hastan), bejaye inke    |
   //| HICH KODOOM anjam nashe, SL hamchenan be Breakeven montaghel     |
   //| mishe.                                                            |
   //+------------------------------------------------------------------+
   void ManageTrade2PartialAndBreakeven(STradePair &pair)
     {
      RefreshPairFlags(pair);

      //--- hardo marhale (nime-basti + risk-free) anjam shode
      if(pair.trade2PartialDone && pair.trade2PartialClosed)
         return;

      if(pair.ticket2 == 0 || !PositionSelectByTicket(pair.ticket2))
         return; // Moamele 2 vojood nadare ya digeh baz nist

      //--- [v1.17] sood va Risk-Free-e Moamele 2 az gheimat-e vorud-e KHOD-E Moamele 2 hesab mishe (na Moamele 1).
      //--- ghablan az pair.entryPrice (= vorud-e Moamele 1) estefade mishod; ba slippage, ta'khir-e bein-e do ejra
      //--- ya joft-haye dasti (ta 60 sanie fasele) fasele-ye 500 pip va noghte-ye Risk-Free kami kaj mishod
      double entry2 = PositionGetDouble(POSITION_PRICE_OPEN);
      if(entry2 <= 0.0)
         entry2 = pair.entryPrice;

      double currentPrice = (pair.direction == POSITION_TYPE_BUY)
                             ? SymbolInfoDouble(m_symbol, SYMBOL_BID)
                             : SymbolInfoDouble(m_symbol, SYMBOL_ASK);

      double profitPips = (pair.direction == POSITION_TYPE_BUY)
                           ? (currentPrice - entry2) / m_pipSize
                           : (entry2 - currentPrice) / m_pipSize;

      if(profitPips < InpTrade2PartialPips)
         return;

      //--- 1) nime-basti. [Bug Fix v1.11] ghablan flag-e nime-basti faghat vaghti set mishod ke enteghal-e SL
      //--- ham movafagh bood; age PositionModify na-movafagh mishod, har tick yek nime-basti-e jadid anjam mishod
      //--- va hajm-e Moamele 2 tadrijan sefr mishod. Alan nime-basti flag-e joda dare va faghat yek bar anjam mishe
      if(!pair.trade2PartialClosed)
        {
         double currentVolume = PositionGetDouble(POSITION_VOLUME);
         double closeVolume   = NormalizeVolume(currentVolume * (InpTrade2PartialPercent / 100.0));
         double volMin        = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);

         bool partialFeasible = (closeVolume >= volMin) && (closeVolume < currentVolume);

         if(!partialFeasible)
           {
            Print("TradeManager: hajm-e Moamele 2 (", DoubleToString(currentVolume, 2),
                  " lot) baraye partial-close kafi nist (hadeaghal-lot-e broker = ",
                  DoubleToString(volMin, 2), " lot). Faghat SL be noghte-ye vorud montaghel mishe, ",
                  "hajm hamoon mimoone.");
            pair.trade2PartialClosed = true;
            SavePairFlags(pair);
           }
         else if(m_trade.PositionClosePartial(pair.ticket2, closeVolume))
           {
            pair.trade2PartialClosed = true;
            SavePairFlags(pair);
            Print("TradeManager: Moamele 2 (ticket ", pair.ticket2, ") be andaze-ye ",
                  DoubleToString(closeVolume, 2), " lot nime baste shod (sood ",
                  DoubleToString(profitPips, 1), " pip)");
           }
         else
           {
            pair.fails++;
            Print("TradeManager: khata dar nime-bastan-e Moamele 2 - ", m_trade.ResultRetcodeDescription(),
                  " (talash ", pair.fails, " az 5)");

            if(pair.fails >= 5)
              {
               Print("TradeManager: talash baraye nime-basti-e Moamele 2 motevaghef shod - faghat risk-free anjam mishe.");
               pair.trade2PartialClosed = true;
               SavePairFlags(pair);
              }
           }
        }

      //--- 2) risk-free: SL be noghte-ye vorud (hata age nime-basti na-movafagh bood - mohemtarin ghadam-e modiriat-e risk)
      if(pair.trade2PartialDone)
         return;

      if(!PositionSelectByTicket(pair.ticket2))
         return;

      double breakevenSL = MKBreakEvenPrice(pair.direction, entry2, m_pipSize, m_digits);   // [v1.17] vorud-e khod-e Moamele 2 (+ [v1.20] offset)
      double currentTP   = PositionGetDouble(POSITION_TP);

      //--- [v1.20] age SL (masalan ba trailing) ghablan az noghte-ye Risk-Free behtar shode, dast nemizanim
      double slNow = PositionGetDouble(POSITION_SL);
      if(slNow > 0.0 && ((pair.direction == POSITION_TYPE_BUY) ? (slNow >= breakevenSL) : (slNow <= breakevenSL)))
        {
         pair.trade2PartialDone = true;
         SavePairFlags(pair);
         return;
        }

      if(m_trade.PositionModify(pair.ticket2, breakevenSL, currentTP))
        {
         pair.trade2PartialDone = true;
         SavePairFlags(pair);
         Print("TradeManager: SL-e Moamele 2 rooye noghte-ye vorud (Risk-Free) gharar gereft: ",
               DoubleToString(breakevenSL, m_digits), " (vorud-e Moamele 2; vorud-e Moamele 1 = ",
               DoubleToString(pair.entryPrice, m_digits), ")");
        }
      else if(TimeCurrent() - m_lastBeErr >= 5)   // [v1.17] ghablan har tick log mishod
        {
         m_lastBeErr = TimeCurrent();
         Print("TradeManager: khata dar enteghal-e SL be noghte-ye vorud - ", m_trade.ResultRetcodeDescription());
        }
     }

   //+------------------------------------------------------------------+
   //| Pak kardan-e joft-moamele-haye ghair-fa'al az array (baraye      |
   //| jelogiri az bozorg shodan-e bi-nahayat-e array dar session-haye  |
   //| toolani)                                                          |
   //+------------------------------------------------------------------+
   void CompactInactivePairs()
     {
      int activeCount = 0;
      for(int i = 0; i < ArraySize(m_pairs); i++)
         if(m_pairs[i].active)
            activeCount++;

      if(activeCount == ArraySize(m_pairs))
         return; // hich chizi baraye pak kardan nist

      STradePair kept[];
      ArrayResize(kept, activeCount);
      int k = 0;
      for(int i = 0; i < ArraySize(m_pairs); i++)
        {
         if(m_pairs[i].active)
           {
            kept[k] = m_pairs[i];
            k++;
           }
        }

      ArrayResize(m_pairs, activeCount);
      for(int i = 0; i < activeCount; i++)
         m_pairs[i] = kept[i];
     }

   //+------------------------------------------------------------------+
   //| Round kardan-e hajm motabegh-e hadeaghal/hadeaksar/gam-e mojaz-e |
   //| broker                                                            |
   //+------------------------------------------------------------------+
   double NormalizeVolume(double volume)
     {
      return MKNormalizeVolume(m_symbol, volume);
     }

   //--- khata-haye mowaghati ke talash-e mojaddad baraye oon-ha bi-khatar ast
   bool IsRetryableRetcode(uint code)
     {
      return (code == TRADE_RETCODE_REQUOTE ||
              code == TRADE_RETCODE_PRICE_CHANGED ||
              code == TRADE_RETCODE_PRICE_OFF ||
              code == TRADE_RETCODE_REJECT ||
              code == TRADE_RETCODE_TOO_MANY_REQUESTS);
     }

   //--- [v1.17] khata-haye mowaghati-e baz kardan-e Moamele 1: order ersal nashode (ya rad shode), pas talash-e mojaddad bi-khatar ast.
   //--- TRADE_RETCODE_TIMEOUT ghasdan nist (momkene order ejra shode bashe va talash-e mojaddad moamele-ye tekrari baz kone)
   bool IsRetryableOpenRetcode(uint code)
     {
      return (IsRetryableRetcode(code) ||
              code == TRADE_RETCODE_CONNECTION ||
              code == TRADE_RETCODE_MARKET_CLOSED ||
              code == TRADE_RETCODE_CLIENT_DISABLES_AT);
     }
  };
//+------------------------------------------------------------------+
