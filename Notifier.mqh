//+------------------------------------------------------------------+
//|                                                   Notifier.mqh   |
//|  Notifier.mqh - Notification (Alert / Push / Email) va log-e CSV   |
//|  [v1.20] Hame-ye hoshdar-ha az in ja mirand; har kanal va har noe   |
//|  rooydad ro mishe ba tanzimat (Group 15 va 16) roshan/khamoosh kard |
//+------------------------------------------------------------------+
#property strict

#ifndef __MAGICKEYS_NOTIFIER_MQH__
#define __MAGICKEYS_NOTIFIER_MQH__

#include "Settings.mqh"

//--- aya in noe-e rooydad ejaze-ye notification dare?
bool MKNotifyKindEnabled(const ENUM_NOTIFY_KIND kind)
  {
   switch(kind)
     {
      case NOTIFY_SIGNAL: return InpNotifyOnSignal;
      case NOTIFY_ENTRY:  return InpNotifyOnEntry;
      case NOTIFY_CLOSE:  return InpNotifyOnClose;
      case NOTIFY_GUARD:  return InpNotifyOnGuard;
      default:            return true;
     }
  }

//--- ersal-e peyam be kanal-haye roshan (Popup / Push / Email). Dar Tester hichkodoom ersal nemishe
void MKNotify(const ENUM_NOTIFY_KIND kind, const string message)
  {
   if(!MKNotifyKindEnabled(kind))
      return;

   if(MQLInfoInteger(MQL_TESTER) != 0)
      return;

   string text = (StringFind(message, "MagicKeysEA") == 0) ? message : ("MagicKeysEA " + _Symbol + ": " + message);

   if(InpNotifyPopup)
      Alert(text);

   if(InpNotifyPush)
     {
      //--- Push hadeaksar 255 character
      if(!SendNotification(StringSubstr(text, 0, 250)))
         Print("Notifier: ersal-e Push ba khata mowajeh shod (", GetLastError(), ") - MetaQuotes ID ro check kon.");
     }

   if(InpNotifyEmail)
     {
      if(!SendMail("MagicKeysEA " + _Symbol, text))
         Print("Notifier: ersal-e Email ba khata mowajeh shod (", GetLastError(), ") - tanzimat-e Email ro check kon.");
     }
  }

//--- esm-e file-e CSV: MagicKeysEA_<symbol>_<hesab>.csv
string MKCsvFileName()
  {
   return "MagicKeysEA_" + _Symbol + "_" + (string)AccountInfoInteger(ACCOUNT_LOGIN) + ".csv";
  }

//--- yek radif be file-e CSV ezafe mikone (age file nabood, header ham minevise)
void MKCsvAppend(const string line)
  {
   if(!InpCsvLogEnable)
      return;

   string name = MKCsvFileName();
   int    flags = FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE;
   int    handle = FileOpen(name, flags);

   if(handle == INVALID_HANDLE)
     {
      Print("Notifier: baz kardan-e file-e CSV (", name, ") ba khata mowajeh shod: ", GetLastError());
      return;
     }

   if(FileSize(handle) == 0)
      FileWriteString(handle, "time,symbol,deal,position,type,entry,volume,price,sl,tp,profit,commission,swap,magic,comment\r\n");

   FileSeek(handle, 0, SEEK_END);
   FileWriteString(handle, line + "\r\n");
   FileClose(handle);
  }

//--- deal-e jadid ro (agar marbut be EA bashe) dar CSV zakhire mikone va dar surat-e bastan, notification mide.
//--- includeManual: position-haye dasti-ye jazb-shode (magic = 0) ham jozve-ye EA hesab beshan
void MKHandleDeal(const ulong dealTicket, const bool includeManual)
  {
   if(dealTicket == 0 || !HistoryDealSelect(dealTicket))
      return;

   if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
      return;

   ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
   if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
      return;

   long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   bool mine  = (magic == (long)MKMagic(1) || magic == (long)MKMagic(2) || (includeManual && magic == 0));
   if(!mine)
      return;

   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

   int    digits     = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double volume     = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
   double price      = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
   double profit     = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
   double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
   double swap       = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
   double slv        = HistoryDealGetDouble(dealTicket, DEAL_SL);
   double tpv        = HistoryDealGetDouble(dealTicket, DEAL_TP);
   ulong  posId      = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   datetime when     = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
   string comment    = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   StringReplace(comment, ",", ";");

   string entryText = "IN";
   if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
      entryText = "OUT";
   else if(entry == DEAL_ENTRY_INOUT)
      entryText = "INOUT";

   string line = TimeToString(when, TIME_DATE | TIME_SECONDS) + "," + _Symbol + "," + (string)dealTicket + "," + (string)posId + "," +
                 (type == DEAL_TYPE_BUY ? "BUY" : "SELL") + "," + entryText + "," + DoubleToString(volume, 2) + "," +
                 DoubleToString(price, digits) + "," + DoubleToString(slv, digits) + "," + DoubleToString(tpv, digits) + "," +
                 DoubleToString(profit, 2) + "," + DoubleToString(commission, 2) + "," + DoubleToString(swap, 2) + "," +
                 (string)magic + "," + comment;

   MKCsvAppend(line);

   if(entry == DEAL_ENTRY_IN)
     {
      MKNotify(NOTIFY_ENTRY, "moamele baz shod: " + (type == DEAL_TYPE_BUY ? "BUY " : "SELL ") + DoubleToString(volume, 2) +
               " lot @ " + DoubleToString(price, digits));
     }
   else
     {
      double net = profit + commission + swap;
      MKNotify(NOTIFY_CLOSE, "moamele baste shod: " + DoubleToString(volume, 2) + " lot @ " + DoubleToString(price, digits) +
               " | natije: " + DoubleToString(net, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
     }
  }

#endif // __MAGICKEYS_NOTIFIER_MQH__
//+------------------------------------------------------------------+
