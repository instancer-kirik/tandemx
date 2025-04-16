-- Seed products table
INSERT INTO products (id, name, description, category, price, sale_price, image_url, badge) 
VALUES 
('servo-motor-sg90', 'SG90 Micro Servo Motor', 'Compact servo motor ideal for small robotics projects and prototypes.', 'robot-parts', 4.99, NULL, '/images/wishlist/servo-motor.jpg', 'best-seller'),
('dc-motor-n20', 'N20 DC Gear Motor', 'Mini DC geared motor with high torque output for small robots.', 'robot-parts', 6.99, NULL, '/images/wishlist/dc-motor.jpg', NULL),
('arduino-nano', 'Arduino Nano Board', 'Compact microcontroller board for robotics and IoT projects.', 'controllers', 12.99, NULL, '/images/wishlist/arduino-nano.jpg', NULL),
('raspberry-pi-4', 'Raspberry Pi 4 (4GB)', 'Powerful single-board computer for advanced robotics and AI projects.', 'controllers', 59.99, NULL, '/images/wishlist/raspberry-pi.jpg', 'featured'),
('ultrasonic-sensor', 'HC-SR04 Ultrasonic Sensor', 'Distance measurement sensor for obstacle detection and navigation.', 'sensors', 3.99, 2.99, '/images/wishlist/ultrasonic-sensor.jpg', 'sale'),
('infrared-sensor', 'IR Line Tracking Sensor', 'Infrared line following sensor module for line-following robots.', 'sensors', 2.99, NULL, '/images/wishlist/ir-sensor.jpg', NULL),
('robot-car-kit', '4WD Robot Car Kit', 'Complete robot car chassis kit with motors, wheels, and mount plates.', 'vehicles', 29.99, NULL, '/images/wishlist/robot-car.jpg', NULL),
('drone-kit', 'DIY Quadcopter Drone Kit', 'Build your own drone with this complete kit including frame, motors and controller.', 'vehicles', 89.99, NULL, '/images/wishlist/drone-kit.jpg', NULL),
('lipo-battery', '11.1V LiPo Battery Pack', 'High-capacity lithium polymer battery for powering robots and drones.', 'accessories', 24.99, NULL, '/images/wishlist/lipo-battery.jpg', NULL),
('robot-wheels', 'Robot Wheels Set (4pcs)', 'Rubber wheels with excellent grip for robotics projects.', 'accessories', 9.99, NULL, '/images/wishlist/robot-wheels.jpg', NULL),
('robot-arm-kit', 'Robotic Arm Kit', 'DIY robotic arm kit with 5 degrees of freedom and gripper.', 'robot-parts', 49.99, NULL, '/images/wishlist/robot-arm.jpg', NULL),
('motor-driver', 'L298N Motor Driver', 'Dual H-bridge motor driver module for controlling DC motors.', 'controllers', 5.99, NULL, '/images/wishlist/motor-driver.jpg', NULL)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  price = EXCLUDED.price,
  sale_price = EXCLUDED.sale_price,
  image_url = EXCLUDED.image_url,
  badge = EXCLUDED.badge;

-- Seed product specs
-- Servo Motor SG90
INSERT INTO product_specs (product_id, spec_key, spec_value) VALUES 
('servo-motor-sg90', 'Weight', '9g'),
('servo-motor-sg90', 'Torque', '1.8kg/cm'),
('servo-motor-sg90', 'Speed', '0.1s/60°'),
('servo-motor-sg90', 'Voltage', '4.8-6V')
ON CONFLICT (product_id, spec_key) DO UPDATE SET spec_value = EXCLUDED.spec_value;

-- DC Motor N20
INSERT INTO product_specs (product_id, spec_key, spec_value) VALUES 
('dc-motor-n20', 'RPM', '200'),
('dc-motor-n20', 'Voltage', '6V'),
('dc-motor-n20', 'Shaft Diameter', '3mm'),
('dc-motor-n20', 'Weight', '15g')
ON CONFLICT (product_id, spec_key) DO UPDATE SET spec_value = EXCLUDED.spec_value;

-- Arduino Nano
INSERT INTO product_specs (product_id, spec_key, spec_value) VALUES 
('arduino-nano', 'Microcontroller', 'ATmega328P'),
('arduino-nano', 'Clock Speed', '16MHz'),
('arduino-nano', 'Digital I/O', '14 pins'),
('arduino-nano', 'Analog Inputs', '8 pins')
ON CONFLICT (product_id, spec_key) DO UPDATE SET spec_value = EXCLUDED.spec_value;

-- Raspberry Pi 4
INSERT INTO product_specs (product_id, spec_key, spec_value) VALUES 
('raspberry-pi-4', 'CPU', 'Quad-core Cortex-A72'),
('raspberry-pi-4', 'RAM', '4GB'),
('raspberry-pi-4', 'Connectivity', 'WiFi, Bluetooth 5.0'),
('raspberry-pi-4', 'Ports', 'USB 3.0, HDMI, Ethernet')
ON CONFLICT (product_id, spec_key) DO UPDATE SET spec_value = EXCLUDED.spec_value;

-- Ultrasonic Sensor
INSERT INTO product_specs (product_id, spec_key, spec_value) VALUES 
('ultrasonic-sensor', 'Range', '2-400cm'),
('ultrasonic-sensor', 'Accuracy', '3mm'),
('ultrasonic-sensor', 'Voltage', '5V'),
('ultrasonic-sensor', 'Current', '15mA')
ON CONFLICT (product_id, spec_key) DO UPDATE SET spec_value = EXCLUDED.spec_value;

-- More specs for other products can be added similarly 