package me.id.assignment;

import me.id.assignment.dto.HelloWorld;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import java.util.Optional;

@Path("/helloworld")
public class HelloWorldResource {

	@Inject
	HelloWordService helloService;

	@POST
	@Produces(MediaType.APPLICATION_JSON)
	@Consumes(MediaType.APPLICATION_JSON)
	public HelloWorld helloworld(HelloWorld userHello) {
		Optional<HelloWorld> savedHello = helloService.save( userHello );

		if ( savedHello.isEmpty() ) {
			throw new InternalServerErrorException("The world fell apart");
		}
		return savedHello.get();
	}

	@GET
	@Path("{id}")
	@Produces(MediaType.APPLICATION_JSON)
	public HelloWorld get(@PathParam("id") Long id) {
		Optional<HelloWorld> hello = helloService.get(id);
		if ( hello.isEmpty() ) {
			throw new NotFoundException("No hello found");
		}

		return hello.get();
	}

	@GET
	@Produces(MediaType.APPLICATION_JSON)
	public HelloWorld get() {
		return HelloWorld.builder().message("Test Hello World").build();
	}
}
