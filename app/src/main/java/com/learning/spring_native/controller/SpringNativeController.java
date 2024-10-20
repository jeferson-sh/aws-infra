package com.learning.spring_native.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("api/v1")
public class SpringNativeController {

    @GetMapping("/messages")
    public ResponseEntity<String> getMessage(){
        return ResponseEntity.ok("ok");
    }
}
