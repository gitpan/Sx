#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "libsx.h"
#include "libsx_private.h"
#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>
#ifdef XAW3D
#include <X11/Xaw3d/AsciiText.h>
#include <X11/Xaw3d/AsciiSrc.h>
#else
#include <X11/Xaw/AsciiText.h>
#include <X11/Xaw/AsciiSrc.h>
#endif

typedef char **String_Array;
typedef short *RGB_Array;
typedef unsigned char *Byte_Array;

char *		GetWidgetDat();
Widget		Make3Com(), MakeThreeList();
String_Array	XS_unpack_String_Array();
XPoint *	XS_unpack_XPointPtr();

#define MAXARGS 5

struct Edata
{
    Widget w;
    SV *data;
    SV *mysv;
    char *fun[MAXARGS];
    CV *cvcache[MAXARGS];
#define CB_GENFUN 0
#define CB_BU_IDX 1
#define CB_BD_IDX 2
#define CB_KP_IDX 3
#define CB_MM_IDX 4

#define CB_BUTT_1 1
#define CB_BUTT_2 2
#define CB_BUTT_3 3

#define CB_RESFUN 0
#define CB_REAFUN 1
#define CB_EXPFUN 2
};

String_Array XS_unpack_String_Array(ax, items)
int ax;
int items;
{
    char **argv;
    int i;
    
    Newz(666, argv, items+1, char *);
    for (i = 0; i < items; i++)
      argv[i] = SvPV(ST(i), na);
    argv[i] = NULL;
    return argv;
}

char *NewString(s)
char *s; {
  char *tmp;

  Newz(666,tmp,strlen(s)+1,char);
  strcpy(tmp,s);
  return tmp;
}

void do_callback(callback, index)
struct Edata *callback;
int index;
{
    register CV *cv;
    GV *gv = Nullgv;
    GV *gvjunk;
    HV *hvjunk;
    BINOP myop;
    
    if (!callback->fun[index] || *(callback->fun[index]) == '\0')
	return;
 
    /* If the CV has not been cached yet, work it out now */
    cv = callback->cvcache[index];
    if (!cv)
    {
      gv = gv_fetchpv(callback->fun[index], FALSE,SVt_PVCV);

      /* If we haven't found anything, give up */
      if (gv == Nullgv)
	croak("method %s not found for callback",callback->fun[index]);

      if (!(cv = sv_2cv(gv, &hvjunk, &gvjunk, FALSE)))
	croak("sv_2cv failed on method");
      callback->cvcache[index] = cv; /* save for future use */
    }
    perl_call_sv((SV*)cv, G_SCALAR);
}

void button_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);
  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void but1_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_BUTT_1] && *(char*)dd->fun[CB_BUTT_1]) {
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_BUTT_1);
  }
}

void but2_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_BUTT_2] && *(char*)dd->fun[CB_BUTT_2]) {
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_BUTT_2);
  }
}

void but3_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_BUTT_3] && *(char*)dd->fun[CB_BUTT_3]) {
    SvREFCNT_inc(dd->mysv);
    XPUSHs(dd->mysv);
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_BUTT_3);
  }
}

void string_callback(w, string, data)
Widget w;
char *string;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(string,strlen(string))));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void scroll_callback(w, new_val, data)
Widget w;
float new_val;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  dd->fun[0]; new_val;
  PUSHMARK(sp);

  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVnv((double)new_val)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void list_callback(w, string, index, data)
Widget w;
char *string;
int index;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(string,strlen(string))));
    XPUSHs(sv_2mortal(newSViv(index)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void threelist_callback(w, string, index, event_mask, data)
Widget w;
char *string;
int index;
unsigned int event_mask;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(string,strlen(string))));
    XPUSHs(sv_2mortal(newSViv(index)));
    XPUSHs(sv_2mortal(newSViv(event_mask)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void general_callback(data)
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
  Safefree(dd->fun[CB_GENFUN]);
  Safefree(dd);  /* Timeout callback are called only once */
}

void io_callback(data, fd)
void *data;
int *fd; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(sv_2mortal(newSViv(*fd)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void redisplay_callback(w, new_width, new_height, data)
Widget w;
int new_width, new_height;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(new_width)));
    XPUSHs(sv_2mortal(newSViv(new_height)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void button_down_callback(w, button, x, y, data)
Widget w;
int button, x, y;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_BD_IDX] && *(char*)dd->fun[CB_BD_IDX]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(button)));
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_BD_IDX);
  }
}

void button_up_callback(w, button, x, y, data)
Widget w;
int button, x, y;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_BU_IDX] && *(char*)dd->fun[CB_BU_IDX]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(button)));
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_BU_IDX);
  }
}

void keypress_callback(w, input, up_or_down, data)
Widget w;
char *input;
int up_or_down;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_KP_IDX] && *(char*)dd->fun[CB_KP_IDX]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSVpv(input,strlen(input))));
    XPUSHs(sv_2mortal(newSViv(up_or_down)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_KP_IDX);
  }
}

void motion_callback(w, x, y, data)
Widget w;
int x, y;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  if (dd->fun[CB_MM_IDX] && *(char*)dd->fun[CB_MM_IDX]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_MM_IDX);
  }
}

void expose_callback(w, event, region, data)
Widget w;
XExposeEvent *event;
Region region;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  printf("Expose CB call (%x %x %x %x)\n",w, event, region, data);
  return;
  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void resize_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  printf("Resize CB call (%x %x)\n",w, data);
  return;
  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}

void realize_callback(w, data)
Widget w;
void *data; 
{
  struct Edata *dd = data;
  dSP;

  PUSHMARK(sp);

  printf("Realize CB call (%x %x)\n",w, data);
  return;
  if (dd->fun[CB_GENFUN] && *(char*)dd->fun[CB_GENFUN]) {
    XPUSHs(SvREFCNT_inc(dd->mysv));
    XPUSHs(sv_mortalcopy(dd->data));
    PUTBACK;
    do_callback(dd,CB_GENFUN);
  }
}



struct Edata	*tmp;

MODULE = Sx	PACKAGE = Sx	PREFIX = Sx_


void
OpenDisplay(args,...)
	String_Array	args = NO_INIT
	PPCODE: 
	{
	    int i;
	    args = XS_unpack_String_Array(ax,items);
	    if (!items) {
	      *args = "Main Sx Window"; items = 1;
	    }
	    if (i = OpenDisplay(items,args)) {
		int j;
		for (j = 0; j != i; j++) 
		    PUSHs(sv_2mortal(newSVpv(args[j],strlen(args[j]))));
	    }
	}

void
ShowDisplay()

void
MainLoop()

void
SyncDisplay()

Widget
MakeWindow(window_name, display_name, exclusive)
	char *		window_name
	char *		display_name = NO_INIT
	int		exclusive
	CODE:

	Newz(666, tmp , 1, struct Edata);
	display_name = ((ST(1) == &sv_undef) ? SAME_DISPLAY : SvPV(ST(1),na));
	RETVAL = MakeWindow(window_name,display_name,exclusive);

	OUTPUT:
	RETVAL

void
SetCurrentWindow(window)
	Widget		window

void
CloseWindow()

Widget
MakeForm(parent, where1, from1, where2, from2)
	Widget		parent
	int		where1
	Widget		from1
	int		where2
	Widget		from2
	CODE:

	Newz(666, tmp , 1, struct Edata);
	RETVAL = MakeForm(parent, where1, from1, where2, from2);

	OUTPUT:
	RETVAL

void
SetForm(form)
	Widget		form


Widget
MakeButton(label, callback, data = &sv_undef)
	char *		label
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeButton(label, button_callback, tmp);

	OUTPUT:
	RETVAL

Widget
Make3Button(label, callback1, callback2, callback3, data = &sv_undef)
	char *		label
	char *		callback1
	char *		callback2
	char *		callback3
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_BUTT_1] = NewString(callback1);
	tmp->fun[CB_BUTT_2] = NewString(callback2);
	tmp->fun[CB_BUTT_3] = NewString(callback3);
	RETVAL = Make3Com(label, but1_callback, but2_callback, but3_callback, tmp);

	OUTPUT:
	RETVAL

Widget
MakeLabel(txt)
	char *		txt
	CODE:

	Newz(666, tmp, 1, struct Edata);
	RETVAL = MakeLabel(txt);

	OUTPUT:
	RETVAL

Widget
MakeToggle(txt, state, widget, callback, data = &sv_undef)
	char *		txt
	int		state
	Widget		widget
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeToggle(txt, state, widget, button_callback, tmp);

	OUTPUT:
	RETVAL

void
SetToggleState(widget, state)
	Widget		widget
	int		state

int
GetToggleState(widget)
	Widget		widget

Widget
MakeDrawArea(width, height, callback, data = &sv_undef)
	int		width
	int		height
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeDrawArea(width, height, redisplay_callback, tmp);

	OUTPUT:
	RETVAL

void
SetButtonDownCB(widget, callback)
	Widget		widget = NO_INIT
	char *		callback
	CODE:
	{
		struct Edata *	w;

		if (sv_isa(ST(0),"SxWidget")) {
			unsigned long tmp;
			tmp = (unsigned long)SvNV((SV*)SvRV(ST(0)));
			w = (struct Edata *) tmp;
		} else
			croak("arg 1 is not a SxWidget");
		w->fun[CB_BD_IDX] = callback;
		w->cvcache[CB_BD_IDX] = NULL;
		if (*callback)
			SetButtonDownCB(w->w, button_down_callback);
		else
			SetButtonDownCB(w->w, NULL);
	}

void
SetButtonUpCB(widget, callback)
	Widget		widget = NO_INIT
	char *		callback
	CODE:
	{
		struct Edata *	w;

		if (sv_isa(ST(0),"SxWidget")) {
			unsigned long tmp;
			tmp = (unsigned long)SvNV((SV*)SvRV(ST(0)));
			w = (struct Edata *) tmp;
		} else
			croak("arg 1 is not a SxWidget");
		w->fun[CB_BU_IDX] = callback;
		w->cvcache[CB_BU_IDX] = NULL;
		if (*callback)
			SetButtonUpCB(w->w, button_up_callback);
		else
			SetButtonUpCB(w->w, NULL);
	}

void
SetKeypressCB(widget, callback)
	Widget		widget = NO_INIT
	char *		callback
	CODE:
	{
		struct Edata *	w;

		if (sv_isa(ST(0),"SxWidget")) {
			unsigned long tmp;
			tmp = (unsigned long)SvNV((SV*)SvRV(ST(0)));
			w = (struct Edata *) tmp;
		} else
			croak("form is not a SxWidget");
		w->fun[CB_KP_IDX] = callback;
		w->cvcache[CB_KP_IDX] = NULL;
		if (*callback)
			SetKeypressCB(w->w, keypress_callback);
		else
			SetKeypressCB(w->w, NULL);
	}

void
SetMouseMotionCB(widget, callback)
	Widget		widget = NO_INIT
	char *		callback
	CODE:
	{
		struct Edata *	w;

		if (sv_isa(ST(0),"SxWidget")) {
			unsigned long tmp;
			tmp = (unsigned long)SvNV((SV*)SvRV(ST(0)));
			w = (struct Edata *) tmp;
		} else
			croak("form is not a SxWidget");
		w->fun[CB_MM_IDX] = callback;
		w->cvcache[CB_MM_IDX] = NULL;
		if (*callback)
			SetMouseMotionCB(w->w, motion_callback);
		else
			SetMouseMotionCB(w->w, NULL);
	}

void
SetColor(color)
	int		color

void
SetDrawMode(mode)
	int		mode

void
SetLineWidth(width)
	int		width

void
SetDrawArea(widget)
	Widget		widget

void
GetDrawAreaSize(width, height)
	int		width = NO_INIT
	int		height = NO_INIT
	CODE:

	GetDrawAreaSize(&width,&height);

	OUTPUT:
	width
	height

void
ClearDrawArea()

void
DrawPixel(x1, y1)
	int		x1
	int		y1

int
GetPixel(x1, y1)
	int		x1
	int		y1

void
DrawLine(x1, y1, x2, y2)
	int		x1
	int		y1
	int		x2
	int		y2

void
DrawPolyline(points, ...)
	XPoint *	points = NO_INIT
	CODE:
	{
		int n, i;

		i = items / 2;
		Newz(666,points,i,XPoint);
		for (n = 0; n < i; n++) {
			points[n].x = SvIV(ST(0+(2*n)));
		  	points[n].y = SvIV(ST(1+(2*n)));
		}
		DrawPolyline(points, n);
		Safefree(points);
	}


void
DrawFilledPolygon(points, ...)
	XPoint *	points = NO_INIT
	CODE:
	{
		int n, i;

		i = items / 2;
		Newz(666,points,i,XPoint);
		for (n = 0; n < i; n++) {
			points[n].x = SvIV(ST(0+(2*n)));
		  	points[n].y = SvIV(ST(1+(2*n)));
		}
		DrawFilledPolygon(points, n);
		Safefree(points);
	}

void
DrawFilledBox(x, y, width, height)
	int		x
	int		y
	int		width
	int		height

void
DrawBox(x, y, width, height)
	int		x
	int		y
	int		width
	int		height

void
DrawText(string, x, y)
	char *		string
	int		x
	int		y

void
DrawArc(x, y, width, height, angle1, angle2)
	int		x
	int		y
	int		width
	int		height
	double		angle1
	double		angle2

void
DrawFilledArc(x, y, width, height, angle1, angle2)
	int		x
	int		y
	int		width
	int		height
	double		angle1
	double		angle2

void
DrawImage(data, x, y, width, height)
	Byte_Array	data
	int		x
	int		y
	int		width
	int		height

void
GetImage(x, y, width, height, result)
	int		x
	int		y
	int		width
	int		height
	Byte_Array	result = NO_INIT
	CODE:
	{

		Newz(666,result,width*height,unsigned char);
		GetImage(result,x,y,width,height);
	}
	OUTPUT:
	result	sv_setpvn(ST(4), (char *)result, width*height);

void
ScrollDrawArea(dx, dy, x1, y1, x2, y2)
	int		dx
	int		dy
	int		x1
	int		y1
	int		x2
	int		y2

Widget
MakeStringEntry(txt, size, callback, data = &sv_undef)
	char *		txt
	int		size
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeStringEntry(txt, size, string_callback, tmp);

	OUTPUT:
	RETVAL

void
SetStringEntry(widget, new_text)
	Widget		widget
	char *		new_text

char *
GetStringEntry(widget)
	Widget		widget

Widget
MakeTextWidget(txt, is_file, editable, width, height)
	char *		txt
	int		is_file
	int		editable
	int		width
	int		height
	CODE:

	Newz(666, tmp, 1, struct Edata);
	RETVAL = MakeTextWidget(txt, is_file, editable, width, height);

	OUTPUT:
	RETVAL

void
SetTextWidgetText(widget, txt, is_file)
	Widget		widget
	char *		txt
	int		is_file

char *
GetTextWidgetText(widget)
	Widget		widget

Widget
MakeHorizScrollbar(len, callback, data = &sv_undef)
	int		len
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeHorizScrollbar(len, scroll_callback, tmp);

	OUTPUT:
	RETVAL

Widget
MakeVertScrollbar(height, callback, data = &sv_undef)
	int		height
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeVertScrollbar(height, scroll_callback, tmp);

	OUTPUT:
	RETVAL

void
SetScrollbar(widget, where, max, size_shown)
	Widget		widget
	float		where
	float		max
	float		size_shown

Widget
MakeScrollList(width, height, callback, data, list, ...)
	int		width
	int		height
	char *		callback
	SV *		data
	char **		list = NO_INIT
	CODE:

	list = XS_unpack_String_Array(ax+4,items-4);
	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeScrollList(list, width, height, list_callback, tmp);

	OUTPUT:
	RETVAL

Widget
Make3List(width, height, callback, data, list, ...)
	int		width
	int		height
	char *		callback
	SV *		data
	char **		list = NO_INIT
	CODE:

	list = XS_unpack_String_Array(ax+4,items-4);
	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeThreeList(list, width, height, threelist_callback, tmp);

	OUTPUT:
	RETVAL

void
SetCurrentListItem(widget, list_index)
	Widget		widget
	int		list_index

int
GetCurrentListItem(widget)
	Widget		widget

void
ChangeScrollList(widget, new_list, ...)
	Widget		widget
	char **		new_list = NO_INIT
	CODE:
	new_list = XS_unpack_String_Array(ax+1,items-1);
	ChangeScrollList(widget,new_list);

Widget
MakeMenu(name)
	char *		name
	CODE:

	Newz(666, tmp, 1, struct Edata);
	RETVAL = MakeMenu(name);

	OUTPUT:
	RETVAL

Widget
MakeMenuItem(menu, name, callback, data = &sv_undef)
	Widget		menu
	char *		name
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = MakeMenuItem(menu, name, button_callback, tmp);

	OUTPUT:
	RETVAL

void
SetMenuItemChecked(widget, state)
	Widget		widget
	int		state

int
GetMenuItemChecked(widget)
	Widget		widget

void
SetWidgetPos(parent, where1, from1, where2, from2)
	Widget		parent
	int		where1
	Widget		from1
	int		where2
	Widget		from2

void
AttachEdge(widget, edge, attach_to)
	Widget		widget
	int		edge
	int		attach_to

void
SetFgColor(widget, color)
	Widget		widget
	int		color

void
SetBgColor(widget, color)
	Widget		widget
	int		color

void
SetBorderColor(widget, color)
	Widget		widget
	int		color

int
GetFgColor(widget)
	Widget		widget

int
GetBgColor(widget)
	Widget		widget

void
SetLabel(widget, txt)
	Widget		widget
	char *		txt

void
SetWidgetState(widget, state)
	Widget		widget
	int		state

int
GetWidgetState(widget)
	Widget		widget

void
SetWidgetBitmap(widget, data, width, height)
	Widget		widget
	Byte_Array	data
	int		width
	int		height

void
Beep()

XFont
GetFont(fontname)
	char *		fontname

void
SetWidgetFont(widget, font)
	Widget		widget
	XFont		font

XFont
GetWidgetFont(widget)
	Widget		widget

void
FreeFont(font)
	XFont		font

int
FontHeight(font)
	XFont		font

int
TextWidth(font, txt)
	XFont		font
	char *		txt

unsigned long
AddTimeOut(interval, callback, data = &sv_undef)
	unsigned long	interval
	char *		callback
	SV *		data
	CODE:
	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = AddTimeOut(interval, general_callback, tmp);

	OUTPUT:
	RETVAL

void
RemoveAddTimeOut(id)
	unsigned long	id

unsigned long
AddReadCallback(fd, callback, data = &sv_undef)
	int		fd
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = AddReadCallback(fd, io_callback, tmp);

	OUTPUT:
	RETVAL

unsigned long
AddWriteCallback(fd, callback, data = &sv_undef)
	int		fd
	char *		callback
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_GENFUN] = NewString(callback);
	RETVAL = AddWriteCallback(fd, io_callback, tmp);

	OUTPUT:
	RETVAL

void
RemoveReadWriteCallback(id)
	unsigned long	id

char *
GetString(blurb, default_string)
	char *		blurb
	char *		default_string

int
GetYesNo(question)
	char *		question

void
GetStandardColors()

int
GetNamedColor(name)
	char *		name

int
GetRGBColor(red, green, blue)
	int		red
	int		green
	int		blue

void
FreeStandardColors()

int
GetPrivateColor()

void
SetPrivateColor(which, red, green, blue)
	int		which
	int		red
	int		green
	int		blue

void
FreePrivateColor(which)
	int		which

int
GetAllColors()

void
SetColorMap(num)
	int		num

void
SetMyColorMap(color_array, ...)
	RGB_Array	color_array = NO_INIT
	CODE:
	{
		unsigned char *red, *green, *blue;
		int n, i;
		
		i = items / 3;
		Newz(666,red,i,unsigned char);
		Newz(666,green,i,unsigned char);
		Newz(666,blue,i,unsigned char);
		for (n = 0; n < i; n++) {
			red[n] = (unsigned char) 	SvIV(ST(0+(n*3)));
			green[n] = (unsigned char)	SvIV(ST(1+(n*3)));
			blue[n] = (unsigned char)	SvIV(ST(2+(n*3)));
		}
		SetMyColorMap(i,red,green,blue);
		Safefree(red); Safefree(green); Safefree(blue); 
	}		

void
FreeAllColors()

# Add on (C code is in suplibsx.c)

long
WTA(widget)
	Widget		widget
	CODE:
	RETVAL = (long) widget;
	OUTPUT:
	RETVAL

void
XtDestroyWidget(widget)
	Widget		widget
	CODE:
	if (widget)
	  XtDestroyWidget(widget);
	else
          printf("Trying to destroy Null widget %s\n",ST(0));


void
XWarpPointer(widget, dx, dy)
	Widget		widget
	int		dx
	int		dy
	CODE:
	XWarpPointer(lsx_curwin->display,None,widget->core.window,0,0,0,0,dx,dy);

void
SetWidgetInt(widget, resource, value)
	Widget		widget
	char *		resource
	int		value

void
SetWidgetDat(widget, resource, value)
	Widget		widget
	char *		resource
	char *		value

int
GetWidgetInt(widget, resource)
	Widget		widget
	char *		resource

char *
GetWidgetDat(widget, resource)
	Widget		widget
	char *		resource

void
AppendText(widget, text)
	Widget		widget
	char *		text

void
InsertText(widget, text)
	Widget		widget
	char *		text


void
AddTrans(widget, text)
	Widget		widget
	char *		text

Widget
MakeCanvas(width, height, expose, realize, resize, data)
	int		width
	int		height
	char *		expose
	char *		realize
	char *		resize
	SV *		data
	CODE:

	Newz(666, tmp, 1, struct Edata);
	tmp->data = newSVsv(data);
	tmp->fun[CB_REAFUN] = NewString(realize);
	tmp->fun[CB_RESFUN] = NewString(resize);
	tmp->fun[CB_EXPFUN] = NewString(expose);
	RETVAL = MakeCanvas(width, height, realize_callback, resize_callback,
					   expose_callback, tmp);
	OUTPUT:
	RETVAL




# Completion for various widget. Here are some Text widget functions
# This is temporary, there'll be a complete rewrite to get every 'standard'
# Athena widget public functions.

void
GetTextSelectionPos(widget, begin, end)
	Widget		widget
	long 		begin = NO_INIT
	long 		end = NO_INIT
	CODE:
	XawTextGetSelectionPos(widget, &begin, &end);
	OUTPUT:
	begin
	end

int
ReplaceText(w, start, end, text)
	Widget		w
	long		start
	long		end
	char *		text

void
UnsetTextSelection(widget)
	Widget		widget
	CODE:
	XawTextUnsetSelection(widget);

void
SetTextSelection(widget, left, right)
	Widget		widget
	long		left
	long		right
	CODE:
	XawTextSetSelection(widget,left,right);

void
GetSelection(widget, buf)
	Widget		widget
	char *		buf = NO_INIT
	CODE:
	{
	long x, y;
	XawTextGetSelectionPos(widget,&x,&y);
	buf = (char *) _XawTextGetText(widget,x,y);
	}
	OUTPUT:
	buf	sv_setpvn(ST(1), (char *)buf, strlen(buf));



# Variable/Constants to function call...

int
WHITE()
	CODE:
	RETVAL = WHITE;
	OUTPUT:
	RETVAL

int
BLACK()
	CODE:
	RETVAL = BLACK;
	OUTPUT:
	RETVAL

int
RED()
	CODE:
	RETVAL = RED;
	OUTPUT:
	RETVAL

int
GREEN()
	CODE:
	RETVAL = GREEN;
	OUTPUT:
	RETVAL

int
BLUE()
	CODE:
	RETVAL = BLUE;
	OUTPUT:
	RETVAL

int
YELLOW()
	CODE:
	RETVAL = YELLOW;
	OUTPUT:
	RETVAL

