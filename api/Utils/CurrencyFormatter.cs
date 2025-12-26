namespace RealEstateHubAPI.Utils
{
    public static class CurrencyFormatter
    {
        public static string FormatCurrency(decimal amount)
        {
            if (amount >= 1000000)
            {
                return (amount / 1000000M).ToString("0.#") + " triệu";
            }
            else if (amount >= 1000)
            {
                return (amount / 1000M).ToString("0.#") + " nghìn";
            }
            else
            {
                return amount.ToString("0");
            }
        }

         public static string FormatCurrencyWithUnit(decimal amount)
        {
            return FormatCurrency(amount) + " VNĐ";
        }
    }
}

