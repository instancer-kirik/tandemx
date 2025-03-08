import React, { useRef, useEffect } from 'react';
import { Canvas, useFrame, useThree } from 'three/fiber';
import { useGLTF, Environment } from 'three/drei';
import * as THREE from 'three';

function Platform({ color = '#2563eb', ...props }) {
  const mesh = useRef();
  
  useFrame((state) => {
    mesh.current.rotation.y = Math.sin(state.clock.elapsedTime * 0.1) * 0.05;
  });

  return (
    <mesh ref={mesh} {...props}>
      <boxGeometry args={[100, 1, 100]} />
      <meshPhongMaterial color={color} transparent opacity={0.1} side={2} />
    </mesh>
  );
}

function Grid({ color = '#3b82f6', ...props }) {
  return (
    <gridHelper 
      args={[100, 50, color, color]} 
      position={[0, 0.5, 0]} 
      material-transparent
      material-opacity={0.1}
      {...props}
    />
  );
}

function Building({ position, height, color = '#3b82f6' }) {
  const mesh = useRef();
  
  useFrame((state) => {
    const time = state.clock.elapsedTime;
    mesh.current.position.y = height/2 + Math.sin(time + position[0]) * 0.2;
  });

  return (
    <mesh ref={mesh} position={[position[0], height/2, position[2]]}>
      <boxGeometry args={[2, height, 2]} />
      <meshPhongMaterial color={color} transparent opacity={0.3} />
    </mesh>
  );
}

function Scene() {
  const { camera } = useThree();
  
  useEffect(() => {
    camera.position.set(50, 30, 50);
    camera.lookAt(0, 0, 0);
  }, [camera]);

  return (
    <>
      <ambientLight intensity={0.6} />
      <directionalLight position={[50, 50, 50]} intensity={0.8} />
      
      <Platform />
      <Grid />
      
      <Building position={[-20, 0, -20]} height={15} />
      <Building position={[25, 0, 15]} height={10} />
      <Building position={[-10, 0, 30]} height={20} />
      <Building position={[30, 0, -25]} height={12} />
      
      <Environment preset="city" />
    </>
  );
}

export default function Background() {
  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      zIndex: -1,
      background: 'linear-gradient(135deg, rgba(248, 250, 252, 0.9), rgba(239, 246, 255, 0.9))'
    }}>
      <Canvas
        camera={{ fov: 45 }}
        dpr={[1, 2]}
        performance={{ min: 0.5 }}
      >
        <Scene />
      </Canvas>
    </div>
  );
} 