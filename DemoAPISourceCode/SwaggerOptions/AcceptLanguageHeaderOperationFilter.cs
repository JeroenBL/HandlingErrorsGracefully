using Microsoft.OpenApi.Any;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace ErrorhandlingDemoAPI.SwaggerOptions
{
    public class AcceptLanguageHeaderOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            var httpMethod = context.ApiDescription.HttpMethod;
            var relativePath = context.ApiDescription.RelativePath?.ToLower();

            if (httpMethod == "GET" && relativePath != null && relativePath.StartsWith("api/user/") && relativePath.Contains("{id}"))
            {
                operation.Parameters ??= new List<OpenApiParameter>();

                operation.Parameters.Add(new OpenApiParameter
                {
                    Name = "Accept-Language",
                    In = ParameterLocation.Header,
                    Required = false,
                    Schema = new OpenApiSchema
                    {
                        Type = "string",
                        Default = new OpenApiString("en")
                    },
                    Description = "Optional language code for localization, e.g. 'en' or 'de'."
                });
            }
        }
    }
}
