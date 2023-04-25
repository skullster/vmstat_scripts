BEGIN { FS = "[ ,\t]+"
        if (!time_frmt) {time_frmt=5}
        if (!test_name) {test_name="unknown"}
      }
NF == 2 { x_sum += $1
          y_sum += $2
          xy_sum += $1*$2
          x2_sum += $1*$1
          num += 1
          x[NR] = $1
          y[NR] = $2
        }
END { mean_x = x_sum / num
      mean_y = y_sum / num
      mean_xy = xy_sum / num
      mean_x2 = x2_sum / num
      slope = (mean_xy - (mean_x*mean_y)) / (mean_x2 - (mean_x*mean_x))
      y_inter = mean_y - slope * mean_x
      for (i = num; i > 0; i--) {
          ss_total += (y[i] - mean_y)**2
          ss_residual += (y[i] - (slope * x[i] + y_inter))**2
      }
      # Get the slope in radians
      slope_radians = atan2(slope,1)

      #Get the X intercept - time when Y is 0
      x_inter = "none"
      if (slope != 0) {
         x_inter = (y_inter * -1.0) / slope
      }

      # Get the array mid point
      # NOTE: awk array indices start at 1
      midpoint = int(num/2)
      # If array length is odd add 1 to the mid point
      if (num % 2 == 1)
         midpoint++

      # Vertical print
      #printf("Start point %g %.6f\n", x[1], y[1])
      #printf("Mid point %g %.6f\n", x[midpoint], y[midpoint])
      #printf("End point %g %.6f\n", x[num], y[num])
      #printf("Slope      :  %g\n", slope)
      #printf("Slope (rads) : %g\n", slope_radians)
      #printf("X Intercept  :  %g\n", x_inter)
      #printf("Y Intercept  :  %g\n", y_inter)
      #printf("Error measure %g\n", ss_residual)

      # Horizontal print
      printf("%*-g %.6f ", time_frmt, x[1], y[1])
      printf("%*-g %.6f ", time_frmt, x[midpoint], y[midpoint])
      printf("%*-g %.6f ", time_frmt, x[num], y[num])
      #printf("%+.5e ", slope)
      printf("%+.5e ", slope_radians)
      if ( x_inter == "none" ) {
         printf("%s ", x_inter)
      } else {
         printf("%+.5e ", x_inter)
      }
      printf("%+g ", y_inter)
      printf("%+.5e %s\n", ss_residual, test_name)
    }
