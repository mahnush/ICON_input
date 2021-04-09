;*************************************************
; plot_grid.ncl
;
; plot limited area grid including the boundary interpolation and nudging zone
; 02/2017 : DWD
;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"

begin

  rad2deg = 45./atan(1.)                      ; radians to degrees


  ; --- open GRID and EXTERNAL PARAMETER files for reading:
  grid_file   = addfile("/work/bb1036/b380900/h_corse_run1/input/testgrid_10km_DOM02.nc", "r" )
  extpar_file = addfile("/work/bb1036/b380900/h_corse_run1/input/extpar_testgrid_10km_DOM02.nc", "r")

  ; --- read cell information
  clon_1 = grid_file->clon *rad2deg           ; cell center, lon
  clat_1 = grid_file->clat *rad2deg           ; cell center, lat
  vlat_1 = grid_file->clat_vertices * rad2deg
  vlon_1 = grid_file->clon_vertices * rad2deg



  ; --- open boundary grid file for reading (if available)

  bgrid_filename = "output/lateral_boundary.grid.nc"
  if (fileexists(bgrid_filename)) then
    bgrid_file = addfile(bgrid_filename, "r" )
    ; --- read cell information for boundary grid
    clon_b = bgrid_file->clon *rad2deg           ; cell center, lon
    clat_b = bgrid_file->clat *rad2deg           ; cell center, lat
    vlat_b = bgrid_file->clat_vertices * rad2deg
    vlon_b = bgrid_file->clon_vertices * rad2deg
  else
    bgrid_file = False
  end if

  ; --- set resources for a map plot.
  config1                      = True
  config1@gsnMaximize          = True
  config1@gsnFrame             = False        ; postpone map drawing until all lines are drawn ...
  config1@gsnDraw              = False

  ; --- define contour plot settings
  config1@cnFillOn             = True
  config1@cnFillMode           = "cellfill"
  config1@lbLabelBarOn         = False
  config1@cnInfoLabelOn        = False
  config1@cnLinesOn            = False
  config1@cnConstFEnableFill   = True
  config1@cnConstFLabelOn      = False
  config1@gsnLeftString        = ""
  config1@gsnRightString       = ""

  ; --- Tick marks
  config1@pmTickMarkDisplayMode = "Always"            ; turn on built-in tickmarks


  ; --- create a second resource for the ocean
  config2 = config1

  ; --- create another resource for the boundary grid
  config_b = config1


  ; -------------------------
  ; land-only map plot
  ;--------------------------

  ; --- specify map projection and clipping
  config1@mpProjection         = "Satellite"
  config1@mpCenterLonF         =  0.0
  config1@mpCenterLatF         =  60.0
  config1@mpLimitMode          = "LatLon"     ; required
  config1@mpMinLatF            =   30.0       ; min lat
  config1@mpMaxLatF            =   90.0       ; max lat
  config1@mpMinLonF            =  -120.0       ; min lon
  config1@mpMaxLonF            =   90.0       ; max lon

  ; --- coast lines
  config1@mpDataBaseVersion    = "MediumRes"
  config1@mpGridAndLimbOn      = True  
  config1@mpGridMaskMode       = "MaskNotOcean"
  config1@mpOutlineOn          = True
  config1@mpGreatCircleLinesOn = True

  ; --- define color map
  cmap = read_colormap_file("OceanLakeLandSnow")
  config1@cnFillPalette        = cmap(2:,:)

  ; --- define cell geometry
  config1@sfXArray             = clon_1
  config1@sfYArray             = clat_1
  config1@sfXCellBounds        = vlon_1
  config1@sfYCellBounds        = vlat_1


  ; --- define topography (over land)
  topo  = extpar_file->topography_c
  topo  = mask(topo,(extpar_file->FR_LAND .gt. 0.50),True)

  wks      = gsn_open_wks("ps","local_grid")
  contour1 = gsn_csm_contour_map(wks,topo,config1)


  ;-------------------------
  ; ocean-only map plot
  ;--------------------------

  ;  --- define topography (ocean)
  ocean = extpar_file->topography_c
  ocean = mask(ocean,(extpar_file->FR_LAND .lt. 0.50),True) 

  ; --- define cell geometry
  config2@sfXArray             = clon_1
  config2@sfYArray             = clat_1
  config2@sfXCellBounds        = vlon_1
  config2@sfYCellBounds        = vlat_1

  ; -- define contour levels
  config2@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  config2@cnMinLevelValF       = -50.               ; set min contour level
  config2@cnMaxLevelValF       =  2000.             ; set max contour level
  config2@cnLevelSpacingF      =  250.              ; set contour spacing

  ; --- define color map
  cmap2                        = read_colormap_file("cmp_haxby")      ; load new colortable
  cmap2(5,:)                   = 0.0                                  ; make last color transparent
  config2@cnFillPalette        = cmap2(2:5,:)

 
  contour2 = gsn_csm_contour(wks,ocean,config2)

  ; overlay contour2 (ocean) on contour1 (land)
  overlay(contour1,contour2)


  ;-------------------------
  ; boundary-region map plot
  ;--------------------------

  if (bgrid_file) then

    ; --- define cell geometry
    config_b@sfXArray             = clon_b
    config_b@sfYArray             = clat_b
    config_b@sfXCellBounds        = vlon_b
    config_b@sfYCellBounds        = vlat_b
  
    cmap_b                        = read_colormap_file("WhBlGrYeRe")     ; load new colortable
    config_b@cnFillPalette        = cmap_b(0:1,:)
  
    ; --- add transparency
    config_b@cnFillOpacityF        = 0.50     ; Half transparent
  
  
    dummy = new(dimsizes(clon_b),typeof(topo))
    dummy = 0.0
    dummy(0) = 0.00100   ; cheating so that NCL thinks the field is non-constant
    contour_b = gsn_csm_contour(wks,dummy,config_b)
  
    ; overlay contour_b (boundary region)
    overlay(contour1,contour_b)

  end if

  ; draw final plot
  draw (contour1)
  frame(wks)

end
