SELECT *
FROM core.vw_data_quality
WHERE valid_price_values = 0
   OR valid_volume = 0
   OR valid_high_low = 0
   OR valid_open_range = 0
   OR valid_close_range = 0
   OR large_daily_move_flag = 1;