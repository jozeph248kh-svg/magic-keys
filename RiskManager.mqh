//+------------------------------------------------------------------+
//|                                                 RiskManager.mqh   |
//|  RiskManager.mqh - Modiriat Risk va Position                      |
//|  Vazife: mohasebeye hajme moamele bar asas darsad risk az balance  |
//|                                                                    |
//|  [Update / Bug Fix]: CalculateStopLoss(), CalculateTakeProfit() va |
//|  GetRiskRewardRatio() az in nasxe hazf shodan. Dalil: TradeManager |
//|  khodesh SL/TP ro bar asas pip-settings (Group 4 dar Settings.mqh) |
//|  mohasebe mikone; vojoode do settings-e joda baraye SL/TP (point   |
//|  dar in file va pip dar TradeManager) faghat baese sardargomi      |
//|  mishod - karbar InpStopLossPoints ro avaz mikard vali hich taghiri|
//|  dar moamelat nemidid, chon oon settings digeh estefade nemishod.  |
//+------------------------------------------------------------------+
#property strict

#include "Settings.mqh"

//+------------------------------------------------------------------+
//| Class Modiriat Risk                                               |
//+------------------------------------------------------------------+
class CRiskManager
  {
private:
   string   m_symbol;
   double   m_tickValue;
   double   m_tickSize;
   double   m_point;
   int      m_digits;
   double   m_volumeMin;
   double   m_volumeMax;
   double   m_volumeStep;
   double   m_lastRiskPerLot;   // [v1.12] risk-e pooli-ye 1 lot dar akharin mohasebe (ba SL-e hamoon mohasebe)

public:
   void Init(string symbol)
     {
      m_symbol     = symbol;
      m_tickValue  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      m_tickSize   = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      m_point      = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      m_digits     = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      m_volumeMin  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      m_volumeMax  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      m_volumeStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      m_lastRiskPerLot = 0.0;
     }

   //+------------------------------------------------------------------+
   //| Hajm-e lot ro bar asas darsad-e risk az balance-e fe'li mohasebe |
   //| mikone.                                                          |
   //| Formula: risk-e pooli = balance * (darsad-e risk / 100)          |
   //|          lot = risk-e pooli / (fasele-ye SL bar hasab-e point *  |
   //|                                 arzesh-e har point)               |
   //| verbose = false: hoshdar-ha Print nemishan (baraye pish-namayesh-e|
   //| panel ke har sanie seda zade mishe)                                |
   //+------------------------------------------------------------------+
   double CalculateLotSize(int stopLossPoints, bool verbose = true)
     {
      double balance   = MKRiskBaseAmount();   // [v1.20] balance ya equity (InpRiskBase)
      double riskMoney = balance * (InpRiskPercent / 100.0);

      //--- [v1.11] arzesh-e tick ba nerkh-e arz taghir mikone (jofte-arz-haye cross, tala, ...) - har bar tazeh mikhoonim
      double liveTickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
      if(liveTickValue <= 0.0)
         liveTickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      if(liveTickValue > 0.0)
         m_tickValue = liveTickValue;

      m_lastRiskPerLot = 0.0;

      if(stopLossPoints <= 0 || m_tickSize <= 0 || m_tickValue <= 0)
        {
         if(verbose)
            Print("RiskManager: parametr-haye na-motabar baraye mohasebeye lot - bargasht be hadeaghal-e hajm");
         return NormalizeVolume(m_volumeMin);
        }

      //--- arzesh-e har point-e harekat-e gheimat be ezaye 1 lot
      double pointValue = (m_tickValue / m_tickSize) * m_point;
      m_lastRiskPerLot  = stopLossPoints * pointValue;

      double rawLot = riskMoney / (stopLossPoints * pointValue);

      double lot = NormalizeVolume(rawLot);

      //--- [v1.20] sagf/kaf-e hajm-e kol (InpMaxTotalLot / InpMinTotalLot)
      if(InpMaxTotalLot > 0.0 && lot > InpMaxTotalLot)
        {
         if(verbose)
            Print("RiskManager: hajm (", DoubleToString(lot, 2), ") bishtar az InpMaxTotalLot (", DoubleToString(InpMaxTotalLot, 2), ") bood - kam shod.");
         lot = NormalizeVolume(InpMaxTotalLot);
        }
      if(InpMinTotalLot > 0.0 && lot < InpMinTotalLot)
        {
         if(verbose)
            Print("RiskManager: hajm (", DoubleToString(lot, 2), ") kamtar az InpMinTotalLot (", DoubleToString(InpMinTotalLot, 2), ") bood - bala raft (risk afzayesh miyabad).");
         lot = NormalizeVolume(InpMinTotalLot);
        }

      //--- barresi ke risk-e vaghei az hadeaksar-e mojaz forogh nare (be dalile round shodan-e hajm)
      double actualRisk = lot * stopLossPoints * pointValue;
      if(verbose && actualRisk > riskMoney * 1.05) // 5% tolerance baraye round shodan-e hajm (pish-namayesh-e panel ba verbose = false saket)
        {
         Print("RiskManager: hoshdar - risk-e mohasebeshode (", DoubleToString(actualRisk,2),
               ") kami bishtar az hadde mojaz (", DoubleToString(riskMoney,2), ") ast, be dalile gam-e hajm.");
        }

      return lot;
     }

   //+------------------------------------------------------------------+
   //| Round kardan-e hajm motabegh-e hadeaghal/hadeaksar/gam-e mojaz-e |
   //| broker                                                            |
   //+------------------------------------------------------------------+
   double NormalizeVolume(double volume)
     {
      return MKNormalizeVolume(m_symbol, volume);
     }

   //+------------------------------------------------------------------+
   //| [v1.12] Risk-e vaghei (darsad-e balance) baraye ye hajm-e kol, ba |
   //| fasele-ye SL-e akharin CalculateLotSize(). 0 = mohasebe nashode    |
   //+------------------------------------------------------------------+
   double RiskPercentForLot(double lot)
     {
      double balance = MKRiskBaseAmount();   // [v1.20]
      if(balance <= 0.0 || m_lastRiskPerLot <= 0.0)
         return 0.0;

      return lot * m_lastRiskPerLot / balance * 100.0;
     }
  };
//+------------------------------------------------------------------+
