#ifndef PLOT_2D_HPP
#define PLOT_2D_HPP

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class Plot_2D : public Control {

  GDCLASS(Plot_2D, Control);

  public:

    Plot_2D();
    ~Plot_2D();
    // void _process(double delta) override;

    void set_background_color(const Color color);
    Color get_background_color() const;

    void _draw() override;

  protected:
    static void _bind_methods();

  private:
    Vector2 _graph_size;
    Color _background_color;

};

}

#endif