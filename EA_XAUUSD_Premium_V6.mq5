//+------------------------------------------------------------------+
//| EA XAUUSD Premium v6 - Advanced Risk Management, Hedging & News  |
//+------------------------------------------------------------------+
#property strict

#include <stdlib.mqh>
#include <string.mqh>

// Input Parameter
input ENUM_TIMEFRAMES Timeframe = PERIOD_M15;
input ENUM_TIMEFRAMES HigherTF1 = PERIOD_H1, HigherTF2 = PERIOD_H4;
input double RiskPercentage = 1.5;          // Persentase risiko per trade
input double ATRMultiplier = 1.8;
input int GridDistance = 100;               // Jarak antar grid dalam pip
input bool UseHedgingMode = true;           // Mode Hedging
input bool UseNewsFilter = true;            // Gunakan filter berita
input bool UseDynamicLotSizing = true;      // Menyesuaikan lot secara dinamis

// Fungsi untuk menghitung ATR
double GetATR(ENUM_TIMEFRAMES timeframe)
{
   return iATR(_Symbol, timeframe, 14, 0);
}

// Fungsi untuk menghitung ukuran lot berdasarkan persentase risiko
double CalculateLotSize(double stopLossPips, double accountBalance, double riskPercentage)
{
   double riskAmount = accountBalance * riskPercentage / 100;
   double lotSize = riskAmount / (stopLossPips * MarketInfo(_Symbol, MODE_POINT));
   return NormalizeDouble(lotSize, 2);  // Menjaga dua angka di belakang koma
}

// Fungsi Hedging (membuka Buy & Sell jika harga bergerak melawan posisi)
void HedgingMode()
{
   if (UseHedgingMode)
   {
      // Jika posisi Buy dan Sell terbuka, lanjutkan untuk membuka keduanya
      if (PositionSelect(_Symbol))
      {
         double buyPrice = 0, sellPrice = 0;
         if (OrderType() == OP_BUY)
            buyPrice = OrderOpenPrice();
         else if (OrderType() == OP_SELL)
            sellPrice = OrderOpenPrice();
            
         if (buyPrice != 0 && sellPrice == 0)
         {
            OrderSend(_Symbol, OP_SELL, 0.1, Bid, 10, 0, 0, "Hedging Sell", 123);
         }
         else if (sellPrice != 0 && buyPrice == 0)
         {
            OrderSend(_Symbol, OP_BUY, 0.1, Ask, 10, 0, 0, "Hedging Buy", 123);
         }
      }
   }
}

// Fungsi untuk menyesuaikan lot size secara dinamis
void DynamicLotSizing(double stopLossPips)
{
   if (UseDynamicLotSizing)
   {
      double lotSize = CalculateLotSize(stopLossPips, AccountBalance(), RiskPercentage);
      // Membuka posisi berdasarkan ukuran lot dinamis
      OrderSend(_Symbol, OP_BUY, lotSize, Ask, 10, Ask - ATRMultiplier * GetATR(Timeframe), Ask + 2 * ATRMultiplier * GetATR(Timeframe), "Dynamic Buy", 123);
   }
}

// Fungsi utama EA
void OnTick()
{
   // Memanggil fungsi Hedging jika mode aktif
   HedgingMode();

   double ATR = GetATR(Timeframe);
   double stopLossPips = ATR * ATRMultiplier; // Menghitung stop loss berdasarkan ATR

   // Memanggil DynamicLotSizing untuk menyesuaikan ukuran lot
   DynamicLotSizing(stopLossPips);

   // Cek sinyal trading dan buka posisi berdasarkan strategi lainnya
   // Misalnya menggunakan Fibonacci, MA, dan indikator lainnya untuk sinyal buy/sell
   if (UseNewsFilter) 
   {
      // Cek apakah ada berita besar yang dapat mempengaruhi pasar
      if (IsHighImpactNews())
      {
         Print("Tunggu, ada berita besar yang akan datang.");
         return;  // Jangan open posisi jika ada berita besar
      }
   }

   // Fungsi untuk membuka posisi berdasarkan sinyal
   if (Ask > iHigh(_Symbol, Timeframe, 1)) // Buy ketika harga menembus high candle sebelumnya
   {
      OrderSend(_Symbol, OP_BUY, 0.1, Ask, 10, Ask - ATRMultiplier * ATR, Ask + 2 * ATRMultiplier * ATR, "Breakout Buy", 123);
   }
   else if (Bid < iLow(_Symbol, Timeframe, 1)) // Sell ketika harga menembus low candle sebelumnya
   {
      OrderSend(_Symbol, OP_SELL, 0.1, Bid, 10, Bid + ATRMultiplier * ATR, Bid - 2 * ATRMultiplier * ATR, "Breakout Sell", 123);
   }
}

// Fungsi untuk mengecek apakah ada berita besar yang dapat mempengaruhi pasar
bool IsHighImpactNews()
{
   // Implementasikan filter berita melalui API atau sumber berita
   // Misalnya, cek jika ada berita dengan dampak tinggi (red flag)
   return false;  // Simulasi bahwa tidak ada berita besar saat ini
}
