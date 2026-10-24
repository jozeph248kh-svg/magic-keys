//+------------------------------------------------------------------+
//|                                                AccountGuard.mqh  |
//|  AccountGuard.mqh - Mohafez-e Hesab                                |
//|  [v1.20] hadd-e zarar-e hafteghi, zarar-e motevali (joft-moamele), |
//|  tedad-e vorud dar rooz, fasele-ye zamani bein-e vorud-ha,         |
//|  afat-e equity az ghole, Margin Level                              |
//|  Hame ba tanzimat-e Group 14 kontrol mishan (default = ghair-faal) |
//+------------------------------------------------------------------+
#property strict

#ifndef __MAGICKEYS_ACCOUNTGUARD_MQH__
#define __MAGICKEYS_ACCOUNTGUARD_MQH__

#include "Settings.mqh"

#define MKG_FAR_FUTURE  ((datetime)4102444800)   // sal-e 2100: "ta reset-e dasti"
#define MKG_PAIR_WINDOW 120                       // do position ke dar in fasele (sanie) baz shodan = yek joft

struct SGuardPos
  {
   ulong    id;
   double   net;          // majmoo-e sood + commission + swap-e hame-ye deal-haye in position
   datetime entryTime;
   datetime lastOutTime;
   bool     open;
  };

class CAccountGuard
  {
private:
   string    m_symbol;
   double    m_peakEquity;
   datetime  m_pausedUntil;
   string    m_gvPeak;
   string    m_gvPause;
   datetime  m_lastPeakSave;

   //--- amar-e cache-shode (har 5 sanie tazeh mishe)
   datetime  m_lastScan;
   int       m_entriesToday;
   datetime  m_lastEntryTime;
   int       m_consecLosses;
   datetime  m_lastLossTime;
   double    m_weekLossPct;

   string    m_status;

   int FindPos(SGuardPos &arr[], const ulong id)
     {
      for(int i = ArraySize(arr) - 1; i >= 0; i--)
         if(arr[i].id == id)
            return i;
      return -1;
     }

   //--- history ro scan mikone va amar ro por mikone
   void Scan()
     {
      datetime now = TimeCurrent();
      if(m_lastScan != 0 && (now - m_lastScan) < 5)
         return;
      m_lastScan = now;

      m_entriesToday  = 0;
      m_lastEntryTime = 0;
      m_consecLosses  = 0;
      m_lastLossTime  = 0;
      m_weekLossPct   = 0.0;

      datetime dayStart  = now - (now % 86400);
      datetime weekStart = MKWeekStart(now);
      datetime from      = MathMin(weekStart, now - 14 * 86400);

      if(!HistorySelect(from, now + 60))
         return;

      SGuardPos positions[];
      double    weekClosed = 0.0;

      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;

         ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
            continue;

         datetime        dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         ENUM_DEAL_ENTRY entry    = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         bool            isOut    = (entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY || entry == DEAL_ENTRY_INOUT);

         double dealNet = HistoryDealGetDouble(ticket, DEAL_COMMISSION) + HistoryDealGetDouble(ticket, DEAL_FEE);
         if(isOut)
            dealNet += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP);

         //--- zarar-e hafteghi: hame-ye deal-haye hesab
         if(dealTime >= weekStart)
            weekClosed += dealNet;

         //--- faghat deal-haye khod-e EA rooye in symbol
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) != m_symbol)
            continue;

         long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         if(magic != (long)MKMagic(1) && magic != (long)MKMagic(2))
            continue;

         //--- vorud-haye Moamele 1 = tedad-e joft-haye baz-shode
         if(entry == DEAL_ENTRY_IN && magic == (long)MKMagic(1))
           {
            if(dealTime >= dayStart)
               m_entriesToday++;
            if(dealTime > m_lastEntryTime)
               m_lastEntryTime = dealTime;
           }

         //--- natije-ye har position
         ulong posId = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         int   idx   = FindPos(positions, posId);
         if(idx < 0)
           {
            idx = ArraySize(positions);
            ArrayResize(positions, idx + 1);
            positions[idx].id          = posId;
            positions[idx].net         = 0.0;
            positions[idx].entryTime   = dealTime;
            positions[idx].lastOutTime = 0;
            positions[idx].open        = false;
           }

         positions[idx].net += dealNet;
         if(isOut && dealTime > positions[idx].lastOutTime)
            positions[idx].lastOutTime = dealTime;
        }

      //--- zarar-e hafteghi (mesl-e TodayLossPercent: baste-shode + shenavar)
      double pnl          = weekClosed + AccountInfoDouble(ACCOUNT_PROFIT);
      double startBalance = AccountInfoDouble(ACCOUNT_BALANCE) - weekClosed;
      if(pnl < 0.0 && startBalance > 0.0)
         m_weekLossPct = -pnl / startBalance * 100.0;

      //--- position-haye hanooz baz
      for(int p = PositionsTotal() - 1; p >= 0; p--)
        {
         ulong t = PositionGetTicket(p);
         if(t == 0)
            continue;
         ulong ident = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
         int   idx   = FindPos(positions, ident);
         if(idx >= 0)
            positions[idx].open = true;
        }

      //--- gorooh-bandi be joft (position-haye ba fasele-ye vorud <= MKG_PAIR_WINDOW sanie = yek joft)
      int pc = ArraySize(positions);
      double   groupNet[];
      bool     groupOpen[];
      datetime groupLast[];
      datetime groupStart = 0;
      int      groups = 0;

      for(int k = 0; k < pc; k++)
        {
         if(groups == 0 || (positions[k].entryTime - groupStart) > MKG_PAIR_WINDOW)
           {
            groups++;
            ArrayResize(groupNet, groups);
            ArrayResize(groupOpen, groups);
            ArrayResize(groupLast, groups);
            groupNet[groups - 1]  = 0.0;
            groupOpen[groups - 1] = false;
            groupLast[groups - 1] = 0;
            groupStart = positions[k].entryTime;
           }

         int g = groups - 1;
         groupNet[g] += positions[k].net;
         if(positions[k].open)
            groupOpen[g] = true;
         if(positions[k].lastOutTime > groupLast[g])
            groupLast[g] = positions[k].lastOutTime;
        }

      //--- tedad-e zarar-haye motevali (az akhar be aval; joft-haye hanooz baz nadide gerefte mishan)
      for(int g = groups - 1; g >= 0; g--)
        {
         if(groupOpen[g])
            continue;

         if(groupNet[g] < 0.0)
           {
            m_consecLosses++;
            if(groupLast[g] > m_lastLossTime)
               m_lastLossTime = groupLast[g];
           }
         else
            break;
        }
     }

   void SavePeak(const bool force)
     {
      datetime now = TimeCurrent();
      if(!force && m_lastPeakSave != 0 && (now - m_lastPeakSave) < 5)
         return;

      m_lastPeakSave = now;
      GlobalVariableSet(m_gvPeak, m_peakEquity);
     }

   void SavePause()
     {
      GlobalVariableSet(m_gvPause, (double)(long)m_pausedUntil);
     }

public:
   CAccountGuard()
     {
      m_peakEquity    = 0.0;
      m_pausedUntil   = 0;
      m_lastPeakSave  = 0;
      m_lastScan      = 0;
      m_entriesToday  = 0;
      m_lastEntryTime = 0;
      m_consecLosses  = 0;
      m_lastLossTime  = 0;
      m_weekLossPct   = 0.0;
      m_status        = "";
     }

   void Init(const string symbol)
     {
      m_symbol  = symbol;
      string login = (string)AccountInfoInteger(ACCOUNT_LOGIN);
      m_gvPeak  = "MKEA_" + login + "_PeakEquity";
      m_gvPause = "MKEA_" + login + "_GuardPause";

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);

      if(InpResetGuardOnStart)
        {
         m_peakEquity  = equity;
         m_pausedUntil = 0;
         SavePeak(true);
         SavePause();
         Print("AccountGuard: ghole-ye equity (", DoubleToString(equity, 2), ") va tavaghof-haye mohafez reset shodan.");
        }
      else
        {
         m_peakEquity  = GlobalVariableCheck(m_gvPeak) ? GlobalVariableGet(m_gvPeak) : equity;
         m_pausedUntil = GlobalVariableCheck(m_gvPause) ? (datetime)(long)GlobalVariableGet(m_gvPause) : 0;

         if(m_peakEquity < equity)
            m_peakEquity = equity;

         SavePeak(true);
        }

      if(m_pausedUntil > TimeCurrent())
         Print("AccountGuard: hoshdar - vorud-e jadid ta ", (m_pausedUntil >= MKG_FAR_FUTURE ? "reset-e dasti (InpResetGuardOnStart)" :
               TimeToString(m_pausedUntil, TIME_DATE | TIME_MINUTES)), " motevaghef ast (afat-e equity).");
     }

   //--- har tick: ghole-ye equity va afat. needCloseAll = true yani bayad hame-ye moamele-ha baste beshan
   void OnTick(bool &needCloseAll)
     {
      needCloseAll = false;

      datetime now    = TimeCurrent();
      double   equity = AccountInfoDouble(ACCOUNT_EQUITY);

      //--- tavaghof tamoom shode: ghole-ye jadid az hamin lahze
      if(m_pausedUntil != 0 && m_pausedUntil < MKG_FAR_FUTURE && now >= m_pausedUntil)
        {
         m_pausedUntil = 0;
         m_peakEquity  = equity;
         SavePause();
         SavePeak(true);
         Print("AccountGuard: moddat-e tavaghof tamoom shod - ghole-ye equity dobare az ", DoubleToString(equity, 2), " shoroo mishe.");
        }

      if(equity > m_peakEquity)
        {
         m_peakEquity = equity;
         SavePeak(false);
        }
      else if(m_lastPeakSave != 0 && (now - m_lastPeakSave) >= 3600)
         SavePeak(true);   // GlobalVariable-ha ba 4 hafte adam-e dastresi pak mishan

      if(InpMaxEquityDrawdownPercent > 0.0 && m_pausedUntil <= now && m_peakEquity > 0.0)
        {
         double dd = (m_peakEquity - equity) / m_peakEquity * 100.0;
         if(dd >= InpMaxEquityDrawdownPercent)
           {
            m_pausedUntil = (InpDrawdownPauseHours > 0) ? (now + (datetime)(InpDrawdownPauseHours * 3600)) : MKG_FAR_FUTURE;
            SavePause();
            needCloseAll = InpDrawdownCloseAll;

            Print("AccountGuard: afat-e equity ", DoubleToString(dd, 2), "% (hadd: ", DoubleToString(InpMaxEquityDrawdownPercent, 2),
                  "%) - vorud-e jadid motevaghef shod", (InpDrawdownCloseAll ? " va hame-ye moamele-ha baste mishan." : "."));
           }
        }
     }

   //--- aya in lahze vorud-e jadid mojaz ast?
   bool Allow(string &reason)
     {
      reason = "";
      datetime now = TimeCurrent();

      if(m_pausedUntil > now)
        {
         reason = (m_pausedUntil >= MKG_FAR_FUTURE)
                  ? "tavaghof-e afat-e equity ta reset-e dasti (InpResetGuardOnStart)"
                  : "tavaghof-e afat-e equity ta " + TimeToString(m_pausedUntil, TIME_DATE | TIME_MINUTES);
         return false;
        }

      if(InpMinMarginLevelPercent > 0.0)
        {
         double level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
         if(level > 0.0 && level < InpMinMarginLevelPercent)
           {
            reason = "Margin Level (" + DoubleToString(level, 0) + "%) kamtar az hadd (" + DoubleToString(InpMinMarginLevelPercent, 0) + "%)";
            return false;
           }
        }

      bool needScan = (InpMaxEntriesPerDay > 0 || InpMaxWeeklyLossPercent > 0.0 ||
                       InpMaxConsecutiveLosses > 0 || InpMinMinutesBetweenEntries > 0);
      if(!needScan)
         return true;

      Scan();

      if(InpMaxEntriesPerDay > 0 && m_entriesToday >= InpMaxEntriesPerDay)
        {
         reason = "tedad-e vorud-e emrooz (" + IntegerToString(m_entriesToday) + ") be InpMaxEntriesPerDay resid";
         return false;
        }

      if(InpMaxWeeklyLossPercent > 0.0 && m_weekLossPct >= InpMaxWeeklyLossPercent)
        {
         reason = "zarar-e hafteghi " + DoubleToString(m_weekLossPct, 2) + "% (hadd: " + DoubleToString(InpMaxWeeklyLossPercent, 2) + "%)";
         return false;
        }

      if(InpMaxConsecutiveLosses > 0 && m_consecLosses >= InpMaxConsecutiveLosses && m_lastLossTime > 0)
        {
         datetime until = (InpConsecLossPauseHours > 0)
                          ? m_lastLossTime + (datetime)(InpConsecLossPauseHours * 3600)
                          : (m_lastLossTime - (m_lastLossTime % 86400)) + 86400;

         if(now < until)
           {
            reason = IntegerToString(m_consecLosses) + " joft-moamele-ye zarar-e motevali - tavaghof ta " + TimeToString(until, TIME_DATE | TIME_MINUTES);
            return false;
           }
        }

      if(InpMinMinutesBetweenEntries > 0 && m_lastEntryTime > 0 &&
         (now - m_lastEntryTime) < (datetime)(InpMinMinutesBetweenEntries * 60))
        {
         reason = "fasele ba vorud-e ghabli kamtar az " + IntegerToString(InpMinMinutesBetweenEntries) + " daghighe";
         return false;
        }

      return true;
     }

   //--- khat-e vaziat baraye panel / log
   string Status()
     {
      string reason;
      if(!Allow(reason))
         return "Guard: " + reason;

      return "";
     }
  };

#endif // __MAGICKEYS_ACCOUNTGUARD_MQH__
//+------------------------------------------------------------------+
