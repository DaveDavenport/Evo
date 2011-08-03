using GLib;
using Gdk;
using Xml;

namespace DNA
{
    public class Polygon
    {
        private const int mutation_pos_add = 700;
        private const int mutation_pos_remove = 1500;
        private const int initial_points = 3;
        public List<DNA.Point> points;
        public DNA.Point top = new DNA.Point();
        public DNA.Point bottom = new DNA.Point();
        private Brush brush;

        public void store_xml(Xml.Node *node)
        {
            Xml.Node *polygon = new Xml.Node(null,"polygon");
            brush.store_xml(polygon);
            foreach(unowned DNA.Point p in points)
            {
                p.store_xml(polygon);
            }
            node->add_child(polygon);
        }

        public Polygon.from_xml(Xml.Node *node)
        {
            for(Xml.Node *iter =  node->children; iter != null; iter = iter->next)
            {
                if(iter->name == "point")
                {
                    stdout.printf("add point\n");
                    DNA.Point point = new DNA.Point.from_xml(iter);
                    AddPoint(point);
                }
                else if (iter->name == "brush")
                {
                    stdout.printf("add brush\n");
                    DNA.Brush b = new DNA.Brush.from_xml(iter);
                    brush = b;
                }
            }
            points.reverse();
            update_bb();
        }

        private void update_bb()
        {
            bool init =true;
            foreach(unowned DNA.Point p in points)
            {
                if(init) {
                    top.x = p.x;
                    top.y = p.y;
                    bottom.x = p.x;
                    bottom.y = p.y;
                    init = false;
                }else{
                     top.x = float.min(top.x,p.x);
                     top.y = float.min(top.y, p.y);
                     bottom.x = float.max(bottom.x,p.x);
                     bottom.y = float.max(bottom.y, p.y);

                }
            }
        }
        /**
         * Constructor
         */
        public Polygon()
        {
            brush = new Brush();
            for(int j=0;j<initial_points;j++)
            {
                AddPoint(new DNA.Point());
            }
            points.reverse();
            update_bb();
        }

        /**
         * Getter for brush
         */
        public unowned Brush GetBrush()
        {
            return brush;
        }

        /**
         * Clone polygon
         */
        public Polygon.Clone(Polygon pol)
        {

            brush = new Brush.Clone(pol.brush);
            foreach (unowned Point p in pol.points)
            {
                AddPoint(new Point.Clone(p));
            }
            top.x = pol.top.x;
            top.y = pol.top.y;
            bottom.x = pol.bottom.x;
            bottom.y = pol.bottom.y;
            points.reverse();
        }

        /**
         * Add a point
         */
        public void AddPoint(Point p)
        {
            points.prepend(p);
        }

        /**
         * Remove a point
         */
        public void RemovePoint(Point p)
        {
            unowned List<Point> en = points.find(p);
            if(en != null)
            {
                var pol = (owned)en.data;
                points.delete_link(en);
                pol = null;
            }
        }
        /**
         * Mutate
         */
        public bool Mutate()
        {
            bool dirt = false;

            if(false && DNA.Tool.Mutate(mutation_pos_add))
            {
                AddPoint(new Point());
                dirt = true;
            }
            List<Point> remove_list = null;
            foreach(unowned DNA.Point P in points)
            {
                if(false && DNA.Tool.Mutate(mutation_pos_remove))
                {
                    remove_list.prepend(P);
                }
                else
                {
                    if(P.Mutate())
                    {
                        dirt = true;
                    }
                }
            }
            foreach(unowned DNA.Point P in remove_list)
            {
                RemovePoint(P);
                dirt = true;
            }
            if(dirt) {
                update_bb();
            }
            if(brush.Mutate())
            {
                dirt = true;
            }

            return dirt;
        }
    }
}
