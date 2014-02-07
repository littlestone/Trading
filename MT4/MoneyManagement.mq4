//+------------------------------------------------------------------+
//|                                              MoneyManagement.mq4 |
//|                                      Copyright 2014, Junjie Tang |
//|                                            razorsniper@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window

//---- input parameters
extern int    FontSize = 11;
extern double MaxRiskPercentage = 0.01;
int    nDigits;
int    nTimes;
double LeastPipPoint;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//---- indicators
   if(StringFind(Symbol(), "JPY", 0) >= 0 || StringFind(Symbol(), "XAU", 0) >= 0) {
      nDigits = 3;
      LeastPipPoint = 0.01;
      nTimes = 100;
   }
   else {
      nDigits = 5;
      LeastPipPoint = 0.0001;
      nTimes = 10000;
   }
//----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
//----
   ObjectDelete("MaxLotSize");
   ObjectDelete("MaxStopLoss");
   ObjectDelete("SwingRange");
//----
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw all
//----
   double SwingRange_MN1 = 0.0, SwingRange_W1 = 0.0, SwingRange_D1 = 0.0, SwingRange_H4 = 0.0, SwingRange_H1 = 0.0, MarginRequired = 0.0;
   double SwingRange_M30 = 0.0, SwingRange_M15 = 0.0, SwingRange_M5 = 0.0, SwingRange_M1 = 0.0, MaxStopLoss = 0.0, SwingRange = 0.0;
   double MinCapitalSize = 0.0, MaxRiskLots = 0.0, AvailableLots = 0.0, TotalOpenOrderLots = 0.0, TotalOrderRiskLots = 0.0;
   string Text_MaxLotSize = "", Text_MaxStopLoss = "", Text_SwingRange = "";
   
   // Total open order lots without risk
   for(int i = 0; i < OrdersTotal(); i++) {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      TotalOpenOrderLots += OrderLots();
      if(OrderStopLoss() != 0) {
         if(OrderType() == OP_BUY && OrderStopLoss() - OrderOpenPrice() >= 0) continue;
         if(OrderType() == OP_SELL && OrderOpenPrice() - OrderStopLoss() >= 0) continue;
      }
      TotalOrderRiskLots += OrderLots();
   }
   
   // Calculate average price swing range
   for(i = 1; i <= 240; i++) {
      SwingRange_MN1 += (iHigh(NULL, PERIOD_MN1, i) - iLow(NULL, PERIOD_MN1, i)) / Point / 10;
      SwingRange_W1 += (iHigh(NULL, PERIOD_W1, i) - iLow(NULL, PERIOD_W1, i)) / Point / 10;
      SwingRange_D1 += (iHigh(NULL, PERIOD_D1, i) - iLow(NULL, PERIOD_D1, i)) / Point / 10;
      SwingRange_H4 += (iHigh(NULL, PERIOD_H4, i) - iLow(NULL, PERIOD_H4, i)) / Point / 10;
      SwingRange_H1 += (iHigh(NULL, PERIOD_H1, i) - iLow(NULL, PERIOD_H1, i)) / Point / 10;
      SwingRange_M30 += (iHigh(NULL, PERIOD_M30, i) - iLow(NULL, PERIOD_M30, i)) / Point / 10;
      SwingRange_M15 += (iHigh(NULL, PERIOD_M15, i) - iLow(NULL, PERIOD_M15, i)) / Point / 10;
      SwingRange_M5 += (iHigh(NULL, PERIOD_M5, i) - iLow(NULL, PERIOD_M5, i)) / Point / 10;
      SwingRange_M1 += (iHigh(NULL, PERIOD_M1, i) - iLow(NULL, PERIOD_M1, i)) / Point / 10;
      
      if(i == 240) {
         SwingRange_MN1 /= i;
         SwingRange_W1 /= i;
         SwingRange_D1 /= i;
         SwingRange_H4 /= i;
         SwingRange_H1 /= i;
         SwingRange_M30 /= i;
         SwingRange_M15 /= i;
         SwingRange_M5 /= i;
         SwingRange_M1 /= i;
      }
   }
   
   // Calculate maximum stop loss pips
   MaxStopLoss = SwingRange_D1;
   
   // Calulate minimum capital size required for 1 mini lot (0.01)
   MinCapitalSize = MaxStopLoss / MaxRiskPercentage / 10;
   
   // Calculate margin required for 1 mini lot (0.01)
   MarginRequired = MarketInfo(Symbol(),MODE_MARGINREQUIRED) * 0.01;
   
   // Calculate maximum risk lots
   MaxRiskLots = MathFloor(AccountBalance() / (MinCapitalSize + MarginRequired)) * 0.01;
   if (MaxRiskLots==0.0) MaxRiskLots=0.01;
   
   // Calculate available lots
   AvailableLots = MaxRiskLots - TotalOrderRiskLots;
   
   // Display weekly average swing range in pips
   ObjectCreate("SwingRange", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("SwingRange", OBJPROP_CORNER, 0);
   ObjectSet("SwingRange", OBJPROP_XDISTANCE, 15);
   ObjectSet("SwingRange", OBJPROP_YDISTANCE, 15);
   Text_SwingRange = StringConcatenate("W/R: ",DoubleToStr(SwingRange_W1, 1));
   ObjectSetText("SwingRange", "", FontSize, "Consolas", Orange);
   ObjectSetText("SwingRange", Text_SwingRange);
   
   // Display maximum stop loss in pips
   ObjectCreate("MaxStopLoss", OBJ_LABEL, 0,0,0,0,0,0,0);
   ObjectSet("MaxStopLoss", OBJPROP_CORNER, 0);
   ObjectSet("MaxStopLoss", OBJPROP_XDISTANCE, 15);
   ObjectSet("MaxStopLoss", OBJPROP_YDISTANCE, 35);
   if (TotalOpenOrderLots > 0) {
      Text_MaxStopLoss = StringConcatenate("S/L: ", DoubleToStr(MaxStopLoss, 1));
   }
   else {
      Text_MaxStopLoss = StringConcatenate("S/L: ", DoubleToStr(MaxStopLoss, 1));
   }
   ObjectSetText("MaxStopLoss", "", FontSize, "Consolas", DeepSkyBlue);
   ObjectSetText("MaxStopLoss", Text_MaxStopLoss);
   
   // Display maximume lot size available
   if (AvailableLots >= 0) {
      ObjectCreate("MaxLotSize", OBJ_LABEL, 0,0,0,0,0,0,0);
      ObjectSet("MaxLotSize", OBJPROP_CORNER, 0);
      ObjectSet("MaxLotSize", OBJPROP_XDISTANCE, 15);
      ObjectSet("MaxLotSize", OBJPROP_YDISTANCE, 55);
      Text_MaxLotSize = StringConcatenate("M/L: ", DoubleToStr(AvailableLots, 2));
      ObjectSetText("MaxLotSize", "", FontSize, "Consolas", Gold);
      if (AvailableLots - TotalOrderRiskLots > 0) {
         ObjectSetText("MaxLotSize", "", FontSize, "Consolas", Lime); 
      }
      else {
         Text_MaxLotSize = StringConcatenate("O/L:  ", DoubleToStr(TotalOpenOrderLots, 2));
         ObjectSetText("MaxLotSize", "", FontSize, "Consolas", Lavender);
      }
      ObjectSetText("MaxLotSize", Text_MaxLotSize);
   }
   
   RefreshRates();   // automatically refresh the chart
   WindowRedraw();   // now redraw all
   
//----
   return(0);
}
//+------------------------------------------------------------------+