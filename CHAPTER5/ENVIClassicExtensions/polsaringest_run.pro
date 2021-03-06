; docformat = 'rst'
; polSARingest_run.pro
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.

PRO polsaringest_run_define_buttons, buttonInfo
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, $
    VALUE = 'polSAR Covariance Matrix', $
    REF_VALUE = 'AIRSAR Scattering Classification', $
    EVENT_PRO = 'polsaringest_run', $
    UVALUE = 'ENVI',$
    POSITION = 'after'
END

;+
; :Description:
; utility to ingest georeferenced single, dual or quad polSAR 
; files generated by ENVI/SARscape or polSARpro/MapReady 
; from TerraSAR-X, Radarsat-2, Cosmo-Skymed SLC images and 
; convert to a single float32 image.
; :Params:
;      event:  in, required
;         if called from the ENVI Classic menu
; :KEYWORDS:
;    NONE
; :Uses:
;    ENVI
; :Author:
;    Mort Canty (2014)
;-    
pro polSARingest_run, event

   COMPILE_OPT IDL2
   ;  Standard error handling.
   Catch, theError
   IF theError NE 0 THEN BEGIN
     Catch, /CANCEL
     void = Error_Message()
     RETURN
   ENDIF
   
   dir = dialog_pickfile(/directory, title='Choose directory ')
   cd, dir

; get (spatial subset of) the C11 file first   
   envi_select, title='Choose (spatial subset of) one component', $
                fid=fid, dims=dims, pos=pos, /band_only
   if (fid eq -1) then begin       
         print, 'cancelled'
         return
      end    
   envi_file_query, fid, fname=fname
   cols = dims[2]-dims[1]+1
   rows = dims[4]-dims[3]+1
; map tie point
   map_info = envi_get_map_info(fid=fid)
   envi_convert_file_coordinates, fid, $
     dims[1], dims[3], e, n, /to_map
   map_info.mc = [0D,0D,e,n]
; output image (float32, bsq)
   outim = fltarr(cols,rows,9)
   envi_file_mng,/remove,id=fid 
   bandnames = ['C11','C12re','C12im','C13re','C13im','C22','C23re','C23im','C33']    
 
; get a list of all files   
   files = file_search()
; accumulate the matrix elements 
   foreach file, files do begin    
;   special case: single polarimetry    
     if stregex(file,'pwr_geo',/boolean) and not stregex(file,'hdr|sml',/boolean) then begin
       envi_open_file, file, r_fid=fid
       outim[*,*,0] = envi_get_data(fid=fid,dims=dims,pos=pos)
       envi_file_mng,/remove,id=fid
     endif    
;   dual and quad polarimetry     
     if (stregex(file,'hh_hh_geo',/boolean) or stregex(file,'C11.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin
       envi_open_file, file, r_fid=fid
       outim[*,*,0] = envi_get_data(fid=fid,dims=dims,pos=pos)
       envi_file_mng,/remove,id=fid
     endif    
      if (stregex(file,'re_hh_hv_geo',/boolean) or stregex(file,'C12_real.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,1] = envi_get_data(fid=fid,dims=dims,pos=pos)
        envi_file_mng,/remove,id=fid
      endif 
      if (stregex(file,'im_hh_hv_geo',/boolean) or stregex(file,'C12_imag.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,2] = envi_get_data(fid=fid,dims=dims,pos=pos)
        envi_file_mng,/remove,id=fid        
      endif     
      if (stregex(file,'re_hh_vv_geo',/boolean) or stregex(file,'C13_real.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,3] = envi_get_data(fid=fid,dims=dims,pos=pos)
        envi_file_mng,/remove,id=fid        
      endif 
      if (stregex(file,'im_hh_vv_geo',/boolean) or stregex(file,'C13_imag.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,4] = envi_get_data(fid=fid,dims=dims,pos=pos)
        envi_file_mng,/remove,id=fid        
      endif      
      if (stregex(file,'hv_hv_geo',/boolean) or stregex(file,'C22.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,5] = envi_get_data(fid=fid,dims=dims,pos=pos)
        envi_file_mng,/remove,id=fid        
      endif   
      if (stregex(file,'re_hv_vv_geo',/boolean) or stregex(file,'C23_real.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,6] = envi_get_data(fid=fid,dims=dims,pos=pos)
        envi_file_mng,/remove,id=fid        
      endif   
      if (stregex(file,'im_hv_vv_geo',/boolean) or stregex(file,'C23_imag.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,7] = envi_get_data(fid=fid,dims=dims,pos=pos)
        envi_file_mng,/remove,id=fid        
      endif   
      if (stregex(file,'vv_vv_geo',/boolean) or stregex(file,'C33.tif',/boolean)) and not stregex(file,'hdr|sml',/boolean) then begin 
        envi_open_file, file, r_fid=fid
        outim[*,*,8] = envi_get_data(fid=fid,dims=dims,pos=pos)       
        envi_file_mng,/remove,id=fid           
      endif     
   endforeach       
   for i = 0, 8 do if total(outim[*,*,i]) eq 0 then bandnames[i] = '-'
   
   idx = where(bandnames ne '-',bands)
   if bands gt 0 then outim = outim[*,*,idx] else message, 'no image bands'
   bandnames = bandnames[idx]
   idx = where(finite(outim,/NAN),count)
   if count gt 0 then outim[idx]=0.0
   
; write to memory or disk   
   base = widget_auto_base(title='Output file')
   sb = widget_base(base, /row, /frame)
   wp = widget_outf(sb, uvalue='outf', /auto)
   result = auto_wid_mng(base)
   if (result.accept eq 0) then begin
      print, 'output cancelled'
      return
   end else begin
      openw, lun, result.outf, /get_lun    
      writeu, lun, outim
      free_lun, lun
      envi_setup_head,fname=result.outf, $
                  descrip = 'polSAR covariance matrix file '+systime(), $
                  ns = cols, $
                  nl=rows, nb = bands, $
                  data_type = 4, $
                  file_type = 0, $
                  interleave = 0, $
                  map_info = map_info, $
                  bnames = bandnames, /write
   endelse                
end

