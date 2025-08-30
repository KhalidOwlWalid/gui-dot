#pragma once

#include "guidot_common.hpp"

namespace godot {

class Frame_t {
	public:
		Rect2 frame;
		Color color;

		// Helper function to get the top left position of the frame
		inline Vector2 get_pos() const {return frame.position;}
		inline void set_pos(const Vector2 pos) {frame.set_position(pos);}
		inline int x() const {return frame.position.x;}
		inline int y() const {return frame.position.y;}

		// Useful to get different coordinates of the frame
		inline Vector2 top_left() const {return Vector2(frame.position.x, frame.position.y);}
		inline Vector2 top_right() const {return Vector2(frame.position.x + frame.size.x, frame.position.y);}
		inline Vector2 bottom_left() const {return Vector2(frame.position.x, frame.position.y + frame.size.y);}
		inline Vector2 bottom_right() const {return Vector2(frame.position.x + frame.size.x, frame.position.y + frame.size.y);}

		// Helper function to get or set the size of the frame
		inline Vector2 get_size() const {return frame.get_size();}
		inline void set_size(const Vector2 size) {frame.set_size(size);}
		inline uint x_size() const {return frame.size.x;}
		inline uint y_size() const {return frame.size.y;}
};

}
