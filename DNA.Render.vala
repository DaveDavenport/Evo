using GLib;
using Gdk;
using Xml;
using Cairo;

namespace DNA
{
	private void draw (Cairo.Surface surf,DNA.Strain strain, uint width, uint height)
	{
		var ct = new Context(surf);
		ct.set_source_rgba(0,0,0,1);
		ct.paint();
		ct.scale((double)width,(double)height);
		foreach(unowned DNA.Polygon pol in strain.polygons)
		{
			if(pol.points == null) break;
			unowned DNA.Brush b  = pol.GetBrush();
			ct.set_source_rgba(b.r/255.0,b.g/255.0,b.b/255.0,b.a);
			bool init = true;
			foreach(unowned DNA.Point node in pol.points)
			{
				if(init) {
					ct.move_to(node.x, node.y);
					init = false;
				}else{
					ct.line_to(node.x, node.y);
				}
			}
			ct.fill();
		}
	}
	public void RenderSVG(string filename, DNA.Strain strain, uint width, uint height)
	{
		var surf = new Cairo.SvgSurface(filename, width, height);
		draw(surf,strain, width,height);
		surf.finish();
		surf.flush();
	}
	public void RenderPNG(string filename, DNA.Strain strain, uint width, uint height)
	{
		var surf = new Cairo.ImageSurface(Cairo.Format.RGB24, (int)width, (int)height);
		GLib.debug("Write to png: %s", filename);
		draw(surf,strain, width,height);
		surf.write_to_png(filename);
		surf.finish();
		surf.flush();
	}

	public void Render(DNA.Strain strain, uchar[] pixels, uint width, uint height, uint nchan=3)
	{
		uint[] cpoints = new uint[64];
		uint stride = width*nchan;
		/* Clear */
		GLib.Memory.set(pixels, 0, stride*height);
		/* itterate over each polygon */
		foreach(unowned DNA.Polygon pol in strain.polygons)
		{
			if(pol.points == null) break;
			unowned DNA.Brush b  = pol.GetBrush();
			if(b.a < 0.01) break;
			float ba = 1-b.a;
			/* doing this outside innerloop saves me 2% */
			float br = b.r*b.a;
			float bg = b.g*b.a;
			float bb = b.b*b.a;

			uint y_min = (uint)(pol.top.y*height);
			uint y_max = (uint)(pol.bottom.y*height);
			//  Loop through the rows of the image.
			for (uint y= y_min; y<y_max; y++) 
			{
				float pixely = y/(float)height;
				//  build a list of nodes.
				uint nodes=0;
				unowned DNA.Point lp = pol.last_point.data;
				foreach(unowned DNA.Point node in pol.points)
				{
					if (
							(lp.y < pixely && node.y>= pixely) ||
							(node.y < pixely && lp.y >= pixely)   
						)
					{
						cpoints[nodes++]= (uint)(width*(node.x+(pixely-node.y)/(lp.y-node.y)*(lp.x-node.x))); 
					}
					lp = node;
				}
				if(nodes > 0)
				{
					uint uy = y*stride;
					uint8 i=0;
					//  sort the nodes, via a simple “bubble” sort.
					while (i<nodes-1) {
						if (cpoints[i]>cpoints[i+1]) {
							uint swap=cpoints[i];
							cpoints[i]=cpoints[i+1];
							cpoints[i+1]=swap;
							if (i > 0) i--; 
						}
						else 
							i++; 
					}
					//  fill the pixels between node pairs.
					for (i=0; i<nodes; i+=2)
					{
						for (uint j=cpoints[i]; j<cpoints[i+1]; j++)
						{
							uint index = uy+(uint)j*nchan;
							pixels[index] =   (uchar)(br +ba*(pixels[index]  ));
							pixels[index+1] = (uchar)(bg +ba*(pixels[index+1]));
							pixels[index+2] = (uchar)(bb +ba*(pixels[index+2]));
						}
					}
				}
			}
		}
	}
}
